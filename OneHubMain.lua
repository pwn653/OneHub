


local DISCORD = "https://discord.gg/yNTHZAJvMd"
local PREMIUM_URL = "https://onehub-script.mysellauth.com/product/one-hub-7-days-key-premium"
local PREMIUM_PRICE = "" 
local PAYMENT_METHODS = {
	{ Badge = "PP", Name = "PayPal" },
	{ Badge = "CC", Name = "Credit / debit card" },
	{ Badge = "BTC", Name = "Crypto" },
}

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
		forgetKey()
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

	local C = {
		Back = Color3.fromHex("#111114"),
		Head = Color3.fromHex("#1f1f24"),
		Card = Color3.fromHex("#16161a"),
		Field = Color3.fromHex("#0d0d10"),
		Line = Color3.fromHex("#222228"),
		Edge = Color3.fromHex("#26262c"),
		Text = Color3.fromHex("#ededf0"),
		Soft = Color3.fromHex("#d4d4da"),
		Muted = Color3.fromHex("#9a9aa6"),
		Dim = Color3.fromHex("#8b8b97"),
		Accent = Color3.fromHex("#7c3aed"),
		AccentHi = Color3.fromHex("#8b5cf6"),
		Grey = Color3.fromHex("#2a2a31"),
		GreyHi = Color3.fromHex("#33333b"),
		Second = Color3.fromHex("#18181c"),
		Purple = Color3.fromHex("#4c1d95"),
		Lilac = Color3.fromHex("#ddd6fe"),
		Chip = Color3.fromHex("#2a2140"),
		ChipText = Color3.fromHex("#c4b5fd"),
		Good = Color3.fromHex("#4ade80"),
		Bad = Color3.fromHex("#f87171"),
	}
	local function font(weight)
		local ok, f = pcall(Font.new, "rbxasset://fonts/families/BuilderSans.json", weight)
		return ok and f or nil
	end
	local F = {
		Regular = font(Enum.FontWeight.Regular),
		Medium = font(Enum.FontWeight.Medium),
		Semi = font(Enum.FontWeight.SemiBold),
		Bold = font(Enum.FontWeight.Bold),
	}
	local function setFont(o, weight)
		if F[weight] then
			o.FontFace = F[weight]
		else
			o.Font = (weight == "Bold" or weight == "Semi") and Enum.Font.GothamBold or Enum.Font.GothamMedium
		end
	end
	local function corner(p, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r)
		c.Parent = p
	end
	local function outline(p, color)
		local st = Instance.new("UIStroke")
		st.Color = color or C.Edge
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = p
		return st
	end
	local function frame(parent, color, x, y, w, h, r)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.Position = UDim2.new(0, x, 0, y)
		f.Size = UDim2.new(0, w, 0, h)
		f.Parent = parent
		if r then
			corner(f, r)
		end
		return f
	end
	local function label(parent, text, size, color, weight, x, y, w, h)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextSize = size
		l.TextColor3 = color
		setFont(l, weight)
		l.TextWrapped = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.Size = UDim2.new(0, w, 0, h)
		l.Position = UDim2.new(0, x, 0, y)
		l.Parent = parent
		return l
	end

	local vp = Vector2.new(1280, 720)
	pcall(function()
		vp = workspace.CurrentCamera.ViewportSize
	end)
	local UIS = game:GetService("UserInputService")
	local phone = false
	pcall(function()
		local pf = UIS:GetPlatform()
		phone = pf == Enum.Platform.IOS or pf == Enum.Platform.Android
	end)
	phone = phone or (UIS.TouchEnabled and (not UIS.MouseEnabled or math.min(vp.X, vp.Y) < 600))
	local mode = not phone and "pc" or (vp.X >= vp.Y and "wide" or "tall")
	local bh = phone and 46 or 44
	local W, H
	if mode == "pc" then
		W, H = 440, 520
	elseif mode == "wide" then
		W, H = math.floor(math.clamp(vp.X - 40, 520, 680)), 330
	else
		W, H = math.floor(math.clamp(vp.X - 24, 300, 440)), 530
	end
	local P = 22 

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
	card.ClipsDescendants = true
	card.Parent = gui
	corner(card, 16)
	outline(card, C.Edge)
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local fit = math.min(1, (vp.X - 16) / W, (vp.Y - 16) / H)
	scale.Scale = fit * 0.96

	local function hoverize(b, base, hover)
		if phone then
			return
		end
		b.MouseEnter:Connect(function()
			b.BackgroundColor3 = hover
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundColor3 = base
		end)
	end
	local function button(parent, text, kind, x, y, w, h)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, w, 0, h or bh)
		b.Position = UDim2.new(0, x, 0, y)
		b.AutoButtonColor = false
		b.Text = text
		b.TextSize = phone and 15 or 14
		setFont(b, "Semi")
		local base, hover
		if kind == "primary" then
			base, hover = C.Accent, C.AccentHi
			b.TextColor3 = Color3.new(1, 1, 1)
		elseif kind == "grey" then
			base, hover = C.Grey, C.GreyHi
			b.TextColor3 = C.Soft
		else
			base, hover = C.Second, Color3.fromHex("#202026")
			b.TextColor3 = C.Text
			outline(b, Color3.fromHex("#2f2f37"))
		end
		b.BackgroundColor3 = base
		b.Parent = parent
		corner(b, 10)
		hoverize(b, base, hover)
		return b
	end
	local function iconButton(parent, text, x)
		local s = phone and 40 or 32
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, s, 0, s)
		b.Position = UDim2.new(0, x, 0, (60 - s) / 2)
		b.BackgroundColor3 = C.Text
		b.BackgroundTransparency = 1
		b.AutoButtonColor = false
		b.Text = text
		b.TextColor3 = C.Dim
		b.TextSize = 15
		setFont(b, "Bold")
		b.Parent = parent
		corner(b, 8)
		if not phone then
			b.MouseEnter:Connect(function()
				b.BackgroundTransparency = 0.93
				b.TextColor3 = C.Text
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundTransparency = 1
				b.TextColor3 = C.Dim
			end)
		end
		return b, s
	end
	local function page()
		local p = Instance.new("Frame")
		p.BackgroundTransparency = 1
		p.Size = UDim2.fromScale(1, 1)
		p.Parent = card
		return p
	end
	local function header(p, title, sub, withBack)
		frame(p, C.Head, 0, 59, W, 1)
		local x = 18
		local back
		if withBack then
			back = iconButton(p, "‹", 10)
			back.TextSize = 24
			x = 10 + (phone and 40 or 32) + 8
		else
			local logo = Instance.new("ImageLabel")
			logo.Size = UDim2.new(0, 32, 0, 32)
			logo.Position = UDim2.new(0, 18, 0, 14)
			logo.BackgroundColor3 = C.Accent
			logo.BorderSizePixel = 0
			logo.Image = "rbxassetid://100519548765315"
			logo.Parent = p
			corner(logo, 9)
			x = 62
		end
		if sub then
			label(p, title, 14, C.Text, "Semi", x, 12, W - x - 60, 18)
			label(p, sub, 12, C.Dim, "Medium", x, 30, W - x - 60, 16)
		else
			label(p, title, 14, C.Text, "Semi", x, 20, W - x - 60, 20)
		end
		local cs = phone and 40 or 32
		local close = iconButton(p, "✕", W - cs - 12)
		close.MouseButton1Click:Connect(function()
			result = false
		end)
		return back
	end

	local keyPage = page()
	header(keyPage, "One Hub", current.Name, false)
	local wide = mode == "wide"
	local colW = wide and math.floor((W - P * 2 - 20) / 2) or (W - P * 2)
	local lx, rx = P, wide and (P + colW + 20) or P
	local y = 82
	label(keyPage, "Get your free key", 20, C.Text, "Bold", lx, y, colW, 24)
	label(keyPage, mode == "pc" and "Takes a minute. You only do it once on this device." or "Takes a minute, once per device.", 13, C.Muted, "Medium", lx, y + 28, colW, 18)
	local steps = frame(keyPage, C.Card, lx, y + 58, colW, 122, 12)
	outline(steps, C.Line)
	local texts = {
		"Join our Discord",
		"Pick " .. current.Name .. " in the script channel",
		"Paste your key " .. (wide and "here" or "below"),
	}
	for i, t in texts do
		local sy = (i - 1) * 41
		if i > 1 then
			frame(steps, C.Line, 46, sy, colW - 46, 1)
		end
		local dot = Instance.new("TextLabel")
		dot.Size = UDim2.new(0, 20, 0, 20)
		dot.Position = UDim2.new(0, 14, 0, sy + 10)
		dot.BackgroundColor3 = C.Chip
		dot.BorderSizePixel = 0
		dot.Text = tostring(i)
		dot.TextColor3 = C.ChipText
		dot.TextSize = 11
		setFont(dot, "Bold")
		dot.Parent = steps
		corner(dot, 10)
		local l = label(steps, t, 13, C.Soft, "Medium", 46, sy, colW - 58, 40)
		l.TextWrapped = false
		l.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local ky = wide and 82 or (y + 58 + 122 + 18)
	label(keyPage, "Key", 12, C.Muted, "Medium", rx, ky, colW, 16)
	local fh = phone and 46 or 44
	local field = frame(keyPage, C.Field, rx, ky + 22, colW, fh, 10)
	local fStroke = outline(field, Color3.fromHex("#2a2a31"))
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
		fStroke.Color = Color3.fromHex("#2a2a31")
	end)
	local sy = ky + 22 + fh + 6
	local status = label(keyPage, firstMessage or "", 12, C.Bad, "Medium", rx, sy, colW, 16)
	status.TextTruncate = Enum.TextTruncate.AtEnd
	status.TextWrapped = false
	local by = sy + 22
	local half = math.floor((colW - 10) / 2)
	local join = button(keyPage, "Join Discord", "second", rx, by, half)
	local check = button(keyPage, "Check Key", "primary", rx + half + 10, by, colW - half - 10)
	local dy = by + bh + 14
	frame(keyPage, C.Line, rx, dy + 7, colW, 1)
	local orText = label(keyPage, "  or skip the key with Premium  ", 11, C.Dim, "Medium", rx, dy, colW, 14)
	orText.TextXAlignment = Enum.TextXAlignment.Center
	orText.AutomaticSize = Enum.AutomaticSize.None
	local orBack = frame(keyPage, C.Back, rx + math.floor(colW / 2) - 92, dy, 184, 14)
	orBack.ZIndex = 1
	orText.ZIndex = 2
	local skip = button(keyPage, "Skip", "grey", rx, dy + 26, colW)

	local premPage = page()
	premPage.Visible = false
	local back = header(premPage, "One Hub Premium", nil, true)
	local py = 80
	local pw = wide and colW or (W - P * 2)
	local banner = frame(premPage, C.Purple, P, py, pw, 78, 12)
	banner.ClipsDescendants = true
	local ring = frame(banner, Color3.new(0, 0, 0), pw - 120, -60, 170, 170)
	ring.BackgroundTransparency = 1
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
	outline(ring, Color3.fromHex("#6d3fc4"))
	local emblem = frame(banner, C.Accent, 16, 17, 44, 44, 12)
	outline(emblem, Color3.fromHex("#a78bfa"))
	local crown = Instance.new("ImageLabel")
	crown.BackgroundTransparency = 1
	crown.Image = "rbxassetid://127843403295538"
	crown.ImageColor3 = Color3.new(1, 1, 1)
	crown.AnchorPoint = Vector2.new(0.5, 0.5)
	crown.Position = UDim2.fromScale(0.5, 0.5)
	crown.Size = UDim2.new(0, 22, 0, 22)
	crown.Parent = emblem
	local priceW = PREMIUM_PRICE ~= "" and 70 or 0
	label(banner, "No key, every game", 16, Color3.new(1, 1, 1), "Bold", 74, 18, pw - 74 - 16 - priceW, 20)
	local sub = label(banner, "Skip key checkpoints and get new features first.", 12, C.Lilac, "Medium", 74, 40, pw - 74 - 16 - priceW, 28)
	sub.TextYAlignment = Enum.TextYAlignment.Top
	if PREMIUM_PRICE ~= "" then
		local pr = label(banner, PREMIUM_PRICE, 18, Color3.new(1, 1, 1), "Bold", pw - 16 - priceW, 20, priceW, 22)
		pr.TextXAlignment = Enum.TextXAlignment.Right
		local per = label(banner, "7 days", 11, C.Lilac, "Medium", pw - 16 - priceW, 42, priceW, 14)
		per.TextXAlignment = Enum.TextXAlignment.Right
	end
	local mx = wide and (P + colW + 20) or P
	local my = wide and 80 or (py + 78 + 16)
	label(premPage, "Pay with", 12, C.Muted, "Medium", mx, my, pw, 16)
	local list = frame(premPage, C.Card, mx, my + 22, pw, #PAYMENT_METHODS * 48, 12)
	outline(list, C.Line)
	local premStatus
	local function copyStore(how)
		pcall(setclipboard, PREMIUM_URL)
		premStatus.Text = "Store link copied. Open it in your browser" .. (how and (" and pick " .. how) or "") .. "."
		premStatus.TextColor3 = C.Good
	end
	for i, m in PAYMENT_METHODS do
		local ry = (i - 1) * 48
		if i > 1 then
			frame(list, C.Line, 0, ry, pw, 1)
		end
		local row = Instance.new("TextButton")
		row.BackgroundColor3 = C.Card
		row.BackgroundTransparency = 1
		row.AutoButtonColor = false
		row.Text = ""
		row.Size = UDim2.new(1, 0, 0, 48)
		row.Position = UDim2.new(0, 0, 0, ry)
		row.Parent = list
		local badge = label(row, m.Badge, 11, Color3.fromHex("#c8c8d0"), "Bold", 14, 9, 30, 30)
		badge.BackgroundTransparency = 0
		badge.BackgroundColor3 = Color3.fromHex("#222228")
		badge.TextXAlignment = Enum.TextXAlignment.Center
		corner(badge, 8)
		label(row, m.Name, 13, C.Text, "Semi", 56, 0, pw - 90, 48)
		local arrow = label(row, "›", 18, Color3.fromHex("#6b6b76"), "Medium", pw - 28, 0, 14, 48)
		arrow.TextXAlignment = Enum.TextXAlignment.Center
		row.MouseButton1Click:Connect(function()
			copyStore(m.Name)
		end)
		if not phone then
			row.MouseEnter:Connect(function()
				row.BackgroundTransparency = 0
				row.BackgroundColor3 = Color3.fromHex("#1c1c21")
			end)
			row.MouseLeave:Connect(function()
				row.BackgroundTransparency = 1
			end)
		end
	end
	local cy = my + 22 + #PAYMENT_METHODS * 48 + 16
	local copyBtn = button(premPage, "Copy store link", "primary", mx, cy, pw)
	premStatus = label(premPage, "Open it in your browser to pay. Your key arrives right after.", 11, C.Dim, "Medium", wide and P or mx, wide and (py + 78 + 14) or (cy + bh + 8), pw, wide and 30 or 16)
	premStatus.TextXAlignment = wide and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
	copyBtn.MouseButton1Click:Connect(function()
		copyStore(nil)
	end)

	skip.MouseButton1Click:Connect(function()
		keyPage.Visible = false
		premPage.Visible = true
	end)
	back.MouseButton1Click:Connect(function()
		premPage.Visible = false
		keyPage.Visible = true
	end)

	local open = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(card, open, { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	TweenService:Create(scale, open, { Scale = fit }):Play()

	local function setStatus(t, good)
		status.Text = t
		status.TextColor3 = good and C.Good or C.Bad
		fStroke.Color = (t ~= "" and not good) and Color3.fromHex("#7f2d2d") or Color3.fromHex("#2a2a31")
	end
	if firstMessage then
		setStatus(firstMessage)
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
	else
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
	local said = src:gsub("<[^>]*>", " "):gsub("%s+", " "):sub(1, 140)
	pcall(setclipboard, said)
	notify("The " .. current.Name .. " script failed to load. Server said: " .. said, 15)
	return
end
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
