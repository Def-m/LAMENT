if CLIENT then
	-- ============================================================
	-- Inventory: ammo + equipment + injuries, styled like the attachments menu
	--   left   : ammo list, drop / drop all, count slider
	--   middle : your character (fitted to its box), with markers on injuries
	--   right  : armor slots + other equipment, and the injury list (linked to the markers)
	-- ============================================================

	local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end

	local function CreateInvFonts()
		local s = math.min(ScrW(), ScrH()) / 1000
		surface.CreateFont("ZCity_Inv_Title", { font = "IBM Plex Mono", size = math.max(16, math.floor(26 * s)), weight = 400, antialias = true })
		surface.CreateFont("ZCity_Inv_Small", { font = "IBM Plex Mono", size = math.max(13, math.floor(18 * s)), weight = 400, antialias = true })
		surface.CreateFont("ZCity_Inv_Tiny", { font = "IBM Plex Mono", size = math.max(11, math.floor(14 * s)), weight = 400, antialias = true })
	end
	hook.Add("OnScreenSizeChanged", "ZCity_Inv_Fonts", CreateInvFonts)
	CreateInvFonts()

	-- palette shared with the other menus
	local C_FRAME = Color(16, 16, 18, 240)
	local C_PANEL = Color(28, 28, 28, 180)
	local C_BTN = Color(31, 31, 31, 205)
	local C_BTN_HOVER = Color(48, 48, 48, 235)
	local C_BTN_ACTIVE = Color(58, 58, 58, 235)
	local C_BORDER = Color(180, 180, 180)
	local C_TEXT = Color(220, 220, 220)
	local C_TEXT_IDLE = Color(188, 188, 188)
	local C_DIM = Color(140, 140, 140)
	local C_WHITE = Color(240, 240, 240)
	local C_ACCENT = Color(225, 225, 225)
	local C_GREEN = Color(115, 115, 118)      -- slider fill (gray)
	local C_GREEN_DARK = Color(62, 62, 66)    -- slider border
	local SND_CLICK = "ui/rem_click.wav"

	local EXTRA_EQUIPMENT = {
		{ id = "hg_flashlight", name = "Flashlight" },
		{ id = "hg_sling", name = "Sling" },
		{ id = "hg_brassknuckles", name = "Brass Knuckles" },
	}
	local ARMOR_SLOTS = {
		{ placement = "head", label = "HEAD" },
		{ placement = "torso", label = "TORSO" },
		{ placement = "face", label = "FACE" },
	}

	local iconCache = {}
	local function GetIcon(name)
		local path = hg.armorIcons and hg.armorIcons[name]
		if not path then return end
		if iconCache[path] == nil then
			local m = Material(path, "smooth")
			iconCache[path] = (m and not m:IsError()) and m or false
		end
		return iconCache[path] or nil
	end

	local function ArmorName(name)
		return (hg.armorNames and hg.armorNames[name]) or string.NiceName(tostring(name or ""))
	end

	local function PaintPanel(w, h)
		surface.SetDrawColor(C_PANEL)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local function PaintButtonBase(self, w, h, active, enabled)
		local hov = enabled ~= false and self:IsHovered()
		self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, hov and 1 or 0)
		local hl = self.HoverLerp
		draw.RoundedBox(3, 0, 0, w, h, active and C_BTN_ACTIVE or (hov and C_BTN_HOVER or C_BTN))
		surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, enabled == false and 20 or (active and 145 or 45 + 100 * hl))
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		if active or hl > 0.01 then
			surface.SetDrawColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, active and 210 or 210 * hl)
			surface.DrawRect(0, 0, U(3), h)
		end
		return hov
	end

	local function MakeTextButton(parent, label, onClick, isEnabled)
		local btn = vgui.Create("DButton", parent)
		btn:SetText("")
		btn.Paint = function(self, w, h)
			local enabled = not isEnabled or isEnabled()
			local hov = PaintButtonBase(self, w, h, false, enabled)
			local c = not enabled and Color(80, 80, 80) or (hov and C_TEXT or C_TEXT_IDLE)
			draw.SimpleText(label, "ZCity_Inv_Small", w / 2, h / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			if isEnabled and not isEnabled() then return end
			surface.PlaySound(SND_CLICK)
			onClick()
		end
		return btn
	end

	local function StyleScroll(scroll)
		scroll.Paint = function() end
		local bar = scroll:GetVBar()
		bar:SetWide(U(4))
		bar:SetHideButtons(true)
		function bar:Paint(w, h)
			surface.SetDrawColor(25, 25, 25, 200)
			surface.DrawRect(0, 0, w, h)
		end
		function bar.btnGrip:Paint(w, h)
			draw.RoundedBox(2, 0, 0, w, h, self:IsHovered() and Color(120, 120, 120) or Color(80, 80, 80))
		end
	end

	-- what the player is carrying right now
	local function GatherState(ply)
		local state = { ammo = {}, armor = {}, extra = {} }

		for id, count in pairs(ply:GetAmmo() or {}) do
			if count and count > 0 then
				state.ammo[#state.ammo + 1] = { id = id, name = game.GetAmmoName(id) or ("Ammo " .. id), count = count }
			end
		end
		table.sort(state.ammo, function(a, b) return a.name < b.name end)

		local armors = ply:GetNetVar("Armor", {}) or {}
		local slotted = {}
		for _, slot in ipairs(ARMOR_SLOTS) do
			local name = armors[slot.placement]
			if name then
				state.armor[slot.placement] = name
				slotted[slot.placement] = true
			end
		end
		for placement, name in pairs(armors) do
			if name and not slotted[placement] then
				state.extra[#state.extra + 1] = { id = name, name = ArmorName(name), icon = GetIcon(name) }
			end
		end

		local inv = ply:GetNetVar("Inventory", {}) or {}
		local weps = inv["Weapons"] or {}
		for _, e in ipairs(EXTRA_EQUIPMENT) do
			if weps[e.id] then state.extra[#state.extra + 1] = { id = e.id, name = e.name } end
		end

		local sig = {}
		for _, a in ipairs(state.ammo) do sig[#sig + 1] = a.id .. ":" .. a.count end
		for p, n in pairs(state.armor) do sig[#sig + 1] = p .. "=" .. n end
		for _, e in ipairs(state.extra) do sig[#sig + 1] = "x" .. e.id end
		table.sort(sig)
		state.signature = table.concat(sig, "|")
		return state
	end

	local function DropAmmo(id, count)
		if not id or count < 1 then return end
		net.Start("drop_ammo")
			net.WriteFloat(id)
			net.WriteFloat(count)
		net.SendToServer()
	end

	local function DropEquipment(id)
		RunConsoleCommand("hg_drop_equipment", id)
	end

	local function ArmorPlacementOf(name)
		for placement, group in pairs(hg.armor or {}) do
			if group[name] then return placement end
		end
	end

	local HEADISH = { head = true, ears = true, visor = true, helmet_jaw = true, helmet_ears = true, face = true }
	local TAKEOFF_HIDE_FRAC = 0.45 -- the piece disappears this far into the gesture

	-- same gesture the server plays when you drop armor (hg.DropArmor)
	local function TakeoffAct(placement)
		return HEADISH[placement] and ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND or ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND
	end

	local function GetPreviewArmorModel(mp, name, data, fem)
		mp.ArmorModels = mp.ArmorModels or {}
		local m = mp.ArmorModels[name]
		if IsValid(m) then return m end
		local ply = mp.Owner
		local path = IsValid(ply) and ply:GetNWString("ArmorModel" .. name, "") or ""
		if path == "" then path = data.model end
		if not path or path == "" then return end
		m = ClientsideModel(path, RENDERGROUP_OPAQUE)
		if not IsValid(m) and data.model then m = ClientsideModel(data.model, RENDERGROUP_OPAQUE) end
		if not IsValid(m) then return end
		m:SetNoDraw(true)
		m:SetModelScale((fem and data.femscale) or data.scale or 1)
		local mat = istable(data.material) and data.material[1] or data.material
		mat = IsValid(ply) and ply:GetNWString("ArmorMaterials" .. name, mat or "") or mat
		if mat and mat ~= "" then m:SetSubMaterial(0, mat) end
		if IsValid(ply) then m:SetSkin(ply:GetNWInt("ArmorSkins" .. name, 0)) end
		m.HGBonemerge = not data.nobonemerge
		mp.ArmorModels[name] = m
		return m
	end

	-- draws one armor piece on the preview model, optionally partway through being taken off
	local function DrawPreviewArmor(mp, ent, placement, name, takeoff)
		local group = hg.armor and hg.armor[placement]
		local data = group and group[name]
		if not data or not data.model or data.model == "" then return end

		local fem = ThatPlyIsFemale and ThatPlyIsFemale(ent) or false
		local m = GetPreviewArmorModel(mp, name, data, fem)
		if not IsValid(m) then return end

		if data.toggleableVisor and hg.IsVisorLowered and IsValid(mp.Owner) then
			m:SetBodygroup(0, hg.IsVisorLowered(mp.Owner, name, data) and 0 or 1)
		end

		if takeoff and CurTime() >= takeoff then return end

		local bone = ent:LookupBone(data.bone or "")
		local matrix = bone and ent:GetBoneMatrix(bone)
		if not matrix then return end
		local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
		local femPos = data.femPos or vector_origin
		bonePos:Add(boneAng:Forward() * (fem and femPos[1] or 0) + boneAng:Up() * (fem and femPos[2] or 0) + boneAng:Right() * (fem and femPos[3] or 0))
		local pos, ang = LocalToWorld(data[3] or vector_origin, (fem and data.femAng) or data[4] or angle_zero, bonePos, boneAng)
		if m.HGBonemerge then m:AddEffects(EF_BONEMERGE) end
		m:SetRenderOrigin(pos)
		m:SetRenderAngles(ang)
		m:SetParent(ent, bone)
		m:DrawModel()
	end

	-- live preview of the local player
	local function BuildCharacterPreview(parent, ply)
		local mp = vgui.Create("DModelPanel", parent)
		mp.Owner = ply
		mp.TakingOff = {}
		mp:SetModel(ply:GetModel())
		mp:SetFOV(32)
		mp:SetCamPos(Vector(120, 0, 40))
		mp:SetLookAt(Vector(0, 0, 37))
		mp:SetAmbientLight(Color(60, 60, 66))
		mp:SetDirectionalLight(BOX_TOP, Color(230, 228, 220))
		mp:SetDirectionalLight(BOX_FRONT, Color(160, 160, 165))
		mp:SetDirectionalLight(BOX_RIGHT, Color(80, 80, 90))
		mp:SetDirectionalLight(BOX_LEFT, Color(70, 70, 82))
		mp.Yaw = 15
		mp.Dragging = false

		local ent = mp.Entity
		if IsValid(ent) and hg.SetupPreviewModel then hg.SetupPreviewModel(ent, ply) end

		function mp:LayoutEntity(e)
			if not IsValid(ply) then return end
			if e:GetModel() ~= ply:GetModel() then e:SetModel(ply:GetModel()) self.SeqSet = nil end
			e:SetSkin(ply:GetSkin())
			for i = 0, (ply:GetNumBodyGroups() or 1) - 1 do
				e:SetBodygroup(i, ply:GetBodygroup(i))
			end
			for i = 0, 31 do
				e:SetSubMaterial(i, ply:GetSubMaterial(i) or "")
			end
			-- clothing colors, masks and accessory colors come from the real player
			-- (see hg.SetupPreviewModel in new_appearance/cl_init.lua)
			if hg.SetupPreviewModel then hg.SetupPreviewModel(e, ply) end
			if self.Gesture then
				-- playing the drop gesture
				if not self.Gesture.started then
					e:ResetSequence(self.Gesture.seq)
					e:SetCycle(0)
					e:SetPlaybackRate(1)
					self.Gesture.started = true
				end
				if CurTime() >= self.Gesture.finish then
					self.Gesture = nil
					self.SeqSet = nil
				end
			end
			if not self.Gesture and not self.SeqSet then
				local seq = e:LookupSequence("menu_combine")
				if not seq or seq < 0 then seq = e:LookupSequence("idle_all_01") end
				if seq and seq >= 0 then e:ResetSequence(seq) end
				self.SeqSet = true
			end
			e:FrameAdvance(RealFrameTime())
			if self.Dragging then
				local mx = gui.MouseX()
				self.Yaw = self.Yaw + (mx - (self.LastMX or mx)) * 0.6
				self.LastMX = mx
			end
			e:SetAngles(Angle(0, self.Yaw, 0))
		end

		-- start the take-off animation for a piece (called when you drop it from the menu)
		function mp:TakeOff(name)
			local placement = ArmorPlacementOf(name)
			local e = self.Entity
			local dur = 0.6
			if IsValid(e) then
				local seq = e:SelectWeightedSequence(TakeoffAct(placement or "torso"))
				if seq and seq >= 0 then
					dur = math.max(e:SequenceDuration(seq), 0.3)
					self.Gesture = { seq = seq, finish = CurTime() + dur }
				end
			end
			if placement then
				self.TakingOff[name] = { placement = placement, start = CurTime() + dur * TAKEOFF_HIDE_FRAC, finish = CurTime() + dur }
			end
		end

		function mp:OnRemove()
			-- this replaces DModelPanel's own OnRemove, so the preview model has to be removed here too
			if IsValid(self.Entity) then self.Entity:Remove() end
			for _, m in pairs(self.ArmorModels or {}) do
				if IsValid(m) then m:Remove() end
			end
		end

		-- amputated limbs: run the game's own gore pass on the preview so missing limbs are gone and
		-- the stumps show, exactly like on the real body
		local noRagdoll = {} -- stand-in for the player so the gore pass never touches the real one
		local AMPUTATION_BONES = {
			lleg = "ValveBiped.Bip01_L_Calf", rleg = "ValveBiped.Bip01_R_Calf",
			larm = "ValveBiped.Bip01_L_Forearm", rarm = "ValveBiped.Bip01_R_Forearm",
			lhand = "ValveBiped.Bip01_L_Hand", rhand = "ValveBiped.Bip01_R_Hand",
			llegup = "ValveBiped.Bip01_L_Thigh", rlegup = "ValveBiped.Bip01_R_Thigh",
			larmup = "ValveBiped.Bip01_L_UpperArm", rarmup = "ValveBiped.Bip01_R_UpperArm",
		}
		function mp:PreDrawModel(e)
			if not IsValid(ply) then return end
			e.organism = ply.organism
			local org = ply.organism
			if not org then return end
			if hg.GoreCalc then
				e:SetupBones()
				hg.GoreCalc(e, noRagdoll)
			else
				-- fallback: just shrink the missing limbs away at the joint
				for limb, boneName in pairs(AMPUTATION_BONES) do
					local b = e:LookupBone(boneName)
					if b and b >= 0 then
						e:ManipulateBoneScale(b, org[limb .. "amputated"] and Vector(0.01, 0.01, 0.01) or Vector(1, 1, 1))
					end
				end
			end
		end

		function mp:PostDrawModel(e)
			-- worn armor
			local armors = IsValid(ply) and ply:GetNetVar("Armor", {}) or {}
			local drawn = {}
			for placement, name in pairs(armors) do
				if name then
					local t = self.TakingOff[name]
					DrawPreviewArmor(self, e, placement, name, t and t.start)
					drawn[name] = true
				end
			end
			-- pieces already removed on the server but still finishing their take-off animation
			for name, t in pairs(self.TakingOff) do
				if CurTime() > t.finish then
					self.TakingOff[name] = nil
					if not drawn[name] and self.ArmorModels and IsValid(self.ArmorModels[name]) then
						self.ArmorModels[name]:Remove()
						self.ArmorModels[name] = nil
					end
				elseif not drawn[name] then
					DrawPreviewArmor(self, e, t.placement, name, t.start)
				end
			end
			-- drop cached models for pieces no longer worn
			for name, m in pairs(self.ArmorModels or {}) do
				if not drawn[name] and not self.TakingOff[name] then
					if IsValid(m) then m:Remove() end
					self.ArmorModels[name] = nil
				end
			end

			local acc = IsValid(ply) and ply.GetNetVar and ply:GetNetVar("Accessories")
			if istable(acc) and hg and hg.Accessories and DrawAccesories then
				for _, a in ipairs(acc) do
					local d = hg.Accessories[a]
					if d then DrawAccesories(e, e, a, d, false, true) end
				end
			end
		end

		function mp:OnMousePressed(code)
			if code == MOUSE_LEFT then
				self.Dragging = true
				self.LastMX = gui.MouseX()
				self:MouseCapture(true)
			end
		end
		function mp:OnMouseReleased(code)
			if code == MOUSE_LEFT then
				self.Dragging = false
				self:MouseCapture(false)
			end
		end

		return mp
	end

	------------------------------------------------------------------
	-- injuries (read from the organism the server sends you)
	------------------------------------------------------------------
	local LIMB_BONES = {
		lleg = "ValveBiped.Bip01_L_Calf", rleg = "ValveBiped.Bip01_R_Calf",
		larm = "ValveBiped.Bip01_L_Forearm", rarm = "ValveBiped.Bip01_R_Forearm",
	}
	local LIMB_NAMES = { lleg = "LEFT LEG", rleg = "RIGHT LEG", larm = "LEFT ARM", rarm = "RIGHT ARM" }
	local BONE_HEAD, BONE_NECK = "ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Neck1"
	local BONE_CHEST, BONE_SPINE, BONE_PELVIS = "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Pelvis"

	-- which part of the body a bone belongs to (for grouping open wounds)
	local function RegionOf(bone)
		bone = tostring(bone or "")
		if bone:find("Head") or bone:find("Neck") then return "head", "HEAD" end
		if bone:find("L_Upper") or bone:find("L_Fore") or bone:find("L_Hand") or bone:find("L_Finger") or bone:find("L_Clav") then return "larm", "LEFT ARM" end
		if bone:find("R_Upper") or bone:find("R_Fore") or bone:find("R_Hand") or bone:find("R_Finger") or bone:find("R_Clav") then return "rarm", "RIGHT ARM" end
		if bone:find("L_Thigh") or bone:find("L_Calf") or bone:find("L_Foot") or bone:find("L_Toe") then return "lleg", "LEFT LEG" end
		if bone:find("R_Thigh") or bone:find("R_Calf") or bone:find("R_Foot") or bone:find("R_Toe") then return "rleg", "RIGHT LEG" end
		return "torso", "TORSO"
	end

	-- { id, part, text, bone, lpos (optional, offset from bone), sev 0-1 }
	local function GatherInjuries(ply)
		local list = {}
		local org = ply.organism or {}
		local function add(id, part, text, bone, sev, lpos, lang)
			list[#list + 1] = { id = id, part = part, text = text, bone = bone, sev = math.Clamp(sev or 0.5, 0, 1), lpos = lpos, lang = lang }
		end
		local function num(k) return tonumber(org[k]) or 0 end

		for limb, bone in pairs(LIMB_BONES) do
			local splinted = istable(org.splints) and org.splints[limb]
			if org[limb .. "amputated"] or org[limb .. "upamputated"] then
				add(limb .. "_amp", LIMB_NAMES[limb], "AMPUTATED", bone, 1)
			else
				local v = num(limb)
				if v >= 1 then add(limb, LIMB_NAMES[limb], splinted and "BROKEN  (SPLINTED)" or "BROKEN", bone, 1)
				elseif v >= 0.3 then add(limb, LIMB_NAMES[limb], splinted and "FRACTURED  (SPLINTED)" or "FRACTURED", bone, v)
				elseif v >= 0.08 then add(limb, LIMB_NAMES[limb], "BRUISED", bone, v) end
				if org[limb .. "dislocation"] then add(limb .. "_dis", LIMB_NAMES[limb], "DISLOCATED", bone, 0.6) end
				if num(limb .. "artery") > 0 then add(limb .. "_art", LIMB_NAMES[limb], "SEVERED ARTERY", bone, 1) end
			end
		end
		for _, h in ipairs({ "l", "r" }) do
			if org[h .. "handamputated"] then
				add(h .. "hand_amp", h == "l" and "LEFT HAND" or "RIGHT HAND", "AMPUTATED", "ValveBiped.Bip01_" .. string.upper(h) .. "_Hand", 1)
			end
		end

		-- only things you could see by looking at someone: breaks, dislocations, amputations, bleeding.
		-- internal damage (skull, brain, ribs, lungs, spine, pelvis, internal bleeding...) stays hidden.
		if num("jaw") >= 0.5 then add("jaw", "JAW", "BROKEN JAW", BONE_HEAD, num("jaw"))
		elseif org.jawdislocation then add("jaw", "JAW", "DISLOCATED", BONE_HEAD, 0.5) end
		if num("eyeL") >= 0.5 then add("eyeL", "LEFT EYE", "INJURED", BONE_HEAD, num("eyeL")) end
		if num("eyeR") >= 0.5 then add("eyeR", "RIGHT EYE", "INJURED", BONE_HEAD, num("eyeR")) end
		if num("arteria") > 0 then add("arteria", "NECK", "SEVERED ARTERY", BONE_NECK, 1) end

		-- open wounds, one entry per body part, marked on the first wound's exact spot
		local regions = {}
		for _, w in ipairs(ply.wounds or {}) do
			if istable(w) and (tonumber(w[1]) or 0) > 0 then
				local key, name = RegionOf(w[4])
				local r = regions[key]
				if not r then
					r = { name = name, n = 0, sev = 0, bone = w[4], lpos = w[2], lang = w[3] }
					regions[key] = r
				end
				r.n = r.n + 1
				r.sev = math.max(r.sev, math.min(tonumber(w[1]) or 0, 1))
			end
		end
		for key, r in pairs(regions) do
			add("wound_" .. key, r.name, r.n == 1 and "OPEN WOUND" or (r.n .. " OPEN WOUNDS"), r.bone, math.max(r.sev, 0.4), r.lpos, r.lang)
		end

		table.sort(list, function(a, b)
			if a.sev ~= b.sev then return a.sev > b.sev end
			return a.id < b.id
		end)
		return list
	end

	local function InjurySignature(list)
		local s = {}
		for _, i in ipairs(list) do s[#s + 1] = i.id .. "=" .. i.text end
		return table.concat(s, "|")
	end

	------------------------------------------------------------------
	-- attachments-menu look (same fonts, panels, corners, links, scramble)
	------------------------------------------------------------------
	local INV_FONT = "Mx437 IBM PS/55 re."
	local invUI = 1
	local function P(v) return math.max(1, math.floor(v * invUI + 0.5)) end
	local function CreateAttStyleFonts()
		invUI = math.Clamp(math.min(ScrW() / 2560, ScrH() / 1440) * 1.05, 0.5, 1.25)
		surface.CreateFont("ZCity_InvA_Title", { font = INV_FONT, size = P(28), weight = 700, antialias = true, extended = true })
		surface.CreateFont("ZCity_InvA_Label", { font = INV_FONT, size = P(17), weight = 600, antialias = true, extended = true })
		surface.CreateFont("ZCity_InvA_Small", { font = INV_FONT, size = P(13), weight = 500, antialias = true, extended = true })
		surface.CreateFont("ZCity_InvA_Card", { font = INV_FONT, size = P(11), weight = 600, antialias = true, extended = true })
		surface.CreateFont("ZCity_InvA_Micro", { font = INV_FONT, size = P(10), weight = 600, antialias = true, extended = true })
		surface.CreateFont("ZCity_InvA_Count", { font = "Courier Prime", size = P(13), weight = 400, italic = true, antialias = true, extended = true })
	end
	hook.Add("OnScreenSizeChanged", "ZCity_InvA_Fonts", CreateAttStyleFonts)
	CreateAttStyleFonts()

	local A_TEXT = Color(235, 235, 235)
	local A_MUTED = Color(145, 150, 152)
	local A_LINE = Color(255, 255, 255)
	local A_INJURY = Color(215, 85, 75)
	local gradientD = Material("vgui/gradient-d")
	local INV_GRAD_R = surface.GetTextureID("vgui/gradient-r")
	local INV_GRAD_L = surface.GetTextureID("vgui/gradient-l")

	local function Accent() return hg.theme and hg.theme.c and hg.theme.c.accent or Color(55, 55, 55) end
	local function PanelCol(a)
		local p = hg.theme and hg.theme.c and hg.theme.c.panel or Color(10, 10, 10)
		return Color(p.r, p.g, p.b, a or 212)
	end
	local function AText(text, font, x, y, col, ax, ay)
		draw.SimpleText(text, font, x + 1, y + 1, Color(10, 10, 10, 200), ax, ay)
		draw.SimpleText(text, font, x, y, col, ax, ay)
	end
	local function Corners(x, y, w, h, col, alpha)
		local inset = 4
		local len = math.min(13, math.floor(math.min(w, h) * 0.24))
		surface.SetDrawColor(col.r, col.g, col.b, alpha or 190)
		surface.DrawRect(x + inset, y + inset, len, 1)
		surface.DrawRect(x + inset, y + inset, 1, len)
		surface.DrawRect(x + w - inset - len, y + h - inset - 1, len, 1)
		surface.DrawRect(x + w - inset - 1, y + h - inset - len, 1, len)
	end
	local function Link(x1, y1, x2, y2, x3, y3, col, phase)
		surface.SetDrawColor(0, 0, 0, 190)
		for o = -1, 1 do
			surface.DrawLine(x1 + o, y1, x2 + o, y2)
			surface.DrawLine(x2, y2 + o, x3, y3 + o)
		end
		surface.SetDrawColor(col.r, col.g, col.b, 125)
		surface.DrawLine(x1, y1, x2, y2)
		surface.DrawLine(x2, y2, x3, y3)
		local l1 = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
		local l2 = math.sqrt((x3 - x2) ^ 2 + (y3 - y2) ^ 2)
		local d = phase * (l1 + l2)
		local px, py
		if d <= l1 and l1 > 0 then px, py = Lerp(d / l1, x1, x2), Lerp(d / l1, y1, y2)
		elseif l2 > 0 then px, py = Lerp((d - l1) / l2, x2, x3), Lerp((d - l1) / l2, y2, y3) end
		if px then
			surface.SetDrawColor(col.r, col.g, col.b, 230)
			surface.DrawRect(px - 2, py - 2, 4, 4)
		end
	end
	local SCRAMBLE = { "?", "%", "#", "*", "!", "/", "+", "-" }
	local function Scramble(text, started, dur)
		text = tostring(text or "")
		local n = math.floor(#text * math.Clamp((RealTime() - started) / dur, 0, 1))
		if n >= #text then return text end
		local out = text:sub(1, n)
		for i = n + 1, #text do
			local c = text:sub(i, i)
			out = out .. (c == " " and " " or SCRAMBLE[math.random(#SCRAMBLE)])
		end
		return out
	end

	-- a floating section like the attachment slot panels: header bar + body
	local function MakeSection(frame, title, side, countText, delay)
		local s = vgui.Create("DPanel", frame)
		s.side, s.title, s.countText, s.delay = side, title, countText, delay or 0
		s.scrambleStarted = frame.openedAt + s.delay
		s.Paint = function(self, w, h)
			local acc = Accent()
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(P(4), P(4), w, h)
			surface.SetDrawColor(PanelCol(218))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255, 9)
			surface.SetMaterial(gradientD)
			surface.DrawTexturedRect(0, P(38), w, h - P(38))
			surface.SetDrawColor(acc.r, acc.g, acc.b, 52)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			surface.SetDrawColor(255, 255, 255, 16)
			surface.DrawOutlinedRect(P(2), P(2), w - P(4), h - P(4), 1)
			-- header
			local hh = P(38)
			surface.SetDrawColor(PanelCol(240))
			surface.DrawRect(0, 0, w, hh)
			surface.SetDrawColor(acc.r, acc.g, acc.b, 75)
			surface.DrawRect(0, hh - 1, w, 1)
			surface.DrawRect(self.side == 1 and 0 or w - 3, 0, 3, hh)
			Corners(0, 0, w, hh, acc, 130)
			AText(Scramble(self.title, self.scrambleStarted, 0.65), "ZCity_InvA_Label", P(10), hh * 0.5, A_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			local ct = isfunction(self.countText) and self.countText() or self.countText
			if ct then AText(ct, "ZCity_InvA_Count", w - P(10), hh * 0.5, A_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
		end
		return s
	end

	-- attachment-card style button background
	local function CardPaint(btn, w, h, active, enabled)
		local acc = Accent()
		btn.hover = Lerp(FrameTime() * 14, btn.hover or 0, (enabled ~= false and btn:IsHovered()) and 1 or 0)
		surface.SetDrawColor(PanelCol(active and 235 or 205 + btn.hover * 30))
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(acc.r, acc.g, acc.b, enabled == false and 25 or (active and 190 or 65 + btn.hover * 65))
		surface.DrawOutlinedRect(0, 0, w, h, active and 2 or 1)
		if active or btn.hover > 0.05 then Corners(0, 0, w, h, acc, active and 185 or btn.hover * 150) end
		return btn.hover > 0.5
	end

	local function StyleAttScroll(scroll)
		scroll.Paint = function() end
		local bar = scroll:GetVBar()
		bar:SetWide(P(8))
		bar:SetHideButtons(true)
		bar.Paint = function(_, w, h)
			surface.SetDrawColor(5, 5, 5, 210)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255, 35)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		bar.btnGrip.Paint = function(self, w, h)
			local acc = Accent()
			surface.SetDrawColor(acc.r, acc.g, acc.b, self:IsHovered() and 160 or 80)
			surface.DrawRect(0, 0, w, h)
		end
	end

	local function AttButton(parent, label, onClick, isEnabled)
		local b = vgui.Create("DButton", parent)
		b:SetText("")
		b.Paint = function(self, w, h)
			local enabled = not isEnabled or isEnabled()
			local hov = CardPaint(self, w, h, false, enabled)
			AText(label, "ZCity_InvA_Small", w / 2, h / 2, enabled and (hov and A_TEXT or A_MUTED) or Color(80, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		b.DoClick = function()
			if isEnabled and not isEnabled() then return end
			surface.PlaySound(SND_CLICK)
			onClick()
		end
		return b
	end

	function hg.OpenInventoryMenu()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end
		if IsValid(hg.InventoryMenu) then hg.InventoryMenu:Remove() end
		CreateAttStyleFonts()

		local W, H = ScrW(), ScrH()
		local frame = vgui.Create("DFrame")
		hg.InventoryMenu = frame
		hg.armorMenuPanel = frame -- keeps the old equipment refresh hook working
		frame:SetTitle("")
		frame:SetSize(W, H)
		frame:SetPos(0, 0)
		frame:SetDraggable(false)
		frame:ShowCloseButton(false)
		frame:MakePopup()
		frame:SetKeyboardInputEnabled(true)
		frame.openedAt = RealTime()
		frame.escapeWasDown = input.IsKeyDown(KEY_ESCAPE)
		frame.injuries = {}
		frame.injuryRows = {}

		-- layout: character in the middle, ammo on the left, equipment + injuries on the right
		local marginX = math.Clamp(W * 0.035, P(24), P(68))
		local topY, bottomY = math.floor(H * 0.08), math.floor(H * 0.9)
		local charW = math.floor(math.Clamp(W * 0.24, P(360), P(560)))
		local charX = math.floor((W - charW) / 2)
		local sideW = math.floor(math.min(P(540), charX - marginX - P(30)))
		local ammoW = math.floor(math.min(P(640), charX - marginX - P(24))) -- the ammunition tab gets a bit more room
		local fullH = bottomY - topY

		------------------------------------------------------------------
		-- middle: the character (fitted inside its box) + injury markers
		------------------------------------------------------------------
		local charSec = MakeSection(frame, "CHARACTER", 1, function()
			local n = #frame.injuries
			return n == 0 and "HEALTHY" or (n .. (n == 1 and " INJURY" or " INJURIES"))
		end, 0.05)
		charSec:SetSize(charW, fullH)
		charSec:SetPos(charX, topY)
		charSec.PaintOver = function(self, w, h)
			AText("DRAG TO ROTATE", "ZCity_InvA_Micro", w / 2, h - P(12), A_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		local preview = BuildCharacterPreview(charSec, ply)
		preview:SetPos(P(6), P(44))
		preview:SetSize(charW - P(12), fullH - P(44) - P(26))
		preview.InjuryScreen = {}
		-- the body is sized to fill this much of the box's height (measured on screen every frame,
		-- so it fits whatever the panel's shape is)
		local CHAR_FILL = 0.92
		preview:SetFOV(30)
		preview.FitDist = 110
		preview:SetCamPos(Vector(preview.FitDist, 0, 37))
		preview:SetLookAt(Vector(0, 0, 37))
		-- work out where each injury is on screen while the model is being drawn
		local basePost = preview.PostDrawModel
		preview.PostDrawModel = function(self, e)
			local frameLookAt = Vector(self:GetLookAt()) -- the look-at this frame was drawn with
			basePost(self, e)
			-- measure head-to-feet on screen and move the camera until it fills CHAR_FILL of the box
			local hb = e:LookupBone("ValveBiped.Bip01_Head1")
			local hm = hb and e:GetBoneMatrix(hb)
			if hm then
				local topZ = hm:GetTranslation().z + 8
				local feetZ = e:GetPos().z
				local top = Vector(e:GetPos().x, e:GetPos().y, topZ):ToScreen()
				local bot = e:GetPos():ToScreen()
				local span = bot.y - top.y
				local target = self:GetTall() * CHAR_FILL
				if span > 1 and target > 1 then
					local want = math.Clamp(self.FitDist * span / target, 25, 500)
					self.FitDist = Lerp(0.35, self.FitDist, want)
					local midZ = (topZ + feetZ) * 0.5 - e:GetPos().z
					self:SetCamPos(Vector(self.FitDist, 0, midZ))
					self:SetLookAt(Vector(0, 0, midZ))
				end
			end
			local pts = {}
			for _, inj in ipairs(frame.injuries) do
				local b = inj.bone and e:LookupBone(inj.bone)
				local m = b and e:GetBoneMatrix(b)
				if m then
					local pos = m:GetTranslation()
					if isvector(inj.lpos) then
						pos = LocalToWorld(inj.lpos, isangle(inj.lang) and inj.lang or angle_zero, m:GetTranslation(), m:GetAngles())
					end
					-- (ignore ToScreen's "visible" flag: inside a model panel it's judged against the game's
					-- main view, not this box, so markers blinked in and out as the model turned)
					local sp = pos:ToScreen()
					pts[inj.id] = { sp.x, sp.y }
				end
			end
			-- inside the model panel, projected points can come back relative to the panel instead of the
			-- screen. the camera's look-at point always lands in the middle of the panel, so use it to
			-- work out the offset and put every marker in real screen space
			local c = frameLookAt:ToScreen()
			local px, py = self:LocalToScreen(0, 0)
			local dx, dy = px + self:GetWide() * 0.5 - c.x, py + self:GetTall() * 0.5 - c.y
			for _, pt in pairs(pts) do pt[1], pt[2] = pt[1] + dx, pt[2] + dy end
			self.InjuryScreen = pts
		end

		------------------------------------------------------------------
		-- left: ammo
		------------------------------------------------------------------
		local state
		local selectedAmmo
		local dropCount = 1
		local sliderFrac = 0.5

		local ammoSec = MakeSection(frame, "AMMUNITION", -1, function()
			return state and (#state.ammo .. " TYPES") or ""
		end, 0)
		ammoSec:SetSize(ammoW, fullH)
		ammoSec.targetX, ammoSec.targetY = marginX, topY

		local ammoScroll = vgui.Create("DScrollPanel", ammoSec)
		StyleAttScroll(ammoScroll)

		local function SelectedEntry()
			if not state or not selectedAmmo then return end
			for _, a in ipairs(state.ammo) do if a.id == selectedAmmo then return a end end
		end
		local function UpdateCount()
			local a = SelectedEntry()
			if not a then dropCount = 0 return end
			dropCount = math.Clamp(math.Round(sliderFrac * a.count), 1, a.count)
		end
		local function SetFrac(f) sliderFrac = math.Clamp(f, 0, 1) UpdateCount() end

		local slider = vgui.Create("DButton", ammoSec)
		slider:SetText("")
		slider.Paint = function(self, w, h)
			local a = SelectedEntry()
			local acc = Accent()
			surface.SetDrawColor(PanelCol(235))
			surface.DrawRect(0, 0, w, h)
			if a then
				surface.SetDrawColor(acc.r, acc.g, acc.b, 120)
				surface.DrawRect(0, 0, math.floor(w * (dropCount / math.max(a.count, 1))), h)
			end
			surface.SetDrawColor(acc.r, acc.g, acc.b, 120)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			Corners(0, 0, w, h, acc, 130)
			AText("COUNT", "ZCity_InvA_Small", P(10), h / 2, A_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			AText(a and (dropCount .. " / " .. a.count) or "SELECT AMMO", "ZCity_InvA_Count", w - P(10), h / 2, A_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
		slider.OnMousePressed = function(self, code)
			if code ~= MOUSE_LEFT then return end
			self.Dragging = true
			self:MouseCapture(true)
			SetFrac(self:CursorPos() / self:GetWide())
		end
		slider.OnMouseReleased = function(self, code)
			if code ~= MOUSE_LEFT then return end
			self.Dragging = false
			self:MouseCapture(false)
		end
		slider.OnCursorMoved = function(self, x) if self.Dragging then SetFrac(x / self:GetWide()) end end
		slider.OnMouseWheeled = function(self, delta)
			local a = SelectedEntry()
			if not a then return end
			dropCount = math.Clamp(dropCount + (delta > 0 and 1 or -1), 1, a.count)
			sliderFrac = dropCount / a.count
			return true
		end

		local dropBtn = AttButton(ammoSec, "DROP", function()
			local a = SelectedEntry()
			if a then DropAmmo(a.id, math.min(dropCount, a.count)) end
		end, function() return SelectedEntry() ~= nil end)
		local dropAllBtn = AttButton(ammoSec, "DROP ALL", function()
			local a = SelectedEntry()
			if a then DropAmmo(a.id, a.count) end
		end, function() return SelectedEntry() ~= nil end)

		ammoSec.PerformLayout = function(self, w, h)
			local bp, sliderH, btnH = P(10), P(46), P(46)
			slider:SetPos(bp, h - bp - sliderH)
			slider:SetSize(w - bp * 2, sliderH)
			local by = h - bp - sliderH - P(8) - btnH
			local half = math.floor((w - bp * 2 - P(8)) / 2)
			dropBtn:SetPos(bp, by) dropBtn:SetSize(half, btnH)
			dropAllBtn:SetPos(bp + half + P(8), by) dropAllBtn:SetSize(w - bp * 2 - half - P(8), btnH)
			ammoScroll:SetPos(bp, P(46))
			ammoScroll:SetSize(w - bp - P(3), by - P(8) - P(46))
		end

		local function RebuildAmmo()
			ammoScroll:Clear()
			if #state.ammo == 0 then
				local empty = vgui.Create("DPanel", ammoScroll)
				empty:Dock(TOP) empty:SetTall(P(40))
				empty.Paint = function(_, w, h) AText("NO AMMO", "ZCity_InvA_Small", w / 2, h / 2, A_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
				selectedAmmo = nil
				return
			end
			if not SelectedEntry() then selectedAmmo = state.ammo[1].id end
			for _, a in ipairs(state.ammo) do
				local row = vgui.Create("DButton", ammoScroll)
				row:SetText("")
				row:Dock(TOP)
				row:DockMargin(0, 0, P(10), P(6))
				row:SetTall(P(66))
				row.Paint = function(self, w, h)
					local active = selectedAmmo == a.id
					CardPaint(self, w, h, active)
					if active then AText("SELECTED", "ZCity_InvA_Micro", P(10), P(6), A_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) end
					AText(string.upper(a.name), "ZCity_InvA_Label", P(12), h * 0.6, A_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					AText("x" .. a.count, "ZCity_InvA_Label", w - P(14), h / 2, A_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
				row:SetTooltip("LMB: select  |  RMB: drop all")
				row.DoClick = function() surface.PlaySound(SND_CLICK) selectedAmmo = a.id UpdateCount() end
				row.DoRightClick = function() DropAmmo(a.id, a.count) end
			end
			UpdateCount()
		end

		------------------------------------------------------------------
		-- right top: equipment (armor slots + other equipment)
		------------------------------------------------------------------
		local equipH = math.floor(fullH * 0.48)
		local equipSec = MakeSection(frame, "EQUIPMENT", 1, function()
			if not state then return "" end
			local n = #state.extra
			for _ in pairs(state.armor) do n = n + 1 end
			return n .. " ITEMS"
		end, 0.07)
		equipSec:SetSize(sideW, equipH)
		equipSec.targetX, equipSec.targetY = W - marginX - sideW, topY

		local slotRow = {}
		for i, slot in ipairs(ARMOR_SLOTS) do
			local card = vgui.Create("DButton", equipSec)
			card:SetText("")
			card.Paint = function(self, w, h)
				local name = state and state.armor[slot.placement]
				CardPaint(self, w, h, name ~= nil, name ~= nil)
				AText(slot.label, "ZCity_InvA_Micro", P(5), P(5), A_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				if not name then
					AText("EMPTY", "ZCity_InvA_Card", w / 2, h / 2, Color(90, 90, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					return
				end
				local icon = GetIcon(name)
				local s = math.min(w - P(20), h - P(40))
				if icon and s > 0 then
					surface.SetMaterial(icon)
					surface.SetDrawColor(255, 255, 255, 235)
					surface.DrawTexturedRect(w / 2 - s / 2, P(18), s, s)
				end
				AText(self:IsHovered() and "DROP" or string.upper(ArmorName(name)), "ZCity_InvA_Card", w / 2, h - P(5), A_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
			card.DoClick = function()
				local name = state and state.armor[slot.placement]
				if not name then return end
				surface.PlaySound(SND_CLICK)
				if IsValid(preview) then preview:TakeOff(name) end
				DropEquipment(name)
			end
			slotRow[i] = card
		end

		local equipScroll = vgui.Create("DScrollPanel", equipSec)
		StyleAttScroll(equipScroll)
		local equipCards = vgui.Create("DIconLayout", equipScroll)
		equipCards:Dock(TOP)
		equipCards:SetSpaceX(P(8))
		equipCards:SetSpaceY(P(8))

		equipSec.PerformLayout = function(self, w, h)
			local bp, gap = P(8), P(8)
			local cw = math.floor((w - bp * 2 - P(10) - gap * 2) / 3)
			local ch = math.floor(cw * 1.1)
			for i, card in ipairs(slotRow) do
				card:SetPos(bp + (i - 1) * (cw + gap), P(46))
				card:SetSize(cw, ch)
			end
			local sy = P(46) + ch + P(10)
			equipScroll:SetPos(bp, sy)
			equipScroll:SetSize(w - bp - P(3), h - sy - P(6))
			equipCards:SetWide(w - bp * 2 - P(14))
		end

		local function RebuildEquipment()
			equipCards:Clear()
			local rowW = equipSec:GetWide() - P(8) * 2 - P(14)
			equipCards:SetWide(rowW)
			for _, e in ipairs(state.extra) do
				local card = equipCards:Add("DButton")
				card:SetText("")
				card:SetSize(rowW, P(48))
				card.Paint = function(self, w, h)
					local hov = CardPaint(self, w, h, false)
					local x = P(12)
					if e.icon then
						local s = h - P(12)
						surface.SetMaterial(e.icon)
						surface.SetDrawColor(255, 255, 255, 235)
						surface.DrawTexturedRect(x, P(6), s, s)
						x = x + s + P(10)
					end
					AText(string.upper(e.name), "ZCity_InvA_Label", x, h / 2, A_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					AText(hov and "DROP" or "", "ZCity_InvA_Count", w - P(12), h / 2, A_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
				card:SetTooltip("LMB: drop")
				card.DoClick = function()
					surface.PlaySound(SND_CLICK)
					if IsValid(preview) then preview:TakeOff(e.id) end
					DropEquipment(e.id)
				end
			end
			equipCards:InvalidateLayout(true)
			equipCards:SizeToChildren(false, true)
		end

		------------------------------------------------------------------
		-- right bottom: injuries (each one linked to its spot on the body)
		------------------------------------------------------------------
		local injSec = MakeSection(frame, "INJURIES", 1, function()
			local n = #frame.injuries
			return n == 0 and "NONE" or (n .. " FOUND")
		end, 0.14)
		local injY = topY + equipH + P(16)
		injSec:SetSize(sideW, bottomY - injY)
		injSec.targetX, injSec.targetY = W - marginX - sideW, injY

		local injScroll = vgui.Create("DScrollPanel", injSec)
		StyleAttScroll(injScroll)
		injSec.PerformLayout = function(self, w, h)
			injScroll:SetPos(P(8), P(46))
			injScroll:SetSize(w - P(11), h - P(52))
		end

		local function RebuildInjuries()
			injScroll:Clear()
			frame.injuryRows = {}
			if #frame.injuries == 0 then
				local empty = vgui.Create("DPanel", injScroll)
				empty:Dock(TOP) empty:SetTall(P(40))
				empty.Paint = function(_, w, h) AText("NO INJURIES", "ZCity_InvA_Small", w / 2, h / 2, A_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
				return
			end
			for _, inj in ipairs(frame.injuries) do
				local row = vgui.Create("DPanel", injScroll)
				row:Dock(TOP)
				row:DockMargin(0, 0, P(10), P(6))
				row:SetTall(P(46))
				row.Paint = function(self, w, h)
					self.hover = Lerp(FrameTime() * 14, self.hover or 0, self:IsHovered() and 1 or 0)
					surface.SetDrawColor(PanelCol(215 + self.hover * 20))
					surface.DrawRect(0, 0, w, h)
					surface.SetDrawColor(A_INJURY.r, A_INJURY.g, A_INJURY.b, 70 + 110 * inj.sev)
					surface.DrawRect(0, 0, P(3), h)
					surface.DrawOutlinedRect(0, 0, w, h, 1)
					if self.hover > 0.05 then Corners(0, 0, w, h, A_INJURY, 150 * self.hover) end
					AText(inj.part, "ZCity_InvA_Micro", P(10), P(5), A_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					AText(inj.text, "ZCity_InvA_Small", P(10), h - P(6), A_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
					-- severity pips
					local pips = math.max(1, math.ceil(inj.sev * 3))
					for i = 1, 3 do
						surface.SetDrawColor(A_INJURY.r, A_INJURY.g, A_INJURY.b, i <= pips and 220 or 40)
						surface.DrawRect(w - P(12) - (3 - i) * P(9), h / 2 - P(3), P(6), P(6))
					end
				end
				frame.injuryRows[inj.id] = row
			end
		end

		------------------------------------------------------------------
		-- close button, links, animation, refresh
		------------------------------------------------------------------
		local closeBtn = vgui.Create("DButton", frame)
		closeBtn:SetText("")
		closeBtn:SetSize(P(42), P(42))
		closeBtn:SetPos(W - P(66), P(24))
		closeBtn.Paint = function(self, w, h)
			local acc = Accent()
			self.hover = Lerp(FrameTime() * 12, self.hover or 0, self:IsHovered() and 1 or 0)
			surface.SetDrawColor(PanelCol(132 + self.hover * 80))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(acc.r, acc.g, acc.b, 70 + self.hover * 80)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			if self.hover > 0.05 then Corners(0, 0, w, h, acc, self.hover * 180) end
			AText("X", "ZCity_InvA_Label", w / 2, h / 2, A_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		closeBtn.DoClick = function() frame:Close() end

		frame.Paint = function(self, w, h)
			-- the menus' base backdrop: darken, then the same soft side gradients as the main menu
			surface.SetDrawColor(0, 0, 0, 105)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(80, 80, 80, 15)
			surface.SetTexture(INV_GRAD_R)
			surface.DrawTexturedRect(0, 0, w, h)
			surface.SetDrawColor(20, 20, 20, 80)
			surface.SetTexture(INV_GRAD_L)
			surface.DrawTexturedRect(0, 0, w, h)
			AText("CHARACTER OVERVIEW", "ZCity_InvA_Title", marginX, P(46), A_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			AText("LMB  SELECT / DROP     RMB  DROP ALL     DRAG  ROTATE     ESC  CLOSE", "ZCity_InvA_Small", w * 0.5, h * 0.95, A_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		-- sections slide in from the sides (character rises in), like the attachments menu
		local slides = { { ammoSec, -1 }, { equipSec, 1 }, { injSec, 1 } }
		for _, s in ipairs(slides) do s[1]:SetPos(s[2] == 1 and W + P(20) or -s[1]:GetWide() - P(20), s[1].targetY) end
		charSec:SetAlpha(0)
		local function Animate()
			for _, s in ipairs(slides) do
				local sec, side = s[1], s[2]
				local p = math.Clamp((RealTime() - frame.openedAt - sec.delay) / 0.35, 0, 1)
				p = 1 - (1 - p) ^ 3
				local startX = side == 1 and W + P(20) or -sec:GetWide() - P(20)
				sec:SetPos(Lerp(p, startX, sec.targetX), sec.targetY)
			end
			local cp = math.Clamp((RealTime() - frame.openedAt - charSec.delay) / 0.35, 0, 1)
			cp = 1 - (1 - cp) ^ 3
			charSec:SetAlpha(255 * cp)
			charSec:SetPos(charX, topY + (1 - cp) * P(30))
		end

		local function Refresh(force)
			local newState = GatherState(ply)
			if force or not state or newState.signature ~= state.signature then
				state = newState
				RebuildAmmo()
				RebuildEquipment()
			end
			local inj = GatherInjuries(ply)
			local sig = InjurySignature(inj)
			if force or sig ~= frame.injurySig then
				frame.injurySig = sig
				frame.injuries = inj
				RebuildInjuries()
			end
		end
		frame.RefreshTbl = function() Refresh(false) end

		frame.Think = function(self)
			if not IsValid(ply) or not ply:Alive() then self:Close() return end
			local esc = input.IsKeyDown(KEY_ESCAPE)
			if esc and not self.escapeWasDown then self:Close() return end
			self.escapeWasDown = esc
			Animate()
			if (self.NextRefresh or 0) > CurTime() then return end
			self.NextRefresh = CurTime() + 0.25
			Refresh(false)
		end
		frame.OnKeyCodePressed = function(self, key)
			if key == KEY_ESCAPE then self:Close() end
		end
		frame.OnRemove = function()
			if hg.InventoryMenu == frame then hg.InventoryMenu = nil end
		end

		Refresh(true)
		Animate()
	end

	-- old commands both open the merged menu
	concommand.Add("hg_ammomenu", function()
		hg.OpenInventoryMenu()
	end)
	function AmmoMenu()
		hg.OpenInventoryMenu()
	end

	-- one radial entry for both ammo and equipment
	hook.Add("radialOptions", "hg-ammomenu", function()
		local lp = LocalPlayer()
		local organism = lp.organism or {}
		if organism.otrub then return end

		local hasStuff = table.Count(lp:GetAmmo()) > 0 or table.Count(lp:GetNetVar("Armor", {}) or {}) > 0
		if not hasStuff then
			local weps = (lp:GetNetVar("Inventory", {}) or {})["Weapons"] or {}
			hasStuff = weps["hg_flashlight"] or weps["hg_sling"] or weps["hg_brassknuckles"]
		end
		if not hasStuff then return end

		hg.radialOptions[#hg.radialOptions + 1] = {
			function()
				hg.OpenInventoryMenu()
				return 0
			end,
			"Character Overview"
		}
	end)
end
