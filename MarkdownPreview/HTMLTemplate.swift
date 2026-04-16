import Foundation

enum HTMLTemplate {

    private static func bundleString(_ name: String, _ ext: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return content
    }

    private static let css: String = {
        bundleString("github-markdown", "css") ?? "/* github-markdown.css not found */"
    }()

    private static let katexCSS: String? = { bundleString("katex.min", "css") }()

    /// Skeleton HTML loaded once during pre-warm. Contains CSS, KaTeX CSS,
    /// and the toggle/inject JS. The body starts empty — content is injected
    /// later via evaluateJavaScript calling injectContent().
    static func skeleton() -> String {
        var styles = "<style>\(css)</style>"
        if let katexStyle = katexCSS {
            styles += "\n<style>\(katexStyle)</style>"
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        \(styles)
        </head>
        <body>
        <script>
        function toggleView(){
          var r=document.getElementById('rendered'),
              w=document.getElementById('raw'),
              b=document.getElementById('toggle-btn');
          if(w.style.display==='none'){
            w.style.display='block';r.style.display='none';
            b.textContent='Render Markdown';
          }else{
            w.style.display='none';r.style.display='block';
            b.textContent='Raw Markdown';
          }
        }

        function injectContent(rendered, raw, zoom, startRendered, needsCode, needsMath) {
          var renderedDisplay = startRendered ? 'block' : 'none';
          var rawDisplay = startRendered ? 'none' : 'block';
          var buttonText = startRendered ? 'Raw Markdown' : 'Render Markdown';

          document.body.innerHTML =
            '<button id="toggle-btn" onclick="toggleView()">' + buttonText + '</button>' +
            '<article id="rendered" class="markdown-body" style="zoom:' + zoom + ';display:' + renderedDisplay + '">' + rendered + '</article>' +
            '<pre id="raw" style="display:' + rawDisplay + '">' + raw + '</pre>';

          if (needsCode) {
            var s = document.createElement('script');
            s.src = 'highlight.min.js';
            s.onload = function(){ hljs.highlightAll(); };
            document.head.appendChild(s);
          }

          if (needsMath) {
            var k = document.createElement('script');
            k.src = 'katex.min.js';
            k.onload = function(){
              var a = document.createElement('script');
              a.src = 'auto-render.min.js';
              a.onload = function(){
                renderMathInElement(document.getElementById('rendered'), {
                  delimiters: [
                    {left:'$$', right:'$$', display:true},
                    {left:'$', right:'$', display:false}
                  ],
                  throwOnError: false,
                  strict: false
                });
              };
              document.head.appendChild(a);
            };
            document.head.appendChild(k);
          }
        }
        </script>
        </body>
        </html>
        """
    }

    /// Builds a JS call that sets the theme classes and injects content.
    static func injectCall(
        raw: String,
        rendered: String,
        needsMath: Bool,
        needsCode: Bool,
        fontSize: Int,
        theme: String,
        colorScheme: String,
        startRendered: Bool
    ) -> String {
        let zoom = String(format: "%.2f", Double(fontSize) / 100.0)
        let themeClass = (theme == "basic") ? "theme-basic" : "theme-github"
        let colorClass = "color-\(colorScheme)"

        let escapedRendered = jsEscape(rendered)
        let escapedRaw = jsEscape(htmlEscape(raw))

        return """
        document.body.className = '\(themeClass) \(colorClass)';
        injectContent('\(escapedRendered)', '\(escapedRaw)', '\(zoom)', \(startRendered), \(needsCode), \(needsMath));
        """
    }

    static func htmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func jsEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
            .replacingOccurrences(of: "\u{0000}", with: "\\u0000")
            .replacingOccurrences(of: "</script>", with: "<\\/script>")
    }
}
