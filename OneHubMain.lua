-- One Hub - main loader (key system). Loaded by OneHubLoader.lua, which passes the games list.


local DISCORD = "https://discord.gg/yNTHZAJvMd"

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local function notify(text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "One Hub",
			Text = text,
			Duration = duration or 5,
		})
	end)
end

-- the games list comes from OneHubLoader.lua (the readable file), passed in when it loads this one
local GAMES = ...
if type(GAMES) ~= "table" then
	notify("Run the One Hub loader, not this file.", 8)
	return
end



local current
for _, g in ipairs(GAMES) do
	for _, id in ipairs(g.Ids) do
		if game.PlaceId == id then
			current = g
			break
		end
	end
	for _, id in ipairs(g.GameIds or {}) do
		if game.GameId == id then
			current = g
			break
		end
	end
	if current then
		break
	end
end
if not current then
	notify("This script is not supported in this game")
	return
end


local KEY_FILE = "OneHub/key_" .. (current.Url:match("loaders/(%w+)") or "main") .. ".txt"

local function looksLikeKey(k)
	return type(k) == "string" and #k >= 20 and #k <= 64 and k:match("^%w+$") ~= nil
end
local function clean(k)
	if type(k) == "table" then
		k = k[current.Name]
	end
	k = k and tostring(k) or ""
	local inQuotes = k:match("script_key%s*=%s*[\"']([^\"']+)[\"']")
	if inQuotes then
		k = inQuotes
	end
	k = k:gsub("%s+", ""):gsub("[\"'`]", "")
	if looksLikeKey(k) then
		return k
	end
	local best
	for w in k:gmatch("%w+") do
		if looksLikeKey(w) and not w:lower():find("http") and (not best or #w > #best) then
			best = w
		end
	end
	return best
end

local function pastedKey()
	local k
	pcall(function()
		k = (getgenv and getgenv().script_key) or script_key
	end)
	return clean(k)
end

local function forgetKey()
	pcall(function()
		if isfile and isfile(KEY_FILE) then
			if delfile then
				delfile(KEY_FILE)
			else
				writefile(KEY_FILE, "")
			end
		end
	end)
end

local function savedKey()
	local k
	pcall(function()
		if isfile and isfile(KEY_FILE) then
			k = readfile(KEY_FILE)
		end
	end)
	local c = clean(k)
	if k and k ~= "" and not c then
		forgetKey() -- a broken saved key would get you kicked every time
	end
	return c
end

local function saveKey(k)
	pcall(function()
		if makefolder and not (isfolder and isfolder("OneHub")) then
			makefolder("OneHub")
		end
		writefile(KEY_FILE, k)
	end)
end


local luarmor
local function checkKey(k)
	if not looksLikeKey(k) then
		return false, "That's not a key. Paste only the key from our Discord.", true
	end
	if not luarmor then
		pcall(function()
			luarmor = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
			luarmor.script_id = current.Url:match("loaders/(%w+)")
		end)
	end
	if not luarmor then
		return false, "Could not check the key, try again.", false
	end
	local ok, res, finished = nil, nil, false
	task.spawn(function()
		ok, res = pcall(luarmor.check_key, k)
		finished = true
	end)
	local t0 = os.clock()
	while not finished and os.clock() - t0 < 15 do
		task.wait(0.1)
	end
	if not finished then
		return false, "Key check timed out (Luarmor is slow). Try again.", false
	end
	if not ok or type(res) ~= "table" then
		return false, "Could not check the key, try again.", false
	end
	local code = res.code
	if code == "KEY_VALID" then
		return true
	elseif code == "KEY_HWID_LOCKED" then
		return false, "This key is locked to another device. In our Discord click Reset HWID and paste this key."
	elseif code == "KEY_EXPIRED" then
		return false, "This key has expired. Get a new one in our Discord."
	elseif code == "KEY_BANNED" then
		return false, "This key is banned."
	elseif code == "KEY_INCORRECT" or code == "KEY_INVALID" then
		return false, "Wrong key. Get yours for free in our Discord."
	end
	return false, tostring(res.message or code or "Could not check the key, try again."), false
end


local function joinDiscord()
	pcall(setclipboard, DISCORD)
	local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
	if req then
		task.spawn(pcall, req, {
			Url = "http://127.0.0.1:6463/rpc?v=1",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
			Body = HttpService:JSONEncode({
				cmd = "INVITE_BROWSER",
				nonce = HttpService:GenerateGUID(false),
				args = { code = "yNTHZAJvMd" },
			}),
		})
	end
end


local function keyWindow(firstMessage)
	local result
	local resultVerified = false
	local gui = Instance.new("ScreenGui")
	gui.Name = "OneHubKey"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999
	local okParent = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not okParent or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	-- same look as the hub (Graphite). Plain frames only (no CanvasGroup / blur): cheap on low-end phones.
	local C = {
		Back = Color3.fromHex("#111114"),
		Card = Color3.fromHex("#18181c"),
		Field = Color3.fromHex("#121215"),
		Line = Color3.fromHex("#26262c"),
		Text = Color3.fromHex("#ededf0"),
		Muted = Color3.fromHex("#8b8b97"),
		Accent = Color3.fromHex("#7c3aed"),
		AccentHi = Color3.fromHex("#8b5cf6"),
		Good = Color3.fromHex("#4ade80"),
		Bad = Color3.fromHex("#f87171"),
	}
	local function corner(p, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r)
		c.Parent = p
	end
	local function outline(p, color)
		local st = Instance.new("UIStroke")
		st.Color = color or C.Line
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = p
		return st
	end
	local function label(parent, text, size, color, font, x, y, w, h)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextSize = size
		l.TextColor3 = color
		l.Font = font
		l.TextWrapped = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top
		l.Size = UDim2.new(0, w, 0, h)
		l.Position = UDim2.new(0, x, 0, y)
		l.Parent = parent
		return l
	end

	-- which layout: PC, phone sideways (two columns) or phone upright (one column, big buttons)
	local vp = Vector2.new(1280, 720)
	pcall(function()
		vp = workspace.CurrentCamera.ViewportSize
	end)
	-- phones and tablets (iOS / Android, or a touch screen without a mouse, or a small one)
	local UIS = game:GetService("UserInputService")
	local phone = false
	pcall(function()
		local pf = UIS:GetPlatform()
		phone = pf == Enum.Platform.IOS or pf == Enum.Platform.Android
	end)
	phone = phone or (UIS.TouchEnabled and (not UIS.MouseEnabled or math.min(vp.X, vp.Y) < 600))
	local mode = not phone and "pc" or (vp.X >= vp.Y and "wide" or "tall")
	local W, H
	if mode == "pc" then
		W, H = 420, 370
	elseif mode == "wide" then
		W, H = math.floor(math.clamp(vp.X - 40, 420, 640)), 246
	else
		W, H = math.floor(math.clamp(vp.X - 24, 280, 440)), 452
	end

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Parent = gui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.53)
	card.Size = UDim2.new(0, W, 0, H)
	card.BackgroundColor3 = C.Back
	card.Active = true
	card.Parent = gui
	corner(card, 14)
	outline(card, C.Line)
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local fit = math.min(1, (vp.X - 16) / W, (vp.Y - 16) / H)
	scale.Scale = fit * 0.96

	-- header: logo, hub name, game, close
	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(0, 30, 0, 30)
	logo.Position = UDim2.new(0, 16, 0, 13)
	logo.BackgroundColor3 = C.Accent
	logo.Image = "rbxassetid://100519548765315"
	logo.Parent = card
	corner(logo, 8)
	label(card, "One Hub", 15, C.Text, Enum.Font.GothamBold, 56, 13, W - 120, 18)
	label(card, current.Name, 12, C.Muted, Enum.Font.GothamMedium, 56, 31, W - 120, 14)

	local close = Instance.new("TextButton")
	local cs = phone and 40 or 30
	close.Size = UDim2.new(0, cs, 0, cs)
	close.Position = UDim2.new(1, -cs - 10, 0, (56 - cs) / 2)
	close.BackgroundColor3 = C.Text
	close.BackgroundTransparency = 1
	close.AutoButtonColor = false
	close.Text = "✕"
	close.TextColor3 = C.Muted
	close.Font = Enum.Font.GothamBold
	close.TextSize = 14
	close.Parent = card
	corner(close, 8)

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 0, 56)
	line.BackgroundColor3 = C.Line
	line.BorderSizePixel = 0
	line.Parent = card

	-- left part (or top): what to do
	local colW = mode == "wide" and math.floor((W - 60) / 2) or (W - 40)
	label(card, "Free key needed", 15, C.Text, Enum.Font.GothamBold, 20, 72, colW, 20)
	label(card, mode == "pc" and "Takes a minute, and you only do it once on this device." or "Takes a minute, once per device.", 12, C.Muted, Enum.Font.GothamMedium, 20, 94, colW, 16)
	local steps = {
		"Join our Discord",
		"Pick " .. current.Name .. " in the script channel",
		"Paste your key " .. (mode == "wide" and "here" or "below"),
	}
	for i, t in steps do
		local y = 122 + (i - 1) * 26
		local dot = Instance.new("TextLabel")
		dot.Size = UDim2.new(0, 20, 0, 20)
		dot.Position = UDim2.new(0, 20, 0, y)
		dot.BackgroundColor3 = C.Accent
		dot.BackgroundTransparency = 0.8
		dot.Text = tostring(i)
		dot.TextColor3 = Color3.fromHex("#c4b5fd")
		dot.Font = Enum.Font.GothamBold
		dot.TextSize = 11
		dot.Parent = card
		corner(dot, 10)
		local l = label(card, t, 13, Color3.fromHex("#d4d4da"), Enum.Font.GothamMedium, 50, y + 3, colW - 30, 16)
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.TextWrapped = false
	end

	-- right part (or bottom): key box, message, buttons
	local fx, fy, fw = 20, 208, W - 40
	if mode == "wide" then
		fx, fy, fw = 40 + colW, 72, colW
	end
	local fh = phone and 46 or 40
	local field = Instance.new("Frame")
	field.Size = UDim2.new(0, fw, 0, fh)
	field.Position = UDim2.new(0, fx, 0, fy)
	field.BackgroundColor3 = C.Field
	field.Parent = card
	corner(field, 9)
	local fStroke = outline(field, C.Line)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -24, 1, 0)
	box.Position = UDim2.new(0, 12, 0, 0)
	box.BackgroundTransparency = 1
	box.TextColor3 = C.Text
	box.PlaceholderText = "Paste your key here"
	box.PlaceholderColor3 = Color3.fromHex("#5c5c66")
	box.Font = Enum.Font.Code
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.ClearTextOnFocus = false
	box.Text = ""
	box.Parent = field
	box.Focused:Connect(function()
		fStroke.Color = C.Accent
	end)
	box.FocusLost:Connect(function()
		fStroke.Color = C.Line
	end)

	local status = label(card, firstMessage or "", 12, C.Bad, Enum.Font.GothamMedium, fx, fy + fh + 6, fw, 30)

	local bh = phone and 46 or 40
	local function button(text, primary, i)
		local b = Instance.new("TextButton")
		if mode == "tall" then
			-- one under the other, full width (easy to hit with a thumb)
			b.Size = UDim2.new(0, fw, 0, bh)
			b.Position = UDim2.new(0, fx, 0, fy + fh + 40 + (primary and 0 or bh + 8))
		else
			local half = math.floor((fw - 10) / 2)
			b.Size = UDim2.new(0, half, 0, bh)
			b.Position = UDim2.new(0, fx + (primary and half + 10 or 0), 0, fy + fh + 40)
		end
		b.BackgroundColor3 = primary and C.Accent or C.Card
		b.AutoButtonColor = false
		b.Text = text
		b.TextColor3 = primary and Color3.new(1, 1, 1) or C.Text
		b.Font = Enum.Font.GothamBold
		b.TextSize = phone and 15 or 14
		b.Parent = card
		corner(b, 9)
		if not primary then
			outline(b, C.Line)
		end
		if not phone then
			local base = b.BackgroundColor3
			local hover = primary and C.AccentHi or Color3.fromHex("#202026")
			b.MouseEnter:Connect(function()
				b.BackgroundColor3 = hover
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundColor3 = base
			end)
		end
		return b
	end
	local join = button("Join Discord", false)
	local check = button("Check Key", true)
	local footY = mode == "tall" and (fy + fh + 40 + bh * 2 + 8 + 12) or (fy + fh + 40 + bh + 12)
	local foot = label(card, (DISCORD:gsub("^https://", "")), 11, Color3.fromHex("#5c5c66"), Enum.Font.Code, fx, footY, fw, 14)
	foot.TextXAlignment = Enum.TextXAlignment.Center

	if not phone then
		close.MouseEnter:Connect(function()
			close.BackgroundTransparency = 0.93
			close.TextColor3 = C.Text
		end)
		close.MouseLeave:Connect(function()
			close.BackgroundTransparency = 1
			close.TextColor3 = C.Muted
		end)
	end

	-- open: slides up a little and grows to size (two cheap tweens)
	local open = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(card, open, { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	TweenService:Create(scale, open, { Scale = fit }):Play()

	local function setStatus(t, good)
		status.Text = t
		status.TextColor3 = good and C.Good or C.Bad
	end

	join.MouseButton1Click:Connect(function()
		joinDiscord()
		setStatus("Discord link copied! It should open in your Discord app.", true)
	end)

	local busy = false
	local unsure = 0
	check.MouseButton1Click:Connect(function()
		if busy then
			return
		end
		local k = clean(box.Text)
		if not k then
			return setStatus("Paste your key first. Get it for free in our Discord.")
		end
		busy = true
		check.Text = "Checking..."
		local ok, why, sure = checkKey(k)
		busy = false
		check.Text = "Check Key"
		resultVerified = ok
		-- Luarmor can't be reached: after a few tries, a key that looks right is let through
		if not ok and sure == false then
			unsure += 1
			if unsure >= 3 then
				ok = true
			end
		end
		if ok then
			box.Text = k
			setStatus("Key accepted! Loading...", true)
			result = k
		else
			setStatus(why)
		end
	end)

	close.MouseButton1Click:Connect(function()
		result = false
	end)

	while result == nil and gui.Parent do
		task.wait(0.1)
	end
	if result then
		task.wait(0.4)
	end
	gui:Destroy()
	if not result then
		return nil, false
	end
	return result, resultVerified
end


if current.Key then
	-- A key is only saved once Luarmor says it's valid. A pasted or saved key that Luarmor
	-- rejects (expired, wrong, banned, other device) is thrown away at once, so it can never
	-- get stuck and keep failing to load.
	local function dropPasted()
		pcall(function()
			script_key = nil
			if getgenv then
				getgenv().script_key = nil
			end
		end)
	end
	local key, why, unchecked = nil, nil, nil
	local pasted = pastedKey()
	if pasted then
		local ok, w, sure = checkKey(pasted)
		if ok then
			key = pasted
		elseif sure == false then
			unchecked = pasted
		else
			why = w
			dropPasted()
		end
	end
	if not key then
		local saved = savedKey()
		if saved then
			local ok, w, sure = checkKey(saved)
			if ok then
				key = saved
			elseif sure == false then
				unchecked = unchecked or saved
			else
				forgetKey()
				why = why or w
			end
		end
	end
	local verified = key ~= nil
	local keepSaved = false
	if not key and unchecked and not why then
		-- Luarmor didn't answer (often right after a teleport): use the key anyway, the script checks it
		-- itself. No window, so re-executing after a teleport doesn't wait for a click.
		key = unchecked
		keepSaved = true
	end
	if not key then
		key, verified = keyWindow(why or (unchecked and "Could not check your key. Try again." or nil))
	end
	if not key then
		dropPasted()
		pcall(setclipboard, DISCORD)
		notify("Join our Discord (link copied) to get your free key.", 8)
		return
	end
	if verified then
		saveKey(key)
	elseif keepSaved then
		-- (couldn't be checked right now: keep the saved key for next time)
	else
		-- (Luarmor couldn't be reached: this key is tried once, never saved)
		forgetKey()
	end
	script_key = key
	pcall(function()
		getgenv().script_key = key
	end)
end


local src
for _ = 1, 3 do
	local ok, res = pcall(function()
		return game:HttpGet(current.Url)
	end)
	if ok and type(res) == "string" and #res > 50 then
		src = res
		break
	end
	task.wait(2)
end
if not src then
	notify("Could not download the " .. current.Name .. " script. Try again.")
	return
end

local fn, err = loadstring(src)
if not fn then
	-- what the server sent instead of a script (Luarmor puts its reason there)
	local said = src:gsub("<[^>]*>", " "):gsub("%s+", " "):sub(1, 140)
	pcall(setclipboard, said)
	notify("The " .. current.Name .. " script failed to load. Server said: " .. said, 15)
	return
end
-- an error while the script starts is shown (and copied) instead of failing silently
task.spawn(function()
	local ok, e = xpcall(fn, function(m)
		return tostring(m) .. "\n" .. debug.traceback()
	end)
	if not ok then
		warn("[One Hub] " .. current.Name .. ": " .. tostring(e))
		pcall(setclipboard, tostring(e))
		notify(current.Name .. " script error (copied): " .. tostring(e):sub(1, 120), 15)
	end
end)
