# QuickMD — Build Instructions for Claude Code on Mac

You are setting up and building a macOS Quick Look extension app called **QuickMD** that renders Markdown files when pressing spacebar in Finder. The source code is already written. Your job is to get it building and running.

## Prerequisites

Install these if not already present:

```bash
brew install xcodegen
```

Xcode must be installed with command line tools.

## Step 1: Download Resources

Run the setup script from the project root. This downloads KaTeX (LaTeX rendering) and highlight.js (syntax highlighting) into `MarkdownPreview/Resources/`.

```bash
cd /path/to/QuickMD   # wherever this project lives
chmod +x setup.sh
./setup.sh
```

Verify the downloads succeeded:
- `MarkdownPreview/Resources/katex.min.js` should exist and be ~300KB
- `MarkdownPreview/Resources/katex.min.css` should exist
- `MarkdownPreview/Resources/auto-render.min.js` should exist
- `MarkdownPreview/Resources/katex-fonts/` should contain ~20 `.woff2` files
- `MarkdownPreview/Resources/highlight.min.js` should exist and be ~70KB

If any download failed (network issues, CDN changes), re-run or download manually from:
- KaTeX: https://github.com/KaTeX/KaTeX/releases
- highlight.js: https://highlightjs.org/download

## Step 2: Generate Xcode Project

```bash
xcodegen generate
```

This reads `project.yml` and produces `QuickMD.xcodeproj`. Open it:

```bash
open QuickMD.xcodeproj
```

## Step 3: Configure Signing and App Group

This step requires manual Xcode configuration. You cannot do this from the CLI.

Instruct the user to do the following in Xcode:

1. **Select the QuickMD target** → Signing & Capabilities tab
   - Set a valid Development Team
   - The bundle identifier is `com.quickmd.app` — change if needed to match their team
   - Verify the "App Groups" capability is listed with `group.com.quickmd.shared`
   - If the App Group shows a red error, click the refresh button or re-add it

2. **Select the MarkdownPreview target** → Signing & Capabilities tab
   - Set the same Development Team
   - The bundle identifier is `com.quickmd.app.markdownpreview`
   - Verify "App Groups" capability with the same `group.com.quickmd.shared`

3. If the user changes the bundle ID prefix (e.g., from `com.quickmd` to `com.theirname.quickmd`), update these places:
   - `project.yml`: both `PRODUCT_BUNDLE_IDENTIFIER` values
   - Both `.entitlements` files: the App Group string must match in both
   - Re-run `xcodegen generate` after editing `project.yml`

**Important**: Both targets MUST use the same App Group identifier, or settings from the host app won't be readable by the extension.

## Step 4: Build and Run

1. Select the **QuickMD** scheme (not MarkdownPreview)
2. Build target: **My Mac**
3. Build & Run (Cmd+R)

The app should launch and show a settings window with three dropdowns:
- Font Size (80%–140%)
- Theme (System / Light / Dark)
- Default Action (Always Render / Render on Click)

### If it fails to build

Common issues:

- **swift-markdown SPM package not resolved**: Xcode should auto-resolve it on first open. If not: File → Packages → Resolve Package Versions. The dependency is `https://github.com/swiftlang/swift-markdown` version 0.5.0+.
- **Signing errors**: The user needs a valid Apple Developer account (free or paid). Both targets need the same team.
- **App Group provisioning**: If running on macOS without a paid developer account, App Groups may not be available. As a workaround, remove the App Group entitlement from both `.entitlements` files and change `Settings.swift` to use `UserDefaults.standard` instead of the suite. Settings won't sync between app and extension, but the extension will use defaults.
- **"No such module 'Markdown'"** on the MarkdownPreview target: Make sure the swift-markdown package dependency is linked to the MarkdownPreview target, not just the QuickMD target. In Xcode: MarkdownPreview target → General → Frameworks and Libraries → add the `Markdown` library from the swift-markdown package.

## Step 5: Enable the Quick Look Extension

After the first successful build and launch:

1. Open **System Settings → General → Login Items & Extensions**
2. Scroll down to **Quick Look** (or search for it)
3. Find **QuickMD** and toggle it on

Alternatively, from Terminal:
```bash
# List registered Quick Look preview extensions
pluginkit -m -v -p com.apple.quicklook.preview | grep -i quickmd

# Reset Quick Look if the extension isn't appearing
qlmanage -r && qlmanage -r cache
```

## Step 6: Test

Create a test markdown file or use an existing one:

```bash
cat > /tmp/test.md << 'EOF'
# Hello from QuickMD

This is **bold** and *italic* text.

## Code Block

```python
def hello():
    print("Hello, world!")
```

## Math

Inline equation: $E = mc^2$

Display equation:

$$\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}$$

Fenced math block:

```math
\sum_{k=1}^{n} k = \frac{n(n+1)}{2}
```

## Table

| Feature | Status |
|---------|--------|
| GFM tables | Yes |
| Task lists | Yes |
| Strikethrough | Yes |

## Task List

- [x] Render markdown
- [x] Syntax highlighting
- [ ] World domination

> This is a blockquote with ~~strikethrough~~.
EOF
```

Then in Finder, navigate to `/tmp/` and press spacebar on `test.md`. You should see rendered markdown instead of raw text, with a "Raw Markdown" button in the top-right corner.

### What to verify

- [ ] Rendered markdown appears instantly (not raw text)
- [ ] Toggle button switches between "Raw Markdown" and "Render Markdown"
- [ ] Code block has syntax highlighting with colors
- [ ] Math equations render (inline $E=mc^2$ and display block)
- [ ] ```math fenced block renders as display math
- [ ] Table has borders and alternating row colors
- [ ] Task list shows checkboxes
- [ ] Dark mode: switch macOS to dark mode, re-open Quick Look — colors should adapt (if theme is set to "System")
- [ ] Settings changes take effect on next Quick Look open (close and reopen preview after changing settings)

## Troubleshooting

**Extension not appearing in Quick Look:**
```bash
qlmanage -r && qlmanage -r cache
killall Finder
```
Then try again. May need to log out and back in.

**Extension shows raw text instead of rendered:**
Another app may have claimed the markdown UTI. Check:
```bash
mdls -name kMDItemContentType /tmp/test.md
```
Should show `net.daringfireball.markdown` or `public.markdown`. If it shows something else (e.g., `com.obsidian.markdown`), another app is overriding the UTI. Disable competing Quick Look extensions in System Settings.

**KaTeX not rendering / highlight.js not working:**
Verify the resource files exist in the built app:
```bash
ls "$(find ~/Library/Developer/Xcode/DerivedData -name 'MarkdownPreview.appex' -path '*/Build/Products/*' 2>/dev/null | head -1)/Contents/Resources/"
```
Should list `katex.min.js`, `katex.min.css`, `auto-render.min.js`, `highlight.min.js`, `github-markdown.css`, and the `katex-fonts/` directory. If missing, the resources weren't copied — check that `MarkdownPreview/Resources/` has the files and that the Xcode target includes them in the Copy Bundle Resources build phase.

**Settings not syncing between app and extension:**
App Group must be correctly provisioned. Check both targets have the same App Group identifier in their entitlements. Try changing a setting in the app, then running:
```bash
defaults read group.com.quickmd.shared
```
If this shows the values, the App Group is working. If it errors, the App Group provisioning failed.

## Architecture Summary (for context)

```
QuickMD.app                          → Host app, settings UI only
  Contents/PlugIns/
    MarkdownPreview.appex             → Quick Look preview extension
      Contents/Resources/
        github-markdown.css           → GitHub-flavored CSS (inlined at runtime)
        katex.min.js                  → LaTeX rendering (loaded only when $ detected)
        katex.min.css                 → KaTeX styles + font references
        auto-render.min.js            → KaTeX auto-render for $...$ delimiters
        katex-fonts/                  → KaTeX woff2 fonts
        highlight.min.js              → Syntax highlighting (loaded only when code blocks detected)
```

The extension renders markdown to HTML using Apple's swift-markdown (cmark-gfm), wraps it in a full HTML document with GitHub-flavored CSS, and loads it in a WKWebView. KaTeX and highlight.js are only injected when the document contains math or code blocks respectively. A toggle button in the top-right switches between rendered and raw views.
