;;; arcer.el --- Arc VCS interface for Emacs -*- lexical-binding: t; coding: utf-8 -*-

(require 'magit-section)
(require 'transient)
(require 'with-editor)
(require 'diff-mode)
(require 'ansi-color)
(require 'cl-lib)
(require 'map)
(require 'seq)

;; --- Magit ---
;; Открывать magit-status на весь фрейм; при выходе восстанавливать окна.
(use-package magit
  :ensure t
  :commands (magit-status)
  :config
  (setq magit-display-buffer-function
        #'magit-display-buffer-fullframe-status-v1))

;;;; Customization

(defgroup arcer nil "Arc VCS interface." :group 'tools)

(defcustom arcer-log-page-size 25
  "Number of commits per page in log buffer."
  :type 'integer :group 'arcer)

(defcustom arcer-log-buffer-width 0.4
  "Width of the log side window as fraction of frame width."
  :type 'float :group 'arcer)

;;;; Faces

(defface arcer-branch
  '((((class color) (background dark))  :foreground "LightSkyBlue1" :weight bold)
    (((class color) (background light)) :foreground "SkyBlue4"      :weight bold))
  "Current branch name." :group 'arcer)

(defface arcer-dimmed
  '((t :foreground "grey50"))
  "Dimmed text (hashes, timestamps)." :group 'arcer)

(defface arcer-log-author
  '((((class color) (background dark))  :foreground "tomato")
    (((class color) (background light)) :foreground "firebrick"))
  "Author name in log." :group 'arcer)

(defface arcer-pr-status
  '((t :inherit magit-section-heading))
  "PR status heading." :group 'arcer)

(defface arcer-staged
  '((t :inherit magit-diff-added))
  "Staged file name." :group 'arcer)

(defface arcer-unstaged
  '((t :inherit magit-diff-removed))
  "Unstaged/modified file name." :group 'arcer)

(defface arcer-untracked
  '((t :inherit shadow))
  "Untracked file name." :group 'arcer)

;;;; Process layer

(defvar arcer--live-procs nil
  "List of currently running background arc processes (for cancellation).")

(defun arcer--kill-pending ()
  "Kill all running background arc processes."
  (dolist (p arcer--live-procs)
    (when (process-live-p p)
      (kill-process p)))
  (setq arcer--live-procs nil))

(defun arcer--run (args &optional parse callback)
  "Run arc ARGS asynchronously. PARSE: nil|'json. CALLBACK(stdout exit-code)."
  (let* ((buf  (generate-new-buffer " *arcer-proc*"))
         (proc (make-process
                :name "arcer"
                :command (cons "arc" args)
                :buffer buf
                :connection-type 'pipe
                :noquery t
                :sentinel
                (lambda (p _)
                  (setq arcer--live-procs (delq p arcer--live-procs))
                  (unless (process-live-p p)
                    (let* ((code (process-exit-status p))
                           (out  (with-current-buffer buf
                                   (goto-char (point-min))
                                   (condition-case nil
                                       (if (and (= code 0) (eq parse 'json))
                                           (json-parse-buffer :object-type 'alist
                                                              :array-type 'list)
                                         (string-trim (buffer-string)))
                                     (error nil)))))
                      (kill-buffer buf)
                      (when callback (funcall callback out code))))))))
    (push proc arcer--live-procs)
    proc))

(defun arcer--run-sync (args &optional parse)
  "Run arc ARGS synchronously, return stdout."
  (let (result ready)
    (arcer--run args parse (lambda (out _) (setq result out ready t)))
    (while (not ready) (accept-process-output nil 0.05))
    (when (and (stringp result) (string-prefix-p "error:" result))
      (message "Arcer: Command failed. Args: %s\nOutput: %s" args result))
    result))

(defun arcer--wait-proc (proc &optional noraise)
  "Wait for async PROC (make-process) to finish and return its output.
If NORAISE is non-nil, return nil on non-zero exit instead of erroring."
  (while (process-live-p proc) (accept-process-output proc 0.1))
  ;; Output is already in the process buffer; the sentinel stored it
  ;; We need a different approach: use a callback-based wrapper.
  ;; Actually arcer--run uses sentinel+callback, not direct buffer read.
  ;; So arcer--wait-proc is not applicable here — we use callbacks instead.
  ;; This function is kept as a no-op placeholder.
  nil)

;;;; Diff parsing

(defun arcer--propertize-line (text face)
  (propertize text 'face face 'font-lock-face face))

(defun arcer--insert-diff-body (text)
  "Insert diff TEXT using diff-mode faces with word-level refinement."
  (let (removed-beg removed-end added-beg added-end blocks)

    (cl-flet ((flush ()
                (when (or removed-beg added-beg)
                  (push (list removed-beg removed-end added-beg added-end) blocks))
                (setq removed-beg nil removed-end nil
                      added-beg  nil added-end  nil)))

      (dolist (line (split-string text "\n"))
        (unless (string-empty-p line)
          (pcase (aref line 0)
            (?-
             ;; Pure-addition block before this removal — flush it first
             (when (and added-beg (not removed-beg)) (flush))
             (unless removed-beg (setq removed-beg (point)))
             (insert (arcer--propertize-line (substring line 0 1) 'diff-indicator-removed))
             (insert (arcer--propertize-line (concat (substring line 1) "\n") 'diff-removed))
             (setq removed-end (point)))
            (?+
             (unless added-beg (setq added-beg (point)))
             (insert (arcer--propertize-line (substring line 0 1) 'diff-indicator-added))
             (insert (arcer--propertize-line (concat (substring line 1) "\n") 'diff-added))
             (setq added-end (point)))
            (?@
             (flush)
             (insert (arcer--propertize-line (concat line "\n") 'diff-hunk-header)))
            (_
             (flush)
             (insert (arcer--propertize-line (concat line "\n") 'diff-context))))))

      (flush))

    ;; Word-level refinement for change blocks that have both removals and additions
    (require 'smerge-mode nil t)
    (when (fboundp 'smerge-refine-regions)
      (let ((strip-indicator
             (lambda ()
               (goto-char (point-min))
               (while (not (eobp))
                 (delete-char 1)    ; strip the +/- indicator character
                 (forward-line 1)))))
        (dolist (block blocks)
          (pcase-let ((`(,rb ,re ,ab ,ae) block))
            (when (and rb re ab ae)
              (ignore-errors
                (smerge-refine-regions
                 rb re ab ae
                 nil
                 strip-indicator
                 '((face . diff-refine-removed) (font-lock-face . diff-refine-removed))
                 '((face . diff-refine-added)   (font-lock-face . diff-refine-added)))))))))))

(defun arcer--parse-diffs (text)
  "Parse unified diff TEXT → alist of (path . plain-string)."
  (when (and text (stringp text) (not (string-empty-p text)))
    (with-temp-buffer
      (insert text "\n")
      (diff-mode)
      (goto-char (point-min))
      (unless (looking-at diff-file-header-re)
        (ignore-errors (diff-file-next)))
      (let (result)
        (while (not (eobp))
          (let* ((path   (ignore-errors
                           (substring-no-properties (car (diff-hunk-file-names)))))
                 (bounds (ignore-errors (diff-bounds-of-file)))
                 (diff   (when (and path bounds)
                           (let ((raw (apply #'buffer-substring-no-properties bounds)))
                             (with-temp-buffer
                               (insert raw)
                               (goto-char (point-min))
                               (ignore-errors (diff-hunk-next))
                               (delete-region (point-min) (point))
                               (buffer-substring-no-properties (point-min) (point-max)))))))
            (when (and path diff)
              (push (cons path diff) result)))
          (ignore-errors (diff-file-next)))
        result))))

(defun arcer--split-hunks (diff-text)
  "Split DIFF-TEXT (already stripped of file header) into list of hunk strings."
  (when (and diff-text (not (string-empty-p diff-text)))
    (with-temp-buffer
      (insert diff-text)
      (goto-char (point-min))
      (let (hunks begin)
        (when (re-search-forward "^@@" nil t)
          (setq begin (line-beginning-position))
          (while (re-search-forward "^@@" nil t)
            (push (buffer-substring-no-properties begin (line-beginning-position)) hunks)
            (setq begin (line-beginning-position)))
          (push (buffer-substring-no-properties begin (point-max)) hunks))
        (nreverse hunks)))))

;;;; Section classes

(defclass arcer-root-section   (magit-section) ())
(defclass arcer-head-section   (magit-section) ())
(defclass arcer-pr-section     (magit-section) ((pr-id :type string :initform "")))
(defclass arcer-file-list-sec  (magit-section) ((kind  :type symbol :initform 'staged)))
(defclass arcer-file-section   (magit-section)
  ((path  :type string :initform "")
   (state :type symbol :initform 'unstaged)))
(defclass arcer-hunk-section   (magit-section) ())
(defclass arcer-log-sum-sec    (magit-section) ())
(defclass arcer-commit-section (magit-section) ((hash :type string :initform "")))
(defclass arcer-load-more-sec  (magit-section) ())
(defclass arcer-stash-sum-sec   (magit-section) ())
(defclass arcer-stash-entry-sec (magit-section) ((stash-id :type string :initform "")))

(defun arcer--parse-stash-list (text)
  "Parse plain-text arc stash list output into list of alists with \\='id and \\='display."
  (when (and text (stringp text) (not (string-empty-p text)))
    (seq-filter #'identity
      (mapcar (lambda (line)
                (when (string-match "^\\([0-9a-f]+\\) \\(.+\\)$" line)
                  (list (cons 'id      (match-string 1 line))
                        (cons 'display (match-string 2 line)))))
              (split-string (string-trim text) "\n" t)))))

;;;; Buffer-local state

(defvar-local arcer--state nil
  "Plist: :branch :head-commit :head-message :staged :unstaged :untracked
:unmerged :staged-diffs :unstaged-diffs :pr :log-base :log-commits :stash-list.")

;;;; Render helpers

(defun arcer--render-head ()
  (magit-insert-section (arcer-head-section)
    (let ((branch  (plist-get arcer--state :branch))
          (commit  (plist-get arcer--state :head-commit))
          (msg     (plist-get arcer--state :head-message)))
      (insert (propertize "Head:\t" 'face 'magit-section-heading))
      (insert (propertize (or branch (and commit (substring commit 0 8)) "?")
                          'face 'arcer-branch))
      (when msg (insert "\t" msg))
      (insert "\n\n"))))

(defun arcer--render-pr ()
  (when-let ((pr (plist-get arcer--state :pr)))
    (let ((pr-id  (number-to-string (or (map-elt pr 'id) 0)))
          (summary (or (map-elt pr 'summary) ""))
          (status  (or (map-elt pr 'status) ""))
          (issues  (or (map-elt pr 'issues) [])))
      (magit-insert-section (arcer-pr-section pr-id)
        (oset magit-insert-section--current pr-id pr-id)
        
        ;; Создаем keymap для действия
        (let ((heading-map (make-sparse-keymap)))
          (define-key heading-map [return]
                      (lambda () (interactive)
                        (browse-url (format "https://a.yandex-team.ru/review/%s/details" pr-id))))
          ;; Опционально: привязка клика мышью
          (define-key heading-map [mouse-1]
                      (lambda () (interactive)
                        (browse-url (format "https://a.yandex-team.ru/review/%s/details" pr-id))))

          (magit-insert-heading
            ;; Добавляем свойства прямо в строку с помощью propertize
            (propertize (format "Pull request #%s" pr-id)
                        'keymap heading-map
                        'mouse-face 'highlight ;; Подсветка при наведении мыши
                        'help-echo "Click or press RET to open PR"))) ;; Подсказка
        
        (insert "Summary: " summary "\n")
        (insert "Status:  " status "\n")
        (when (and (sequencep issues) (not (seq-empty-p issues)))
          (insert "Tickets: ")
          (let ((tickets (seq-map (lambda (t) (if (stringp t) t (format "%s" t))) issues)))
            (arcer--insert-ticket-link (car tickets))
            (dolist (ticket (cdr tickets))
              (insert ", ")
              (arcer--insert-ticket-link ticket)))
          (insert "\n"))
        (insert "\n")))))

(defun arcer--insert-pr-link (pr-id)
  (insert-text-button ticket
                      'button-data (format "https://st.yandex-team.ru/%s/details" pr-id)
                      'action (lambda (url) (browse-url url))
                      'follow-link t))

(defun arcer--insert-ticket-link (ticket)
  (insert-text-button ticket
                      'button-data (concat "https://st.yandex-team.ru/" ticket)
                      'action #'browse-url
                      'follow-link t))

(defun arcer--open-author (login)
  (if (fboundp 'yandex-show-staff-profile)
      (yandex-show-staff-profile login nil t)
    (browse-url (concat "https://staff.yandex-team.ru/" login))))

(defun arcer--file-face (state)
  (pcase state
    ('staged    'arcer-staged)
    ('unstaged  'arcer-unstaged)
    ('untracked 'arcer-untracked)
    (_ 'default)))

(defun arcer--render-file-list (kind heading)
  (let ((files (plist-get arcer--state
                           (pcase kind
                             ('staged    :staged)
                             ('unstaged  :unstaged)
                             ('untracked :untracked)
                             ('unmerged  :unmerged))))
        (diffs  (plist-get arcer--state
                            (pcase kind
                              ('staged   :staged-diffs)
                              (_         :unstaged-diffs)))))
    (when (and files (not (seq-empty-p files)))
      (magit-insert-section (arcer-file-list-sec kind)
        (oset magit-insert-section--current kind kind)
        (magit-insert-heading heading)
        (dolist (file files)
          (let* ((path   (or (map-elt file 'path) ""))
                 (status (map-elt file 'status))
                 (diff   (map-elt diffs path))
                 (hunks  (when diff (arcer--split-hunks diff))))
            (magit-insert-section (arcer-file-section path t)
              (oset magit-insert-section--current path  path)
              (oset magit-insert-section--current state kind)
              (let ((ff (arcer--file-face kind)))
                (insert (propertize
                         (concat (when status (concat (string-pad status 10) " "))
                                 path "\n")
                         'face ff 'font-lock-face ff)))
              (magit-insert-heading)
              (when hunks
                (magit-insert-section-body
                  (dolist (hunk hunks)
                    (magit-insert-section (arcer-hunk-section)
                      (let ((nl (string-match "\n" hunk)))
                        (if nl
                            (progn
                              (insert (propertize (substring hunk 0 nl)
                                                  'face 'diff-hunk-header
                                                  'font-lock-face 'diff-hunk-header))
                              (insert "\n")
                              (magit-insert-heading)
                              (arcer--insert-diff-body (substring hunk (1+ nl))))
                          (insert (propertize hunk
                                             'face 'magit-diff-hunk-heading
                                             'font-lock-face 'magit-diff-hunk-heading))
                          (insert "\n")
                          (magit-insert-heading))))))))))
        (insert "\n")))))

(defun arcer--render-log-summary ()
  (let ((commits (plist-get arcer--state :log-commits))
        (base    (plist-get arcer--state :log-base)))
    (when commits
      (magit-insert-section (arcer-log-sum-sec)
        (magit-insert-heading
          (format "Commits ahead of trunk (%d):" (length commits)))
        (dolist (commit commits)
          (let ((hash (or (map-elt commit 'commit) ""))
                (msg  (car (string-lines (or (map-elt commit 'message) "")))))
            (magit-insert-section (arcer-commit-section hash)
              (oset magit-insert-section--current hash hash)
              (insert (propertize (substring hash 0 (min 8 (length hash)))
                                  'face 'arcer-dimmed))
              (insert " " msg "\n"))))
        (insert "\n")))))

(defun arcer--render-stash-list ()
  (let ((entries (plist-get arcer--state :stash-list)))
    (when (and (listp entries) entries)
      (magit-insert-section (arcer-stash-sum-sec)
        (magit-insert-heading
          (format "Stash entries (%d):" (length entries)))
        (dolist (entry entries)
          (let* ((id      (or (map-elt entry 'id) ""))
                 (display (or (map-elt entry 'display) ""))
                 (short   (substring id 0 (min 8 (length id)))))
            (magit-insert-section (arcer-stash-entry-sec id)
              (oset magit-insert-section--current stash-id id)
              (insert (propertize short 'face 'arcer-dimmed))
              (insert " " display "\n"))))
        (insert "\n")))))

(defun arcer--render ()
  (let ((inhibit-read-only t)
        (saved-line (line-number-at-pos)))
    (erase-buffer)
    (magit-insert-section (arcer-root-section)
      (arcer--render-head)
      (arcer--render-pr)
      (arcer--render-file-list 'untracked "Untracked files:")
      (arcer--render-file-list 'unmerged  "Unmerged files:")
      (arcer--render-file-list 'unstaged  "Unstaged changes:")
      (arcer--render-file-list 'staged    "Staged changes:")
      (arcer--render-log-summary)
      (arcer--render-stash-list))
    (goto-char (point-min))
    (forward-line (1- saved-line))))

;;;; Refresh

(defun arcer--await-and-build-state (buf
                                     status-result pr-result
                                     udiff-result  sdiff-result
                                     base          log-commits)
  (with-current-buffer buf
    (setq arcer--state
          (list :branch       (map-nested-elt status-result '(branch_info local name))
                :head-commit  (map-nested-elt status-result '(branch_info local commit id))
                :head-message (map-nested-elt status-result '(branch_info local commit title))
                :staged       (map-nested-elt status-result '(status staged))
                :unstaged     (map-nested-elt status-result '(status changed))
                :untracked    (map-nested-elt status-result '(status untracked))
                :unmerged     (map-nested-elt status-result '(status unmerged))
                :staged-diffs   (arcer--parse-diffs sdiff-result)
                :unstaged-diffs (arcer--parse-diffs udiff-result)
                :pr           pr-result
                :log-base     base
                :log-commits  log-commits
                :stash-list   nil))
    (arcer--render)))

;; Fully async refresh: merge-base first, then fan out 5 parallel requests.
;; Never calls arcer--run-sync so it is safe to invoke from process sentinels.
(defun arcer--refresh ()
  (message "Refreshing arcer...")
  (let ((buf (current-buffer)))
    (arcer--run '("merge-base" "HEAD" "trunk") nil
               (lambda (base _)
                 (when (buffer-live-p buf)
                   (with-current-buffer buf
                     (arcer--refresh-phase2
                      (if (and (stringp base) (not (string-empty-p base)))
                          base
                        "trunk"))))))))

(defun arcer--refresh-phase2 (base)
  ;; Phase 1: render status/pr/diffs immediately when 4 fast processes finish.
  ;; Phase 2: arc log loads in background and triggers a second render when ready.
  (let* ((arcer--p2-buf  (current-buffer))
         (arcer--p2-tbl  (make-hash-table :test 'eq))
         (arcer--p2-left 4)
         (arcer--p2-done (lambda ()
                           (cl-decf arcer--p2-left)
                           (when (= arcer--p2-left 0)
                             (when (buffer-live-p arcer--p2-buf)
                               (with-current-buffer arcer--p2-buf
                                 (arcer--await-and-build-state
                                  arcer--p2-buf
                                  (gethash 'status arcer--p2-tbl)
                                  (gethash 'pr     arcer--p2-tbl)
                                  (gethash 'udiff  arcer--p2-tbl)
                                  (gethash 'sdiff  arcer--p2-tbl)
                                  base
                                  nil)
                                 (arcer--run
                                  `("log" "--json" "-n"
                                    ,(number-to-string arcer-log-page-size)
                                    ,(format "%s..HEAD" base))
                                  'json
                                  (lambda (commits _)
                                    (when (buffer-live-p arcer--p2-buf)
                                      (with-current-buffer arcer--p2-buf
                                        (plist-put arcer--state :log-commits
                                                   (when (listp commits) commits))
                                        (arcer--render)))))
                                 (arcer--run '("stash" "list") nil
                                             (lambda (text _)
                                               (when (buffer-live-p arcer--p2-buf)
                                                 (with-current-buffer arcer--p2-buf
                                                   (plist-put arcer--state :stash-list
                                                              (arcer--parse-stash-list text))
                                                   (arcer--render)))))))))))
    (arcer--run '("status" "--json" "--branch" "-u" "all") 'json
                (lambda (out _)
                  (puthash 'status out arcer--p2-tbl)
                  (funcall arcer--p2-done)))
    (arcer--run '("pr" "status" "--json") 'json
                (lambda (out code)
                  (puthash 'pr (when (= code 0) out) arcer--p2-tbl)
                  (funcall arcer--p2-done)))
    (arcer--run '("diff" "--no-color") nil
                (lambda (out _)
                  (puthash 'udiff out arcer--p2-tbl)
                  (funcall arcer--p2-done)))
    (arcer--run '("diff" "--no-color" "--staged") nil
                (lambda (out _)
                  (puthash 'sdiff out arcer--p2-tbl)
                  (funcall arcer--p2-done)))))

(defun arcer-refresh ()
  "Refresh the arcer status buffer."
  (interactive)
  (arcer--refresh))

;;;; Commands — file operations

(defun arcer--section-path ()
  "Return path of the arcer-file-section at point, or nil."
  (let* ((sec  (magit-current-section))
         (type (and sec (oref sec type))))
    (when (eq type 'arcer-file-section)
      (oref sec value))))  ; value holds the path (set by magit-insert-section)

(defun arcer--section-state ()
  "Return state of the arcer-file-section at point, or nil."
  (let* ((sec  (magit-current-section))
         (type (and sec (oref sec type))))
    (when (eq type 'arcer-file-section)
      (oref sec state))))

(defvar-local arcer--root nil
  "Root directory of the arc working tree for this buffer.")

(defun arcer--root ()
  "Return the arc root for this buffer, detecting it if needed."
  (or arcer--root
      (setq arcer--root
            (string-trim
             (with-output-to-string
               (call-process "arc" nil standard-output nil "root"))))))

(defun arcer--arc-call (&rest args)
  "Run arc ARGS synchronously from the arc root. Signal error on non-zero exit."
  (let* ((default-directory (arcer--root))
         (out-buf (generate-new-buffer " *arcer-call*"))
         (code    (apply #'call-process "arc" nil out-buf nil args))
         (output  (with-current-buffer out-buf
                    (string-trim (buffer-string)))))
    (kill-buffer out-buf)
    (unless (= code 0)
      (user-error "arc %s: %s" (car args) output))))

(defun arcer-stage-file ()
  "Stage the file at point."
  (interactive)
  (let ((path (or (arcer--section-path) (user-error "No file at point"))))
    (arcer--arc-call "add" path)
    (message "Staged %s" path)
    (run-at-time 0 nil #'arcer-refresh)))

(defun arcer-stage-all ()
  "Stage all changes (arc add --all)."
  (interactive)
  (arcer--arc-call "add" "--all")
  (message "Staged all")
  (run-at-time 0 nil #'arcer-refresh))

(defun arcer-unstage-file ()
  "Unstage the file at point."
  (interactive)
  (let ((path  (or (arcer--section-path) (user-error "No file at point")))
        (state (arcer--section-state)))
    (unless (eq state 'staged) (user-error "File is not staged"))
    (arcer--arc-call "reset" path)
    (message "Unstaged %s" path)
    (run-at-time 0 nil #'arcer-refresh)))

(defun arcer-discard-file ()
  "Discard changes to the file at point."
  (interactive)
  (let ((path  (or (arcer--section-path) (user-error "No file at point")))
        (state (arcer--section-state)))
    (pcase state
      ('untracked
       (when (yes-or-no-p (format "Delete untracked file '%s'? " path))
         (delete-file path)
         (run-at-time 0 nil #'arcer-refresh)))
      ((or 'unstaged 'staged)
       (when (yes-or-no-p (format "Discard changes in '%s'? " path))
         (arcer--arc-call "checkout" path)
         (run-at-time 0 nil #'arcer-refresh)))
      (_ (user-error "Don't know how to discard this")))))

(defun arcer-visit-thing ()
  "Visit the thing at point (open file, or show revision)."
  (interactive)
  (let* ((sec  (magit-current-section))
         (type (and sec (oref sec type))))
    (pcase type
      ('arcer-file-section
       (let ((path (oref sec value)))
         (if current-prefix-arg
             (find-file-other-window path)
           (find-file path))))
      ('arcer-commit-section
       (arcer-show-revision (oref sec hash)))
      ('arcer-pr-section
       (browse-url (format "https://a.yandex-team.ru/review/%s"
                           (oref sec pr-id))))
      ('arcer-stash-entry-sec
       (arcer-stash-show (oref sec stash-id)))
      (_ (message "Nothing to visit here")))))

;;;; Blame

(defun arcer-blame-buffer ()
  "Run arc blame on the current buffer's file."
  (interactive)
  (let ((file (or (buffer-file-name) (user-error "Buffer is not a file"))))
    (with-current-buffer (get-buffer-create "*arcer-blame*")
      (setq buffer-read-only nil)
      (erase-buffer)
      (call-process "arc" nil t nil "blame" file)
      (ansi-color-apply-on-region (point-min) (point-max))
      (setq buffer-read-only t)
      (goto-char (point-min)))
    (pop-to-buffer "*arcer-blame*")))

;;;; Commit

(defun arcer--server-available-p ()
  "Return non-nil if the Emacs server is running and emacsclient can connect."
  (and (fboundp 'server-running-p)
       (server-running-p)
       (fboundp 'with-editor--emacsclient-online-p)
       (with-editor--emacsclient-online-p)))

;;;; Commit — buffer-based editor (no emacsclient/EDITOR needed)

(defvar-local arcer--commit-extra-args nil)
(defvar-local arcer--commit-transient-args nil)

(defun arcer--commit-open-buffer (initial-msg extra-args)
  "Open a commit-message buffer pre-filled with INITIAL-MSG."
  (arcer--kill-pending)
  (let ((buf (get-buffer-create "*arcer-commit*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert (or initial-msg ""))
      (goto-char (point-max))
      (unless (bolp) (insert "\n"))
      (insert "# C-c C-c to commit, C-c C-k to cancel.\n"
              "# Lines starting with '#' are ignored.\n")
      (goto-char (point-min))
      (arcer-commit-msg-mode)
      (setq arcer--commit-extra-args   extra-args
            arcer--commit-transient-args (transient-args 'arcer-commit)))
    (pop-to-buffer buf)))

(defun arcer--head-message ()
  "Return the HEAD commit message, or nil."
  (let ((out (with-output-to-string
               (call-process "arc" nil standard-output nil
                             "log" "--json" "-n1" "HEAD"))))
    (condition-case nil
        (let* ((commits (json-parse-string out :object-type 'alist :array-type 'list))
               (first   (car commits)))
          (map-elt first 'message))
      (error nil))))

(defun arcer--with-editor-commit (&rest arc-args)
  "Run arc commit ARC-ARGS via with-editor (emacsclient opens COMMIT_EDITMSG)."
  (arcer--kill-pending)
  (with-editor
    (arcer--run arc-args nil
               (lambda (_ code)
                 (when (= code 0)
                   (when-let ((buf (get-buffer "*arcer-status*")))
                     (with-current-buffer buf (arcer--refresh))))))))

(defun arcer-commit-create ()
  "Commit: use emacsclient if server is up, else open an in-Emacs buffer."
  (interactive)
  (if (arcer--server-available-p)
      (arcer--with-editor-commit "commit")
    (arcer--commit-open-buffer "" nil)))

(defun arcer-commit-extend ()
  "Amend HEAD without editing the message."
  (interactive)
  (arcer--kill-pending)
  (arcer--arc-call "commit" "--amend" "--no-edit")
  (message "Amended HEAD (no edit)")
  (run-at-time 0 nil #'arcer-refresh))

(defun arcer-commit-amend ()
  "Amend: use emacsclient if server is up, else open buffer with HEAD message."
  (interactive)
  (if (arcer--server-available-p)
      (arcer--with-editor-commit "commit" "--amend")
    (arcer--commit-open-buffer (or (arcer--head-message) "") '("--amend"))))

;; Commit-message minor mode

(define-derived-mode arcer-commit-msg-mode text-mode "Arcer-Commit"
  "Mode for editing arc commit messages."
  (setq-local header-line-format
              (substitute-command-keys
               " \\[arcer-commit-msg-finish]: commit  \\[arcer-commit-msg-cancel]: cancel"))
  (auto-fill-mode 1)
  (setq fill-column 72))

(define-key arcer-commit-msg-mode-map (kbd "C-c C-c") #'arcer-commit-msg-finish)
(define-key arcer-commit-msg-mode-map (kbd "C-c C-k") #'arcer-commit-msg-cancel)

(defun arcer-commit-msg-finish ()
  "Commit using the message in the current buffer."
  (interactive)
  (let* ((raw  (buffer-string))
         (msg  (string-trim
                (replace-regexp-in-string "^#[^\n]*\n?" "" raw)))
         (extra  arcer--commit-extra-args)
         (targs  arcer--commit-transient-args))
    (when (string-empty-p msg)
      (user-error "Commit message is empty"))
    (let ((buf (current-buffer)))
      (quit-window t)
      (let ((default-directory (arcer--root)))
        (apply #'arcer--arc-call
               (flatten-list (list "commit" "-m" msg extra targs))))
      (message "Committed.")
      (run-at-time 0 nil #'arcer-refresh))))

(defun arcer-commit-msg-cancel ()
  "Abort commit."
  (interactive)
  (quit-window t)
  (message "Commit cancelled."))

(transient-define-prefix arcer-commit ()
  "Arc commit."
  ["Arguments"
   ("-a" "Stage all changed files" "--all")
   ("-n" "Skip pre-commit hooks"   "--no-verify")]
  [["Create"
    ("c" "Commit"           arcer-commit-create)]
   ["Edit HEAD"
    ("e" "Extend (no edit)" arcer-commit-extend)
    ("a" "Amend"            arcer-commit-amend)
    ("x" "Reset HEAD"       arcer-reset-head)]])

;;;; Push

(defun arcer-do-push ()
  "Run arc push with transient args."
  (interactive)
  (let ((args (transient-args 'arcer-push-dispatch)))
    (message "arc push ...")
    (arcer--run (flatten-list (list "push" args)) nil
               (lambda (_ code)
                 (if (= code 0)
                     (progn (message "arc push done")
                            (when-let ((buf (get-buffer "*arcer-status*")))
                              (with-current-buffer buf (arcer--refresh))))
                   (message "arc push failed"))))))

(transient-define-prefix arcer-push-dispatch ()
  "Arc push."
  ["Options"
   ("-f" "Force push"      "--force")
   ("-p" "Publish PR diff" "--publish")
   ("-nv" "No verify"     "--no-verify")]
  [("p" "Push" arcer-do-push)])

;;;; Pull / Rebase

(defun arcer-do-pull ()
  "Run arc pull."
  (interactive)
  (message "arc pull ...")
  (arcer--run '("pull") nil
              (lambda (_ code)
                (if (= code 0)
                    (progn (message "arc pull done")
                           (when-let ((buf (get-buffer "*arcer-status*")))
                             (with-current-buffer buf (arcer--refresh))))
                  (message "arc pull failed")))))

(defun arcer-do-rebase ()
  "Run arc rebase --onto BRANCH (default: trunk)."
  (interactive)
  (let* ((branches (or (arcer--branch-list) '()))
         (cands    (cl-union '("trunk") branches :test #'equal))
         (branch   (completing-read "Rebase --onto: " cands nil nil nil nil "trunk")))
    (message "arc rebase --onto %s ..." branch)
    (arcer--run (list "rebase" "--onto" branch) nil
                (lambda (_ code)
                  (if (= code 0)
                      (progn (message "arc rebase done")
                             (when-let ((buf (get-buffer "*arcer-status*")))
                               (with-current-buffer buf (arcer--refresh))))
                    (message "arc rebase failed"))))))

(transient-define-prefix arcer-pull-dispatch ()
  "Arc pull / rebase."
  [("F" "Pull"          arcer-do-pull)
   ("r" "Rebase --onto" arcer-do-rebase)])

;;;; Submit

(defun arcer-do-submit ()
  "Run arc submit."
  (interactive)
  (with-editor
    (arcer--run (flatten-list (list "submit" (transient-args 'arcer-submit-dispatch)))
               nil
               (lambda (_ code)
                 (when (= code 0)
                   (when-let ((buf (get-buffer "*arcer-status*")))
                     (with-current-buffer buf (arcer--refresh))))))))

(transient-define-prefix arcer-submit-dispatch ()
  "Arc submit."
  ["Options"
   ("-A"  "Auto (publish + automerge)" "--auto")
   ("-ne" "No edit"                    "--no-edit")
   ("-nr" "No code review check"       "--no-code-review")]
  [("s" "Submit" arcer-do-submit)])

;;;; PR

;;;; PR message buffer (buffer-based editor, no emacsclient required)

(defvar-local arcer--pr-extra-args nil)

(define-derived-mode arcer-pr-msg-mode text-mode "Arcer-PR"
  "Mode for writing arc PR title and description."
  (setq-local header-line-format
              (substitute-command-keys
               " \\[arcer-pr-msg-finish]: create PR  \\[arcer-pr-msg-cancel]: cancel"))
  (auto-fill-mode 1)
  (setq fill-column 72))

(define-key arcer-pr-msg-mode-map (kbd "C-c C-c") #'arcer-pr-msg-finish)
(define-key arcer-pr-msg-mode-map (kbd "C-c C-k") #'arcer-pr-msg-cancel)

(defun arcer--pr-open-buffer (extra-args)
  "Open a PR title/description buffer pre-filled with instructions."
  (let ((buf (get-buffer-create "*arcer-pr*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert "# First line: PR title\n"
              "# Remaining lines: PR description (optional)\n"
              "# Lines starting with '#' are ignored.\n")
      (goto-char (point-min))
      (arcer-pr-msg-mode)
      (setq arcer--pr-extra-args extra-args))
    (pop-to-buffer buf)))

(defun arcer-pr-msg-finish ()
  "Create PR using the title/description in the current buffer."
  (interactive)
  (let* ((raw   (buffer-string))
         (msg   (string-trim (replace-regexp-in-string "^#[^\n]*\n?" "" raw)))
         (lines (split-string msg "\n" t))
         (title (car lines))
         (desc  (string-trim (mapconcat #'identity (cdr lines) "\n")))
         (extra arcer--pr-extra-args))
    (when (or (null title) (string-empty-p title))
      (user-error "PR title is empty"))
    (quit-window t)
    (arcer--run (flatten-list
                 (list "pr" "create" "--push"
                       "--title" title
                       (unless (string-empty-p desc) (list "--description" desc))
                       extra))
                nil
                (lambda (_ code)
                  (if (= code 0)
                      (progn
                        (message "PR created.")
                        (when-let ((buf (get-buffer "*arcer-status*")))
                          (with-current-buffer buf (arcer--refresh))))
                    (message "arc pr create failed"))))))

(defun arcer-pr-msg-cancel ()
  "Cancel PR creation."
  (interactive)
  (quit-window t)
  (message "PR creation cancelled."))

(defun arcer-pr-create ()
  "Create a PR with arc pr create --push."
  (interactive)
  (let ((extra-args (transient-args 'arcer-pr-dispatch)))
    (if (arcer--server-available-p)
        (with-editor
          (arcer--run (flatten-list (list "pr" "create" "--push" extra-args))
                      nil
                      (lambda (_ code)
                        (when (= code 0)
                          (when-let ((buf (get-buffer "*arcer-status*")))
                            (with-current-buffer buf (arcer--refresh)))))))
      (arcer--pr-open-buffer extra-args))))

(defun arcer-pr-checkout-out ()
  "Checkout an outgoing pull request."
  (interactive)
  (let* ((prs   (arcer--run-sync '("pr" "list" "--json" "--out") 'json))
         (cands (seq-map (lambda (pr)
                           (format "%s | %s" (map-elt pr 'id) (map-elt pr 'summary)))
                         (or prs [])))
         (sel   (completing-read "Outgoing PR: " cands nil t))
         (id    (car (string-split sel "|"))))
    (arcer--run-sync (list "pr" "checkout" (string-trim id)))
    (arcer--refresh)))

(defun arcer-pr-checkout-in ()
  "Checkout an incoming pull request."
  (interactive)
  (let* ((prs   (arcer--run-sync '("pr" "list" "--json" "--in") 'json))
         (cands (seq-map (lambda (pr)
                           (format "%s | %s" (map-elt pr 'id) (map-elt pr 'summary)))
                         (or prs [])))
         (sel   (completing-read "Incoming PR: " cands nil t))
         (id    (car (string-split sel "|"))))
    (arcer--run-sync (list "pr" "checkout" (string-trim id)))
    (arcer--refresh)))

(transient-define-prefix arcer-pr-dispatch ()
  "Arc pull-request operations."
  ["Options"
   ("-nc" "No commit messages in description" "--no-commits")
   ("-ne" "No edit"                           "--no-edit")
   ("-nr" "No code review"                    "--no-code-review")]
  [("c" "Create PR (--push)"        arcer-pr-create)
   ("o" "Checkout outgoing PR"       arcer-pr-checkout-out)
   ("i" "Checkout incoming PR"       arcer-pr-checkout-in)])

;;;; Reset

(defun arcer-reset-to-commit ()
  "Reset current branch to the commit at point (soft or hard)."
  (interactive)
  (let* ((sec   (magit-current-section))
         (hash  (if (arcer-commit-section-p sec)
                    (oref sec hash)
                  (user-error "No commit at point")))
         (short (substring hash 0 (min 8 (length hash))))
         (mode  (completing-read (format "Reset to %s [soft/hard]: " short)
                                 '("soft" "hard") nil t)))
    (when (or (string= mode "soft")
              (yes-or-no-p (format "Hard reset to %s? All uncommitted changes will be lost! " short)))
      (arcer--arc-call "reset" (concat "--" mode) (concat hash "~1"))
      (message "Reset --%s to %s" mode short)
      (run-at-time 0 nil #'arcer-refresh))))

(defun arcer-reset-head ()
  "Reset working tree/index to HEAD: soft keeps staged changes, hard discards all."
  (interactive)
  (let ((mode (completing-read "Reset HEAD [soft/hard]: " '("soft" "hard") nil t)))
    (when (or (string= mode "soft")
              (yes-or-no-p "Hard reset to HEAD? All uncommitted changes will be lost! "))
      (arcer--arc-call "reset" (concat "--" mode) "HEAD")
      (message "Reset --%s HEAD" mode)
      (run-at-time 0 nil #'arcer-refresh))))

;;;; Branch

(defun arcer--branch-list ()
  "Return list of local branch names."
  (let ((out (arcer--run-sync '("branch") nil)))
    (when (stringp out)
      (seq-filter #'identity
        (mapcar (lambda (line)
                  (string-trim (replace-regexp-in-string "^[* ]+" "" line)))
                (split-string out "\n" t))))))

(defun arcer-branch-checkout ()
  "Switch to a local branch."
  (interactive)
  (let* ((branches (or (arcer--branch-list) (user-error "No branches found")))
         (sel (completing-read "Branch: " branches nil t)))
    (arcer--arc-call "checkout" sel)
    (message "Switched to %s" sel)
    (run-at-time 0 nil #'arcer-refresh)))

(defun arcer-branch-create ()
  "Create and switch to a new branch."
  (interactive)
  (let ((name (read-string "Branch name: ")))
    (when (string-empty-p name) (user-error "Branch name is empty"))
    (arcer--arc-call "checkout" "-b" name)
    (message "Created and switched to %s" name)
    (run-at-time 0 nil #'arcer-refresh)))

(defun arcer-branch-delete ()
  "Delete a local branch."
  (interactive)
  (let* ((branches (or (arcer--branch-list) (user-error "No branches found")))
         (sel (completing-read "Delete branch: " branches nil t)))
    (when (yes-or-no-p (format "Delete branch '%s'? " sel))
      (arcer--arc-call "branch" "-d" sel)
      (message "Deleted %s" sel)
      (run-at-time 0 nil #'arcer-refresh))))

(transient-define-prefix arcer-branch-dispatch ()
  "Arc branch operations."
  [("b" "Checkout branch" arcer-branch-checkout)
   ("n" "New branch"      arcer-branch-create)
   ("d" "Delete branch"   arcer-branch-delete)])

;;;; Stash

(defun arcer--select-stash (prompt)
  "Select a stash entry from the current buffer state via completing-read.
Returns the full stash id."
  (let* ((entries (or (plist-get arcer--state :stash-list)
                      (user-error "No stash entries")))
         (cands (mapcar (lambda (e)
                          (let ((id (or (map-elt e 'id) "")))
                            (cons (format "%s %s"
                                          (substring id 0 (min 8 (length id)))
                                          (or (map-elt e 'display) ""))
                                  id)))
                        entries))
         (sel (completing-read prompt (mapcar #'car cands) nil t)))
    (cdr (assoc sel cands))))

(defun arcer-stash-push ()
  "Stash current changes, optionally with a message."
  (interactive)
  (let ((msg (read-string "Stash message (blank for none): ")))
    (if (string-empty-p msg)
        (arcer--arc-call "stash" "push")
      (arcer--arc-call "stash" "push" "-m" msg))
    (message "Changes stashed.")
    (run-at-time 0 nil #'arcer-refresh)))

(defun arcer-stash-pop ()
  "Pop the stash entry at point, or select one via completing-read."
  (interactive)
  (let* ((sec  (magit-current-section))
         (id   (if (eq (and sec (oref sec type)) 'arcer-stash-entry-sec)
                   (oref sec stash-id)
                 (arcer--select-stash "Pop stash: "))))
    (arcer--arc-call "stash" "pop" id)
    (message "Popped stash %s" (substring id 0 (min 8 (length id))))
    (run-at-time 0 nil #'arcer-refresh)))

(defun arcer-stash-drop ()
  "Drop the stash entry at point, or select one via completing-read."
  (interactive)
  (let* ((sec  (magit-current-section))
         (id   (if (eq (and sec (oref sec type)) 'arcer-stash-entry-sec)
                   (oref sec stash-id)
                 (arcer--select-stash "Drop stash: "))))
    (when (yes-or-no-p (format "Drop stash '%s'? "
                               (substring id 0 (min 8 (length id)))))
      (arcer--arc-call "stash" "drop" id)
      (message "Dropped stash %s" (substring id 0 (min 8 (length id))))
      (run-at-time 0 nil #'arcer-refresh))))

(defun arcer-stash-show (stash-id)
  "Show diff of STASH-ID in a side buffer."
  (interactive "sStash ID: ")
  (let* ((short (substring stash-id 0 (min 8 (length stash-id))))
         (buf   (get-buffer-create (format "*arcer-stash: %s*" short))))
    (arcer--run `("stash" "show" ,stash-id) nil
                (lambda (diff _)
                  (with-current-buffer buf
                    (let ((inhibit-read-only t))
                      (erase-buffer)
                      (arcer-revision-mode)
                      (magit-insert-section (arcer-root-section)
                        (magit-insert-heading (format "Stash %s" short))
                        (let ((diffs (arcer--parse-diffs diff)))
                          (if diffs
                              (dolist (d diffs)
                                (magit-insert-section (arcer-file-section (car d))
                                  (oset magit-insert-section--current path (car d))
                                  (magit-insert-heading (propertize (car d) 'face 'bold))
                                  (arcer--insert-diff-body (concat (cdr d) "\n"))))
                            (insert "No diff available.\n"))))
                      (goto-char (point-min))))
                  (switch-to-buffer-other-window buf)))))

(defun arcer-discard-or-drop ()
  "Discard file changes at point, or drop stash entry at point."
  (interactive)
  (let* ((sec  (magit-current-section))
         (type (and sec (oref sec type))))
    (if (eq type 'arcer-stash-entry-sec)
        (arcer-stash-drop)
      (arcer-discard-file))))

(transient-define-prefix arcer-stash-dispatch ()
  "Arc stash operations."
  [("z" "Push stash"  arcer-stash-push)
   ("p" "Pop stash"   arcer-stash-pop)
   ("d" "Drop stash"  arcer-stash-drop)])

;;;; Dispatch

(transient-define-prefix arcer-dispatch ()
  "Arc command dispatcher."
  [["Arc"
    ("g" "Refresh"  arcer-refresh)
    ("c" "Commit"   arcer-commit)
    ("l" "Log"      arcer-log)
    ("X" "Reset to commit (soft/hard)" arcer-reset-to-commit)
    ("H" "Reset HEAD (soft/hard)"     arcer-reset-head)
    ("b" "Branch"   arcer-branch-dispatch)
    ("z" "Stash"    arcer-stash-dispatch)
    ("P" "Push"        arcer-push-dispatch)
    ("F" "Pull/Rebase" arcer-pull-dispatch)
    ("r" "Rebase --onto" arcer-do-rebase)
    ("p" "PR"          arcer-pr-dispatch)]])

;;;; Log buffer

(defvar-local arcer-log--commits   nil)
(defvar-local arcer-log--last-hash nil)  ; oldest loaded commit hash, anchor for next page
(defvar-local arcer-log--exhausted nil)

(defun arcer--render-full-log (commits exhausted)
  (with-current-buffer (get-buffer-create "*arcer-log*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (magit-insert-section (arcer-root-section)
        (magit-insert-heading "Arc log (HEAD →)")
        (dolist (commit commits)
          (let* ((hash   (or (map-elt commit 'commit) ""))
                 (msg    (car (string-lines (or (map-elt commit 'message) ""))))
                 (author (or (map-elt commit 'author) ""))
                 (short  (if (> (length hash) 8) (substring hash 0 8) hash)))
            (magit-insert-section (arcer-commit-section hash)
              (oset magit-insert-section--current hash hash)
              (insert (propertize short 'face 'arcer-dimmed))
              (insert " ")
              (insert (propertize (string-pad author 16) 'face 'arcer-log-author))
              (insert " " msg "\n"))))
        (unless exhausted
          (magit-insert-section (arcer-load-more-sec)
            (insert (propertize "  [Load more — M-n]\n" 'face 'arcer-dimmed))))))))

(defun arcer-log--load-page ()
  ;; Use <last-hash>~1 as anchor for next page so we don't need --skip
  (let ((range (if arcer-log--last-hash
                   (concat arcer-log--last-hash "~1")
                 "HEAD")))
    (arcer--run `("log" "--json" "-n" ,(number-to-string arcer-log-page-size) ,range)
               'json
               (lambda (new-commits _)
                 (when-let ((buf (get-buffer "*arcer-log*")))
                   (with-current-buffer buf
                     (let ((new (when (listp new-commits) new-commits)))
                       (setq arcer-log--commits  (append arcer-log--commits new))
                       (setq arcer-log--last-hash
                             (when (and (listp new) new)
                               (map-elt (car (last new)) 'commit)))
                       (setq arcer-log--exhausted (< (length new) arcer-log-page-size))
                       (arcer--render-full-log arcer-log--commits arcer-log--exhausted))))))))

(defun arcer-log-load-more ()
  "Load next page of commits in the log buffer."
  (interactive)
  (unless arcer-log--exhausted
    (arcer-log--load-page)))

(defun arcer-log ()
  "Open the Arc log buffer in a right side window."
  (interactive)
  (let ((buf (get-buffer-create "*arcer-log*")))
    (display-buffer buf `((display-buffer-in-side-window)
                          (side . right)
                          (slot . 0)
                          (window-width . ,arcer-log-buffer-width)))
    (with-current-buffer buf
      (unless (derived-mode-p 'arcer-log-mode)
        (arcer-log-mode))
      (when (null arcer-log--commits)
        (arcer-log--load-page)))))

;;;; Revision view

(defun arcer-show-revision-at-point ()
  "Show revision for the commit section at point."
  (interactive)
  (let ((sec (magit-current-section)))
    (if (arcer-commit-section-p sec)
        (arcer-show-revision (oref sec hash))
      (message "No commit at point"))))

(defun arcer-show-revision (hash)
  "Show a revision buffer for HASH."
  (interactive "sRevision: ")
  (let ((buf (get-buffer-create (format "*arcer-rev: %s*"
                                        (substring hash 0 (min 8 (length hash))))))
        (meta-result nil)
        (diff-result nil)
        (done 0))
    (cl-flet ((maybe-render ()
                (cl-incf done)
                (when (= done 2)
                  (arcer--render-revision buf hash meta-result diff-result))))
      (arcer--run `("show" "--json" ,hash) 'json
                  (lambda (out _) (setq meta-result out) (maybe-render)))
      (arcer--run `("show" "--no-color" ,hash) nil
                  (lambda (out _) (setq diff-result out) (maybe-render))))
    (switch-to-buffer-other-window buf)))

(defun arcer--render-revision (buf hash meta-result diff-result)
  (with-current-buffer buf
    (let ((inhibit-read-only t))
      (erase-buffer)
      (arcer-revision-mode)
      (magit-insert-section (arcer-root-section)
        (magit-insert-heading (format "Revision %s" (substring hash 0 (min 8 (length hash)))))
        ;; metadata
        (let* ((entries  (or meta-result []))
               (entry    (and (not (seq-empty-p entries)) (seq-first entries)))
               (commits  (and entry (map-elt entry 'commits)))
               (cdata    (and commits (not (seq-empty-p commits)) (seq-first commits))))
          (when cdata
            (let ((author  (or (map-elt cdata 'author) ""))
                  (date    (or (map-elt cdata 'date) ""))
                  (msg     (or (map-elt cdata 'message) ""))
                  (tickets-raw (map-nested-elt cdata '(attributes pr.tickets)))
                  (pr-id   (map-nested-elt cdata '(attributes pr.id))))
              (insert (string-pad "Author:" 10))
              (insert-text-button author
                                  'button-data author
                                  'action (lambda (l) (arcer--open-author l))
                                  'follow-link t)
              (insert "\n")
              (insert (string-pad "Date:" 10) date "\n")
              (when pr-id
                (insert (string-pad "PR:" 10))
                (insert-text-button pr-id
                                    'button-data (format "https://a.yandex-team.ru/review/%s" pr-id)
                                    'action #'browse-url
                                    'follow-link t)
                (insert "\n"))
              (when (and tickets-raw (not (string-empty-p tickets-raw)))
                (insert (string-pad "Tickets:" 10))
                (let ((tlist (mapcar #'string-trim (split-string tickets-raw "," t))))
                  (arcer--insert-ticket-link (car tlist))
                  (dolist (ticket (cdr tlist))
                    (insert ", ")
                    (arcer--insert-ticket-link ticket)))
                (insert "\n"))
              (insert "\n")
              (insert msg "\n\n"))))
        ;; diff
        (magit-insert-section (arcer-hunk-section)
          (magit-insert-heading "Changes:")
          (let ((diffs (arcer--parse-diffs diff-result)))
            (if diffs
                (dolist (d diffs)
                  (magit-insert-section (arcer-file-section (car d) t)
                    (oset magit-insert-section--current path (car d))
                    (magit-insert-heading (propertize (car d) 'face 'bold))
                    (arcer--insert-diff-body (concat (cdr d) "\n"))))
              (insert "No diff available.\n")))))
      (goto-char (point-min)))))

;;;; with-editor integration for arc commit messages

(defun arcer--commit-setup ()
  (when (string-match-p "/.arc/COMMIT_EDITMSG\\'" (or buffer-file-name ""))
    (with-editor-mode 1)
    (when (fboundp 'git-commit-setup-font-lock)
      (git-commit-setup-font-lock))))

(defun arcer--rebase-setup ()
  (when (string-match-p "/.arc/sequencer/arc-rebase-todo\\'" (or buffer-file-name ""))
    (with-editor-mode 1)
    (when (fboundp 'git-rebase-mode) (git-rebase-mode))))

(defun arcer--arc-editor-setup ()
  "Activate with-editor-mode for any arc-opened editor file (PR, submit, etc.)."
  (when (and buffer-file-name
             (string-match-p "/.arc/[^/]+\\'" buffer-file-name)
             (not (string-match-p "/COMMIT_EDITMSG\\'" buffer-file-name))
             (not (string-match-p "/arc-rebase-todo\\'" buffer-file-name)))
    (with-editor-mode 1)))

(add-hook 'find-file-hook #'arcer--commit-setup)
(add-hook 'find-file-hook #'arcer--rebase-setup)
(add-hook 'find-file-hook #'arcer--arc-editor-setup)

(advice-add 'git-commit-setup-check-buffer :before-until
            (lambda () (string-match-p "/.arc/" (or buffer-file-name ""))))

;;;; Major modes

(defvar-keymap arcer-status-mode-map
  :parent magit-section-mode-map
  "g"           #'arcer-refresh
  "q"           #'quit-window
  "s"           #'arcer-stage-file
  "u"           #'arcer-unstage-file
  "k"           #'arcer-discard-or-drop
  "<return>"    #'arcer-visit-thing
  "<tab>"       #'magit-section-toggle
  "n"           #'magit-section-forward
  "p"           #'magit-section-backward
  "l"           #'arcer-log
  "b"           #'arcer-branch-dispatch
  "z"           #'arcer-stash-dispatch
  "c"           #'arcer-commit
  "P"           #'arcer-push-dispatch
  "F"           #'arcer-pull-dispatch
  "r"           #'arcer-do-rebase
  "S"           #'arcer-stage-all
  "W"           #'arcer-submit-dispatch
  "X"           #'arcer-reset-to-commit
  "H"           #'arcer-reset-head
  "a"           #'arcer-pr-dispatch
  "?"           #'arcer-dispatch)

(define-derived-mode arcer-status-mode magit-section-mode "Arcer"
  "Major mode for the arcer status buffer."
  (setq truncate-lines t)
  (hl-line-mode 1))

(defvar-keymap arcer-log-mode-map
  :parent magit-section-mode-map
  "q"        #'quit-window
  "g"        #'arcer-log-load-more
  "M-n"      #'arcer-log-load-more
  "<return>" #'arcer-show-revision-at-point
  "X"        #'arcer-reset-to-commit)

(define-derived-mode arcer-log-mode magit-section-mode "Arcer-Log"
  "Major mode for the arcer log buffer."
  (setq truncate-lines t))

(defvar-keymap arcer-revision-mode-map
  :parent magit-section-mode-map
  "q"     #'quit-window
  "<tab>" #'magit-section-toggle)

(define-derived-mode arcer-revision-mode magit-section-mode "Arcer-Rev"
  "Major mode for the arcer revision view."
  (setq truncate-lines t))

;;;; Evil state

(with-eval-after-load 'evil
  (evil-set-initial-state 'arcer-status-mode   'emacs)
  (evil-set-initial-state 'arcer-log-mode      'emacs)
  (evil-set-initial-state 'arcer-revision-mode 'emacs))

;;;; Entry point

;;;###autoload
(defun arcer-status ()
  "Open the arcer status buffer."
  (interactive)
  (let ((buf (get-buffer-create "*arcer-status*")))
    (with-current-buffer buf
      (unless (derived-mode-p 'arcer-status-mode)
        (arcer-status-mode)))
    (switch-to-buffer buf)
    (with-current-buffer buf
      (arcer--refresh))))


(provide 'arcer)
;;; arcer.el ends here
