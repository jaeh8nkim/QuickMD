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
        self.view = webView

        let baseURL = Bundle.main.resourceURL
        webView.loadHTMLString(HTMLTemplate.skeleton(), baseURL: baseURL)
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
            let escapedSrc = ns.substring(with: match.range(at: 1))
            // The rendered HTML escapes &, <, >, " in src. Decode before doing a
            // filesystem lookup so paths like "img/a&b.png" resolve correctly.
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
