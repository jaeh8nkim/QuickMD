import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {

    private var webView: WKWebView!
    private var skeletonReady = false
    private var pendingInject: String?
    private var completionHandler: ((Error?) -> Void)?

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 400), configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]

        // Prevent the white flash Finder shows when swapping preview instances
        // between dark-mode files: disable the default white paint and back
        // the view's layer with the user's theme color so the moment between
        // "view attached" and "skeleton body painted" is invisible.
        webView.setValue(false, forKey: "drawsBackground")
        webView.wantsLayer = true
        webView.layer?.backgroundColor = Self.themeBackgroundColor().cgColor

        self.view = webView

        // Pre-warm: load the skeleton now so WebKit parses CSS and starts
        // fetching highlight.js/KaTeX (via preload tags) while we compute
        // the rendered HTML in parallel. preparePreviewOfFile just hands
        // the ready content off via evaluateJavaScript.
        let baseURL = Bundle.main.resourceURL
        webView.loadHTMLString(HTMLTemplate.skeleton(), baseURL: baseURL)
    }

    /// CGColor matching the CSS --bg-color for the user's current theme.
    /// Kept in sync with the palettes in github-markdown.css.
    private static func themeBackgroundColor() -> NSColor {
        let isDark: Bool
        switch Settings.colorScheme {
        case "dark":
            isDark = true
        case "light":
            isDark = false
        default: // "system"
            let appearance = NSApp?.effectiveAppearance ?? NSAppearance.current
            isDark = appearance?.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        }

        switch Settings.theme {
        case "basic":
            return isDark
                ? NSColor(red: 0x1c/255, green: 0x1c/255, blue: 0x1c/255, alpha: 1)
                : NSColor.white
        default: // "github"
            return isDark
                ? NSColor(red: 0x0d/255, green: 0x11/255, blue: 0x17/255, alpha: 1)
                : NSColor.white
        }
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let result = MarkdownRenderer.render(markdown)
            let htmlWithImages = resolveLocalImages(in: result.html, relativeTo: url)

            let js = HTMLTemplate.injectCall(
                raw: markdown,
                rendered: htmlWithImages,
                needsMath: result.needsMath,
                needsCode: result.needsCode,
                fontSize: Settings.fontSize,
                theme: Settings.theme,
                colorScheme: Settings.colorScheme,
                startRendered: Settings.defaultAction != "click"
            )

            if skeletonReady {
                inject(js, handler: handler)
            } else {
                pendingInject = js
                completionHandler = handler
            }
        } catch {
            handler(error)
        }
    }

    private func inject(_ js: String, handler: @escaping (Error?) -> Void) {
        webView.evaluateJavaScript(js) { _, error in
            handler(error)
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !skeletonReady {
            skeletonReady = true
            if let js = pendingInject, let handler = completionHandler {
                pendingInject = nil
                completionHandler = nil
                inject(js, handler: handler)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completionHandler?(error)
        completionHandler = nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    // MARK: - Local image resolution

    private static let mimeTypes: [String: String] = [
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "svg": "image/svg+xml",
        "webp": "image/webp",
        "bmp": "image/bmp",
        "ico": "image/x-icon",
    ]

    private static let imgRegex: NSRegularExpression = try! NSRegularExpression(
        pattern: #"<img\s[^>]*?src="([^"]+)"[^>]*?>"#
    )

    /// Replaces relative image `src` attributes with base64 data URIs by
    /// reading the adjacent file. The `temporary-exception.files.
    /// home-relative-path.read-only` entitlement makes the sandboxed
    /// extension able to read files under the user's home directory. Silent
    /// fallback keeps the original tag if the file can't be read.
    private func resolveLocalImages(in html: String, relativeTo fileURL: URL) -> String {
        let regex = Self.imgRegex
        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return html }

        let dir = fileURL.deletingLastPathComponent()
        var output = ""
        var cursor = 0

        for match in matches {
            let fullMatch = ns.substring(with: match.range)
            let escapedSrc = ns.substring(with: match.range(at: 1))
            // The rendered HTML escapes &, <, >, " in src. Decode before
            // building the filesystem URL so paths like "img/a&b.png" work.
            let src = MarkdownRenderer.decodeHTMLEntities(escapedSrc)

            output += ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))

            if src.hasPrefix("http://") || src.hasPrefix("https://") || src.hasPrefix("data:") || src.hasPrefix("//") {
                output += fullMatch
            } else if let data = try? Data(contentsOf: dir.appendingPathComponent(src)) {
                let ext = URL(fileURLWithPath: src).pathExtension.lowercased()
                let mime = Self.mimeTypes[ext] ?? "image/png"
                let dataURI = "data:\(mime);base64,\(data.base64EncodedString())"
                output += fullMatch.replacingOccurrences(
                    of: "src=\"\(escapedSrc)\"",
                    with: "src=\"\(dataURI)\""
                )
            } else {
                output += fullMatch
            }

            cursor = match.range.location + match.range.length
        }

        output += ns.substring(from: cursor)
        return output
    }
}
