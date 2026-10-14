local CLASS = player.RegClass("swat")

function CLASS.Off(self)
    if CLIENT then return end
    self.ChudmorseSWATSetupToken = nil
end

local SWAT_MODEL = "models/css_seb_swat/css_swat.mdl"

local function ApplySWATModel(ply, force)
    if not IsValid(ply) or not ply:Alive() or ply.PlayerClassName ~= "swat" then return end
    if IsValid(ply.FakeRagdoll) then return end
    if not force and ply:GetModel() == SWAT_MODEL then return end

    ply:SetModel(SWAT_MODEL)
    ply:SetSubMaterial()
    ply:SetSkin(0)
    ply:SetBodyGroups("00000000000")
end

function CLASS.On(self)
    if CLIENT then return end
    local setupToken = {}
    self.ChudmorseSWATSetupToken = setupToken
    ApplyAppearance(self,nil,nil,nil,true)
    self:SetPlayerColor(Color(10,10,100):ToVector())
    ApplySWATModel(self, true)
    timer.Simple(0, function()
        if not IsValid(self) or self.ChudmorseSWATSetupToken ~= setupToken then return end
        ApplySWATModel(self, true)
    end)
    local Appearance = table.Copy(self.CurAppearance or hg.Appearance.GetRandomAppearance())
    Appearance.AAttachments = ""
    Appearance.AColthes = ""
    self:SetNetVar("Accessories", "")
    self.CurAppearance = Appearance
    local inv = self:GetNetVar("Inventory", {})
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    self:SetNetVar("Inventory", inv)

    self:SetNWString("PlayerName","SWAT "..Appearance.AName)
end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end

    if Victim:GetPlayerClass() == self:GetPlayerClass() then
        return 1
    end

    if CurrentRound().name == "hmcd" then
        return zb.ForcesAttackedInnocent(self, Victim)
    end

    if Victim == zb.hostage then
        return 1
    end

    return 1
end

hook.Add("HG_PlayerFootstep", "swat_footsteps", function(ply, pos, foot, sound, volume, rf)
	local chr = hg.GetCurrentCharacter(ply)
	if ply:Alive() and ply.PlayerClassName == "swat" then
		local ent = hg.GetCurrentCharacter(ply)

		if not (ply:IsWalking() or ply:Crouching()) and ent == ply then
			local snd = "zcitysnd/" .. string.Replace(sound, "player/footsteps", "player/footsteps_military/")
			if SoundDuration(snd) <= 0 then
				snd = sound -- missing footsteps fix
			end

			hg.EmitFootstepSound(snd, pos, ply, volume, 75, changePitch(math.random(95,105)) )

			return true
		end
	end
end)

-- Appearance/spawn callbacks may arrive after class setup on dedicated servers.
-- Repair only a model mismatch; never rerun class setup or reset the loadout.
if SERVER then
    timer.Create("ChudmorseSWATModel", 0.5, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            ApplySWATModel(ply, false)
        end
    end)
end
