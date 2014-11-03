import Foundation

let tokensFile = NSString(contentsOfFile: "tokens.txt", encoding: NSUTF8StringEncoding, error: nil)!
let tokens = readTokens(tokensFile)
let stream = TokenStream(tokens)

let (varDecls, statements, remainingStream) = parseSubroutineBody(stream)
println(formatList(varDecls))
println(formatList(statements))
println("Remaining tokens: \(remainingStream)")