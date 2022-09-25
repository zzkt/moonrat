#! /usr/bin/env racket
#lang racket

;; Conversion utility for corpora.json files to MRG templates
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

;; Darius Kazemi has compiled a collection of copora for “the creation
;; of weird internet stuff” specifically for text generation.
;; This is a basic conversion utility to help use these lists with moonrat.
;; The converted lists are not validated in any way and will almost
;; certainly need some manual coercion to be useful.

;; https://github.com/dariusk/corpora/blob/master/data/animals/ant_anatomy.json

(require json
         net/url)

;; echoing verbosity
(define-syntax verbose
  (syntax-rules ()
    ((verbose str ...) (when (verbose?) (printf str ...)))))

;;  remapping
(define (cp2mg path)
  (let ((corpora (load-corpora-file path)))
    (hash-map corpora
              parse-element)))

(define (parse-element k v)
  (verbose "parsing: ~s -> ~s~n" k v)
  (cond
    ;; comments, source or description
    ((string-ci=? (stringify k) "comments")
     (format "// ~a~n" (stringify v)))
    ((string-ci=? (stringify k) "description")
     (format "// description: ~a~n" v))
    ((string-ci=? (stringify k) "source")
     (format "// source: ~a~n" v))
    ;; nested list
    ((and (string? (stringify k)) (hash? v))
     (verbose "~nparsing nested string & hash...~n")
     (format "~a~n  ~a~n" (stringify k) (hash-map v parse-element)))
    ;; list of options
    ((and (string? (stringify k)) (list? v))
     (verbose "~nparsing string & list: ~s -> ~s~n" k v)
     (format "~a~n  ~a~n"
             (stringify k)
             (string-join (map stringify v) "\n  ")))
    ;; list with single option
    ((and (string? (stringify k)) (string? (stringify v)))
     (verbose "~nparsing string & string: ~s -> ~s~n" k v)
     (format "~a~n  ~a~n" (stringify k) (stringify v)))
    ;; something else
    (else "wonk?")))

(define (description-prefix? s)
  (when (not (null? s))
    (string-prefix? s "// description")))

;; output
(define (print-element e)
  (cond
   ((string? e) (printf e))
   ((symbol? e) (printf e))
   ((number? e) (printf e))
   ((list? e) (printf "~a" (string-join (flatten e))))
   (else null)))

(define (format-element e)
  (cond
   ((string? e) (format "~a" e))
   ((symbol? e) (format "~a" e))
   ((number? e) (format "~a" e))
   ((list? e) (format "~a" (string-join (flatten e))))
   (else null)))

(define (print-corpora l)
  (for-each
   print-element
   (cons
    (car (filter description-prefix? l))
    (filter (lambda (e) (not (description-prefix? e))) l))))

(define (format-corpora l)
  (string-join
   (map
    format-element
    (cons
     (car (filter description-prefix? l))
     (filter (lambda (e) (not (description-prefix? e))) l)))))

;; text [un]mangling
(define (stringify s)
  (cond
    ((string? s) s)
    ((symbol? s) (symbol->string s))
    ((number? s) (number->string s))
    ((list? s) (string-join (flatten s)))
    (else "")))

;; load a corpora from a string or file
(define (load-corpora-string str)
  (read-json str))

(define (load-corpora-file path)
  (call-with-input-file* path
    (lambda (string)
      (load-corpora-string string))))

;; or a url
(define (load-corpora-url url)
  (let ((corpora (call/input-url
                  (string->url url)
                  get-pure-port
                  load-corpora-string)))
    (hash-map corpora
              parse-element)))

;; cli options

(define verbose? (make-parameter #f))
(define filename (make-parameter ""))
(define out (make-parameter ""))
(define url (make-parameter ""))


(define getopt
  (when (not (vector-empty?
              (current-command-line-arguments))) ;; i.e. cli or not?
    (command-line
     #:program "cp2mg"
     #:once-each
     (("-v" "--verbose")   "various verbose messages" (verbose? #t))
     (("-f" "--from-file")   path "convert from file" (filename path))
     (("-o" "--output-file") path "write output to file" (out path))
     (("-u" "--url")         uri "convert from url" (url uri))
     )))

(define (process-cli)
  (when (non-empty-string? (url))
    (let ((output (load-corpora-url (url))))
      (verbose "Converting corpora from url: ~a\n" (url))
      (if (non-empty-string? (out))
          (display-to-file (format-corpora output)
                         (out) #:exists 'replace)
          (print-corpora output))))
  (when (non-empty-string? (filename))
    (if (file-exists? (filename))
        (let* ((path (filename))
               (output (cp2mg path)))
          (verbose "Converting corpora from file: ~a\n" path)
          (if (non-empty-string? (out))
              (display-to-file (format-corpora output)
                               (out) #:exists 'replace)
              (print-corpora output)))
        (raise-user-error 'cp2mg "File '~a' does not exist." (filename)))))

(process-cli)
