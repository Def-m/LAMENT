hg = hg or {}

local looseMelee = setmetatable({}, {__mode = "k"})
local function IsLooseMelee(wep)
    return IsValid(wep) and wep:IsWeapon() and wep.ismelee2
        and not IsValid(wep:GetOwner()) and not IsValid(wep:GetParent())
end

function hg.RestoreDroppedMeleeCollision(wep)
    if not IsLooseMelee(wep) then return false end
    local phys = wep:GetPhysicsObject()
    local repaired = not IsValid(phys) or wep:GetSolid() ~= SOLID_VPHYSICS
        or wep:GetMoveType() ~= MOVETYPE_VPHYSICS
        or bit.band(wep:GetSolidFlags(), FSOLID_NOT_SOLID) ~= 0
        or wep:GetCollisionGroup() ~= COLLISION_GROUP_WEAPON
        or (IsValid(phys) and not phys:IsCollisionEnabled())
    if not repaired then return true end

    if not IsValid(phys) then
        wep:PhysicsInit(SOLID_VPHYSICS)
        phys = wep:GetPhysicsObject()
        if not IsValid(phys) then
            -- Some custom melee models have no compiled collision mesh.
            local mins, maxs = wep:OBBMins(), wep:OBBMaxs()
            if (maxs - mins):LengthSqr() <= 0 then return false end
            wep:PhysicsInitBox(mins, maxs)
            phys = wep:GetPhysicsObject()
        end
    end
    if not IsValid(phys) then return false end
    wep:SetSolid(SOLID_VPHYSICS)
    wep:RemoveSolidFlags(FSOLID_NOT_SOLID)
    wep:SetMoveType(MOVETYPE_VPHYSICS)
    wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    phys:EnableCollisions(true)
    phys:EnableMotion(true)
    phys:Wake()
    return true
end

function hg.TrackDroppedMelee(wep)
    if not IsValid(wep) or not wep:IsWeapon() or not wep.ismelee2 then return end
    looseMelee[wep] = true
    hg.RestoreDroppedMeleeCollision(wep)
end

-- Recover state again after engine drop/fake-up callbacks have completed.
hook.Add("OnEntityCreated", "ChudMeleeCollisionTrack", function(ent)
    timer.Simple(0, function() hg.TrackDroppedMelee(ent) end)
end)
hook.Add("InitPostEntity", "ChudMeleeCollisionExisting", function()
    for _, ent in ipairs(ents.GetAll()) do hg.TrackDroppedMelee(ent) end
end)
timer.Create("ChudMeleeCollisionRepair", 0.1, 0, function()
    for wep in pairs(looseMelee) do
        if not IsValid(wep) then looseMelee[wep] = nil
        elseif IsLooseMelee(wep) then hg.RestoreDroppedMeleeCollision(wep) end
    end
end)

-- Check the entire rotated weapon, not just its origin or the hand bone.
function hg.PlaceDroppedMelee(wep, desired, angles, carrier, ply)
    if not IsValid(wep) or not wep.ismelee2 then return false end
    if IsValid(wep:GetOwner()) or IsValid(wep:GetParent()) then return false end
    if not hg.RestoreDroppedMeleeCollision(wep) then return false end
    hg.TrackDroppedMelee(wep)
    local lo, hi = wep:OBBMins(), wep:OBBMaxs()
    local mins = Vector(math.huge, math.huge, math.huge)
    local maxs = Vector(-math.huge, -math.huge, -math.huge)
    for _, x in ipairs({lo.x, hi.x}) do
        for _, y in ipairs({lo.y, hi.y}) do
            for _, z in ipairs({lo.z, hi.z}) do
                local corner = Vector(x, y, z)
                corner:Rotate(angles)
                for _, axis in ipairs({"x", "y", "z"}) do
                    mins[axis] = math.min(mins[axis], corner[axis] - 1)
                    maxs[axis] = math.max(maxs[axis], corner[axis] + 1)
                end
            end
        end
    end
    local filter = {wep}
    if IsValid(carrier) then filter[#filter + 1] = carrier end
    if IsValid(ply) then filter[#filter + 1] = ply end
    local function trace(a, b)
        return util.TraceHull({start = a, endpos = b, mins = mins, maxs = maxs,
            filter = filter, mask = MASK_SOLID})
    end
    local function clear(pos)
        local tr = trace(pos, pos)
        return not tr.StartSolid and not tr.AllSolid and not tr.Hit
    end
    local safe
    do
        local candidates = {}
        -- Sweep from the body's side of the floor even if the target is already
        -- in empty space underneath a thin brush.
        if IsValid(carrier) then candidates[#candidates + 1] = carrier:WorldSpaceCenter() + Vector(0, 0, 32) end
        if IsValid(ply) then candidates[#candidates + 1] = ply:EyePos() end
        -- Lift out of the floor even when the hand and weapon origin are buried.
        for _, height in ipairs({16, 32, 64, 96, 128}) do
            candidates[#candidates + 1] = desired + Vector(0, 0, height)
        end
        if IsValid(carrier) then candidates[#candidates + 1] = carrier:WorldSpaceCenter() + Vector(0, 0, 32) end
        if IsValid(ply) then candidates[#candidates + 1] = ply:EyePos() end
        candidates[#candidates + 1] = wep:GetPos()
        for _, start in ipairs(candidates) do
            if clear(start) then
                local tr = trace(start, desired)
                local pos = tr.Hit and (tr.HitPos + tr.HitNormal * 2) or desired
                safe = clear(pos) and pos or start
                break
            end
        end
    end
    if not safe then return false end -- Keep the last position instead of forcing an embedded one.
    wep:RemoveSolidFlags(FSOLID_NOT_SOLID)
    wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    wep:SetMoveType(MOVETYPE_VPHYSICS)
    wep:SetAngles(angles)
    wep:SetPos(safe)
    local phys = wep:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableCollisions(true)
        phys:EnableMotion(true)
        phys:Wake()
    end
    return true, safe:DistToSqr(desired) > 0.01
end
