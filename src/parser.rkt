#! /usr/bin/env racket
#lang racket

;; Simple parser for MRG text generators.
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

(provide (all-defined-out)
         (all-from-out parsack))

(require parsack)

;;;;;; ; ;  ;;
;;
;; parsing & combinations
;;

;; string escape/quoting
(define (qstring s)
  (cond
    ((string? s) (string-append "\"" s "\""))
    ((char? s) (string-append "\"" (make-string 1 s) "\""))
    ((list? s)
     (cond ((eq? (length s) 1)
            (qstring (car s)))
           (else (map qstring s))))
    (else "")))

;; numerics
(define $integer
  (<?> (parser-compose
        (x <- (many $digit))
        (return (list->string x)))
       "integer"))

(define $decimal
  (<?> (parser-compose
        (x <- (many1 $digit))
        (char #\.)
        (y <- (many $digit))
        (return
         (string-join (map list->string (list x y)) ".")))
       "decimal"))

(define $number (<or> $integer $decimal))

;; basic punctuation (and/or unicode/emojis?)
(define $punctuation
  (<?> (oneOf ",.:;/!?$&=><'\\\"()") "punctuation"))

;; characters used for operators
(define $operator
  (<?> (oneOf "[]{}") "operator character"))

;; a word is a string of 1 or more alphanumeric characters (with some modifiers)
(define $basic-word
  (<?> (parser-compose
        (x <- (many1 (<any> $alphaNum (oneOf "_-&"))))
        (return (list->string x)))
       "basic word"))

;; only one sort of word (for now)
(define $word
  (<?> $basic-word
       "word"))

;; text is just words with semantics
(define $text
  (<?> (parser-compose
        (x <- (<any> $word $punctuation
                     (and $anyChar (<!> $operator)))) ;; unicode?
        (return (list 'text (qstring x))))
       "text"))

;; significant whitespace
(define $spc
  (<?> (parser-compose
        $space
        (return (list 'text (qstring #\space))))
       "printable space"))

;; blank line
(define $blank
  (<?> (parser-compose
        (x <- (<any> $eol (parser-seq (skipMany $space) $eol)))
        (return null))
       "blank line"))

;; comments are strings beginning with "//" that are ignored
(define $comment
  (<?> (parser-compose (string "//")
                       (x <- $line)
                       (return null))
       ;; (return (list 'comment (map qstring x))))
       "comment"))

;; a [word] which subsitutes from a list
(define $select
  (<?> (parser-compose (char #\[)
                       (x <- $word)
                       (char #\])
                       (return (list 'select-from-list
                                     (qstring x))))
       "select"))

;; selection with operator e.g. [word.capitalize]
(define $select-dot
  (<?> (parser-compose (char #\[)
                       (x <- $word)
                       (char #\.)
                       (y <- $word)
                       (char #\])
                       (return (list (string->symbol y)
                                     (list 'select-from-list
                                           (qstring x)))))
       "select.dot"))

;; curly operators
;;   {a|b} -> $choice
;;   {import: } ->
;;   {n-m} -> range of numbers
;;   {A} -> look ahead article e.g {a|an}
;;   {s} -> pluralize

;; multiple choice
(define $choice
  (<?> (parser-compose
        (char #\{)
        (x <- (many1 (<or> (try $probability-modifier)
                           $word $spc)))
        (char #\|)
        (y <- (sepBy1 (many1 (<or> (try $probability-modifier)
                                   $word $spc))
                      (char #\|)))
        (char #\})
        (return (list 'choose
                      (list 'quote
                            (cons (qstring x)
                                  (map qstring y))))))
       "choice"))

;; a range of numbers
(define $range
  (<?> (parser-compose (char #\{)
                       (x <- $number)
                       (char #\-)
                       (y <- $number)
                       (char #\})
                       (return (list 'random-integer x y)))
       "range"))

;; import from a file
;;  - {import:name} or {import.name.list}
;;  - just 'name' uses a list from a file (list name is same as basename)
;;  - name.list is a 'list' in file 'name'
;;  - only {import:name} supported for now?

(define $import
  (<?> (parser-compose (string "{import:")
                       (x <- $basic-word)
                       (char #\})
                       (return (list 'import-list (qstring x))))
       "import"))

;; things that can have articles or plurals
;; - $word $select $select-dot $import $choice

;; the correct indefinte article via {a}
(define $article-modifier
  (<?> (parser-compose
        (oneOfStrings "{a} " "{A} ")
        (x <- (many1 (<any> $word
                            $select
                            $select-dot
                            $import
                            $choice))) ;; token? order of precedence?
        (return (cons 'mod-article x)))
       "{a} modifier"))

;; potential plurals via {s} -> lookahead/rewind
(define $plural-modifier
  (<?> (parser-compose
        (x <- (many1 (<or> $word
                           (try $select)
                           (try $import)
                           (try $choice)))) ;; token? order of precedence?
        (string "{s}")
        (return (cons 'mod-plural x)))
       "modifer{s}"))

;; probability modifier e.g. word^2 (unimplemented)
(define $probability-modifier
  (<?> (parser-compose
        (x <- $word) ;; token? order of precedence?
        (char #\^)
        $number
        (return (list 'text (qstring x))))
       "prob^n?"))


;; things like {this}
;; - choice
;; - article modifier
;; - plural modifier
;; - range
;; - import

(define $op-curl
  (<?> (<or>
        (try $choice)
        (try $import)
        (try $range))
       "{operator}"))

(define $modifier
  (<?> (<or>
        (try $article-modifier)
        (try $plural-modifier)
        (try $probability-modifier))
       "modifier"))

;; things like [this]
;; - substitution
;; - sub with dot operator

(define $op-square
  (<?> (<or>
        (try $select)
        (try $select-dot))
       "[operator]"))

;; types of wordlike things
(define $token
  (<?> (<or> $text
             $spc
             $punctuation
             $op-curl
             $op-square
             (try $comment))
       "wordlike token"))

;; a line can be composed of wordlike tokens...
(define $line
  (<?> (parser-compose
        (x <- (manyTill (<or> $modifier $token)
                        (<or> $eol $eof)))
        (return (apply ~a x)))
       "line"))

;; an element is a space indented, non blank line
(define $element
  (<?> (parser-compose (string "  ")
                       (x <- $line)
                       (return x)) "element"))

;; a list is a single word name followed by indented lines
(define $list
  (<?> (parser-compose (x <- $word) $eol
                       (y <- (many $element))
                       (return (list 'add-list
                                     (cons x y)))) "list"))

;; generate and test
(define $generator
  (parser-compose
   (x <- (many (<or> $list
                     $blank
                     $comment)))
   $eof
   (return x)))
