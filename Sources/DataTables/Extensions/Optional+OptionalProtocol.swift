extension Optional: OptionalProtocol {
    func isSome() -> Bool {
        switch self {
            case .none: return false
            case .some: return true
        }
    }

    func unwrap() -> Any {
        switch self {
            // If a nil is unwrapped it will crash!
            case .none: preconditionFailure("nill unwrap")
            case .some(let unwrapped): return unwrapped
        }
    }
}

protocol OptionalProtocol {
    func isSome() -> Bool
    func unwrap() -> Any
}