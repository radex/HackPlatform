import Foundation

let tokensFile = NSString(contentsOfFile: "tokens.txt", encoding: NSUTF8StringEncoding, error: nil)!
let tokens = readTokens(tokensFile)
let stream = TokenStream(tokens)

let (decl, remainingStream) = parseSubroutineDeclarations(stream)
println(formatList(decl))
println("Remaining tokens: \(remainingStream)")