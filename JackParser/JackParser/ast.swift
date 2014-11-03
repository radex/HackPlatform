//struct Class {
//    let name: String
//    let variables: [ClassVariableDeclaration]
//    let subroutines: [SubroutineDeclaration]
//}
//
//struct ClassVariableDeclaration {
//    enum Scope {
//        case Static, Field
//    }
//    
//    let scope: Scope
//    let type: Type
//    let names: [String]
//}
//
//struct SubroutineDeclaration {
//    enum Scope {
//        case Constructor, Function, Method
//    }
//    
//    let scope: Scope
//    let returnType: Type?
//    let name: String
//    let parameters: [(Type, String)]
//    let variableDeclarations: [VariableDeclaration]
//    let statements: [Statement]
//}
//
//struct VariableDeclaration {
//    let type: Type
//    let names: [String]
//}
//
//enum Type {
//    case Int, Char, Boolean
//    case Class(String)
//}

enum Statement {
    case Let(variable: String, subskript: Expression?, expression: Expression)
    case If(condition: Expression, ifStatements: [Statement], elseStatements: [Statement]?)
    case While(condition: Expression, statements: [Statement])
    //    case Do(SubroutineCall)
    case Return(Expression?)
}

struct Expression {
    let firstTerm: Term
    let extraTerms: [(Operator, Term)]
}

enum Term {
    case IntegerConstant(Int)
    case StringConstant(String)
    case KeywordConstant(JackParser.KeywordConstant)
    case VariableName(String)
    case VariableSubscript(String, Box<Expression>)
    case SubroutineCall(JackParser.SubroutineCall)
    case BoxedExpression(Box<Expression>)
    case UnaryOpTerm(UnaryOperator, Box<Term>)
}

struct SubroutineCall {
    let classOrVar: String?
    let name: String
    let arguments: [Expression]
}

enum KeywordConstant: String {
    case True = "TRUE"
    case False = "FALSE"
    case Null = "NULL"
    case This = "THIS"
}

enum Operator: String {
    case Plus = "+"
    case Minus = "-"
    case Mul = "*"
    case Div = "/"
    case And = "&"
    case Or = "|"
    case Lt = "<"
    case Gt = ">"
    case Eq = "="
}

enum UnaryOperator: String {
    case Minus = "-"
    case Not = "~"
}

// MARK: Printable

extension Term: Printable {
    var description: String {
        switch self {
        case .IntegerConstant(let num): return "\(num)"
        case .StringConstant(let str): return "\"\(str)\""
        case .KeywordConstant(let kwd): return kwd.rawValue
        case .VariableName(let id): return id
        case .VariableSubscript(let id, let sub): return "\(id)[\(sub)]"
        case .SubroutineCall(let call): return "\(call)"
        case .BoxedExpression(let expr): return "(\(expr))"
        case .UnaryOpTerm(let op, let box): return "\(op)\(box.value)"
        }
    }
}

extension Operator: Printable {
    var description: String {
        return rawValue
    }
}

extension UnaryOperator: Printable {
    var description: String {
        return rawValue
    }
}

extension Statement: Printable {
    var description: String {
        switch self {
        case .While(let condition, let statements):
            return "WHILE (\(condition)) {\n \(statements) }\n"
        case .If(let condition, let ifStatements, let elseStatements):
            var str = "IF (\(condition)) {\n \(ifStatements) }"
            if let elseStatements = elseStatements {
                str += " ELSE {\n \(elseStatements) }"
            }
            return str + "\n"
        case .Let(let variable, let subskript, let expression):
            var str = "LET \(variable)"
            if let sub = subskript {
                str += "[\(sub)]"
            }
            str += " = \(expression);\n"
            return str
        case .Return(let expr):
            let expression = expr?.description ?? ""
            return "RETURN \(expression);\n"
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

extension Expression: Printable {
    var description: String {
        let first = firstTerm.description
        let extra = extraTerms.map { (op, term) in op.description + " " + term.description }
        
        return first + " " + join(" ", extra)
    }
}