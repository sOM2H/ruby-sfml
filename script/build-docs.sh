#!/usr/bin/env bash
# Regenerate the ruby-sfml HTML docs into the sibling
# ruby-sfml-doc/public/ tree, ready to commit + push there.
#
# The docs site repo (../ruby-sfml-doc) is intentionally a
# pure-static publish artefact — no build, no Ruby on Netlify.
# This script is what produces what gets committed.
#
# Usage:
#   script/build-docs.sh              build into ../ruby-sfml-doc/public
#   script/build-docs.sh --serve      build, then open index.html
#   script/build-docs.sh --check      build into a tmp dir and diff
#                                     against the committed output
#
# Override locations if your layout differs:
#
#   RUBY_SFML_SRC=/path/to/ruby-sfml \
#   RUBY_SFML_DOC=/path/to/ruby-sfml-doc \
#     script/build-docs.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${RUBY_SFML_SRC:-$ROOT}"
DOC="${RUBY_SFML_DOC:-$ROOT/../ruby-sfml-doc}"
OUT="$DOC/public"

if [[ ! -d "$SRC/lib/sfml" ]]; then
  echo "error: ruby-sfml source not found at $SRC" >&2
  exit 1
fi
if [[ ! -d "$DOC" ]]; then
  echo "error: ruby-sfml-doc repo not found at $DOC" >&2
  echo "       set RUBY_SFML_DOC=/path/to/ruby-sfml-doc to override." >&2
  exit 1
fi

VERSION="$(ruby -I "$SRC/lib" -r sfml/version -e 'print SFML::VERSION')"
echo "==> building ruby-sfml $VERSION docs from $SRC"

TARGET="$OUT"
if [[ "${1:-}" == "--check" ]]; then
  TARGET="$(mktemp -d)"
fi

rm -rf "$TARGET"

# RDoc reads $SRC/.rdoc_options for project-wide knobs (markup,
# excludes, template). We override --title (so the version is
# baked into every page) and --output (so it lands where Netlify
# publishes).
(cd "$SRC" && rdoc \
  --title "ruby-sfml ${VERSION}" \
  --output "$TARGET" \
  README.md CHANGELOG.md LICENSE.txt lib/) 2>&1 | tail -8

# Netlify-edge fallback redirect from / → /index.html.
cat >"$TARGET/_redirects" <<'EOF'
/  /index.html  200
EOF

cat >"$TARGET/BUILD_INFO.txt" <<EOF
ruby-sfml docs site
Built:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Version: ${VERSION}
Source:  ${SRC}
Repo:    https://github.com/sOM2H/ruby-sfml
EOF

echo "==> output in $TARGET ($(du -sh "$TARGET" | cut -f1))"

if [[ "${1:-}" == "--check" ]]; then
  # `created.rid` and `BUILD_INFO.txt` always carry a timestamp,
  # so exclude them from drift detection.
  drift="$(diff -rq -x created.rid -x BUILD_INFO.txt "$OUT" "$TARGET" 2>&1 || true)"
  if [[ -n "$drift" ]]; then
    echo "::: docs in $OUT are out of date with the gem source." >&2
    echo "::: run script/build-docs.sh and commit the result in ruby-sfml-doc." >&2
    echo "$drift" | head -20 >&2
    rm -rf "$TARGET"
    exit 1
  fi
  rm -rf "$TARGET"
  echo "==> $OUT matches a fresh build."
fi

if [[ "${1:-}" == "--serve" ]]; then
  if command -v xdg-open >/dev/null; then
    xdg-open "$TARGET/index.html"
  elif command -v open >/dev/null; then
    open "$TARGET/index.html"
  else
    echo "(no opener; open $TARGET/index.html manually)"
  fi
fi
