-- Round commence screen.
--   left  : MODE NAME / sub-mode, then the role reveal, occupation, extra lines and objective (one after another)
--   right : your character, a black shadow until the role is revealed, then lit up doing a role pose
--   end   : white "wake up" flash that fades into the game (like arriving on the train in HL2)
--
-- Modes call hg.RoundIntro.Sync(info) every frame while their intro is running:
--   info = {
--     key        = any value unique to this round start (e.g. the start time)
--     startTime  = CurTime() the intro began
--     duration   = seconds (default 10)
--     mode       = "HOMICIDE"
--     submode    = "State of Emergency" (optional)
--     role       = "an Innocent" / "the Executioner" (optional; nil keeps the shadow + "???")
--     roleColor  = Color
--     occupation = "Doctor" (optional)
--     extra      = { {text=, color=} , ... } (optional, shown under the occupation)
--     objective  = "Survive."
--     pose       = "salute" | "scared" | "armed" | "idle"
--   }
-- The old hg.RoundStart.DrawTitle / Fade API still works and is routed through this.

hg = hg or {}
hg.RoundIntro = hg.RoundIntro or {}
local RI = hg.RoundIntro

RI.FONT = "Cascadia Code SemiLight"

local function CreateFonts()
	local s = math.min(ScrW(), ScrH()) / 1000
	surface.CreateFont("RI_Mode", { font = RI.FONT, size = math.max(24, math.floor(64 * s)), weight = 400, antialias = true, extended = true })
	surface.CreateFont("RI_SubMode", { font = RI.FONT, size = math.max(14, math.floor(26 * s)), weight = 350, antialias = true, extended = true })
	surface.CreateFont("RI_Label", { font = RI.FONT, size = math.max(12, math.floor(20 * s)), weight = 350, antialias = true, extended = true })
	surface.CreateFont("RI_Role", { font = RI.FONT, size = math.max(22, math.floor(52 * s)), weight = 400, antialias = true, extended = true })
	surface.CreateFont("RI_Line", { font = RI.FONT, size = math.max(13, math.floor(24 * s)), weight = 350, antialias = true, extended = true })
	surface.CreateFont("RI_Objective", { font = RI.FONT, size = math.max(14, math.floor(30 * s)), weight = 350, antialias = true, extended = true })
end
hook.Add("OnScreenSizeChanged", "RoundIntro_Fonts", CreateFonts)
CreateFonts()

local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end
local function smooth(x) x = math.Clamp(x, 0, 1) return x * x * (3 - 2 * x) end

-- when each piece of text comes in (seconds after the intro starts)
local T_MODE = 0.35
local T_SUBMODE = 0.95
local T_YOUARE = 1.6       -- "YOUR ROLE IS" shows up
local T_ROLE = T_YOUARE + 1 -- role (and the character) revealed 1 second later
local T_OCCUPATION = T_ROLE + 0.8
local T_EXTRA = T_ROLE + 1.3
local T_EXTRA_STEP = 0.35
local T_OBJECTIVE_AFTER = 0.5
local WAKE_TIME = 0.35     -- the white flash at the end lasts a split second
local WASH_TIME = 0.12     -- how fast the screen washes out to white right before it

------------------------------------------------------------------------
-- character on the right
------------------------------------------------------------------------
local POSE_SEQS = {
	hidden = { "idle_all_01", "idle_all_02" },
	salute = { "gesture_salute", "taunt_salute" },
	scared = { "idle_all_scared", "idle_all_cower" },
	armed  = { "menu_gman", "idle_all_01" },
	idle   = { "idle_all_01", "idle_all_02" },
}
local FACE_YAW = -35 -- negative = toward the left of the screen
local POSE_HOLD = { salute = 0.42 } -- freeze one-shot gestures at this point of the animation

local function FindSeq(ent, list)
	for _, name in ipairs(list) do
		local s = ent:LookupSequence(name)
		if s and s >= 0 then return s end
	end
	local s = ent:LookupSequence("idle_all_01")
	return (s and s >= 0) and s or 0
end

local function WeaponModelFor(ply)
	local wep = IsValid(ply) and ply:GetActiveWeapon()
	if IsValid(wep) then
		local wm = wep.WorldModel or (wep.GetWeaponWorldModel and wep:GetWeaponWorldModel())
		local cls = wep:GetClass()
		if wm and wm ~= "" and not string.find(cls, "hands", 1, true) and util.IsValidModel(wm) then
			return wm
		end
	end
	return "models/weapons/w_pistol.mdl"
end

-- worn armor, drawn the same way the player wears it
local function DrawArmorOn(mp, ent, ply)
	local armors = IsValid(ply) and ply:GetNetVar("Armor", {}) or {}
	mp.ArmorModels = mp.ArmorModels or {}
	local fem = ThatPlyIsFemale and ThatPlyIsFemale(ent) or false
	local worn = {}
	for placement, name in pairs(armors) do
		local data = name and hg.armor and hg.armor[placement] and hg.armor[placement][name]
		if not data or not data.model or data.model == "" then continue end
		worn[name] = true

		local m = mp.ArmorModels[name]
		if not IsValid(m) then
			local path = ply:GetNWString("ArmorModel" .. name, "")
			if path == "" then path = data.model end
			m = ClientsideModel(path, RENDERGROUP_OPAQUE)
			if not IsValid(m) then continue end
			m:SetNoDraw(true)
			m:SetModelScale((fem and data.femscale) or data.scale or 1)
			local mat = istable(data.material) and data.material[1] or data.material
			mat = ply:GetNWString("ArmorMaterials" .. name, mat or "")
			if mat and mat ~= "" then m:SetSubMaterial(0, mat) end
			m:SetSkin(ply:GetNWInt("ArmorSkins" .. name, 0))
			if not data.nobonemerge then m:AddEffects(EF_BONEMERGE) end
			mp.ArmorModels[name] = m
		end
		if data.toggleableVisor and hg.IsVisorLowered then
			m:SetBodygroup(0, hg.IsVisorLowered(ply, name, data) and 0 or 1)
		end

		local bone = ent:LookupBone(data.bone or "")
		local matrix = bone and ent:GetBoneMatrix(bone)
		if matrix then
			local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
			local femPos = data.femPos or vector_origin
			bonePos:Add(boneAng:Forward() * (fem and femPos[1] or 0) + boneAng:Up() * (fem and femPos[2] or 0) + boneAng:Right() * (fem and femPos[3] or 0))
			local pos, ang = LocalToWorld(data[3] or vector_origin, (fem and data.femAng) or data[4] or angle_zero, bonePos, boneAng)
			m:SetRenderOrigin(pos)
			m:SetRenderAngles(ang)
			m:SetParent(ent, bone)
			m:DrawModel()
		end
	end
	for name, m in pairs(mp.ArmorModels) do
		if not worn[name] then
			if IsValid(m) then m:Remove() end
			mp.ArmorModels[name] = nil
		end
	end
end

-- weapons you're carrying but not holding, in their holstered spot (homigrad weapons only)
local function DrawHolsteredOn(mp, ent, ply)
	if not IsValid(ply) then return end
	mp.HolsterModels = mp.HolsterModels or {}
	local active = ply:GetActiveWeapon()
	local carried = {}
	for _, wep in ipairs(ply:GetWeapons()) do
		if not IsValid(wep) or wep == active then continue end
		if not wep.holsteredBone or wep.shouldntDrawHolstered then continue end
		local path = wep.WorldModelFake or wep.WorldModel
		if not path or path == "" then continue end
		local cls = wep:GetClass()
		carried[cls] = true

		local m = mp.HolsterModels[cls]
		if not IsValid(m) then
			m = ClientsideModel(path, RENDERGROUP_OPAQUE)
			if not IsValid(m) then continue end
			m:SetNoDraw(true)
			if wep.WorldModelFake then
				if wep.FakeScale then m:SetModelScale(wep.FakeScale, 0) end
				if wep.FakeBodyGroups then m:SetBodyGroups(wep.FakeBodyGroups) end
			end
			for i = 0, 6 do m:SetBodygroup(i, wep:GetBodygroup(i)) end
			mp.HolsterModels[cls] = m
		end

		local bone = ent:LookupBone(wep.holsteredBone)
		local matrix = bone and ent:GetBoneMatrix(bone)
		if matrix then
			local hp, ha = LocalToWorld(wep.holsteredPos or vector_origin, wep.holsteredAng or angle_zero, matrix:GetTranslation(), matrix:GetAngles())
			local pos, ang = LocalToWorld(wep.WorldPos or vector_origin, wep.WorldAng or angle_zero, hp, ha)
			if wep.WorldModelFake and wep.FakePos then
				pos, ang = LocalToWorld(wep.FakePos, wep.FakeAng or angle_zero, pos, ang)
			end
			m:SetRenderOrigin(pos)
			m:SetRenderAngles(ang)
			m:DrawModel()
		end
	end
	for cls, m in pairs(mp.HolsterModels) do
		if not carried[cls] then
			if IsValid(m) then m:Remove() end
			mp.HolsterModels[cls] = nil
		end
	end
end

local function BuildCharacter(parent, ply)
	local mp = vgui.Create("DModelPanel", parent)
	mp:SetMouseInputEnabled(false)
	mp:SetModel(IsValid(ply) and ply:GetModel() or "models/player/group01/male_07.mdl")
	mp:SetFOV(26)
	mp:SetCamPos(Vector(135, 0, 42))
	mp:SetLookAt(Vector(0, 0, 37))
	mp.Lit = 0
	mp.Pose = "hidden"
	mp.Frozen = true

	function mp:SetPose(pose)
		if self.Pose == pose then return end
		self.Frozen = (pose == "hidden")
		self.Pose = pose
		self.SeqApplied = nil
		if IsValid(self.Gun) then self.Gun:Remove() self.Gun = nil end
	end

	function mp:LayoutEntity(e)
		if IsValid(ply) then
			if e:GetModel() ~= ply:GetModel() then e:SetModel(ply:GetModel()) self.SeqApplied = nil end
			e:SetSkin(ply:GetSkin())
			for i = 0, (ply:GetNumBodyGroups() or 1) - 1 do e:SetBodygroup(i, ply:GetBodygroup(i)) end
			for i = 0, 31 do
				local sm = ply:GetSubMaterial(i)
				if sm and sm ~= "" then e:SetSubMaterial(i, sm) end
			end
			e.GetPlayerColor = function() return IsValid(ply) and ply:GetPlayerColor() or Vector(1, 1, 1) end
		end

		if not self.SeqApplied then
			e:ResetSequence(FindSeq(e, POSE_SEQS[self.Pose] or POSE_SEQS.idle))
			e:SetCycle(0)
			self.SeqApplied = true
		end
		local hold = POSE_HOLD[self.Pose]
		if self.Frozen then
			e:SetCycle(0)
			e:FrameAdvance(0)
		elseif not hold or e:GetCycle() < hold then
			e:FrameAdvance(RealFrameTime())
		end
		-- always face 35 degrees toward the left of the screen (toward the center): some animations
		-- turn the body, so measure where the hips point and counter-rotate the model to keep them there
		local yaw = self.BodyYaw or FACE_YAW
		e:SetAngles(Angle(0, yaw, 0))
		e:SetupBones()
		local pelvis = e:LookupBone("ValveBiped.Bip01_Pelvis")
		local pm = pelvis and e:GetBoneMatrix(pelvis)
		if pm then
			local rel = math.NormalizeAngle(pm:GetAngles().y - yaw)
			if self.Frozen and not self.PelvisRef then self.PelvisRef = rel end
			if self.PelvisRef then
				self.BodyYaw = math.NormalizeAngle(FACE_YAW - (rel - self.PelvisRef))
				e:SetAngles(Angle(0, self.BodyYaw, 0))
			end
		end
		e:SetPoseParameter("head_yaw", 0)
		e:SetPoseParameter("body_yaw", 0)
		e:SetPoseParameter("aim_yaw", 0)

		-- light: black shadow until revealed, then a quick flicker up to full
		local f = self.Lit
		self:SetAmbientLight(Color(40 * f, 40 * f, 46 * f))
		self:SetDirectionalLight(BOX_TOP, Color(250 * f, 246 * f, 236 * f))
		self:SetDirectionalLight(BOX_FRONT, Color(165 * f, 165 * f, 170 * f))
		self:SetDirectionalLight(BOX_RIGHT, Color(70 * f, 70 * f, 80 * f))
		self:SetDirectionalLight(BOX_LEFT, Color(110 * f, 110 * f, 125 * f))
		self:SetDirectionalLight(BOX_BACK, Color(60 * f, 60 * f, 70 * f))
	end

	function mp:PreDrawModel(e)
		if self.Lit <= 0.01 then
			render.SuppressEngineLighting(true)
			render.SetColorModulation(0, 0, 0)
		end
	end

	function mp:PostDrawModel(e)
		-- armor + holstered weapons (still black while the character is a shadow)
		if self.Lit > 0.01 then
			DrawArmorOn(self, e, ply)
			DrawHolsteredOn(self, e, ply)
		end

		if self.Lit <= 0.01 then
			render.SetColorModulation(1, 1, 1)
			render.SuppressEngineLighting(false)
		end
		-- accessories
		local acc = IsValid(ply) and ply.GetNetVar and ply:GetNetVar("Accessories")
		if self.Lit > 0.01 and istable(acc) and hg.Accessories and DrawAccesories then
			for _, a in ipairs(acc) do
				local d = hg.Accessories[a]
				if d then DrawAccesories(e, e, a, d, false, true) end
			end
		end
	end

	function mp:OnRemove()
		if IsValid(self.Gun) then self.Gun:Remove() end
		for _, m in pairs(self.ArmorModels or {}) do if IsValid(m) then m:Remove() end end
		for _, m in pairs(self.HolsterModels or {}) do if IsValid(m) then m:Remove() end end
	end

	return mp
end

------------------------------------------------------------------------
-- the screen
------------------------------------------------------------------------
local function TypeOut(text, t, speed)
	if t <= 0 then return "" end
	local n = math.min(#text, math.floor(t * (speed or 40)))
	return text:sub(1, n)
end

local function DrawFaded(text, font, x, y, col, a, xa, ya)
	draw.SimpleText(text, font, x, y, Color(col.r, col.g, col.b, a), xa or TEXT_ALIGN_LEFT, ya or TEXT_ALIGN_TOP)
end

-- word-wrap so text never goes past maxW; returns a list of lines
local function Wrap(text, font, maxW)
	surface.SetFont(font)
	local lines, cur = {}, ""
	for word in string.gmatch(text or "", "%S+") do
		local try = cur == "" and word or (cur .. " " .. word)
		if surface.GetTextSize(try) > maxW and cur ~= "" then
			lines[#lines + 1] = cur
			cur = word
		else
			cur = try
		end
	end
	if cur ~= "" then lines[#lines + 1] = cur end
	return lines
end

-- draws wrapped text, optionally typed out (chars shown so far); returns the height used
local function DrawWrapped(text, font, x, y, maxW, col, a, typed, lineH)
	local lines = Wrap(text, font, maxW)
	local left = typed or math.huge
	for i, line in ipairs(lines) do
		if left <= 0 then break end
		local shown = left >= #line and line or line:sub(1, left)
		DrawFaded(shown, font, x, y + (i - 1) * lineH, col, a)
		left = left - #line - 1
	end
	return #lines * lineH
end

local function Close()
	if IsValid(RI.Panel) then RI.Panel:Remove() end
	RI.Panel = nil
	RI.Key = nil
end

local function BeginWake()
	RI.WakeStart = CurTime()
end

function RI.Sync(info)
	if not info then return end
	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	local duration = info.duration or 10
	local startTime = info.startTime or CurTime()
	local t = CurTime() - startTime

	if t >= duration then
		if RI.Key ~= nil and RI.Key == info.key then
			Close()
			BeginWake()
			RI.FinishedKey = info.key
		end
		return
	end

	if RI.FinishedKey ~= nil and RI.FinishedKey == info.key then return end

	if RI.Key ~= info.key or not IsValid(RI.Panel) then
		Close()
		RI.Key = info.key
		RI.WakeStart = nil

		local pnl = vgui.Create("DPanel")
		pnl:SetPos(0, 0)
		pnl:SetSize(ScrW(), ScrH())
		pnl:SetMouseInputEnabled(false)
		pnl:SetKeyboardInputEnabled(false)
		pnl:ParentToHUD()
		RI.Panel = pnl

		local charW, charH = math.floor(ScrW() * 0.4), math.floor(ScrH() * 0.96)
		pnl.Char = BuildCharacter(pnl, lp)
		pnl.Char:SetPos(ScrW() - charW - math.floor(ScrW() * 0.08), ScrH() - charH)
		pnl.Char:SetSize(charW, charH)

		pnl.Paint = function(self, w, h)
			local inf = self.Info
			if not inf then return end
			local tt = CurTime() - inf.startTime
			local dur = inf.duration or 10
			local out = smooth((dur - tt) / 1.2)

			-- background
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, w, h)

			-- soft light behind the character so the shadow reads
			local cx = self.Char:GetX() + self.Char:GetWide() / 2
			local glow = 0.35 + 0.65 * (self.Char.Lit or 0)
			for i = 8, 1, -1 do
				local k = i / 8
				draw.NoTexture()
				surface.SetDrawColor(70, 70, 78, 9 * glow)
				local rx, ry = w * 0.22 * k, h * 0.42 * k
				local poly = {}
				for s = 0, 31 do
					local ang = (s / 32) * math.pi * 2
					poly[#poly + 1] = { x = cx + math.cos(ang) * rx, y = h * 0.55 + math.sin(ang) * ry }
				end
				surface.DrawPoly(poly)
			end

			local x = U(28)                  -- hug the left edge of the screen
			local maxW = w * 0.5 - x - U(10) -- never past the left half
			local white = Color(240, 240, 240)
			local dim = Color(150, 150, 150)

			-- mode name + sub mode
			local modeY = math.floor(h * 0.24)
			local modeText = string.upper(inf.mode or "")
			DrawFaded(TypeOut(modeText, tt - T_MODE, 30), "RI_Mode", x, modeY, white, 255 * out)
			if inf.submode and inf.submode ~= "" then
				local a = smooth((tt - T_SUBMODE) / 0.5) * 255 * out
				DrawFaded(inf.submode, "RI_SubMode", x + U(4), modeY + U(72), dim, a)
			end

			-- role reveal
			local roleY = math.floor(h * 0.47)
			local revealed = inf.role and inf.role ~= ""
			local la = smooth((tt - T_YOUARE) / 0.4) * 255 * out
			DrawFaded("YOUR ROLE IS", "RI_Label", x + U(4), roleY - U(26), dim, la)
			if revealed and tt >= T_ROLE then
				local p = smooth((tt - T_ROLE) / 0.45)
				local col = inf.roleColor or white
				DrawFaded(string.upper(inf.role), "RI_Role", x - (1 - p) * U(60), roleY, col, 255 * p * out)
			else
				local blink = (math.floor(CurTime() * 2) % 2 == 0) and 255 or 120
				DrawFaded("???", "RI_Role", x, roleY, dim, math.min(la, blink * out))
				revealed = false
			end

			-- occupation, extra lines, objective
			local y = roleY + U(70)
			local nextT = T_OCCUPATION
			if revealed and inf.occupation and inf.occupation ~= "" then
				local a = smooth((tt - nextT) / 0.4) * 255 * out
				y = y + DrawWrapped("OCCUPATION: " .. string.upper(inf.occupation), "RI_Line", x + U(4), y, maxW, Color(200, 200, 200), a, nil, U(30)) + U(4)
				nextT = nextT + 0.5
			end
			if revealed and inf.extra then
				nextT = math.max(nextT, T_EXTRA)
				for _, line in ipairs(inf.extra) do
					local a = smooth((tt - nextT) / 0.4) * 255 * out
					y = y + DrawWrapped(line.text or "", "RI_Line", x + U(4), y, maxW, line.color or Color(200, 200, 200), a, nil, U(30))
					nextT = nextT + T_EXTRA_STEP
				end
			end
			local willReveal = inf.role and inf.role ~= ""
			if inf.objective and inf.objective ~= "" and (revealed or not willReveal) then
				local objT = revealed and (nextT + T_OBJECTIVE_AFTER - 0.35) or (T_YOUARE + 0.6)
				y = y + U(18)
				surface.SetDrawColor(255, 255, 255, 40 * smooth((tt - objT) / 0.4) * out)
				surface.DrawRect(x + U(4), y, U(260), 1)
				local typed = math.max(0, math.floor((tt - objT) * 55))
				DrawWrapped(inf.objective, "RI_Objective", x + U(4), y + U(14), maxW, white, 255 * out, typed, U(36))
			end

			-- last moment: wash out to white, the wake-up fade takes it from there
			local wa = smooth((tt - (dur - WASH_TIME)) / WASH_TIME)
			if wa > 0 then
				surface.SetDrawColor(255, 255, 255, 255 * wa)
				surface.DrawRect(0, 0, w, h)
			end
		end

		pnl.Think = function(self)
			local inf = self.Info
			if not inf then return end
			local tt = CurTime() - inf.startTime
			local revealed = inf.role and inf.role ~= ""
			self.Char:SetPose((revealed and tt >= T_ROLE) and (inf.pose or "idle") or "hidden")

			-- reveal: flicker on, then full light
			local target = 0
			if revealed and tt >= T_ROLE then
				local rt = tt - T_ROLE
				if rt < 0.35 then
					if CurTime() > (self.FlickNext or 0) then
						self.FlickNext = CurTime() + math.Rand(0.03, 0.08)
						self.Flick = math.random() < 0.45 and 0.1 or 1
					end
					target = smooth(rt / 0.5) * (self.Flick or 1)
				else
					target = smooth(rt / 0.5)
				end
				if not self.RevealSound then
					self.RevealSound = true
					surface.PlaySound("rem_newroundreveal.wav")
					surface.PlaySound("buttons/lightswitch2.wav")
				end
			end
			self.Char.Lit = target

			-- done: close and start the wake-up fade
			if tt >= (inf.duration or 10) then
				RI.FinishedKey = RI.Key
				Close()
				BeginWake()
			end
		end
	end

	RI.Panel.Info = info
end

function RI.IsActive()
	return IsValid(RI.Panel)
end

function RI.Stop()
	Close()
end

-- white "wake up" fade into the game, drawn over the world after the screen closes
local blurMat = Material("pp/blurscreen")
hook.Add("HUDPaint", "RoundIntro_Wake", function()
	if not RI.WakeStart then return end
	local p = (CurTime() - RI.WakeStart) / WAKE_TIME
	if p >= 1 then RI.WakeStart = nil return end
	local w, h = ScrW(), ScrH()
	local k = 1 - smooth(p)

	-- brief blur that clears up
	surface.SetMaterial(blurMat)
	surface.SetDrawColor(255, 255, 255, 255)
	for i = 1, 2 do
		blurMat:SetFloat("$blur", (i / 2) * 4 * k)
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(0, 0, w, h)
	end

	-- white flash fading out
	surface.SetDrawColor(255, 255, 255, 255 * k)
	surface.DrawRect(-1, -1, w + 2, h + 2)
end)

hook.Add("RenderScreenspaceEffects", "RoundIntro_Wake", function()
	if not RI.WakeStart then return end
	local p = math.Clamp((CurTime() - RI.WakeStart) / WAKE_TIME, 0, 1)
	local k = 1 - smooth(p)
	DrawColorModify({
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = 0.15 * k,
		["$pp_colour_contrast"] = 1 + 0.2 * k,
		["$pp_colour_colour"] = 1 - 0.7 * k,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0,
	})
end)

------------------------------------------------------------------------
-- old title card API, routed through the new screen
------------------------------------------------------------------------
hg.RoundStart = hg.RoundStart or {}
local RS = hg.RoundStart
RS.duration = RS.duration or 10
RS.sound = RS.sound or "rem_newroundcommence.mp3"
RS.soundEnabled = RS.soundEnabled or false

local POSE_WORDS = {
	salute = { "swat", "police", "sobr", "forces", "officer", "soldier", "military", "guard", "cop", "operator", "hero", "judge", "combine", "national" },
	armed = { "terror", "robber", "criminal", "traitor", "executioner", "gang", "trinity", "shooter", "rebel", "killer", "zoo" },
}
function RI.GuessPose(text)
	text = string.lower(text or "")
	for pose, words in pairs(POSE_WORDS) do
		for _, w in ipairs(words) do
			if string.find(text, w, 1, true) then return pose end
		end
	end
	return "idle"
end

local soundObj, soundKey
function hg.RoundStart.DrawTitle(content, opts)
	opts = opts or {}
	local lp = LocalPlayer()
	if not IsValid(lp) or lp:Team() == TEAM_SPECTATOR then return end
	content = content or {}
	local startTime = opts.startTime or zb.ROUND_START or CurTime()
	local duration = opts.duration or RS.duration
	if zb.RemoveFade then zb.RemoveFade() end

	local role, roleColor
	local extra = {}
	for i, line in ipairs(content.lines or {}) do
		if i == 1 then
			role = string.gsub(line.text or "", "^[Yy]ou are%s+", "")
			roleColor = line.color or content.color
		else
			extra[#extra + 1] = { text = line.text, color = line.color }
		end
	end

	if (opts.sound or RS.soundEnabled) and soundKey ~= startTime and RS.sound and RS.sound ~= "" then
		soundKey = startTime
		if soundObj then soundObj:Stop() end
		soundObj = CreateSound(lp, RS.sound)
		if soundObj then soundObj:PlayEx(1, 100) end
	end
	if soundObj then
		local t = CurTime() - startTime
		soundObj:ChangeVolume(math.Clamp((duration - t) / 1.5, 0, 1), 0)
	end

	RI.Sync({
		key = startTime,
		startTime = startTime,
		duration = duration,
		mode = content.header or "",
		submode = content.submode,
		role = role,
		roleColor = roleColor,
		extra = extra,
		objective = content.objective,
		pose = content.pose or RI.GuessPose(role),
	})
end

-- the new screen draws its own black background, so the old fade only covers the gap before it opens
function hg.RoundStart.Fade(opts)
	if RI.IsActive() or RI.WakeStart then return end
	opts = opts or {}
	local startTime = opts.startTime or zb.ROUND_START or CurTime()
	local duration = opts.duration or RS.duration
	local time_diff = (startTime + duration) - CurTime()
	if time_diff <= 0 then return end
	surface.SetDrawColor(0, 0, 0, 255 * math.min(time_diff / 2.5, 1))
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end
