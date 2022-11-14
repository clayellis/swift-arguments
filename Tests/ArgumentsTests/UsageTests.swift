@testable import Arguments
import XCTest

class UsageTests: XCTestCase {
    func testUsage() {
        let usage = Usage(
            overview: "This is the overview",
            seeAlso: ["this one", "that one"],
            commands: [
                [
                    "command",
                    .argument(.both(short: "s", long: "something"), description: "This is something that you'll want to use."),
                    .option("another", default: "one bites the dust", description: "Another thing that might matter. This description is really long and should wrap to multiple lines. It's gonna get lengthy."),
                    "literal",
                    .flag("flag", description: "Turn this on for a good time.")
                ]
            ]
        )

        XCTAssertEqual("\(usage)", """
        OVERVIEW: This is the overview

        SEE ALSO: this one, that one

        USAGE: command [--something] [--another <another>] literal [--flag]

        ARGUMENTS:
         -s, --something        This is something that you'll want to use.
        
        OPTIONS:
         --another <another>    Another thing that might matter. This description is
                                really long and should wrap to multiple lines. It's gonna
                                get lengthy. (default: one bites the dust)
         --flag                 Turn this on for a good time.

        """)
    }
}
