# Ghostty Font Picker

An interactive terminal-based font picker for the Ghostty terminal emulator.

## Features

- 🎨 Interactive font selection with arrow key navigation
- 👁️ **Real-time font preview** - see fonts applied as you navigate
- ⚡ Fast and lightweight - pure Lua with no external dependencies
- 🔄 Automatic Ghostty config update
- 📝 Sample text includes pangram, terminal commands, and SQL queries
- ✨ Character comparison samples (0O, iIl1, etc.)

## Requirements

- Lua 5.1 or higher
- Ghostty terminal emulator
- Unix-like system (Linux, macOS)

## Installation

1. Make the script executable:
   ```bash
   chmod +x ghostfont.lua
   ```

2. (Optional) Create a symlink to use it from anywhere:
   ```bash
   sudo ln -s "$(pwd)/ghostfont.lua" /usr/local/bin/ghostfont
   ```

   Or add this directory to your PATH.

## Usage

Run the font picker:

```bash
./ghostfont.lua
```

Or if you created the symlink:

```bash
ghostfont
```

### Controls

- **↑/↓** - Navigate through fonts (font changes in real-time!)
- **Enter** - Save selected font to Ghostty config
- **Q** or **Esc** - Quit without saving

### Sample Text

The preview includes:
- Pangram ("The quick brown fox...")
- Common terminal commands (`ls`, `grep`, `docker-compose`, `git`)
- SQL query with multiple clauses
- Character comparison samples (0O, iIl1, brackets, operators)

## How It Works

1. Fetches available fonts using `ghostty +list-fonts`
2. Displays an interactive terminal UI with:
   - Scrollable font list on the left
   - Sample text preview on the right
3. **Real-time preview**: As you navigate with arrow keys, the font is applied immediately using Ghostty escape sequences
4. Press Enter to save: Updates your Ghostty config file at:
   - `~/.config/ghostty/config` or
   - `~/.ghostty`

The script automatically creates or updates the `font-family` setting in your config when you press Enter.

## Config Location

The script searches for your Ghostty config in:
1. `~/.config/ghostty/config`
2. `~/.ghostty`

If no config exists, it will create one at `~/.config/ghostty/config`.

## Troubleshooting

**"No fonts found" error:**
- Ensure Ghostty is installed and in your PATH
- Try running `ghostty +list-fonts` manually to verify

**Config not updating:**
- Check file permissions on your Ghostty config
- Verify the config path is correct

**Terminal issues after crash:**
- Run `reset` to restore terminal settings

## Future Enhancements

- [ ] Live font preview (actually render in selected font)
- [ ] Search/filter fonts
- [ ] Favorite fonts
- [ ] Custom sample text
- [ ] NeoVim plugin integration

## License

MIT
