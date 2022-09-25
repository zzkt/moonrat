;;; moonrat.el --- Mode for moon rat gardening -*- coding: utf-8; lexical-binding: t -*-

;; Copyright 2022 FoAM oü
;;
;; Author: nik gaffney <nik@fo.am>
;; Created: 2022-09-17
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: text generation, generative, languages, tools
;; URL: https://github.com/zzkt/moonrat

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; a mode for moon rat gardening with text templates.
;;                       see https://github.com/zzkt/moonrat

;;; Code:

(defun moonrat-generate ()
  "Generate something."
  (message "not yet..."))

(defvar moonrat-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "C-x g" #'moonrat-generate)
    map))

(defconst moonrat-keywords
  '(("output" . 'font-lock-function-name-face)))

;; (defconst moonrat-syntax-table
;;   (let ((table (make-syntax-table)))

;;     ;; brackets
;;     (modify-syntax-entry ?\{ "(}" table)
;;     (modify-syntax-entry ?\} "){" table)
;;     (modify-syntax-entry ?\[ "(]" table)
;;     (modify-syntax-entry ?\] ")[" table)

;;     ;; / is punctuation, but // is a comment starter
;;     (modify-syntax-entry ?/ ". 12" table)
;;     ;; \n ends a comment
;;     (modify-syntax-entry ?\n ">" table)
;;     table))

;;;###autoload
(define-derived-mode moonrat-mode prog-mode "🌝"
  "Major mode for a moon rat gardener."
  ;; :syntax-table moonrat-syntax-table

  ;; square brackets
  (font-lock-add-keywords 'moonrat-mode '(("\\(\\[.*?]\\)"
                                           1 font-lock-variable-name-face prepend)))
  ;; curly brackets
  (font-lock-add-keywords 'moonrat-mode '(("\\({.*?\}\\)"
                                           1 font-lock-constant-face prepend)))
  ;; list name
  (font-lock-add-keywords nil '(("\\(^[^ ].*?$\\)"
                                 1 font-lock-variable-name-face)))
  ;; comments
  (font-lock-add-keywords 'moonrat-mode '(("\\(//.*?$\\)"
                                           1 font-lock-comment-face)))
  ;; output block
  (font-lock-add-keywords 'moonrat-mode '(("\\(^output\\)"
                                           1 font-lock-function-name-face)))
  ;; other keywords?
  (setq font-lock-defaults '(moonrat-keywords))
  (setq-local comment-start "//")
  (setq-local indent-tabs-mode t)
  (font-lock-ensure))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mg\\'" . moonrat-mode))

(provide 'moonrat)

;;; moonrat.el ends here
