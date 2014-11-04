func parseSubroutineDeclarations(stream: TokenStream) -> ([SubroutineDeclaration], TokenStream) {
    var declarations: [SubroutineDeclaration] = []
    var stream = stream
    
    while let (decl, newStream) = parseSubroutineDeclaration(stream) {
        declarations.append(decl)
        stream = newStream
    }
    
    return (declarations, stream)
}

func parseSubroutineDeclaration(stream: TokenStream) -> (SubroutineDeclaration, TokenStream)? {
    var stream = stream
    if stream.isEmpty {
        return nil
    }
    
    // scope
    var scope: SubroutineDeclaration.Scope
    if let theScope = stream[0].getKeyword() |> { SubroutineDeclaration.Scope(rawValue: $0) } {
        scope = theScope
    } else {
        return nil
    }
    
    // return type
    var returnType: Type?
    if stream[1] == .Keyword("void") {
        returnType = nil
    } else {
        returnType = parseType(stream[1])
    }
    
    // name
    var name = stream[2].getIdent()!
    stream = stream.advance(3)
    
    // params
    let (parameters, newStream) = parseSubroutineParameters(stream)
    stream = newStream
    
    // body
    let (varDecls, statements, newStream2) = parseSubroutineBody(stream)
    stream = newStream2
    
    // return
    let decl = SubroutineDeclaration(scope: scope, returnType: returnType, name: name, parameters: parameters, variableDeclarations: varDecls, statements: statements)
    return (decl, stream)
}

func parseSubroutineParameters(stream: TokenStream) -> ([(Type, String)], TokenStream) {
    var stream = stream
    var parameters: [(Type, String)] = []
    
    assert(stream[0] == .Symbol("("))
    stream = stream.advance(1)
    
    if stream[0] != .Symbol(")") {
        while true {
            let type = parseType(stream[0])
            let name = stream[1].getIdent()!
            parameters.append((type, name))
            stream = stream.advance(2)
            
            if stream[0] == .Symbol(",") {
                stream = stream.advance(1)
                continue
            } else if stream[0] == .Symbol(")") {
                break
            } else {
                fatalError("Expected comma or closing paren")
            }
        }
    }
    
    // closing paren
    stream = stream.advance(1)
    
    return (parameters, stream)
}

func parseSubroutineBody(stream: TokenStream) -> ([VariableDeclaration], [Statement], TokenStream) {
    var stream = stream
    
    assert(stream[0] == .Symbol("{"))
    
    let (varDecls, newStream) = parseVariableDeclarations(stream.advance(1))
    stream = newStream
    
    let (statements, newStream2) = parseStatements(stream)
    stream = newStream2
    
    assert(stream[0] == .Symbol("}"))
    
    return (varDecls, statements, stream.advance(1))
}

func parseVariableDeclarations(stream: TokenStream) -> ([VariableDeclaration], TokenStream) {
    var declarations: [VariableDeclaration] = []
    var stream = stream
    
    while let (decl, newStream) = parseVariableDeclaration(stream) {
        declarations.append(decl)
        stream = newStream
    }
    
    return (declarations, stream)
}

func parseVariableDeclaration(stream: TokenStream) -> (VariableDeclaration, TokenStream)? {
    var stream = stream
    if stream.isEmpty || stream[0] != .Keyword("var") {
        return nil
    }
    
    // type
    var type: Type = parseType(stream[1])
    stream = stream.advance(2)
    
    // names
    var names: [String] = []
    
    while true {
        if let name = stream[0].getIdent() {
            names.append(name)
        } else {
            fatalError("Expected a valid variable name")
        }
        
        if stream[1] == .Symbol(",") {
            stream = stream.advance(2)
            continue
        } else if stream[1] == .Symbol(";") {
            stream = stream.advance(2)
            break
        } else {
            fatalError("Expected another variable name or semicolon")
        }
    }
    
    // return
    let declaration = VariableDeclaration(type: type, names: names)
    return (declaration, stream)
}

func parseType(token: Token) -> Type {
    switch token {
    case .Keyword("int"): return .Int
    case .Keyword("char"): return .Char
    case .Keyword("boolean"): return .Boolean
    case .Identifier(let name): return .Class(name)
    default:
        fatalError("Expected a valid type")
    }
}

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
        parseSubroutineCallTerm(stream) ??
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
        if let keywordConstant = KeywordConstant(rawValue: kwd) {
            return (.KeywordConstant(keywordConstant), stream1)
        } else {
            fatalError("Found a non-constant keyword expecting an expression term")
        }
    } else {
        return nil
    }
}

func parseSubroutineCallTerm(stream: TokenStream) -> (Term, TokenStream)? {
    if let (call, stream) = parseSubroutineCall(stream) {
        return (.SubroutineCall(call), stream)
    } else {
        return nil
    }
}

func parseSubroutineCall(stream: TokenStream) -> (SubroutineCall, TokenStream)? {
    var stream = stream
    var firstIdent: String
    var secondIdent: String?
    var arguments: [Expression] = []
    
    // first identifier (name or class/variable name)
    if let str = stream[0].getIdent() {
        firstIdent = str
        stream = stream.advance(1)
    } else {
        return nil
    }
    
    // do we have a dot?
    if stream[0] == .Symbol(".") {
        if let str = stream[1].getIdent() {
            secondIdent = str
            stream = stream.advance(2)
        } else {
            fatalError("Invalid method name")
        }
    }
    
    // opening paren
    if stream[0] != .Symbol("(") {
        return nil
    }
    
    stream = stream.advance(1)
    
    // do we have arguments?
    if stream[0] != .Symbol(")") {
        let (args, newStream) = parseSubroutineCallArguments(stream)
        arguments = args
        stream = newStream
        assert(stream[0] == .Symbol(")"))
    }
    
    // return
    let classOrVar = (secondIdent != nil) ? firstIdent : Optional<String>.None
    let name = (secondIdent != nil) ? secondIdent! : firstIdent
    let call = SubroutineCall(classOrVar: classOrVar, name: name, arguments: arguments)
    return (call, stream.advance(1))
}

// assumes more than one argument in the stream

func parseSubroutineCallArguments(stream: TokenStream) -> ([Expression], TokenStream) {
    var stream = stream
    var arguments: [Expression] = []
    
    while true {
        let (expr, newStream) = parseExpression(stream)!
        arguments.append(expr)
        stream = newStream
        
        if stream[0] == .Symbol(")") {
            break
        } else if stream[0] == .Symbol(",") {
            stream = stream.advance(1)
            continue
        } else {
            fatalError("Syntax error in the argument list")
        }
    }
    
    return (arguments, stream)
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