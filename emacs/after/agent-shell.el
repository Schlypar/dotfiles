;;; agent-shell — конфигурация и биндинги

(defun my/agent-shell-in-project ()
  "Открыть agent-shell в корне текущего projectile-проекта."
  (interactive)
  (let ((default-directory (or (and (fboundp 'projectile-project-root)
                                    (projectile-project-root))
                               default-directory)))
    (agent-shell)))

(defun my/agent-shell-new-in-project ()
  "Создать НОВЫЙ agent-shell в корне текущего projectile-проекта."
  (interactive)
  (let ((default-directory (or (and (fboundp 'projectile-project-root)
                                    (projectile-project-root))
                               default-directory)))
    (agent-shell-new-shell)))

;;; --- Биндинги ---

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global (kbd "<leader>aa") #'my/agent-shell-in-project)
  (evil-define-key 'normal 'global (kbd "<leader>an") #'my/agent-shell-new-in-project)
  (evil-define-key 'normal 'global (kbd "<leader>ac") #'agent-shell-restart)
  (evil-define-key 'normal 'global (kbd "<leader>aw") #'agent-shell-workspace-toggle))

;;; --- Фикс: '/' и '@' не закрывают Agents workspace ---
;; agent-shell-completion вызывает completion-at-point при вводе '/' или '@',
;; что показывает *Completions* буфер. Изоляция workspace видит его как
;; "не-агентский" и переключает таб обратно. Разрешаем completion-буферы.
(defun my/agent-shell-workspace--allow-completions (orig-fn buffer)
  "Пропускать completion-буферы сквозь изоляцию Agents workspace."
  (or (funcall orig-fn buffer)
      (when (and buffer (buffer-live-p buffer))
        (let ((name (buffer-name buffer)))
          (or (string= name "*Completions*")
              (string-prefix-p " *company" name)
              (string-prefix-p "*corfu" name))))))

(with-eval-after-load 'agent-shell-workspace
  (advice-add 'agent-shell-workspace--agent-buffer-p
              :around #'my/agent-shell-workspace--allow-completions))

;;; --- which-key descriptions ---
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "SPC a"   "agent/claude"
    "SPC a a" "open in project"
    "SPC a n" "new chat in project"
    "SPC a c" "clear/restart chat"
    "SPC a w" "workspace"))
