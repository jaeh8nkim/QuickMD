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
        let formatted = SafeHTMLFormatter.format(document)
        var html = formatted.html

        html = postProcessMathBlocks(html)

        // sawMath is set during the AST walk and only fires on prose Text
        // nodes — not on inline code, fenced code, or raw HTML — so code
        // snippets containing $var or $10 no longer trigger KaTeX.
        let needsMath = html.contains("math-display") || formatted.sawMath
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

    /// Reverses the entity escaping applied by `SafeHTMLFormatter.escape`.
    /// Shared with `PreviewViewController` so it can resolve image src
    /// attributes back to filesystem paths.
    static func decodeHTMLEntities(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}

/// Replacement for swift-markdown's HTMLFormatter that properly HTML-escapes
/// text, inline code, and code block content, and renders heading children as
/// inline markdown (rather than stripping formatting via plainText).
private struct SafeHTMLFormatter: MarkupWalker {
    struct Output {
        let html: String
        /// True iff at least one prose Text node contained a plausible math
        /// delimiter pair. Code spans, fenced code, and raw HTML are skipped
        /// because they never produce Text nodes.
        let sawMath: Bool
    }

    var result = ""
    var sawMath = false
    private var tableColumnAlignments: [Table.ColumnAlignment?]? = nil
    private var inTableHead = false
    private var currentTableColumn = 0

    static func format(_ markup: Markup) -> Output {
        var walker = SafeHTMLFormatter()
        walker.visit(markup)
        return Output(html: walker.result, sawMath: walker.sawMath)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: Block elements

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>\n"
        descendInto(blockQuote)
        result += "</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let languageAttr: String
        if let language = codeBlock.language {
            languageAttr = " class=\"language-\(Self.escape(language))\""
        } else {
            languageAttr = ""
        }
        result += "<pre><code\(languageAttr)>\(Self.escape(codeBlock.code))</code></pre>\n"
    }

    mutating func visitHeading(_ heading: Heading) {
        result += "<h\(heading.level)>"
        descendInto(heading)
        result += "</h\(heading.level)>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr />\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += html.rawHTML
    }

    mutating func visitListItem(_ listItem: ListItem) {
        if let checkbox = listItem.checkbox {
            result += "<li class=\"task-list-item\"><input type=\"checkbox\" disabled=\"\""
            if checkbox == .checked {
                result += " checked=\"\""
            }
            result += " /> "
        } else {
            result += "<li>"
        }
        descendInto(listItem)
        result += "</li>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        let start = orderedList.startIndex != 1 ? " start=\"\(orderedList.startIndex)\"" : ""
        result += "<ol\(start)>\n"
        descendInto(orderedList)
        result += "</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        result += "<ul>\n"
        descendInto(unorderedList)
        result += "</ul>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        descendInto(paragraph)
        result += "</p>\n"
    }

    mutating func visitTable(_ table: Table) {
        result += "<table>\n"
        tableColumnAlignments = table.columnAlignments
        descendInto(table)
        tableColumnAlignments = nil
        result += "</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) {
        result += "<thead>\n<tr>\n"
        inTableHead = true
        currentTableColumn = 0
        descendInto(tableHead)
        inTableHead = false
        result += "</tr>\n</thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Table.Body) {
        if !tableBody.isEmpty {
            result += "<tbody>\n"
            descendInto(tableBody)
            result += "</tbody>\n"
        }
    }

    mutating func visitTableRow(_ tableRow: Table.Row) {
        result += "<tr>\n"
        currentTableColumn = 0
        descendInto(tableRow)
        result += "</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) {
        guard let alignments = tableColumnAlignments, currentTableColumn < alignments.count else { return }
        guard tableCell.colspan > 0 && tableCell.rowspan > 0 else { return }

        let element = inTableHead ? "th" : "td"
        result += "<\(element)"

        if let alignment = alignments[currentTableColumn] {
            result += " align=\"\(alignment)\""
        }
        currentTableColumn += 1

        if tableCell.rowspan > 1 {
            result += " rowspan=\"\(tableCell.rowspan)\""
        }
        if tableCell.colspan > 1 {
            result += " colspan=\"\(tableCell.colspan)\""
        }

        result += ">"
        descendInto(tableCell)
        result += "</\(element)>\n"
    }

    // MARK: Inline elements

    mutating func visitText(_ text: Text) {
        result += Self.escape(text.string)
        if !sawMath, Self.looksLikeMath(text.string) {
            sawMath = true
        }
    }

    /// Detects plausible inline/display math delimiters. Runs only on prose
    /// Text nodes, so code spans / fenced code / raw HTML are excluded by
    /// construction.
    ///
    /// Triggers on:
    /// - $$...$$  (display math with any non-empty content), or
    /// - $...$    where content either contains a LaTeX-ish char (\, ^, _,
    ///            {, }) OR starts with a non-digit character.
    ///
    /// The non-digit rule keeps `$x$`, `$f(x)$`, `$a+b$` working while
    /// rejecting currency like `$5 and $10` (content starts with a digit).
    /// `$5$` alone is intentionally rejected as ambiguous.
    private static func looksLikeMath(_ s: String) -> Bool {
        // Fast path: no `$` at all.
        guard s.contains("$") else { return false }
        if s.range(of: #"\$\$[^$]+\$\$"#, options: .regularExpression) != nil {
            return true
        }
        if s.range(of: #"\$(?:[^$\n]*[\\^_{}][^$\n]*|[^\d$\n][^$\n]*)\$"#, options: .regularExpression) != nil {
            return true
        }
        return false
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(Self.escape(inlineCode.code))</code>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        descendInto(emphasis)
        result += "</em>"
    }

    mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        descendInto(strong)
        result += "</strong>"
    }

    mutating func visitImage(_ image: Image) {
        result += "<img"
        if let source = image.source, !source.isEmpty {
            result += " src=\"\(Self.escape(source))\""
        }
        // Always emit alt, even when empty: `![](url)` indicates a decorative
        // image and `alt=""` is the correct accessibility hint for that.
        let alt = Self.plainText(of: image)
        result += " alt=\"\(Self.escape(alt))\""
        if let title = image.title, !title.isEmpty {
            result += " title=\"\(Self.escape(title))\""
        }
        result += " />"
    }

    /// Recursively collects plain text from the children of a markup node.
    /// Used to build alt text for images from their inline children.
    private static func plainText(of markup: Markup) -> String {
        var text = ""
        for child in markup.children {
            if let t = child as? Text {
                text += t.string
            } else if let c = child as? InlineCode {
                text += c.code
            } else {
                text += plainText(of: child)
            }
        }
        return text
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        result += inlineHTML.rawHTML
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br />\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "\n"
    }

    mutating func visitLink(_ link: Link) {
        result += "<a"
        if let destination = link.destination {
            result += " href=\"\(Self.escape(destination))\""
        }
        result += ">"
        descendInto(link)
        result += "</a>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += "<del>"
        descendInto(strikethrough)
        result += "</del>"
    }

    mutating func visitSymbolLink(_ symbolLink: SymbolLink) {
        if let destination = symbolLink.destination {
            result += "<code>\(Self.escape(destination))</code>"
        }
    }
}
