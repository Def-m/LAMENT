local F = FoxPhoneHack
local targets = {}
F.Targets = targets
local status, statusUntil = "", 0
local props = {}
local function InAnimation(ply)
    return IsValid(ply) and CurTime() < ply:GetNWFloat("FoxHackAnimationEnd", 0)
end
-- Z-City normally maps only the left hand for gestures. This sequence operates
-- the decoder with both hands, so map the right hand/fingers in its draw callback.
local function DrawDecoder(character, ply, vm, progress)
    if not InAnimation(ply) then return end
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) then weapon.rhandik = true end
    local blend = math.Clamp(math.min(progress * 8, (1 - progress) * 8), 0, 1)
    for _, boneName in ipairs(hg.TPIKBonesRH or {}) do
        local sourceBone, targetBone = vm:LookupBone(boneName), character:LookupBone(boneName)
        if sourceBone and targetBone then
            local source, destination = vm:GetBoneMatrix(sourceBone), character:GetBoneMatrix(targetBone)
            if source and destination then
                destination:SetTranslation(LerpVector(blend, destination:GetTranslation(), source:GetTranslation()))
                destination:SetAngles(LerpAngle(blend, destination:GetAngles(), source:GetAngles()))
                character:SetBoneMatrix(targetBone, destination)
            end
        end
    end
    local hand = vm:LookupBone("ValveBiped.Bip01_R_Hand")
    local matrix = hand and vm:GetBoneMatrix(hand)
    if not matrix then return end
    local prop = props[ply]
    if not IsValid(prop) then
        prop = ClientsideModel("models/sjz/w_sjz_decipherer.mdl", RENDERGROUP_OPAQUE)
        if not IsValid(prop) then return end
        prop:SetNoDraw(true)
        props[ply] = prop
    end
    -- Keep the original addon's hand attachment transform.
    local angles = matrix:GetAngles()
    angles:RotateAroundAxis(angles:Right(), 180)
    local position = matrix:GetTranslation() + angles:Right() - angles:Forward() * 3.5 - angles:Up() * 0.5
    prop:SetRenderOrigin(position)
    prop:SetRenderAngles(angles)
    prop.FoxHackReady = true
end
local wrappedRender
local function RegisterAnimation()
    -- Remove the original addon's shortcut if a separately installed copy survives.
    hook.Remove("Think", "MXW_SJZ_Keybind")
    hook.Remove("PlayerButtonDown", "MXW_SJZ_Keybind_Button")
    concommand.Remove("mxw_sjz_use")
    -- The original addon has a separate music/tablet shortcut on K.
    hook.Remove("Think", "MXW_SJZ_MusicKey")
    hook.Remove("PlayerButtonDown", "MXW_SJZ_MusicButton")
    concommand.Remove("mxw_sjz_music")
    if not hg or not hg.ZManipAnims then return end
    hg.ZManipAnims.fox_phone_decoder = {
        mdl = "models/sjz/v_sjz_decipherer.mdl", seq = "turnon", playTime = F.Warmup,
        otherData = {posAdjust = Vector(6, 0, 0)}, drawFunc = DrawDecoder
    }
    if hg.RenderWeapons and hg.RenderWeapons ~= wrappedRender then
        local original = hg.RenderWeapons
        wrappedRender = function(character, owner, ...)
            if InAnimation(owner) then return end
            return original(character, owner, ...)
        end
        hg.RenderWeapons = wrappedRender
    end
end
hook.Add("InitPostEntity", "FoxPhoneHackAnimation", RegisterAnimation)
hook.Add("OnReloaded", "FoxPhoneHackAnimation", RegisterAnimation)
timer.Create("FoxPhoneHackAnimation", 2, 0, RegisterAnimation)
timer.Simple(0, RegisterAnimation)
hook.Add("PreDrawViewModel", "FoxPhoneHackViewModel", function(_, ply)
    if InAnimation(ply) then return true end
end)
hook.Add("PostDrawTranslucentRenderables", "FoxPhoneHackDecoderProp", function(depth, sky)
    if depth or sky then return end
    for ply, prop in pairs(props) do
        if InAnimation(ply) and IsValid(prop) and prop.FoxHackReady then prop:DrawModel() end
    end
end)
local animationEnds = setmetatable({}, {__mode = "k"})
hook.Add("Think", "FoxPhoneHackAnimationSync", function()
    if not hg or not hg.RunZManipAnim or not hg.ZManipAnims or not hg.ZManipAnims.fox_phone_decoder then return end
    for _, ply in ipairs(player.GetAll()) do
        local ends = ply:GetNWFloat("FoxHackAnimationEnd", 0)
        if ends > CurTime() and animationEnds[ply] ~= ends then
            -- Native RunZManipAnim returns early before Z-City creates zmodel.
            if not IsValid(ply.zmodel) then
                ply.zmodel = ClientsideModel("models/sjz/v_sjz_decipherer.mdl")
                if IsValid(ply.zmodel) then ply.zmodel:SetNoDraw(true) end
            end
            if IsValid(ply.zmodel) then
                hg.RunZManipAnim(ply, "fox_phone_decoder", false, F.Warmup)
                ply.zmanipstart = ends - F.Warmup
                animationEnds[ply] = ends
            end
        elseif ends <= CurTime() and ply.zmanipanim == "fox_phone_decoder" then
            ply.zmanipstart = nil
        end
    end
end)
hook.Add("Think", "FoxPhoneHackCleanup", function()
    for ply, prop in pairs(props) do
        if not InAnimation(ply) then
            if IsValid(prop) then prop:Remove() end
            props[ply] = nil
        end
    end
    local ply = LocalPlayer()
    if not F.CanAct(ply) or CurTime() >= ply:GetNWFloat("FoxHackEnd", 0) then targets = {} F.Targets = targets end
    if IsValid(ply) and ply.zmanipanim == "fox_phone_decoder" and not InAnimation(ply) then
        ply.zmanipstart = nil
    end
end)
hook.Add("ShutDown", "FoxPhoneHackModels", function()
    for _, prop in pairs(props) do if IsValid(prop) then prop:Remove() end end
end)
hook.Add("radialOptions", "FoxPhoneHack", function()
    local ply = LocalPlayer()
    if not F.CanAct(ply) then return end
    local active = ply:GetNWFloat("FoxHackEnd", 0) > CurTime()
    local remaining = math.ceil(ply:GetNWFloat("FoxHackCooldown", 0) - CurTime())
    hg.radialOptions[#hg.radialOptions + 1] = {
        function()
            if active or CurTime() < ply:GetNWFloat("FoxHackCooldown", 0) then return end
            net.Start("FoxPhoneHackStart") net.SendToServer()
        end,
        active and "Hack Tablet (ACTIVE)" or (remaining > 0 and ("Hack Tablet (" .. remaining .. "s)") or "Hack Tablet")
    }
end)
net.Receive("FoxPhoneHackTargets", function()
    local updated = {}
    for i = 1, net.ReadUInt(6) do
        updated[i] = {id = net.ReadUInt(16), pos = net.ReadVector(), trap = net.ReadBool(), calling = net.ReadBool(), disabled = net.ReadFloat()}
    end
    targets = updated
    F.Targets = targets
end)
net.Receive("FoxPhoneHackStatus", function()
    status = net.ReadString() statusUntil = CurTime() + 3
    surface.PlaySound("buttons/blip1.wav")
end)
local function SelectedTarget(ply)
    if not F.CanAct(ply) or CurTime() >= ply:GetNWFloat("FoxHackEnd", 0) then return end
    local best, bestDot = nil, F.AimDot
    for _, target in ipairs(targets) do
        local delta = target.pos - ply:EyePos()
        local dot = ply:GetAimVector():Dot(delta:GetNormalized())
        local range = target.trap and F.TrapRange or F.Range
        if dot > bestDot and ply:GetPos():DistToSqr(target.pos) <= range * range and target.disabled <= CurTime() then
            best, bestDot = target, dot
        end
    end
    return best
end
hook.Add("PlayerBindPress", "FoxPhoneHackRemoteShock", function(ply, bind, pressed)
    if not pressed or bind ~= "+use" then return end
    if vgui.CursorVisible() or gui.IsGameUIVisible() then return end
    local target = SelectedTarget(ply)
    if not target then return end
    if not target.trap and CurTime() < ply:GetNWFloat("FoxShockCooldown", 0) then return true end
    net.Start("FoxPhoneHackShock") net.WriteUInt(target.id, 16) net.SendToServer()
    return true
end)
hook.Add("HUDPaint", "FoxPhoneHackMarkers", function()
    local ply = LocalPlayer()
    if not F.CanAct(ply) then return end
    if CurTime() < statusUntil then
        draw.SimpleText(status, "DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.70, Color(235, 235, 235), TEXT_ALIGN_CENTER)
    end
    local ends = ply:GetNWFloat("FoxHackEnd", 0)
    if ends <= CurTime() then return end
    local selected = SelectedTarget(ply)
    for _, target in ipairs(targets) do
        local screen = target.pos:ToScreen()
        if screen.visible then
            local color = target == selected and Color(255, 70, 70) or Color(190, 190, 190)
            local size = target == selected and 12 or 9
            surface.SetDrawColor(color)
            surface.DrawLine(screen.x, screen.y - size, screen.x + size, screen.y)
            surface.DrawLine(screen.x + size, screen.y, screen.x, screen.y + size)
            surface.DrawLine(screen.x, screen.y + size, screen.x - size, screen.y)
            surface.DrawLine(screen.x - size, screen.y, screen.x, screen.y - size)
            local label = target.trap and (target.disabled > CurTime() and "TRAP UNAVAILABLE" or "TRAP")
                or (target.disabled > CurTime() and "DISABLED" or (target.calling and "CALLING" or "PHONE"))
            draw.SimpleText(label, "DermaDefaultBold", screen.x, screen.y + size + 4, color, TEXT_ALIGN_CENTER)
        end
    end
    if selected then
        local cooldown = math.ceil(ply:GetNWFloat("FoxShockCooldown", 0) - CurTime())
        local key = string.upper(input.LookupBinding("+use") or "E")
        draw.SimpleText(selected.trap and ("[" .. key .. "] ACTIVATE TRAP")
            or (cooldown > 0 and ("SHOCK RECHARGING: " .. cooldown .. "s") or ("[" .. key .. "] SHOCK PHONE")),
            "DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.60, Color(255, 80, 80), TEXT_ALIGN_CENTER)
    end
end)
