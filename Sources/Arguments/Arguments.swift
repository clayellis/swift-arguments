import Foundation

public struct Arguments {
    var arguments: [String]
    var usage: Usage?

    public init(arguments: [String] = CommandLine.arguments, usage: Usage? = nil) {
        self.arguments = arguments
        self.usage = usage
    }

    public mutating func consumeOption(named name: String) throws -> String {
        guard let nameIndex = arguments.firstIndex(of: name) else {
            throw ArgumentError(reason: .missingOption(name: name), usage: usage)
        }

        let valueIndex = arguments.index(after: nameIndex)
        guard valueIndex < arguments.endIndex else {
            throw ArgumentError(reason: .missingOption(name: name), usage: usage)
        }

        let option = arguments[valueIndex]
        arguments.removeSubrange(nameIndex...valueIndex)
        return option
    }

    public mutating func consumeArgument() throws -> String {
        guard !arguments.isEmpty else {
            throw ArgumentError(reason: .missingArgument, usage: usage)
        }

        return arguments.removeFirst()
    }

    public mutating func consumeFlag(named name: String) -> Bool {
        guard let flagIndex = arguments.firstIndex(of: name) else {
            return false
        }

        arguments.remove(at: flagIndex)
        return true
    }
}

public struct ArgumentError: LocalizedError, CustomStringConvertible {
    let reason: Reason
    let usage: Usage?

    enum Reason {
        case missingOption(name: String)
        case invalidOption(name: String, value: String, expectedType: any ExpressibleByArgument.Type)
        case missingArgument
        case invalidArgument(value: String, expectedType: any ExpressibleByArgument.Type)
    }

    public var description: String {
        "\(reason)"
    }

    public var errorDescription: String? {
        var description = ""
        switch reason {
        case let .missingOption(name):
            description = "Missing expected option '\(name)'."

        case let .invalidOption(name, value, expectedType):
            description = "Could not convert option '\(name)' value '\(value)' to expected type: \(expectedType)."

        case .missingArgument:
            description = "Missing expected argument."

        case let .invalidArgument(value, expectedType):
            description = "Could not convert argument value '\(value)' to expected type: \(expectedType)."
        }

        if let usage {
            description += """
            \(usage.description)
            """
        }

        return description
    }
}
