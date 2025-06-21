#!/bin/bash
set -euo pipefail

FORK_DIR=~/token-list
MY_JSON=~/netari-token/solana.tokenlist.json
BRANCH="netari-submit-$(date +%s)"
LOG="/var/log/netari-official-submit.log"

{
  echo "🚀 Start officiële token submit: $(date)"

  # Stap 1: Ga naar fork repo
  if [ ! -d "$FORK_DIR" ]; then
    echo "❌ Fork repo niet gevonden: $FORK_DIR"
    exit 1
  fi
  cd "$FORK_DIR"

  # Stap 2: Zorg dat je remote goed staat
  git remote set-url origin https://github.com/MairbekAbdulkhazhiev/token-list.git
  git fetch origin
  git checkout main
  git pull origin main

  # Stap 3: Nieuwe branch maken
  echo "🔀 Nieuwe branch maken: $BRANCH"
  git checkout -b "$BRANCH"

  # Stap 4: Tokenlist kopiëren en committen
  cp "$MY_JSON" ./src/tokens/solana.tokenlist.json
  git add ./src/tokens/solana.tokenlist.json
  git commit -m "➕ Netari (NTI) toegevoegd aan tokenlijst"

  # Stap 5: Push naar jouw fork op GitHub
  echo "📤 Pushen naar eigen fork"
  git push --set-upstream origin "$BRANCH"

  # Stap 6: Maak de officiële PR naar solana-labs
  echo "📬 Pull request aanmaken naar solana-labs/token-list"
  gh pr create \
    --repo solana-labs/token-list \
    --title "Add Netari (NTI) token to Solana Token List" \
    --body "This PR adds Netari (NTI) to the token list, including full metadata and logo." \
    --base main \
    --head MairbekAbdulkhazhiev:"$BRANCH"

  echo "✅ Submit voltooid!"
} 2>&1 | tee -a "$LOG"
