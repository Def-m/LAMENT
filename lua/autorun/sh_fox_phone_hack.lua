if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("fox_phone_hack/cl_hack.lua")
    AddCSLuaFile("fox_phone_hack/cl_overlay.lua")
    AddCSLuaFile("fox_phone_hack/cl_ground.lua")
end
FoxPhoneHack = FoxPhoneHack or {}
local F = FoxPhoneHack
-- Balance settings: Source units and seconds.
F.Range = 1600
F.TrapRange = 4096
F.TrapClass = "ttt_traitor_button"
F.Warmup = 2
F.Duration = 24
F.ScanCooldown = 60
F.ShockCooldown = 10
F.StunTime = 3
F.AimDot = math.cos(math.rad(8))
F.PhoneClass = "weapon_police_phone"
F.RadioClass = "weapon_walkie_talkie"
function F.IsFox(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if not zb or zb.ROUND_STATE ~= 1 then return false end
    if SERVER and (not ply.isTraitor or ply.SubRole ~= "traitor_fox") then return false end
    return ply:GetNWBool("HMCD_IsFox", false) == true
end
function F.CanAct(ply)
    if not F.IsFox(ply) or ply:InVehicle() then return false end
    if IsValid(ply.FakeRagdoll) or IsValid(ply:GetNWEntity("FakeRagdoll")) then return false end
    local org = ply.organism or {}
    return not org.otrub and not org.larmamputated and not org.rarmamputated
end
if SERVER then
    include("fox_phone_hack/sv_hack.lua")
else
    include("fox_phone_hack/cl_hack.lua")
    include("fox_phone_hack/cl_overlay.lua")
    include("fox_phone_hack/cl_ground.lua")
end
