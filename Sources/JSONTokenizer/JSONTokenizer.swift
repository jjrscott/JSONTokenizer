//
//  JSONTokenizer.swift
//
//  MIT License
//
//  Copyright (c) 2025 John Scott
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

public enum JSONToken {
    case bareword(String)
    case string(String)
    case array([JSONToken])
    case object([(key: JSONToken, value: JSONToken)])
}

public enum JSONTokenizationError: Error {
    case unexpectedEndOfInput(String.Index)
    case unexpectedToken(Set<Substring>, Substring, Range<String.Index>)
    case remainingTokens(String.Index)
    case unhandledStringToken(Substring, unicode: Substring?, escaped: Substring?, character: Substring?)
}

public struct JSONTokenizer {
    public init() {
    }

    public func tokenize(_ input: String) throws(JSONTokenizationError) -> JSONToken {
        var index = input.startIndex
        let value = try tokenize(input: input, index: &index)
        guard index == input.endIndex else {
            throw JSONTokenizationError.remainingTokens(index)
        }
        return value
    }

    private let tokenRegex = /[\{\}\[\]\:\,]|"(?:\\.|[^"])*"|[^\s\{\}\[\]\:\,"]+/.dotMatchesNewlines()

    private func nextToken(expected: Set<Substring>? = nil, input: String, index: inout String.Index) throws(JSONTokenizationError) -> Substring {
        if index > input.endIndex {
            throw JSONTokenizationError.unexpectedEndOfInput(index)
        }
        guard let match = input[index...].firstMatch(of: tokenRegex) else {
            throw JSONTokenizationError.unexpectedEndOfInput(index)
        }
        if let expected, !expected.contains(match.output) {
            throw JSONTokenizationError.unexpectedToken(expected, match.output, match.range)
        }
        index = match.range.upperBound
        return match.output
    }

    private let stringRegex = /(?:\\(?:u(?<unicode>[0-9A-Fa-f]{4})|(?<escaped>.)))|(?<character>.)/.dotMatchesNewlines()

    private func tokenize(input: String, index: inout String.Index) throws(JSONTokenizationError) -> JSONToken {
        let token = try nextToken(input: input, index: &index)

        if token == "[" {
            var output = [JSONToken]()
            while true {
                let element = try tokenize(input: input, index: &index)
                output.append(element)
                let nextToken = try nextToken(expected: ["]", ","], input: input, index: &index)
                if nextToken == "]" {
                    return .array(output)
                }
            }
        } else if token == "{" {
            var output = [(JSONToken, JSONToken)]()
            while true {
                let key = try tokenize(input: input, index: &index)

                _ = try nextToken(expected: [":"], input: input, index: &index)

                let value = try tokenize(input: input, index: &index)

                output.append((key, value))

                let nextToken = try nextToken(expected: ["}", ","], input: input, index: &index)

                if nextToken == "}" {
                    return .object(output)
                }
            }
        } else if token.hasPrefix("\"") {
            var output = ""

            for match in token.dropFirst().dropLast().matches(of: stringRegex) {
                if let character = match.output.character {
                    output += character
                } else if let escaped = match.output.escaped {
                    switch escaped {
                    case "b": output += "\u{08}"
                    case "f": output += "\u{0C}"
                    case "n": output += "\u{0A}"
                    case "r": output += "\u{0D}"
                    case "t": output += "\u{09}"
                    default: throw JSONTokenizationError.unhandledStringToken(match.output.0, unicode: match.output.unicode, escaped: match.output.escaped, character: match.output.character)
                    }
                } else if let unicodeString = match.output.unicode,
                          let unicodeValue = UInt32(unicodeString, radix: 16),
                          let character = UnicodeScalar(unicodeValue) {
                    output += String(character)
                } else {
                    throw JSONTokenizationError.unhandledStringToken(match.output.0, unicode: match.output.unicode, escaped: match.output.escaped, character: match.output.character)
                }
            }
            return .string(output)
        } else {
            return .bareword(String(token))
        }
    }
}

extension JSONTokenizer: CustomConsumingRegexComponent {
    public typealias RegexOutput = JSONToken

    public func consuming(_ input: String, startingAt index: String.Index, in bounds: Range<String.Index>) throws -> (upperBound: String.Index, output: JSONToken)? {
        var index = index
        let value = try? tokenize(input: input, index: &index)
        guard let value else { return nil }
        return (upperBound: index, output: value)
    }
}

extension JSONToken: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.bareword(let lhs), .bareword(let rhs)):
            return lhs == rhs
        case (.string(let lhs), .string(let rhs)):
            return lhs == rhs
        case (.array(let lhs), .array(let rhs)):
            return lhs == rhs
        case (.object(let lhs), .object(let rhs)):
            return lhs.elementsEqual(rhs, by: ==)
        default:
            return false
        }
    }
}
