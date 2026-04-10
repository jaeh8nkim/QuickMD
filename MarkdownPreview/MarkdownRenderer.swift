import Foundation
import Markdown

struct RenderResult {
    let html: String
    let needsMath: Bool
    let needsCode: Bool
}

enum MarkdownRenderer {

    static func render(_ markdown: String) -> RenderResult {
        let document = Document(parsing: markdown)
        var html = HTMLFormatter.format(document)

        html = postProcessMathBlocks(html)

        let needsMath = html.contains("math-display") || markdown.contains("$")
        let needsCode = html.contains("<pre><code")

        return RenderResult(html: html, needsMath: needsMath, needsCode: needsCode)
    }

    /// Converts ```math fenced code blocks from <pre><code class="language-math"> to
    /// KaTeX-renderable display math divs.
    private static func postProcessMathBlocks(_ html: String) -> String {
        let openTag = #"<pre><code class="language-math">"#
        let closeTag = "</code></pre>"
        var result = html

        while let openRange = result.range(of: openTag) {
            guard let closeRange = result.range(of: closeTag, range: openRange.upperBound..<result.endIndex) else {
                break
            }

            let encoded = String(result[openRange.upperBound..<closeRange.lowerBound])
            let latex = decodeHTMLEntities(encoded).trimmingCharacters(in: .whitespacesAndNewlines)
            let replacement = #"<div class="math-display">$$"# + latex + "$$</div>"

            result.replaceSubrange(openRange.lowerBound..<closeRange.upperBound, with: replacement)
        }

        return result
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}
