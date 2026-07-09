;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("0325a6b5eea7e5febae709dab35ec8648908af12cf2d2b569bedc8da0a3a81c1"
     "4594d6b9753691142f02e67b8eb0fda7d12f6cc9f1299a49b819312d6addad1d"
     "8d3ef5ff6273f2a552152c7febc40eabca26bae05bd12bc85062e2dc224cde9a"
     "dfb1c8b5bfa040b042b4ef660d0aab48ef2e89ee719a1f24a4629a0c5ed769e8"
     "02d422e5b99f54bd4516d4157060b874d14552fe613ea7047c4a5cfa1288cf4f"
     "b754d3a03c34cfba9ad7991380d26984ebd0761925773530e24d8dd8b6894738"
     "38b43b865e2be4fe80a53d945218318d0075c5e01ddf102e9bec6e90d57e2134"
     "f053f92735d6d238461da8512b9c071a5ce3b9d972501f7a5e6682a90bf29725"
     "f4d1b183465f2d29b7a2e9dbe87ccc20598e79738e5d29fc52ec8fb8c576fcfd"
     "9b9d7a851a8e26f294e778e02c8df25c8a3b15170e6f9fd6965ac5f2544ef2a9"
     "e8bd9bbf6506afca133125b0be48b1f033b1c8647c628652ab7a2fe065c10ef0"
     "70c88c01b0b5fde9ecf3bb23d542acba45bb4c5ae0c1330b965def2b6ce6fac3"
     "1f8bd4db8280d5e7c5e6a12786685a7e0c6733b0e3cf99f839fb211236fb4529"
     "df6dfd55673f40364b1970440f0b0cb8ba7149282cf415b81aaad2d98b0f0290"
     "456697e914823ee45365b843c89fbc79191fdbaff471b29aad9dcbe0ee1d5641"
     "93011fe35859772a6766df8a4be817add8bfe105246173206478a0706f88b33d"
     "e14289199861a5db890065fdc5f3d3c22c5bac607e0dbce7f35ce60e6b55fc52"
     "d481904809c509641a1a1f1b1eb80b94c58c210145effc2631c1a7f2e4a2fdf4"
     "3613617b9953c22fe46ef2b593a2e5bc79ef3cc88770602e7e569bbd71de113b"
     "aec7b55f2a13307a55517fdf08438863d694550565dee23181d2ebd973ebd6b8"
     "720838034f1dd3b3da66f6bd4d053ee67c93a747b219d1c546c41c4e425daf93"
     "dd4582661a1c6b865a33b89312c97a13a3885dc95992e2e5fc57456b4c545176"
     "9e5e0ff3a81344c9b1e6bfc9b3dcf9b96d5ec6a60d8de6d4c762ee9e2121dfb2"
     "4990532659bb6a285fee01ede3dfa1b1bdf302c5c3c8de9fad9b6bc63a9252f7"
     "13096a9a6e75c7330c1bc500f30a8f4407bd618431c94aeab55c9855731a95e1"
     "f64189544da6f16bab285747d04a92bd57c7e7813d8c24c30f382f087d460a33"
     "f1e8339b04aef8f145dd4782d03499d9d716fdc0361319411ac2efc603249326"
     "8363207a952efb78e917230f5a4d3326b2916c63237c1f61d7e5fe07def8d378"
     "d5fd482fcb0fe42e849caba275a01d4925e422963d1cd165565b31d3f4189c87"
     "51fa6edfd6c8a4defc2681e4c438caf24908854c12ea12a1fbfd4d055a9647a3"
     default))
 '(package-selected-packages
   '(agent-shell-manager agent-shell-workspace company consult dashboard
                         doom-themes eat evil-collection
                         fancy-compilation go-mode gruvbox-theme
                         haskell-ts-mode ligature lsp-pyright lsp-ui
                         magit marginalia mixed-pitch nerd-icons
                         olivetti orderless persp-projectile
                         protobuf-ts-mode reverse-im smartparens
                         undo-tree valign vertico vterm))
 '(package-vc-selected-packages
   '((agent-shell-manager :url
                          "https://github.com/jethrokuan/agent-shell-manager")
     (agent-shell-workspace :url
                            "https://github.com/gveres/agent-shell-workspace")))
 '(safe-local-variable-values
   '((eval setq-local TeX-master
           (concat "../"
                   (seq-find (-cut string-match ".*-3-pz.tex$" <>)
                             (directory-files ".."))))
     (TeX-engine . xetex))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(markdown-blockquote-face ((t (:inherit variable-pitch :height 1.0 :background "#282828" :foreground "#8ec07c" :slant italic))))
 '(markdown-bold-face ((t (:weight bold :inherit variable-pitch))))
 '(markdown-code-face ((t (:family "Iosevka Nerd Font Mono" :background "#282828" :height 1.0))))
 '(markdown-header-delimiter-face ((t (:foreground "gray50" :inherit variable-pitch))))
 '(markdown-header-face-1 ((t (:height 1.8 :weight bold :inherit variable-pitch))))
 '(markdown-header-face-2 ((t (:height 1.5 :weight bold :inherit variable-pitch))))
 '(markdown-header-face-3 ((t (:height 1.3 :weight bold :inherit variable-pitch))))
 '(markdown-header-face-4 ((t (:height 1.1 :weight bold :inherit variable-pitch))))
 '(markdown-header-face-5 ((t (:height 1.0 :weight bold :inherit variable-pitch))))
 '(markdown-italic-face ((t (:slant italic :inherit variable-pitch))))
 '(markdown-list-item ((t (:inherit variable-pitch))))
 '(markdown-markup-face ((t (:inherit variable-pitch))))
 '(markdown-table-cell-face ((t (:family "Iosevka Nerd Font Mono" :height 1.2 :inherit variable-pitch))))
 '(markdown-table-face ((t (:family "Iosevka Nerd Font Mono" :height 1.2 :inherit variable-pitch))))
 '(markdown-table-row-face ((t (:family "Iosevka Nerd Font Mono" :height 1.2 :inherit variable-pitch)))))
