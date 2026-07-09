;; Some bindings

(defun my/service-buffer-p (buf)
  "Return non-nil if BUF is a service buffer to preserve across project switches."
  (let ((name (buffer-name buf)))
    (or (minibufferp buf)
        (member name '("*Messages*" "*scratch*" "*dashboard*"))
        (string-match-p
         "\\`[[:space:]]*\\*\\(lsp\\|arcer\\|Codeenv\\|Help\\|Backtrace\\|Warnings\\|Async\\)"
         name))))

(defun my/kill-all-project-buffers ()
  "Kill all non-service buffers (file-visiting, dired, vterm, etc.)."
  (let ((kill-buffer-query-functions nil))
    (dolist (buf (buffer-list))
      (unless (my/service-buffer-p buf)
        (ignore-errors (kill-buffer buf))))))

(defun my/switch-project ()
  "Kill non-service buffers, then switch project."
  (interactive)
  (my/kill-all-project-buffers)
  (projectile-switch-project))

(with-eval-after-load 'evil-maps
  ;; Отвязываем K от evil-lookup, чтобы не конфликтовал с LSP
  (define-key evil-normal-state-map (kbd "K") nil)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-define-key 'normal 'global (kbd "<leader>u") 'undo-tree-visualize)
  (evil-define-key 'normal 'global (kbd "u") 'undo-tree-undo)
  (evil-define-key 'normal 'global (kbd "<leader>pv") 'dired-jump)
  (evil-define-key 'normal 'global (kbd "<leader>pf") #'my/find-file-with-preview)
  (evil-define-key 'normal 'global (kbd "<leader>pb") #'consult-project-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>pp") #'my/switch-project)
  (evil-define-key 'normal 'global (kbd "<leader>ps") #'consult-ripgrep)
  (evil-define-key 'normal 'global (kbd "<leader>p!") 'projectile-run-async-shell-command-in-root)
  (evil-define-key 'normal 'global (kbd "<leader>pr") #'my/ya-codeenv-select)
  (evil-define-key 'normal 'global (kbd "<leader>!") #'my/shell-command-on-buffer)

  (evil-define-key 'normal 'global (kbd "<leader>cc") 'projectile-compile-project)

  (evil-define-key 'normal 'global (kbd "<leader>er") #'my/reload-config)
  (evil-define-key 'normal 'global (kbd "<leader>qq") #'my/quit-emacs)

  (evil-define-key 'normal 'global (kbd "<leader>gg") #'my/vcs-status)
  (evil-define-key 'normal 'global (kbd "<leader>gb") #'arcer-blame-buffer)

  (define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-insert-state-map (kbd "C-u")
              (lambda ()
                (interactive)
                (evil-delete (point-at-bol) (point))))

)

;; В dired SPC может перехватываться keymap'ом раньше leader — освобождаем
(with-eval-after-load 'dired
  (evil-define-key 'normal dired-mode-map (kbd "SPC") nil))

;; K только в prog-mode буферах (nil везде остальном — задано выше)
(evil-define-key 'normal prog-mode-map (kbd "K") #'lsp-ui-doc-glance)

;; --- LSP биндинги (как в nvim lsp.lua) ---
(with-eval-after-load 'lsp-mode
  (evil-define-key 'normal lsp-mode-map
    (kbd "<leader>vca") #'lsp-execute-code-action
    (kbd "<leader>vrn") #'lsp-rename
    (kbd "<leader>vrr") #'lsp-find-references
    (kbd "<leader>f")   #'lsp-format-buffer
    (kbd "gd")          #'lsp-find-definition
    (kbd "[d")          #'flymake-goto-prev-error
    (kbd "]d")          #'flymake-goto-next-error))

;; --- company (автодополнение, как blink.cmp в nvim) ---
(with-eval-after-load 'company
  (define-key company-active-map (kbd "C-n")      #'company-select-next)
  (define-key company-active-map (kbd "C-p")      #'company-select-previous)
  (define-key company-active-map (kbd "C-e")      #'company-abort)
  (define-key company-active-map (kbd "C-y")      #'company-complete-selection)
  (define-key company-active-map (kbd "TAB")      nil)
  (define-key company-active-map (kbd "<tab>")    nil)
  (define-key company-active-map (kbd "RET")      nil)
  (define-key company-active-map (kbd "<return>") nil))

(evil-define-key 'insert 'global (kbd "C-SPC") #'company-complete)

;;; --- which-key descriptions ---
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    ;; top-level prefixes
    "SPC p"     "project"
    "SPC v"     "lsp/code"
    "SPC v c"   "code..."
    "SPC v r"   "refactor"
    ;; project bindings
    "SPC p v"   "dired jump"
    "SPC p f"   "find file"
    "SPC p b"   "project buffer"
    "SPC p p"   "projectile dired"
    "SPC p s"   "ripgrep"
    "SPC p !"   "shell in root"
    "SPC p r"   "codeenv select"
    ;; misc
    "SPC u"     "undo-tree"
    "SPC !"     "shell on buffer"
    "SPC f"     "format buffer"
    ;; lsp
    "SPC e"     "emacs"
    "SPC e r"   "reload config"
    "SPC q"     "quit"
    "SPC q q"   "quit emacs"
    "SPC v c a" "code action"
    "SPC v r n" "rename"
    "SPC v r r" "references"
    "SPC g"     "arc/git"
    "SPC g g"   "vcs status"
    "SPC g b"   "arc blame"))

(defun my/vcs-status ()
  "Open arcer-status if current path contains \"arc\", magit-status otherwise."
  (interactive)
  (if (string-match-p "arc" (or buffer-file-name default-directory ""))
      (arcer-status)
    (magit-status)))

(defun my/reload-config ()
  "Перезагрузить конфигурацию Emacs (init.el и все файлы в after/)."
  (interactive)
  (load-file (expand-file-name "init.el" user-emacs-directory))
  (message "Config reloaded"))

(defun my/quit-emacs ()
  "Полностью завершить Emacs, предложив сохранить несохранённые буферы."
  (interactive)
  (save-buffers-kill-emacs))

(defun my/shell-command-on-buffer ()
  "Запустить bash-команду над текущим файлом и перечитать буфер.
% в команде заменяется на путь к файлу; если % нет — файл добавляется в конец."
  (interactive)
  (let* ((file (buffer-file-name)))
    (unless file (user-error "Буфер не связан с файлом"))
    (let* ((cmd (read-shell-command (format "Shell [%%=%s]: " (file-name-nondirectory file))))
           (full-cmd (if (string-match-p "%" cmd)
                         (replace-regexp-in-string "%" (shell-quote-argument file) cmd)
                       (concat cmd " " (shell-quote-argument file)))))
      (shell-command full-cmd)
      (revert-buffer nil t t))))
