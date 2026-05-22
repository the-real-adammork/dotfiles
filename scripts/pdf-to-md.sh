#!/usr/bin/env bash
# Convert a PDF to Markdown.
# Usage: ./scripts/pdf-to-md.sh <input.pdf> [output.md]
# Default output: same path with .md extension.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <input.pdf> [output.md]" >&2
  exit 1
fi

input="$1"
output="${2:-${input%.pdf}.md}"

if [[ ! -f "$input" ]]; then
  echo "error: file not found: $input" >&2
  exit 1
fi

# Prefer pymupdf4llm — it preserves heading hierarchy via font analysis.
# Fall back to markitdown, then pdftotext (flat text only).
if python3 -c "import pymupdf4llm" 2>/dev/null; then
  python3 -c "import pymupdf4llm,sys; open(sys.argv[2],'w').write(pymupdf4llm.to_markdown(sys.argv[1]))" "$input" "$output"
elif command -v uvx >/dev/null 2>&1; then
  uvx --from pymupdf4llm --with pymupdf python -c "import pymupdf4llm,sys; open(sys.argv[2],'w').write(pymupdf4llm.to_markdown(sys.argv[1]))" "$input" "$output"
elif command -v markitdown >/dev/null 2>&1; then
  markitdown "$input" > "$output"
elif command -v pdftotext >/dev/null 2>&1; then
  pdftotext -layout "$input" "$output"
else
  echo "error: no PDF converter found. Install one of: pymupdf4llm, uvx, markitdown, pdftotext" >&2
  exit 1
fi

echo "wrote $output"
