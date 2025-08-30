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
