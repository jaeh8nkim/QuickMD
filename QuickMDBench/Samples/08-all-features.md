# Everything, kitchen sink

A sampler of GFM features in one document.

## Text styles

Regular, **bold**, *italic*, ***bold italic***, ~~strikethrough~~, `inline
code`, and a mix like **bold with `inline code` inside**.

Footnote-like asides in parentheses (e.g. this one) are common.

## Headers

### h3 header
#### h4 header
##### h5 header
###### h6 header

## Paragraph with soft and hard breaks

This paragraph has a soft break at the end of this line
and continues here after a newline, so the two lines flow together.

This paragraph has a hard break at the end of this line  
and continues here on a new line because of the trailing two spaces.

## Horizontal rule

---

## Blockquote

> A first-level quote that stretches across more than a single line, so we
> can check the rendering of multi-line quotes.
>
> > A nested quote, second level.
> >
> > > A third level of nesting.

## Lists

### Unordered

- foo
- bar
  - baz
  - qux
- quux

### Ordered

1. one
2. two
3. three

### Task

- [ ] undone
- [x] done

## Code

```swift
func greet(_ name: String) -> String {
    "Hello, \(name)!"
}
```

```python
def greet(name: str) -> str:
    return f"Hello, {name}!"
```

## Table

| Col A | Col B | Col C   |
|:------|:-----:|--------:|
| a1    |  b1   |     c1  |
| a2    |  b2   |     c2  |

## Link and image

A [link to Widgetron](https://example.com/widgetron) followed by a local
image: ![swatch](images/blue.png).

## Math

Inline math $\sigma^2 = \mathbb{E}[X^2] - (\mathbb{E}[X])^2$ and a display:

$$
\oint_{\partial S} \mathbf{B} \cdot d\mathbf{l} = \mu_0 I_{\text{enc}}
$$

## Raw HTML

<details>
<summary>Click to expand</summary>

Hidden content: `a = 1`, `b = 2`, `a + b = 3`.

</details>

## Trailing note

Done.
