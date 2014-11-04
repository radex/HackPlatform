import Foundation

func indent(string: String) -> String {
    let lines = (string as NSString).componentsSeparatedByString("\n") as [String]
    return join("\n", lines.map { "    \($0)" })
}

func formatList<T>(array: [T]) -> String {
    return join("\n", array.map { "\($0)" })
}

func stringifyList<T>(array: [T]) -> [String] {
    return array.map { "\($0)" }
}

extension ClassDeclaration: Printable {
    var description: String {
        var str = "class \(name) {\n"
        let decls = stringifyList(variables) + [""] + stringifyList(subroutines)
        str += indent(formatList(decls))
        str += "\n}\n"
        return str
    }
}

extension ClassVariableDeclaration: Printable {
    var description: String {
        let names = join(", ", self.names)
        return "\(scope) \(type) \(names);"
    }
}

extension ClassVariableDeclaration.Scope: Printable {
    var description: String { return self.rawValue }
}

extension SubroutineDeclaration: Printable {
    var description: String {
        var returnType = (self.returnType == nil) ? "void" : "\(self.returnType!)"
        var params = join(", ", parameters.map { (type, name) in "\(type) \(name)" })
        var str = "\(scope.rawValue) \(returnType) \(name)(\(params))"
        str += " {\n"
        var decls = stringifyList(variableDeclarations) + [""] + stringifyList(statements)
        str += indent(formatList(decls))
        str += "\n}\n"
        return str
    }
}

extension SubroutineDeclaration.Scope: Printable {
    var description: String { return self.rawValue }
}

extension VariableDeclaration: Printable {
    var description: String {
        let names = join(", ", self.names)
        return "var \(type) \(names);"
    }
}

extension Type: Printable {
    var description: String {
        switch self {
        case .Int: return "int"
        case .Boolean: return "boolean"
        case .Char: return "char"
        case .Class(let name): return name
        }
    }
}

extension Statement: Printable {
    var description: String {
        switch self {
        case .While(let condition, let statements):
            var str = "while (\(condition)) {\n"
            str += indent(formatList(statements))
            str += "\n}\n"
            return str
            
        case .If(let condition, let ifStatements, let elseStatements):
            var str = "if (\(condition)) {\n"
            str += indent(formatList(ifStatements))
            str += "\n}"
            if let elseStatements = elseStatements {
                str += " else {\n"
                str += indent(formatList(elseStatements))
                str += "\n}"
            }
            return str + "\n"
            
        case .Let(let variable, let subskript, let expression):
            var str = "let \(variable)"
            if let sub = subskript {
                str += "[\(sub)]"
            }
            str += " = \(expression);"
            return str
            
        case .Return(let expr):
            var str = "return"
            if let expr = expr {
                str += " \(expr)"
            }
            return "\(str);"
            
        case .Do(let call):
            return "do \(call);"
        }
    }
}

extension Expression: Printable {
    var description: String {
        var components: [String] = ["\(firstTerm)"]
        components += extraTerms.map { "\($0) \($1)" }
        
        return join(" ", components)
    }
}

extension Term: Printable {
    var description: String {
        switch self {
        case .IntegerConstant(let num): return "\(num)"
        case .StringConstant(let str): return "\"\(str)\""
        case .KeywordConstant(let kwd): return "\(kwd)"
        case .VariableName(let id): return id
        case .VariableSubscript(let id, let sub): return "\(id)[\(sub)]"
        case .SubroutineCall(let call): return "\(call)"
        case .BoxedExpression(let expr): return "(\(expr))"
        case .UnaryOpTerm(let op, let box): return "\(op)\(box)"
        }
    }
}

extension SubroutineCall: Printable {
    var description: String {
        var str = ""
        if let classOrVar = classOrVar {
            str += "\(classOrVar)."
        }
        str += name
        str += "("
        str += join(", ", arguments.map { "\($0)" })
        str += ")"
        return str
    }
}

extension KeywordConstant: Printable {
    var description: String {
        return self.rawValue
    }
}

extension Operator: Printable {
    var description: String {
        return self.rawValue
    }
}

extension UnaryOperator: Printable {
    var description: String {
        return self.rawValue
    }
}