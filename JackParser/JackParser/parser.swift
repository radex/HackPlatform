import Foundation

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
    return parseWhileStatement(stream) ??
        parseIfStatement(stream) ??
        parseLetStatement(stream) ??
        parseReturnStatement(stream)
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

func parseIfStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if stream.isEmpty || stream[0] != .Keyword("if") {
        return nil
    }
    
    assert(stream[1] == .Symbol("("))
    let (expr, stream) = parseExpression(stream.advance(2))!
    assert(stream[0] == .Symbol(")"))
    
    assert(stream[1] == .Symbol("{"))
    let (statements, stream2) = parseStatements(stream.advance(2))
    assert(stream2[0] == .Symbol("}"))
    
    let (elseStatements, stream3) = parseElseStatements(stream2.advance(1))
    
    let ifStatement = Statement.If(condition: expr, ifStatements: statements, elseStatements: elseStatements)
    return (ifStatement, stream3)
}

func parseElseStatements(stream: TokenStream) -> ([Statement]?, TokenStream) {
    if stream.isEmpty || stream[0] != .Keyword("else") {
        return (nil, stream)
    }
    
    assert(stream[1] == .Symbol("{"))
    let (statements, stream) = parseStatements(stream.advance(2))
    assert(stream[0] == .Symbol("}"))
    
    return (statements, stream.advance(1))
}


func parseLetStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    var stream = stream
    
    if stream.isEmpty || stream[0] != .Keyword("let") {
        return nil
    }
    
    // extract variable
    let (variableName, sub, newStream) = parseVariableNameSubscript(stream.advance(1))!
    stream = newStream
    
    // extract value
    assert(stream[0] == .Symbol("="))
    let (expr, newStream2) = parseExpression(stream.advance(1))!
    stream = newStream2
    assert(stream[0] == .Symbol(";"))
    
    let statement = Statement.Let(variable: variableName, subskript: sub, expression: expr)
    return (statement, stream.advance(1))
}

func parseReturnStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if stream.isEmpty || stream[0] != .Keyword("return") {
        return nil
    }
    
    var expression: Expression?
    var workingStream = stream.advance(1)
    
    if let (expr, stream) = parseExpression(workingStream) {
        expression = expr
        workingStream = stream
    }
    
    assert(workingStream[0] == .Symbol(";"))
    
    return (.Return(expression), workingStream.advance(1))
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
    
    return parseSimpleConstantTerm(stream) ??
        parseVariableTerm(stream) ??
        parseBoxedExpression(stream) ??
        parseUnaryOperatorTerm(stream)
}

func parseSimpleConstantTerm(stream: TokenStream) -> (Term, TokenStream)? {
    let token = stream[0]
    let stream1 = stream.advance(1)
    
    if let number = token.getNumber() {
        return (.IntegerConstant(number), stream1)
    } else if let string = token.getString() {
        return (.StringConstant(string), stream1)
    } else if let kwd = token.getKeyword() {
        if let keywordConstant = KeywordConstant(rawValue: (kwd as NSString).uppercaseString) {
            return (.KeywordConstant(keywordConstant), stream1)
        } else {
            fatalError("Found a non-constant keyword expecting an expression term")
        }
    } else {
        return nil
    }
}

func parseVariableTerm(stream: TokenStream) -> (Term, TokenStream)? {
    if let (varName, sub, newStream) = parseVariableNameSubscript(stream) {
        if let sub = sub {
            return (.VariableSubscript(varName, Box(sub)), newStream)
        } else {
            return (.VariableName(varName), newStream)
        }
    }
    
    return nil
}

func parseBoxedExpression(stream: TokenStream) -> (Term, TokenStream)? {
    if let sym = stream[0].getSymbol() {
        if sym == "(" {
            let (expr, newStream) = parseExpression(stream.advance(1))!
            assert(newStream[0] == .Symbol(")"))
            return (.BoxedExpression(Box(expr)), newStream.advance(1))
        }
    }
    
    return nil
}

func parseUnaryOperatorTerm(stream: TokenStream) -> (Term, TokenStream)? {
    if let sym = stream[0].getSymbol() {
        if let op = UnaryOperator(rawValue: sym) {
            if let (term, newStream) = parseTerm(stream.advance(1)) {
                return (.UnaryOpTerm(op, Box(term)), newStream)
            } else {
                fatalError("No valid expression term following an unary operator")
            }
        }
    }
    
    return nil
}

func parseVariableNameSubscript(stream: TokenStream) -> (String, Expression?, TokenStream)? {
    var stream = stream
    if stream.isEmpty {
        return nil
    }
    
    // extract variable name
    var variableName: String
    
    switch stream[0] {
    case .Identifier(let varName): variableName = varName
    default: return nil
    }
    
    stream = stream.advance(1)
    
    // extract subscript
    var sub: Expression?
    
    if stream[0] == .Symbol("[") {
        let (expr, newStream) = parseExpression(stream.advance(1))!
        sub = expr
        assert(newStream[0] == .Symbol("]"))
        stream = newStream.advance(1)
    }
    
    return (variableName, sub, stream)
}

func parseOp(stream: TokenStream) -> (Operator, TokenStream)? {
    if stream.isEmpty {
        return nil
    }
    
    switch stream[0] {
    case .Symbol(let symbol):
        if let op = Operator(rawValue: symbol) {
            return (op, stream.advance(1))
        }
    default: ()
    }
    
    return nil
}