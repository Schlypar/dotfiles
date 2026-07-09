;;; initial config
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(package-initialize)

;;; Disable nothingburgers
(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(horizontal-scroll-bar-mode -1)
(setq frame-title-format nil)
(setq ns-use-proxy-icon nil)
(electric-indent-mode 0)
(setq lsp-enable-on-type-formatting nil)


;;; Enable somethingburgers
(add-to-list 'default-frame-alist '(fullscreen . fullboth))

(require 'ansi-color)
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

(setq blink-cursor-blinks 0)
(setq-default cursor-type 'box)

(setq-default standard-indent 4)
(setq-default c-basic-offset 4)
(setq-default python-indent-offset 4)
(setq-default js-indent-level 4)
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)

(add-hook 'prog-mode-hook
          (lambda ()
            (setq tab-width 4)
            (setq indent-tabs-mode nil)))

(add-hook 'go-mode-hook
		  (lambda ()
			(setq-default)
			(setq tab-width 2)
			(setq standard-indent 2)
			(setq indent-tabs-mode nil)))
(setq go-ts-mode-indent-offset 4)

(defconst ya-path  "/usr/local/bin/ya" "ya util path")

(setq-default compile-command (concat ya-path " " compile-command))

;; doc view
(setq doc-view-continuous t)

;; remember cursor position, for emacs 25.1 or later
(save-place-mode 1)

(setq display-line-numbers-type 'relative)
(add-hook 'prog-mode-hook 'display-line-numbers-mode)

(show-paren-mode 1)
(use-package smartparens
  :ensure t
  :hook (prog-mode text-mode markdown-mode)
  :config
  (require 'smartparens-config))


;;; theme
(use-package doom-themes
  :ensure t
  :demand t
  :init (setq custom-safe-themes t)
  :config (load-theme 'doom-miramare))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror)

(setq make-backup-files nil)
(setq create-lockfiles nil)
(setq auto-save-default nil)

(global-auto-revert-mode 1)
(setq revert-without-query '(".*"))

(set-face-attribute 'default nil 
                    :font "Iosevka Nerd Font Mono"
                    :height 180)

(use-package ligature
  :ensure t
  :config
  ;; Enable all Cascadia Code / Fira Code ligatures in programming modes
  (ligature-set-ligatures 'prog-mode '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
                                       ":::" "::=" "=:=" "===" "==>" "=>" "=<<" "=/=" ">-" ">="
                                       ">=>" ">>-" ">>=" ">>>" "<*" "<*>" "<|" "<|>" "<$" "<$>"
                                       "<!--" "<-" "<--" "<->" "<+" "<+>" "<=" "<==" "<=>" "<=<"
                                       "<>" "<<" "<<-" "<<=" "<<<" "<~" "<~~" "</" "</>" "~@" "~-"
                                       "~=" "~>" "~~" "~~>" "%%" "->" "!=" "=="))
  ;; Enable globally
  (global-ligature-mode t))


(set-face-attribute 'line-number nil :foreground "gray50" :background nil)
(set-face-attribute 'line-number-current-line nil :foreground "orange" :background nil)

(use-package fancy-compilation
  :ensure t
  :commands (fancy-compilation-mode)
  :custom
  (fancy-compilation-override-colors nil))

(with-eval-after-load 'compile
  (fancy-compilation-mode))


(defun rune/evil-hook ()
  (dolist (mode '(custom-mode
                  eshell-mode
                  git-rebase-mode
                  erc-mode
                  circe-server-mode
                  circe-chat-mode
                  circe-query-mode
                  sauron-mode
                  term-mode))
    (add-to-list 'evil-emacs-state-modes mode)))


(use-package undo-tree
  :defer t
  :diminish undo-tree-mode
  :init (global-undo-tree-mode)
  :custom
  (undo-tree-visualizer-diff t)
  (undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
  (undo-tree-visualizer-timestamps t))


(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  :hook (evil-mode . rune/evil-hook)
  :config

  (evil-set-leader 'normal (kbd "SPC"))

  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)


  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(evil-mode 1)
(which-key-mode 1)

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init 'dired))

;; Vim motions работают при русской раскладке — биндинги транслируются
;; через input-method, переключать язык в normal-state не нужно.
(use-package reverse-im
  :ensure t
  :after evil
  :custom
  (reverse-im-input-methods '("russian-computer"))
  :config
  (reverse-im-mode t))


(use-package projectile
  :ensure t
  :config
  (projectile-mode +1)
  (setq projectile-enable-caching t)
  (setq projectile-project-search-path '("~/arcadia/taxi/backend-go/" "~/arcadia/taxi/uservices/serivces/"  "~/Desktop/"))
  (add-to-list 'projectile-project-root-files "service.yaml")
  (projectile-discover-projects-in-search-path)
  )

(add-hook 'after-init-hook #'projectile-global-mode)


(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))

(setq initial-buffer-choice 'dashboard-open)

(defun my/dashboard-open-unless-editing ()
  "Open dashboard on a new server frame, unless emacsclient was invoked to
edit a specific file (e.g. magit's COMMIT_EDITMSG via with-editor)."
  (unless (or command-line-args-left
              (cl-some (lambda (buf)
                         (or (buffer-local-value 'server-buffer-clients buf)
                             (buffer-local-value 'with-editor-mode buf)))
                       (buffer-list)))
    (dashboard-open)))

(add-hook 'server-after-make-frame-hook #'my/dashboard-open-unless-editing)

(use-package nerd-icons
  :ensure t
  :after dashboard)


(use-package agent-shell
  :ensure t
  :config
  (setq agent-shell-session-strategy 'prompt)
  (setq agent-shell-confirm-interrupt t)
  (setq agent-shell-prefer-viewport-interaction t))

(use-package agent-shell-workspace
  :vc (:url "https://github.com/gveres/agent-shell-workspace")
  :ensure t
  :after agent-shell)

(use-package agent-shell-manager
  :vc (:url "https://github.com/jethrokuan/agent-shell-manager")
  :ensure t
  :after agent-shell
  :config
  (setq agent-shell-manager-side 'right))

(let ((config-dir (file-name-directory (or load-file-name buffer-file-name))))
  (mapc #'load-file (directory-files (expand-file-name "after/" config-dir) t "\\.el$")))
