# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **chezmoi dotfiles repository** that manages a comprehensive development environment configuration. Chezmoi is used to securely manage and synchronize dotfiles across multiple machines.

## Essential Commands

### Chezmoi Operations
- `chezmoi apply` - Apply configuration changes to the system
- `chezmoi apply <target_file>` - Apply configuration changes to the target file of the template file
- `chezmoi diff` - Show what would change without applying
- `chezmoi add <file>` - Add a new file to be managed by chezmoi
- `chezmoi re-add` - Update managed files with local changes
- `chezmoi cd` - Change to the chezmoi source directory
- `chezmoi init glebglazov` - Initial installation command

### Common Aliases and Functions
- `ch` - Shortcut for `chezmoi` command
- `cha` - Shortcut for `chezmoi apply`
- `ide` - Launch tmux IDE layout (calls `tmux-ide-layout`)
- `t` - Create or attach to main tmux session
- `tmux-sessioniser` - Fuzzy finder for project directories and tmux session management

### Development Environment
- **Version Management**: `mise` manages all language runtimes (Node.js, Ruby, Python, Go, Rust, Java, etc.)
- **Shell**: Primary shell is `zsh` with custom prompt and functions
- **Terminal**: Alacritty with Berkeley Mono Nerd Font
- **Editor**: Neovim with custom Lua configuration
- **Session Management**: Tmux with custom layouts and session management tools

## Architecture and Structure

### Chezmoi File Naming Conventions
- `dot_` prefix: Files that start with `.` (dotfiles)
- `private_` prefix: Files containing sensitive information (not committed to git)
- `exact_` prefix: Directories that should be exact matches
- `executable_` prefix: Files that should be executable
- `.tmpl` suffix: Template files requiring variable substitution

### Key Configuration Categories

**Shell Environment** (`home/exact_dot_my_zsh_plugins/`):
- Modular zsh configuration with separate files for different concerns
- `env_vars.sh` - Environment variables
- `aliases_and_commands.sh` - Shell aliases and functions
- `mise.sh.tmpl` - Runtime version management setup

**Development Tools**:
- `home/private_dot_config/exact_mise/config.toml` - Multi-language version management
- `home/private_dot_config/git/config.tmpl` - Git configuration with SSH signing
- `home/private_dot_config/exact_nvim/init.lua` - Neovim configuration

**Project-Specific Environments** (`home/literal_private/Dev/`):
- Work projects in `work/` subdirectory
- Personal projects in `personal/` subdirectory
- Mixed/experimental projects in `mixed/` subdirectory
- Each project contains `.envrc` files for direnv-based environment management

**Custom Scripts** (`home/dot_local/bin/`):
- `git-wrapper` - Enhanced git clone functionality with SSH URL conversion
- `tmux-ide-layout` - IDE-like tmux pane arrangements
- `tmux-sessioniser` & `tmux-windowiser` - Session management utilities
- `update-alacritty-icon` - Terminal icon customization

### Security Patterns
- Private files use `.tmpl` suffix to avoid committing secrets
- SSH keys and credentials are templated
- Environment-specific configurations are parameterized
- 1Password CLI integration for secret management

### Machine Detection and Configuration
- Automatic detection of work vs personal vs remote machines via computer name
- Machine-specific configurations using chezmoi data variables
- Work machine: `macbook-tds`
- Personal machine: `macbook-personal`
- Remote machine: `hetzner-workbench`

### External Tool Management
The `.chezmoiexternal.toml` automatically downloads and manages:
- `mise` for language version management
- `kanata` for keyboard remapping on macOS
- `antidote` for zsh plugin management
- `git-pile` for enhanced Git workflow

### Multi-Language Development Support
Configured languages and versions (via mise):
- **Frontend**: Node.js (24.4.1), Bun (1.2.18), Yarn (4.9.2), PNPM (10.13.1)
- **Backend**: Ruby (3.4.5 with YJIT), Python (3.13.5), Go (1.24.5)
- **Systems**: Rust (1.88.0), Java (24.0.2)
- **Functional**: Elixir (1.18.4), Erlang (28.0.2)
- **Infrastructure**: Terraform (1.12.2)

## Working with This Repository

### Making Changes
1. Edit files in the chezmoi source directory
2. Use `chezmoi diff` to preview changes
3. Apply with `chezmoi apply`
4. For new files, use `chezmoi add <file>` first

### Adding New Configurations
- Follow chezmoi naming conventions
- Use templates (`.tmpl`) for files needing variable substitution
- Mark sensitive files with `private_` prefix
- Use `exact_` prefix for directories requiring exact matching

### Project Environment Setup
- Project-specific environments are managed via direnv
- Each project directory contains `.envrc` files
- Environment variables are templated to avoid committing secrets

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
