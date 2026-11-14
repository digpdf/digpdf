#!/usr/bin/env bash
# check.sh VERSION DIR: the files in DIR are exactly the packages that SHA256SUMS (of the tagged commit, in the
# current folder) names for VERSION - sixteen of them, eight wheels and eight archives, each with the hash named.
set -euo pipefail
version="$1"
dir="$2"

names="$(awk '{print $2}' SHA256SUMS | LC_ALL=C sort)"
if [ "$(awk 'NF != 2' SHA256SUMS | wc -l)" -ne 0 ]; then
  echo "::error::SHA256SUMS has a line that is not a hash and a name"; exit 1
fi
if [ "$(printf '%s\n' "$names" | wc -l)" -ne 16 ] || [ "$(printf '%s\n' "$names" | uniq | wc -l)" -ne 16 ]; then
  echo "::error::SHA256SUMS does not name sixteen different packages"; exit 1
fi
if [ "$(printf '%s\n' "$names" | grep -c '\.whl$')" -ne 8 ]; then
  echo "::error::SHA256SUMS does not name eight wheels"; exit 1
fi
if printf '%s\n' "$names" | grep -qv "^digpdf-$(printf '%s' "$version" | sed 's/\./\\./g')-[A-Za-z0-9_.-]*\.\(whl\|tar\.gz\|zip\)$"; then
  echo "::error::SHA256SUMS names a file that is not a package of digpdf $version"; exit 1
fi
there="$(cd "$dir" && find . -mindepth 1 -maxdepth 1 -not -name .git -printf '%f\n' | LC_ALL=C sort)"
if [ "$names" != "$there" ]; then
  echo "::error::the branch does not hold exactly the packages SHA256SUMS names"
  diff <(printf '%s\n' "$names") <(printf '%s\n' "$there") || true
  exit 1
fi
sums="$PWD/SHA256SUMS"
(cd "$dir" && sha256sum --check --strict --quiet "$sums")
echo "the sixteen packages of digpdf $version are the ones the tag names"
