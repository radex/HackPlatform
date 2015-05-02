import Foundation

enum Token {
    case Identifier(Swift.String)
    case Keyword(Swift.String)
    case Symbol(Swift.String)
    case Number(Int)
    case String(Swift.String)
}

extension Token: Printable {
    var description: Swift.String {
        switch self {
        case .Keyword(let str): return "Keyword \(str)"
        case .Symbol(let str): return str
        case .Number(let num): return "\(num)"
        case .String(let str): return "\"\(str)\""
        case .Identifier(let str): return "id '\(str)'"
        }
    }
}

extension Token: Equatable {}

func ==(a: Token, b: Token) -> Bool {
    switch (a, b) {
    case (.Keyword(let a),    .Keyword(let b))    where a == b: return true
    case (.Symbol(let a),     .Symbol(let b))     where a == b: return true
    case (.Number(let a),     .Number(let b))     where a == b: return true
    case (.String(let a),     .String(let b))     where a == b: return true
    case (.Identifier(let a), .Identifier(let b)) where a == b: return true
    default: return false
    }
}

extension Token {
    private enum GetterType {
        case Keyword, Symbol, String, Identifier
    }
    
    func getKeyword() -> Swift.String? {
        return get(.Keyword)
    }
    
    func getSymbol() -> Swift.String? {
        return get(.Symbol)
    }
    
    func getNumber() -> Int? {
        switch self {
        case .Number(let v): return v
        default: return nil
        }
    }
    
    func getString() -> Swift.String? {
        return get(.String)
    }
    
    func getIdent() -> Swift.String? {
        return get(.Identifier)
    }
    
    private func get(what: GetterType) -> Swift.String? {
        switch (what, self) {
        case (.Keyword, .Keyword(let v)): return v
        case (.Symbol, .Symbol(let v)): return v
        case (.String, .String(let v)): return v
        case (.Identifier, .Identifier(let v)): return v
        default: return nil
        }
    }
}

func readTokens(tokens: String) -> [Token] {
    return tokens.componentsSeparatedByString("\n")
        .filter { !$0.isEmpty }
        .map { readToken(lstrip($0) as String) }
}

private func readToken(token: String) -> Token {
    let token = extractToken(token, "keyword") { .Keyword($0) } ??
                extractToken(token, "symbol") { .Symbol($0) } ??
                extractToken(token, "number") { .Number(($0 as NSString).integerValue) } ??
                extractToken(token, "string") { .String($0) } ??
                extractToken(token, "identifier") { .Identifier($0) }
    
    return token!
}

func extractToken(token: NSString, prefix: String, builder: String -> Token) -> Token? {
    let prefix = "\(prefix) "
    
    if token.hasPrefix(prefix) {
        let value = token.substringFromIndex(count(prefix.utf16))
        return builder(value)
    } else {
        return nil
    }
}

func lstrip(string: NSString) -> NSString {
    if string.hasPrefix(" ") || string.hasPrefix("\t") {
        return lstrip(string.substringFromIndex(1))
    } else {
        return string
    }
}