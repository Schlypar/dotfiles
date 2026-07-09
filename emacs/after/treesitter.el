;; Максимальный уровень подсветки (как nvim treesitter)
(setq treesit-font-lock-level 4)

;; Источники грамматик для установки/обновления
(setq treesit-language-source-alist
  '((go         "https://github.com/tree-sitter/tree-sitter-go")
    (c          "https://github.com/tree-sitter/tree-sitter-c")
    (cpp        "https://github.com/tree-sitter/tree-sitter-cpp")
    (python     "https://github.com/tree-sitter/tree-sitter-python")
    (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
    (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
    (json       "https://github.com/tree-sitter/tree-sitter-json")
    (yaml       "https://github.com/ikatyang/tree-sitter-yaml")
    (bash       "https://github.com/tree-sitter/tree-sitter-bash")
    (proto   "https://github.com/mitchellh/tree-sitter-proto")
    (haskell    "https://github.com/tree-sitter/tree-sitter-haskell")
    (cmake      "https://github.com/uyha/tree-sitter-cmake")))

;; Авто-установка недостающих грамматик при запуске
(defun my/treesit-auto-install-grammars ()
  "Установить недостающие tree-sitter грамматики автоматически."
  (dolist (lang (mapcar #'car treesit-language-source-alist))
    (unless (treesit-language-available-p lang)
      (message "tree-sitter: устанавливаю грамматику %s..." lang)
      (treesit-install-language-grammar lang))))

(add-hook 'after-init-hook #'my/treesit-auto-install-grammars)

;; Авто-переключение старых режимов на ts-режимы
(setq major-mode-remap-alist
  '((go-mode         . go-ts-mode)
    (c-mode          . c-ts-mode)
    (c++-mode        . c++-ts-mode)
    (python-mode     . python-ts-mode)
    (js-json-mode    . json-ts-mode)
    (sh-mode         . bash-ts-mode)
    (haskell-mode    . haskell-ts-mode)))

;; TSX / TypeScript → ts-режимы
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-ts-mode))

;; JSON
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode))

;; YAML
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))

;; Shell
(add-to-list 'auto-mode-alist '("\\.sh\\'"   . bash-ts-mode))
(add-to-list 'auto-mode-alist '("\\.bash\\'" . bash-ts-mode))
(add-to-list 'auto-mode-alist '("\\.zsh\\'"  . bash-ts-mode))

;; Protobuf
(use-package protobuf-ts-mode
  :ensure t
  :mode "\\.proto\\'")


;; Haskell
(use-package haskell-ts-mode
  :ensure t
  :mode (("\\.hs\\'"  . haskell-ts-mode)
         ("\\.lhs\\'" . haskell-ts-mode)))

;; CMake
(add-to-list 'auto-mode-alist '("CMakeLists\\.txt\\'" . cmake-ts-mode))
(add-to-list 'auto-mode-alist '("\\.cmake\\'"         . cmake-ts-mode))

;; ts-mode indent offsets (override global tab-width; ts-modes have their own variable)
(setq typescript-ts-mode-indent-offset 4)
(setq c-ts-mode-indent-offset 4)

(add-hook 'haskell-ts-mode-hook
  (lambda ()
    (setq-local tab-width 4)
    (setq-local indent-tabs-mode nil)))
