#!/usr/bin/env bash
set -euo pipefail

IDENTITY_LINE="$(security find-identity -p codesigning -v | awk '/"Apple Development:/{print; exit}')"

if [[ -z "$IDENTITY_LINE" ]]; then
  cat >&2 <<'MESSAGE'
No Apple Development identity was found.

Open Xcode → Settings → Accounts, sign in with your Apple Account, select your
Personal Team, and click Manage Certificates → + → Apple Development. A free
Personal Team is enough for this local-only app; a paid Developer ID is not
required.
MESSAGE
  exit 1
fi

IDENTITY_HASH="$(awk '{print $2}' <<<"$IDENTITY_LINE")"
IDENTITY_NAME="$(sed -E 's/^[[:space:]]*[0-9]+\) [[:xdigit:]]+ "(.*)"$/\1/' <<<"$IDENTITY_LINE")"

echo "Local signing is ready."
echo "Identity: $IDENTITY_NAME"
echo "Fingerprint: $IDENTITY_HASH"
