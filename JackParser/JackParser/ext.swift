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