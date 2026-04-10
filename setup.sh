#!/bin/bash
# Downloads KaTeX and highlight.js into MarkdownPreview/Resources/
# Run this once before building in Xcode.

set -euo pipefail

RESOURCES="MarkdownPreview/Resources"
mkdir -p "$RESOURCES/katex-fonts"

KATEX_VERSION="0.16.21"
HLJS_VERSION="11.11.1"

echo "==> Downloading KaTeX v${KATEX_VERSION}..."
curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/katex.min.js" \
    -o "$RESOURCES/katex.min.js"
curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/katex.min.css" \
    -o "$RESOURCES/katex.min.css"
curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/contrib/auto-render.min.js" \
    -o "$RESOURCES/auto-render.min.js"

# Download KaTeX fonts (woff2 only -- smallest, all modern browsers/WebKit support)
KATEX_FONTS=(
    KaTeX_AMS-Regular
    KaTeX_Caligraphic-Bold
    KaTeX_Caligraphic-Regular
    KaTeX_Fraktur-Bold
    KaTeX_Fraktur-Regular
    KaTeX_Main-Bold
    KaTeX_Main-BoldItalic
    KaTeX_Main-Italic
    KaTeX_Main-Regular
    KaTeX_Math-BoldItalic
    KaTeX_Math-Italic
    KaTeX_SansSerif-Bold
    KaTeX_SansSerif-Italic
    KaTeX_SansSerif-Regular
    KaTeX_Script-Regular
    KaTeX_Size1-Regular
    KaTeX_Size2-Regular
    KaTeX_Size3-Regular
    KaTeX_Size4-Regular
    KaTeX_Typewriter-Regular
)

for font in "${KATEX_FONTS[@]}"; do
    curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/fonts/${font}.woff2" \
        -o "$RESOURCES/katex-fonts/${font}.woff2"
done

echo "==> Downloading highlight.js v${HLJS_VERSION} (common languages)..."
curl -sL "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${HLJS_VERSION}/build/highlight.min.js" \
    -o "$RESOURCES/highlight.min.js"

echo "==> Patching KaTeX CSS font paths..."
# KaTeX CSS references fonts/ -- we need katex-fonts/ since that's our directory
sed -i.bak 's|fonts/|katex-fonts/|g' "$RESOURCES/katex.min.css"
rm -f "$RESOURCES/katex.min.css.bak"

echo "==> Done. Resources downloaded to ${RESOURCES}/"
ls -lh "$RESOURCES/"
