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