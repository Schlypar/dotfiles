;;; -*- lexical-binding: t -*-
;; --- vertico: вертикальный UI ---
(use-package vertico
  :ensure t
  :init (vertico-mode))

;; --- orderless: fuzzy-матчинг ---
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; --- marginalia: аннотации (тип файла, размер, дата) ---
(use-package marginalia
  :ensure t
  :init (marginalia-mode))

;; --- consult: поиск + file preview ---
(use-package consult
  :ensure t
  :config
  ;; consult-find и consult-ripgrep стартуют из корня проекта через projectile
  (setq consult-project-function #'projectile-project-root))

(defconst my/image-preview-exts
  '("svg" "png" "jpg" "jpeg" "gif" "bmp" "webp" "tiff" "tif" "ico" "xpm" "xbm")
  "Расширения файлов для показа как изображения в превью.")

(defconst my/skip-preview-exts
  '("pdf" "zip" "tar" "gz" "bz2" "xz" "7z" "rar"
    "exe" "so" "dylib" "dll" "o" "a" "class" "pyc"
    "mp4" "mp3" "avi" "mkv" "mov" "flac" "wav" "ogg" "opus")
  "Расширения бинарных/медиа файлов — превью не показываем.")

(defun my/file-preview-state ()
  "Consult state function с поддержкой SVG, изображений, пропуском бинарников."
  (let ((text-state (consult--file-preview))
        (img-buf nil))
    (lambda (action cand)
      (let ((ext (and cand (downcase (or (file-name-extension cand) "")))))
        (cond
         ;; Изображения (SVG, PNG, ...)
         ((and (eq action 'preview) cand (member ext my/image-preview-exts))
          (when (file-readable-p cand)
            (when (buffer-live-p img-buf) (kill-buffer img-buf))
            (setq img-buf (generate-new-buffer " *my/preview-image*"))
            (with-current-buffer img-buf
              (let ((inhibit-read-only t))
                (erase-buffer)
                (condition-case err
                    (insert-image (create-image cand) " ")
                  (error (insert (format "[Нет превью: %s]"
                                         (error-message-string err)))))))
            (let ((win (minibuffer-selected-window)))
              (when (window-live-p win)
                (with-selected-window win
                  (switch-to-buffer img-buf))))))
         ;; Бинарные/медиа — пропускаем
         ((and (eq action 'preview) cand (member ext my/skip-preview-exts))
          nil)
         ;; Всё остальное (текст) — стандартный consult preview
         (t
          (when (memq action '(exit return))
            (when (buffer-live-p img-buf)
              (kill-buffer img-buf)
              (setq img-buf nil)))
          (funcall text-state action cand)))))))

(defun my/find-file-with-preview ()
  "Найти файл в проекте с live-превью при навигации."
  (interactive)
  (require 'consult)
  (let* ((root (projectile-project-root))
         (files (mapcar (lambda (f) (expand-file-name f root))
                        (projectile-current-project-files)))
         (file (consult--read
                files
                :prompt "Find file: "
                :category 'file
                :sort nil
                :require-match t
                :state (my/file-preview-state))))
    (find-file file)))
