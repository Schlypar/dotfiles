;;; workspaces — tab-bar tabs + vterm

(use-package vterm
  :ensure t
  :custom
  (vterm-max-scrollback 10000)
  (vterm-shell (or (executable-find "zsh") "/bin/zsh"))
  :config
  (add-to-list 'evil-emacs-state-modes 'vterm-mode)
  (define-key vterm-mode-map (kbd "M-<left>")  #'tab-bar-switch-to-prev-tab)
  (define-key vterm-mode-map (kbd "M-<right>") #'tab-bar-switch-to-next-tab))

(defun my/tab-new-default ()
  "Open dired at project root, or current directory if not in a project."
  (dired (if (projectile-project-p)
             (projectile-project-root)
           default-directory)))

(use-package tab-bar
  :custom
  (tab-bar-show 1)
  (tab-bar-new-tab-choice #'my/tab-new-default)
  (tab-bar-close-button-show nil)
  (tab-bar-new-button-show nil)
  :config
  (tab-bar-mode 1))

(defun my/workspace-new ()
  "Create 3-tab layout in current directory: code / term / free."
  (interactive)
  (let ((root (when (projectile-project-p) (projectile-project-root))))
    (tab-bar-rename-tab "code")
    (tab-bar-new-tab)
    (tab-bar-rename-tab "term")
    (let ((default-directory (or root default-directory)))
      (let ((kill-buffer-query-functions nil))
        (dolist (buf (buffer-list))
          (when (eq (buffer-local-value 'major-mode buf) 'vterm-mode)
            (ignore-errors (kill-buffer buf)))))
      (vterm))
    (tab-bar-new-tab)
    (tab-bar-rename-tab "free")
    (dired (or root default-directory))
    (tab-bar-select-tab 1)))

(with-eval-after-load 'evil-maps
  (evil-define-key 'normal 'global
    (kbd "<leader>tn") #'tab-bar-new-tab
    (kbd "<leader>tk") #'tab-bar-close-tab
    (kbd "<leader>tK") #'tab-bar-close-other-tabs
    (kbd "<leader>tr") #'tab-bar-rename-tab
    (kbd "<leader>tl") #'my/workspace-new
    (kbd "<leader>t1") (lambda () (interactive) (tab-bar-select-tab 1))
    (kbd "<leader>t2") (lambda () (interactive) (tab-bar-select-tab 2))
    (kbd "<leader>t3") (lambda () (interactive) (tab-bar-select-tab 3))
    (kbd "<leader>t4") (lambda () (interactive) (tab-bar-select-tab 4))
    (kbd "<leader>t5") (lambda () (interactive) (tab-bar-select-tab 5))))

(global-set-key (kbd "M-<right>") #'tab-bar-switch-to-next-tab)
(global-set-key (kbd "M-<left>")  #'tab-bar-switch-to-prev-tab)

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "SPC t"   "tabs"
    "SPC t n" "new tab"
    "SPC t k" "close tab"
    "SPC t K" "close other tabs"
    "SPC t r" "rename tab"
    "SPC t l" "layout code/term/free"
    "SPC t 1" "tab 1"
    "SPC t 2" "tab 2"
    "SPC t 3" "tab 3"
    "SPC t 4" "tab 4"
    "SPC t 5" "tab 5"))
