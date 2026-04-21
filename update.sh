#!/usr/bin/env bash
# Bump package.nix to the latest Claude Desktop release.
# Resolves https://claude.ai/api/desktop/darwin/universal/dmg/latest/redirect
# to discover the newest build, then writes the version, URL, and SRI hash.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkg="$here/package.nix"

redirect_endpoint="https://claude.ai/api/desktop/darwin/universal/dmg/latest/redirect"
ua="Mozilla/5.0 (Macintosh; Apple Silicon Mac OS X 14_0) AppleWebKit/605.1.15"

echo "==> resolving latest DMG URL"
location=$(curl -sI -A "$ua" "$redirect_endpoint" \
  | awk 'BEGIN{IGNORECASE=1} /^location:/ {print $2}' \
  | tr -d '\r\n')

if [[ -z "$location" ]]; then
  echo "error: could not resolve redirect from $redirect_endpoint" >&2
  exit 1
fi

version=$(printf '%s' "$location" | sed -E 's|.*/darwin/universal/([^/]+)/.*|\1|')

if [[ -z "$version" || "$version" == "$location" ]]; then
  echo "error: could not parse version from $location" >&2
  exit 1
fi

echo "    version  = $version"
echo "    url      = $location"

echo "==> prefetching DMG"
sha256=$(nix-prefetch-url --type sha256 "$location")
sri=$(nix hash to-sri --type sha256 "$sha256")
echo "    hash     = $sri"

echo "==> rewriting $pkg"
# BSD sed (macOS): -i '' requires an argument.
sed -i '' -E "s|^(  version = \").*(\";)$|\1${version}\2|" "$pkg"
sed -i '' -E "s|^(    url = \").*(\";)$|\1${location}\2|" "$pkg"
sed -i '' -E "s|^(    hash = \").*(\";)$|\1${sri}\2|" "$pkg"

echo "done."
