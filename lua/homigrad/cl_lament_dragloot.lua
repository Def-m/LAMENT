-- LAMENT :: drag-to-loot
-- Replaces the grid loot menu: reach into the container with your hand, hold on a "?" box to
-- dig through it, grab what you find and drag it down into the pocket (the semicircle) to take it.
-- Uses the existing inventory backend (Inventory netvar + "ply_take_item"), nothing new on the server.
-- Styled to match the ESC menu / round stats (IBM Plex Mono, grey palette, accent strips).
-- Turn it off with  lament_dragloot 0  to get the old grid menu back.

hg = hg or {}
hg.DragLoot = hg.DragLoot or {}
local DL = hg.DragLoot

local cvEnabled = CreateClientConVar("lament_dragloot", "1", true, false, "Use the drag-to-loot menu (0 = old grid menu)", 0, 1)
function DL.Enabled() return cvEnabled:GetBool() end

local CFG = {
    MaxDist     = 125,      -- same as the old menu / server check
    TakeGap     = 0.55,     -- server has a 0.5s cooldown on ply_take_item, so space requests out
    ConfirmWait = 1.5,      -- if the item is still there after this long, it pops back home
    HandHeight  = 0.19,     -- hand sprite height as a fraction of screen height
    FakeFadeSpeed = 8,      -- how fast an empty fakeout box fades away once searched (8 = ~0.12s)
    HandGrabAlpha = 0.45,   -- hand opacity while grabbing: searching a [?] or dragging an item (1 = solid)

    -- base equip sounds (what the game plays when you equip that kind of thing)
    SndDrawDefault = "homigrad/weapons/draw_rifle.mp3",     -- homigrad_base SWEP.DeploySnd
    SndAmmo        = "items/ammo_pickup.wav",               -- bullet / ammo pickup
    SndArmor       = "snd_jack_hmcd_disguise.wav",          -- armor_base equip
    SndSmall       = function() return "physics/metal/weapon_impact_soft" .. math.random(3) .. ".wav" end, -- attachment_base

    -- interaction sounds
    SndHover  = "ui/rem_hover.wav",     -- same as the ESC menu buttons
    SndTick   = "ui/rem_tik.wav",       -- round stats typewriter tick
    SndGrab   = function() return "arc9_eft_shared/generic_mag_pouch_out" .. math.random(7) .. ".ogg" end,
    SndFound  = function() return "arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg" end,
    SndDrop   = "physics/cardboard/cardboard_box_impact_soft5.wav",
    SndDeny   = "ui/rem_select.wav",
}

-- palette borrowed from the ESC menu / round stats
local C = {
    white    = Color(240, 240, 240, 240),
    text     = Color(220, 220, 220),
    idle     = Color(188, 188, 188),
    dim      = Color(140, 140, 140),
    label    = Color(132, 132, 132),
    accent   = Color(225, 225, 225),
    panel    = Color(28, 28, 28, 180),
    panelHi  = Color(48, 48, 48, 235),
    btn      = Color(31, 31, 31, 205),
    border   = Color(180, 180, 180),
    red      = Color(192, 0, 0),
}

local MAT_OPEN = Material("lament/loot/hand_open.png")
local MAT_GRAB = Material("lament/loot/hand_grab.png")
local HOT_OPEN = { 0.39, 0.46 }   -- palm centre on the 512x512 sprite
local HOT_GRAB = { 0.50, 0.58 }   -- fist centre

local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end
local function cellSize() return U(110) end -- one grid cell; items are 1-3 cells wide, 1-2 tall

local MONO = "IBM Plex Mono"
local function fonts()
    local scale = math.min(ScrW(), ScrH()) / 1000
    surface.CreateFont("LAMENT.DL.Title", { font = MONO, size = math.max(16, math.floor(32 * scale)), weight = 400, antialias = true })
    surface.CreateFont("LAMENT.DL.Small", { font = MONO, size = math.max(14, math.floor(20 * scale)), weight = 400, antialias = true })
    surface.CreateFont("LAMENT.DL.Tiny",  { font = MONO, size = math.max(12, math.floor(16 * scale)), weight = 400, antialias = true })
    surface.CreateFont("LAMENT.DL.Key",   { font = MONO, size = math.max(10, math.floor(13 * scale)), weight = 600, antialias = true })
    DL.QFonts = {}
end
fonts()
hook.Add("OnScreenSizeChanged", "LAMENT.DragLoot.Fonts", fonts)

local function qFont(T)
    local name = "LAMENT.DL.Q" .. T
    if not DL.QFonts[name] then
        surface.CreateFont(name, { font = MONO, size = math.max(22, math.floor(T * 0.5)), weight = 300, antialias = true })
        DL.QFonts[name] = true
    end
    return name
end

local function play(s)
    if isfunction(s) then s = s() end
    if s and s ~= "" then surface.PlaySound(s) end
end

-- the sound you'd hear when equipping this item normally
local function equipSound(tab, i)
    if tab == "Ammo" then return CFG.SndAmmo end
    if tab == "Armor" then return CFG.SndArmor end
    if tab == "Weapons" then
        local wep = weapons.Get(i)
        if wep then
            local d = wep.DeploySnd
            return (istable(d) and d[1]) or (isstring(d) and d) or CFG.SndDrawDefault
        end
        return CFG.SndSmall() -- flashlight, sling, brass knuckles...
    end
    return CFG.SndSmall()
end

local function ease(t) t = math.Clamp(t, 0, 1) return 1 - (1 - t) ^ 3 end

---------------------------------------------------------------------------
-- reading the container's inventory (same rules as the old grid menu)
---------------------------------------------------------------------------

local function collectItems(ent)
    local H = hg.LootHelpers
    local inv = ent:GetNetVar("Inventory")
    if not inv or not H then return nil end
    local ply = LocalPlayer()
    local out = {}

    local tabs = {
        Weapons = inv.Weapons, Ammo = inv.Ammo,
        Armor = ent:GetNetVar("Armor"), Attachments = inv.Attachments,
    }
    for tab, things in pairs(tabs) do
        if not istable(things) then continue end
        for i, thing in pairs(things) do
            local thing1 = istable(thing) and thing or { thing }
            if H.canLoot[tab] and not H.canLoot[tab](ply, ent, i, unpack(thing1)) then continue end
            if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == i then continue end

            local name = H.nameThings(i, thing)
            local text = (tab == "Ammo" and game.GetAmmoName(tonumber(name) or name)) or language.GetPhrase(name)
            if tab == "Ammo" and tonumber(thing) then text = text .. " x" .. thing end

            local key = tab .. ":" .. tostring(i)
            out[key] = { key = key, tab = tab, i = i, thing = thing, text = text or tostring(i) }
        end
    end
    return out
end

-- item weight / size, same rules as the old grid menu (OpenInv in sh_inventory.lua)
local SMALL_THINGS = { hg_flashlight = true, hg_brassknuckles = true } -- always 1x1
local function lootWeight(tab, i, thing)
    if SMALL_THINGS[i] then return 1 end
    if tab == "Weapons" then
        local wep = weapons.Get(i)
        if wep then return wep.weight or wep.Weight or ((wep.weaponInvCategory == 1) and 8 or 3) end
        return 3
    elseif tab == "Ammo" then
        local amt = tonumber(istable(thing) and thing[1] or thing) or 1
        return math.Clamp((game.GetAmmoForce(tonumber(i) or 0) * amt) / 1500, 0.8, 6)
    elseif tab == "Armor" then
        return (hg.armor and hg.armor[i] and hg.armor[i][thing] and hg.armor[i][thing].mass) or 4
    end
    return 1
end

-- how many grid cells (wide, tall) the item takes up
local function lootSize(tab, i, thing)
    if SMALL_THINGS[i] then return 1, 1 end
    if tab == "Armor" then return 2, 2 end
    local w = lootWeight(tab, i, thing)
    if w >= 8 then return 3, 2 end
    if w >= 5 then return 2, 2 end
    if w >= 2.5 then return 2, 1 end
    return 1, 1
end

-- search time scales with how bulky the thing is, like the old menu
local function searchTime(it)
    return math.Clamp(0.45 + lootWeight(it.tab, it.i, it.thing) * 0.24, 0.65, 4)
end

local tabLabel = { Weapons = "weapon", Ammo = "ammo", Armor = "armor", Attachments = "attachment" }

---------------------------------------------------------------------------
-- drawing helpers
---------------------------------------------------------------------------

local function halfEllipse(cx, cy, rx, ry, col)
    draw.NoTexture()
    local pts = { { x = cx, y = cy } }
    for s = 0, 48 do
        local ang = math.pi + (s / 48) * math.pi
        pts[#pts + 1] = { x = cx + math.cos(ang) * rx, y = cy + math.sin(ang) * ry }
    end
    surface.SetDrawColor(col)
    for s = 2, #pts - 1 do surface.DrawPoly({ pts[1], pts[s], pts[s + 1] }) end
end

local function inPocket(px, py, p)
    if py > p.cy then return false end
    local dx, dy = (px - p.cx) / p.rx, (py - p.cy) / p.ry
    return dx * dx + dy * dy <= 1
end

-- "##### " -> "title" typewriter reveal, like the ESC menu buttons
local function typed(text, t0, speed)
    local chars = math.min(#text, math.floor((RealTime() - t0) * (speed or 22)))
    return text:sub(1, chars) .. string.rep("#", #text - chars), chars
end

-- little keycap, used in the hint bar
local function keycap(x, y, key, font)
    surface.SetFont(font)
    local tw, th = surface.GetTextSize(key)
    local pw, ph = tw + U(12), th + U(4)
    draw.RoundedBox(3, x, y - ph / 2, pw, ph, C.btn)
    surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 90)
    surface.DrawOutlinedRect(x, y - ph / 2, pw, ph, 1)
    draw.SimpleText(key, font, x + pw / 2, y, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return pw
end

-- Draws the item's icon fitted inside a w x h box centred on cx, cy.
local function drawIcon(st, cx, cy, w, h, alpha)
    local H = hg.LootHelpers
    if not H or not H.getIconThing then return false end
    local ok, Icon, HaveIcon, Overide, Quad = pcall(H.getIconThing, st.i, st.thing, st.tab)
    if not ok or not HaveIcon or not Icon then return false end
    if Overide and isnumber(Icon) then
        surface.SetTexture(Icon)
    else
        st.mat = st.mat or (isstring(Icon) and Material(Icon)) or Icon
        if type(st.mat) ~= "IMaterial" then return false end
        surface.SetMaterial(st.mat)
    end
    local iw, ih
    if Quad then iw = math.min(w, h) ih = iw else iw = w ih = math.min(h, w * 0.5) end
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.DrawTexturedRect(cx - iw / 2, cy - ih / 2, iw, ih)
    return true
end

local function fitText(text, font, maxW)
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxW then return text end
    while #text > 4 and surface.GetTextSize(text .. "...") > maxW do text = string.sub(text, 1, -2) end
    return text .. "..."
end

---------------------------------------------------------------------------
-- panel
---------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()
    self:SetSize(sw, sh)
    self:SetPos(0, 0)
    self:MakePopup()
    self:SetKeyboardInputEnabled(true)
    self:SetCursor("blank")

    self.items, self.held, self.handScale = {}, nil, 1
    self.tile = cellSize()
    self.gap = U(8)
    self.nextSend = CurTime() + CFG.TakeGap   -- OpenInventory sets a 0.5s server cooldown
    self.nextScan = 0
    self.opened = RealTime()

    -- container card
    local bw, bh = math.floor(sw * 0.56), math.floor(sh * 0.68)
    self.box = { x = math.floor((sw - bw) / 2), y = math.floor(sh * 0.03), w = bw, h = bh }
    self.header = U(70)
    self.footer = U(44)
    -- where the tiles live
    local pad = U(24)
    self.area = {
        x = self.box.x + pad, y = self.box.y + self.header,
        w = bw - pad * 2, h = bh - self.header - self.footer,
    }
    self.pocket = { cx = sw / 2, cy = sh + sh * 0.02, rx = sw * 0.2, ry = sh * 0.11 }

    self.hx, self.hy = sw * 0.5, sh * 1.2  -- hand starts below the screen and reaches in
    input.SetCursorPos(sw * 0.5, sh * 0.6)
    play(CFG.SndGrab)
end

-- how many cells of size C (plus the gap between them) fit in the area
function PANEL:Grid(C)
    local a, g = self.area, self.gap
    return math.max(3, math.floor((a.w + g) / (C + g))), math.max(2, math.floor((a.h + g) / (C + g)))
end

-- would these blocks ({w, h} each) all fit in a cols x rows grid? (biggest first, first free spot)
local function packs(blocks, cols, rows)
    local used = {}
    table.sort(blocks, function(a, b) return a[1] * a[2] > b[1] * b[2] end)
    for _, b in ipairs(blocks) do
        local placed = false
        for y = 1, rows - b[2] + 1 do
            for x = 1, cols - b[1] + 1 do
                local free = true
                for yy = y, y + b[2] - 1 do
                    for xx = x, x + b[1] - 1 do
                        if used[yy * 100 + xx] then free = false break end
                    end
                    if not free then break end
                end
                if free then
                    for yy = y, y + b[2] - 1 do for xx = x, x + b[1] - 1 do used[yy * 100 + xx] = true end end
                    placed = true
                    break
                end
            end
            if placed then break end
        end
        if not placed then return false end
    end
    return true
end

function PANEL:SetEnt(ent)
    self.ent = ent
    ent.foundloot = ent.foundloot or {}
    ent.dragLootLayout = ent.dragLootLayout or {}

    -- items take 1x1 / 2x1 / 2x2 / 3x2 cells like the old grid menu;
    -- shrink the cells if a body is carrying more than fits
    local blocks, cells = {}, 0
    local present = collectItems(ent) or {}
    for _, it in pairs(present) do
        local bw, bh = lootSize(it.tab, it.i, it.thing)
        blocks[#blocks + 1] = { bw, bh }
        cells = cells + bw * bh
    end
    -- fakeouts, like the old grid menu: empty [?] boxes that turn out to be nothing.
    -- rolled once per container, so reopening it shows the same ones (minus the ones you dug out)
    if not ent.dragLootFakes then
        ent.dragLootFakes = {}
        local real = #blocks
        local count = real > 0 and math.random(0, math.Clamp(math.ceil(real * 0.35), 1, 5)) or 0
        for n = 1, count do
            ent.dragLootFakes[n] = {
                w = math.random(1, 3) == 1 and 2 or 1,
                h = math.random(1, 4) == 1 and 2 or 1,
                time = math.Rand(0.7, 1.8),
            }
        end
    end
    for n, f in ipairs(ent.dragLootFakes) do
        if not f.revealed then
            present["fake:" .. n] = true
            blocks[#blocks + 1] = { f.w, f.h }
            cells = cells + f.w * f.h
        end
    end

    -- forget spots of things that were taken while the menu was closed
    for key in pairs(ent.dragLootLayout) do
        if not present[key] then ent.dragLootLayout[key] = nil end
    end
    local cs = cellSize()
    while cs > U(36) do
        local cols, rows = self:Grid(cs)
        if packs(table.Copy(blocks), cols, rows) then break end
        cs = math.floor(cs * 0.92)
    end
    local cols, rows = self:Grid(cs)
    if ent.dragLootCell ~= cs or ent.dragLootCols ~= cols then
        ent.dragLootLayout = {}
        ent.dragLootCell, ent.dragLootCols = cs, cols
    end
    self.cell, self.cols, self.rows = cs, cols, rows
    -- scattered at random when there's room; packed neatly from the top-left when it's crowded
    self.tight = cells > cols * rows * 0.55
    self.tile = cs
    self.qfont = qFont(cs)
    local a, g = self.area, self.gap
    self.gridX = math.floor(a.x + (a.w - (cols * cs + (cols - 1) * g)) / 2)
    self.gridY = math.floor(a.y + (a.h - (rows * cs + (rows - 1) * g)) / 2)

    if ent:IsPlayer() or ent:IsRagdoll() then
        self.title = string.lower((ent.GetPlayerName and ent:GetPlayerName()) or "someone")
        self.subtitle = "body"
    else
        self.title = "container"
        self.subtitle = string.lower(string.NiceName(ent:GetClass()))
    end
    self:Scan()
end

-- Each item gets a bw x bh block of cells at a random free spot (like the old grid menu),
-- remembered on the entity so reopening looks the same. Returns the block's centre and pixel size.
function PANEL:Home(key, bw, bh, noOverlap)
    local L, cs, g, cols, rows = self.ent.dragLootLayout, self.cell, self.gap, self.cols, self.rows
    local used = {}
    for k, b in pairs(L) do
        if k ~= key and b.w then
            for yy = b.y, b.y + b.h - 1 do for xx = b.x, b.x + b.w - 1 do used[yy * 100 + xx] = true end end
        end
    end
    local function fits(x, y)
        if x < 1 or y < 1 or x + bw - 1 > cols or y + bh - 1 > rows then return false end
        for yy = y, y + bh - 1 do for xx = x, x + bw - 1 do if used[yy * 100 + xx] then return false end end end
        return true
    end

    local b = L[key]
    if not (b and b.w == bw and b.h == bh and fits(b.x, b.y)) then
        local spots = {}
        for y = 1, rows do for x = 1, cols do if fits(x, y) then spots[#spots + 1] = { x, y } end end end
        if #spots == 0 and noOverlap then return nil end
        local spot = (self.tight and spots[1]) or spots[math.random(math.max(#spots, 1))] or { 1, 1 } -- no room at all: overlap
        b = { x = spot[1], y = spot[2], w = bw, h = bh }
        L[key] = b
    end

    local pw, ph = bw * cs + (bw - 1) * g, bh * cs + (bh - 1) * g
    local x0 = self.gridX + (b.x - 1) * (cs + g)
    local y0 = self.gridY + (b.y - 1) * (cs + g)
    return x0 + pw / 2, y0 + ph / 2, pw, ph
end

-- Re-read the inventory netvar; spot items that arrived in our pocket.
function PANEL:Scan()
    local data = collectItems(self.ent)
    if not data then return end
    -- place new things biggest first so the big blocks always find room
    local order = table.GetKeys(data)
    table.sort(order, function(a, b)
        local aw, ah = lootSize(data[a].tab, data[a].i, data[a].thing)
        local bw, bh = lootSize(data[b].tab, data[b].i, data[b].thing)
        if aw * ah ~= bw * bh then return aw * ah > bw * bh end
        return a < b
    end)
    for _, key in ipairs(order) do
        local it = data[key]
        local st = self.items[key]
        if not st then
            local bw, bh = lootSize(it.tab, it.i, it.thing)
            local hx, hy, pw, ph = self:Home(key, bw, bh)
            st = { key = key, x = hx, y = hy, hx = hx, hy = hy, pw = pw, ph = ph, a = 0, hl = 0, born = RealTime() }
            self.items[key] = st
        end
        st.tab, st.i, st.thing, st.text = it.tab, it.i, it.thing, it.text
        st.searchTime = st.searchTime or searchTime(it)
    end
    for n, f in ipairs(self.ent.dragLootFakes or {}) do
        local key = "fake:" .. n
        if not f.revealed and not self.items[key] then
            local hx, hy, pw, ph = self:Home(key, f.w, f.h, true)
            if hx then self.items[key] = { key = key, fake = n, x = hx, y = hy, hx = hx, hy = hy, pw = pw, ph = ph,
                a = 0, hl = 0, born = RealTime(), searchTime = f.time, text = "" } end
        end
    end
    for key, st in pairs(self.items) do
        if not st.fake and not data[key] and not st.gone then
            if st.pending then
                play(equipSound(st.tab, st.i))   -- it's ours now
            end
            if self.held == key then self.held = nil end
            st.gone = RealTime()
            self.ent.dragLootLayout[key] = nil -- its cells are free again
        end
    end
end

function PANEL:Found(st)
    if st.fake then return false end -- a fakeout never has anything in it
    return self.ent.foundloot[st.i]
end

function PANEL:Counts()
    local total, hidden = 0, 0
    for _, st in pairs(self.items) do
        if not st.gone and not st.pending and not st.vanish then
            total = total + 1
            if not self:Found(st) then hidden = hidden + 1 end
        end
    end
    return total, hidden
end

function PANEL:ItemAt(mx, my)
    for _, st in pairs(self.items) do
        if not st.gone and not st.pending and not st.vanish and math.abs(mx - st.x) <= st.pw * 0.5 and math.abs(my - st.y) <= st.ph * 0.5 then
            return st
        end
    end
end

function PANEL:OnMousePressed(code)
    if code ~= MOUSE_LEFT or self.closing then return end
    self.grabbing = true
    self:MouseCapture(true)
    local mx, my = self:CursorPos()
    local st = self:ItemAt(mx, my)
    if not st then return end
    if self:Found(st) then
        self.held = st.key
        st.ox, st.oy = st.x - mx, st.y - my
        play(CFG.SndGrab)
    else
        self.searching = st.key           -- rummage until it's revealed
        st.searchStart = CurTime()
    end
end

function PANEL:OnMouseReleased(code)
    if code ~= MOUSE_LEFT then return end
    self:MouseCapture(false)
    self.grabbing = false
    if self.searching then
        local st = self.items[self.searching]
        if st then st.searchStart, st.progress = nil, 0 end
        self.searching = nil
    end

    local st = self.held and self.items[self.held]
    self.held = nil
    if not st then return end

    local mx, my = self:CursorPos()
    if not inPocket(mx, my, self.pocket) then play(CFG.SndDrop) return end

    local H = hg.LootHelpers
    local thing1 = istable(st.thing) and st.thing or { st.thing }
    if H.canTake[st.tab] and not H.canTake[st.tab](LocalPlayer(), self.ent, st.i, unpack(thing1)) then
        self.msg, self.msgTime = "you already have something like this", RealTime()
        play(CFG.SndDeny)
        return
    end

    st.pending = RealTime()
    local when = math.max(CurTime(), self.nextSend)
    self.nextSend = when + CFG.TakeGap
    local ent, tab, i, thing = self.ent, st.tab, st.i, st.thing
    timer.Simple(when - CurTime(), function()
        if not IsValid(ent) then return end
        if istable(thing) then thing["render"] = {} end
        H.TakeItem(tab, i, thing, ent)
    end)
end

function PANEL:OnKeyCodePressed(key)
    if key == KEY_E or key == KEY_R or key == KEY_TAB or key == KEY_SPACE or key == KEY_ESCAPE then self:Close() end
end

-- fade out like ZFrame:Close
function PANEL:Close()
    if self.closing then return end
    self.closing = RealTime()
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
    self:MouseCapture(false)
    timer.Simple(0.2, function() if IsValid(self) then self:Remove() end end)
end

function PANEL:Think()
    local ply, ent = LocalPlayer(), self.ent
    if not IsValid(ent) or not IsValid(ply) or not ply:Alive() or (ply.organism and ply.organism.otrub)
        or (ent:GetPos() - ply:GetPos()):LengthSqr() > CFG.MaxDist ^ 2
        or (ent:IsPlayer() and not IsValid(ent.FakeRagdoll)) then
        return self:Remove()
    end
    if gui.IsGameUIVisible() then gui.HideGameUI() return self:Close() end

    if CurTime() >= self.nextScan then self.nextScan = CurTime() + 0.1 self:Scan() end

    local ft, rt = FrameTime(), RealTime()
    local mx, my = self:CursorPos()
    local p = self.pocket

    -- title typewriter ticks, like round stats
    if self.title then
        local _, chars = typed(self.title, self.opened + 0.1)
        if chars ~= self.lastChars then
            self.lastChars = chars
            if chars > 0 and self.title:sub(chars, chars) ~= " " then play(CFG.SndTick) end
        end
    end

    -- searching: progress while the fist stays on it
    local s = self.searching and self.items[self.searching]
    if s then
        local still = self:ItemAt(mx, my) == s
        if not still then s.searchStart = CurTime() end
        s.progress = math.Clamp((CurTime() - s.searchStart) / (s.searchTime or 1), 0, 1)
        if s.progress >= 1 then
            self.searching = nil
            s.progress = 0
            if s.fake then
                -- nothing in there: the box fades away and its cells free up
                ent.dragLootFakes[s.fake].revealed = true
                ent.dragLootLayout[s.key] = nil
                s.vanish = rt
                play(CFG.SndGrab)
            else
                ent.foundloot[s.i] = true
                s.flash = rt
                play(CFG.SndFound)
            end
        end
    end

    -- hover sound, like the menu buttons
    local hover = not self.held and not self.searching and self:ItemAt(mx, my)
    if hover and hover ~= self.lastHover then play(CFG.SndHover) end
    self.lastHover = hover or nil
    self.hover = hover

    -- the hand reaches toward the cursor; rummages while searching
    local k = math.min(1, ft * 22)
    self.hx, self.hy = Lerp(k, self.hx, mx), Lerp(k, self.hy, my)
    if self.searching then
        self.hx = self.hx + math.sin(rt * 38) * 3
        self.hy = self.hy + math.cos(rt * 31) * 2
    end
    self.overPocket = self.held and inPocket(mx, my, p)
    self.pocketLerp = Lerp(math.min(1, ft * 12), self.pocketLerp or 0, self.held and (self.overPocket and 1 or 0.4) or 0)
    local target = self.grabbing and 0.88 or 1
    if self.overPocket then target = 1.08 end
    self.handScale = Lerp(math.min(1, ft * 14), self.handScale, target)
    -- the hand goes see-through while grabbing (searching a [?] or dragging) so you can see under it
    self.handAlpha = Lerp(math.min(1, ft * 12), self.handAlpha or 1, self.grabbing and CFG.HandGrabAlpha or 1)

    for key, st in pairs(self.items) do
        local hot = st == hover or key == self.held or key == self.searching
        st.hl = Lerp(math.min(1, ft * 12), st.hl or 0, hot and 1 or 0)
        st.a = math.min(1, st.a + ft * 4)
        if key == self.held then
            st.ox, st.oy = Lerp(math.min(1, ft * 10), st.ox or 0, 0), Lerp(math.min(1, ft * 10), st.oy or 0, 0)
            st.x, st.y = mx + st.ox, my + st.oy
        elseif st.vanish then
            st.a = math.max(0, st.a - ft * CFG.FakeFadeSpeed)
            if st.a <= 0 then self.items[key] = nil end
        elseif st.gone or st.pending then
            st.x = Lerp(math.min(1, ft * 10), st.x, p.cx)
            st.y = Lerp(math.min(1, ft * 10), st.y, ScrH() + 40)
            st.a = math.max(0, st.a - ft * 3)
            if st.gone and rt - st.gone > 0.6 then self.items[key] = nil end
            if st.pending and not st.gone and rt - st.pending > CFG.ConfirmWait then st.pending = nil end
        else
            local m = math.min(1, ft * 12)
            st.x, st.y = Lerp(m, st.x, st.hx), Lerp(m, st.y, st.hy)
        end
    end
end

---------------------------------------------------------------------------
-- painting
---------------------------------------------------------------------------

function PANEL:DrawTile(st)
    local rt = RealTime()
    local held = self.held == st.key
    local searching = self.searching == st.key
    local found = self:Found(st)
    local hl = st.hl or 0
    -- tiles pop in one after another when the box opens
    local a = st.a * ease((rt - self.opened - 0.15 - ((st.hx - self.area.x) / self.area.w) * 0.25) / 0.25)
    if a <= 0 then return end
    local k = held and 0.9 or 1
    local w, h = math.floor(st.pw * k), math.floor(st.ph * k)

    local jx, jy = 0, 0
    if searching then jx, jy = math.random(-2, 2), math.random(-2, 2) end -- the box gets jostled while you dig
    local x0, y0 = math.floor(st.x - w / 2 + jx), math.floor(st.y - h / 2 + jy)
    local labelH = U(20)

    -- body
    local bg = hl > 0.5 and C.panelHi or C.btn
    draw.RoundedBox(3, x0, y0, w, h, ColorAlpha(bg, bg.a * a))

    local prog = st.progress or 0
    if not found then
        if prog > 0 then
            -- dig progress rises from the bottom and the item shows through it
            local fh = math.floor(h * prog)
            surface.SetDrawColor(255, 255, 255, 14 * a)
            surface.DrawRect(x0, y0 + h - fh, w, fh)
            render.SetScissorRect(x0, y0 + h - fh, x0 + w, y0 + h, true)
                drawIcon(st, x0 + w / 2, y0 + (h - labelH) / 2 + U(2), w * 0.82, (h - labelH) * 0.82, 230 * a)
            render.SetScissorRect(0, 0, 0, 0, false)
            -- progress strip on the left grows upward (same accent strip as the menu)
            surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 230 * a)
            surface.DrawRect(x0, y0 + h - fh, U(3), fh)
        end
        draw.SimpleText("?", self.qfont, x0 + w / 2, y0 + h / 2,
            ColorAlpha(hl > 0.5 and C.text or C.dim, 255 * a * (1 - prog * 0.85)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if searching then
            draw.SimpleText(fitText("searching...", "LAMENT.DL.Key", w - U(12)), "LAMENT.DL.Key", x0 + w / 2, y0 + h - U(5),
                ColorAlpha(C.label, 230 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    else
        if not drawIcon(st, x0 + w / 2, y0 + (h - labelH) / 2 + U(2), w * 0.82, (h - labelH) * 0.82, 255 * a) then
            draw.SimpleText(string.upper(string.sub(st.text or "?", 1, 1)), self.qfont, x0 + w / 2, y0 + (h - labelH) / 2,
                ColorAlpha(C.idle, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        -- name along the bottom, small category tag in the top corner
        draw.SimpleText(fitText(st.text or "", "LAMENT.DL.Tiny", w - U(14)), "LAMENT.DL.Tiny", x0 + U(7), y0 + h - U(4),
            ColorAlpha(hl > 0.5 and C.text or C.idle, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        if w > U(70) then
            draw.SimpleText(tabLabel[st.tab] or "", "LAMENT.DL.Key", x0 + w - U(6), y0 + U(4),
                ColorAlpha(C.label, 200 * a), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
        if st.flash and rt - st.flash < 0.35 then
            surface.SetDrawColor(255, 255, 255, 90 * (1 - (rt - st.flash) / 0.35) * a)
            surface.DrawRect(x0, y0, w, h)
        end
        -- accent strip on hover
        if hl > 0.01 then
            surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 210 * hl * a)
            surface.DrawRect(x0, y0, U(3), h)
        end
    end

    surface.SetDrawColor(C.border.r, C.border.g, C.border.b, (45 + 100 * hl) * a)
    surface.DrawOutlinedRect(x0, y0, w, h, 1)
end

function PANEL:Paint(w, h)
    local rt = RealTime()
    local open = ease((rt - self.opened) / 0.35)
    local fade = self.closing and (1 - math.Clamp((rt - self.closing) / 0.2, 0, 1)) or 1
    local alpha = open * fade

    -- backdrop: blur + the menu's noise background, lighter so you still see the world
    surface.SetAlphaMultiplier(alpha)
    if hg.DrawBlur then hg.DrawBlur(self, 2) end
    if hg.PaintMenuBackground then
        hg.PaintMenuBackground(w, h, 0.55)
    else
        surface.SetDrawColor(8, 8, 8, 160)
        surface.DrawRect(0, 0, w, h)
    end

    -- the card slides up into place (ZFrame style)
    local m = Matrix()
    m:Translate(Vector(0, (1 - open) * U(40), 0))
    cam.PushModelMatrix(m, true)

    local b, p = self.box, self.pocket
    draw.RoundedBox(3, b.x, b.y, b.w, b.h, C.panel)
    surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 50)
    surface.DrawOutlinedRect(b.x, b.y, b.w, b.h, 1)

    -- header
    local pad = U(24)
    local hy = b.y + self.header / 2
    surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 210)
    surface.DrawRect(b.x, b.y + U(16), U(3), self.header - U(32))
    if self.title then
        draw.SimpleText(typed(self.title, self.opened + 0.1), "LAMENT.DL.Title", b.x + pad, hy - U(9), C.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.upper(self.subtitle or ""), "LAMENT.DL.Tiny", b.x + pad, hy + U(16), C.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local total, hidden = self:Counts()
    draw.SimpleText(total .. (total == 1 and " ITEM" or " ITEMS"), "LAMENT.DL.Small", b.x + b.w - pad, hy - U(9), C.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    draw.SimpleText(hidden > 0 and (hidden .. " UNSEARCHED") or "ALL SEARCHED", "LAMENT.DL.Tiny", b.x + b.w - pad, hy + U(16), C.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 50)
    surface.DrawRect(b.x + pad, b.y + self.header - 1, b.w - pad * 2, 1)

    -- footer: keycap hints
    local fy = b.y + b.h - self.footer / 2
    surface.SetDrawColor(C.border.r, C.border.g, C.border.b, 50)
    surface.DrawRect(b.x + pad, b.y + b.h - self.footer, b.w - pad * 2, 1)
    local hints = { { "HOLD LMB", "search" }, { "DRAG", "into pocket to take" }, { "E", "close" } }
    surface.SetFont("LAMENT.DL.Tiny")
    local gap, totalW = U(18), 0
    local widths = {}
    for n, hnt in ipairs(hints) do
        surface.SetFont("LAMENT.DL.Key")
        local kw = surface.GetTextSize(hnt[1]) + U(12)
        surface.SetFont("LAMENT.DL.Tiny")
        local tw = surface.GetTextSize(hnt[2])
        widths[n] = { kw, tw }
        totalW = totalW + kw + U(6) + tw + (n < #hints and gap or 0)
    end
    local x = b.x + (b.w - totalW) / 2
    for n, hnt in ipairs(hints) do
        x = x + keycap(x, fy, hnt[1], "LAMENT.DL.Key") + U(6)
        draw.SimpleText(hnt[2], "LAMENT.DL.Tiny", x, fy, C.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        x = x + widths[n][2] + gap
    end

    if total == 0 and next(self.items) == nil then
        draw.SimpleText("nothing left", "LAMENT.DL.Small", b.x + b.w / 2, self.area.y + self.area.h / 2, C.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- tiles (held one on top)
    for key, st in pairs(self.items) do
        if key ~= self.held then self:DrawTile(st) end
    end
    cam.PopModelMatrix()

    -- pocket
    local pl = self.pocketLerp or 0
    local t = math.max(1, U(2))
    halfEllipse(p.cx, p.cy, p.rx, p.ry, Color(C.border.r, C.border.g, C.border.b, 50 + 150 * pl))
    halfEllipse(p.cx, p.cy, p.rx - t, p.ry - t, self.overPocket and C.panelHi or C.panel)
    draw.SimpleText(self.overPocket and "release to take" or "pocket", "LAMENT.DL.Tiny", p.cx, h - p.ry * 0.5,
        ColorAlpha(self.overPocket and C.text or C.dim, 80 + 175 * pl), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if self.held and self.items[self.held] then self:DrawTile(self.items[self.held]) end

    if self.msg and rt - self.msgTime < 1.8 then
        local ma = 1 - (rt - self.msgTime) / 1.8
        draw.SimpleText(self.msg, "LAMENT.DL.Tiny", p.cx, h - p.ry - U(22), ColorAlpha(C.red, 255 * ma), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- the hand, drawn last so you see it over the box you're digging in
    local grab = self.grabbing
    local mat, hot = grab and MAT_GRAB or MAT_OPEN, grab and HOT_GRAB or HOT_OPEN
    local size = h * CFG.HandHeight * self.handScale
    local hyy = self.hy - (self.hover and size * 0.02 or 0)
    surface.SetMaterial(mat)
    surface.SetDrawColor(255, 255, 255, 255 * (self.handAlpha or 1))
    surface.DrawTexturedRect(self.hx - size * hot[1], hyy - size * hot[2], size, size)
    surface.SetAlphaMultiplier(1)
end

vgui.Register("LAMENT.DragLootPanel", PANEL, "EditablePanel")

function DL.Open(ent)
    if IsValid(DL.Panel) then DL.Panel:Remove() end
    if not IsValid(ent) or not ent:GetNetVar("Inventory") then return end
    local pnl = vgui.Create("LAMENT.DragLootPanel")
    pnl:SetEnt(ent)
    DL.Panel = pnl
    return pnl
end
