if SERVER then AddCSLuaFile() end
hg = hg or {}

-- A fake player's hidden engine body does not determine the visibility of
-- the item attached to the ragdoll. Unknown initial transmission state is
-- not an explicit cull; keep the existing visibility system's true/false result.
function hg.IsHeldWeaponCulled(owner)
    if not IsValid(owner) then return false end
    local body = hg.GetCurrentCharacter and hg.GetCurrentCharacter(owner) or owner
    if not IsValid(body) then body = owner end
    return body.shouldTransmit == false or body.NotSeen == true
end

-- Server-side retention during ragdoll entry, unconsciousness and fake-up Spawn.
-- Explicit drops/disarms use their existing paths and are not intercepted here.
function hg.KeepWeaponInRagdoll(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if IsValid(ply.FakeRagdoll) or ply.hgFakeUpSpawning then return true end
    local org = ply.organism
    return org ~= nil and (org.otrub == true or org.needotrub == true or org.needfake == true)
end
