if CLIENT then
	-- ============================================================
	-- Inventory: ammo + equipment in one window
	--   left   : ammo list, drop / drop all, count slider
	--   middle : your character
	--   right  : head / torso / face armor slots + other equipment
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
		if IsValid(ent) then
			ent.GetPlayerColor = function() return IsValid(ply) and ply:GetPlayerColor() or Vector(1, 1, 1) end
		end

		function mp:LayoutEntity(e)
			if not IsValid(ply) then return end
			if e:GetModel() ~= ply:GetModel() then e:SetModel(ply:GetModel()) self.SeqSet = nil end
			e:SetSkin(ply:GetSkin())
			for i = 0, (ply:GetNumBodyGroups() or 1) - 1 do
				e:SetBodygroup(i, ply:GetBodygroup(i))
			end
			for i = 0, 31 do
				local sm = ply:GetSubMaterial(i)
				if sm and sm ~= "" then e:SetSubMaterial(i, sm) end
			end
			e.GetPlayerColor = function() return IsValid(ply) and ply:GetPlayerColor() or Vector(1, 1, 1) end
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
			for _, m in pairs(self.ArmorModels or {}) do
				if IsValid(m) then m:Remove() end
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

	function hg.OpenInventoryMenu()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end

		if IsValid(hg.InventoryMenu) then hg.InventoryMenu:Remove() end

		local fw = math.min(math.floor(ScrW() * 0.66), U(1180))
		local fh = math.min(math.floor(ScrH() * 0.66), U(640))

		local frame = vgui.Create("ZFrame")
		hg.InventoryMenu = frame
		hg.armorMenuPanel = frame -- keeps the old equipment refresh hook harmless
		frame:SetTitle("")
		frame:SetSize(fw, fh)
		frame:SetPos(ScrW() / 2 - fw / 2, ScrH() + 50)
		frame:MakePopup()
		frame:SetKeyboardInputEnabled(false)
		frame:SetDraggable(false)
		if IsValid(frame.btnClose) then
			frame.btnClose:SetVisible(false)
			frame.btnClose:SetMouseInputEnabled(false)
		end
		frame:SetAlpha(0)
		frame:MoveTo(frame:GetX(), ScrH() / 2 - fh / 2, 0.35, 0, 0.3)
		frame:AlphaTo(255, 0.2, 0.05)
		function frame:First() end
		frame.Paint = function(self, w, h)
			hg.DrawBlur(self, 3)
			surface.SetDrawColor(C_FRAME)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 60)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText("INVENTORY", "ZCity_Inv_Title", U(18), U(26), C_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 40)
			surface.DrawRect(0, U(52), w, 1)
		end

		local close = MakeTextButton(frame, "X", function() frame:Close() end)
		close:SetSize(U(34), U(34))
		close:SetPos(fw - U(34) - U(10), U(9))

		local pad = U(14)
		local top = U(52) + pad
		local bodyH = fh - top - pad
		local leftW = math.floor(fw * 0.31)
		local rightW = math.floor(fw * 0.19)
		local midW = fw - leftW - rightW - pad * 4

		------------------------------------------------------------------
		-- left: ammo
		------------------------------------------------------------------
		local left = vgui.Create("DPanel", frame)
		left:SetPos(pad, top)
		left:SetSize(leftW, bodyH)
		left.Paint = function(self, w, h)
			PaintPanel(w, h)
			draw.SimpleText("AMMO", "ZCity_Inv_Tiny", U(10), U(14), C_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local selectedAmmo
		local dropCount = 1
		local state

		local ammoScroll = vgui.Create("DScrollPanel", left)
		ammoScroll:SetPos(U(8), U(28))
		StyleScroll(ammoScroll)

		local function SelectedEntry()
			if not state or not selectedAmmo then return end
			for _, a in ipairs(state.ammo) do
				if a.id == selectedAmmo then return a end
			end
		end

		local sliderFrac = 0.5
		local slider = vgui.Create("DButton", left)
		slider:SetText("")
		local function UpdateCount()
			local a = SelectedEntry()
			if not a then dropCount = 0 return end
			dropCount = math.Clamp(math.Round(sliderFrac * a.count), 1, a.count)
		end
		local function SetFrac(frac)
			sliderFrac = math.Clamp(frac, 0, 1)
			UpdateCount()
		end
		slider.Paint = function(self, w, h)
			local a = SelectedEntry()
			surface.SetDrawColor(20, 20, 20, 230)
			surface.DrawRect(0, 0, w, h)
			if a then
				local fillW = math.floor(w * (dropCount / math.max(a.count, 1)))
				surface.SetDrawColor(C_GREEN)
				surface.DrawRect(0, 0, fillW, h)
			end
			surface.SetDrawColor(C_GREEN_DARK)
			surface.DrawOutlinedRect(0, 0, w, h, U(3))
			local txt = a and ("COUNT: " .. dropCount .. " / " .. a.count) or "SELECT AMMO"
			draw.SimpleTextOutlined(txt, "ZCity_Inv_Small", w / 2, h / 2, C_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
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
		slider.OnCursorMoved = function(self, x)
			if self.Dragging then SetFrac(x / self:GetWide()) end
		end
		slider.OnMouseWheeled = function(self, delta)
			local a = SelectedEntry()
			if not a then return end
			dropCount = math.Clamp(dropCount + (delta > 0 and 1 or -1), 1, a.count)
			sliderFrac = dropCount / a.count
			return true
		end

		local dropBtn = MakeTextButton(left, "DROP", function()
			local a = SelectedEntry()
			if a then DropAmmo(a.id, math.min(dropCount, a.count)) end
		end, function() return SelectedEntry() ~= nil end)
		local dropAllBtn = MakeTextButton(left, "DROP ALL", function()
			local a = SelectedEntry()
			if a then DropAmmo(a.id, a.count) end
		end, function() return SelectedEntry() ~= nil end)

		left.PerformLayout = function(self, w, h)
			local bp = U(8)
			local sliderH = U(38)
			local btnH = U(32)
			slider:SetPos(bp, h - bp - sliderH)
			slider:SetSize(w - bp * 2, sliderH)
			local by = h - bp - sliderH - U(8) - btnH
			local half = math.floor((w - bp * 2 - U(10)) / 2)
			dropBtn:SetPos(bp, by)
			dropBtn:SetSize(half, btnH)
			dropAllBtn:SetPos(bp + half + U(10), by)
			dropAllBtn:SetSize(w - bp * 2 - half - U(10), btnH)
			ammoScroll:SetSize(w - bp * 2, by - U(8) - U(28))
		end

		local function RebuildAmmo()
			ammoScroll:Clear()
			if #state.ammo == 0 then
				local empty = vgui.Create("DPanel", ammoScroll)
				empty:Dock(TOP)
				empty:SetTall(U(40))
				empty.Paint = function(self, w, h)
					draw.SimpleText("NO AMMO", "ZCity_Inv_Tiny", w / 2, h / 2, C_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				selectedAmmo = nil
				return
			end
			if not SelectedEntry() then selectedAmmo = state.ammo[1].id end
			for _, a in ipairs(state.ammo) do
				local row = vgui.Create("DButton", ammoScroll)
				row:SetText("")
				row:Dock(TOP)
				row:DockMargin(0, 0, U(4), U(6))
				row:SetTall(U(38))
				row.Paint = function(self, w, h)
					local active = selectedAmmo == a.id
					local hov = PaintButtonBase(self, w, h, active)
					draw.SimpleText(string.upper(a.name), "ZCity_Inv_Small", U(12), h / 2, (active or hov) and C_WHITE or C_TEXT_IDLE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					draw.SimpleText(tostring(a.count), "ZCity_Inv_Small", w - U(12), h / 2, C_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
				row.DoClick = function()
					surface.PlaySound(SND_CLICK)
					selectedAmmo = a.id
					UpdateCount()
				end
				row.DoRightClick = function()
					DropAmmo(a.id, a.count)
				end
			end
			UpdateCount()
		end

		------------------------------------------------------------------
		-- middle: the character
		------------------------------------------------------------------
		local mid = vgui.Create("DPanel", frame)
		mid:SetPos(pad * 2 + leftW, top)
		mid:SetSize(midW, bodyH)
		mid.Paint = function(self, w, h)
			PaintPanel(w, h)
			draw.SimpleText("DRAG TO ROTATE", "ZCity_Inv_Tiny", w / 2, h - U(14), C_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		local preview = BuildCharacterPreview(mid, ply)
		preview:SetPos(0, 0)
		preview:SetSize(midW, bodyH - U(24))

		------------------------------------------------------------------
		-- right: armor slots + equipment
		------------------------------------------------------------------
		local right = vgui.Create("DPanel", frame)
		right:SetPos(pad * 3 + leftW + midW, top)
		right:SetSize(rightW, bodyH)
		right.Paint = function() end

		local slotGap = U(10)
		local slotH = math.floor((bodyH - slotGap * 3) / 4)

		local slotPanels = {}
		for i, slot in ipairs(ARMOR_SLOTS) do
			local box = vgui.Create("DButton", right)
			box:SetText("")
			box:SetPos(0, (i - 1) * (slotH + slotGap))
			box:SetSize(rightW, slotH)
			box.Paint = function(self, w, h)
				local name = state and state.armor[slot.placement]
				local hov = PaintButtonBase(self, w, h, false, name ~= nil)
				draw.SimpleText(slot.label, "ZCity_Inv_Tiny", U(10), U(12), C_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				if not name then
					draw.SimpleText("EMPTY", "ZCity_Inv_Tiny", w / 2, h / 2, Color(90, 90, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					return
				end
				local icon = GetIcon(name)
				local iconS = math.min(w - U(30), h - U(56))
				if icon and iconS > 0 then
					surface.SetMaterial(icon)
					surface.SetDrawColor(255, 255, 255, 235)
					surface.DrawTexturedRect(w / 2 - iconS / 2, U(22), iconS, iconS)
				end
				local label = hov and "CLICK TO DROP" or string.upper(ArmorName(name))
				draw.SimpleText(label, "ZCity_Inv_Tiny", w / 2, h - U(14), hov and C_WHITE or C_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			box.DoClick = function()
				local name = state and state.armor[slot.placement]
				if not name then return end
				surface.PlaySound(SND_CLICK)
				if IsValid(preview) then preview:TakeOff(name) end
				DropEquipment(name)
			end
			slotPanels[i] = box
		end

		local equipBox = vgui.Create("DPanel", right)
		equipBox:SetPos(0, 3 * (slotH + slotGap))
		equipBox:SetSize(rightW, slotH)
		equipBox.Paint = function(self, w, h)
			PaintPanel(w, h)
			draw.SimpleText("EQUIPMENT", "ZCity_Inv_Tiny", U(10), U(12), C_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			if state and #state.extra == 0 then
				draw.SimpleText("EMPTY", "ZCity_Inv_Tiny", w / 2, h / 2, Color(90, 90, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		local equipScroll = vgui.Create("DScrollPanel", equipBox)
		equipScroll:SetPos(U(6), U(24))
		equipScroll:SetSize(rightW - U(12), slotH - U(30))
		StyleScroll(equipScroll)

		local function RebuildEquipment()
			equipScroll:Clear()
			for _, e in ipairs(state.extra) do
				local row = vgui.Create("DButton", equipScroll)
				row:SetText("")
				row:Dock(TOP)
				row:DockMargin(0, 0, U(4), U(4))
				row:SetTall(U(26))
				row.Paint = function(self, w, h)
					local hov = PaintButtonBase(self, w, h, false)
					local x = U(8)
					if e.icon then
						surface.SetMaterial(e.icon)
						surface.SetDrawColor(255, 255, 255, 235)
						surface.DrawTexturedRect(x, U(2), h - U(4), h - U(4))
						x = x + h
					end
					draw.SimpleText(hov and "DROP" or string.upper(e.name), "ZCity_Inv_Tiny", x, h / 2, hov and C_WHITE or C_TEXT_IDLE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
				row.DoClick = function()
					surface.PlaySound(SND_CLICK)
					if IsValid(preview) then preview:TakeOff(e.id) end
					DropEquipment(e.id)
				end
			end
		end

		------------------------------------------------------------------
		-- keep everything in sync with what the player actually carries
		------------------------------------------------------------------
		local function Refresh(force)
			local newState = GatherState(ply)
			if not force and state and newState.signature == state.signature then return end
			state = newState
			RebuildAmmo()
			RebuildEquipment()
		end
		frame.RefreshTbl = function() Refresh(false) end
		frame.Think = function(self)
			if not IsValid(ply) or not ply:Alive() then self:Close() return end
			if (self.NextRefresh or 0) > CurTime() then return end
			self.NextRefresh = CurTime() + 0.25
			Refresh(false)
		end
		frame.OnRemove = function()
			if hg.InventoryMenu == frame then hg.InventoryMenu = nil end
		end

		Refresh(true)
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
			"Inventory"
		}
	end)
end
