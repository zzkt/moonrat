#! /usr/bin/env racket
#lang racket

;; Simple generator for MRG text generators.
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

;; Requirements
;;  - parsack, english & mzlib/string for retro compatibility

;; Commentary
;;  see https://github.com/zzkt/moonrat
;;
;;  current coverage
;;   - lists & substitutions
;;   - choice
;;   - comments are (mostly) ignored
;;   - a/an articles with {a}
;;   - plural using an {s} suffix
;;   - [animal.pluralForm] -> [animal]{s}
;;   - numeric ranges (e.g. {1-33})
;;   - (some) capitalisation
;;
;;  not yet
;;   - probability modifiers (e.g. worm^2)
;;   - import (e.g. {import:noun}
;;   - general inline processing (e.g. [animal.pluralForm] or [name.titleCase])
;;   - nested lists (e.g. [descriptor.lifeforms.consumableList] )
;;   - assignment and/or storing selections (e.g. [w = word.selectOne] )
;;
;;  issues
;;   - semi-semantic whitespace (trim and/or remove)
;;   - $choice at beginning of line?
;;   - not very useful parse errors -> guides
;;   - shared/overwritten generator hash -> one per output?
;;   - unreliable comment detection


(provide (all-defined-out))

(require english           ;; articles & plurals
         "parser.rkt"
         "verbose.rkt"
         "reader.rkt")     ;; read-from-string-all

(define-namespace-anchor an0)
(define ns0 (namespace-anchor->namespace an0))

;;;;;; ;; ;
;;
;; construction & alleviation
;;

;; main generator -> (generate)
(define (output x)
  (verbose "output:  ~a~n" x))

;; text
(define (text x)
  (verbose "text: ~s~n" x)
  x)

;; choices
(define (choose x)
  (verbose "choose -> ~a~n" x)
  (let ((choice (car (shuffle x))))
    (verbose "choice: ~a~n" choice)
    choice))

;; import and substitute from list
(define (import-list x)
  (verbose "import: ~a~n" x)
  " ")

;; a number (int) within the given range
(define (random-integer x y)
  (verbose "range: ~s-~s~n" x y)
  (number->string (random x y)))

;; modifier - articles
(define (mod-article x)
  (verbose "article: ~s~n" x)
  (cond ((non-empty-string? x) (a/an x))
        ((list? x) (a/an (string-join (flatten x) "")))
        (else "")))

;; modifier - plural
(define (mod-plural x)
  (verbose "plural: ~s~n" x)
  (cond ((non-empty-string? x) (plural x))
        ((list? x) (apply plural x))
        (else "")))

(define (comment x)
  (verbose "comment: ~a~n" x))

;; probably per generator rather than shared...
(define substitution-lists (make-hash))

(define (add-list l)
  (hash-set! substitution-lists (car l) (rest l)))

(define (reset-generator)
  (hash-clear! substitution-lists))


(define (select-from-list name)
  (verbose "select from list '~a': ~s~n" name (hash-ref substitution-lists name))
  (let ((es
         (read-from-string-all
          (car (shuffle (hash-ref substitution-lists name))))))
    (verbose "substitute -> ~a~nwith -> ~s~n" name es)
    (szeval es)))

(define (format-result l)
  (when (list? l)
    (string-join (flatten l) "")))

(define (generate)
  (verbose "generating...~n")
  (format-result
   (select-from-list "output")))


;; load a generator from a string or file
(define (load-generator-string str)
  (for-each eval-form
            (parse-result $generator str)))

(define (load-generator-file path)
  (call-with-input-file* path
    (lambda (string)
      (load-generator-string string))))


;; optional extras to convert
(define (title-case s)
  (verbose ".titleCase: ~s~n" s)
  (string-titlecase
   (string-join (flatten (list s)) "")))

(define (upper-case s)
  (verbose ".upperCase: ~s~n" s)
  (string-upcase
   (string-join (flatten (list s)) "")))

;; use 'plural' etc. from 'english'

;;;;;; ;; ;
;;
;; apply/eval loops
;;

;; eval forms of shape '(name (str ...))
;; e.g. '(choose ("this" "that" "the other"))

(define (szeval f)
  (verbose "szeval: ~s ~n" f)
  (cond
    ((symbol? f)
     (eval f ns0))
    ((list? f)
     (map (lambda (e) (eval e ns0)) f))
    (else null)))

(define (szpply f a)
  (verbose "szpply: ~s -> ~s ~n" f a)
  (apply f a))

(define (eval-form f)
  (verbose "eval-form: ~s~n" f)
  (when (not (null? f))
    (szpply (szeval (car f)) (cdr f))))
