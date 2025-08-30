#  JSONTokenizer

JSONTokenizer is a project design to demonstrate parsing JSON using Swift's
awesome regular expression support. It might also be useful if you wish to handle
broken JSON when you don't have a choice. JSONTokenizer leaves as much as it
can for you to deal with yourself. Good Luck!

## Examples

### Normal object

```json
{
  "Hello" : "World"
}
```

```swift
.object([(key: .string("Hello"), value: .string("World"))])
```

### Weird object

JSONTokenizer doesn't care that an object's key is a quoted string, just that it's
a valid JSONToken. Therefore the following is valid:

```json
{
  ["Hello"] : "World"
}
```

```swift
.object([(key: .array([.string("Hello")]), value: .string("World"))])
```

### Null, booleans and numbers

JSONTokenizer doesn't handle `null`, booleans and numbers, it just captures them as barewords for you to handle as you wish. This avoids any preprocessing Swift might do (ie, treat `0` and `0.0` as identical)

```json
[
  null,
  true,
  10e-30,
  0,
  0.0   
]
```

```swift
.array([.bareword("null"), .bareword("true"), .bareword("10e-30"), .bareword("0"), .bareword("0.0")])
```

### Inside a regular expression

JSONTokenizer can also be used directly in a regular expression as it conforms to RegexComponent.

```swift
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

let result = try regex.wholeMatch(in: input)

print(result![token])
```

```swift
.array([.string("small"), .string("big")])
```
