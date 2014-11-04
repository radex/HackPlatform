func parseClass(stream: TokenStream) -> (ClassDeclaration, TokenStream)? {
    var stream = stream
    if stream.isEmpty || stream[0] != .Keyword("class") {
        return nil
    }
    
    let name = stream[1].getIdent()!
    
    let (varDecls, subroutines, newStream) = parseClassBody(stream.advance(2))
    stream = newStream
    
    let klass = ClassDeclaration(name: name, variables: varDecls, subroutines: subroutines)
    return (klass, stream)
}

func parseClassBody(stream: TokenStream) -> ([ClassVariableDeclaration], [SubroutineDeclaration], TokenStream) {
    var stream = stream
    
    assert(stream[0] == .Symbol("{"))
    
    let (varDecls, newStream) = parseClassVariableDeclarations(stream.advance(1))
    stream = newStream
    
    let (subroutines, newStream2) = parseSubroutineDeclarations(stream)
    stream = newStream2
    
    assert(stream[0] == .Symbol("}"))
    
    return (varDecls, subroutines, stream.advance(1))
}

func parseClassVariableDeclarations(stream: TokenStream) -> ([ClassVariableDeclaration], TokenStream) {
    var declarations: [ClassVariableDeclaration] = []
    var stream = stream
    
    while let (decl, newStream) = parseClassVariableDeclaration(stream) {
        declarations.append(decl)
        stream = newStream
    }
    
    return (declarations, stream)
}

func parseClassVariableDeclaration(stream: TokenStream) -> (ClassVariableDeclaration, TokenStream)? {
    var stream = stream
    if stream.isEmpty {
        return nil
    }
    
    // scope
    var scope: ClassVariableDeclaration.Scope
    if let theScope = stream[0].getKeyword() |> { ClassVariableDeclaration.Scope(rawValue: $0) } {
        scope = theScope
    } else {
        return nil
    }
    
    // type and names
    let (type, names, newStream) = parseVariableTypeAndNames(stream.advance(1))
    stream = newStream
    assert(stream[0] == .Symbol(";"))
    
    let declaration = ClassVariableDeclaration(scope: scope, type: type, names: names)
    return (declaration, stream.advance(1))
}

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
    
    let (type, names, newStream) = parseVariableTypeAndNames(stream.advance(1))
    stream = newStream
    assert(stream[0] == .Symbol(";"))
    
    let declaration = VariableDeclaration(type: type, names: names)
    return (declaration, stream.advance(1))
}

func parseVariableTypeAndNames(stream: TokenStream) -> (Type, [String], TokenStream) {
    var stream = stream
    
    // type
    let type = parseType(stream[0])
    stream = stream.advance(1)
    
    // names
    var names: [String] = []
    
    while true {
        if let name = stream[0].getIdent() {
            names.append(name)
            stream = stream.advance(1)
        } else {
            fatalError("Expected a valid variable name")
        }
        
        if stream[0] == .Symbol(",") {
            stream = stream.advance(1)
            continue
        } else if stream[0] == .Symbol(";") {
            break
        } else {
            fatalError("Expected another variable name or semicolon")
        }
    }
    
    return (type, names, stream)
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