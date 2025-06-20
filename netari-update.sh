#!/bin/bash
set -euo pipefail

KEYPAIR="/root/netari-wallet.json"
MINT="225Vy7jGCdCRGxGxMWuD1cBeDib4qRpuVTgQBoo9DrMx"
RECEIVER="5GR7AnoFdWWRdb6KF1pGwmhykya6jqbnfQbtwcpBYnfT"
REPO="MairbekAbdulkhazhiev/netari-token"
METAFILE="/root/netari-meta/netari.json"
LOGO="/root/netari-token/assets/mainnet/${MINT}.png"
TOKEN=$(cat ~/.github_token)

# 📌 Zet git remote met token
git remote remove origin 2>/dev/null || true
git remote add origin "https://${TOKEN}@github.com/${REPO}.git"

# 🧠 Git config voor auto-auth
git config --global credential.helper store
echo "https://${TOKEN}@github.com" > ~/.git-credentials

echo "✅ Check SOL balance"
solana balance -k "$KEYPAIR"

echo "✅ Check token supply"
spl-token supply "$MINT"

echo "✅ SPL token accounts voor owner:"
spl-token accounts --owner "$(solana-keygen pubkey "$KEYPAIR")"

echo "✅ SPL token accounts voor receiver:"
spl-token accounts --owner "$RECEIVER"

echo "✅ Check metadata"
if metaboss decode mint --account "$MINT" 2>&1 | grep -qi 'Network Error'; then
  echo "❌ Metadata ontbreekt of netwerkfout"
else
  echo "✅ Metadata bestaat!"
fi

echo "🔧 Metadata bijwerken via Metaboss"
if [ -f "$METAFILE" ]; then
  metaboss update data --keypair "$KEYPAIR" --account "$MINT" --new-data-file "$METAFILE"
else
  echo "❌ Metadatafile ontbreekt: $METAFILE"
  exit 1
fi

echo "🧾 Check of logo aanwezig is"
if [ -f "$LOGO" ]; then
  echo "✅ Logo is aanwezig"
else
  echo "❌ Logo ontbreekt: $LOGO"
  exit 1
fi

echo "🔀 Push naar GitHub"
cd /root/netari-token
git add .
git commit -m "🔄 Automatische Netari update via veilig script" || echo "⚠️ Niets te committen"
git push origin main
