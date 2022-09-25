#lang scribble/manual
@require[@for-label[moonrat
                    racket/base]]

@title{Moon Rat Gardener}
@author[(author+email "nik gaffney" "nik at fo.am")]

@defmodule[moonrat]

@section[#:tag "sec0"]{Moon Rat Gardening}

A simple template based text generator. aka. Moon Rat Gardener

MRG is a template based text generator closely following the @hyperlink["https://perchance.org"]{perchance} grammar and borrowing features (or non-features) from similar generators such as rant, tracery, lorem ipsum, dada engine etc. MRG aims to be simple to use and easy to read. Extensibility is possible but shouldn’t be at the expense of readability or simplicity. Extraneous syntax is kept to a minimum.

Generators are usually built around list substitution (such as this example from the perchance documentation).

@verbatim{
output
  Your [pack] contains [item], [item] and [item].

pack
  purse
  backpack
  bag
  pack
  knapsack
  rucksack

item
  a few coins
  an old {silver|bronze} ring
  a handkerchief
  a shard of bone
  some lint
  a tin of tea leaves
}

This template generates sentences like “Your purse contains some lint, a few coins and a handkerchief.” or “Your knapsack contains a few coins, a shard of bones and an old silver ring.”

@section[#:tag "sec1"]{Writing templates}

Templates are written in plain text with placeholders for text that can be replaced. They are usually based around lists of words or phrases. Special characters are limited to the square and curly brackets. i.e. “[ ]” and “{ }”. (Further examples can be found in the data folder).

The inclusion of a word in square brackets, like @tt{[word]}, will select an item from the list named @tt{word}. A list begins with a single word label and is followed by lines indented with 2 spaces.

Curly brackets can be used to indicate a choice, @tt{{this|that|the other}} or a range of numbers @tt{{1-101}} and can also be used to generate the correct article or plural for a word using @tt{{a}} or @tt{{s}} (e.g. @tt{fish{s}} generates “fishes” and @tt{ox{s}} generates “oxen”)

There are some modifier functions with the form @tt{[word.modifier]} that can be used to as filters (e.g. @tt{[mouse.plural]} give “mice” or @tt{[mouse.upcase]} gives “MOUSE”)

A template needs to include an @tt{output} label with at least one item. An element is chosen randomly from the @tt{output} list and used to generate a single output text.

@verbatim{
output
  one word
}

The @tt{output} items can select from a list like so…

@verbatim{
output
  [word]

word
  lonely
}

@section[#:tag "sec3"]{Generate text}

@defform[(load-generator-file file-path)
         #:contracts ((file-path string?))]{
Load an MRG template from a file.}

@defform[(load-generator-string template)
         #:contracts ((template string?))]{
Load an MRG template from a string.}

@defform[(generate)]{
Generate some text from the currently active MRG template.}

@bold{Generate text from a racket programme}

Read a template from a file and generate text...

@codeblock{
#lang racket           
(require moonrat)
(load-generator-file "music-genre.mg")
(generate)
}

@bold{Generate text from the command line}

Run @tt{moonrat} with a template file to generate text on the command line…

@verbatim{raco moonrat data/music-genre.mg}

further details…

@verbatim{raco moonrat -h}

@section[#:tag "sec4"]{Moon Grade Ranter}

@hyperlink["https://tinysubversions.com/"]{Darius Kazemi} has compiled a @hyperlink["https://github.com/dariusk/corpora"]{collection of copora} for “the creation of weird internet stuff” specifically for text generation. MRG includes a basic conversion utility to help use these lists with moonrat. The converted lists are not validated in any way and will almost certainly need some manual coercion to be useful.

copora can be converted from a given url

@verbatim{raco cp2mg -u https://raw.githubusercontent.com/dariusk/corpora/master/data/colors/fictional.json}

or file…

@verbatim{raco cp2mg -f data/corpora/interjections.json -o data/interjections.mg}

@section[#:tag "sec5"]{Weird Machinery}

The templates are almost certainly a weird machine capable of unexpected machinations using list substitution (well formed recursive lists) and choice (even without assignment). Implementation is left as an exercise for the reader (see also string rewriting and @hyperlink["https://esolangs.org/wiki/Antigram"]{antigram})

@section[#:tag "sec6"]{Syntax & grammar}

@itemlist[@item{output}
          @item{a word}
          @item{a [word]}
          @item{{word|another word}}
          @item{{a} thing}
          @item{some thing{s}}
          @item{a [word.plural]}
          @item{[the four word title.title-case]}
          @item{a [nested.list.word]}
          @item{// comments are on a line by themselves (not yet inline)}]

(to be continued…)

@section[#:tag "sec7"]{links & further}

Included, precluded, transcluded and occluded…

@itemlist[@item{@hyperlink["https://perchance.org/useful-generators"]{useful perchance generators}}
          @item{@hyperlink["https://perchance.org/generators"]{more perchance generators}}
          @item{@hyperlink["https://github.com/rant-lang/rant"]{rant}}
          @item{@hyperlink["https://dev.null.org/dadaengine/manual-1.0/dada_toc.html"]{the dada engine}}
          @item{@hyperlink["https://github.com/dariusk/corpora"]{corpora}}
          @item{@hyperlink["https://github.com/catseye/NaNoGenLab"]{NaNoGenLab}}]
