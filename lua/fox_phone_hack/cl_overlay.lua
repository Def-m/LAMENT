-- 破译器的屏幕扫描框。由玩家的扫描状态驱动，与当前武器和世界轨迹线无关。
-- GMod 会单独热加载 include 的文件。保留同一个状态表，避免 HUDPaint
-- 换成新表、调用方仍持有旧表，导致扫描期间 HUD 永远停在 alpha = 0。
local hud = FoxPhoneHack_ScanHudState or {
    active = false,
    fromAlpha = 0,
    targetAlpha = 0,
    fadeAt = 0,
    fadeDuration = 0.4,
    count = 0,
    scanStartedAt = 0,
    scanEndsAt = 0,
    countChangedAt = -1,
    inertiaYaw = nil,
    inertiaPitch = nil,
    inertiaOffsetX = 0,
    inertiaOffsetY = 0
}
FoxPhoneHack_ScanHudState = hud
-- 热加载时沿用旧状态表，补齐新字段，避免旧表中的 nil 参与插值。
hud.inertiaOffsetX = hud.inertiaOffsetX or 0
hud.inertiaOffsetY = hud.inertiaOffsetY or 0
local HUD_LAYOUT_SCALE = 0.84
-- 视角变化带来的 HUD 惯性。数值保持克制，避免遮挡扫描信息。
local HUD_INERTIA_RESPONSE = 4
local HUD_INERTIA_YAW_SCALE = 2
local HUD_INERTIA_PITCH_SCALE = 2.5
local HUD_INERTIA_MAX_X = 48
local HUD_INERTIA_MAX_Y = 16

local function SmoothStep(value)
    value = math.Clamp(value, 0, 1)
    return value * value * (3 - 2 * value)
end

function hud:GetAlpha(now)
    local progress = SmoothStep((now - self.fadeAt) / self.fadeDuration)
    return Lerp(progress, self.fromAlpha, self.targetAlpha)
end

function hud:GetRemainingFraction(now)
    local duration = self.scanEndsAt - self.scanStartedAt
    -- 网络状态刚到、时间尚未到齐时暂时显示满格，不在客户端另起计时器。
    if duration <= 0 then return 1 end
    return math.Clamp((self.scanEndsAt - now) / duration, 0, 1)
end

function hud:SetState(active, count, scanStartedAt, scanEndsAt)
    local now = CurTime()
    if active ~= self.active then
        self.fromAlpha = self:GetAlpha(now)
        self.targetAlpha = active and 1 or 0
        self.fadeAt = now
        self.fadeDuration = active and 0.4 or 0.35
        self.active = active
        if active then
            self.scanStartedAt, self.scanEndsAt = 0, 0
        end
    end
    if active then
        count = math.Clamp(math.floor(count or 0), 0, 32)
        if self.count ~= count then self.countChangedAt = now end
        self.count = count
        if scanStartedAt and scanEndsAt and scanEndsAt > scanStartedAt then
            self.scanStartedAt, self.scanEndsAt = scanStartedAt, scanEndsAt
        end
    end
end

function hud:UpdateInertia(ply, frameTime, scaleFactor)
    if not IsValid(ply) then
        self.inertiaYaw = nil
        self.inertiaPitch = nil
        self.inertiaOffsetX = 0
        self.inertiaOffsetY = 0
        return 0, 0
    end

    local eyeAngles = ply:EyeAngles()
    local yaw, pitch = eyeAngles.y, eyeAngles.p
    if self.inertiaYaw == nil or self.inertiaPitch == nil then
        self.inertiaYaw, self.inertiaPitch = yaw, pitch
        self.inertiaOffsetX, self.inertiaOffsetY = 0, 0
        return 0, 0
    end

    frameTime = math.Clamp(frameTime or 0, 0, 0.1)
    local response = 1 - math.exp(-HUD_INERTIA_RESPONSE * frameTime)
    -- 使用角度差而不是直接相减，避免跨越 -180/180 度时 HUD 瞬移。
    local yawError = math.AngleDifference(yaw, self.inertiaYaw)
    local pitchError = math.AngleDifference(pitch, self.inertiaPitch)
    self.inertiaYaw = self.inertiaYaw + yawError * response
    self.inertiaPitch = self.inertiaPitch + pitchError * response

    local targetX = math.Clamp(-math.AngleDifference(yaw, self.inertiaYaw)
        * HUD_INERTIA_YAW_SCALE * scaleFactor, -HUD_INERTIA_MAX_X * scaleFactor,
        HUD_INERTIA_MAX_X * scaleFactor)
    local targetY = math.Clamp(math.AngleDifference(pitch, self.inertiaPitch)
        * HUD_INERTIA_PITCH_SCALE * scaleFactor, -HUD_INERTIA_MAX_Y * scaleFactor,
        HUD_INERTIA_MAX_Y * scaleFactor)
    self.inertiaOffsetX = Lerp(response, self.inertiaOffsetX, targetX)
    self.inertiaOffsetY = Lerp(response, self.inertiaOffsetY, targetY)
    return self.inertiaOffsetX, self.inertiaOffsetY
end

local cachedWidth, cachedHeight, scale
local function UpdateFonts(width, height)
    if width == cachedWidth and height == cachedHeight then return end
    cachedWidth, cachedHeight = width, height
    scale = math.Clamp(math.min(width / 1280, height / 720), 0.65, 2.5)
    surface.CreateFont("FoxPhoneHack_ScanHudLabel", {
        font = "Microsoft YaHei",
        size = math.floor(20 * scale + 0.5),
        weight = 400,
        antialias = true,
        extended = true
    })
    surface.CreateFont("FoxPhoneHack_ScanHudCount", {
        font = "Roboto Light",
        size = math.floor(32 * scale + 0.5),
        weight = 300,
        antialias = true
    })
end

local dotVertices = {}
for step = 0, 11 do
    local angle = step / 12 * math.pi * 2
    dotVertices[step + 1] = {x = 0, y = 0, dx = math.cos(angle), dy = math.sin(angle)}
end

local function DrawArcDot(x, y)
    local radius = 1.1 * scale
    for _, vertex in ipairs(dotVertices) do
        vertex.x, vertex.y = x + vertex.dx * radius, y + vertex.dy * radius
    end
    draw.NoTexture()
    surface.DrawPoly(dotVertices)
end

local function DrawDashedSegment(x1, y1, x2, y2, distance, visible, withDots, dashLength, period)
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= 0.001 then return distance end

    -- 点沿弧长放在留白正中，与两端线段保持相同距离。
    local endDistance = distance + length
    if visible ~= false then
        for dash = math.floor(distance / period), math.floor(endDistance / period) do
            local startAt = math.max(distance, dash * period)
            local endAt = math.min(endDistance, dash * period + dashLength)
            if endAt > startAt then
                local from, to = (startAt - distance) / length, (endAt - distance) / length
                surface.DrawLine(x1 + dx * from, y1 + dy * from, x1 + dx * to, y1 + dy * to)
            end
            local dotAt = dash * period + (dashLength + period) * 0.5
            if withDots and dotAt >= distance and dotAt < endDistance then
                local t = (dotAt - distance) / length
                DrawArcDot(x1 + dx * t, y1 + dy * t)
            end
        end
    end
    return endDistance
end

local function DrawFrameArc(centerX, y, halfWidth, gap, bend, side, opacity)
    -- 开放式弧线，不围住画面中心；两端用更低的 alpha 收尾。
    local previousX, previousY
    for step = 0, 24 do
        local t = step / 24
        local x = centerX + side * (gap + (halfWidth - gap) * t)
        local curveY = y + bend * t * t
        if previousX then
            local edgeAlpha = 1 - SmoothStep((t - 0.72) / 0.28) * 0.6
            surface.SetDrawColor(255, 255, 255, math.floor(opacity * edgeAlpha + 0.5))
            surface.DrawLine(previousX, previousY, x, curveY)
        end
        previousX, previousY = x, curveY
    end
end

local function DrawSideArc(centerX, topY, bottomY, halfWidth, bow, side, opacity, gapTop, gapBottom)
    -- 左（右）：中间向画面外侧鼓出，上下端点向中心收回；独立于上下横线。
    local halfAngle = math.rad(50)
    local radiusX = bow / (1 - math.cos(halfAngle))
    local radiusY = (bottomY - topY) * 0.5 / math.sin(halfAngle)
    local centerY = (topY + bottomY) * 0.5
    local dashLength, period = 8 * scale, 14 * scale
    if side < 0 then
        -- 左弧使用更疏的点划线，并让两端都以完整线段收尾，点位上下对称。
        local arcLength = 0
        local lastX, lastY = radiusX * math.cos(-halfAngle), radiusY * math.sin(-halfAngle)
        for step = 1, 64 do
            local angle = Lerp(step / 64, -halfAngle, halfAngle)
            local x, y = radiusX * math.cos(angle), radiusY * math.sin(angle)
            arcLength = arcLength + math.sqrt((x - lastX) ^ 2 + (y - lastY) ^ 2)
            lastX, lastY = x, y
        end
        dashLength = 30 * scale
        local gaps = math.max(1, math.floor((arcLength - dashLength) / (54 * scale) + 0.5))
        period = (arcLength - dashLength) / gaps
    end
    local previousX, previousY
    local distance = 0
    for step = 0, 64 do
        local t = step / 64
        local angle = Lerp(t, -halfAngle, halfAngle)
        local x = centerX + side * (halfWidth - radiusX * (1 - math.cos(angle)))
        local y = centerY + radiusY * math.sin(angle)
        if previousX then
            local visible = not gapTop or y < gapTop or previousY > gapBottom
            local edgeAlpha = 0.65 + 0.35 * math.sin(t * math.pi)
            surface.SetDrawColor(255, 255, 255, math.floor(opacity * edgeAlpha + 0.5))
            distance = DrawDashedSegment(previousX, previousY, x, y, distance, visible, side < 0, dashLength, period)
        end
        previousX, previousY = x, y
    end
end

local function DrawDurationBattery(centerX, centerY, remaining, alpha)
    local width, height = 54 * scale, 20 * scale
    local capWidth, capHeight = 3 * scale, 8 * scale
    local x, y = centerX - (width + capWidth) * 0.5, centerY - height * 0.5
    local stroke, inset = scale, 4 * scale

    -- 电池外框固定，内部电量按整次技能的剩余时间连续减少。
    surface.SetDrawColor(255, 255, 255, math.floor(112 * alpha + 0.5))
    surface.DrawRect(x, y, width, stroke)
    surface.DrawRect(x, y + height - stroke, width, stroke)
    surface.DrawRect(x, y + stroke, stroke, height - 2 * stroke)
    surface.DrawRect(x + width - stroke, y + stroke, stroke, height - 2 * stroke)
    surface.DrawRect(x + width, centerY - capHeight * 0.5, capWidth, capHeight)

    local fillWidth = (width - 2 * inset) * math.Clamp(remaining, 0, 1)
    if fillWidth > 0 then
        surface.SetDrawColor(255, 255, 255, math.floor(196 * alpha + 0.5))
        surface.DrawRect(x + inset, y + inset, fillWidth, height - 2 * inset)
    end
end

local function DrawScanHud()
    local ply = LocalPlayer()
    local validPlayer = IsValid(ply)
    local active = validPlayer and FoxPhoneHack.CanAct(ply) and ply:GetNWFloat("FoxHackEnd", 0) > CurTime()
    local signals = FoxPhoneHack.Targets or {}
    -- 绘制模块自行同步玩家状态，不依赖主脚本的局部引用或地面网点更新是否成功。
    hud:SetState(active, #signals,
        validPlayer and ply:GetNWFloat("FoxHackStart", 0) or 0,
        validPlayer and ply:GetNWFloat("FoxHackEnd", 0) or 0)
    local inertiaX, inertiaY = hud:UpdateInertia(ply, FrameTime(), HUD_LAYOUT_SCALE)
    if not FoxPhoneHack.IsFox(ply) then return end
    if hook.Run("HUDShouldDraw", "FoxPhoneHack_ScanOverlay") == false then return end

    local now = CurTime()
    local alpha = hud:GetAlpha(now)
    if alpha <= 0.001 then return end

    local width, height = ScrW(), ScrH()
    UpdateFonts(width, height)
    -- 整个扫描框以同一偏移量移动，电池、弧线和计数保持相对位置不变。
    local centerX, centerY = width * 0.5 + inertiaX, height * 0.5 + inertiaY
    -- 超宽屏保持框和计数靠近主要视野，字体大小按实际分辨率缓存。
    local frameWidth = math.min(width, height * 16 / 9)
    local halfWidth = frameWidth * 0.4 * HUD_LAYOUT_SCALE * (0.96 + 0.04 * alpha)
    -- 横线与侧弧共用同一个垂直中心和高度基准，渐入渐出时也保持上下等距。
    local frameHalfHeight = height * 0.3875 * HUD_LAYOUT_SCALE - (1 - alpha) * 12 * scale
    local topY, bottomY = centerY - frameHalfHeight, centerY + frameHalfHeight
    local frameBend = 11 * scale
    local topGap = 54 * scale
    local bottomGap = 152 * scale * HUD_LAYOUT_SCALE * 0.65
    for _, side in ipairs({-1, 1}) do
        DrawFrameArc(centerX, topY, halfWidth, topGap, -frameBend, side, 82 * alpha)
        DrawFrameArc(centerX, bottomY, halfWidth, bottomGap, frameBend, side, 62 * alpha)
    end

    -- 两侧弧线共用屏幕中心，左右镜像、上下等距。
    local arcCenterX, arcCenterY = centerX, centerY
    local arcHalfWidth = frameWidth * 0.315 * (0.98 + 0.02 * alpha)
    local arcHalfHeight = frameHalfHeight - 24 * scale
    local arcTopY, arcBottomY = arcCenterY - arcHalfHeight, arcCenterY + arcHalfHeight
    local bow = frameWidth * 0.08
    DrawSideArc(arcCenterX, arcTopY, arcBottomY,
        arcHalfWidth, bow, -1, 88 * alpha)
    DrawSideArc(arcCenterX, arcTopY, arcBottomY,
        arcHalfWidth, bow, 1, 88 * alpha)

    DrawDurationBattery(centerX, topY, hud:GetRemainingFraction(now), alpha)


end

hook.Add("HUDPaint", "FoxPhoneHack_ScanOverlay", DrawScanHud)

return hud
