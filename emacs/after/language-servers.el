;; --- Go ---
(use-package go-mode
  :ensure t)

;; Root detection for Arcadia monorepo:
;; use nearest ya.make instead of the arcadia/.git root
(defun my/lsp-arcadia-go-root (file-path)
  "Find LSP root by nearest ya.make (Arcadia monorepo).
For TRAMP paths skips locate-dominating-file — each check opens a new
SSH/GIO connection and causes an infinite reconnect loop."
  (unless (file-remote-p file-path)
    (let ((dir (file-name-directory
                (if (file-directory-p file-path)
                    (directory-file-name file-path)
                  file-path))))
      (locate-dominating-file dir "ya.make"))))

(defun my/go-lsp-setup ()
  (setq-local lsp-project-root-function #'my/lsp-arcadia-go-root))

(add-hook 'go-mode-hook    #'my/go-lsp-setup)
(add-hook 'go-ts-mode-hook #'my/go-lsp-setup)

;; --- LSP mode (Go, C, C++, TypeScript/TSX) ---
(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :hook ((go-mode          . lsp-deferred)
         (go-ts-mode       . lsp-deferred)
         (c-mode           . lsp-deferred)
         (c-ts-mode        . lsp-deferred)
         (c++-mode         . lsp-deferred)
         (c++-ts-mode      . lsp-deferred)
         (typescript-ts-mode . lsp-deferred)
         (tsx-ts-mode      . lsp-deferred))
  :config
  (setq lsp-auto-guess-root nil)
  (setq lsp-enable-snippet nil)
  ;; Не спрашивать про рестарт сервера — если упал, просто молчим
  (setq lsp-restart 'ignore)
  ;; Отключаем серверы, которых нет на машине
  (setq lsp-disabled-clients '(semgrep-ls golangci-lint-langserver))
  ;; Локальный gopls через ya tool
  (setq lsp-go-gopls-server-path ya-path)
  (setq lsp-go-gopls-server-args '("tool" "gopls" "serve"))
  (lsp-register-custom-settings
   '(("gopls.completeUnimported" t)
     ("gopls.staticcheck" t)
     ("clangd.headerInsertion" "never")
     ("clangd.completionStyle" "detailed"))))

(setq lsp-headerline-breadcrumb-mode nil)

;; lsp-watch-root-folder рекурсивно обходит все поддиректории воркспейса.
;; Для TRAMP-пути каждая проверка открывает новый GIO/SSH-коннект → бесконечный цикл.
;; lsp-enable-file-watchers при проверке читается в process filter (не в буфере) → setq-local не работает.
;; Единственный надёжный способ — advice напрямую на функцию.
(with-eval-after-load 'lsp-mode
  (advice-add 'lsp-watch-root-folder :around
              (lambda (orig dir &rest args)
                (if (file-remote-p dir)
                    (lsp-log "LSP: skipping file watcher for remote path %s" dir)
                  (apply orig dir args)))))

;; Удалённый gopls для TRAMP.
;; bash --login sourсит ~/.bash_profile и даёт gopls полный PATH (включая go, ya и т.д.)
(with-eval-after-load 'lsp-go
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection
                     (lambda ()
                       (list "bash" "-c"
                             (concat "export PATH=\"$(ya tool go env GOROOT)/bin:$PATH\""
                                     " && ya tool gopls serve"))))
    :major-modes '(go-mode go-ts-mode)
    :language-id "go"
    :priority 0
    :remote? t
    :server-id 'ya-gopls-remote)))

;; --- Python (pyright) ---
;; (use-package lsp-pyright
;;   :ensure t
;;   :hook ((python-mode    . (lambda () (require 'lsp-pyright) (lsp-deferred)))
;;          (python-ts-mode . (lambda () (require 'lsp-pyright) (lsp-deferred)))))

(use-package lsp-pyright
  :ensure t
  :hook ((python-ts-mode . (lambda () (require 'lsp-pyright) (lsp-deferred)))))

;; --- company-mode (автодополнение) ---
(use-package company
  :ensure t
  :hook (lsp-mode . company-mode)
  :config
  (setq company-minimum-prefix-length 1
        company-idle-delay 0.2
        company-selection-wrap-around t))

;; --- lsp-ui (диагностика в sideline, doc по K) ---
(use-package lsp-ui
  :ensure t
  :after lsp-mode
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-show-with-cursor nil
        lsp-ui-sideline-show-diagnostics t
        lsp-ui-sideline-show-code-actions t))
