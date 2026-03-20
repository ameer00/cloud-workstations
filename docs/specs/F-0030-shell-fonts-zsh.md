# F-0030: ZSH Shell, Nerd Fonts, Starship Prompt, and Terminal Config

**Type:** Feature
**Priority:** P0 (critical)
**Status:** Draft
**Requested by:** PO
**Date:** 2026-03-20

## Problem

The Cloud Workstation currently uses the default bash shell with default fonts and no prompt customization. The PO requires a modern, productive terminal environment with Nerd Font support for icon glyphs, ZSH as the default shell with syntax highlighting and autosuggestions, the Starship cross-shell prompt, and the foot terminal configured with the correct font and size.

## Requirements

1. **R1 — Install Fonts from dev-fonts/ directory:** Install ALL fonts from the `dev-fonts/` directory in the repo to `~/.local/share/fonts/` on the workstation. This includes:
   - **CascadiaCode** (`dev-fonts/CascadiaCode/`) — Full CascadiaCode family (OTF + TTF, variable + static)
   - **CaskaydiaCove Nerd Font** (`dev-fonts/CaskaydiaCove/`) — Bold, ExtraLight, Light, Regular, SemiBold, SemiLight
   - **FiraCodeiScript** (`dev-fonts/FiraCodeiScript/`) — FiraCode + Script italic variant (Bold, Italic, Regular TTF)
   - **Operator Mono** (`dev-fonts/Operator-Mono/Fonts/` and `dev-fonts/dev-fonts/`) — Multiple weights

   Copy all `.otf` and `.ttf` files from the entire `dev-fonts/` directory tree to `~/.local/share/fonts/`. Fonts are already in the repo — no need to download from GitHub releases. Run `fc-cache -fv` after copying to rebuild the font cache.

2. **R2 — Make ZSH the default shell:** Set ZSH as the default shell. Since `chsh` may not work in a container environment, add `exec zsh` to `.bashrc` as a fallback mechanism. Ensure that opening the foot terminal launches ZSH, not bash.

3. **R3 — Install zsh-syntax-highlighting plugin:** Clone `https://github.com/zsh-users/zsh-syntax-highlighting.git` to `~/.zsh/zsh-syntax-highlighting`. Source it in `.zshrc` with `source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`. No plugin manager (no oh-my-zsh, no zinit, no antigen, etc.).

4. **R4 — Install zsh-autosuggestions plugin:** Clone `https://github.com/zsh-users/zsh-autosuggestions.git` to `~/.zsh/zsh-autosuggestions`. Source it in `.zshrc` with `source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh`. No plugin manager.

5. **R5 — Install Starship prompt:** Install Starship via Nix (preferred) or via the curl installer to `~/.local/bin`. Add `eval "$(starship init zsh)"` to `.zshrc`. Use the default Starship config or a minimal config.

6. **R6 — Configure foot terminal font:** Set the foot terminal font to `Operator Mono Book:size=18` (with `Operator Mono Light:size=18` as fallback) in `~/.config/foot/foot.ini`. Use `font=Operator Mono Book:size=18` as the primary font setting.

## Acceptance Criteria

- [ ] AC1: `fc-list` shows Operator Mono, CascadiaCode, CaskaydiaCove, and FiraCodeiScript font families
- [ ] AC2: Opening foot terminal launches ZSH (not bash) — verified by `echo $SHELL` or `echo $0`
- [ ] AC3: ZSH has syntax highlighting (valid commands colored green, invalid red) and autosuggestions (grey ghost text from history)
- [ ] AC4: Starship prompt is visible in the terminal (shows directory, git status, etc.)
- [ ] AC5: Terminal font is Operator Mono at size 18 — verified visually and in foot.ini config
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
