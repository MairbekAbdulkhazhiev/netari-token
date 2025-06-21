#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/netari-submit-community.log"
FORK_URL="https://github.com/solana-token-ecosystem/token-list.git"
LOCAL_REPO="/root/token-list-community"
TOKENLIST_FILE="/root/netari-token/solana.tokenlist.json"
BRANCH="netari-submit-$(date +%s)"
COMMIT_MSG="➕ Netari (NTI) toegevoegd aan tokenlijst"
PR_TITLE="Add Netari (NTI) token to Solana Token List (Community Fork)"
PR_BODY="Deze PR voegt de Netari-token (NTI) toe aan de community-gebaseerde Solana tokenlijst, inclusief metadata en logo."

{
  echo "🚀 Start officiële token submit: $(date)"

  if [ ! -d "$LOCAL_REPO" ]; then
    echo "📦 Cloning community-fork..."
    git clone "$FORK_URL" "$LOCAL_REPO"
  fi

  cd "$LOCAL_REPO"
  git checkout main
  git pull origin main

  echo "🔀 Nieuwe branch maken: $BRANCH"
  git checkout -b "$BRANCH"

  echo "📁 Tokenlijst kopiëren"
  cp "$TOKENLIST_FILE" ./src/tokens/solana.tokenlist.json

  git add ./src/tokens/solana.tokenlist.json
  git commit -m "$COMMIT_MSG" || echo "⚠️ Geen commit nodig"
  git push --set-upstream origin "$BRANCH"

  echo "📬 Pull Request aanmaken..."
  gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head "$(git config user.username):$BRANCH" \
    || echo "⚠️ PR bestaat al of fout"
    
  echo "✅ Script afgerond: $(date)"
} 2>&1 | tee -a "$LOGFILE"

