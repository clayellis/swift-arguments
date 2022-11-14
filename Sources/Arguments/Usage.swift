import Foundation

private let tab = "    "

public struct Usage {
    public enum CommandComponent: Hashable, ExpressibleByStringLiteral {
        case raw(String)
        case argument(Argument)

        public static func option(_ name: Argument.Name, required: Bool = false, default: String? = nil, description: String = "") -> CommandComponent {
            .argument(.init(kind: .option, name: name, description: description, required: required, default: `default`))
        }

        public static func argument(_ name: Argument.Name, required: Bool = false, default: String? = nil, description: String = "") -> CommandComponent {
            .argument(.init(kind: .argument, name: name, description: description, required: required, default: `default`))
        }

        public static func flag(_ name: Argument.Name, description: String = "") -> CommandComponent {
            .argument(.init(kind: .flag, name: name, description: description, required: false, default: nil))
        }

        public init(stringLiteral value: String) {
            self = .raw(value)
        }

        var help: String {
            switch self {
            case let .raw(raw):
                return raw
            case let .argument(argument):
                return argument.commandHelp
            }
        }
    }

    public struct Argument: Hashable {
        public enum Name: Hashable, ExpressibleByStringLiteral {
            case both(short: String, long: String)
            case short(String)
            case long(String)

            public init(stringLiteral value: String) {
                self = .long(value)
            }

            var name: String {
                switch self {
                case let .both(_, long):
                    return long
                case let .short(short):
                    return short
                case let .long(long):
                    return long
                }
            }

            var commandHelp: String {
                switch self {
                case let .both(_, long):
                    return "--\(long)"
                case let .short(short):
                    return "-\(short)"
                case let .long(long):
                    return "--\(long)"
                }
            }

            var argumentHelp: String {
                switch self {
                case let .both(short, long):
                    return "-\(short), --\(long)"
                case let .short(short):
                    return "-\(short)"
                case let .long(long):
                    return "--\(long)"
                }
            }
        }

        enum Kind {
            case option
            case argument
            case flag
        }

        let kind: Kind
        let name: Name
        let description: String
        var required: Bool
        var `default`: String?

        // TODO: Command/Argument help of option where value is an array
        // - command help: option [<arg0> ...]
        // - argument help: <arg0>  description

        var commandHelp: String {
            let help: String
            switch kind {
            case .option:
                help = "\(name.commandHelp) <\(name.name)>"
            case .argument:
                help = "\(name.commandHelp)"
            case .flag:
                help = "\(name.commandHelp)"
            }
            return required ? help : "[\(help)]"
        }

        func argumentHelpName(paddedToLength paddingLength: Int? = nil) -> String {
            var helpName: String
            switch kind {
            case .option:
                helpName = "\(name.argumentHelp) <\(name.name)>"
            case .argument:
                helpName = name.argumentHelp
            case .flag:
                helpName = name.argumentHelp
            }

            if let paddingLength {
                helpName = helpName.padding(toLength: paddingLength, withPad: " ", startingAt: 0)
            }

            return helpName
        }

        func argumentHelp(paddedToLength paddingLength: Int? = nil) -> String {
            let help = "\(argumentHelpName(paddedToLength: paddingLength))\(tab)\(description)"

            if let `default` {
                return "\(help) (default: \(`default`))"
            } else {
                return help
            }
        }
    }

    var overview: String?
    var seeAlso: [String]?
    let commands: [[CommandComponent]]

    public init(overview: String? = nil, seeAlso: [String]? = nil, commands: [[CommandComponent]]) {
        self.overview = overview
        self.seeAlso = seeAlso
        self.commands = commands
    }

    private var arguments: Set<Argument> {
        let arguments = commands.flatMap { $0 }.compactMap { component -> Argument? in
            switch component {
            case .raw: return nil
            case let .argument(argument): return argument
            }
        }
        return Set(arguments)
    }

    private var uniqueArgumentsByKind: [Argument.Kind: [Argument]] {
        var uniqueArgumentsByKind = [Argument.Kind: [Argument]]()
        let sortedArguments = arguments.sorted { $0.argumentHelpName() < $1.argumentHelpName() }
        for argument in sortedArguments {
            if !uniqueArgumentsByKind[argument.kind, default: []].contains(argument) {
                uniqueArgumentsByKind[argument.kind, default: []].append(argument)
            }
        }
        return uniqueArgumentsByKind
    }

    public var help: String {
        var help = ""

        if let overview {
            help += """
            OVERVIEW: \(overview)


            """
        }

        if let seeAlso, !seeAlso.isEmpty {
            help += """
            SEE ALSO: \(seeAlso.joined(separator: ", "))


            """
        }

        // TODO: USAGE where there's a base raw command component but no specific mix of arguments.
        // - command <arguments> <options>

        switch commands.count {
        case 0:
            break
        case 1:
            help += """
            USAGE: \(commands[0].map(\.help).joined(separator: " "))


            """
        default:
            help += """
            USAGE:
            \(commands.map { tab + $0.map(\.help).joined(separator: " ") }.joined(separator: "\n"))


            """
        }

        let widestArgument = arguments.reduce(into: 0) { $0 = max($0, $1.argumentHelpName().count) }
        let uniqueArgumentsByKind = self.uniqueArgumentsByKind
        func appendArgumentSection(title: String, arguments: [Argument]) {
            help += """
            \(title):
            \(arguments.map { " " + $0.argumentHelp(paddedToLength: widestArgument) }.joined(separator: "\n"))


            """
        }

        if let arguments = uniqueArgumentsByKind[.argument], !arguments.isEmpty {
            appendArgumentSection(title: "ARGUMENTS", arguments: arguments)
        }

        let optionsAndFlags = uniqueArgumentsByKind[.option, default: []] + uniqueArgumentsByKind[.flag, default: []]
        if !optionsAndFlags.isEmpty {
            appendArgumentSection(title: "OPTIONS", arguments: optionsAndFlags)
        }

        return help
    }
}
