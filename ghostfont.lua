#!/usr/bin/env lua

--[[
Ghostty Font Picker
Interactive terminal font picker for Ghostty terminal emulator
]]

local function execute_command(cmd)
	local handle = io.popen(cmd)
	if not handle then error("blank execution response") end
	local result = handle:read("*a")
	handle:close()
	return result
end

local function get_fonts()
	local fonts = {}
	local output = execute_command("ghostty +list-fonts 2>/dev/null")

	if output == "" then
		-- Fallback: common monospace fonts for testing
		return {
			"JetBrains Mono",
			"Fira Code",
			"Source Code Pro",
			"Hack",
			"Inconsolata",
			"Monaco",
			"Menlo",
			"Consolas",
			"Ubuntu Mono",
			"DejaVu Sans Mono",
		}
	end

	for line in output:gmatch("[^\r\n]+") do
		if line ~= "" then
			table.insert(fonts, line)
		end
	end

	return fonts
end

local function get_terminal_size()
	local handle = io.popen("stty size 2>/dev/null")
    if !handle then return 24, 80 end

	local result = handle:read("*a")
	handle:close()

	local rows, cols = result:match("(%d+)%s+(%d+)")
	return tonumber(rows) or 24, tonumber(cols) or 80
end

local function find_ghostty_config()
	local home = os.getenv("HOME")
	local config_paths = {
		home .. "/.config/ghostty/config",
		home .. "/.ghostty",
	}

	for _, path in ipairs(config_paths) do
		local f = io.open(path, "r")
		if f then
			f:close()
			return path
		end
	end

	return config_paths[1]
end

-- ANSI escape codes
local ESC = string.char(27)
local CSI = ESC .. "["

local function hide_cursor()
	io.write(CSI .. "?25l")
	io.flush()
end

local function show_cursor()
	io.write(CSI .. "?25h")
	io.flush()
end

local function clear_screen()
	io.write(CSI .. "2J")
	io.write(CSI .. "H")
	io.flush()
end

local function move_cursor(row, col)
	io.write(CSI .. row .. ";" .. col .. "H")
	io.flush()
end

local function set_color(fg, bg)
	if bg then
	    io.write(CSI .. fg .. ";" .. bg .. "m")
	else
	    io.write(CSI .. fg .. "m")
	end
end

local function reset_color()
	io.write(CSI .. "0m")
end

-- Apply font in real-time by temporarily updating config and triggering reload
local original_font = nil
local function open_file(config_path, mode)
	local f = io.open(config_path, mode or "r")
	if not f then
		error "dumb"
	end
	return f
end


local function apply_font_preview(font_name)
	local config_path = find_ghostty_config()
	local f = open_file(config_path)

	if not f then
		return -- Can't preview if no config exists
	end

	local lines = {}
	local found_font = false

	-- Save original font on first preview
	if not original_font then
		for line in f:lines() do
			if line:match("^%s*font%-family%s*=") then
				original_font = line:match("font%-family%s*=%s*(.+)$")
				if original_font then
					original_font = original_font:gsub("^%s*(.-)%s*$", "%1") -- trim
				end
			end
		end
		f:close()
		f = open_file(config_path)
	end

	for line in f:lines() do
		if line:match("^%s*font%-family%s*=") then
			table.insert(lines, "font-family = " .. font_name)
			found_font = true
		else
			table.insert(lines, line)
		end
	end
	f:close()

	if not found_font then
		table.insert(lines, "font-family = " .. font_name)
	end

	-- Write temporary config
	f = open_file(config_path, "w")
	if f then
		for _, line in ipairs(lines) do
			f:write(line .. "\n")
		end
		f:close()

		-- Trigger config reload via escape sequence
		-- Send Ctrl+Shift+, keystroke to reload config
		local OSC = ESC .. "]"
		local BEL = string.char(7)
		io.write(OSC .. "1337;ReloadConfig" .. BEL)
		io.flush()
	end
end

-- Terminal raw mode handling
local old_stty_config

local function set_raw_mode()
	old_stty_config = execute_command("stty -g")
	os.execute("stty raw -echo 2>/dev/null")
end

local function restore_terminal()
	if old_stty_config then
		os.execute("stty " .. old_stty_config .. " 2>/dev/null")
	end
	show_cursor()
	reset_color()
	print()
end

local function read_key()
	local char = io.read(1)
	if char == ESC then
		local next1 = io.read(1)
		if next1 == "[" then
			local next2 = io.read(1)
			if next2 == "A" then
				return "up"
			end
			if next2 == "B" then
				return "down"
			end
			if next2 == "C" then
				return "right"
			end
			if next2 == "D" then
				return "left"
			end
		end
		return "escape"
	elseif char == "\n" or char == "\r" then
		return "enter"
	elseif char == "q" or char == "Q" then
		return "quit"
	end
	return char
end

local function get_sample_text()
	return {
		"The quick brown fox jumps over the lazy dog",
		"",
		"$ ls -la /usr/local/bin",
		'$ grep -r "pattern" *.txt',
		"$ docker-compose up -d --build",
		'$ git commit -m "feat: add new feature"',
		"",
		"SELECT users.id, users.name, COUNT(orders.id) AS order_count",
		"FROM users",
		"LEFT JOIN orders ON users.id = orders.user_id",
		"WHERE users.created_at >= '2024-01-01'",
		"GROUP BY users.id, users.name",
		"HAVING COUNT(orders.id) > 5",
		"ORDER BY order_count DESC LIMIT 10;",
		"",
		"0O oO iIl1 `'\"\\ {}[]() <=> := == != >= <=",
	}
end

local function draw_ui(fonts, selected_index, scroll_offset)
	local rows, cols = get_terminal_size()
	clear_screen()

	move_cursor(1, 1)
	set_color(37, 44) -- White on blue
	local title = " Ghostty Font Picker "
	local padding = string.rep(" ", cols - #title)
	io.write(title .. padding)
	reset_color()

	move_cursor(2, 1)
	set_color(90) -- Bright black (gray)
	io.write("↑/↓: Navigate & Preview  Enter: Save to Config  Q/Esc: Quit")
	reset_color()

	local list_width = 35
	local content_start_row = 4
	local visible_rows = rows - content_start_row

	for i = 1, visible_rows do
		local font_index = i + scroll_offset
		if font_index > #fonts then
			break
		end

		local row = content_start_row + i - 1
		move_cursor(row, 2)

		if font_index == selected_index then
			set_color(30, 47) -- Black on white
			io.write("▶ " .. fonts[font_index])
			-- Pad to list width
			local padding_len = list_width - #fonts[font_index] - 2
			if padding_len > 0 then
				io.write(string.rep(" ", padding_len))
			end
			reset_color()
		else
			set_color(37) -- White
			io.write("  " .. fonts[font_index])
			reset_color()
		end
	end

	for i = content_start_row, rows do
		move_cursor(i, list_width + 3)
		set_color(90) -- Gray
		io.write("│")
		reset_color()
	end

	local sample_start_col = list_width + 5
	local sample_texts = get_sample_text()

	move_cursor(content_start_row, sample_start_col)
	set_color(33) -- Yellow
	io.write("Font: " .. fonts[selected_index])
	reset_color()

	move_cursor(content_start_row + 1, sample_start_col)
	set_color(90) -- Gray
	io.write(string.rep("─", cols - sample_start_col - 2))
	reset_color()

	for i, text in ipairs(sample_texts) do
		if content_start_row + 2 + i <= rows then
			move_cursor(content_start_row + 2 + i, sample_start_col)
			set_color(37) -- White
			local max_len = cols - sample_start_col - 2
			if #text > max_len then
				io.write(text:sub(1, max_len))
			else
				io.write(text)
			end
			reset_color()
		end
	end

	io.flush()
end

local function update_ghostty_config(font_name)
	local config_path = find_ghostty_config()
	local f = open_file(config_path)

	if not f then
		local dir = config_path:match("(.+)/[^/]+$")
		os.execute("mkdir -p " .. dir)
		f = open_file(config_path, "w")

		if f then
			f:write("font-family = " .. font_name .. "\n")
			f:close()
			return true, "Created new config with font: " .. font_name
		end
		return false, "Could not create config file"
	end

	local lines = {}
	local font_updated = false

	for line in f:lines() do
		if line:match("^%s*font%-family%s*=") then
			table.insert(lines, "font-family = " .. font_name)
			font_updated = true
		else
			table.insert(lines, line)
		end
	end
	f:close()

	if not font_updated then
		table.insert(lines, "font-family = " .. font_name)
	end

	f = open_file(config_path, "w")
	if not f then
		return false, "Could not write to config file"
	end

	for _, line in ipairs(lines) do
		f:write(line .. "\n")
	end
	f:close()

	return true, "Updated font to: " .. font_name
end

local function main()
	local fonts = get_fonts()

	if #fonts == 0 then
		print("Error: No fonts found. Is Ghostty installed?")
		print("Try running: ghostty +list-fonts")
		return 1
	end

	local selected_index = 1
	local scroll_offset = 0
	local rows = get_terminal_size()
	local visible_rows = rows - 4

	set_raw_mode()
	hide_cursor()

	local function safe_exit(code)
		restore_terminal()
		os.exit(code or 0)
	end

	apply_font_preview(fonts[selected_index])
	draw_ui(fonts, selected_index, scroll_offset)

	while true do
		local key = read_key()
		local prev_index = selected_index

		if key == "up" then
			if selected_index > 1 then
				selected_index = selected_index - 1
				if selected_index < scroll_offset + 1 then
					scroll_offset = selected_index - 1
				end
			end
		elseif key == "down" then
			if selected_index < #fonts then
				selected_index = selected_index + 1
				if selected_index > scroll_offset + visible_rows then
					scroll_offset = selected_index - visible_rows
				end
			end
		elseif key == "enter" then
			local success, message = update_ghostty_config(fonts[selected_index])
			restore_terminal()

			if success then
				print("✓ " .. message)
				print("\nSet to " .. fonts[selected_index])
			else
				print("✗ Error: " .. message)
			end

			return success and 0 or 1
		elseif key == "quit" or key == "escape" then
			if original_font then
				update_ghostty_config(original_font)
			end
			safe_exit(0)
		end

		if selected_index ~= prev_index then
			apply_font_preview(fonts[selected_index])
		end

		draw_ui(fonts, selected_index, scroll_offset)
	end
end

-- Run main with error handling
local status, err = pcall(main)
if not status then
	restore_terminal()
	print("Error: " .. tostring(err))
	os.exit(1)
end
