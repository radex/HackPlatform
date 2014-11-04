import Foundation

let tokensFile = NSString(contentsOfFile: "tokens.txt", encoding: NSUTF8StringEncoding, error: nil)!
let tokens = readTokens(tokensFile)
let stream = TokenStream(tokens)

let (klass, remainingStream) = parseClass(stream)!
println(klass)
println("Remaining tokens: \(remainingStream)")