#lang racket

;; MRG parsing & generator tests

(module+ test
  ;; Any code in this `test` submodule runs when this file is run using DrRacket
  ;; or with `raco test`. The code here does not run when this file is
  ;; required by another module.

  (require rackunit
           "parser.rkt"
           "reader.rkt"
           "verbose.rkt"
           "generator.rkt")

  (define test0 "adjective
  
  small
  big
  cute
  sneaky
  unusual
  helpful
  mean
")

  (define test1 "
output
  {This|That} [animal] is so [adjective]!
  I wish I could [verb] that [animal].
  Aren't [animal]{s} just so [adjective]?
  There must be at least four [animal]{s} (or [animal]{s}) [location]!
  THE [animal]! It's eating {a} [common-noun]!
  {A} [animal] is a bit like {a} [common-noun].

animal
  pig
  mouse
  chicken
  zebra
  fish
  jellyfish
  worm
  armadillo

adjective
  small
  big
  cute
  sneaky
  unusual
  helpful
  mean

verb
  pat
  befriend
  help

location
  on {the|this|that} island
  in {the|this|that} valley
  {around|in} here
  over there
  under {a} {thing|thingie}

common-noun
  spoon
  block
  slab
  archive
")

  (define test2 "
output
  {This|That} [animal] is so [adjective]!
  I wish I could [verb] that [animal].
  Aren't [animal]{s} just so [adjective]?
  There must be at least {1-10} [animal]{s} [location]!
  THE [animal.upper-case]! It's eating the {import:common-noun}!
  {A} [animal] is a bit like {a} {import:common-noun}.

animal
  pig
  cow
  chicken
  zebra
  crayfish
  jellyfish^0.5
  worm^2

adjective
  small
  big
  cute
  sneaky
  unusual
  helpful
  mean

verb
  pat
  befriend
  help

location
  on {the|this|that} island
  in {the|this|that} valley
  {around|in} here
  over there
  under this {thing^2|thingie}
")

  (define test3 "// description: Unexpected Guests

output
  {A} [adjective] [character] [unexpectedly] with {a} [noun1] that [verbs-thing]
  {A} [character] [wearing], appearing [mood] with {a} [accessory]
  [honorific] [character] ({a} [occupation])
  {A} [character] eating {a} [biological-diet] [fast-food]

character
  mycologist
  installation artist
  DJ
  pilgrim
  brother-in-law

verb
  agree
  alert
  allow
  amuse
  analyse
  announce
  annoy
  answer

unexpectedly
  becomes a clock tower
  looms at the door

wearing
  wearing [fabric]
  wearing [clothing]

fabric
  silk
  rubber
  impractical

clothing
  a cap
  a cardigan
  a coat
  a cravat
  rubber boots
  scuba diving gear

mood
  baffled
  bashful
  benevolent
  betrayed
  bewildered
  bitter

accessory
  travelling trunk
  untuned balalaika
  soldering iron
  mummified cat
  stolen e-bike
  box

adjective
  shuffling
  extremely thin
  massive
  dark
  formless
  still

noun1
  beast
  spider
  insect
  thing
  bird
  humanoid

noun2
  long arms
  alien tattoos
  tumorous growths
  countless limbs
  eyes
  a single unblinking eye

verbs-thing
  eats dreams
  brings gifts
  turns into something else
  causes chaos
  reflects the moonlight
  is an extension of a greater organism

biological-diet
  apivorous
  baccivorous
  batrachivorous
  carnivorous
  cepivorous
  limivorous

fast-food
  burger
  burger
  burger
  burger
  burger
  burger

honorific
  Mr
  Ms
  Dr
  Count
  Sir
  Lady

occupation
  mycologist
  artist
  cook
  dragon breeder
  collector
  human
")

  ;; basic tests

  (check-equal?
   "word" (parse-result $word "word"))

  (check-equal?
   '(mod-article "oblong") (parse-result $article-modifier "{a} oblong"))

  (printf "choice: ~a~n" (parse-result $choice "{wonk|wonkier}"))
  (printf "word: ~a~n" (parse-result $word "wonk"))
  (printf "number: ~a~n" (parse-result $number "1"))
  (printf "number: ~a~n" (parse-result $number "101"))
  (printf "number: ~a~n" (parse-result $number "101.99"))
  (printf "a word: ~a~n" (parse-result $article-modifier "{a} wonk"))
  (printf "a word: ~a~n" (parse-result $article-modifier"{a} oblong"))
  (printf "substitute: ~a~n" (parse-result $select "[oblong]"))
  (printf "plural: ~a~n" (parse-result $plural-modifier "oblong{s}"))
  (printf "plural: ~a~n" (parse-result $plural-modifier "tooth{s}"))
  (printf "plural: ~a~n" (parse-result $plural-modifier "[oblong]{s}"))
  (printf "plural: ~a~n" (parse-result $article-modifier "{a} [thing]"))
  (printf "choice: ~a~n" (parse-result $choice "{wonk|wonkier}"))
  (printf "range: ~a~n" (parse-result $range "{7-33}"))
  (printf "line: ~a~n" (parse-result $line "a simple line"))
  (printf "line: ~a~n" (parse-result $line "{A} ordinary line"))

  ;; implement prob?
  (printf "prob?: ~s~n"(parse-result $probability-modifier "simple^2"))
  (printf "prob?: ~s~n"(parse-result $probability-modifier "simple^0.75"))

  ;; (printf "line: ~s~n" (parse-result $line "a {simple^0.5|complex} line"))

  (printf "list: ~a~n" (parse-result $list test0))

  ;;  (define out1 (parse-result $generator test1))
  ;;  (printf "out1: ~a~n" (length out1))

  (verbose? #t)

  (define out2 (parse-result $generator test2))

  (printf "~neval...~n")
  (for-each eval-form out2)

  (printf "~ngenerate...~n")
  (generate)

  ;;(printf "~nload from file...~n")
  ;;(load-generator-file "../data/adjective.mg")
  ;; (load-generator-file "../data/unexpected-guests.mg")

  ;;(printf "~ngenerate...~n")
  ;;(generate)

  (printf "~ntested...~n")

  ) ;; end module
