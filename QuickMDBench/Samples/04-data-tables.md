# Data tables

## Simple table

| Name   | Quantity | Price |
|--------|---------:|------:|
| Alpha  |        3 |  9.99 |
| Beta   |       12 |  4.50 |
| Gamma  |        1 | 22.00 |
| Delta  |        7 |  3.25 |

## Alignment variants

| Left      | Center     | Right |
|:----------|:----------:|------:|
| foo       | middle     |   123 |
| bar       | center     |    45 |
| baz       | axis       |     6 |

## Wide table

| Key     | Default | Required | Type     | Description                        |
|---------|---------|:--------:|----------|------------------------------------|
| host    | `null`  |    ✓     | `string` | Fully qualified hostname           |
| port    | `443`   |          | `int`    | TCP port number                    |
| path    | `/`     |          | `string` | Request path component             |
| timeout | `30`    |          | `int`    | Request timeout in seconds         |
| retries | `3`     |          | `int`    | Retry count on transient failure   |
| verbose | `false` |          | `bool`   | Emit extra diagnostic output       |

## Table with inline formatting

| Command         | Purpose                                  | Notes                     |
|-----------------|------------------------------------------|---------------------------|
| `widgetron new` | Create a new widget                      | Asks for a **label**      |
| `widgetron ls`  | List widgets in the *active* workspace   | Output is _paginated_     |
| `widgetron rm`  | Remove a widget by id                    | Requires `--force` flag   |
| `widgetron env` | Print environment variables              | Includes `$HOME`, `$PATH` |

## Sparse content

| Col A | Col B | Col C |
|-------|-------|-------|
|       | has   |       |
| only  |       |       |
|       |       | tail  |
