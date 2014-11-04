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
        parseReturnStatement(stream) ??
        parseDoStatement(stream)
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

func parseDoStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if stream.isEmpty || stream[0] != .Keyword("do") {
        return nil
    }
    
    let (call, newStream) = parseSubroutineCall(stream.advance(1))!
    assert(newStream[0] == .Symbol(";"))
    return (.Do(call), newStream.advance(1))
}