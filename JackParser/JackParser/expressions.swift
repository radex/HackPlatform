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
    if stream.isSymbol(".") {
        if let str = stream[1].getIdent() {
            secondIdent = str
            stream = stream.advance(2)
        } else {
            fatalError("Invalid method name")
        }
    }
    
    // opening paren
    if !stream.isSymbol("(") {
        return nil
    }
    
    stream = stream.advance(1)
    
    // do we have arguments?
    if !stream.isSymbol(")") {
        let (args, newStream) = parseSubroutineCallArguments(stream)
        arguments = args
        stream = newStream
        assert(stream.isSymbol(")"))
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
        
        if stream.isSymbol(")") {
            break
        } else if stream.isSymbol(",") {
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
    if stream.isSymbol("(") {
        let (expr, newStream) = parseExpression(stream.advance(1))!
        assert(newStream.isSymbol(")"))
        return (.BoxedExpression(Box(expr)), newStream.advance(1))
    }
    
    return nil
}

func parseUnaryOperatorTerm(stream: TokenStream) -> (Term, TokenStream)? {
    if let op = stream[0].getSymbol() |> { UnaryOperator(rawValue: $0) } {
        if let (term, newStream) = parseTerm(stream.advance(1)) {
            return (.UnaryOpTerm(op, Box(term)), newStream)
        } else {
            fatalError("No valid expression term following an unary operator")
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
    
    if let varName = stream[0].getIdent() {
        variableName = varName
    } else {
        return nil
    }
    
    stream = stream.advance(1)
    
    // extract subscript
    var sub: Expression?
    
    if stream.isSymbol("[") {
        let (expr, newStream) = parseExpression(stream.advance(1))!
        sub = expr
        assert(newStream.isSymbol("]"))
        stream = newStream.advance(1)
    }
    
    return (variableName, sub, stream)
}

func parseOp(stream: TokenStream) -> (Operator, TokenStream)? {
    if stream.isEmpty {
        return nil
    }
    if let op = stream[0].getSymbol() |> { Operator(rawValue: $0) } {
        return (op, stream.advance(1))
    }
    
    return nil
}