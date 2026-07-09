(require 'tramp)

;;; Путь на удалённой машине
(add-to-list 'tramp-remote-path 'tramp-own-remote-path)

;;; --- Производительность -------------------------------------------------

;; SSH ControlMaster: одно TCP-соединение на хост вместо нового при каждой
;; файловой операции. Самое важное улучшение для скорости TRAMP.
(setq tramp-default-method "ssh")
(setq tramp-use-ssh-controlmaster-options t)

;; Кэш файловых атрибутов: nil = живёт всю сессию.
;; Ручное обновление: C-l в dired или M-x tramp-cleanup-connection.
(setq remote-file-name-inhibit-cache nil)

;; Не перечитывать директорию при каждом tab-completion.
(setq tramp-completion-reread-directory-timeout nil)

;; Минимум логов — каждый DEBUG-вызов обходится дорого на remote.
(setq tramp-verbose 1)

;;; --- Бэкапы и автосохранение -------------------------------------------

;; Автосохранение — локально, не гнать трафик на хост.
(setq tramp-auto-save-directory temporary-file-directory)

;; Бэкапы для remote-файлов отключить (nil = не делать копий).
(add-to-list 'backup-directory-alist (cons tramp-file-name-regexp nil))

;;; --- VC (git/hg/svn) ---------------------------------------------------

;; git status по SSH на каждый открытый файл — главный убийца скорости.
;; Полностью исключаем remote-пути из всех VC-бэкендов.
(setq vc-ignore-dir-regexp
      (format "\\(%s\\)\\|\\(%s\\)"
              vc-ignore-dir-regexp
              tramp-file-name-regexp))

;;; --- Projectile --------------------------------------------------------

;; Не индексировать remote-директории (рекурсивный find по SSH — очень медленно).
(with-eval-after-load 'projectile
  (advice-add 'projectile-project-root :around
              (lambda (orig &rest args)
                (unless (file-remote-p default-directory)
                  (apply orig args)))))

;;; --- Prefetch ----------------------------------------------------------

(defun my/tramp-prefetch-directory (dir)
  "Рекурсивно загружает все файлы удалённой директории DIR в буферы Emacs.
Запрашивает путь в формате TRAMP (например /ssh:host:/path/to/dir).
Обычные файлы загружаются через `find-file-noselect', так что последующее
открытие файла происходит мгновенно — без обращения к удалённому хосту.
Использует одну команду `find' по SSH, перечисляя все файлы за один
сетевой обход. Симлинки не загружаются. Уже открытые файлы пропускаются."
  (interactive
   (list (read-directory-name
          "TRAMP директория для загрузки: "
          (when (and buffer-file-name (tramp-tramp-file-p buffer-file-name))
            (file-name-directory buffer-file-name)))))
  (unless (tramp-tramp-file-p dir)
    (user-error "Не TRAMP путь: %s" dir))
  (let* ((root    (file-name-as-directory dir))
         (loaded  0)
         (skipped 0)
         (errors  0))
    (with-parsed-tramp-file-name root nil
      (let ((remote-dir (directory-file-name localname))
            (raw-paths  nil)
            (exit-code  nil))
        (message "Перечисляю файлы в %s ..." root)
        (condition-case enum-err
            (with-temp-buffer
              (set-buffer-multibyte nil)
              (buffer-disable-undo)
              (let ((default-directory root))
                (setq exit-code
                      (process-file "find" nil t nil
                                    remote-dir
                                    "-type" "f"
                                    "!" "-type" "l"
                                    "-print0")))
              (unless (zerop exit-code)
                (user-error "find завершился с кодом %d в %s" exit-code root))
              (setq raw-paths (split-string (buffer-string) (string 0) t)))
          (error
           (user-error "Ошибка перечисления %s: %s"
                       root (error-message-string enum-err))))
        (let ((total (length raw-paths)))
          (message "Найдено %d файлов, начинаю загрузку..." total)
          (dolist (remote-path raw-paths)
            (let ((tramp-path (tramp-make-tramp-file-name v remote-path)))
              (if (get-file-buffer tramp-path)
                  (cl-incf skipped)
                (condition-case load-err
                    (progn
                      (find-file-noselect tramp-path)
                      (cl-incf loaded)
                      (when (zerop (mod loaded 10))
                        (message "Загружено %d из %d файлов... (пропущено %d)"
                                 loaded total skipped)))
                  (error
                   (cl-incf errors)
                   (message "Пропуск %s: %s"
                            (file-name-nondirectory remote-path)
                            (error-message-string load-err)))))))
          (message "Готово: загружено %d, пропущено %d, ошибок %d"
                   loaded skipped errors))))))
