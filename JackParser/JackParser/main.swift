import Foundation

let tokensFile = NSString(contentsOfFile: "tokens.txt", encoding: NSUTF8StringEncoding, error: nil)!
let tokens = readTokens(tokensFile)
let stream = TokenStream(tokens)

let (statements, remainingStream) = parseStatements(stream)
println(formatStatements(statements))
println("Remaining tokens: \(remainingStream)")