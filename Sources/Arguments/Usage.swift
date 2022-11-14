import Foundation

private let tab = "    "

public struct Usage: CustomStringConvertible {
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

        func argumentHelp(paddedToLength paddingLength: Int? = nil, limitedToLength limit: Int? = nil) -> String {
            var description = description

            if let `default` {
                description += " (default: \(`default`))"
            }

            let fallback = "\(argumentHelpName(paddedToLength: paddingLength))\(tab)\(description)"

            guard let paddingLength, let limit, fallback.count > limit else {
                return fallback
            }

            guard limit > paddingLength else {
                assertionFailure("Limit (\(limit)) should be greater than padding length (\(paddingLength))")
                return fallback
            }

            let allowedDescriptionWidth = limit - paddingLength - tab.count

            guard allowedDescriptionWidth > 0 else {
                assertionFailure("Length limit must be a number that results in a allowed width greater than zero.")
                return fallback
            }

            var lines = description.breakOnWordsIntoLines(ofLength: allowedDescriptionWidth)

            if lines.isEmpty {
                return fallback
            }

            for (index, line) in zip(lines.indices, lines) {
                lines[index] = index == 0
                ? "\(argumentHelpName(paddedToLength: paddingLength))\(tab)\(line)"
                : "\(Array(repeating: " ", count: limit - allowedDescriptionWidth).joined())\(line)"
            }

            return lines.joined(separator: "\n")
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

    public init(overview: String? = nil, seeAlso: [String]? = nil, commands: [CommandComponent]...) {
        self.init(overview: overview, seeAlso: seeAlso, commands: commands)
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

    public var description: String {
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
        func appendArgumentSection(title: String, arguments: [Argument], terminator: String = "\n") {
            help += """
            \(title):
            \(arguments.map { $0.argumentHelp(paddedToLength: widestArgument, limitedToLength: 100).indented(tabs: 1, tab: " ") }.joined(separator: "\n"))
            \(terminator)
            """
        }

        if let arguments = uniqueArgumentsByKind[.argument], !arguments.isEmpty {
            appendArgumentSection(title: "ARGUMENTS", arguments: arguments)
        }

        let optionsAndFlags = uniqueArgumentsByKind[.option, default: []] + uniqueArgumentsByKind[.flag, default: []]
        if !optionsAndFlags.isEmpty {
            appendArgumentSection(title: "OPTIONS", arguments: optionsAndFlags, terminator: "")
        }

        return help
    }
}

extension String {
    func indented(tabs: Int = 1, tab: String = "\t") -> String {
        self.components(separatedBy: "\n")
            .map { Array(repeating: tab, count: tabs).joined() + $0 }
            .joined(separator: "\n")
    }

    func breakOnWordsIntoLines(ofLength lineLength: Int) -> [String] {
        let words = self.components(separatedBy: .whitespaces)
        var lines = [String]()
        var line = ""
        for word in words {
            var proposedLine = line
            if proposedLine.isEmpty {
                proposedLine = word
            } else {
                proposedLine += " \(word)"
            }

            if proposedLine.count > lineLength {
                lines.append(line)
                line = word
            } else {
                line = proposedLine
            }
        }

        if !line.isEmpty {
            lines.append(line)
        }

        return lines
    }
}
