#lang racket

;; string reader from mzlib/string -> 'read-from-string-all'
;;  via https://github.com/racket/compatibility/blob/master/compatibility-lib/mzlib/string.rkt

(provide read-from-string-all)

(define-syntax wrap-errors
  (syntax-rules ()
    [(wrap-errors who error-handler body ...)
     (if error-handler
       (with-handlers
           ([void
             (cond [(not (procedure? error-handler))
                    (error who "bad error handler: ~e" error-handler)]
                   [(procedure-arity-includes? error-handler 1)
                    error-handler]
                   [(procedure-arity-includes? error-handler 0)
                    (lambda (exn) (error-handler))]
                   [else (error who "bad error handler: ~e" error-handler)])])
         body ...)
       (begin body ...))]))

(define (open-input-bstring s)
  (if (bytes? s) (open-input-bytes s) (open-input-string s)))

(define (read-from-string-all str [error-handler #f])
  (let ([p (open-input-bstring str)])
    (wrap-errors 'read-from-string-all error-handler
      (let loop ([r '()])
        (let ([v (read p)])
          (if (eof-object? v) (reverse r) (loop (cons v r))))))))
