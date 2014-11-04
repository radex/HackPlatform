import Foundation

struct ClassDeclaration {
    let name: String
    let variables: [ClassVariableDeclaration]
    let subroutines: [SubroutineDeclaration]
}

struct ClassVariableDeclaration {
    enum Scope: String {
        case Static = "static"
        case Field  = "field"
    }
    
    let scope: Scope
    let type: Type
    let names: [String]
}

struct SubroutineDeclaration {
    enum Scope: String {
        case Constructor = "constructor"
        case Function    = "function"
        case Method      = "method"
    }
    
    let scope: Scope
    let returnType: Type?
    let name: String
    let parameters: [(Type, String)]
    let variableDeclarations: [VariableDeclaration]
    let statements: [Statement]
}

struct VariableDeclaration {
    let type: Type
    let names: [String]
}

enum Type {
    case Int, Char, Boolean
    case Class(String)
}

enum Statement {
    case Let(variable: String, subskript: Expression?, expression: Expression)
    case If(condition: Expression, ifStatements: [Statement], elseStatements: [Statement]?)
    case While(condition: Expression, statements: [Statement])
    case Do(SubroutineCall)
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
    case True = "true"
    case False = "false"
    case Null = "null"
    case This = "this"
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