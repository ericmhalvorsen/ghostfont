# Ghostty Font Picker

An interactive terminal-based font picker in lua. For the Ghostty terminal emulator.

## Usage

Run the font picker:

```bash
./ghostfont.lua
```

- **↑/↓** - Navigate through fonts
- **P** - Preview font
- **Enter** - Save selected font to Ghostty config
- **Q** or **Esc** - Quit without saving

<img width="1171" height="781" alt="Screenshot 2025-11-23 at 11 24 07 PM" src="https://github.com/user-attachments/assets/2cd43d5e-60ea-4626-8675-1162ad398238" />

Fetches available fonts using `ghostty +list-fonts`
Updates your Ghostty config file at:
   - `~/.config/ghostty/config` or
   - `~/.ghostty`

The script automatically creates or updates the `font-family` setting in your config.

- [ ] Search/filter fonts
- [ ] Favorite fonts
- [ ] NeoVim plugin

## License

MIT
