struct TokenStream: Printable {
    private let tokens: [Token]
    
    init(_ tokens: [Token]) {
        self.tokens = tokens
    }
    
    private(set) var offset = 0
    
    subscript(i: Int) -> Token {
        return tokens[offset + i]
    }
    
    var isEmpty: Bool { return count == 0 }
    
    func advance(n: Int) -> TokenStream {
        var stream = self
        stream.offset += n
        return stream
    }
    
    var count: Int { return tokens.count - offset }
    
    var description: String {
        return tokens[offset..<tokens.count].description
    }
    
    func get(n: Int) -> [Token]? {
        if count < n {
            return nil
        } else {
            return Array(tokens[offset..<(offset+n)])
        }
    }
    
    // checkers
    
    func isKeyword(keyword: String) -> Bool {
        return !isEmpty && self[0] == .Keyword(keyword)
    }
    
    func isSymbol(sym: String) -> Bool {
        return !isEmpty && self[0] == .Symbol(sym)
    }
}