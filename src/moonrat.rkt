#! /usr/bin/env racket
#lang racket

;; Random text generator using MRG templates.
;;
;; Copyright (C) 2022 FoAM
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see http://www.gnu.org/licenses/

;; Authors
;;  - nik gaffney <nik@fo.am>

;; Commentary
;;  command line interface to MRG

(require moonrat)

(define filename (make-parameter ""))

(define getopt
  (when (not (vector-empty?
              (current-command-line-arguments))) ;; i.e. cli or not?
    (command-line
     #:program "moonrat"
     #:once-each
     (("-v" "--verbose")   "various verbose messages" (verbose? #t))

     #:args (input-file)
     (filename input-file)
     (parameterize ((verbose? (verbose?)))
       (if (file-exists? (filename))
           (let ((path (filename)))
             (verbose "Using generator from ~a\n" path)
             (load-generator-file path)
             (printf "~a~n" (generate)))
           (raise-user-error 'moonrat "File '~a' does not exist." (filename)))))))
