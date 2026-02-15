#!/bin/bash
set -e

echo "==> Configuring git from host..."
if [ -f /tmp/host-gitconfig ]; then
  GIT_USER_NAME=$(git config --file /tmp/host-gitconfig user.name 2>/dev/null || true)
  GIT_USER_EMAIL=$(git config --file /tmp/host-gitconfig user.email 2>/dev/null || true)
  if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    echo "    Set git user.name: $GIT_USER_NAME"
  fi
  if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    echo "    Set git user.email: $GIT_USER_EMAIL"
  fi
else
  echo "    No ~/.gitconfig found on host, skipping"
fi

echo "==> Installing neovim and direnv..."
sudo apt-get update && sudo apt-get install -y neovim direnv

echo "==> Configuring direnv..."
grep -qF 'eval "$(direnv hook bash)"' ~/.bashrc 2>/dev/null || echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
mkdir -p ~/.config/direnv
cat > ~/.config/direnv/direnv.toml << 'TOML'
[whitelist]
prefix = ["/workspaces"]
TOML

echo "==> Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

echo "==> Adding shortcut commands..."
sudo tee /usr/local/bin/cy > /dev/null << 'EOF'
#!/bin/bash
exec claude --dangerously-skip-permissions "$@"
EOF
sudo chmod +x /usr/local/bin/cy

echo "==> Setup complete!"
echo "    Shortcuts: cy (claude)"
echo "    Run 'nvim' for neovim"
echo ""
echo "    OrbStack domain: https://${DEVCONTAINER_DOMAIN:-<not set>}"
