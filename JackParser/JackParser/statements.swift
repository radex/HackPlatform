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
    if !stream.isKeyword("while") {
        return nil
    }
    
    assert(stream[1] == .Symbol("("))
    let (expr, stream) = parseExpression(stream.advance(2))!
    assert(stream.isSymbol(")"))
    
    assert(stream[1] == .Symbol("{"))
    let (statements, stream2) = parseStatements(stream.advance(2))
    assert(stream2.isSymbol("}"))
    
    let whileStatement = Statement.While(condition: expr, statements: statements)
    return (whileStatement, stream2.advance(1))
}

func parseIfStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if !stream.isKeyword("if") {
        return nil
    }
    
    assert(stream[1] == .Symbol("("))
    let (expr, stream) = parseExpression(stream.advance(2))!
    assert(stream.isSymbol(")"))
    
    assert(stream[1] == .Symbol("{"))
    let (statements, stream2) = parseStatements(stream.advance(2))
    assert(stream2.isSymbol("}"))
    
    let (elseStatements, stream3) = parseElseStatements(stream2.advance(1))
    
    let ifStatement = Statement.If(condition: expr, ifStatements: statements, elseStatements: elseStatements)
    return (ifStatement, stream3)
}

func parseElseStatements(stream: TokenStream) -> ([Statement]?, TokenStream) {
    if !stream.isKeyword("else") {
        return (nil, stream)
    }
    
    assert(stream[1] == .Symbol("{"))
    let (statements, stream) = parseStatements(stream.advance(2))
    assert(stream.isSymbol("}"))
    
    return (statements, stream.advance(1))
}


func parseLetStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    var stream = stream
    
    if !stream.isKeyword("let") {
        return nil
    }
    
    // extract variable
    let (variableName, sub, newStream) = parseVariableNameSubscript(stream.advance(1))!
    stream = newStream
    
    // extract value
    assert(stream.isSymbol("="))
    let (expr, newStream2) = parseExpression(stream.advance(1))!
    stream = newStream2
    assert(stream.isSymbol(";"))
    
    let statement = Statement.Let(variable: variableName, subskript: sub, expression: expr)
    return (statement, stream.advance(1))
}

func parseReturnStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if !stream.isKeyword("return") {
        return nil
    }
    
    var expression: Expression?
    var workingStream = stream.advance(1)
    
    if let (expr, stream) = parseExpression(workingStream) {
        expression = expr
        workingStream = stream
    }
    
    assert(workingStream.isSymbol(";"))
    
    return (.Return(expression), workingStream.advance(1))
}

func parseDoStatement(stream: TokenStream) -> (Statement, TokenStream)? {
    if !stream.isKeyword("do") {
        return nil
    }
    
    let (call, newStream) = parseSubroutineCall(stream.advance(1))!
    assert(newStream.isSymbol(";"))
    return (.Do(call), newStream.advance(1))
}