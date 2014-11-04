class Box<T> {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}

extension Box: Printable {
    var description: String {
        return "\(value)"
    }
}

infix operator |> { associativity left precedence 150 }

func |><A, B>(a: A?, f: A -> B?) -> B? {
    if let a = a {
        return f(a)
    } else {
        return .None
    }
}

func |><A>(a: A?, f: A -> ()) {
    if let a = a {
        f(a)
    }
}