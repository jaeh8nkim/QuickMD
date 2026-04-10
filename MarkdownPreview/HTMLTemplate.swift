import Foundation

enum HTMLTemplate {

    /// CSS loaded once from the extension bundle and cached.
    private static let css: String = {
        guard let url = Bundle.main.url(forResource: "github-markdown", withExtension: "css"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return "/* github-markdown.css not found */"
        }
        return content
    }()

    /// Builds the complete HTML document for the Quick Look preview.
    ///
    /// Both the rendered HTML and raw markdown are embedded in the document.
    /// JavaScript toggles visibility between them. KaTeX and highlight.js
    /// are only included when the document actually needs them.
    static func build(
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
        let escapedRaw = htmlEscape(raw)

        let renderedDisplay = startRendered ? "block" : "none"
        let rawDisplay = startRendered ? "none" : "block"
        let buttonText = startRendered ? "Raw Markdown" : "Render Markdown"

        var head = """
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>\(css)</style>
        """

        if needsMath {
            head += "\n<link rel=\"stylesheet\" href=\"katex.min.css\">"
        }

        var scripts = """
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
        </script>
        """

        if needsCode {
            scripts += """

            <script src="highlight.min.js"></script>
            <script>hljs.highlightAll();</script>
            """
        }

        if needsMath {
            scripts += """

            <script src="katex.min.js"></script>
            <script src="auto-render.min.js"></script>
            <script>
            renderMathInElement(document.getElementById('rendered'),{
              delimiters:[
                {left:'$$',right:'$$',display:true},
                {left:'$',right:'$',display:false}
              ],
              throwOnError:false,
              strict:false
            });
            </script>
            """
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        \(head)
        </head>
        <body class="\(themeClass) \(colorClass)">
        <button id="toggle-btn" onclick="toggleView()">\(buttonText)</button>
        <article id="rendered" class="markdown-body" style="zoom:\(zoom);display:\(renderedDisplay)">
        \(rendered)
        </article>
        <pre id="raw" style="zoom:\(zoom);display:\(rawDisplay)">\(escapedRaw)</pre>
        \(scripts)
        </body>
        </html>
        """
    }

    private static func htmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
