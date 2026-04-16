# Code samples

A collection of code snippets in several languages to exercise the syntax
highlighter.

## Swift

```swift
import Foundation

struct Widget: Identifiable {
    let id: UUID
    let label: String
    var price: Decimal
}

extension Widget {
    static func mock(_ label: String = "mock") -> Widget {
        Widget(id: UUID(), label: label, price: 9.99)
    }
}

func total(_ widgets: [Widget]) -> Decimal {
    widgets.reduce(into: Decimal(0)) { $0 += $1.price }
}
```

## Python

```python
from dataclasses import dataclass
from decimal import Decimal

@dataclass(frozen=True)
class Widget:
    label: str
    price: Decimal = Decimal("9.99")

def total(widgets: list[Widget]) -> Decimal:
    return sum((w.price for w in widgets), Decimal(0))

if __name__ == "__main__":
    shelf = [Widget("alpha"), Widget("beta", Decimal("4.50"))]
    print(f"Total: ${total(shelf):.2f}")
```

## JavaScript

```javascript
const widgets = [
    { label: 'alpha', price: 9.99 },
    { label: 'beta',  price: 4.50 },
];

const total = ws => ws.reduce((sum, w) => sum + w.price, 0);

console.log(`Total: $${total(widgets).toFixed(2)}`);
```

## Shell

```bash
#!/usr/bin/env bash
set -euo pipefail

for f in *.md; do
    lines=$(wc -l < "$f")
    printf "%-40s %6d lines\n" "$f" "$lines"
done
```

## JSON

```json
{
  "widgets": [
    { "label": "alpha", "price": 9.99 },
    { "label": "beta", "price": 4.50 }
  ],
  "currency": "USD"
}
```

## YAML

```yaml
widgets:
  - label: alpha
    price: 9.99
  - label: beta
    price: 4.50
currency: USD
```

## Inline snippets

Call `widget.render()` to obtain the HTML. The parameters are `size`, `color`,
and `rotation` (in radians). A common invocation looks like
`widget.render(size: .medium, color: .slate)`.
