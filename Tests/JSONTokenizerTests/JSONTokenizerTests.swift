import Testing
@testable import JSONTokenizer
import RegexBuilder

@Test func `Normal object`() async throws {
    let tokenizer = JSONTokenizer()

    let input = """
    {
        "Hello" : "World"
    }
    """

    #expect(try tokenizer.tokenize(input) == .object([(.string("Hello"), .string("World"))]))
}

@Test func `Weird object`() async throws {
    let tokenizer = JSONTokenizer()

    let input = """
    {
        ["Hello"] : "World"
    }
    """

    #expect(try tokenizer.tokenize(input) == .object([(.array([.string("Hello")]), .string("World"))]))
}

@Test func `Null, booleans and numbers`() async throws {
    let tokenizer = JSONTokenizer()

    let input = """
    [
      null,
      true,
      10e-30,
      0,
      0.0   
    ]
    """

    #expect(try tokenizer.tokenize(input) == .array([.bareword("null"), .bareword("true"), .bareword("10e-30"), .bareword("0"), .bareword("0.0")]))
}

@Test func `Inside a regular expression`() async throws {
    let token = Reference(JSONToken.self)
    let regex = Regex {
        "Hello"
        OneOrMore(.whitespace)
        Capture(as: token) {
            JSONTokenizer()
        }
        OneOrMore(.whitespace)
        "World"
    }

    let input = """
Hello ["small", "big"] World
"""

    let result = try #require(try regex.wholeMatch(in: input))

    #expect(result[token] == .array([.string("small"), .string("big")]))
}

@Test func `Single "`() async throws {
    let tokenizer = JSONTokenizer()

    let input = """
        x"
"""
    #expect(throws: JSONTokenizationError.self) {
        try tokenizer.tokenize(input)
    }
}

func printJSONToken(token: JSONToken) {
    print(".\(token)".replacing("JSONTokenizer.JSONToken", with: ""))
}
