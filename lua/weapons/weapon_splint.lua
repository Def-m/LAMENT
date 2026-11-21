if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.BandageTPIK = false
SWEP.PrintName = "Splint"
SWEP.Instructions = "A padded limb splint with a strap. Immobilizes a broken arm or leg so the bone can start knitting back together. Aim at a limb to pick which one, RMB to use on someone else."
SWEP.HowToUseInstructions = "LMB - splint yourself  /  RMB - splint someone else"
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/bandages.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("scrappers/jgut.png")
	SWEP.IconOverride = "scrappers/jgut.png"
	SWEP.BounceWeaponIcon = false

	SWEP.WepSelectIcon2 = Material("scrappers/jgut.png")

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.SetMaterial( self.WepSelectIcon2 )

		local maxWide = wide
		local maxTall = wide / 2
		local iconWide = self.WepSelectIcon2:Width()
		local iconTall = self.WepSelectIcon2:Height()
		if iconWide <= 0 or iconTall <= 0 then return end
		local scale = math.min(maxWide / iconWide, maxTall / iconTall)
		local drawWide = iconWide * scale
		local drawTall = iconTall * scale

		surface.DrawTexturedRect( x + (maxWide - drawWide) / 2, y + 10 + (maxTall - drawTall) / 2, drawWide, drawTall )

		self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
	end
end

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -3.5, 0)
SWEP.offsetAng = Angle(90, 90, 0)
SWEP.ModelScale = 1
SWEP.modeNames = {
	[1] = "splint"
}
SWEP.showstats = false

function SWEP:InitializeAdd()
	self:SetHold(self.HoldType)
	self.modeValues = {
		[1] = 1,
	}
end

SWEP.modeValuesdef = {
	[1] = 1,
}

-- how the splint works
SWEP.SplintBrokenAt = 0.3      -- limb damage (0 = fine, 1 = broken) worth splinting
SWEP.SplintSetTo = 0.5         -- a splinted limb immediately drops to this (no longer counts as broken)
SWEP.SplintHealTime = 45       -- seconds for a splinted limb to heal from SplintSetTo to 0

local hg_healanims = ConVarExists("hg_healanims") and GetConVar("hg_healanims") or CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)

function SWEP:Think()
	if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
		self:SetHolding(math.max(self:GetHolding() - 12, 0))
	end
end

local lang1, lang2 = Angle(0, -10, 0), Angle(0, 10, 0)
function SWEP:Animation()
	local owner = self:GetOwner()
	local aimvec = owner:GetAimVector()
	local hold = self:GetHolding()
	if (owner.zmanipstart ~= nil and not ( owner.organism and owner.organism.larmamputated )) then return end
	self:BoneSet("r_upperarm", vector_origin, Angle(30 - hold / 4, -30 + hold / 2 + 20 * aimvec[3], 5 - hold / 3.5))
	self:BoneSet("r_forearm", vector_origin, Angle(hold / 10, -hold / 2.5, 35 - hold / 1.5))
	self:BoneSet("l_upperarm", vector_origin, lang1)
	self:BoneSet("l_forearm", vector_origin, lang2)
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:NPCHeal(owner, 0.2, "snd_jack_hmcd_bandage.wav")
	end
end

if SERVER then
	local LIMB_BONES = {
		["ValveBiped.Bip01_L_Thigh"] = "lleg", ["ValveBiped.Bip01_L_Calf"] = "lleg", ["ValveBiped.Bip01_L_Foot"] = "lleg", ["ValveBiped.Bip01_L_Toe0"] = "lleg",
		["ValveBiped.Bip01_R_Thigh"] = "rleg", ["ValveBiped.Bip01_R_Calf"] = "rleg", ["ValveBiped.Bip01_R_Foot"] = "rleg", ["ValveBiped.Bip01_R_Toe0"] = "rleg",
		["ValveBiped.Bip01_L_UpperArm"] = "larm", ["ValveBiped.Bip01_L_Forearm"] = "larm", ["ValveBiped.Bip01_L_Hand"] = "larm",
		["ValveBiped.Bip01_R_UpperArm"] = "rarm", ["ValveBiped.Bip01_R_Forearm"] = "rarm", ["ValveBiped.Bip01_R_Hand"] = "rarm",
	}
	local LIMB_NAMES = { lleg = "left leg", rleg = "right leg", larm = "left arm", rarm = "right arm" }
	local LIMBS = { "lleg", "rleg", "larm", "rarm" }

	function SWEP:GetTargetLimb(ent)
		local owner = self:GetOwner()
		local tr = hg.eyeTrace(owner)
		if not tr or tr.Entity ~= ent then return nil end
		local physbone = tr.PhysicsBone
		if not physbone or physbone < 0 then return nil end
		local boneid = ent:TranslatePhysBoneToBone(physbone)
		if not boneid or boneid < 0 then return nil end
		return LIMB_BONES[ent:GetBoneName(boneid)]
	end

	local function CanSplint(self, org, limb)
		if not limb or not isnumber(org[limb]) then return false end
		if org[limb .. "amputated"] or org[limb .. "upamputated"] then return false end
		if org.splints and org.splints[limb] then return false end
		return org[limb] >= self.SplintBrokenAt
	end

	-- aimed at a specific limb, otherwise the worst one; nil if nothing needs a splint
	function SWEP:FindSplintLimb(org, limb)
		if CanSplint(self, org, limb) then return limb end
		local best, worst = nil, 0
		for _, l in ipairs(LIMBS) do
			if CanSplint(self, org, l) and org[l] > worst then
				worst = org[l]
				best = l
			end
		end
		return best
	end

	-- chat messages are rate limited so holding the button doesn't spam
	function SWEP:SplintMessage(text)
		local owner = self:GetOwner()
		if not IsValid(owner) or not owner:IsPlayer() then return end
		if (owner.NextSplintMsg or 0) > CurTime() then return end
		owner.NextSplintMsg = CurTime() + 3
		owner:ChatPrint(text)
	end

	function SWEP:Splint(ent, limb)
		local org = ent.organism
		if not org then return false end

		limb = self:FindSplintLimb(org, limb)
		local owner = self:GetOwner()
		if not limb then return false end

		org[limb] = math.min(org[limb], self.SplintSetTo)
		org.splints = org.splints or {}
		org.splints[limb] = self.SplintSetTo / math.max(self.SplintHealTime, 1) -- heal per second
		if org.avgpain then org.avgpain = math.max(org.avgpain - 10, 0) end
		if org.pain then org.pain = math.max(org.pain - 5, 0) end

		local who = hg.GetCurrentCharacter(owner) == ent and "your" or "their"
		local text = "You splint " .. who .. " " .. LIMB_NAMES[limb] .. "."
		-- short delay so the message lands after the splint goes on
		timer.Simple(0.6, function()
			if IsValid(owner) and owner:IsPlayer() then owner:ChatPrint(text) end
		end)
		owner:EmitSound("snd_jack_hmcd_bandage.wav", 60, math.random(85, 95))
		return true
	end

	function SWEP:Heal(ent, mode)
		if ent:IsNPC() then
			self:NPCHeal(ent, 0.2, "snd_jack_hmcd_bandage.wav")
			return
		end

		local owner = self:GetOwner()
		local org = ent.organism
		if not org then return end

		-- nothing broken: don't start the animation at all
		local limb = self:FindSplintLimb(org, self:GetTargetLimb(ent))
		if not limb then
			self:SetHolding(0)
			self:SplintMessage(ent == hg.GetCurrentCharacter(owner) and "You have no broken limbs to splint." or "They have no broken limbs to splint.")
			return
		end

		if ent == hg.GetCurrentCharacter(owner) and hg_healanims:GetBool() then
			self:SetHolding(math.min(self:GetHolding() + 10, 100))
			if self:GetHolding() < 100 then return end
		end

		if self:Splint(ent, limb) then
			self.modeValues[1] = 0
			owner:SelectWeapon("weapon_hands_sh")
			self:Remove()
			return true
		end
	end

	-- splinted limbs heal back to 0 over time, then the splint comes off
	hook.Add("Org Think", "ZC_SplintHealing", function(owner, org, timeValue)
		if not org.splints then return end
		for limb, rate in pairs(org.splints) do
			if not isnumber(org[limb]) or org[limb .. "amputated"] then
				org.splints[limb] = nil
			else
				org[limb] = math.max(org[limb] - rate * timeValue, 0)
				if org[limb] <= 0 then org.splints[limb] = nil end
			end
		end
		if next(org.splints) == nil then org.splints = nil end
	end)

	hook.Add("PlayerSpawn", "ZC_SplintReset", function(ply)
		if ply.organism then ply.organism.splints = nil end
	end)
end
