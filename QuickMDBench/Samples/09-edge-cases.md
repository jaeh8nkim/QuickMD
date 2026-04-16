# Edge cases

## Unicode text

Hangul: 안녕하세요. Japanese: こんにちは。 Cyrillic: Привет.
Emoji: 🚀 🎉 🤔 🧪 🦀. Zero-width joiner family: 👨‍👩‍👧‍👦.
Combining characters: café vs café (the second uses e + ◌́ ).

## Right-to-left in mixed text

Arabic alongside English: "the book is called كتاب" then continues in English.

## Quotes and dashes

He said, "it's a long story — about a year and a half long," and sighed. The
'single quotes' and "double quotes" should render cleanly. An ASCII hyphen
`-`, an en dash `–`, and an em dash `—`.

## HTML-like tokens in prose

Angle brackets in prose: the type is `Array<Int>` and the HTML is `<div
class="foo">`. Ampersands in text: AT&T, rock & roll, &mdash; (which should
show as the literal text "&mdash;", not as an em dash).

## Escaped markdown

\*literal asterisks\* and \_literal underscores\_ and \`literal backticks\`.

An escaped dollar: \$5 should render as $5 literally. A doubled escape: \\$
shows a single backslash followed by the dollar.

## Whitespace inside code

```
leading    spaces
trailing spaces   
tabs	 after
```

## Empty link and image

Empty link: [](https://example.com). An empty image: ![](images/red.png).

## Inline math that should NOT render as math

Currency in prose: the widget costs $5 and the upgraded widget costs $10.
Shell variables in prose: the path is set via $PATH and the home is $HOME.

## Inline math that SHOULD render as math

A variable $x$ and an expression $f(x) = x^2 + 1$ and a Greek letter
$\alpha$ mixed into prose.

## Very long inline code

A single backtick span containing a long word: `thisisaverylongidentifierthatshouldnotbreak`.

## Trailing heading

###
