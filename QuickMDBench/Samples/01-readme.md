# Widgetron

A tiny utility for widget management.

## Installation

```bash
brew install widgetron
```

## Usage

The `widgetron` command takes a single argument:

```bash
widgetron --count 5
```

This produces five widgets. Each widget is identified by a UUID and persisted
to `~/.widgetron/widgets.db`.

## Configuration

| Key        | Default | Description                          |
|------------|--------:|--------------------------------------|
| `timeout`  |    `30` | Request timeout in seconds           |
| `retries`  |     `3` | Number of retries on failure         |
| `verbose`  | `false` | Emit extra diagnostic output         |

## Contributing

1. Fork the repository on [GitHub](https://github.com/example/widgetron).
2. Clone your fork and create a topic branch.
3. Run the test suite with `widgetron test` before opening a pull request.

## License

MIT. See the `LICENSE` file for the full text.
