public protocol ExpressibleByArgument {
    init?(argument: String)
}

public extension Arguments {
    mutating func consumeOption<Option: ExpressibleByArgument>(named name: String, as type: Option.Type = Option.self) throws -> Option {
        let rawOption = try consumeOption(named: name)
        guard let option = Option(argument: rawOption) else {
            throw ArgumentError(reason: .invalidOption(name: name, value: rawOption, expectedType: Option.self), usage: usage)
        }
        return option
    }

    mutating func consumeArgument<Argument: ExpressibleByArgument>(as type: Argument.Type = Argument.self) throws -> Argument {
        let rawArgument = try consumeArgument()
        guard let argument = Argument(argument: rawArgument) else {
            throw ArgumentError(reason: .invalidArgument(value: rawArgument, expectedType: Argument.self), usage: usage)
        }
        return argument
    }
}
