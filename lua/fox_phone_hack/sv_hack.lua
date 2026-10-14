local F = FoxPhoneHack
for _, name in ipairs({"FoxPhoneHackStart", "FoxPhoneHackTargets", "FoxPhoneHackShock", "FoxPhoneHackStatus"}) do
    util.AddNetworkString(name)
end
-- Original animation/material/sound assets are shipped with the full build.
local function AddResources(dir)
    local files, dirs = file.Find(dir .. "/*", "GAME")
    for _, name in ipairs(files or {}) do resource.AddFile(dir .. "/" .. name) end
    for _, name in ipairs(dirs or {}) do AddResources(dir .. "/" .. name) end
end
AddResources("models/sjz")
AddResources("materials/sjz")
AddResources("sound/sjz")
AddResources("materials/vgui/ttt")
resource.AddFile("materials/entities/activator_new.vmt")
resource.AddFile("materials/entities/activator_new.vtf")
local scans = {}
-- Keep sound ownership across Lua reloads so an existing loop can still be stopped.
F.ShockSounds = F.ShockSounds or {}
local shockSounds = F.ShockSounds
local function StopShockSound(ply)
    local state = shockSounds[ply]
    if not state then return end
    shockSounds[ply] = nil
    if IsValid(ply) then
        ply:StopSound("tazer.wav")
        if IsValid(ply.FakeRagdoll) then ply.FakeRagdoll:StopSound("tazer.wav") end
    end
    if IsValid(state.ragdoll) then state.ragdoll:StopSound("tazer.wav") end
end
hook.Add("Think", "FoxPhoneHackStopTaserSound", function()
    for ply, state in pairs(shockSounds) do
        if not IsValid(ply) or not ply:Alive() or CurTime() >= state.ends then
            StopShockSound(ply)
        end
    end
end)
hook.Add("PlayerDeath", "FoxPhoneHackStopTaserSound", StopShockSound)
hook.Add("PlayerSpawn", "FoxPhoneHackStopTaserSound", StopShockSound)
hook.Add("PlayerDisconnected", "FoxPhoneHackStopTaserSound", StopShockSound)

local function Status(ply, text)
    net.Start("FoxPhoneHackStatus") net.WriteString(text) net.Send(ply)
end
local function Clear(ply, reset)
    local state = scans[ply]
    scans[ply] = nil
    if not IsValid(ply) then return end
    if state and not reset then
        -- Start the full cooldown when the scan completes or is interrupted.
        ply:SetNWFloat("FoxHackCooldown", math.min(CurTime(), state.ends) + F.ScanCooldown)
    end
    ply:SetNWFloat("FoxHackStart", 0)
    ply:SetNWFloat("FoxHackEnd", 0)
    ply:SetNWFloat("FoxHackAnimationEnd", 0)
    if reset then
        ply:SetNWFloat("FoxHackCooldown", 0)
        ply:SetNWFloat("FoxShockCooldown", 0)
    end
    net.Start("FoxPhoneHackTargets") net.WriteUInt(0, 6) net.Send(ply)
end
function F.PhoneHolder(phone)
    local owner = phone:GetOwner()
    if not phone.FoxPhoneDropped and IsValid(owner) and owner:IsPlayer()
        and owner:GetWeapon(phone:GetClass()) == phone then return owner end
end
function F.PhonePosition(phone)
    local owner = F.PhoneHolder(phone)
    if IsValid(owner) then
        local char = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner
        return char:WorldSpaceCenter()
    end
    -- Z-City parents hidden corpse inventory weapons below the ragdoll.
    local parent = phone:GetParent()
    if IsValid(parent) then return parent:WorldSpaceCenter() end
    return phone:WorldSpaceCenter()
end
function F.ValidPhone(ply, phone)
    return IsValid(phone) and (phone:GetClass() == F.PhoneClass or phone:GetClass() == F.RadioClass)
        and F.PhoneHolder(phone) ~= ply
        and not (phone.GetSpent and phone:GetSpent())
        and not (phone.IsRadioDestroyed and phone:IsRadioDestroyed())
        and not phone:GetNWBool("FoxPhoneDestroyed", false) and not phone.FoxPhoneDestroyed
        and ply:GetPos():DistToSqr(F.PhonePosition(phone)) <= F.Range * F.Range
end
function F.ValidTrap(ply, trap)
    return IsValid(trap) and trap:GetClass() == F.TrapClass
        and isfunction(trap.IsUsable) and isfunction(trap.GetDelay)
        and ply:GetPos():DistToSqr(trap:GetPos()) <= F.TrapRange * F.TrapRange
end
local function TargetPosition(ent)
    return ent:GetClass() == F.TrapClass and ent:GetPos() or F.PhonePosition(ent)
end
local function SendTargets(ply, state)
    local found = {}
    for _, phone in ipairs(ents.FindByClass(F.PhoneClass)) do
        if F.ValidPhone(ply, phone) then found[#found + 1] = phone end
    end
    for _, radio in ipairs(ents.FindByClass(F.RadioClass)) do
        if F.ValidPhone(ply, radio) then found[#found + 1] = radio end
    end
    for _, trap in ipairs(ents.FindByClass(F.TrapClass)) do
        if F.ValidTrap(ply, trap) then found[#found + 1] = trap end
    end
    table.sort(found, function(a, b)
        return ply:GetPos():DistToSqr(TargetPosition(a)) < ply:GetPos():DistToSqr(TargetPosition(b))
    end)
    state.targets = {}
    local count = math.min(#found, 63)
    net.Start("FoxPhoneHackTargets") net.WriteUInt(count, 6)
    for i = 1, count do
        local target = found[i]
        local trap = target:GetClass() == F.TrapClass
        state.targets[target] = true
        net.WriteUInt(target:EntIndex(), 16)
        net.WriteVector(TargetPosition(target))
        net.WriteBool(trap)
        net.WriteBool(not trap and ((target.GetCalling and target:GetCalling()) or (target.GetInUsing and target:GetInUsing())) or false)
        local disabled = trap and (target:GetLocked() and CurTime() + 1 or target:GetNextUseTime())
            or target:GetNWFloat("FoxPhoneDisabledUntil", 0)
        net.WriteFloat(disabled)
    end
    net.Send(ply)
end

function F.TryActivateTrap(ply, trap)
    if not F.CanAct(ply) then return false end
    local state, now = scans[ply], CurTime()
    if not state or now < state.ready or now >= state.ends then return false end
    if now < (state.nextTrap or 0) or not state.targets[trap] or not F.ValidTrap(ply, trap) then return false end
    if not trap:IsUsable() then return false end
    if ply:GetAimVector():Dot((trap:GetPos() - ply:EyePos()):GetNormalized()) < F.AimDot then return false end
    if hook.Run("TTTCanUseTraitorButton", trap, ply) == false then return false end
    -- Reserve before map outputs: outputs can re-enter, remove entities or end a round.
    state.nextTrap = now + 0.25
    local remove = trap.RemoveOnPress or trap:GetDelay() < 0
    if remove then trap:SetLocked(true)
    else trap:SetNextUseTime(now + math.max(0.25, trap:GetDelay())) end
    trap:TriggerOutput("OnPressed", ply)
    if remove and IsValid(trap) then trap:Remove() end
    hook.Run("TTTTraitorButtonActivated", trap, ply)
    if scans[ply] == state and F.CanAct(ply) then SendTargets(ply, state) end
    Status(ply, "TRAP ACTIVATED")
    return true
end

net.Receive("FoxPhoneHackStart", function(_, ply)
    if not F.CanAct(ply) then return end
    if scans[ply] or CurTime() < ply:GetNWFloat("FoxHackCooldown", 0) then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep.reload or IsValid(ply:GetNetVar("carryent2")) then return end
    local now = CurTime()
    scans[ply] = {ready = now + F.Warmup, ends = now + F.Warmup + F.Duration, targets = {}, nextTick = 0}
    ply:SetNWFloat("FoxHackStart", now + F.Warmup)
    ply:SetNWFloat("FoxHackEnd", now + F.Warmup + F.Duration)
    ply:SetNWFloat("FoxHackCooldown", now + F.Warmup + F.Duration + F.ScanCooldown)
    ply:SetNWFloat("FoxHackAnimationEnd", now + F.Warmup)
    if hg and hg.RunZManipAnim then hg.RunZManipAnim(ply, "fox_phone_decoder", false, F.Warmup) end
    ply:EmitSound("sjz/mxw/C202_Ultimate_SignalDecipher_Char_Raise1_01.wav", 65)
    timer.Simple(0.55, function()
        if not IsValid(ply) or not scans[ply] or not F.CanAct(ply) then return end
        ply:EmitSound("sjz/mxw/C202_Ultimate_SignalDecipher_Char_Activate.wav", 65)
    end)
    Status(ply, "SCANNING DEVICES")
end)
hook.Add("Think", "FoxPhoneHackScan", function()
    local now = CurTime()
    for ply, state in pairs(scans) do
        if not F.CanAct(ply) or now >= state.ends then
            Clear(ply)
        elseif now >= state.ready and now >= state.nextTick then
            state.nextTick = now + 0.35
            SendTargets(ply, state)
        end
    end
end)
net.Receive("FoxPhoneHackShock", function(_, ply)
    local index = net.ReadUInt(16)
    if not F.CanAct(ply) then return end
    local state = scans[ply]
    local now = CurTime()
    if not state or now < state.ready or now >= state.ends then return end
    local phone = Entity(index)
    if IsValid(phone) and phone:GetClass() == F.TrapClass then
        F.TryActivateTrap(ply, phone)
        return
    end
    if now < ply:GetNWFloat("FoxShockCooldown", 0) then return end
    if not state.targets[phone] or not F.ValidPhone(ply, phone) then return end
    if now < phone:GetNWFloat("FoxPhoneDisabledUntil", 0) then return end
    local position = F.PhonePosition(phone)
    if ply:GetAimVector():Dot((position - ply:EyePos()):GetNormalized()) < F.AimDot then return end
    -- Reserve cooldown before callbacks such as Fake/CancelCall can run.
    ply:SetNWFloat("FoxShockCooldown", now + F.ShockCooldown)
    local owner = F.PhoneHolder(phone)
    if phone:GetClass() == F.RadioClass then
        phone:DestroyRadio()
    else
        phone:DestroyPhone()
    end
    for scanner, scan in pairs(scans) do
        if F.CanAct(scanner) and now >= scan.ready then SendTargets(scanner, scan) end
    end
    if IsValid(owner) and owner:IsPlayer() and owner:Alive() and owner.organism then
        if hg and hg.StunPlayer then hg.StunPlayer(owner, F.StunTime) end
        owner.organism.tasered = now + F.StunTime
        StopShockSound(owner)
        shockSounds[owner] = {ends = now + F.StunTime, ragdoll = owner.FakeRagdoll}
        owner:EmitSound("tazer.wav", 75, 100)
        if phone.SendPhoneStatus then phone:SendPhoneStatus("PHONE SHOCKED", "PHONE PERMANENTLY DISABLED", 3) end
    end
    local fx = EffectData() fx:SetOrigin(position) fx:SetMagnitude(1) fx:SetScale(1)
    util.Effect("Sparks", fx, true, true)
    sound.Play("ambient/energy/spark2.wav", position, 70, 100, 1)
    Status(ply, "REMOTE SHOCK DELIVERED")
end)
-- Prevent firing a weapon through the two-handed activation animation.
hook.Add("StartCommand", "FoxPhoneHackAnimationLock", function(ply, cmd)
    if CurTime() < ply:GetNWFloat("FoxHackAnimationEnd", 0) then
        cmd:RemoveKey(IN_ATTACK) cmd:RemoveKey(IN_ATTACK2) cmd:RemoveKey(IN_RELOAD)
    end
end)
hook.Add("PlayerDeath", "FoxPhoneHackDeath", function(ply) Clear(ply) end)
hook.Add("Fake", "FoxPhoneHackRagdoll", function(ply) Clear(ply) end)
hook.Add("PlayerSpawn", "FoxPhoneHackSpawn", function(ply) Clear(ply, true) end)
hook.Add("PlayerDisconnected", "FoxPhoneHackDisconnect", function(ply) scans[ply] = nil end)
local function ResetRound()
    for ply in pairs(shockSounds) do StopShockSound(ply) end
    for _, ply in ipairs(player.GetAll()) do Clear(ply, true) end
    for _, phone in ipairs(ents.FindByClass(F.PhoneClass)) do phone:SetNWFloat("FoxPhoneDisabledUntil", 0) end
end
hook.Add("ZB_PreRoundStart", "FoxPhoneHackRoundStart", ResetRound)
hook.Add("ZB_EndRound", "FoxPhoneHackRoundEnd", ResetRound)

-- Disable both legacy tablet entry points, including the independent K shortcut.
-- The Technician Hack Tablet radial menu uses FoxPhoneHackStart and remains role/cooldown checked.
local IgnoreLegacyShortcut = function() end
local function DisableLegacyShortcut()
    for _, name in ipairs({"mxw_sjz_use", "mxw_sjz_music"}) do
        if net.Receivers and net.Receivers[name] and net.Receivers[name] ~= IgnoreLegacyShortcut then
            net.Receive(name, IgnoreLegacyShortcut)
        end
    end
end
DisableLegacyShortcut()
hook.Add("InitPostEntity", "FoxPhoneHackDisableLegacyShortcut", DisableLegacyShortcut)
hook.Add("OnReloaded", "FoxPhoneHackDisableLegacyShortcut", function()
    timer.Simple(0, DisableLegacyShortcut)
end)
timer.Simple(0, DisableLegacyShortcut)
timer.Create("FoxPhoneHackDisableLegacyShortcut", 2, 0, DisableLegacyShortcut)
