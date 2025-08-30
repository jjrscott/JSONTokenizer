import Testing
@testable import JSONTokenizer

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

func printJSONToken(token: JSONToken) {
    print(".\(token)".replacing("JSONTokenizer.JSONToken", with: ""))
}
