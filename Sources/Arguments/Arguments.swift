public struct Arguments {
    var arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public mutating func consumeArgument() throws -> String {
        guard !arguments.isEmpty else {
            throw ArgumentError.missingArgument
        }

        return arguments.removeFirst()
    }

    public mutating func consumeOption(named name: String) throws -> String {
        guard let nameIndex = arguments.firstIndex(of: name) else {
            throw ArgumentError.missingOption(name: name)
        }

        let valueIndex = arguments.index(after: nameIndex)
        guard valueIndex < arguments.endIndex else {
            throw ArgumentError.missingOption(name: name)
        }

        let option = arguments[valueIndex]
        arguments.removeSubrange(nameIndex...valueIndex)
        return option
    }

    public mutating func consumeFlag(named name: String) -> Bool {
        guard let flagIndex = arguments.firstIndex(of: name) else {
            return false
        }

        arguments.remove(at: flagIndex)
        return true
    }
}

public enum ArgumentError: Error {
    case missingArgument
    case invalidArgument(value: String, expectedType: any ExpressibleByArgument.Type)
    case missingOption(name: String)
    case invalidOption(name: String, value: String, expectedType: any ExpressibleByArgument.Type)
}