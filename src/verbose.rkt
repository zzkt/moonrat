#lang racket/base

(provide verbose?
         verbose)

;; echoing verbosity
(define verbose? (make-parameter #f))

(define-syntax verbose
  (syntax-rules ()
    ((verbose str ...) (when (verbose?) (printf str ...)))))
