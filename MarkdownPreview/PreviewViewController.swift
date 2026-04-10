import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {

    private var webView: WKWebView!
    private var completionHandler: ((Error?) -> Void)?
    private var titleObservation: NSKeyValueObservation?

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 400), configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]
        self.view = webView

        titleObservation = webView.observe(\.title, options: .new) { _, change in
            guard let title = change.newValue ?? nil else { return }
            if title == "mode:raw" || title == "mode:rendered" {
                let mode = String(title.dropFirst(5))
                Settings.setLastViewMode(mode)
            }
        }
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let result = MarkdownRenderer.render(markdown)
            let htmlWithImages = resolveLocalImages(in: result.html, relativeTo: url)

            let fullHTML = HTMLTemplate.build(
                raw: markdown,
                rendered: htmlWithImages,
                needsMath: result.needsMath,
                needsCode: result.needsCode,
                fontSize: Settings.fontSize,
                theme: Settings.theme,
                colorScheme: Settings.colorScheme,
                startRendered: Settings.startRendered
            )

            self.completionHandler = handler
            let baseURL = Bundle.main.resourceURL
            webView.loadHTMLString(fullHTML, baseURL: baseURL)
        } catch {
            handler(error)
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        completionHandler?(nil)
        completionHandler = nil
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

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        completionHandler?(error)
        completionHandler = nil
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

    /// Finds `<img src="...">` tags with local (relative) paths, reads the image files,
    /// and replaces the src with base64 data URIs. This works around the sandbox restriction
    /// where the WebView's baseURL points to the bundle, not the markdown file's directory.
    private func resolveLocalImages(in html: String, relativeTo fileURL: URL) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"<img\s[^>]*?src="([^"]+)"[^>]*?>"#
        ) else {
            return html
        }

        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return html }

        let dir = fileURL.deletingLastPathComponent()
        var output = ""
        var cursor = 0

        for match in matches {
            let fullMatch = ns.substring(with: match.range)
            let src = ns.substring(with: match.range(at: 1))

            // Append text between previous match and this one
            output += ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))

            if src.hasPrefix("http://") || src.hasPrefix("https://") || src.hasPrefix("data:") || src.hasPrefix("//") {
                output += fullMatch
            } else if let data = try? Data(contentsOf: dir.appendingPathComponent(src)) {
                let ext = URL(fileURLWithPath: src).pathExtension.lowercased()
                let mime = Self.mimeTypes[ext] ?? "image/png"
                let dataURI = "data:\(mime);base64,\(data.base64EncodedString())"
                output += fullMatch.replacingOccurrences(
                    of: "src=\"\(src)\"",
                    with: "src=\"\(dataURI)\""
                )
            } else {
                // Could not read image (sandbox or missing file) — keep original
                output += fullMatch
            }

            cursor = match.range.location + match.range.length
        }

        output += ns.substring(from: cursor)
        return output
    }
}
