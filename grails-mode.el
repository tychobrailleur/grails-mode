;; Copyright (c) 2014 Sébastien Le Callonnec

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;
(setq debug-on-error t)

(require 'cl)
(require 'helm-files)

(defvar grails-mode "0.1.0")

(defgroup grails nil
  "Grails Minor mode Group."
  :group 'programming
  :prefix "grails/")

(defcustom grails/source-dir "grails-app"
  "Location of the application sources in the project."
  :type 'string
  :group 'grails)

(defcustom grails/grails-types '("domain" "controllers" "services" "views")
  "Types of files."
  :type 'sexp
  :group 'grails)

;; List all the files under directory matching pattern.
(defun find-all-files (directory pattern)
  (directory-files-recursively directory pattern))

;; Look for the root of the current grails project.
(defun grails/find-root (file)
  (when file
    (let ((current-dir (file-name-directory file))
          (found nil))
      (while (and (not found) (not (string= current-dir "/")))
        (if (file-exists-p (concat current-dir grails/source-dir))
            (setq found t)
          (setq current-dir (expand-file-name (concat current-dir "../")))))
      (if found
          current-dir))))

;; Builds a list of files belonging to a certain resource type
;; e.g. controllers, domain, etc. under grails-app
(defun grails/grails-list-of (resource-type)
  (let* ((current-buf (current-buffer))
         (current-file (buffer-file-name current-buf))
         (root (grails/find-root current-file))
         (resource-root (concat
                         (file-name-as-directory root)
                         (file-name-as-directory grails/source-dir) resource-type)))
    (find-all-files resource-root "\\(\\.groovy$\\|\\.gsp$\\)")))

(defmacro grails/define-grails-list (name)
  `(defun ,(intern (concat "grails/grails-" name "-list"))
       ()
       (grails/grails-list-of ,name)))



(grails/define-grails-list "domain")
(grails/define-grails-list "controllers")
(grails/define-grails-list "services")
(grails/define-grails-list "views")

;;(macroexpand '(grails/define-grails-list "controllers"))

;; Controllers.

(defvar helm-grails-controllers-list-cache nil)
(defvar helm-grails-controllers-list
  `((name . "Controllers")
    (init . (lambda ()
              (setq helm-grails-controllers-list-cache (grails/grails-controllers-list))))
    (candidates . helm-grails-controllers-list-cache)
    (type . file)))

(defun grails/helm-controllers ()
  (interactive)
  (helm-other-buffer '(helm-grails-controllers-list)
                     "*helm grails*"))

;; Domain

(defvar helm-grails-domain-list-cache nil)
(defvar helm-grails-domain-list
  `((name . "Domain")
    (init . (lambda ()
              (setq helm-grails-domain-list-cache (grails/grails-domain-list))))
    (candidates . helm-grails-domain-list-cache)
    (type . file)))

(defun grails/helm-domain ()
  (interactive)
  (helm-other-buffer '(helm-grails-domain-list)
                     "*helm grails*"))

;; Services

(defvar helm-grails-services-list-cache nil)
(defvar helm-grails-services-list
  `((name . "Services")
    (init . (lambda ()
              (setq helm-grails-services-list-cache (grails/grails-services-list))))
    (candidates . helm-grails-services-list-cache)
    (type . file)))

(defun grails/helm-services ()
  (interactive)
  (helm-other-buffer '(helm-grails-services-list)
                     "*helm grails*"))


;; Views

(defvar helm-grails-views-list-cache nil)
(defvar helm-grails-views-list
  `((name . "Views")
    (init . (lambda ()
              (setq helm-grails-views-list-cache (grails/grails-views-list))))
    (candidates . helm-grails-views-list-cache)
    (type . file)))

(defun grails/helm-views ()
  (interactive)
  (helm-other-buffer '(helm-grails-views-list)
                     "*helm grails*"))


(defun grails/helm-all ()
  (interactive)
  (helm-other-buffer '(helm-grails-controllers-list
                       helm-grails-domain-list
                       helm-grails-services-list
                       helm-grails-views-list)
                     "*helm grails*"))


;; Run test in current buffer.
(defun grails/run-current-test ()
  (interactive)
  (cd (grails/find-root (buffer-file-name)))
  (let ((test-buffer (buffer-name))
        (buffer (get-buffer-create "*grails-test-unit*")))
    (pop-to-buffer buffer)
    (local-set-key "q" 'kill-this-buffer)
    (local-set-key "Q" 'kill-buffer-and-window)
    (message "Run test for %s" test-buffer)
    (let ((proc
           (start-process-shell-command
            "*grails-test-unit*"
            buffer
            "grails" "test-app" "unit:" test-buffer "-debugOut" "-plainOutput"))))))


;; Keymap

(defvar grails-mode-keymap
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap
      (kbd "C-c t") 'grails/run-current-test)
    (define-key keymap
      (kbd "C-c c") 'grails/helm-controllers)
    (define-key keymap
      (kbd "C-c s") 'grails/helm-services)
    (define-key keymap
      (kbd "C-c d") 'grails/helm-domain)
    (define-key keymap
      (kbd "C-c a") 'grails/helm-all)
    keymap)
  "Key map for grails-mode.")


(define-minor-mode grails-mode
  "Grails minor mode."
  :group 'grails
  :lighter " Grails"
  :keymap grails-mode-keymap)

(provide 'grails-mode)
