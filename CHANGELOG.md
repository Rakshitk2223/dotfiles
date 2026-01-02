# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-02

### Added
- Glass transparency theme as default visual style
- Comprehensive Hyprland glass effect example with detailed documentation
- Performance tuning tips for blur effects in example configs

### Changed
- **Wofi**: Updated to pure black transparent glass effect
  - Replaced solid Catppuccin colors with `rgba(0, 0, 0, 0.15-0.35)` layers
  - Creates subtle darkening effect compatible with window blur
  - Maintains consistent transparency throughout UI elements
- **Waybar**: Changed to solid background (`#1a1a1a`)
  - Improved readability when transparent windows are visible behind bar
  - Better contrast with glass-effect applications
- **Hyprland Example**: Replaced basic blur example with production glass setup
  - Active window opacity: 0.55 (55% transparent)
  - Inactive window opacity: 0.40 (40% transparent)
  - Enhanced blur: size=12, passes=3, vibrancy=0.25
  - Added 20+ lines of documentation explaining each setting
  - Included performance optimization tips

### Repository
- Updated all repository URLs from `mohak34/dotfiles` to `Rakshitk2223/dotfiles`
- Updated bootstrap curl command to use new repository
- Updated all installation documentation

### Files Modified
- `.config/wofi/style.css` - Pure black transparent glass theme
- `.config/waybar/style.css` - Solid background for readability
- `examples/hypr-local/appearance.conf` - Comprehensive glass effect setup
- `README.md` - Repository URL updates
- `boot.sh` - Repository URL updates
- `docs/installation.md` - Repository URL updates

### Visual Impact
This release introduces a cohesive glass transparency aesthetic:
- Transparent windows with enhanced blur create frosted glass effect
- Wofi launcher matches the transparency theme
- Solid waybar ensures readability against transparent backgrounds
- Example configs provide easy customization path

### Migration Notes
For existing installations:
- Wofi and Waybar configs will update automatically (managed files)
- Hyprland local configs remain untouched (user override files)
- To apply glass effect to windows, copy `examples/hypr-local/appearance.conf` to `~/.config/hypr/local/appearance.conf`

[1.0.0]: https://github.com/Rakshitk2223/dotfiles/releases/tag/v1.0.0
