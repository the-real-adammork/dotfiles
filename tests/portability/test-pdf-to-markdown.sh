#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
new_fixture

SCRIPT="$REPO/chezmoi/lib_sh/executable_pdf-to-markdown"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

fake_python="$FIXTURE_ROOT/fake-python"
cat > "$fake_python" <<'FAKEPY'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == "-c" ]]; then
    code="$2"
    shift 2
    [[ "$code" == "import pymupdf4llm" ]] && exit 0
    printf '# Converted\n\nSource: %s\n' "$(basename "$1")" > "$2"
    exit 0
fi

exit 1
FAKEPY
chmod +x "$fake_python"

if "$SCRIPT" >"$FIXTURE_ROOT/noargs.out" 2>"$FIXTURE_ROOT/noargs.err"; then
    fail "no-argument invocation should fail"
fi
assert_contains "$FIXTURE_ROOT/noargs.err" "usage:"

if "$SCRIPT" "$FIXTURE_ROOT/missing.pdf" >"$FIXTURE_ROOT/missing.out" 2>"$FIXTURE_ROOT/missing.err"; then
    fail "missing PDF invocation should fail"
fi
assert_contains "$FIXTURE_ROOT/missing.err" "file not found"

input="$FIXTURE_ROOT/sample document.pdf"
touch "$input"
PDF_TO_MARKDOWN_PYTHON="$fake_python" "$SCRIPT" "$input" >"$FIXTURE_ROOT/valid.out"

output="$FIXTURE_ROOT/sample document.md"
assert_contains "$output" "# Converted"
assert_contains "$output" "Source: sample document.pdf"
assert_contains "$FIXTURE_ROOT/valid.out" "wrote $output"

printf 'pdf-to-markdown: ok\n'
