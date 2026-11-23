local DISCORD = 'https://discord.gg/yNTHZAJvMd'
local PREMIUM_URL = 
[[https://onehub-script.mysellauth.com/product/one-hub-7-days-key-premium]]
local PREMIUM_PRICE = '$1.49'
local PAYMENT_METHODS = {
    {
        Badge = 'PP',
        Name = 'PayPal',
    },
    {
        Badge = 'CC',
        Name = 'Credit / debit card',
    },
    {
        Badge = 'BTC',
        Name = 'Crypto',
    },
}
local HttpService = game:GetService('HttpService')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

local function notify(text, duration)
    pcall(function()
        game:GetService('StarterGui'):SetCore('SendNotification', {
            Title = 'One Hub',
            Text = text,
            Duration = duration or 5,
        })
    end)
end

local GAMES = ...

if type(GAMES) ~= 'table' then
    notify('Run the One Hub loader, not this file.', 8)

    return
end

local current

for _, g in ipairs(GAMES)do
    for _, id in ipairs(g.Ids)do
        if game.PlaceId == id then
            current = g

            break
        end
    end
    for _, id in ipairs(g.GameIds or {})do
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
    notify('This script is not supported in this game')

    return
end

local KEY_FILE = 'OneHub/key_' .. (current.Url:match('loaders/(%w+)') or 'main') .. '.txt'

local function looksLikeKey(k)
    return type(k) == 'string' and #k >= 20 and #k <= 64 and k:match('^%w+$') ~= nil
end
local function clean(k)
    if type(k) == 'table' then
        k = k[current.Name]
    end

    k = k and tostring(k) or ''

    local inQuotes = k:match('script_key%s*=%s*["\']([^"\']+)["\']')

    if inQuotes then
        k = inQuotes
    end

    k = k:gsub('%s+', ''):gsub('["\'`]', '')

    if looksLikeKey(k) then
        return k
    end

    local best

    for w in k:gmatch('%w+')do
        if looksLikeKey(w) and not w:lower():find('http') and (not best or #w > #best) then
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
                writefile(KEY_FILE, '')
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

    if k and k ~= '' and not c then
        forgetKey()
    end

    return c
end
local function saveKey(k)
    pcall(function()
        if makefolder and not (isfolder and isfolder('OneHub')) then
            makefolder('OneHub')
        end

        writefile(KEY_FILE, k)
    end)
end

local PREMIUM_FILE = 'OneHub/key_premium.txt'

local function premiumSaved()
    local k

    pcall(function()
        if isfile and isfile(PREMIUM_FILE) then
            k = readfile(PREMIUM_FILE)
        end
    end)

    return clean(k)
end
local function savePremium(k)
    pcall(function()
        if makefolder and not (isfolder and isfolder('OneHub')) then
            makefolder('OneHub')
        end

        writefile(PREMIUM_FILE, k)
    end)
end
local function forgetPremium()
    pcall(function()
        if isfile and isfile(PREMIUM_FILE) then
            if delfile then
                delfile(PREMIUM_FILE)
            else
                writefile(PREMIUM_FILE, '')
            end
        end
    end)
end
local function premiumInfo(res)
    local yes = false

    pcall(function()
        local d = type(res) == 'table' and res.data

        if type(d) ~= 'table' then
            return
        end

        local note = string.lower(tostring(d.note or d.Note or ''))

        if string.find(note, 'premium', 1, true) then
            yes = true
        end

        local exp = tonumber(d.auth_expire)

        if exp and exp > 0 and exp - os.time() >= 48 * 3600 then
            yes = true
        end
    end)

    return yes
end

local luarmor

local function checkKey(k)
    if not looksLikeKey(k) then
        return false, "That's not a key. Paste only the key from our Discord.", true
    end
    if not luarmor then
        pcall(function()
            luarmor = loadstring(game:HttpGet('https://sdkapi-public.luarmor.net/library.lua'))()
            luarmor.script_id = current.Url:match('loaders/(%w+)')
        end)
    end
    if not luarmor then
        return false, 'Could not check the key, try again.', false
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
        return false, 'Key check timed out (Luarmor is slow). Try again.', false
    end
    if not ok or type(res) ~= 'table' then
        return false, 'Could not check the key, try again.', false
    end

    local code = res.code

    if code == 'KEY_VALID' then
        return true, nil, nil, res
    elseif code == 'KEY_HWID_LOCKED' then
        return false, 
[[This key is locked to another device. In our Discord click Reset HWID and paste this key.]]
    elseif code == 'KEY_EXPIRED' then
        return false, 'This key has expired. Get a new one in our Discord.'
    elseif code == 'KEY_BANNED' then
        return false, 'This key is banned.'
    elseif code == 'KEY_INCORRECT' or code == 'KEY_INVALID' then
        return false, 'Wrong key. Get yours for free in our Discord.'
    end

    return false, tostring(res.message or code or 'Could not check the key, try again.'), false
end
local function joinDiscord()
    pcall(setclipboard, DISCORD)

    local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)

    if req then
        task.spawn(pcall, req, {
            Url = 'http://127.0.0.1:6463/rpc?v=1',
            Method = 'POST',
            Headers = {
                ['Content-Type'] = 'application/json',
                Origin = 'https://discord.com',
            },
            Body = HttpService:JSONEncode({
                cmd = 'INVITE_BROWSER',
                nonce = HttpService:GenerateGUID(false),
                args = {
                    code = 'yNTHZAJvMd',
                },
            }),
        })
    end
end
local function qrMatrix(text)
    local ECC = {
        10,
        16,
        26,
        18,
        24,
        16,
        18,
        22,
        22,
        26,
    }
    local BLOCKS = {
        1,
        1,
        1,
        2,
        2,
        4,
        4,
        4,
        5,
        5,
    }

    local function rawModules(v)
        local r = (16 * v + 128) * v + 64

        if v >= 2 then
            local n = v // 7 + 2

            r -= (25 * n - 10) * n - 55

            if v >= 7 then
                r -= 36
            end
        end

        return r
    end
    local function dataCodewords(v)
        return rawModules(v) // 8 - ECC[v] * BLOCKS[v]
    end

    local ver

    for v = 1, 10 do
        local cap = dataCodewords(v) * 8
        local need = 4 + (v <= 9 and 8 or 16) + #text * 8

        if need <= cap then
            ver = v

            break
        end
    end

    if not ver then
        return nil
    end

    local bits = {}

    local function put(val, n)
        for i = n - 1, 0, -1 do
            bits[#bits + 1] = bit32.band(bit32.rshift(val, i), 1)
        end
    end

    put(4, 4)
    put(#text, ver <= 9 and 8 or 16)

    for i = 1, #text do
        put(string.byte(text, i), 8)
    end

    local cap = dataCodewords(ver) * 8

    put(0, math.min(4, cap - #bits))
    put(0, (8 - #bits % 8) % 8)

    local data = {}

    for i = 1, #bits, 8 do
        local b = 0

        for j = 0, 7 do
            b = b * 2 + bits[i + j]
        end

        data[#data + 1] = b
    end

    local pad = 0xec

    while#data < dataCodewords(ver) do
        data[#data + 1] = pad
        pad = pad == 0xec and 0x11 or 0xec
    end

    local function mul(x, y)
        local z = 0

        for i = 7, 0, -1 do
            z = bit32.bxor(bit32.lshift(z, 1), bit32.rshift(z, 7) * 0x11d)
            z = bit32.bxor(z, bit32.band(bit32.rshift(y, i), 1) * x)
        end

        return bit32.band(z, 0xff)
    end

    local deg = ECC[ver]
    local div = {}

    for i = 1, deg - 1 do
        div[i] = 0
    end

    div[deg] = 1

    local root = 1

    for _ = 1, deg do
        for j = 1, deg do
            div[j] = mul(div[j], root)

            if j < deg then
                div[j] = bit32.bxor(div[j], div[j + 1])
            end
        end

        root = mul(root, 0x2)
    end

    local function remainder(block)
        local res = {}

        for i = 1, deg do
            res[i] = 0
        end

        for _, b in block do
            local f = bit32.bxor(b, res[1])

            table.remove(res, 1)

            res[deg] = 0

            for i = 1, deg do
                res[i] = bit32.bxor(res[i], mul(div[i], f))
            end
        end

        return res
    end

    local nb = BLOCKS[ver]
    local raw = rawModules(ver) // 8
    local numShort = nb - raw % nb
    local shortLen = raw // nb
    local blocks = {}
    local k = 1

    for i = 0, nb - 1 do
        local len = shortLen - deg + (i < numShort and 0 or 1)
        local dat = {}

        for _ = 1, len do
            dat[#dat + 1] = data[k]

            k += 1
        end

        local ecc = remainder(dat)
        local full = {}

        for _, b in dat do
            full[#full + 1] = b
        end

        if i < numShort then
            full[#full + 1] = false
        end

        for _, b in ecc do
            full[#full + 1] = b
        end

        blocks[#blocks + 1] = full
    end

    local final = {}

    for i = 1, #blocks[1]do
        for j, b in blocks do
            if b[i] ~= false and b[i] ~= nil then
                final[#final + 1] = b[i]
            end
        end
    end

    local size = ver * 4 + 17
    local m, fn = {}, {}

    for y = 0, size - 1 do
        m[y] = {}
        fn[y] = {}

        for x = 0, size - 1 do
            m[y][x] = false
            fn[y][x] = false
        end
    end

    local function set(x, y, dark)
        m[y][x] = dark
        fn[y][x] = true
    end

    for i = 0, size - 1 do
        set(6, i, i % 2 == 0)
        set(i, 6, i % 2 == 0)
    end

    local function finder(cx, cy)
        for dy = -4, 4 do
            for dx = -4, 4 do
                local d = math.max(math.abs(dx), math.abs(dy))
                local x, y = cx + dx, cy + dy

                if x >= 0 and x < size and y >= 0 and y < size then
                    set(x, y, d ~= 2 and d ~= 4)
                end
            end
        end
    end

    finder(3, 3)
    finder(size - 4, 3)
    finder(3, size - 4)

    if ver > 1 then
        local n = ver // 7 + 2
        local step = (ver * 8 + n * 3 + 5) // (n * 4 - 4) * 2
        local pos = {6}

        for i = n - 2, 0, -1 do
            pos[#pos + 1] = size - 7 - i * step
        end
        for i = 1, n do
            for j = 1, n do
                if not ((i == 1 and j == 1) or (i == 1 and j == n) or (i == n and j == 1)) then
                    for dy = -2, 2 do
                        for dx = -2, 2 do
                            set(pos[i] + dx, pos[j] + dy, math.max(math.abs(dx), math.abs(dy)) ~= 1)
                        end
                    end
                end
            end
        end
    end

    local function drawFormat(mask)
        local d = bit32.bor(0, mask)
        local rem = d

        for _ = 1, 10 do
            rem = bit32.bxor(bit32.lshift(rem, 1), bit32.rshift(rem, 9) * 0x537)
        end

        local b = bit32.bxor(bit32.bor(bit32.lshift(d, 10), rem), 0x5412)

        local function bitAt(i)
            return bit32.band(bit32.rshift(b, i), 1) == 1
        end

        for i = 0, 5 do
            set(8, i, bitAt(i))
        end

        set(8, 7, bitAt(6))
        set(8, 8, bitAt(7))
        set(7, 8, bitAt(8))

        for i = 9, 14 do
            set(14 - i, 8, bitAt(i))
        end
        for i = 0, 7 do
            set(size - 1 - i, 8, bitAt(i))
        end
        for i = 8, 14 do
            set(8, size - 15 + i, bitAt(i))
        end

        set(8, size - 8, true)
    end

    drawFormat(0)

    if ver >= 7 then
        local rem = ver

        for _ = 1, 12 do
            rem = bit32.bxor(bit32.lshift(rem, 1), bit32.rshift(rem, 11) * 0x1f25)
        end

        local b = bit32.bor(bit32.lshift(ver, 12), rem)

        for i = 0, 17 do
            local dark = bit32.band(bit32.rshift(b, i), 1) == 1
            local a, c = size - 11 + i % 3, i // 3

            set(a, c, dark)
            set(c, a, dark)
        end
    end

    local i = 0
    local total = #final * 8
    local right = size - 1

    while right >= 1 do
        if right == 6 then
            right = 5
        end

        for vert = 0, size - 1 do
            for j = 0, 1 do
                local x = right - j
                local upward = ((right + 1) // 2) % 2 == 0
                local y = upward and (size - 1 - vert) or vert

                if not fn[y][x] and i < total then
                    local byte = final[i // 8 + 1]

                    m[y][x] = bit32.band(bit32.rshift(byte, 7 - i % 8), 1) == 1

                    i += 1
                end
            end
        end

        right -= 2
    end

    local MASKS = {
        function(x, y)
            return (x + y) % 2 == 0
        end,
        function(x, y)
            return y % 2 == 0
        end,
        function(x, y)
            return x % 3 == 0
        end,
        function(x, y)
            return (x + y) % 3 == 0
        end,
        function(x, y)
            return (x // 3 + y // 2) % 2 == 0
        end,
        function(x, y)
            return x * y % 2 + x * y % 3 == 0
        end,
        function(x, y)
            return (x * y % 2 + x * y % 3) % 2 == 0
        end,
        function(x, y)
            return ((x + y) % 2 + x * y % 3) % 2 == 0
        end,
    }

    local function applyMask(k2)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                if not fn[y][x] and MASKS[k2 + 1](x, y) then
                    m[y][x] = not m[y][x]
                end
            end
        end
    end
    local function penalty()
        local p = 0

        for y = 0, size - 1 do
            local run, last = 0, nil

            for x = 0, size - 1 do
                if m[y][x] == last then
                    run += 1

                    if run == 5 then
                        p += 3
                    elseif run > 5 then
                        p += 1
                    end
                else
                    last, run = m[y][x], 1
                end
            end
        end
        for x = 0, size - 1 do
            local run, last = 0, nil

            for y = 0, size - 1 do
                if m[y][x] == last then
                    run += 1

                    if run == 5 then
                        p += 3
                    elseif run > 5 then
                        p += 1
                    end
                else
                    last, run = m[y][x], 1
                end
            end
        end

        local dark = 0

        for y = 0, size - 1 do
            for x = 0, size - 1 do
                if m[y][x] then
                    dark += 1
                end
                if x < size - 1 and y < size - 1 then
                    local c = m[y][x]

                    if m[y][x + 1] == c and m[y + 1][x] == c and m[y + 1][x + 1] == c then
                        p += 3
                    end
                end
            end
        end

        local k3 = math.ceil(math.abs(dark * 20 - size * size * 10) / (size * size)) - 1

        return p + math.max(0, k3) * 10
    end

    local best, bestP = 0, math.huge

    for k2 = 0, 7 do
        applyMask(k2)
        drawFormat(k2)

        local p = penalty()

        if p < bestP then
            best, bestP = k2, p
        end

        applyMask(k2)
    end

    applyMask(best)
    drawFormat(best)

    return m, size
end
local function keyWindow(firstMessage)
    local result
    local resultVerified = false
    local gui = Instance.new('ScreenGui')

    gui.Name = 'OneHubKey'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999

    local okParent = pcall(function()
        gui.Parent = (gethui and gethui()) or game:GetService('CoreGui')
    end)

    if not okParent or not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')
    end

    local hex = Color3.fromHex
    local ICON = {
        x = 'rbxassetid://110786993356448',
        key = 'rbxassetid://96510194465420',
        message = 'rbxassetid://83881670383280',
        arrowRight = 'rbxassetid://113692007244654',
        arrowLeft = 'rbxassetid://102531941843733',
        chevron = 'rbxassetid://92473583511724',
        crown = 'rbxassetid://127843403295538',
        shield = 'rbxassetid://87354736164608',
        loader = 'rbxassetid://116535712789945',
        check = 'rbxassetid://93898873302694',
        external = 'rbxassetid://129331830773832',
    }

    local function font(weight)
        local ok, f = pcall(Font.new, 'rbxasset://fonts/families/BuilderSans.json', weight)

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
            o.Font = weight == 'Medium' and Enum.Font.GothamMedium or Enum.Font.GothamBold
        end
    end
    local function corner(p, r)
        local c = Instance.new('UICorner')

        c.CornerRadius = r == 'full' and UDim.new(1, 0) or UDim.new(0, r)
        c.Parent = p
    end
    local function stroke(p, color)
        local st = Instance.new('UIStroke')

        st.Color = hex(color)
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Parent = p

        return st
    end
    local function box(parent, color, x, y, w, h, r, line)
        local f = Instance.new('Frame')

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
        local l = Instance.new('TextLabel')

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
        local i = Instance.new('ImageLabel')

        i.BackgroundTransparency = 1
        i.Image = id
        i.ImageColor3 = hex(color)
        i.Size = UDim2.new(0, size, 0, size)
        i.Position = UDim2.new(0, x or 0, 0, y or 0)
        i.Parent = parent

        return i
    end
    local function centredRow(parent, gap)
        local row = Instance.new('Frame')

        row.BackgroundTransparency = 1
        row.Size = UDim2.fromScale(1, 1)
        row.Parent = parent

        local l = Instance.new('UIListLayout')

        l.FillDirection = Enum.FillDirection.Horizontal
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, gap)
        l.Parent = row

        return row
    end
    local function rowText(row, t, size, color, weight, order)
        local l = Instance.new('TextLabel')

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

    local UIS = game:GetService('UserInputService')
    local phone = false

    pcall(function()
        local pf = UIS:GetPlatform()

        phone = pf == Enum.Platform.IOS or pf == Enum.Platform.Android
    end)

    phone = phone or (UIS.TouchEnabled and (not UIS.MouseEnabled or math.min(vp.X, vp.Y) < 600))

    local W = 440
    local KEY_H, PREM_H = 544, 0
    local dim = Instance.new('Frame')

    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.new(0, 0, 0)
    dim.BackgroundTransparency = 1
    dim.BorderSizePixel = 0
    dim.Parent = gui

    local card = Instance.new('Frame')

    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.53)
    card.Size = UDim2.new(0, W, 0, KEY_H)
    card.BackgroundColor3 = hex('#111114')
    card.BorderSizePixel = 0
    card.Active = true
    card.ClipsDescendants = true
    card.Parent = gui

    corner(card, 16)
    stroke(card, '#26262c')

    local scale = Instance.new('UIScale')

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
        local b = Instance.new('TextButton')

        b.AutoButtonColor = false
        b.Text = ''
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

        b.BackgroundColor3 = hex('#ededf0')

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
        local p = Instance.new('Frame')

        p.BackgroundTransparency = 1
        p.Size = UDim2.fromScale(1, 1)
        p.Parent = card

        return p
    end

    local keyPage = page()
    local logo = Instance.new('ImageLabel')

    logo.Size = UDim2.new(0, 32, 0, 32)
    logo.Position = UDim2.new(0, 18, 0, 14)
    logo.BackgroundColor3 = hex('#7c3aed')
    logo.BorderSizePixel = 0
    logo.Image = 'rbxassetid://100519548765315'
    logo.Parent = keyPage

    corner(logo, 9)
    text(keyPage, 'One Hub', 14, '#ededf0', 'Semi', 62, 12, W - 120, 18)
    text(keyPage, current.Name, 12, '#8b8b97', 'Medium', 62, 30, W - 120, 16)
    headerButton(keyPage, W - 44, ICON.x, '#8b8b97')
    box(keyPage, '#1f1f24', 0, 59, W, 1)

    local CW = W - 44

    text(keyPage, 'Get your free key', 20, '#ededf0', 'Bold', 22, 82, CW, 24)
    text(keyPage, 'Takes a minute. You only do it once on this device.', 13, '#9a9aa6', 'Medium', 22, 112, CW, 16)

    local steps = box(keyPage, '#16161a', 22, 146, CW, 122, 12, '#222228')
    local stepText = {
        'Join our Discord',
        'Pick ' .. current.Name .. ' in the script channel',
        'Paste your key below',
    }

    for i, t in stepText do
        local y = (i - 1) * 41

        if i > 1 then
            box(steps, '#222228', 46, y - 1, CW - 46, 1)
        end

        local dot = text(steps, tostring(i), 11, '#c4b5fd', 'Bold', 14, y + 10, 20, 20, Enum.TextXAlignment.Center)

        dot.BackgroundTransparency = 0
        dot.BackgroundColor3 = hex('#2a2140')

        corner(dot, 'full')
        text(steps, t, 13, '#d4d4da', 'Medium', 46, y, CW - 58, 40)
    end

    text(keyPage, 'Key', 12, '#9a9aa6', 'Medium', 22, 286, CW, 16)

    local field = box(keyPage, '#0d0d10', 22, 310, CW, 44, 10)
    local fieldLine = stroke(field, '#2a2a31')

    icon(field, ICON.key, 16, '#6b6b76', 12, 14)

    local input = Instance.new('TextBox')

    input.Size = UDim2.new(1, -50, 1, 0)
    input.Position = UDim2.new(0, 38, 0, 0)
    input.BackgroundTransparency = 1
    input.TextColor3 = hex('#ededf0')
    input.PlaceholderText = 'Paste your key here'
    input.PlaceholderColor3 = hex('#5c5c66')
    input.Font = Enum.Font.Code
    input.TextSize = 13
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.TextTruncate = Enum.TextTruncate.AtEnd
    input.ClearTextOnFocus = false
    input.Text = ''
    input.Parent = field

    input.Focused:Connect(function()
        fieldLine.Color = hex('#7c3aed')
    end)

    local hasError = false

    input.FocusLost:Connect(function()
        fieldLine.Color = hex(hasError and '#7f2d2d' or '#2a2a31')
    end)

    local status = text(keyPage, '', 12, '#f87171', 'Medium', 22, 360, CW, 16)
    local half = math.floor((CW - 10) / 2)
    local join = plainButton(keyPage, 22, 386, half, 44, '#18181c', 10, '#2f2f37')

    hover(join, '#18181c', '#202026')

    local jr = centredRow(join, 8)

    rowIcon(jr, ICON.message, 16, '#ededf0', 1)
    rowText(jr, 'Join Discord', 14, '#ededf0', 'Semi', 2)

    local check = plainButton(keyPage, 22 + half + 10, 386, CW - half - 10, 44, '#7c3aed', 10)
    local checkGlow = stroke(check, '#9b6bff')

    checkGlow.Transparency = 0.55

    local checkScale = Instance.new('UIScale')

    checkScale.Parent = check

    local checkState = 'idle'
    local checkBase = '#7c3aed'

    if not phone then
        check.MouseEnter:Connect(function()
            if checkState == 'idle' then
                check.BackgroundColor3 = hex('#8b5cf6')
            end
        end)
        check.MouseLeave:Connect(function()
            check.BackgroundColor3 = hex(checkBase)
            checkScale.Scale = 1
        end)
    end

    check.MouseButton1Down:Connect(function()
        if checkState == 'idle' then
            checkScale.Scale = 0.97
        end
    end)
    check.MouseButton1Up:Connect(function()
        checkScale.Scale = 1
    end)

    local cr = centredRow(check, 8)
    local checkIcon = rowIcon(cr, ICON.shield, 16, '#ffffff', 1)
    local checkText = rowText(cr, 'Check Key', 14, '#ffffff', 'Semi', 2)
    local spin

    local function checkLook(state)
        checkState = state

        if spin then
            spin:Disconnect()

            spin = nil
        end

        checkIcon.Rotation = 0

        if state == 'busy' then
            checkBase = '#6d28d9'
            checkIcon.Image = ICON.loader
            checkText.Text = 'Checking...'
            spin = game:GetService('RunService').RenderStepped:Connect(function(
                dt
            )
                checkIcon.Rotation = (checkIcon.Rotation + dt * 360) % 360
            end)
        elseif state == 'good' then
            checkBase = '#16a34a'
            checkIcon.Image = ICON.check
            checkText.Text = 'Key accepted'
            checkGlow.Color = hex('#4ade80')
        else
            checkBase = '#7c3aed'
            checkIcon.Image = ICON.shield
            checkText.Text = 'Check Key'
            checkGlow.Color = hex('#9b6bff')
        end

        check.BackgroundColor3 = hex(checkBase)
    end

    local orRow = box(keyPage, nil, 22, 448, CW, 14)
    local orLabel = text(orRow, 'or skip the key with Premium', 11, '#8b8b97', 'Medium', 0, 0, CW, 14, Enum.TextXAlignment.Center)
    local tw = 150

    pcall(function()
        tw = orLabel.TextBounds.X
    end)

    if tw < 10 then
        tw = 150
    end

    local side = math.floor((CW - tw - 20) / 2)

    box(orRow, '#222228', 0, 7, side, 1)
    box(orRow, '#222228', CW - side, 7, side, 1)
    orLabel:GetPropertyChangedSignal('TextBounds'):Connect(function()
        local w = orLabel.TextBounds.X

        if w > 10 then
            local s = math.floor((CW - w - 20) / 2)

            for _, c in orRow:GetChildren()do
                if c:IsA('Frame') then
                    c.Size = UDim2.new(0, s, 0, 1)

                    if c.Position.X.Offset > 0 then
                        c.Position = UDim2.new(0, CW - s, 0, 7)
                    end
                end
            end
        end
    end)

    local skip = plainButton(keyPage, 22, 480, CW, 44, '#2a2a31', 10)

    hover(skip, '#2a2a31', '#33333b')

    local sr = centredRow(skip, 8)

    rowText(sr, 'Skip', 14, '#d4d4da', 'Semi', 1)
    rowIcon(sr, ICON.arrowRight, 14, '#d4d4da', 2)

    local premPage = page()

    premPage.Visible = false

    local back = headerButton(premPage, 10, ICON.arrowLeft, '#b4b4be')

    text(premPage, 'One Hub Premium', 14, '#ededf0', 'Semi', 50, 20, W - 110, 20)
    headerButton(premPage, W - 44, ICON.x, '#8b8b97')
    box(premPage, '#1f1f24', 0, 59, W, 1)

    local banner = box(premPage, '#4c1d95', 22, 80, CW, 76, 12)

    banner.ClipsDescendants = true

    local ring = box(banner, nil, CW - 120, -60, 170, 170, 'full', '#6d3fc4')

    ring.ZIndex = 1

    local emblem = box(banner, '#7c3aed', 18, 16, 44, 44, 12, '#a78bfa')
    local crown = icon(emblem, ICON.crown, 22, '#ffffff')

    crown.AnchorPoint = Vector2.new(0.5, 0.5)
    crown.Position = UDim2.fromScale(0.5, 0.5)

    local priceW = PREMIUM_PRICE ~= '' and 70 or 0

    text(banner, 'No key, every game', 16, '#ffffff', 'Bold', 76, 18, CW - 76 - 18 - priceW, 20)
    text(banner, 'Skip key checkpoints and get new features first.', 12, '#ddd6fe', 'Medium', 76, 40, CW - 76 - 18 - priceW, 16)

    if PREMIUM_PRICE ~= '' then
        text(banner, PREMIUM_PRICE, 18, '#ffffff', 'Bold', CW - 18 - priceW, 18, priceW, 22, Enum.TextXAlignment.Right)
        text(banner, '7 days', 11, '#ddd6fe', 'Medium', CW - 18 - priceW, 40, priceW, 14, Enum.TextXAlignment.Right)
    end

    text(premPage, 'Pay with', 12, '#9a9aa6', 'Medium', 22, 172, CW, 16)

    local list = box(premPage, '#16161a', 22, 196, CW, #PAYMENT_METHODS * 48, 12, '#222228')
    local note
    local showQr

    local function copied(how)
        pcall(setclipboard, PREMIUM_URL)
        showQr(how)
    end

    for i, m in PAYMENT_METHODS do
        local y = (i - 1) * 48

        if i > 1 then
            box(list, '#222228', 0, y, CW, 1)
        end

        local row = plainButton(list, 0, y, CW, 48, nil)

        row.BackgroundColor3 = hex('#1c1c21')

        local badge = text(row, m.Badge, 11, '#c8c8d0', 'Bold', 14, 9, 30, 30, Enum.TextXAlignment.Center)

        badge.BackgroundTransparency = 0
        badge.BackgroundColor3 = hex('#222228')

        corner(badge, 8)
        text(row, m.Name, 13, '#ededf0', 'Semi', 56, 0, CW - 96, 48)
        icon(row, ICON.chevron, 14, '#6b6b76', CW - 28, 17)
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
    local copyBtn = plainButton(premPage, 22, by, CW, 44, '#7c3aed', 10)

    hover(copyBtn, '#7c3aed', '#8b5cf6')

    local tr = centredRow(copyBtn, 8)

    rowText(tr, 'Take me there', 14, '#ffffff', 'Semi', 1)
    rowIcon(tr, ICON.external, 15, '#ffffff', 2)

    note = text(premPage, 
[[Opens a code to scan with your phone. Your key arrives right after paying.]], 11, '#8b8b97', 'Medium', 22, by + 52, CW, 14, Enum.TextXAlignment.Center)
    PREM_H = by + 52 + 14 + 20

    copyBtn.MouseButton1Click:Connect(function()
        copied(nil)
    end)

    local qrPage = page()

    qrPage.Visible = false

    local qrBack = headerButton(qrPage, 10, ICON.arrowLeft, '#b4b4be')

    text(qrPage, 'Scan to pay', 14, '#ededf0', 'Semi', 50, 20, W - 110, 20)
    headerButton(qrPage, W - 44, ICON.x, '#8b8b97')
    box(qrPage, '#1f1f24', 0, 59, W, 1)

    local QR_BOX = 228
    local qrCard = box(qrPage, '#ffffff', math.floor((W - QR_BOX) / 2), 80, QR_BOX, QR_BOX, 12)
    local qrHow = text(qrPage, '', 13, '#ededf0', 'Semi', 22, 80 + QR_BOX + 16, CW, 18, Enum.TextXAlignment.Center)

    text(qrPage, 'Point your phone camera at the code to open the store.', 12, '#9a9aa6', 'Medium', 22, 80 + QR_BOX + 38, CW, 16, Enum.TextXAlignment.Center)

    local qrCopied = text(qrPage, 
[[The link is also copied, paste it in a browser on this device.]], 11, '#4ade80', 'Medium', 22, 80 + QR_BOX + 60, CW, 14, Enum.TextXAlignment.Center)
    local QR_H = 80 + QR_BOX + 60 + 14 + 22
    local qrDrawn = false

    local function drawQr()
        if qrDrawn then
            return
        end

        qrDrawn = true

        local m, size = qrMatrix(PREMIUM_URL)

        if not m then
            return
        end

        local cell = math.floor((QR_BOX - 24) / size)
        local off = math.floor((QR_BOX - cell * size) / 2)

        for y = 0, size - 1 do
            local x = 0

            while x < size do
                if m[y][x] then
                    local x0 = x

                    while x < size and m[y][x] do
                        x += 1
                    end

                    box(qrCard, '#000000', off + x0 * cell, off + y * cell, (x - x0) * cell, cell)
                else
                    x += 1
                end
            end
        end
    end
    local function show(which)
        keyPage.Visible = which == 'key'
        premPage.Visible = which == 'prem'
        qrPage.Visible = which == 'qr'

        local h = which == 'prem' and PREM_H or which == 'qr' and QR_H or KEY_H

        card.Size = UDim2.new(0, W, 0, h)
        scale.Scale = fitFor(h)
    end

    showQr = function(how)
        drawQr()

        qrHow.Text = how and ('Pay with ' .. how) or 'One Hub Premium'

        show('qr')
    end

    skip.MouseButton1Click:Connect(function()
        show('prem')
    end)
    back.MouseButton1Click:Connect(function()
        show('key')
    end)
    qrBack.MouseButton1Click:Connect(function()
        show('prem')
    end)

    local open = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    TweenService:Create(dim, TweenInfo.new(0.25), {BackgroundTransparency = 0.45}):Play()
    TweenService:Create(card, open, {
        Position = UDim2.fromScale(0.5, 0.5),
    }):Play()
    TweenService:Create(scale, open, {
        Scale = fitFor(KEY_H),
    }):Play()

    local function setStatus(t, good)
        status.Text = t or ''
        status.TextColor3 = hex(good and '#4ade80' or '#f87171')
        hasError = (t or '') ~= '' and not good
        fieldLine.Color = hex(hasError and '#7f2d2d' or '#2a2a31')
    end

    if firstMessage then
        setStatus(firstMessage)
    end

    join.MouseButton1Click:Connect(function()
        joinDiscord()
        setStatus('Discord link copied! It should open in your Discord app.', true)
    end)

    local busy = false
    local unsure = 0

    check.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        local k = clean(input.Text)

        if not k then
            return setStatus('Paste your key first. Get it for free in our Discord.')
        end

        busy = true

        checkLook('busy')

        local ok, why, sure, res = checkKey(k)

        busy = false

        checkLook('idle')

        resultVerified = ok

        if ok and premiumInfo(res) then
            savePremium(k)
        end
        if not ok and sure == false then
            unsure += 1

            if unsure >= 3 then
                ok = true
            end
        end
        if ok then
            input.Text = k

            checkLook('good')
            setStatus('Key accepted! Loading...', true)

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
    local redeemed = false

    pcall(function()
        redeemed = getgenv().OneHubRedeem == true
        getgenv().OneHubRedeem = nil
    end)

    local function tryPremium()
        local prem = premiumSaved()

        if not prem or prem == key then
            return
        end

        local ok, w, sure = checkKey(prem)

        if ok then
            key = prem
        elseif sure == false then
            unchecked = unchecked or prem
        elseif tostring(w):find('another device', 1, true) then
            notify(
[[Your Premium key is locked to another device. Reset HWID in our Discord.]], 10)
        else
            forgetPremium()
        end
    end

    if not redeemed then
        tryPremium()
    end
    if pasted and not key then
        local ok, w, sure, res = checkKey(pasted)

        if ok then
            key = pasted

            if redeemed or premiumInfo(res) then
                savePremium(pasted)
            end
        elseif sure == false then
            unchecked = unchecked or pasted
        else
            why = w

            dropPasted()
        end
    end
    if redeemed and not key then
        tryPremium()
    end
    if not key then
        local saved = savedKey()

        if saved then
            local ok, w, sure, res = checkKey(saved)

            if ok then
                key = saved

                if premiumInfo(res) then
                    savePremium(saved)
                end
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
        key, verified = keyWindow(why or (unchecked and 'Could not check your key. Try again.' or nil))
    end
    if not key then
        dropPasted()
        pcall(setclipboard, DISCORD)
        notify('Join our Discord (link copied) to get your free key.', 8)

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

    if ok and type(res) == 'string' and #res > 50 then
        src = res

        break
    end

    task.wait(2)
end

if not src then
    notify('Could not download the ' .. current.Name .. ' script. Try again.')

    return
end

local fn, err = loadstring(src)

if not fn then
    local said = src:gsub('<[^>]*>', ' '):gsub('%s+', ' '):sub(1, 140)

    pcall(setclipboard, said)
    notify('The ' .. current.Name .. ' script failed to load. Server said: ' .. said, 15)

    return
end

task.spawn(function()
    local ok, e = xpcall(fn, function(m)
        return tostring(m) .. '\n' .. debug.traceback()
    end)

    if not ok then
        warn('[One Hub] ' .. current.Name .. ': ' .. tostring(e))
        pcall(setclipboard, tostring(e))
        notify(current.Name .. ' script error (copied): ' .. tostring(e):sub(1, 120), 15)
    end
end)
