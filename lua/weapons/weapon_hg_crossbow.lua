SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Homemade Crossbow"
SWEP.Author = "Unknown"
SWEP.Instructions = "A rather weighty homemade crossbow that shoots red-hot armature.\nHas very high damage"
SWEP.Category = "Weapons - Other"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_crossbow.mdl"
SWEP.WorldModelFake = "models/weapons/c_crossbow.mdl"

SWEP.FakePos = Vector(-11, 8.2, 7.5)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0.5,-1.2,-6.5)
SWEP.AttachmentAng = Angle(0,0,0)


SWEP.FakeVPShouldUseHand = true

SWEP.CantFireFromCollision = true // 2 спусковых крючка все дела

SWEP.AnimList = {
	["idle"] = "idle_is",
	["reload"] = "reload",
	["reload_empty"] = "reload",
}

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 1

SWEP.FakeReloadSounds = {}

SWEP.FakeEmptyReloadSounds = {
	[0.18] = "weapons/universal/uni_crawl_l_03.wav",
	--[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.62] = "weapons/tfa_hl2r/crossbow/reload1.wav",
	[0.75] = "weapons/tfa_hl2r/crossbow/bolt_load2.wav",
	[0.84] = "weapons/universal/uni_crawl_l_04.wav",
	--[0.92] = "weapons/m45/m45_boltrelease.wav",
}

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(-10,0,0)
SWEP.lmagpos2 = Vector(0,3.5,0.3)
SWEP.lmagang2 = Angle(0,0,-110)

SWEP.GunCamPos = Vector(2.2,-17,-3)
SWEP.GunCamAng = Angle(180,0,-90)

SWEP.MagModel = "models/weapons/zcity/w_glockmag.mdl"

if CLIENT then
	SWEP.FakeReloadEvents = {
		[0.84] = function(self) self:GetWM():SetSkin(1) end
	}
end

SWEP.FakeMagDropBone = "glock_mag"
SWEP.WepSelectIcon2 = Material("vgui/wep_jack_hmcd_crossbow")
SWEP.IconOverride = "vgui/wep_jack_hmcd_crossbow"
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.ShellEject = ""
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Armature"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 1
SWEP.Primary.Sound = {"weapons/crossbow/fire1.wav", 75, 90, 100}
SWEP.Primary.Force = 25
SWEP.Primary.Wait = 0.1
SWEP.ReloadTime = 3
SWEP.DeploySnd = {"weapons/crossbow/crossbow_deploy.wav", 55, 100, 110}
SWEP.HolsterSnd = {"snds_jack_gmod/ez_weapons/amsr/in.wav", 45, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(-4, 2.22, 6.8796)
SWEP.RHandPos = Vector(0,0,0)
SWEP.LHandPos = Vector(13,0,0)
SWEP.Ergonomics = 0.8
SWEP.WorldPos = Vector(0,1.1,-1)
SWEP.WorldAng = Angle(2, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0,0,2)
SWEP.attAng = Angle(-90,0,0)
SWEP.lengthSub = 25
SWEP.DistSound = ""
SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(5, 11, -4)
SWEP.holsteredAng = Angle(-150, -10, 180)

SWEP.OpenBolt = true
SWEP.SprayRand = {Angle(-0.05, -0.01, 0), Angle(-0.1, 0.01, 0)}
SWEP.SprayRandOnly = true
SWEP.scopedef = true

SWEP.mat = Material("effects/arc9/rt")
SWEP.scopemat = Material("decals/scope.png")
SWEP.perekrestie = Material("vgui/arc9_eft_shared/reticles/scope_30mm_march_tactical_3-24x42_marks.png")
SWEP.sizeperekrestie = 4200

SWEP.handsAng = Angle(-5, -1, 0)

SWEP.localScopePos = Vector(-14,-0.365,2.39)
SWEP.scope_blackout = 330
SWEP.rot = 0
SWEP.FOVMin = 6
SWEP.FOVMax = 15
SWEP.ZoomFOV = 10
SWEP.perekrestieSize = false
SWEP.blackoutsize = 3100

SWEP.ReloadSound = "weapons/crossbow/reload1.wav"
SWEP.ReloadSoundes = {
	"none",
	"weapons/tfa_hl2r/crossbow/crossbow_deploy.wav",
	"none",	
	"weapons/tfa_hl2r/crossbow/bolt_load2.wav",
	"none",
	"weapons/tfa_hl2r/ar2/weapon_movement1.wav",
	"none",
	"none",
	"none"
}
SWEP.AnimShootMul = 2
SWEP.AnimShootHandMul = 5
SWEP.addSprayMul = 2

SWEP.Penetration = 40

SWEP.weight = 3

SWEP.RestPosition = Vector(21, -1, 2)

function SWEP:Shoot(override)
	if not self:CanPrimaryAttack() then return false end
	if not self:CanUse() then return false end
	if self:Clip1() == 0 then return end
	local primary = self.Primary
	if not self.drawBullet then
		self.LastPrimaryDryFire = CurTime()
		self:PrimaryShootEmpty()
		primary.Automatic = false
		return false
	end
	local owner = self:GetOwner()
	if primary.Next > CurTime() then return false end
	if (primary.NextFire or 0) > CurTime() then return false end
	primary.Next = CurTime() + primary.Wait
	self:SetLastShootTime(CurTime())
	primary.Automatic = weapons.Get(self:GetClass()).Primary.Automatic
	
	local tr,pos,ang = self:GetTrace(true)
	local owner = self:GetOwner()
	
	if SERVER then
		local dist, point = util.DistanceToLine(pos, pos - ang:Forward() * 50, owner:EyePos())

		--if(GetGlobalBool("PhysBullets_ReplaceDefault", false))then
		local bullet = {}
			-- bullet.Num = 1
		bullet.Pos = point
		bullet.Dir = ang:Forward()
		bullet.Speed = 310
			-- bullet.Force = ammotype.Force or primary.Force
		bullet.Damage = 500
		bullet.Force = 80
			-- bullet.Size = 0.5
			-- bullet.Spread = ammotype.Spread or self.Primary.Spread or 0
		bullet.AmmoType = "Armature"
		bullet.Attacker = owner.suiciding and Entity(0) or owner
		bullet.IgnoreEntity = not owner.suiciding and (owner.InVehicle and owner:InVehicle() and owner:GetVehicle() or hg.GetCurrentCharacter(owner)) or nil
			-- bullet.Callback = bulletHit
			-- bullet.TracerName = self.Tracer or "nil"
			-- bullet.Speed = ammotype.Speed
			-- bullet.Distance = ammotype.Distance or 56756
		bullet.Penetration = 10

		hg.PhysBullet.CreateBullet(bullet)
			-- self:FireBullets(bullet)
		--else
		--	local projectile = ents.Create("crossbow_projectile")
		--	projectile:SetPos(point)
		--	projectile:SetAngles(ang)
		--	projectile:Spawn()
		--	projectile.Penetration = -(-self.Penetration)
--
		--	local phys = projectile:GetPhysicsObject()
		--	if IsValid(phys) then
		--		phys:SetVelocity(self:GetOwner():GetVelocity() + ang:Forward() * 9000)
		--	end
		--end
	end

	self:EmitShoot()
	self:PrimarySpread()
	self:TakePrimaryAmmo(1)
	self:GetWM():SetSkin(0)
	self:PlayAnim("fire",1,false,nil,false,false,true)
end
SWEP.dort = true

if CLIENT then
	-- ===== Scope =====
	-- The crossbow renders its own scope picture into its own render target and puts it on the
	-- model's lens. The lens slot is found in game: the first time you aim, the part of the model
	-- under the middle of the screen is the lens. The base DoRT is not used here: it blacks the
	-- whole picture out whenever the eye isn't lined up with localScopePos.
	local RT_SIZE = 640
	local scopeRT = GetRenderTargetEx("hg_crossbow_scope_640", RT_SIZE, RT_SIZE,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_SHARED,
		bit.bor(2, 256),
		0,
		IMAGE_FORMAT_BGR888
	)
	local scopeMat = CreateMaterial("hg_crossbow_scope_v1", "UnlitGeneric", {
		["$basetexture"] = scopeRT:GetName(),
		["$model"] = 1,
	})
	local scopeMatName = "!hg_crossbow_scope_v1"
	SWEP.mat = scopeMat

	local cvLensSlot = CreateClientConVar("hg_crossbow_lens_slot", "-1", true, false, "Crossbow scope: model material slot used as the lens (-1 = find it automatically when you aim)", -1, 31)
	local lensKeywords = {"lens", "glass"}

	-- tiny offscreen target used to find which material slot sits in the middle of the screen
	local pickRT = GetRenderTargetEx("hg_crossbow_lenspick_16", 16, 16,
		RT_SIZE_LITERAL,
		MATERIAL_RT_DEPTH_SEPARATE,
		0,
		0,
		IMAGE_FORMAT_RGBA8888
	)
	-- no $basetexture: UnlitGeneric falls back to plain white, tinted by $color/$color2
	local pickWhite = CreateMaterial("hg_crossbow_pick_white_v2", "UnlitGeneric", {
		["$model"] = 1,
	})
	local pickBlack = CreateMaterial("hg_crossbow_pick_black_v2", "UnlitGeneric", {
		["$color"] = "[0 0 0]",
		["$color2"] = "[0 0 0]",
		["$model"] = 1,
	})

	local function ClearPickOverrides(slotCount)
		for i = 0, slotCount - 1 do
			render.MaterialOverrideByIndex(i, nil)
		end
	end

	-- whiteSlot: a slot number, true (every slot white) or false (every slot black)
	local function SampleCentre(model, view, slotCount, whiteSlot)
		render.Clear(0, 0, 0, 255, true, true)
		cam.Start3D(view.origin, view.angles, 2, 0, 0, 16, 16, 0.5, 512)
			for i = 0, slotCount - 1 do
				render.MaterialOverrideByIndex(i, (whiteSlot == true or whiteSlot == i) and pickWhite or pickBlack)
			end
			model:DrawModel()
			ClearPickOverrides(slotCount)
		cam.End3D()
		render.CapturePixels()
		local r, g, b = render.ReadPixel(8, 8)
		return ((r or 0) + (g or 0) + (b or 0)) / 3
	end

	local function DetectLensSlot(model, view)
		local slotCount = #model:GetMaterials()
		if slotCount == 0 then return nil, "the model has no materials" end

		local oldFog = render.GetFogMode()
		render.FogMode(MATERIAL_FOG_NONE)
		render.SetColorModulation(1, 1, 1)
		render.SetBlend(1)
		render.PushRenderTarget(pickRT)
		local ok, slot, reason = pcall(function()
			local white = SampleCentre(model, view, slotCount, true)
			local black = SampleCentre(model, view, slotCount, false)
			if white - black < 30 then return nil, "the crossbow isn't in the middle of the screen (white " .. math.Round(white) .. ", black " .. math.Round(black) .. ")" end
			local threshold = (white + black) / 2
			for i = 0, slotCount - 1 do
				if SampleCentre(model, view, slotCount, i) >= threshold then return i end
			end
			return nil, "no material slot matched"
		end)
		render.PopRenderTarget()
		ClearPickOverrides(slotCount)
		render.FogMode(oldFog)

		if not ok then return nil, tostring(slot) end
		return slot, reason
	end

	function SWEP:GetScopeLensSlot(model)
		local forced = cvLensSlot:GetInt()
		if forced >= 0 then return forced end
		if model.hgDetectedLensSlot then return model.hgDetectedLensSlot end

		if model.hgKeywordLensModel != model:GetModel() then
			model.hgKeywordLensModel = model:GetModel()
			model.hgKeywordLensSlot = nil
			for index, name in ipairs(model:GetMaterials()) do
				local lower = string.lower(name)
				for _, keyword in ipairs(lensKeywords) do
					if string.find(lower, keyword, 1, true) then
						model.hgKeywordLensSlot = index - 1
						break
					end
				end
				if model.hgKeywordLensSlot then break end
			end
		end

		return model.hgKeywordLensSlot
	end

	function SWEP:ApplyScopeLens(model)
		model = model or self:GetWM()
		if not IsValid(model) then return end

		local slot = self:GetScopeLensSlot(model)
		if model.hgScopeLensSlot != slot then
			-- put the previous slot back to its own material
			if model.hgScopeLensSlot and model:GetSubMaterial(model.hgScopeLensSlot) == scopeMatName then
				model:SetSubMaterial(model.hgScopeLensSlot, "")
			end
			model.hgScopeLensSlot = slot
		end

		if slot and model:GetSubMaterial(slot) != scopeMatName then
			model:SetSubMaterial(slot, scopeMatName)
		end
	end

	function SWEP:UpdateLensDetection(model)
		if cvLensSlot:GetInt() >= 0 or model.hgLensDetectDone then return end

		if not self:IsZoom() or GetViewEntity() != LocalPlayer() then
			self.hgLensAimStart = nil
			return
		end

		self.hgLensAimStart = self.hgLensAimStart or CurTime()
		if CurTime() - self.hgLensAimStart < 0.4 or (model.hgLensRetryAt or 0) > CurTime() then return end

		local slot, reason = DetectLensSlot(model, render.GetViewSetup(true))
		if slot then
			model.hgLensDetectDone = true
			model.hgDetectedLensSlot = slot
			print("[Crossbow] scope lens found on material slot " .. slot .. " (" .. tostring(model:GetMaterials()[slot + 1]) .. ")")
			return
		end

		model.hgLensTries = (model.hgLensTries or 0) + 1
		model.hgLensRetryAt = CurTime() + 1
		if model.hgLensTries >= 3 then
			model.hgLensDetectDone = true
			print("[Crossbow] couldn't find the scope lens automatically (" .. tostring(reason) .. "). Run hg_crossbow_materials, then set hg_crossbow_lens_slot <slot> or cycle with hg_crossbow_lens_next.")
		end
	end

	function SWEP:DrawHUDAdd()
		local model = self:GetWM()
		if not IsValid(model) then return end

		self:UpdateLensDetection(model)
		self:ApplyScopeLens(model)
	end

	local scopeErrorPrinted = false
	function SWEP:DoRT()
		LOW_RENDER = nil

		local owner = self:GetOwner()
		if not IsValid(owner) or owner != LocalPlayer() then return end

		local pos, ang = self:GetTrace(true, nil, nil, true)
		if not isvector(pos) or not isangle(ang) then return end

		self.isscoping = true

		-- scope camera sits at the scope, pulled back out of walls like the base scopes do
		local scopePos = LocalToWorld(self.localScopePos, angle_zero, pos, ang)
		local eyePos = owner:EyePos()
		local dir = scopePos - eyePos
		local dirNorm = dir:GetNormalized()
		local tr = util.QuickTrace(eyePos, dir + dirNorm * 5, {owner, owner.FakeRagdoll})
		local origin = owner:InVehicle() and scopePos or tr.HitPos - dirNorm * 5

		render.PushRenderTarget(scopeRT, 0, 0, RT_SIZE, RT_SIZE)
		render.Clear(0, 0, 0, 255)

		RENDERING_SCOPE = self
		local ok, err = pcall(render.RenderView, {
			x = 0,
			y = 0,
			w = RT_SIZE,
			h = RT_SIZE,
			origin = origin,
			angles = ang,
			fov = math.Clamp(self.ZoomFOV or 10, 1, 90),
			znear = 1,
			zfar = zfar,
			drawviewmodel = false,
			drawhud = false,
			dopostprocess = false,
			bloomtone = false,
		})
		RENDERING_SCOPE = false

		-- reticle and vignette are always centred: the camera looks straight down the barrel
		cam.Start2D()
			local reticleSize = (self.sizeperekrestie * RT_SIZE / 512) / ((self.perekrestieSize and 4) or (self.FOVMax or 10) / 3)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(self.perekrestie)
			surface.DrawTexturedRectRotated(RT_SIZE / 2, RT_SIZE / 2, reticleSize, reticleSize, self.rot or 0)

			local vignetteSize = (self.blackoutsize or 3100) * 0.9 * 0.75 * RT_SIZE / 512 + 512
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetMaterial(self.scopemat)
			surface.DrawTexturedRect((RT_SIZE - vignetteSize) / 2, (RT_SIZE - vignetteSize) / 2, vignetteSize, vignetteSize)
		cam.End2D()

		render.PopRenderTarget()

		if not ok and not scopeErrorPrinted then
			scopeErrorPrinted = true
			ErrorNoHalt("[Crossbow] scope render failed: " .. tostring(err) .. "\n")
		end
	end

	local function GetHeldCrossbowModel()
		local wep = LocalPlayer():GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_hg_crossbow" and IsValid(wep:GetWM()) then
			return wep:GetWM(), wep
		end
	end

	concommand.Add("hg_crossbow_materials", function()
		local model, wep = GetHeldCrossbowModel()
		local temporary = false
		if not IsValid(model) then
			model = ClientsideModel("models/weapons/c_crossbow.mdl")
			if not IsValid(model) then print("[Crossbow] couldn't load models/weapons/c_crossbow.mdl") return end
			temporary = true
		end

		print("[Crossbow] material slots on " .. model:GetModel() .. ":")
		for index, name in ipairs(model:GetMaterials()) do
			print(string.format("[Crossbow]   [%d] %s", index - 1, name))
		end
		print("[Crossbow] slot showing the scope: " .. tostring(model.hgScopeLensSlot)
			.. " | found automatically: " .. tostring(model.hgDetectedLensSlot)
			.. " | hg_crossbow_lens_slot = " .. cvLensSlot:GetInt())

		if temporary then model:Remove() end
	end)

	concommand.Add("hg_crossbow_lens_next", function()
		local model = GetHeldCrossbowModel()
		local count = IsValid(model) and #model:GetMaterials() or 0
		if count == 0 then print("[Crossbow] hold the crossbow first") return end

		local nextSlot = (cvLensSlot:GetInt() + 1) % count
		RunConsoleCommand("hg_crossbow_lens_slot", tostring(nextSlot))
		print("[Crossbow] scope picture now on slot " .. nextSlot .. " (" .. tostring(model:GetMaterials()[nextSlot + 1]) .. "). Use hg_crossbow_lens_slot -1 to go back to automatic.")
	end)

	concommand.Add("hg_crossbow_lens_redetect", function()
		local model = GetHeldCrossbowModel()
		if IsValid(model) then
			model.hgLensDetectDone = nil
			model.hgDetectedLensSlot = nil
			model.hgLensTries = nil
			model.hgLensRetryAt = nil
		end
		RunConsoleCommand("hg_crossbow_lens_slot", "-1")
		print("[Crossbow] lens detection reset: aim down the scope to find it again.")
	end)

	function SWEP:ReloadStart()
		if not self or not IsValid(self:GetOwner()) then return end
		hook.Run("HGReloading", self)
		--self:SetHold(self.ReloadHold or self.HoldType)
		--self:GetOwner():SetAnimation(PLAYER_RELOAD)
	end

	function SWEP:ReloadEnd()
		self:GetWeaponEntity():SetBodygroup(1,0)
		self:SetBodygroup(1,0)

		self:InsertAmmo(1)
		self.ReloadNext = CurTime() + self.ReloadCooldown
		self:Draw()
	end

	function SWEP:ModelCreated(model)
		self:ApplyScopeLens(model)
		model:SetSkin(self:Clip1() < 1 and 0 or 1)
	end

	function SWEP:OwnerChanged()
		if !IsValid(self:GetWM()) then return end
		
		self:PlayAnim( self:Clip1() < 1 and "idle_empty" or "idle_is",10,nil,nil,nil,true)
		self:GetWM():SetSkin(self:Clip1() < 1 and 0 or 1)
	end
end
SWEP.NoWINCHESTERFIRE = true

function SWEP:AnimHoldPost(model)

end

SWEP.LocalMuzzlePos = Vector(25.041,2.587,3.508)
SWEP.LocalMuzzleAng = Angle(2.264,0,0)
SWEP.WeaponEyeAngles = Angle(-2,0,0)

SWEP.CanSuicide = true

--local to head
SWEP.RHPos = Vector(5.5,-7.5,4)
SWEP.RHAng = Angle(0,-5,90)
--local to rh
SWEP.LHPos = Vector(14,-1,-5)
SWEP.LHAng = Angle(-90,-90,-90)

local finger1 = Angle(-15,0,5)
local finger2 = Angle(-15,45,-5)

--RELOAD ANIMS PISTOL

SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(-7,10,-10),
	Vector(-2,-5,0),
	Vector(1,-9,5),
	Vector(1,-7,0),
	"reloadend",
	Vector(-4,-1,0),
	Vector(0,0,0),
	Vector(0,0,0)
}
SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(-180,180,0),
	Angle(-180,180,-45),
	Angle(-180,180,15),
	Angle(-185,185,15),
	Angle(-2,5,0),
	Angle(0,0,0),
}

SWEP.ReloadAnimRH = {
	Vector(0,0,0)
}
SWEP.ReloadAnimRHAng = {
	Angle(0,0,0)
}
SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(-5,16,1),
	Angle(-3,14,2),
	Angle(12,15,-1),
	Angle(-5,14,0),
	Angle(0,16,0),
	Angle(0,-2,-2),
	Angle(0,0,0),
}

-- Inspect Assault

SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(4,4,15),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(-6,-15,-15),
	Angle(1,15,-45),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(0,0,0),
	Angle(0,0,0)
}
