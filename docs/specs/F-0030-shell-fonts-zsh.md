# F-0030: ZSH Shell, Nerd Fonts, Starship Prompt, and Terminal Config

**Type:** Feature
**Priority:** P0 (critical)
**Status:** Draft
**Requested by:** PO
**Date:** 2026-03-20

## Problem

The Cloud Workstation currently uses the default bash shell with default fonts and no prompt customization. The PO requires a modern, productive terminal environment with Nerd Font support for icon glyphs, ZSH as the default shell with syntax highlighting and autosuggestions, the Starship cross-shell prompt, and the foot terminal configured with the correct font and size.

## Requirements

1. **R1 — Install Nerd Fonts:** Install CascadiaCode (CaskaydiaCove Nerd Font) and FiraCode (FiraCode Nerd Font) to `~/.local/share/fonts` via direct download from the [Nerd Fonts GitHub releases](https://github.com/ryanoasis/nerd-fonts/releases). Extract the font files and run `fc-cache -fv` to rebuild the font cache.

2. **R2 — Make ZSH the default shell:** Set ZSH as the default shell. Since `chsh` may not work in a container environment, add `exec zsh` to `.bashrc` as a fallback mechanism. Ensure that opening the foot terminal launches ZSH, not bash.

3. **R3 — Install zsh-syntax-highlighting plugin:** Clone `https://github.com/zsh-users/zsh-syntax-highlighting.git` to `~/.zsh/zsh-syntax-highlighting`. Source it in `.zshrc` with `source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`. No plugin manager (no oh-my-zsh, no zinit, no antigen, etc.).

4. **R4 — Install zsh-autosuggestions plugin:** Clone `https://github.com/zsh-users/zsh-autosuggestions.git` to `~/.zsh/zsh-autosuggestions`. Source it in `.zshrc` with `source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh`. No plugin manager.

5. **R5 — Install Starship prompt:** Install Starship via Nix (preferred) or via the curl installer to `~/.local/bin`. Add `eval "$(starship init zsh)"` to `.zshrc`. Use the default Starship config or a minimal config.

6. **R6 — Configure foot terminal font:** Set the foot terminal font to `CaskaydiaCove Nerd Font:size=18` in `~/.config/foot/foot.ini`. Note: The CascadiaCode Nerd Font is named "CaskaydiaCove Nerd Font" in the actual font files due to Nerd Fonts naming conventions.

## Acceptance Criteria

- [ ] AC1: `fc-list` shows CaskaydiaCove and FiraCode Nerd Font families installed
- [ ] AC2: Opening foot terminal launches ZSH (not bash) — verified by `echo $SHELL` or `echo $0`
- [ ] AC3: ZSH has syntax highlighting (valid commands colored green, invalid red) and autosuggestions (grey ghost text from history)
- [ ] AC4: Starship prompt is visible in the terminal (shows directory, git status, etc.)
- [ ] AC5: Terminal font is CaskaydiaCove Nerd Font at size 18 — verified visually and in foot.ini config
- [ ] AC6: No plugin manager used — plugins are plain git clones in `~/.zsh/` sourced directly in `.zshrc`

## Out of Scope

- Custom Starship theme/config beyond default — can be done later
- Other shells (fish, etc.)
- Font configuration for GUI apps other than foot terminal
- Oh-my-zsh, zinit, antigen, or any other ZSH plugin/framework manager

## Dependencies

- F-0015 (dev tools via Nix HM — ZSH already installed via Nix)
- F-0016 (Sway + foot terminal setup)

## Open Questions

- None currently — all requirements are well-defined by PO
