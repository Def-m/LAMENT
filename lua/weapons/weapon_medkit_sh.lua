if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.BandageTPIK = false
SWEP.PrintName = "Medkit Container"
SWEP.Instructions = "A military medkit. Holds medical supplies - take them out or pack your own in."
SWEP.HowToUseInstructions = "LMB / RMB - open the medkit"
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/w_models/weapons/w_eq_medkit.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_medkit")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_medkit.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -0.5, -3)
SWEP.offsetAng = Angle(-30, 20, 90)
SWEP.modes = 1
SWEP.modeNames = {
	[1] = "open",
}
SWEP.showstats = false
SWEP.ofsV = Vector(-2,-10,8)
SWEP.ofsA = Angle(90,-90,90)

-- ============================================================
-- Storage rules
-- ============================================================
SWEP.MedkitCapacity = 6

-- how many slots an item takes (anything medical not listed takes 1)
hg = hg or {}
hg.MedkitItemSizes = {
	["weapon_bandage_sh"] = 1,
	["weapon_bigbandage_sh"] = 2,
	["weapon_painkillers_tpik"] = 1,
	["weapon_tourniquet"] = 1,
	["weapon_splint"] = 1,
	-- syringes of any kind
	["weapon_adrenaline"] = 0.5,
	["weapon_morphine"] = 0.5,
	["weapon_fentanyl"] = 0.5,
	["weapon_desomorphine"] = 0.5,
	["weapon_mannitol"] = 0.5,
	["weapon_tranexamic"] = 0.5,
	["weapon_midazolam"] = 0.5,
	["weapon_naloxone"] = 0.5,
	["weapon_needle"] = 0.5,
	-- bulkier kit
	["weapon_bloodbag"] = 2,
	["weapon_defibrillator"] = 3,
}

function hg.MedkitIsMedical(class)
	if not isstring(class) or class == "weapon_medkit_sh" or class == "weapon_hg_medicine_base" then return false end
	if hg.MedkitItemSizes[class] then return true end
	local stored = weapons.GetStored(class)
	return stored ~= nil and stored.Category == "ZCity Medicine"
end

function hg.MedkitItemSize(class)
	return hg.MedkitItemSizes[class] or 1
end

function hg.MedkitItemName(class)
	local stored = weapons.Get(class)
	return (stored and stored.PrintName) or class
end

-- after taking something out, keep the medkit in hand for a moment so nothing auto-switches
hook.Add("PlayerSwitchWeapon", "ZC_MedkitHoldOnTake", function(ply, oldWep, newWep)
	if not IsValid(oldWep) or oldWep:GetClass() ~= "weapon_medkit_sh" then return end
	if IsValid(newWep) and newWep:GetClass() == "weapon_medkit_sh" then return end
	if ply:GetNW2Float("ZC_MedkitHold", 0) > CurTime() then return true end
end)

function SWEP:InitializeAdd()
	self:SetHold(self.HoldType)

	self.modeValues = {
		[1] = 1,
	}

	if SERVER and not self.MedContents then
		self:FillMedkit()
	end
end

SWEP.modeValuesdef = {
	[1] = {1,false},
}
-- the medkit is a container now, it never gets used up
SWEP.ShouldDeleteOnFullUse = false

local math = math
local hg_healanims = ConVarExists("hg_healanims") and GetConVar("hg_healanims") or CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)
function SWEP:Think()
	if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
		self:SetHolding(math.max(self:GetHolding() - 12, 0))
	end
end

local lang1, lang2 = Angle(0, -10, 0), Angle(0, 10, 0)
function SWEP:Animation()
	local owner = self:GetOwner()
	if (owner.zmanipstart ~= nil and not ( owner.organism and owner.organism.larmamputated )) then return end

	local aimvec = owner:GetAimVector()
	if not aimvec then return end

	local hold = self:GetHolding()
	local ducking = owner:IsFlagSet(FL_ANIMDUCKING)

    self:BoneSet("r_upperarm", vector_origin, Angle(30 - hold / 5, -30 + hold / 2 + 20 * aimvec[3] * (ducking and -3 or -1), 5 - hold / 4))
    self:BoneSet("r_forearm", vector_origin, Angle(hold / 25, -hold / 2.5, 35 -hold / 1.4))

    self:BoneSet("l_upperarm", vector_origin, lang1)
    self:BoneSet("l_forearm", vector_origin, lang2)
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:SpawnGarbage()
		self:NPCHeal(owner, 0.6, "snd_jack_hmcd_bandage.wav")
	end
end

-- contents as the client sees them: { {c = class, p = percent left or nil}, ... }
function SWEP:GetMedkitContents()
	return self:GetNetVar("MedkitContents", {}) or {}
end

function SWEP:GetMedkitUsed(list)
	local used = 0
	for _, item in ipairs(list or self:GetMedkitContents()) do
		used = used + hg.MedkitItemSize(item.c or item.class)
	end
	return used
end

if SERVER then
	util.AddNetworkString("ZC_MedkitOpen")
	util.AddNetworkString("ZC_MedkitAction")

	SWEP.MedkitLootPool = {
		{weight = 30, class = "weapon_bigbandage_sh"},
		{weight = 25, class = "weapon_painkillers_tpik"},
		{weight = 18, class = "weapon_tourniquet"},
		{weight = 14, class = "weapon_splint"},
		{weight = 12, class = "weapon_adrenaline"},
		{weight = 10, class = "weapon_betablock_tpik"},
		{weight = 7, class = "weapon_morphine"},
		{weight = 7, class = "weapon_mannitol"},
		{weight = 8, class = "weapon_tranexamic"},
		{weight = 6, class = "weapon_naloxone"},
		{weight = 6, class = "weapon_midazolam"},
		{weight = 5, class = "weapon_bloodbag"},
		{weight = 5, class = "weapon_thiamine_tpik"},
	}

	function SWEP:PickMedkitLoot()
		local total = 0
		for _, item in ipairs(self.MedkitLootPool) do total = total + item.weight end

		local roll = math.random(total)
		for _, item in ipairs(self.MedkitLootPool) do
			roll = roll - item.weight
			if roll <= 0 then return item.class end
		end

		return self.MedkitLootPool[1].class
	end

	function SWEP:MedkitServerUsed()
		local used = 0
		for _, item in ipairs(self.MedContents or {}) do
			used = used + hg.MedkitItemSize(item.class)
		end
		return used
	end

	function SWEP:MedkitFits(class)
		return self:MedkitServerUsed() + hg.MedkitItemSize(class) <= self.MedkitCapacity
	end

	SWEP.MedkitMinStartSlots = 4

	-- a bandage, a needle and random extras until at least 4 slots are filled
	function SWEP:FillMedkit()
		self.MedContents = {}
		local function add(class)
			if self:MedkitFits(class) then
				self.MedContents[#self.MedContents + 1] = {class = class}
				return true
			end
		end
		add("weapon_bandage_sh")
		add("weapon_needle")
		local extras, tries = 0, 0
		while (self:MedkitServerUsed() < self.MedkitMinStartSlots or extras < 1) and tries < 30 do
			tries = tries + 1
			if add(self:PickMedkitLoot()) then extras = extras + 1 end
		end
		-- top up with half-slot syringes if the random picks couldn't fit
		while self:MedkitServerUsed() < self.MedkitMinStartSlots and add("weapon_adrenaline") do end
		self:SyncMedkit()
	end

	local function PercentLeft(class, info)
		if not istable(info) or not isnumber(info[1]) then return nil end
		local stored = weapons.Get(class)
		local def = stored and stored.modeValuesdef and stored.modeValuesdef[1]
		local full = istable(def) and def[1] or def
		if not isnumber(full) or full <= 0 then return nil end
		local p = math.Clamp(math.Round(info[1] / full * 100), 0, 100)
		if p >= 100 then return nil end
		return p
	end

	function SWEP:SyncMedkit()
		local list = {}
		for _, item in ipairs(self.MedContents or {}) do
			list[#list + 1] = {c = item.class, p = PercentLeft(item.class, item.info)}
		end
		self:SetNetVar("MedkitContents", list)
	end

	local function ReadItemState(wep)
		if wep.GetInfo then
			local ok, info = pcall(wep.GetInfo, wep)
			if ok and istable(info) then return table.Copy(info) end
		end
		if istable(wep.modeValues) then return table.Copy(wep.modeValues) end
	end

	local function WriteItemState(wep, info)
		if not IsValid(wep) or not istable(info) then return end
		if wep.SetInfo then
			wep:SetInfo(table.Copy(info))
		else
			wep.modeValues = table.Copy(info)
			wep:SetNetVar("modeValues", wep.modeValues)
		end
	end

	function SWEP:OpenMedkit()
		local owner = self:GetOwner()
		if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
		if (self.NextMedkitOpen or 0) > CurTime() then return end
		self.NextMedkitOpen = CurTime() + 0.4
		if not self.MedContents then self:FillMedkit() end
		self:SyncMedkit()

		local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner
		entOwner:EmitSound("items/ammocrate_open.wav", 45, math.random(110, 120), 0.5)

		net.Start("ZC_MedkitOpen")
			net.WriteEntity(self)
		net.Send(owner)
	end

	function SWEP:MedkitTake(ply, index)
		local item = self.MedContents and self.MedContents[index]
		if not item then return end
		if ply:HasWeapon(item.class) then
			ply:ChatPrint("You already carry a " .. hg.MedkitItemName(item.class) .. ".")
			return
		end

		-- block the automatic switch to the new item for a short moment
		ply:SetNW2Float("ZC_MedkitHold", CurTime() + 0.75)
		local wep = ply:Give(item.class, true)
		-- homigrad's "pickupHuy" WeaponEquip hook force-selects anything you're given two ticks later
		-- (straight SetActiveWeapon, so the hold block above can't stop it). this is its opt-out flag;
		-- it's read on the next tick, so setting it right after Give is in time.
		if IsValid(wep) then wep.DontEquipInstantly = true end
		if not IsValid(wep) then wep = ply:GetWeapon(item.class) end
		if not IsValid(wep) then return end
		table.remove(self.MedContents, index)
		-- keep holding the medkit, don't switch to what was taken out
		local kitClass = self:GetClass()
		if ply:GetActiveWeapon() ~= self then ply:SelectWeapon(kitClass) end
		timer.Simple(0, function()
			if IsValid(ply) and IsValid(self) and ply:GetActiveWeapon() ~= self and ply:HasWeapon(kitClass) then
				ply:SelectWeapon(kitClass)
			end
		end)
		if item.info then
			WriteItemState(wep, item.info)
			-- some items reset themselves right after spawning, so apply once more
			local info = item.info
			timer.Simple(0.1, function() WriteItemState(wep, info) end)
		end
		self:SyncMedkit()
		ply:EmitSound("snd_jack_hmcd_bandage.wav", 45, math.random(105, 115), 0.4)
	end

	function SWEP:MedkitStore(ply, class)
		if not hg.MedkitIsMedical(class) then return end
		if not ply:HasWeapon(class) then return end
		if not self:MedkitFits(class) then
			ply:ChatPrint("There is no room in the medkit for that.")
			return
		end

		local wep = ply:GetWeapon(class)
		if not IsValid(wep) or wep == self then return end
		local info = ReadItemState(wep)

		-- a used-up item isn't worth packing
		if istable(info) and isnumber(info[1]) and info[1] <= 0 then
			ply:ChatPrint("That one is used up.")
			return
		end

		self.MedContents[#self.MedContents + 1] = {class = class, info = info}
		if ply:GetActiveWeapon() == wep then ply:SelectWeapon(self:GetClass()) end
		ply:StripWeapon(class)
		self:SyncMedkit()
		ply:EmitSound("snd_jack_hmcd_bandage.wav", 45, math.random(90, 100), 0.4)
	end

	net.Receive("ZC_MedkitAction", function(len, ply)
		local kit = net.ReadEntity()
		local action = net.ReadUInt(2)
		local arg = net.ReadString()
		if not IsValid(kit) or kit:GetClass() ~= "weapon_medkit_sh" then return end
		if kit:GetOwner() ~= ply or not ply:Alive() then return end
		if (ply.NextMedkitAction or 0) > CurTime() then return end
		ply.NextMedkitAction = CurTime() + 0.15
		if not kit.MedContents then kit:FillMedkit() end

		if action == 1 then
			kit:MedkitTake(ply, tonumber(arg) or 0)
		elseif action == 2 then
			kit:MedkitStore(ply, arg)
		end
	end)

	function SWEP:PrimaryAttack()
		self:OpenMedkit()
	end

	function SWEP:SecondaryAttack()
		self:OpenMedkit()
	end

	function SWEP:Reload()
	end
else
	function SWEP:PrimaryAttack() end
	function SWEP:SecondaryAttack() end
	function SWEP:Reload() end

	-- ============================================================
	-- Medkit window
	--   left  : what's inside (click to take out)
	--   right : medical items you carry (click to pack in)
	-- ============================================================
	local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end

	local function CreateMedkitFonts()
		local s = math.min(ScrW(), ScrH()) / 1000
		surface.CreateFont("ZC_Medkit_Title", { font = "IBM Plex Mono", size = math.max(16, math.floor(26 * s)), weight = 400, antialias = true })
		surface.CreateFont("ZC_Medkit_Small", { font = "IBM Plex Mono", size = math.max(13, math.floor(18 * s)), weight = 400, antialias = true })
		surface.CreateFont("ZC_Medkit_Tiny", { font = "IBM Plex Mono", size = math.max(11, math.floor(14 * s)), weight = 400, antialias = true })
	end
	hook.Add("OnScreenSizeChanged", "ZC_Medkit_Fonts", CreateMedkitFonts)
	CreateMedkitFonts()

	local C_FRAME = Color(16, 16, 18, 240)
	local C_PANEL = Color(28, 28, 28, 180)
	local C_BTN = Color(31, 31, 31, 205)
	local C_BTN_HOVER = Color(48, 48, 48, 235)
	local C_BORDER = Color(180, 180, 180)
	local C_TEXT = Color(220, 220, 220)
	local C_DIM = Color(140, 140, 140)
	local C_FILL = Color(150, 150, 154)
	local C_RED = Color(170, 70, 70)
	local SND_CLICK = "ui/rem_click.wav"

	local iconCache = {}
	local function ItemIcon(class)
		if iconCache[class] ~= nil then return iconCache[class] or nil end
		local stored = weapons.Get(class)
		local path = stored and stored.IconOverride
		local mat
		if isstring(path) and path ~= "" then
			mat = Material(path, "smooth")
		elseif stored and stored.WepSelectIcon and type(stored.WepSelectIcon) == "IMaterial" then
			mat = stored.WepSelectIcon
		end
		iconCache[class] = (mat and not mat:IsError()) and mat or false
		return iconCache[class] or nil
	end

	local function SizeText(size)
		if size == 0.5 then return "1/2 SLOT" end
		if size == 1 then return "1 SLOT" end
		return tostring(size) .. " SLOTS"
	end

	local function PaintPanel(w, h)
		surface.SetDrawColor(C_PANEL)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local function MyMedicalItems(kit)
		local list = {}
		local ply = LocalPlayer()
		for _, wep in ipairs(ply:GetWeapons()) do
			if IsValid(wep) and wep ~= kit and hg.MedkitIsMedical(wep:GetClass()) then
				local p
				local mv = wep.modeValues
				local def = wep.modeValuesdef and wep.modeValuesdef[1]
				local full = istable(def) and def[1] or def
				if istable(mv) and isnumber(mv[1]) and isnumber(full) and full > 0 then
					p = math.Clamp(math.Round(mv[1] / full * 100), 0, 100)
					if p >= 100 then p = nil end
				end
				list[#list + 1] = {c = wep:GetClass(), p = p}
			end
		end
		table.sort(list, function(a, b) return hg.MedkitItemName(a.c) < hg.MedkitItemName(b.c) end)
		return list
	end

	local function Signature(list)
		local parts = {}
		for _, item in ipairs(list) do parts[#parts + 1] = item.c .. ":" .. tostring(item.p) end
		return table.concat(parts, "|")
	end

	local function SendAction(kit, action, arg)
		net.Start("ZC_MedkitAction")
			net.WriteEntity(kit)
			net.WriteUInt(action, 2)
			net.WriteString(tostring(arg))
		net.SendToServer()
	end

	local function ItemRow(parent, item, rightText, enabled, onClick)
		local row = vgui.Create("DButton", parent)
		row:SetText("")
		row:SetTall(U(46))
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, U(5))
		row.Paint = function(self, w, h)
			local hov = enabled and self:IsHovered()
			self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, hov and 1 or 0)
			local hl = self.HoverLerp
			draw.RoundedBox(3, 0, 0, w, h, hov and C_BTN_HOVER or C_BTN)
			surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, enabled and (45 + 100 * hl) or 18)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			if hl > 0.01 then
				surface.SetDrawColor(225, 225, 225, 210 * hl)
				surface.DrawRect(0, 0, U(3), h)
			end

			local x = U(10)
			local icon = ItemIcon(item.c)
			if icon then
				local s = h - U(10)
				surface.SetDrawColor(255, 255, 255, enabled and 230 or 90)
				surface.SetMaterial(icon)
				surface.DrawTexturedRect(x, U(5), s, s)
				x = x + s + U(8)
			end

			local textCol = enabled and C_TEXT or C_DIM
			local name = string.upper(hg.MedkitItemName(item.c))
			draw.SimpleText(name, "ZC_Medkit_Small", x, h * 0.5 - U(1), textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			local sub = SizeText(hg.MedkitItemSize(item.c))
			if item.p then sub = sub .. "  /  " .. item.p .. "% LEFT" end
			draw.SimpleText(sub, "ZC_Medkit_Tiny", x, h * 0.5 + U(1), C_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			draw.SimpleText(rightText, "ZC_Medkit_Tiny", w - U(10), h * 0.5, enabled and C_TEXT or C_RED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
		row.DoClick = function()
			if not enabled then return end
			surface.PlaySound(SND_CLICK)
			onClick()
		end
		return row
	end

	local function OpenMedkitMenu(kit)
		if IsValid(hg.MedkitMenu) then hg.MedkitMenu:Remove() end

		local fw, fh = U(760), U(520)
		local frame = vgui.Create("EditablePanel")
		hg.MedkitMenu = frame
		frame:SetSize(fw, fh)
		frame:Center()
		frame:MakePopup()
		frame:SetKeyboardInputEnabled(false)
		frame.Kit = kit
		frame.OpenTime = SysTime()

		local pad = U(18)
		local headerH = U(92)
		local colW = math.floor((fw - pad * 3) / 2)
		local colH = fh - headerH - pad * 2 - U(30)

		frame.Paint = function(self, w, h)
			local a = math.Clamp((SysTime() - self.OpenTime) / 0.15, 0, 1)
			self:SetAlpha(255 * a)
			draw.RoundedBox(4, 0, 0, w, h, C_FRAME)
			surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 60)
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			draw.SimpleText("MEDKIT", "ZC_Medkit_Title", pad, pad, C_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			-- capacity bar, one segment per half slot
			local kitEnt = self.Kit
			local cap = IsValid(kitEnt) and kitEnt.MedkitCapacity or 6
			local used = IsValid(kitEnt) and kitEnt:GetMedkitUsed() or 0
			local segs = cap * 2
			local barX, barY = pad, pad + U(40)
			local barW, barH = w - pad * 2, U(14)
			local gap = U(3)
			local segW = (barW - gap * (segs - 1)) / segs
			for i = 1, segs do
				local sx = barX + (i - 1) * (segW + gap)
				local filled = i <= used * 2
				surface.SetDrawColor(filled and C_FILL or Color(40, 40, 42, 230))
				surface.DrawRect(sx, barY, segW, barH)
				surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 30)
				surface.DrawOutlinedRect(sx, barY, segW, barH, 1)
			end
			local usedText = (used % 1 == 0) and tostring(used) or string.format("%.1f", used)
			draw.SimpleText(usedText .. " / " .. cap .. " SLOTS", "ZC_Medkit_Tiny", w - pad, pad + U(6), C_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

			draw.SimpleText("IN THE MEDKIT", "ZC_Medkit_Tiny", pad, headerH - U(4), C_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("YOUR MEDICAL ITEMS", "ZC_Medkit_Tiny", pad * 2 + colW, headerH - U(4), C_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("CLICK AN ITEM TO MOVE IT  /  RMB OR ESC TO CLOSE", "ZC_Medkit_Tiny", w * 0.5, h - pad, C_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

		local left = vgui.Create("DScrollPanel", frame)
		left:SetPos(pad, headerH)
		left:SetSize(colW, colH)
		left.Paint = function(self, w, h) PaintPanel(w, h) end
		left:GetCanvas():DockPadding(U(6), U(6), U(6), U(6))
		local lbar = left:GetVBar()
		lbar:SetWide(U(4))
		lbar.Paint = function() end
		lbar.btnUp.Paint = function() end
		lbar.btnDown.Paint = function() end
		lbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(120, 120, 120, 150)) end

		local right = vgui.Create("DScrollPanel", frame)
		right:SetPos(pad * 2 + colW, headerH)
		right:SetSize(colW, colH)
		right.Paint = function(self, w, h) PaintPanel(w, h) end
		right:GetCanvas():DockPadding(U(6), U(6), U(6), U(6))
		local rbar = right:GetVBar()
		rbar:SetWide(U(4))
		rbar.Paint = function() end
		rbar.btnUp.Paint = function() end
		rbar.btnDown.Paint = function() end
		rbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(120, 120, 120, 150)) end

		local function EmptyNote(parent, text)
			local note = vgui.Create("DPanel", parent)
			note:SetTall(U(40))
			note:Dock(TOP)
			note.Paint = function(self, w, h)
				draw.SimpleText(text, "ZC_Medkit_Tiny", w * 0.5, h * 0.5, C_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		function frame:Rebuild()
			left:Clear()
			right:Clear()
			local kitEnt = self.Kit
			if not IsValid(kitEnt) then return end
			local contents = kitEnt:GetMedkitContents()
			local mine = MyMedicalItems(kitEnt)
			local used = kitEnt:GetMedkitUsed(contents)
			local cap = kitEnt.MedkitCapacity or 6

			if #contents == 0 then EmptyNote(left, "EMPTY") end
			for i, item in ipairs(contents) do
				local carrying = LocalPlayer():HasWeapon(item.c)
				ItemRow(left:GetCanvas(), item, carrying and "ALREADY CARRYING" or "TAKE  >", not carrying, function()
					SendAction(kitEnt, 1, i)
				end)
			end

			if #mine == 0 then EmptyNote(right, "NO MEDICAL ITEMS") end
			for _, item in ipairs(mine) do
				local fits = used + hg.MedkitItemSize(item.c) <= cap
				local usedUp = item.p == 0
				local label = usedUp and "USED UP" or (fits and "<  PACK" or "NO ROOM")
				ItemRow(right:GetCanvas(), item, label, fits and not usedUp, function()
					SendAction(kitEnt, 2, item.c)
				end)
			end

			self.Sig = Signature(contents) .. "#" .. Signature(mine)
		end

		frame.Think = function(self)
			local kitEnt = self.Kit
			local ply = LocalPlayer()
			if not IsValid(kitEnt) or not ply:Alive() or kitEnt:GetOwner() ~= ply then
				self:Remove()
				return
			end
			-- close if you switch away (ignore a brief switch while taking an item out)
			if ply:GetActiveWeapon() ~= kitEnt then
				self.AwaySince = self.AwaySince or SysTime()
				if SysTime() - self.AwaySince > 0.5 then
					self:Remove()
					return
				end
			else
				self.AwaySince = nil
			end
			if input.IsMouseDown(MOUSE_RIGHT) and SysTime() - self.OpenTime > 0.25 then
				self:Remove()
				return
			end
			local sig = Signature(kitEnt:GetMedkitContents()) .. "#" .. Signature(MyMedicalItems(kitEnt))
			if sig ~= self.Sig then self:Rebuild() end
		end

		frame:Rebuild()
	end

	-- ESC closes the medkit instead of opening the pause menu
	local function CloseOnEsc()
		if IsValid(hg.MedkitMenu) then
			hg.MedkitMenu:Remove()
			return false
		end
	end
	hook.Add("OnShowZCityPause", "ZC_MedkitCloseOnEsc", CloseOnEsc)
	hook.Add("OnPauseMenuShow", "ZC_MedkitCloseOnEsc", CloseOnEsc)

	net.Receive("ZC_MedkitOpen", function()
		local kit = net.ReadEntity()
		if not IsValid(kit) then return end
		-- contents may still be on their way, the window refreshes itself when they arrive
		OpenMedkitMenu(kit)
	end)
end
