# Monkey

## Summury

Monkey is for [Go 言語でつくるインタプリタ](https://www.oreilly.co.jp/books/9784873118222/)(["Writing An Interpreter in Go"](https://interpreterbook.com/)).

In the book the Moneky interpreter is written by Go.
But in this repository it is written in Crystal.
Enjoy Crystal!

## Usage

Supported for linux

```
$ git clone https://github.com/ktanaka101/monkey.git
$ cd monkey
$ crystal build --release ./src/monkey.cr
$ ./monkey
>> 1 + 1
2
>> let a = 10
>> a + 5
15
```

## Contributors

- [ktanaka101](https://github.com/ktanaka101) Kentaro Tanaka - creator, maintainer

## License

MIT
