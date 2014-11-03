enum KeywordConstant: String {
    case True = "TRUE"
    case False = "FALSE"
    case Null = "NULL"
    case This = "THIS"
}

enum Term {
    case IntegerConstant(Int)
    case KeywordConstant(JackParser.KeywordConstant)
    case VariableName(String)
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

struct Expression {
    let firstTerm: Term
    let extraTerms: [(Operator, Term)]
}

enum Statement {
    case While(condition: Expression, statements: [Statement])
    case If(condition: Expression, ifStatements: [Statement], elseStatements: [Statement]?)
    case Let(variable: String, expression: Expression)
}

// MARK: Printable

extension Term: Printable {
    var description: String {
        switch self {
        case .IntegerConstant(let num): return "\(num)"
        case .KeywordConstant(let kwd): return kwd.rawValue
        case .VariableName(let id): return "Variable '\(id)'"
        }
    }
}

extension Operator: Printable {
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
        case .Let(let variable, let expression):
            return "LET \(variable) = \(expression);\n"
        }
    }
}

extension Expression: Printable {
    var description: String {
        let first = firstTerm.description
        let extra = extraTerms.map { (op, term) in op.description + " " + term.description }
        
        return first + " " + join(" ", extra)
    }
}