HackPlatform
============

This repository is a collection of experiments and fun projects inspired by [The Elements of Computing Systems](http://www.amazon.com/The-Elements-Computing-Systems-Principles/dp/0262640686/ref=sr_1_1?ie=UTF8&qid=1415126764&sr=8-1&keywords=elements+of+computing+system). Well, actually, it's just one — and knowing myself, I doubt I'll get back to it and complete other exercises from the book.

JackParser
----------

This is the parsing part of the Jack (simple high-level language devised for the book) compiler. It loads a list of tokens (from tokens.txt), parses them to produce an [abstract syntax tree](http://en.wikipedia.org/wiki/Abstract_syntax_tree) and then spits out a Jack source code recreated from AST into the console log.

The project isn't complete in that it doesn't include a lexer/tokenizer (it starts from tokens, not original source code) — that's simply because I've already written a lexer before ([here](https://github.com/radex/lodoovka_vm/blob/master/lodoovka_vm/lexer.swift) and [here](https://github.com/jneen/rouge/blob/master/lib/rouge/lexers/swift.rb)), so it wasn't fun/challenging anymore.

JackParser is written in Swift 1.2 and features a strong functional flavor. It operates on immutable, passed-by-value data (structs and enums), and all of the parsing is done via functions performing data transformations (no classes to be found). It's not fully functional in that I do mutate data inside of functions, but there's no global state, so it's pretty close.

All functions in the parser follow a similar pattern — they take a stream of tokens (basically an array of tokens yet to be parsed), attempt to find and parse whatever it is that they want to find (e.g. a function declaration) and either return a tuple of an AST fragment (e.g. a SubroutineDeclaration struct) and a transformed token stream (all of the tokens following the parsed fragment); or nil if the parsing function hasn't found what it was looking for.

**TokenStream** is an interesting bit. It's not very natural to return a portion of an Array (say, all elements from index 1) in Swift. It's probably wasteful too. It would be very easy in Haskell, because it uses linked lists instead of arrays (and also has function-level pattern matching and list deconstruction). So I tried to do something vaguely similar by wrapping a struct around the tokens array. Instead of mutating the underlying array, I only transform the stream by advancing its offset property (which basically says where to start reading for next token).
