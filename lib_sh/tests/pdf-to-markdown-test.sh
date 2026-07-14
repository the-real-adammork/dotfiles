#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="${PDF_TO_MARKDOWN_SCRIPT:-$REPO_DIR/lib_sh/lib_sh/pdf-to-markdown}"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local expected="$2"

    [[ -f "$file" ]] || fail "expected file to exist: $file"
    grep -Fq "$expected" "$file" || fail "expected $file to contain: $expected"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fake_python="$tmpdir/fake-python"
cat > "$fake_python" <<'FAKEPY'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == "-c" ]]; then
    code="$2"
    shift 2
    if [[ "$code" == "import pymupdf4llm" ]]; then
        exit 0
    fi

    input="$1"
    output="$2"
    printf '# Converted\n\nSource: %s\n' "$(basename "$input")" > "$output"
    exit 0
fi

exit 1
FAKEPY
chmod +x "$fake_python"

if "$SCRIPT" >/tmp/pdf-to-markdown-noargs.out 2>/tmp/pdf-to-markdown-noargs.err; then
    fail "no-argument invocation should fail"
fi
grep -Fq "usage:" /tmp/pdf-to-markdown-noargs.err || fail "no-argument error should include usage"

if "$SCRIPT" "$tmpdir/missing.pdf" >/tmp/pdf-to-markdown-missing.out 2>/tmp/pdf-to-markdown-missing.err; then
    fail "missing PDF invocation should fail"
fi
grep -Fq "file not found" /tmp/pdf-to-markdown-missing.err || fail "missing file error should mention file not found"

input="$tmpdir/sample document.pdf"
touch "$input"
PDF_TO_MARKDOWN_PYTHON="$fake_python" "$SCRIPT" "$input" >/tmp/pdf-to-markdown-valid.out

output="$tmpdir/sample document.md"
assert_file_contains "$output" "# Converted"
assert_file_contains "$output" "Source: sample document.pdf"
grep -Fq "wrote $output" /tmp/pdf-to-markdown-valid.out || fail "success output should print markdown path"

printf 'ok - pdf-to-markdown contract\n'
