import Foundation
import Markdown

// MARK: - CLI argument parsing

struct Options {
    var samplesDir: String
    var iterations: Int = 50
    var snapshotsDir: String? = nil
}

func parseArgs() -> Options {
    var args = CommandLine.arguments.dropFirst()
    guard let samples = args.first else {
        FileHandle.standardError.write(
            Data("usage: QuickMDBench <samples-dir> [--iters N] [--snapshots DIR]\n".utf8)
        )
        exit(2)
    }
    var opts = Options(samplesDir: samples)
    args = args.dropFirst()
    while let flag = args.first {
        args = args.dropFirst()
        switch flag {
        case "--iters":
            if let v = args.first, let n = Int(v) {
                opts.iterations = n
                args = args.dropFirst()
            }
        case "--snapshots":
            if let v = args.first {
                opts.snapshotsDir = v
                args = args.dropFirst()
            }
        default:
            break
        }
    }
    return opts
}

// MARK: - Timing helpers

@inline(__always)
func nanos() -> UInt64 {
    clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
}

func median(_ xs: [Double]) -> Double {
    let s = xs.sorted()
    return s.isEmpty ? 0 : s[s.count / 2]
}

func mean(_ xs: [Double]) -> Double {
    xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
}

// MARK: - Correctness checks

/// Minimal, markdown-specific assertions that validate features we care
/// about. Returns a list of human-readable failures (empty = all good).
func correctnessChecks(file: String, markdown: String, html: String, result: RenderResult) -> [String] {
    var issues: [String] = []
    let name = (file as NSString).lastPathComponent

    // Task list class on checkbox items (regression test for fix #1)
    if markdown.contains("- [ ]") || markdown.contains("- [x]") {
        if !html.contains("class=\"task-list-item\"") {
            issues.append("missing task-list-item class")
        }
        if !html.contains("type=\"checkbox\"") {
            issues.append("missing checkbox input")
        }
    }

    // Image alt attribute always present when an <img> is emitted (fix #3)
    if html.contains("<img") && !html.contains("alt=") {
        issues.append("img without alt attribute")
    }

    // Math detection shouldn't fire on currency/shell-heavy docs
    // The math-paper file has real math AND a currency line; needsMath must be true.
    // The edge-cases file has currency and real inline math; needsMath must be true.
    // We can't blanket assert either way without per-file expectations, so do per-file.
    switch name {
    case "03-math-paper.md":
        if !result.needsMath { issues.append("math-paper did not set needsMath") }
    case "09-edge-cases.md":
        if !result.needsMath { issues.append("edge-cases did not set needsMath (expected $x$)") }
    case "01-readme.md", "02-code-heavy.md", "05-nested-lists.md", "10-minimal.md":
        if result.needsMath { issues.append("unexpected needsMath on non-math doc") }
    default:
        break
    }

    // needsCode should fire iff the rendered HTML contains a real <pre><code> —
    // ```math fences are post-processed into math-display divs, so a doc with
    // ONLY math fences correctly reports needsCode=false.
    let htmlHasCode = html.contains("<pre><code")
    if htmlHasCode != result.needsCode {
        issues.append("needsCode=\(result.needsCode) but htmlHasCode=\(htmlHasCode)")
    }

    return issues
}

// MARK: - Main

let opts = parseArgs()
let fm = FileManager.default

guard let entries = try? fm.contentsOfDirectory(atPath: opts.samplesDir) else {
    FileHandle.standardError.write(
        Data("cannot read \(opts.samplesDir)\n".utf8)
    )
    exit(1)
}

let mdFiles = entries
    .filter { $0.hasSuffix(".md") }
    .sorted()
    .map { (opts.samplesDir as NSString).appendingPathComponent($0) }

if let snapDir = opts.snapshotsDir {
    try? fm.createDirectory(atPath: snapDir, withIntermediateDirectories: true)
}

// Column widths
let wFile = 30, wBytes = 8, wHtmlB = 8, wMs = 8, wFlag = 5

func padL(_ s: String, _ w: Int) -> String {
    s.count >= w ? s : s + String(repeating: " ", count: w - s.count)
}
func padR(_ s: String, _ w: Int) -> String {
    s.count >= w ? s : String(repeating: " ", count: w - s.count) + s
}
func f2(_ x: Double) -> String { String(format: "%.2f", x) }

// Header
print("""

QuickMDBench — render timings (parse + HTML format)
Iterations per file: \(opts.iterations)
""")
print(padL("file", wFile)
      + " " + padR("bytes", wBytes)
      + " " + padR("htmlB", wHtmlB)
      + " " + padR("min_ms", wMs)
      + " " + padR("med_ms", wMs)
      + " " + padR("mean_ms", wMs)
      + "   " + padL("math", wFlag)
      + " " + padL("code", wFlag)
      + "   issues")
print(String(repeating: "─", count: 110))

var totalMedian = 0.0
var totalIssues = 0

for path in mdFiles {
    let name = (path as NSString).lastPathComponent
    guard let markdown = try? String(contentsOfFile: path, encoding: .utf8) else {
        print("\(name): cannot read")
        continue
    }

    // Warm-up: two un-timed runs so the JIT-ish caches settle.
    _ = MarkdownRenderer.render(markdown)
    _ = MarkdownRenderer.render(markdown)

    var samples = [Double]()
    samples.reserveCapacity(opts.iterations)
    var lastResult: RenderResult = MarkdownRenderer.render(markdown)

    for _ in 0..<opts.iterations {
        let t0 = nanos()
        lastResult = MarkdownRenderer.render(markdown)
        let t1 = nanos()
        samples.append(Double(t1 - t0) / 1_000_000.0)
    }

    let minMs = samples.min() ?? 0
    let medMs = median(samples)
    let meanMs = mean(samples)

    let issues = correctnessChecks(file: path, markdown: markdown, html: lastResult.html, result: lastResult)
    let issueText = issues.isEmpty ? "ok" : "⚠ " + issues.joined(separator: "; ")

    print(padL(name, wFile)
          + " " + padR(String(markdown.utf8.count), wBytes)
          + " " + padR(String(lastResult.html.utf8.count), wHtmlB)
          + " " + padR(f2(minMs), wMs)
          + " " + padR(f2(medMs), wMs)
          + " " + padR(f2(meanMs), wMs)
          + "   " + padL(lastResult.needsMath ? "yes" : "no", wFlag)
          + " " + padL(lastResult.needsCode ? "yes" : "no", wFlag)
          + "   " + issueText)

    totalMedian += medMs
    totalIssues += issues.count

    if let snapDir = opts.snapshotsDir {
        let snapName = (name as NSString).deletingPathExtension + ".html"
        let snapPath = (snapDir as NSString).appendingPathComponent(snapName)
        try? lastResult.html.write(toFile: snapPath, atomically: true, encoding: .utf8)
    }
}

print(String(repeating: "─", count: 110))
print("total median: \(f2(totalMedian)) ms    issues: \(totalIssues)")
print("")

exit(totalIssues > 0 ? 1 : 0)
