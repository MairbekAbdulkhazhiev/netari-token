#!/bin/bash
set -o pipefail

LOGFILE="/var/log/netari-update-debug.log"
{
  echo "🔁 Start Netari update op $(date)"

  KEYPAIR="/root/netari-wallet.json"
  MINT="225Vy7jGCdCRGxGxMWuD1cBeDib4qRpuVTgQBoo9DrMx"
  RECEIVER="5GR7AnoFdWWRdb6KF1pGwmhykya6jqbnfQbtwcpBYnfT"
  METAFILE="/root/netari-meta/netari.json"
  LOGO="/root/netari-token/assets/mainnet/${MINT}.png"

  echo "✅ Check SOL balance:"
  solana balance -k "$KEYPAIR" || echo "⚠️ Fout bij SOL balance"

  echo "✅ Check token supply:"
  spl-token supply "$MINT" || echo "⚠️ Fout bij token supply"

  echo "✅ Owner account:"
  OWNER=$(solana-keygen pubkey "$KEYPAIR" 2>/dev/null || echo "geen")
  spl-token accounts --owner "$OWNER" || echo "⚠️ Geen accounts voor eigenaar"

  echo "✅ Receiver account:"
  spl-token accounts --owner "$RECEIVER" || echo "⚠️ Geen accounts voor ontvanger"

  echo "✅ Metadata check:"
  if metaboss decode mint --account "$MINT" 2>&1 | grep -qi 'Network Error'; then
    echo "❌ Metadata ontbreekt of netwerkfout"
  else
    echo "✅ Metadata gevonden"
    metaboss update data --keypair "$KEYPAIR" --account "$MINT" --new-data-file "$METAFILE" || echo "⚠️ Fout bij metadata update"
  fi

  echo "🧾 Controleren op logo:"
  if [ -f "$LOGO" ]; then
    echo "✅ Logo gevonden"
  else
    echo "❌ Logo ontbreekt op $LOGO"
  fi

  echo "🔀 Push naar GitHub:"
  cd /root/netari-token || exit 1
  git add . || echo "⚠️ Niets toe te voegen"
  git commit -m "🔄 Automatische update" || echo "⚠️ Geen commit nodig"
  
  echo "📤 Push naar remote"
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if ! git push; then
    echo "⚠️ Push mislukt. Probeer met --set-upstream voor branch: $BRANCH"
    git push --set-upstream origin "$BRANCH" || echo "❌ Push definitief mislukt"
  fi

  echo "✅ Einde script op $(date)"
} 2>&1 | tee -a "$LOGFILE"

