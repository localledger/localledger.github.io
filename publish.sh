#!/bin/bash
# Publish this site to GitHub Pages under a GitHub organization.
# Usage: ./publish.sh <org-name>     (org must already exist and be owned by the gh-authenticated user)
set -euo pipefail
ORG="${1:?org name required}"
REPO="$ORG.github.io"
cd "$(dirname "$0")"

# Point the contact links at the chosen org, in case the name differs from the default.
sed -i '' "s#https://github.com/[A-Za-z0-9-]*\"#https://github.com/$ORG\"#g" index.html privacy.html
git add -A && git -c user.name="Neil Sutaria" -c user.email="Sutaria.neil@gmail.com" commit -q -m "Point contact links at $ORG" || true

if ! gh repo view "$ORG/$REPO" >/dev/null 2>&1; then
  gh repo create "$ORG/$REPO" --public --source . --remote origin --push \
    --description "Sutaria Finance: private, self-hosted personal finance dashboard"
else
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "git@github.com:$ORG/$REPO.git"
  git push -u origin HEAD:main
fi

# Enable Pages from main branch root (idempotent).
gh api -X POST "repos/$ORG/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || true

URL="https://$REPO/"
echo "Waiting for $URL ..."
for i in $(seq 1 30); do
  if curl -fsS -o /dev/null "$URL"; then echo "LIVE: $URL"; curl -fsS "$URL/privacy.html" | grep -q "Privacy Policy" && echo "LIVE: ${URL}privacy.html"; exit 0; fi
  sleep 10
done
echo "Not live yet; check: gh api repos/$ORG/$REPO/pages --jq .status"
exit 1
