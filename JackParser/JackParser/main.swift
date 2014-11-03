import Foundation

let tokensFile = NSString(contentsOfFile: "tokens.txt", encoding: NSUTF8StringEncoding, error: nil)!
let tokens = readTokens(tokensFile)
let stream = TokenStream(tokens)

let (statements, remainingStream) = parseVariableDeclarations(stream)
//println(formatStatements(statements))
println(statements)
println("Remaining tokens: \(remainingStream)")