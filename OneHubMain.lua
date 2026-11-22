

local DISCORD = "https://discord.gg/yNTHZAJvMd"
local PREMIUM_URL = "https://onehub-script.mysellauth.com/product/one-hub-7-days-key-premium"
local PREMIUM_PRICE = "$1.49" 
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

	local hex = Color3.fromHex
	local ICON = {
		x = "rbxassetid://110786993356448",
		key = "rbxassetid://96510194465420",
		message = "rbxassetid://83881670383280",
		arrowRight = "rbxassetid://113692007244654",
		arrowLeft = "rbxassetid://102531941843733",
		chevron = "rbxassetid://92473583511724",
		crown = "rbxassetid://127843403295538",
	}
	local function font(weight)
		local ok, f = pcall(Font.new, "rbxasset://fonts/families/BuilderSans.json", weight)
		return ok and f or nil
	end
	local FONT = {
		Medium = font(Enum.FontWeight.Medium),
		Semi = font(Enum.FontWeight.SemiBold),
		Bold = font(Enum.FontWeight.Bold),
	}
	local function setFont(o, weight)
		if FONT[weight] then
			o.FontFace = FONT[weight]
		else
			o.Font = weight == "Medium" and Enum.Font.GothamMedium or Enum.Font.GothamBold
		end
	end
	local function corner(p, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = r == "full" and UDim.new(1, 0) or UDim.new(0, r)
		c.Parent = p
	end
	local function stroke(p, color)
		local st = Instance.new("UIStroke")
		st.Color = hex(color)
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = p
		return st
	end
	local function box(parent, color, x, y, w, h, r, line)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		if color then
			f.BackgroundColor3 = hex(color)
		else
			f.BackgroundTransparency = 1
		end
		f.Position = UDim2.new(0, x, 0, y)
		f.Size = UDim2.new(0, w, 0, h)
		f.Parent = parent
		if r then
			corner(f, r)
		end
		if line then
			stroke(f, line)
		end
		return f
	end
	local function text(parent, t, size, color, weight, x, y, w, h, align)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Text = t
		l.TextSize = size
		l.TextColor3 = hex(color)
		setFont(l, weight)
		l.TextXAlignment = align or Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Position = UDim2.new(0, x, 0, y)
		l.Size = UDim2.new(0, w, 0, h)
		l.Parent = parent
		return l
	end
	local function icon(parent, id, size, color, x, y)
		local i = Instance.new("ImageLabel")
		i.BackgroundTransparency = 1
		i.Image = id
		i.ImageColor3 = hex(color)
		i.Size = UDim2.new(0, size, 0, size)
		i.Position = UDim2.new(0, x or 0, 0, y or 0)
		i.Parent = parent
		return i
	end
	local function centredRow(parent, gap)
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.fromScale(1, 1)
		row.Parent = parent
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Padding = UDim.new(0, gap)
		l.Parent = row
		return row
	end
	local function rowText(row, t, size, color, weight, order)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AutomaticSize = Enum.AutomaticSize.X
		l.Size = UDim2.new(0, 0, 0, size + 6)
		l.Text = t
		l.TextSize = size
		l.TextColor3 = hex(color)
		setFont(l, weight)
		l.LayoutOrder = order
		l.Parent = row
		return l
	end
	local function rowIcon(row, id, size, color, order)
		local i = icon(row, id, size, color)
		i.LayoutOrder = order
		return i
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

	local W = 440
	local KEY_H, PREM_H = 544, 0

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Parent = gui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.53)
	card.Size = UDim2.new(0, W, 0, KEY_H)
	card.BackgroundColor3 = hex("#111114")
	card.BorderSizePixel = 0
	card.Active = true
	card.ClipsDescendants = true
	card.Parent = gui
	corner(card, 16)
	stroke(card, "#26262c")
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local function fitFor(h)
		return math.min(1, (vp.X - 16) / W, (vp.Y - 16) / h)
	end
	scale.Scale = fitFor(KEY_H) * 0.96

	local function hover(b, base, over)
		if phone then
			return
		end
		b.MouseEnter:Connect(function()
			b.BackgroundColor3 = hex(over)
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundColor3 = hex(base)
		end)
	end
	local function plainButton(parent, x, y, w, h, color, r, line)
		local b = Instance.new("TextButton")
		b.AutoButtonColor = false
		b.Text = ""
		b.BorderSizePixel = 0
		b.Position = UDim2.new(0, x, 0, y)
		b.Size = UDim2.new(0, w, 0, h)
		if color then
			b.BackgroundColor3 = hex(color)
		else
			b.BackgroundTransparency = 1
		end
		b.Parent = parent
		if r then
			corner(b, r)
		end
		if line then
			stroke(b, line)
		end
		return b
	end
	local function headerButton(parent, x, id, color)
		local b = plainButton(parent, x, 14, 32, 32, nil, 8)
		b.BackgroundColor3 = hex("#ededf0")
		local i = icon(b, id, id == ICON.x and 14 or 16, color)
		i.AnchorPoint = Vector2.new(0.5, 0.5)
		i.Position = UDim2.fromScale(0.5, 0.5)
		if not phone then
			b.MouseEnter:Connect(function()
				b.BackgroundTransparency = 0.93
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundTransparency = 1
			end)
		end
		b.MouseButton1Click:Connect(function()
			if id == ICON.x then
				result = false
			end
		end)
		return b
	end
	local function page()
		local p = Instance.new("Frame")
		p.BackgroundTransparency = 1
		p.Size = UDim2.fromScale(1, 1)
		p.Parent = card
		return p
	end

	local keyPage = page()
	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(0, 32, 0, 32)
	logo.Position = UDim2.new(0, 18, 0, 14)
	logo.BackgroundColor3 = hex("#7c3aed")
	logo.BorderSizePixel = 0
	logo.Image = "rbxassetid://100519548765315"
	logo.Parent = keyPage
	corner(logo, 9)
	text(keyPage, "One Hub", 14, "#ededf0", "Semi", 62, 12, W - 120, 18)
	text(keyPage, current.Name, 12, "#8b8b97", "Medium", 62, 30, W - 120, 16)
	headerButton(keyPage, W - 44, ICON.x, "#8b8b97")
	box(keyPage, "#1f1f24", 0, 59, W, 1)

	local CW = W - 44
	text(keyPage, "Get your free key", 20, "#ededf0", "Bold", 22, 82, CW, 24)
	text(keyPage, "Takes a minute. You only do it once on this device.", 13, "#9a9aa6", "Medium", 22, 112, CW, 16)
	local steps = box(keyPage, "#16161a", 22, 146, CW, 122, 12, "#222228")
	local stepText = { "Join our Discord", "Pick " .. current.Name .. " in the script channel", "Paste your key below" }
	for i, t in stepText do
		local y = (i - 1) * 41
		if i > 1 then
			box(steps, "#222228", 46, y - 1, CW - 46, 1)
		end
		local dot = text(steps, tostring(i), 11, "#c4b5fd", "Bold", 14, y + 10, 20, 20, Enum.TextXAlignment.Center)
		dot.BackgroundTransparency = 0
		dot.BackgroundColor3 = hex("#2a2140")
		corner(dot, "full")
		text(steps, t, 13, "#d4d4da", "Medium", 46, y, CW - 58, 40)
	end

	text(keyPage, "Key", 12, "#9a9aa6", "Medium", 22, 286, CW, 16)
	local field = box(keyPage, "#0d0d10", 22, 310, CW, 44, 10)
	local fieldLine = stroke(field, "#2a2a31")
	icon(field, ICON.key, 16, "#6b6b76", 12, 14)
	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -50, 1, 0)
	input.Position = UDim2.new(0, 38, 0, 0)
	input.BackgroundTransparency = 1
	input.TextColor3 = hex("#ededf0")
	input.PlaceholderText = "Paste your key here"
	input.PlaceholderColor3 = hex("#5c5c66")
	input.Font = Enum.Font.Code
	input.TextSize = 13
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.TextTruncate = Enum.TextTruncate.AtEnd
	input.ClearTextOnFocus = false
	input.Text = ""
	input.Parent = field
	input.Focused:Connect(function()
		fieldLine.Color = hex("#7c3aed")
	end)
	local hasError = false
	input.FocusLost:Connect(function()
		fieldLine.Color = hex(hasError and "#7f2d2d" or "#2a2a31")
	end)
	local status = text(keyPage, "", 12, "#f87171", "Medium", 22, 360, CW, 16)

	local half = math.floor((CW - 10) / 2)
	local join = plainButton(keyPage, 22, 386, half, 44, "#18181c", 10, "#2f2f37")
	hover(join, "#18181c", "#202026")
	local jr = centredRow(join, 8)
	rowIcon(jr, ICON.message, 16, "#ededf0", 1)
	rowText(jr, "Join Discord", 14, "#ededf0", "Semi", 2)
	local check = plainButton(keyPage, 22 + half + 10, 386, CW - half - 10, 44, "#7c3aed", 10)
	hover(check, "#7c3aed", "#8b5cf6")
	local checkText = rowText(centredRow(check, 0), "Check Key", 14, "#ffffff", "Semi", 1)

	local orRow = box(keyPage, nil, 22, 448, CW, 14)
	local orLabel = text(orRow, "or skip the key with Premium", 11, "#8b8b97", "Medium", 0, 0, CW, 14, Enum.TextXAlignment.Center)
	local tw = 150
	pcall(function()
		tw = orLabel.TextBounds.X
	end)
	if tw < 10 then
		tw = 150
	end
	local side = math.floor((CW - tw - 20) / 2)
	box(orRow, "#222228", 0, 7, side, 1)
	box(orRow, "#222228", CW - side, 7, side, 1)
	orLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
		local w = orLabel.TextBounds.X
		if w > 10 then
			local s = math.floor((CW - w - 20) / 2)
			for _, c in orRow:GetChildren() do
				if c:IsA("Frame") then
					c.Size = UDim2.new(0, s, 0, 1)
					if c.Position.X.Offset > 0 then
						c.Position = UDim2.new(0, CW - s, 0, 7)
					end
				end
			end
		end
	end)

	local skip = plainButton(keyPage, 22, 480, CW, 44, "#2a2a31", 10)
	hover(skip, "#2a2a31", "#33333b")
	local sr = centredRow(skip, 8)
	rowText(sr, "Skip", 14, "#d4d4da", "Semi", 1)
	rowIcon(sr, ICON.arrowRight, 14, "#d4d4da", 2)

	local premPage = page()
	premPage.Visible = false
	local back = headerButton(premPage, 10, ICON.arrowLeft, "#b4b4be")
	text(premPage, "One Hub Premium", 14, "#ededf0", "Semi", 50, 20, W - 110, 20)
	headerButton(premPage, W - 44, ICON.x, "#8b8b97")
	box(premPage, "#1f1f24", 0, 59, W, 1)

	local banner = box(premPage, "#4c1d95", 22, 80, CW, 76, 12)
	banner.ClipsDescendants = true
	local ring = box(banner, nil, CW - 120, -60, 170, 170, "full", "#6d3fc4")
	ring.ZIndex = 1
	local emblem = box(banner, "#7c3aed", 18, 16, 44, 44, 12, "#a78bfa")
	local crown = icon(emblem, ICON.crown, 22, "#ffffff")
	crown.AnchorPoint = Vector2.new(0.5, 0.5)
	crown.Position = UDim2.fromScale(0.5, 0.5)
	local priceW = PREMIUM_PRICE ~= "" and 70 or 0
	text(banner, "No key, every game", 16, "#ffffff", "Bold", 76, 18, CW - 76 - 18 - priceW, 20)
	text(banner, "Skip key checkpoints and get new features first.", 12, "#ddd6fe", "Medium", 76, 40, CW - 76 - 18 - priceW, 16)
	if PREMIUM_PRICE ~= "" then
		text(banner, PREMIUM_PRICE, 18, "#ffffff", "Bold", CW - 18 - priceW, 18, priceW, 22, Enum.TextXAlignment.Right)
		text(banner, "7 days", 11, "#ddd6fe", "Medium", CW - 18 - priceW, 40, priceW, 14, Enum.TextXAlignment.Right)
	end

	text(premPage, "Pay with", 12, "#9a9aa6", "Medium", 22, 172, CW, 16)
	local list = box(premPage, "#16161a", 22, 196, CW, #PAYMENT_METHODS * 48, 12, "#222228")
	local note
	local function copied(how)
		pcall(setclipboard, PREMIUM_URL)
		note.Text = "Store link copied. Open it in your browser" .. (how and (" and pick " .. how) or "") .. "."
		note.TextColor3 = hex("#4ade80")
	end
	for i, m in PAYMENT_METHODS do
		local y = (i - 1) * 48
		if i > 1 then
			box(list, "#222228", 0, y, CW, 1)
		end
		local row = plainButton(list, 0, y, CW, 48, nil)
		row.BackgroundColor3 = hex("#1c1c21")
		local badge = text(row, m.Badge, 11, "#c8c8d0", "Bold", 14, 9, 30, 30, Enum.TextXAlignment.Center)
		badge.BackgroundTransparency = 0
		badge.BackgroundColor3 = hex("#222228")
		corner(badge, 8)
		text(row, m.Name, 13, "#ededf0", "Semi", 56, 0, CW - 96, 48)
		icon(row, ICON.chevron, 14, "#6b6b76", CW - 28, 17)
		row.MouseButton1Click:Connect(function()
			copied(m.Name)
		end)
		if not phone then
			row.MouseEnter:Connect(function()
				row.BackgroundTransparency = 0
			end)
			row.MouseLeave:Connect(function()
				row.BackgroundTransparency = 1
			end)
		end
	end
	local by = 196 + #PAYMENT_METHODS * 48 + 16
	local copyBtn = plainButton(premPage, 22, by, CW, 44, "#7c3aed", 10)
	hover(copyBtn, "#7c3aed", "#8b5cf6")
	rowText(centredRow(copyBtn, 0), "Copy store link", 14, "#ffffff", "Semi", 1)
	note = text(premPage, "Open it in your browser to pay. Your key arrives right after.", 11, "#8b8b97", "Medium", 22, by + 52, CW, 14, Enum.TextXAlignment.Center)
	PREM_H = by + 52 + 14 + 20
	copyBtn.MouseButton1Click:Connect(function()
		copied(nil)
	end)

	local function show(prem)
		keyPage.Visible = not prem
		premPage.Visible = prem
		local h = prem and PREM_H or KEY_H
		card.Size = UDim2.new(0, W, 0, h)
		scale.Scale = fitFor(h)
	end
	skip.MouseButton1Click:Connect(function()
		show(true)
	end)
	back.MouseButton1Click:Connect(function()
		show(false)
	end)

	local open = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(card, open, { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	TweenService:Create(scale, open, { Scale = fitFor(KEY_H) }):Play()

	local function setStatus(t, good)
		status.Text = t or ""
		status.TextColor3 = hex(good and "#4ade80" or "#f87171")
		hasError = (t or "") ~= "" and not good
		fieldLine.Color = hex(hasError and "#7f2d2d" or "#2a2a31")
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
		local k = clean(input.Text)
		if not k then
			return setStatus("Paste your key first. Get it for free in our Discord.")
		end
		busy = true
		checkText.Text = "Checking..."
		local ok, why, sure = checkKey(k)
		busy = false
		checkText.Text = "Check Key"
		resultVerified = ok
		if not ok and sure == false then
			unsure += 1
			if unsure >= 3 then
				ok = true
			end
		end
		if ok then
			input.Text = k
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
