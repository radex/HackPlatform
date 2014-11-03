//import Foundation

func parseStatements(stream: TokenStream) -> ([Statement], TokenStream) {
    var statements: [Statement] = []
    var workingStream = stream
    while let (statement, stream) = parseStatement(workingStream) {
        statements.append(statement)
        workingStream = stream
    }
    return (statements, workingStream)
}

func parseStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    return parseWhileStatement(stream) ?? parseLetStatement(stream)
}

func parseWhileStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if stream.isEmpty || stream[0] != .Keyword("while") {
        return nil
    }
    
    assert(stream[1] == .Symbol("("))
    let (expr, stream) = parseExpression(stream.advance(2))!
    assert(stream[0] == .Symbol(")"))
    
    assert(stream[1] == .Symbol("{"))
    let (statements, stream2) = parseStatements(stream.advance(2))
    assert(stream2[0] == .Symbol("}"))
    
    let whileStatement = Statement.While(condition: expr, statements: statements)
    return (whileStatement, stream2.advance(1))
}

func parseLetStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if stream.isEmpty || stream[0] != .Keyword("let") {
        return nil
    }
    
    var variableName: String
    
    switch stream[1] {
    case .Identifier(let varName): variableName = varName
    default: fatalError("Variable name must follow the let keyword")
    }
    
    assert(stream[2] == .Symbol("="))
    let (expr, stream) = parseExpression(stream.advance(3))!
    assert(stream[0] == .Symbol(";"))
    
    let statement = Statement.Let(variable: variableName, expression: expr)
    return (statement, stream.advance(1))
}

func parseExpression(stream: TokenStream) -> (Expression, TokenStream)? {
    if let (firstTerm, stream) = parseTerm(stream) {
        let (extraTerms, stream) = parseOpTerms(stream)
        return (Expression(firstTerm: firstTerm, extraTerms: extraTerms), stream)
    } else {
        return nil
    }
}

func parseOpTerms(stream: TokenStream) -> ([(Operator, Term)], TokenStream) {
    var extraTerms: [(Operator, Term)] = []
    var workingStream = stream
    while let (op, term, stream) = parseOpTerm(workingStream) {
        extraTerms.append((op, term))
        workingStream = stream
    }
    return (extraTerms, workingStream)
}

func parseOpTerm(stream: TokenStream) -> (Operator, Term, TokenStream)? {
    if let (op, stream) = parseOp(stream) {
        if let (term, stream) = parseTerm(stream) {
            return (op, term, stream)
        }
    }
    
    return nil
}

func parseTerm(stream: TokenStream) -> (Term, TokenStream)? {
    if stream.isEmpty {
        return nil
    }
    
    switch stream[0] {
    case .Number(let number):
        return (.IntegerConstant(number), stream.advance(1))
    case .Identifier(let id):
        return (.VariableName(id), stream.advance(1))
    default:
        return nil
    }
}

func parseOp(stream: TokenStream) -> (Operator, TokenStream)? {
    if stream.isEmpty {
        return nil
    }
    
    switch stream[0] {
    case .Symbol(let symbol):
        switch symbol {
        case "<": return (.Lt, stream.advance(1))
        case "+": return (.Plus, stream.advance(1))
        default:
            return nil
        }
    default:
        return nil
    }
}