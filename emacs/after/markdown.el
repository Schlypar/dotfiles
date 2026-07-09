;; Packages

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" "\\.markdown\\'")
  :init
  (setq markdown-fontify-code-blocks-natively t)
  (setq markdown-hide-markup nil))

(use-package olivetti
  :ensure t
  :init (setq olivetti-body-width 0.9))

(use-package mixed-pitch :ensure t)

(use-package valign
  :ensure t
  :hook (markdown-mode . valign-mode))

;; Variable-pitch font for prose
;; Alternatives: "Iosevka Etoile", "SF Pro Text"
(set-face-attribute 'variable-pitch nil :family "Helvetica Neue" :height 180)

;; Header sizes
(custom-set-faces
 '(markdown-header-face-1 ((t (:inherit variable-pitch :height 2.0 :weight bold))))
 '(markdown-header-face-2 ((t (:inherit variable-pitch :height 1.8 :weight bold))))
 '(markdown-header-face-3 ((t (:inherit variable-pitch :height 1.6 :weight bold))))
 '(markdown-header-face-4 ((t (:inherit variable-pitch :height 1.4 :weight bold))))
 '(markdown-header-face-5 ((t (:inherit variable-pitch :height 1.2 :weight bold))))
 '(markdown-markup-face ((t (:inherit variable-pitch))))
 '(markdown-list-item ((t (:inherit variable-pitch))))
 '(markdown-bold-face ((t (:weight bold :inherit variable-pitch))))
 '(markdown-italic-face ((t (:slant italic :inherit variable-pitch))))
 '(markdown-code-face ((t (:family "Iosevka Nerd Font Mono" :background "#282828" :height 1.0))))
 '(markdown-blockquote-face ((t (:inherit variable-pitch :height 1.0 :background "#282828" :foreground "#8ec07c" :slant italic))))
 '(markdown-header-delimiter-face ((t (:foreground "gray50" :inherit variable-pitch))))
 '(markdown-table-face ((t (:family "Iosevka Nerd Font Mono" :height 1.2 :inherit variable-pitch))))
 '(markdown-table-cell-face ((t (:family "Iosevka Nerd Font Mono" :height 1.2 :inherit variable-pitch))))
 '(markdown-table-row-face ((t (:family "Iosevka Nerd Font Mono" :height 1.2 :inherit variable-pitch)))))

;; Mode hook
(add-hook 'markdown-mode-hook
          (lambda ()
            (olivetti-mode 1)
            (mixed-pitch-mode 1)
            (visual-line-mode 1)
            (setq line-spacing 0.2)
            (display-line-numbers-mode -1)
            (font-lock-add-keywords
             nil
             '(("^#\\{1\\} \\(.*\\)$" 1 'markdown-header-face-1 t)
               ("^#\\{2\\} \\(.*\\)$" 1 'markdown-header-face-2 t)
               ("^#\\{3\\} \\(.*\\)$" 1 'markdown-header-face-3 t)
               ("^#\\{4\\} \\(.*\\)$" 1 'markdown-header-face-4 t)
               ("^#\\{5\\} \\(.*\\)$" 1 'markdown-header-face-5 t)
               ("^#\\{6\\} \\(.*\\)$" 1 'markdown-header-face-6 t)) 
             t)
            (font-lock-add-keywords
             nil
             '(("^# " (0 (prog1 () (compose-region (match-beginning 0) (match-end 0) "§ "))))
               ("^## " (0 (prog1 () (compose-region (match-beginning 0) (match-end 0) " §§ "))))
               ("^### " (0 (prog1 () (compose-region (match-beginning 0) (match-end 0) " §§§ "))))
               ("^#### " (0 (prog1 () (compose-region (match-beginning 0) (match-end 0) " §§§§ "))))
               ("^##### " (0 (prog1 () (compose-region (match-beginning 0) (match-end 0) " §§§§§ "))))
               ("^###### " (0 (prog1 () (compose-region (match-beginning 0) (match-end 0) " §§§§§§ "))))))))


;; Smart TAB (insert mode): advance table cell | normal indent
(defun my/markdown-insert-tab ()
  (interactive)
  (if (markdown-table-at-point-p)
      (markdown-table-forward-cell)
    (indent-for-tab-command)))

(defun my/markdown-insert-shift-tab ()
  (interactive)
  (if (markdown-table-at-point-p)
      (markdown-table-backward-cell)
    (markdown-shifttab)))

;; Keybindings
(with-eval-after-load 'markdown-mode
  (evil-define-key 'normal markdown-mode-map
    (kbd "<leader>ml")   #'markdown-insert-link
    (kbd "<leader>mc")   #'markdown-insert-gfm-code-block
    (kbd "<leader>mt")   #'markdown-insert-table
    (kbd "<leader>mh")   #'markdown-toggle-markup-hiding
    (kbd "]h")           #'markdown-next-visible-heading
    (kbd "[h")           #'markdown-previous-visible-heading))

(evil-define-key 'insert markdown-mode-map
  (kbd "TAB")          #'my/markdown-insert-tab
  (kbd "S-TAB")        #'my/markdown-insert-shift-tab)

(which-key-add-key-based-replacements
  "SPC m"   "markdown"
  "SPC m l" "insert link"
  "SPC m c" "insert code block"
  "SPC m t" "insert table"
  "SPC m h" "toggle markup hiding")
