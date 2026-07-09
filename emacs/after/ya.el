(defun my/ya-find-ssh ()
  "Generate TRAMP connection from 'ya tool codeenv env list' output."
  (interactive)
  (let* ((cmd "ya tool codeenv env list | grep 'Host:' | cut -d '|' -f4 | awk '{print $2}'")
         (host (string-trim (shell-command-to-string cmd)))

         (path-cmd "ya tool codeenv env list | grep 'Paths:' | cut -d '|' -f4 | awk '{print $2}'")
         (path (string-trim (shell-command-to-string path-cmd))))

    (if (and host (> (length host) 0))
        (let* ((user "trumpov") ; Ваше имя пользователя
               (tramp-path (format "/ssh:%s@%s:~/arcadia/%s" user host path)))
          (message "Opening TRAMP connection: %s" tramp-path)
          (find-file tramp-path))
      (message "Could not find host or path. Is 'ya tool' configured?"))))

;; --- codeenv selection buffer ---

(defface my/codeenv-header-face
  '((t :weight bold :inherit font-lock-function-name-face))
  "Face for the codeenv entry name/status header line.")

(defface my/codeenv-key-face
  '((t :inherit font-lock-keyword-face))
  "Face for codeenv field labels.")

(defface my/codeenv-divider-face
  '((t :inherit shadow))
  "Face for codeenv block dividers.")

(defvar-local my/codeenv--entries nil)
(defvar-local my/codeenv--current-idx 0)
(defvar-local my/codeenv--markers nil)
(defvar-local my/codeenv--overlay nil)

(defun my/ya--parse-codeenv-list (output)
  "Parse OUTPUT of `ya tool codeenv env list' into a list of alists."
  (let (entries current)
    (dolist (line (split-string output "\n"))
      (cond
       ((string-match-p "^[- ]*\\+[- ]*\\+[- ]*\\+" line)
        (when (alist-get 'host current)
          (push (nreverse current) entries))
        (setq current nil))
       ((string-match-p "|" line)
        (let* ((cols (mapcar #'string-trim (split-string line "|")))
               (id   (nth 0 cols))
               (name (nth 1 cols))
               (stat (nth 2 cols))
               (desc (or (nth 3 cols) "")))
          (when (and id (> (length id) 0))
            (push (cons 'id id) current)
            (push (cons 'name name) current)
            (push (cons 'status stat) current))
          (when (string-match "^\\([^:]+\\): *\\(.*\\)$" desc)
            (let ((key (intern (downcase (replace-regexp-in-string " " "-" (match-string 1 desc)))))
                  (val (string-trim (match-string 2 desc))))
              (push (cons key val) current)))))))
    (nreverse entries)))

(defun my/codeenv--render ()
  "Render `my/codeenv--entries' into the current buffer."
  (let ((inhibit-read-only t)
        (sep (make-string (max 60 (- (window-width) 2)) ?─)))
    (erase-buffer)
    (setq my/codeenv--markers nil)
    ;; header — ensures the first block never starts at position 1,
    ;; so its highlight looks identical to all other blocks
    (insert (propertize "  Codeenv Environments" 'face '(:weight bold))
            (propertize "   j/k — navigate · RET — connect · q — quit\n\n"
                        'face 'shadow))
    (dolist (env my/codeenv--entries)
      (push (point-marker) my/codeenv--markers)
      (insert (propertize sep 'face 'my/codeenv-divider-face) "\n")
      (insert (propertize
               (format "  %-40s [%s]\n"
                       (alist-get 'name env "")
                       (alist-get 'status env ""))
               'face 'my/codeenv-header-face))
      (insert (propertize sep 'face 'my/codeenv-divider-face) "\n")
      (dolist (field '((project        . "Project")
                       (configuration  . "Configuration")
                       (host           . "Host")
                       (paths          . "Paths")
                       (branch         . "Branch")
                       (supported-ides . "Supported IDEs")
                       (commit         . "Commit")
                       (created        . "Created")
                       (last-usage     . "Last Usage")
                       (resources      . "Resources")))
        (when-let ((val (alist-get (car field) env)))
          (insert (propertize (format "  %-18s" (concat (cdr field) ":"))
                              'face 'my/codeenv-key-face)
                  val "\n")))
      (insert "\n"))
    (setq my/codeenv--markers (nreverse my/codeenv--markers))))

(defun my/codeenv--highlight-current ()
  "Highlight the currently selected entry block."
  (when my/codeenv--overlay
    (delete-overlay my/codeenv--overlay))
  (let* ((idx   my/codeenv--current-idx)
         (start (marker-position (nth idx my/codeenv--markers)))
         (end   (if (< (1+ idx) (length my/codeenv--markers))
                    (marker-position (nth (1+ idx) my/codeenv--markers))
                  (point-max))))
    (setq my/codeenv--overlay (make-overlay start end))
    (overlay-put my/codeenv--overlay 'face 'highlight)
    (goto-char start)
    (let ((win (get-buffer-window (current-buffer))))
      (when win
        (with-selected-window win
          (recenter 2))))))

(defun my/codeenv-next ()
  "Move selection to the next codeenv entry."
  (interactive)
  (when (< my/codeenv--current-idx (1- (length my/codeenv--entries)))
    (cl-incf my/codeenv--current-idx)
    (my/codeenv--highlight-current)))

(defun my/codeenv-prev ()
  "Move selection to the previous codeenv entry."
  (interactive)
  (when (> my/codeenv--current-idx 0)
    (cl-decf my/codeenv--current-idx)
    (my/codeenv--highlight-current)))

(defun my/codeenv-connect-at-point ()
  "Connect to the currently selected codeenv environment via TRAMP."
  (interactive)
  (let* ((env  (nth my/codeenv--current-idx my/codeenv--entries))
         (host (alist-get 'host env))
         (path (or (alist-get 'paths env) ""))
         (user "trumpov")
         (tramp-path (format "/ssh:%s@%s:~/arcadia/%s" user host path)))
    (quit-window)
    (message "Opening: %s" tramp-path)
    (find-file tramp-path)))

(define-derived-mode my/codeenv-list-mode special-mode "Codeenv"
  "Major mode for selecting a codeenv environment."
  (setq-local truncate-lines t)
  (setq-local cursor-type nil)
  ;; Emacs bindings (fallback)
  (define-key my/codeenv-list-mode-map (kbd "RET") #'my/codeenv-connect-at-point)
  (define-key my/codeenv-list-mode-map (kbd "q")   #'quit-window)
  (define-key my/codeenv-list-mode-map (kbd "n")   #'my/codeenv-next)
  (define-key my/codeenv-list-mode-map (kbd "p")   #'my/codeenv-prev)
  ;; Evil bindings — must override evil's j/k which intercept before mode-map
  (when (fboundp 'evil-define-key*)
    (evil-define-key* '(normal motion) my/codeenv-list-mode-map
      "j"         #'my/codeenv-next
      "k"         #'my/codeenv-prev
      (kbd "RET") #'my/codeenv-connect-at-point
      "q"         #'quit-window)))

(defun my/ya-codeenv-select ()
  "Show all running codeenv environments and connect to the selected one via TRAMP."
  (interactive)
  (let* ((output (shell-command-to-string "ya tool codeenv env list"))
         (envs   (my/ya--parse-codeenv-list output)))
    (if (null envs)
        (message "No running codeenv environments found.")
      (let ((buf (get-buffer-create "*Codeenv Environments*")))
        (with-current-buffer buf
          (my/codeenv-list-mode)
          (setq my/codeenv--entries    envs
                my/codeenv--current-idx 0
                my/codeenv--overlay    nil)
          (my/codeenv--render)
          (my/codeenv--highlight-current))
        (pop-to-buffer-same-window buf)
        (delete-other-windows)))))
