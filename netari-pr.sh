#!/bin/bash
set -euo pipefail

TOKEN_NAME="Netari"
SYMBOL="NTI"
MINT="225Vy7jGCdCRGxGxMWuD1cBeDib4qRpuVTgQBoo9DrMx"
LOGO_PATH="/root/netari-token/assets/mainnet/${MINT}.png"
TOKENLIST_PATH="/root/netari-token/solana.tokenlist.json"
FORK_REPO="SolanaTokenList/token-list"
BRANCH="add-netari-$(date +%s)"

# ✅ 1. Check of gh beschikbaar is
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) ontbreekt. Installeer het met: apt install gh -y"
  exit 1
fi

# ✅ 2. Check of jq geïnstalleerd is
if ! command -v jq &> /dev/null; then
  echo "❌ jq is vereist voor JSON-validatie. Installeer het met: apt install jq -y"
  exit 1
fi

# ✅ 3. JSON-bestand valideren
echo "🔍 Validatie van solana.tokenlist.json..."
if ! jq empty "$TOKENLIST_PATH"; then
  echo "❌ Ongeldige JSON in $TOKENLIST_PATH"
  exit 1
fi

# ✅ 4. Vereiste velden controleren in tokenlist
MINT_FOUND=$(jq --arg mint "$MINT" '.tokens[] | select(.address == $mint)' "$TOKENLIST_PATH")

if [ -z "$MINT_FOUND" ]; then
  echo "❌ Geen entry gevonden voor mint $MINT in $TOKENLIST_PATH"
  exit 1
fi

NAME=$(echo "$MINT_FOUND" | jq -r '.name')
SYMBOL_CHECK=$(echo "$MINT_FOUND" | jq -r '.symbol')
LOGO_URI=$(echo "$MINT_FOUND" | jq -r '.logoURI')

if [ "$NAME" != "$TOKEN_NAME" ] || [ "$SYMBOL_CHECK" != "$SYMBOL" ]; then
  echo "❌ Tokennaam of symbool komt niet overeen. Verwacht: $TOKEN_NAME ($SYMBOL)"
  exit 1
fi

if [[ "$LOGO_URI" != *"${MINT}.png" ]]; then
  echo "❌ logoURI moet verwijzen naar ${MINT}.png"
  exit 1
fi

if [ ! -f "$LOGO_PATH" ]; then
  echo "❌ Logo ontbreekt op pad: $LOGO_PATH"
  exit 1
fi

echo "✅ Validatie geslaagd!"

# ✅ 5. Fork repo als nodig
cd /root/netari-token
if [ ! -d token-list ]; then
  gh repo fork "$FORK_REPO" --clone=true --remote=true
fi

cd token-list

# ✅ 6. Nieuwe branch
git checkout -b "$BRANCH"

# ✅ 7. Kopieer bestanden
mkdir -p assets/mainnet
cp "$LOGO_PATH" "assets/mainnet/${MINT}.png"
cp "$TOKENLIST_PATH" "src/tokens/solana.tokenlist.json"

# ✅ 8. Commit & Push
git add "assets/mainnet/${MINT}.png" "src/tokens/solana.tokenlist.json"
git commit -m "➕ Add Netari (NTI) token and logo"
git push origin "$BRANCH"

# ✅ 9. Pull request openen
gh pr create --title "Add Netari (NTI) token" --body "Adds Netari (NTI) token with logo and metadata to the community token list." --base main --head "$BRANCH"

echo "🚀 PR geopend voor Netari token!"
