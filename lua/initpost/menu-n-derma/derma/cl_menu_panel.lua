local PANEL = {}
local curent_panel 
local red_select = Color(192,0,0)
local menu_music_default_path = "sound/rem_mainmenu.mp3"
local menu_music_appearance_path = "sound/rem_track1.mp3"
local menu_music_flags = "noblock noplay"
local menu_music_volume = 0.6
local menu_music_fade_speed = 1.8
local menu_music_station
local menu_music_station_path
local menu_music_station_lerp = 0
local menu_music_pending_station
local menu_music_pending_path
local menu_music_pending_lerp = 0
local menu_music_target_path = menu_music_default_path

DISCORD_URL = "https://discord.gg/475EmEdTgH"

local SOUND_MENU_SELECT = "ui/rem_select.wav"
local SOUND_MENU_HOVER = "ui/rem_hover.wav"
local SOUND_TYPEWRITER = "shitty/tap-resonant.wav"
local SOUND_TYPEWRITER_LEVEL = 55
local SOUND_TYPEWRITER_VOLUME = 0.25
local SOUND_TYPEWRITER_PITCH = 102

local function PlayTypewriterSound()
    local ply = LocalPlayer and LocalPlayer()
    if IsValid(ply) then
        ply:EmitSound(SOUND_TYPEWRITER, SOUND_TYPEWRITER_LEVEL, SOUND_TYPEWRITER_PITCH, SOUND_TYPEWRITER_VOLUME)
        return
    end
    surface.PlaySound(SOUND_TYPEWRITER)
end

local function StopMainMenuMusic()
    if menu_music_station then
        menu_music_station:Stop()
        menu_music_station = nil
    end
    menu_music_station_path = nil
    menu_music_station_lerp = 0
    if menu_music_pending_station then
        menu_music_pending_station:Stop()
        menu_music_pending_station = nil
    end
    menu_music_pending_path = nil
    menu_music_pending_lerp = 0
    menu_music_target_path = menu_music_default_path
end

local function QueueMainMenuMusic(owner, path)
    path = path or menu_music_default_path
    menu_music_target_path = path

    if not IsValid(owner) or MainMenu ~= owner then return end
    if menu_music_station and menu_music_station_path == path and not menu_music_pending_station then return end
    if menu_music_pending_station and menu_music_pending_path == path then return end

    sound.PlayFile(path, menu_music_flags, function(station)
        if not station then return end
        if not IsValid(owner) or MainMenu ~= owner or menu_music_target_path ~= path then
            station:Stop()
            return
        end

        if menu_music_pending_station and menu_music_pending_station ~= station then
            menu_music_pending_station:Stop()
        end

        menu_music_pending_station = station
        menu_music_pending_path = path
        menu_music_pending_lerp = 0
        station:EnableLooping(true)
        station:SetVolume(0)
        station:Play()
    end)
end

local function UpdateMainMenuMusic(owner)
    if not IsValid(owner) or MainMenu ~= owner then
        StopMainMenuMusic()
        return
    end

    if menu_music_station and menu_music_station_path ~= menu_music_target_path and not menu_music_pending_station then
        QueueMainMenuMusic(owner, menu_music_target_path)
    end

    local fadeStep = FrameTime() * menu_music_fade_speed

    if menu_music_pending_station then
        menu_music_pending_lerp = math.min(1, menu_music_pending_lerp + fadeStep)
        menu_music_pending_station:SetVolume(menu_music_volume * menu_music_pending_lerp)

        if menu_music_station then
            menu_music_station_lerp = math.max(0, menu_music_station_lerp - fadeStep)
            menu_music_station:SetVolume(menu_music_volume * menu_music_station_lerp)

            if menu_music_station_lerp <= 0.001 then
                menu_music_station:Stop()
                menu_music_station = menu_music_pending_station
                menu_music_station_path = menu_music_pending_path
                menu_music_station_lerp = menu_music_pending_lerp
                menu_music_pending_station = nil
                menu_music_pending_path = nil
                menu_music_pending_lerp = 0
            end
        elseif menu_music_pending_lerp >= 0.999 then
            menu_music_station = menu_music_pending_station
            menu_music_station_path = menu_music_pending_path
            menu_music_station_lerp = 1
            menu_music_pending_station = nil
            menu_music_pending_path = nil
            menu_music_pending_lerp = 0
        end
    elseif menu_music_station then
        menu_music_station_lerp = math.min(1, menu_music_station_lerp + fadeStep)
        menu_music_station:SetVolume(menu_music_volume * menu_music_station_lerp)
    elseif menu_music_target_path then
        QueueMainMenuMusic(owner, menu_music_target_path)
    end
end

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end

local function CreateMainMenuFonts()
    surface.CreateFont("ZCity_Menu_Tiny", {
        font = "Verily Serif Mono",
        size = ScreenScale(8),
        weight = 200
    })

    surface.CreateFont("ZCity_Menu_Small", {
        font = "Verily Serif Mono",
        size = ScreenScale(20),
        weight = 200
    })
end

hook.Add("OnScreenSizeChanged", "ZCity_MainMenu_Fonts", CreateMainMenuFonts)
CreateMainMenuFonts()

local Selects = {
    resume = {Title = "RESUME", BypassTransition = true, Func = function(luaMenu) luaMenu:Close() end},
    disconnect = {Title = "DISCONNECT", BypassTransition = true, Func = function(luaMenu) luaMenu:PlayDisconnectCutscene() end},
    loadout = {Title = "loadout", GamemodeOnly = true, Func = function(luaMenu, pp)
        if hg.DrawLoadoutMenu then
            hg.DrawLoadoutMenu(pp)
        end
    end},
    roundstats = {Title = "round stats", Func = function(luaMenu, pp)
        if hg.DrawRoundStats then
            hg.DrawRoundStats(pp)
        end
    end},
    achievements = {Title = "achievements", Func = function(luaMenu, pp)
        hg.DrawAchievmentsMenu(pp)
    end},
    menu = {Title = "menu", BypassTransition = true, Func = function(luaMenu)
        gui.ActivateGameUI()
        luaMenu:Close()
    end},
    information = {Title = "information", Func = function(luaMenu, pp)
        hg.DrawInformation(pp)
    end},
    appearance = {Title = "appearance", KeepPreview = true, PreviewOnTop = true, Func = function(luaMenu, pp)
        hg.CreateApperanceMenu(pp)
    end},
    -- keybinds now live inside settings as their own category
    settings = {Title = "settings", Func = function(luaMenu, pp)
        hg.DrawSettings(pp)
    end},
}

local menu_bar_title = "Lament"
local menu_bar_logo = Material("lament/logo.png", "smooth")
local menu_bar_top_buttons = {"information", "appearance", "settings"}
local menu_bar_big_buttons = {"resume", "disconnect"}
local menu_bar_small_buttons = {"loadout", "roundstats", "achievements", "menu"}

local function CreateMenuBarFonts()
    local scale = math.min(ScrW(), ScrH()) / 1000
    surface.CreateFont("ZCity_MenuBar_Name", {font = "IBM Plex Mono", size = math.max(14, math.floor(24 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_MenuBar_XP", {font = "IBM Plex Mono", size = math.max(12, math.floor(17 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_MenuBar_Title", {font = "IBM Plex Mono", size = math.max(18, math.floor(38 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_MenuBar_Button", {font = "IBM Plex Mono", size = math.max(14, math.floor(22 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_MenuBar_ButtonBig", {font = "IBM Plex Mono", size = math.max(18, math.floor(36 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_MenuBar_Tiny", {font = "IBM Plex Mono", size = math.max(11, math.floor(14 * scale)), weight = 400, antialias = true})
end

hook.Add("OnScreenSizeChanged", "ZCity_MenuBar_Fonts", CreateMenuBarFonts)
CreateMenuBarFonts()

local menu_bg_dark = Color(8, 8, 8, 255)
local menu_bg_grad_r = surface.GetTextureID("vgui/gradient-r")
local menu_bg_grad_l = surface.GetTextureID("vgui/gradient-l")

-- Same backdrop the appearance editor uses (dark base, slow noise tiles, soft gradients)
function hg.PaintMenuBackground(w, h, mul)
    mul = mul or 1
    if mul <= 0 then return end
    surface.SetDrawColor(menu_bg_dark.r, menu_bg_dark.g, menu_bg_dark.b, 255 * mul)
    surface.DrawRect(0, 0, w, h)
    local t = RealTime()
    for i = 0, h, 64 do
        for j = 0, w, 64 do
            local n = math.sin(j * 12.9898 + i * 78.233 + t * 0.008) * 43758.5453
            n = n - math.floor(n)
            local v = 80 + n * 30
            surface.SetDrawColor(v, v, v, (1 + n * 3) * mul)
            surface.DrawRect(j, i, 64, 64)
        end
    end
    surface.SetDrawColor(0, 0, 0, 100 * mul)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(80, 80, 80, 15 * mul)
    surface.SetTexture(menu_bg_grad_r)
    surface.DrawTexturedRect(0, 0, w, h)
    surface.SetDrawColor(20, 20, 20, 80 * mul)
    surface.SetTexture(menu_bg_grad_l)
    surface.DrawTexturedRect(0, 0, w, h)
end

-- ESC menu backdrop: the live game behind the menu, blurred and in black & white
local menu_bg_blur = Material("pp/blurscreen")
local menu_bg_mono = Material("pp/colour")
-- blurTop / blurBottom: only blur between these screen heights (the bars stay sharp)
function hg.PaintMenuBackgroundMono(w, h, mul, blurTop, blurBottom, colourAmt)
    mul = mul or 1
    if mul <= 0 then return end
    local x, y = 0, 0
    surface.SetDrawColor(255, 255, 255, 255)

    -- blur (a few passes so it stays smooth at higher strengths)
    blurTop = math.Clamp(math.floor(blurTop or 0), 0, h)
    blurBottom = math.Clamp(math.ceil(blurBottom or h), 0, h)
    if blurBottom > blurTop then
        render.SetScissorRect(0, blurTop, w, blurBottom, true)
        surface.SetMaterial(menu_bg_blur)
        for i = 1, 4 do
            menu_bg_blur:SetFloat("$blur", (i / 4) * 6 * mul)
            menu_bg_blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x, y, ScrW(), ScrH())
        end
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    -- drain the colour out
    render.UpdateScreenEffectTexture()
    menu_bg_mono:SetTexture("$fbtexture", render.GetScreenEffectTexture())
    menu_bg_mono:SetFloat("$pp_colour_addr", 0)
    menu_bg_mono:SetFloat("$pp_colour_addg", 0)
    menu_bg_mono:SetFloat("$pp_colour_addb", 0)
    menu_bg_mono:SetFloat("$pp_colour_brightness", -0.02 * mul)
    menu_bg_mono:SetFloat("$pp_colour_contrast", 1 - 0.1 * mul)
    menu_bg_mono:SetFloat("$pp_colour_colour", colourAmt or 0) -- 0 = black & white
    menu_bg_mono:SetFloat("$pp_colour_mulr", 0)
    menu_bg_mono:SetFloat("$pp_colour_mulg", 0)
    menu_bg_mono:SetFloat("$pp_colour_mulb", 0)
    surface.SetMaterial(menu_bg_mono)
    surface.DrawTexturedRect(x, y, ScrW(), ScrH())

    -- darken a bit and keep the same soft side gradients so the text stays readable
    surface.SetDrawColor(0, 0, 0, 110 * mul)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(80, 80, 80, 15 * mul)
    surface.SetTexture(menu_bg_grad_r)
    surface.DrawTexturedRect(0, 0, w, h)
    surface.SetDrawColor(20, 20, 20, 80 * mul)
    surface.SetTexture(menu_bg_grad_l)
    surface.DrawTexturedRect(0, 0, w, h)
end

local splasheh = {
    'LIKE HOMICIDED',
    'PLUV PLUV PLUVISKI',
    'LULU IS NOT DEAD | !PLUV',
    'THE TRAITOR WAS KILLED',
    'NAB HOMICIDE SERVER',
    'ALSO TRY MODDED HOMICIDE 2',
    'HOP ON Z-CITY',
    'JOHN Z-CITY',
    ':pluvrare:',
    'SAW51 IS REAL',
    'MORE SMALLTOWN',
    'MORE CLUE2022',
    'BACKROOMS == CLUE',
    'HELL IS NEAR',
    'I WISH YOU GOOD HEALTH, JASON STATHAM'
}

--print(string.upper('I wish you good health, Jason Statham'))
surface.CreateFont("ZC_MM_Title", {
    font = "Verily Serif Mono",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})
-- local Title = markup.Parse("error")

local Pluv = Material("pluv/pluvkid.jpg")
local LogoistMat = Material("vgui/logoist.png", "noclamp smooth")

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = splasheh[math.random(#splasheh)] .. " | " .. string.NiceName(mapname) 

    if hg.PluvTown.Active then
        local text = "<font=ZC_MM_Title><colour=199,2,2>    </colour>City</font>\n<font=ZCity_Menu_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text)
    end

    local text = "<font=ZC_MM_Title><colour=199,2,2,255>Z</colour>-City</font>\n<font=ZCity_Menu_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"
    return markup.Parse(text)
end

local color_red = Color(255,25,25,45)
local clr_gray = Color(255,255,255,25)
local clr_verygray = Color(10,10,19,235)
local appearance_preview = {
    width = 340,
    height = 920,
    right = 0,
    top = 210,
    enter_time = 1.35,
    enter_delay = 0.35,
    exit_time = 0.7,
    exit_delay = 0.05,
    ambient = Color(0, 0, 0, 255),
    light_right = Color(115, 115, 115, 255),
    light_left = Color(85, 85, 85, 255),
    light_front = Color(92, 92, 92, 255),
    light_back = Color(0, 0, 0, 255),
    light_top = Color(55, 55, 55, 255),
    light_bottom = Color(0, 0, 0, 255),
    fov = 13,
    cam_pos = Vector(100, 0, 65),
    look_ang = Angle(11, 180, 0),
    entity_ang = Angle(0, 0, 0),
    head_yaw = -45,
    head_pitch = 0,
    head_mouse_yaw = 7,
    head_mouse_pitch = 4,
    sequence = "idle_suitcase"
}
local disconnect_cutscene = {
    ui_fade_time = 0.45,
    walk_delay = 0.08,
    walk_time = 2.5,
    walk_distance = 135,
    walk_sequence = "walk_all",
    walk_playback_rate = 1,
    walk_ang = Angle(0, 90, 0),
    black_fade_time = 0.7,
    disconnect_delay = 0.05
}
local menu_profile = {
    left = 30,
    top = 90,
    min_width = 360,
    height = 160,
    medal_size = 50
}
local menu_title = {
    width = 500,
    offset_x = -11,
    spacing = 55
}
local menu_live = {
    drift_x = 14,
    drift_y = 10,
    shake_x = 1,
    shake_y = 1,
    title_x = 30,
    title_y = 25,
    title_mouse_x = 10,
    title_mouse_y = 7,
    title_float_x = 4,
    title_float_y = 3,
    title_hover_scale = 0.08,
    button_hover_scale = 0.008,
    button_drift_x = 4,
    button_drift_y = 1,
    button_shake_x = 0,
    button_shake_y = 0,
    profile_drift_x = 9,
    profile_drift_y = 6,
    bottom_drift_x = 10,
    bottom_drift_y = 6,
    logo_drift_x = 7,
    logo_drift_y = 4,
    enter_x = 18,
    enter_y = 12
}
local menu_profile_fallback_band = {
    icon = Material("vgui/mats_jack_awards/10")
}
local menu_profile_fallback_medal = {
    icon = Material("vgui/mats_jack_awards/pt")
}
local menu_news = {
    top = 24,
    height = 36,
    speed = 100,
    refresh = 2
}

local function MenuCanStartNet(messageName)
    return util.NetworkStringToID(messageName) ~= 0
end

hg.Leaderboard = hg.Leaderboard or {Rows = {}, NextRequest = 0}

function hg.Leaderboard.Request(limit)
    if not MenuCanStartNet("zb_sql_leaderboard") then return end
    if (hg.Leaderboard.NextRequest or 0) > CurTime() then return end
    hg.Leaderboard.NextRequest = CurTime() + 3

    net.Start("zb_sql_leaderboard")
        net.WriteUInt(math.Clamp(limit or 10, 1, 10), 8)
    net.SendToServer()
end

function hg.Leaderboard.Get(limit)
    hg.Leaderboard.Request(limit)

    local rows = hg.Leaderboard.Rows or {}
    if limit and #rows > limit then
        local trimmed = {}
        for i = 1, limit do
            trimmed[i] = rows[i]
        end
        return trimmed
    end

    return rows
end

function hg.Leaderboard.GetAwards(row)
    if not row or not zb or not zb.Experience or not zb.Experience.GetAwards then return menu_profile_fallback_band, menu_profile_fallback_medal end
    return zb.Experience.GetAwards({skill = row.skill or 0, exp = row.xp or 0})
end

function hg.Leaderboard.GetMedalName(row)
    local _, medal = hg.Leaderboard.GetAwards(row)
    return string.upper((medal and medal.name) or "UNRANKED")
end

if not hg.Leaderboard.NetHooked then
    net.Receive("zb_sql_leaderboard", function()
        local count = net.ReadUInt(8)
        local rows = {}

        for i = 1, count do
            rows[i] = {
                steamid = net.ReadString(),
                name = net.ReadString(),
                skill = net.ReadFloat(),
                xp = net.ReadUInt(32),
                kills = net.ReadUInt(16),
                deaths = net.ReadUInt(16),
                kd = net.ReadFloat()
            }
        end

        hg.Leaderboard.Rows = rows
    end)

    hg.Leaderboard.NetHooked = true
end

local function CleanupPreviewAccessories(ent)
    if not IsValid(ent) or not ent.modelAccess then return end
    for k, v in pairs(ent.modelAccess) do
        if IsValid(v) then
            v:Remove()
        end
        ent.modelAccess[k] = nil
    end
    if IsValid(ent._bandageGlovesPreview) then
        ent._bandageGlovesPreview:Remove()
        ent._bandageGlovesPreview = nil
    end
end

function PANEL:GetPreviewAppearance()
    if not hg or not hg.Appearance then return end
    local appearance
    if hg.Appearance.LoadAppearanceFile and hg.Appearance.SelectedAppearance then
        appearance = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
    end
    appearance = appearance or (hg.Appearance.GetRandomAppearance and hg.Appearance.GetRandomAppearance())
    if not appearance or not hg.Appearance.PlayerModels then return end
    local tMdl = hg.Appearance.PlayerModels[1][appearance.AModel] or hg.Appearance.PlayerModels[2][appearance.AModel]
    if not tMdl or not tMdl.mdl then return end
    return table.Copy(appearance), tMdl
end

function PANEL:GetProfileInfo()
    local ply = LocalPlayer()
    if not IsValid(ply) then
        return "Unknown", "0 XP", nil
    end

    local username = ply:GetNWString("PlayerName", "")
    if username == "" then
        username = ply:Nick()
    end

    local xp = tostring(math.floor(tonumber(ply.exp) or 0)) .. " XP"
    return username, xp, ply
end

function PANEL:GetLiveMouse()
    local mx, my = gui.MouseX(), gui.MouseY()
    if mx <= 0 and my <= 0 then
        mx = ScrW() * 0.5
        my = ScrH() * 0.5
    end
    local nx = math.Clamp((mx / ScrW() - 0.5) * 2, -1, 1)
    local ny = math.Clamp((my / ScrH() - 0.5) * 2, -1, 1)
    return mx, my, nx, ny
end

function PANEL:GetLiveOffset(xAmount, yAmount)
    local _, _, nx, ny = self:GetLiveMouse()
    return nx * xAmount, ny * yAmount
end

function PANEL:GetLiveShake(seedX, seedY, xAmount, yAmount)
    local t = RealTime()
    return math.sin(t * 1.8 + seedX) * xAmount, math.cos(t * 2.4 + seedY) * yAmount
end

function PANEL:Think()
    UpdateMainMenuMusic(self)
    self:UpdatePreviewLayer()

    if self.DisconnectBlackStart then
        local blackFrac = math.Clamp((CurTime() - self.DisconnectBlackStart) / math.max(disconnect_cutscene.black_fade_time, 0.001), 0, 1)
        self.DisconnectBlackAlpha = 255 * blackFrac
    end

    if self.DisconnectWalkStart and CurTime() >= self.DisconnectWalkStart then
        local walkFrac = math.Clamp((CurTime() - self.DisconnectWalkStart) / disconnect_cutscene.walk_time, 0, 1)
        if walkFrac < 1 and CurTime() > (self.NextFootstep or 0) then
            self.NextFootstep = CurTime() + 0.38
            local vol = 1 - walkFrac
            if LocalPlayer and IsValid(LocalPlayer()) then
                LocalPlayer():EmitSound("player/footsteps/concrete" .. math.random(1,4) .. ".wav", 0, 100, vol)
            end
        end
    end

    self.LiveLerp = LerpFT(0.08, self.LiveLerp or 0, 1)
    self.LogoHoverLerp = LerpFT(0.12, self.LogoHoverLerp or 0, IsValid(self.logoPanel) and self.logoPanel:IsHovered() and 1 or 0)

    local enter = 1 - (self.LiveLerp or 0)
    local dockMouseX, dockMouseY = self:GetLiveOffset(MenuUnit(menu_live.drift_x), MenuUnit(menu_live.drift_y))
    local dockShakeX, dockShakeY = self:GetLiveShake(0.6, 1.1, MenuUnit(menu_live.shake_x), MenuUnit(menu_live.shake_y))

    if IsValid(self.lDock) and self.lDockBaseMargins then
        self.lDock:DockMargin(
            math.Round(self.lDockBaseMargins[1] + dockMouseX + dockShakeX - MenuUnit(menu_live.enter_x) * enter),
            math.Round(self.lDockBaseMargins[2] + dockMouseY + dockShakeY + MenuUnit(menu_live.enter_y) * enter),
            self.lDockBaseMargins[3],
            self.lDockBaseMargins[4]
        )
    end

    if IsValid(self.logoPanel) and self.logoBaseMargin then
        local logoMouseX, logoMouseY = self:GetLiveOffset(MenuUnit(menu_live.logo_drift_x), MenuUnit(menu_live.logo_drift_y))
        self.logoPanel:DockMargin(
            math.Round(logoMouseX),
            0,
            0,
            math.Round(self.logoBaseMargin + logoMouseY)
        )
    end

    if IsValid(self.profileInfo) and self.profileBasePos then
        local profileMouseX, profileMouseY = self:GetLiveOffset(MenuUnit(menu_live.profile_drift_x), MenuUnit(menu_live.profile_drift_y))
        local profileShakeX, profileShakeY = self:GetLiveShake(1.7, 2.3, MenuUnit(menu_live.shake_x), MenuUnit(menu_live.shake_y))
        self.profileInfo:SetPos(
            math.Round(self.profileBasePos[1] + profileMouseX + profileShakeX - MenuUnit(menu_live.enter_x) * enter),
            math.Round(self.profileBasePos[2] + profileMouseY + profileShakeY + MenuUnit(menu_live.enter_y) * enter)
        )
    end

    if IsValid(self.bottomDock) and self.bottomDockBasePos then
        local bottomMouseX, bottomMouseY = self:GetLiveOffset(MenuUnit(menu_live.bottom_drift_x), MenuUnit(menu_live.bottom_drift_y))
        local bottomShakeX, bottomShakeY = self:GetLiveShake(2.8, 3.1, MenuUnit(menu_live.shake_x), MenuUnit(menu_live.shake_y))
        self.bottomDock:SetPos(
            math.Round(self.bottomDockBasePos[1] + bottomMouseX + bottomShakeX - MenuUnit(menu_live.enter_x) * enter),
            math.Round(self.bottomDockBasePos[2] + bottomMouseY + bottomShakeY + MenuUnit(menu_live.enter_y) * enter)
        )
    end
end

function PANEL:CreateProfileInfo()
    local profile = vgui.Create("DPanel", self)
    self.profileInfo = profile
    profile:SetSize(MenuUnit(menu_profile.min_width), MenuUnit(menu_profile.height))
    profile:SetPos(MenuUnit(menu_profile.left), MenuUnit(menu_profile.top))
    self.profileBasePos = {MenuUnit(menu_profile.left), MenuUnit(menu_profile.top)}
    profile:SetMouseInputEnabled(false)
    profile:SetAlpha(0)
    profile.Paint = function() end

    local username = vgui.Create("DLabel", profile)
    username:SetPos(0, 0)
    username:SetFont("ZCity_Menu_Small")
    username:SetTextColor(color_white)
    username:SetContentAlignment(7)
    username:SetExpensiveShadow(1, Color(0, 0, 0, 225))

    local medal = vgui.Create("DPanel", profile)
    medal:SetPos(0, MenuUnit(28))
    medal:SetSize(MenuUnit(menu_profile.medal_size), MenuUnit(menu_profile.medal_size))
    medal.Band = nil
    medal.Medal = nil
    medal.Paint = function(this, w, h)
        if this.Band and this.Band.icon then
            surface.SetMaterial(this.Band.icon)
            surface.SetDrawColor(255,255,255,255)
            surface.DrawTexturedRect(0, 0, w, h)
        end
        if this.Medal and this.Medal.icon then
            surface.SetMaterial(this.Medal.icon)
            surface.SetDrawColor(255,255,255,255)
            surface.DrawTexturedRect(0, 0, w, h)
        end
    end

    local xp = vgui.Create("DLabel", profile)
    xp:SetPos(MenuUnit(30), MenuUnit(31))
    xp:SetFont("ZCity_Menu_Small")
    xp:SetTextColor(Color(175, 175, 175))
    xp:SetContentAlignment(7)
    xp:SetExpensiveShadow(1, Color(0, 0, 0, 225))

    local lastExp = -1
    local lastSkill = -1
    function profile:Think()
        local nameText, xpText, ply = self:GetParent():GetProfileInfo()
        if username:GetText() != nameText then
            username:SetText(nameText)
            username:SizeToContents()
        end
        if xp:GetText() != xpText then
            xp:SetText(xpText)
            xp:SizeToContents()
        end
        if IsValid(ply) and (lastExp != (ply.exp or 0) or lastSkill != (ply.skill or 0) or not medal.Band or not medal.Medal) then
            if ply.GetAwards then
                medal.Band, medal.Medal = ply:GetAwards()
            else
                medal.Band, medal.Medal = menu_profile_fallback_band, menu_profile_fallback_medal
            end
            medal.Band = medal.Band or menu_profile_fallback_band
            medal.Medal = medal.Medal or menu_profile_fallback_medal
            lastExp = ply.exp or 0
            lastSkill = ply.skill or 0
        end
        local medalSize = MenuUnit(menu_profile.medal_size)
        medal:SetSize(medalSize, medalSize)
        medal:SetPos(0, username:GetTall() + MenuUnit(3))
        xp:SetPos(medalSize + MenuUnit(4), username:GetTall() + MenuUnit(5))
        profile:SetWide(math.max(MenuUnit(menu_profile.min_width), username:GetWide() + MenuUnit(8), xp:GetX() + xp:GetWide() + MenuUnit(8)))
    end

    timer.Simple(0, function()
        if not IsValid(profile) then return end
        profile:AlphaTo(255, appearance_preview.enter_time * 0.75, appearance_preview.enter_delay)
    end)
end

function PANEL:CreateTopPlayersTicker()
    local ticker = vgui.Create("DPanel", self)
    self.topPlayersTicker = ticker
    ticker:SetSize(ScrW(), MenuUnit(menu_news.height))
    ticker:SetPos(0, MenuUnit(menu_news.top))
    ticker:SetMouseInputEnabled(false)
    ticker:SetAlpha(0)
    ticker.Text = "TOP 3 PLAYERS: LOADING"
    ticker.Leaders = {}
    ticker.NextRefresh = 0
    ticker.Paint = function(this, w, h)
        if (this.NextRefresh or 0) <= CurTime() then
            local leaders = hg.Leaderboard.Get(3)
            this.Leaders = leaders
            this.Text = #leaders > 0 and "TOP 3 PLAYERS:" or "TOP 3 PLAYERS: NO SQL LEADERBOARD DATA"
            this.NextRefresh = CurTime() + menu_news.refresh
        end

        surface.SetDrawColor(0, 0, 0, 185)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255, 70)
        surface.DrawRect(0, h - MenuUnit(1), w, MenuUnit(1))

        surface.SetFont("ZCity_Menu_Tiny")
        local iconSize = MenuUnit(18)
        local gap = MenuUnit(18)
        local textW = surface.GetTextSize(this.Text)
        for i, data in ipairs(this.Leaders or {}) do
            textW = textW + surface.GetTextSize("   #" .. i .. " " .. string.upper(data.name) .. " XP " .. data.xp) + iconSize + gap
        end
        local span = w + textW + MenuUnit(80)
        local x = w - ((RealTime() * menu_news.speed) % span)
        local y = h / 2
        draw.SimpleTextOutlined(this.Text, "ZCity_Menu_Tiny", x, y, Color(225, 225, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 235))
        x = x + surface.GetTextSize(this.Text)

        for i, data in ipairs(this.Leaders or {}) do
            local label = "   #" .. i .. " " .. string.upper(data.name) .. " XP " .. data.xp
            draw.SimpleTextOutlined(label, "ZCity_Menu_Tiny", x, y, Color(225, 225, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 235))
            x = x + surface.GetTextSize(label) + MenuUnit(4)

            local _, medal = hg.Leaderboard.GetAwards(data)
            if medal and medal.icon then
                surface.SetMaterial(medal.icon)
                surface.SetDrawColor(255, 255, 255, 235)
                surface.DrawTexturedRect(x, y - iconSize / 2, iconSize, iconSize)
            end

            x = x + iconSize + gap
        end
    end

    timer.Simple(0, function()
        if IsValid(ticker) then
            ticker:AlphaTo(255, appearance_preview.enter_time * 0.75, appearance_preview.enter_delay)
        end
    end)
end

-- off-screen texture the main menu playermodel is rendered into
local menuPreviewRT, menuPreviewMat
local MENU_PREVIEW_RT_SIZE = 2048
local menuPreviewSolidMat = Material("models/debug/debugwhite")
local function GetMenuPreviewRT()
    if not menuPreviewRT then
        menuPreviewRT = GetRenderTargetEx("lament_menu_preview_rt", MENU_PREVIEW_RT_SIZE, MENU_PREVIEW_RT_SIZE,
            RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(2, 256), 0, IMAGE_FORMAT_RGBA8888)
        menuPreviewMat = CreateMaterial("lament_menu_preview_mat", "UnlitGeneric", {
            ["$basetexture"] = menuPreviewRT:GetName(),
            ["$translucent"] = 1,
            ["$vertexalpha"] = 1,
            ["$vertexcolor"] = 1,
        })
    end
    return menuPreviewRT, menuPreviewMat, MENU_PREVIEW_RT_SIZE
end

function PANEL:CreateAppearancePreview()
    local tbl, tMdl = self:GetPreviewAppearance()
    if not tbl or not tMdl then return end

    if hg.Appearance and hg.Appearance.PrecacheModels then
        hg.Appearance.PrecacheModels()
    end

    local holderW = MenuUnit(appearance_preview.width)
    local holderH = MenuUnit(appearance_preview.height)
    local targetX = ScrW() - holderW - MenuUnit(appearance_preview.right)
    local targetY = MenuUnit(appearance_preview.top)

    -- separate layer: sits under the menu popup, above the background layer
    self.previewHolder = vgui.Create("DPanel")
    local holder = self.previewHolder
    holder:SetSize(holderW, holderH)
    holder:SetPos(targetX, ScrH())
    holder:SetAlpha(255) -- no fade-in, he just slides up into place
    holder.TargetX = targetX
    holder.TargetY = targetY
    holder.ClosedY = ScrH() + MenuUnit(120) -- far enough below the screen that nothing peeks in
    holder:SetMouseInputEnabled(false)
    holder.Paint = function() end
    -- the background playermodel is shown in black & white like the backdrop
    -- (not while the appearance editor has it on top, colours matter there)
    local menuSelf = self
    local monoMat = Material("pp/colour")
    holder.PaintOver = function(this, w, h)
        if IsValid(menuSelf) and this:GetParent() == menuSelf then return end
        -- the model is drawn without clipping, so it can stick out of this panel: desaturate the
        -- whole screen drawn so far (only the backdrop + the model sit under this layer), at full
        -- strength even while the panel is still fading in
        local sx, sy = this:LocalToScreen(0, 0)
        local sw, sh = ScrW(), ScrH()
        local oldAlpha = surface.GetAlphaMultiplier()
        surface.SetAlphaMultiplier(1)
        DisableClipping(true)
        render.UpdateScreenEffectTexture()
        monoMat:SetTexture("$fbtexture", render.GetScreenEffectTexture())
        monoMat:SetFloat("$pp_colour_addr", 0)
        monoMat:SetFloat("$pp_colour_addg", 0)
        monoMat:SetFloat("$pp_colour_addb", 0)
        monoMat:SetFloat("$pp_colour_brightness", 0)
        monoMat:SetFloat("$pp_colour_contrast", 1)
        monoMat:SetFloat("$pp_colour_colour", (IsValid(menuSelf) and menuSelf.MenuClosing) and (1 - menuSelf:GetAlpha() / 255) or 0)
        monoMat:SetFloat("$pp_colour_mulr", 0)
        monoMat:SetFloat("$pp_colour_mulg", 0)
        monoMat:SetFloat("$pp_colour_mulb", 0)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(monoMat)
        surface.DrawTexturedRect(-sx, -sy, sw, sh)
        DisableClipping(false)
        surface.SetAlphaMultiplier(oldAlpha)
    end
    holder.Think = function(this)
        if not this.AppearanceFollow then return end
        local x, y = this:GetPos()
        local targetPosX = this.TargetX or x
        local targetPosY = this.TargetY or y
        local nextX = LerpFT(0.18, x, targetPosX)
        local nextY = LerpFT(0.18, y, targetPosY)
        if math.abs(targetPosX - nextX) < 1 then
            nextX = targetPosX
        end
        if math.abs(targetPosY - nextY) < 1 then
            nextY = targetPosY
        end
        this:SetPos(math.Round(nextX), math.Round(nextY))
    end

    local preview = vgui.Create("DModelPanel", holder)
    self.previewModel = preview
    preview.OwnerMenu = self
    preview:Dock(FILL)
    preview:SetModel(util.IsValidModel(tostring(tMdl.mdl)) and tostring(tMdl.mdl) or "models/player/group01/female_01.mdl")
    preview:SetFOV(appearance_preview.fov)
    preview:SetLookAng(appearance_preview.look_ang)
    preview:SetCamPos(appearance_preview.cam_pos)
    preview:SetAmbientLight(appearance_preview.ambient)
    preview:SetDirectionalLight(BOX_RIGHT, appearance_preview.light_right)
    preview:SetDirectionalLight(BOX_LEFT, appearance_preview.light_left)
    preview:SetDirectionalLight(BOX_FRONT, appearance_preview.light_front)
    preview:SetDirectionalLight(BOX_BACK, appearance_preview.light_back)
    preview:SetDirectionalLight(BOX_TOP, appearance_preview.light_top)
    preview:SetDirectionalLight(BOX_BOTTOM, appearance_preview.light_bottom)
    preview:SetMouseInputEnabled(false)
    preview.AppearanceTable = tbl

    local oldPaint = preview.Paint
    preview.Paint = function(pnl, w, h)
        -- the appearance editor wants the model kept inside its preview box
        if pnl.ClipToBounds then
            oldPaint(pnl, w, h)
            return
        end
        -- render the model into an off-screen texture that is bigger than the box (same
        -- framing, matching wider FOV), then draw that texture over the box. Nothing is cut at
        -- the box edges, and since the 3D view never touches the screen edges the model can't
        -- get squeezed while the box slides in or sits partly off screen
        local ent = pnl.Entity
        if not IsValid(ent) then return end
        local rt, rtMat, rtSize = GetMenuPreviewRT()
        local pad = 1.6
        local vw, vh = w * pad, h * pad
        local fit = math.min(1, rtSize / vw, rtSize / vh)
        local rw, rh = math.floor(vw * fit), math.floor(vh * fit)

        pnl:LayoutEntity(ent)
        local ang = pnl.aLookAngle or (pnl.vLookatPos - pnl.vCamPos):Angle()
        local fov = math.deg(2 * math.atan(math.tan(math.rad(pnl.fFOV) * 0.5) * pad))

        render.PushRenderTarget(rt)
        render.Clear(0, 0, 0, 0, true, true)
        cam.Start3D(pnl.vCamPos, ang, fov, 0, 0, rw, rh, 5, pnl.FarZ)
            render.SuppressEngineLighting(true)
            render.SetLightingOrigin(ent:GetPos())
            local amb = pnl.colAmbientLight or color_black
            render.ResetModelLighting(amb.r / 255, amb.g / 255, amb.b / 255)
            local col = pnl.colColor or color_white
            render.SetColorModulation(col.r / 255, col.g / 255, col.b / 255)
            render.SetBlend(col.a / 255)
            for i = 0, 6 do
                local light = pnl.DirectionalLight and pnl.DirectionalLight[i]
                if light then
                    render.SetModelLighting(i, light.r / 255, light.g / 255, light.b / 255)
                end
            end
            -- Source normally writes depth into the alpha channel, which made him see-through
            render.SetWriteDepthToDestAlpha(false)
            local drew = pnl:PreDrawModel(ent) ~= false
            if drew then
                ent:DrawModel()
                pnl:PostDrawModel(ent)

                -- second pass: stamp full alpha wherever the model (and its accessories) is,
                -- without touching the colours, so he comes out completely solid
                render.OverrideColorWriteEnable(true, false)
                render.OverrideAlphaWriteEnable(true, true)
                render.MaterialOverride(menuPreviewSolidMat)
                render.SetBlend(1)
                ent:DrawModel()
                pnl:PostDrawModel(ent)
                render.MaterialOverride(nil)
                render.OverrideAlphaWriteEnable(false)
                render.OverrideColorWriteEnable(false)
            end
            render.SetWriteDepthToDestAlpha(true)
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
            render.SuppressEngineLighting(false)
        cam.End3D()
        render.PopRenderTarget()

        DisableClipping(true)
        surface.SetDrawColor(255, 255, 255, 255 * (pnl:GetAlpha() / 255))
        surface.SetMaterial(rtMat)
        surface.DrawTexturedRectUV(-(vw - w) * 0.5, -(vh - h) * 0.5, vw, vh, 0, 0, rw / rtSize, rh / rtSize)
        DisableClipping(false)
        pnl.LastPaint = RealTime()
    end

    function preview:LayoutEntity(ent)
        local appearance = self.AppearanceTable
        if not appearance or not hg or not hg.Appearance or not hg.Appearance.PlayerModels then return end

        ent.CurAppearance = appearance
        ent.PreviewAppearanceColor = appearance.AColor
        ent.PreviewAccessoryColors = appearance.AAttachmentColors

        local modelData = hg.Appearance.PlayerModels[1][appearance.AModel] or hg.Appearance.PlayerModels[2][appearance.AModel]
        if not modelData or not modelData.mdl then return end

        local colorData = appearance.AColor or color_white
        ent:SetNWVector("PlayerColor", Vector((colorData.r or 255) / 255, (colorData.g or 255) / 255, (colorData.b or 255) / 255))

        local heightScale = (appearance.AHeight or 100) / 100
        local bodyScale = (appearance.ABodySize or 100) / 100
        ent:SetModelScale(math.Clamp(heightScale, 0.85, 1.25) * math.Clamp(bodyScale, 0.85, 1.25))

        local targetPos = Vector(0, 0, 0)
        if self.OwnerMenu and self.OwnerMenu.DisconnectCutscene then
            if self.OwnerMenu.DisconnectWalkStart and CurTime() >= self.OwnerMenu.DisconnectWalkStart then
                local walkFrac = math.Clamp((CurTime() - self.OwnerMenu.DisconnectWalkStart) / disconnect_cutscene.walk_time, 0, 1)
                targetPos = Vector(0, walkFrac * disconnect_cutscene.walk_distance, 0)
            end
        end
        ent:SetPos(targetPos)

        local targetEntityAngle = self.EntityAngleOverride or appearance_preview.entity_ang
        self.EntityAngle = LerpAngle(RealFrameTime() * 6, self.EntityAngle or targetEntityAngle, targetEntityAngle)
        ent:SetAngles(self.EntityAngle)

        local sequenceName = self.SequenceNameOverride or appearance_preview.sequence
        local seq = ent:LookupSequence(sequenceName)
        
        if self.OwnerMenu and self.OwnerMenu.DisconnectCutscene and (not seq or seq < 0) then
            local fallbacks = {"walk_suitcase", "walk_all", "walk", "walk_all_suitcase"}
            for _, v in ipairs(fallbacks) do
                seq = ent:LookupSequence(v)
                if seq and seq >= 0 then
                    sequenceName = v
                    break
                end
            end
        end

        if (not seq or seq < 0) and sequenceName != appearance_preview.sequence then
            sequenceName = appearance_preview.sequence
            seq = ent:LookupSequence(sequenceName)
        end
        if seq and seq >= 0 then
            if self.ActiveSequenceName != sequenceName then
                ent:ResetSequence(seq)
                self.ActiveSequenceName = sequenceName
            end
            ent:SetPlaybackRate(self.SequencePlaybackRate or 1)
            ent:FrameAdvance(RealFrameTime() * (self.SequencePlaybackRate or 1))
        end

        local owner = self.OwnerMenu
        local nx, ny = 0, 0
        if IsValid(owner) and owner.GetLiveMouse then
            local _, _, newNX, newNY = owner:GetLiveMouse()
            nx, ny = newNX, newNY
        end
        local targetYaw = appearance_preview.head_yaw - nx * appearance_preview.head_mouse_yaw
        local targetPitch = appearance_preview.head_pitch - ny * appearance_preview.head_mouse_pitch
        self.HeadYawLerp = LerpFT(0.08, self.HeadYawLerp or appearance_preview.head_yaw, targetYaw)
        self.HeadPitchLerp = LerpFT(0.08, self.HeadPitchLerp or appearance_preview.head_pitch, targetPitch)
        ent:SetPoseParameter("head_yaw", self.HeadYawLerp)
        ent:SetPoseParameter("head_pitch", self.HeadPitchLerp)
        
        if self.OwnerMenu and self.OwnerMenu.DisconnectCutscene then
            ent:SetPoseParameter("move_x", 1)
            ent:SetPoseParameter("move_y", 0)
        end
        
        ent:SetSubMaterial()
        self:SetCamPos(self.CamPosOverride or appearance_preview.cam_pos)
        self:SetFOV(self.FOVOverride or appearance_preview.fov)
        self:SetLookAng(self.LookAngOverride or appearance_preview.look_ang)

        if ent:GetModel() != modelData.mdl then
            CleanupPreviewAccessories(ent)
            ent:SetModel(modelData.mdl)
            self:SetModel(modelData.mdl)
            self.ActiveSequenceName = nil
        end

        local clothes = appearance.AClothes or {}
        local mats = ent:GetMaterials()
        for k, v in SortedPairs(modelData.submatSlots or {}) do
            local slot = 1
            for i = 1, #mats do
                if mats[i] == v then
                    slot = i - 1
                    break
                end
            end
            local sexID = modelData.sex and 2 or 1
            local clothMat = hg.Appearance.Clothes[sexID] and hg.Appearance.Clothes[sexID][clothes[k]]
            ent:SetSubMaterial(slot, clothMat or (hg.Appearance.Clothes[sexID] and hg.Appearance.Clothes[sexID].normal) or nil)
        end

        local facemapSlot = hg.Appearance.FacemapsModels and hg.Appearance.FacemapsModels[modelData.mdl]
        for i = 1, #mats do
            if facemapSlot and hg.Appearance.FacemapsSlots[mats[i]] and hg.Appearance.FacemapsSlots[mats[i]][appearance.AFacemap] then
                ent:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][appearance.AFacemap])
            end
        end

        appearance.ABodygroups = appearance.ABodygroups or {}
        for k, v in SortedPairs(ent:GetBodyGroups()) do
            if not appearance.ABodygroups[v.name] then continue end
            local bodygroupData = hg.Appearance.Bodygroups[v.name]
            local bodygroupSet = bodygroupData and bodygroupData[modelData.sex and 2 or 1] and bodygroupData[modelData.sex and 2 or 1][appearance.ABodygroups[v.name]]
            if not bodygroupSet then continue end
            for i = 0, #v.submodels do
                if bodygroupSet[1] == v.submodels[i] then
                    ent:SetBodygroup(k - 1, i)
                    break
                end
            end
        end
    end

    function preview:PostDrawModel(ent)
        local appearance = self.AppearanceTable
        if not appearance then return end

        if appearance.AAttachments then
            for _, attach in ipairs(appearance.AAttachments) do
                local accessoryData = hg.Accessories and hg.Accessories[attach]
                if accessoryData and DrawAccesories then
                    DrawAccesories(ent, ent, attach, accessoryData, false, true)
                end
            end
        end

        local handsVal = appearance.ABodygroups and appearance.ABodygroups["HANDS"]
        if handsVal then
            local modelData = hg.Appearance.PlayerModels[1][appearance.AModel] or hg.Appearance.PlayerModels[2][appearance.AModel]
            local sexID = modelData and modelData.sex and 2 or 1
            local bgData = hg.Appearance.Bodygroups["HANDS"] and hg.Appearance.Bodygroups["HANDS"][sexID] and hg.Appearance.Bodygroups["HANDS"][sexID][handsVal]
            if bgData and bgData.bandageMdl then
                if not IsValid(ent._bandageGlovesPreview) or ent._bandageGlovesMdl ~= bgData.bandageMdl then
                    if IsValid(ent._bandageGlovesPreview) then ent._bandageGlovesPreview:Remove() end
                    ent._bandageGlovesPreview = ClientsideModel(bgData.bandageMdl)
                    ent._bandageGlovesMdl = bgData.bandageMdl
                    local bgModel = ent._bandageGlovesPreview
                    bgModel:SetNoDraw(true)
                    bgModel:SetParent(ent)
                    bgModel:AddEffects(EF_BONEMERGE)
                    local bgNames = {[6]="HandLeft",[9]="HandRight"}
                    for _, name in pairs(bgNames) do
                        local bgI = bgModel:FindBodygroupByName(name)
                        if not bgI or bgI < 0 then bgI = bgModel:FindBodygroupByName(name .. "-f") end
                        if bgI and bgI >= 0 then bgModel:SetBodygroup(bgI, 1) end
                    end
                end
                local clr = appearance.AColor
                if clr then render.SetColorModulation((clr.r or 255)/255, (clr.g or 255)/255, (clr.b or 255)/255) end
                ent._bandageGlovesPreview:SetupBones()
                ent._bandageGlovesPreview:DrawModel()
                if clr then render.SetColorModulation(1,1,1) end
            else
                if IsValid(ent._bandageGlovesPreview) then ent._bandageGlovesPreview:Remove() ent._bandageGlovesPreview = nil end
            end
        else
            if IsValid(ent._bandageGlovesPreview) then ent._bandageGlovesPreview:Remove() ent._bandageGlovesPreview = nil end
        end

        ent:SetupBones()
    end

    function preview:OnRemove()
        if IsValid(self.Entity) then
            CleanupPreviewAccessories(self.Entity)
        end
    end

    timer.Simple(0, function()
        if not IsValid(holder) then return end
        holder:MoveTo(targetX, targetY, appearance_preview.enter_time, 0, appearance_preview.enter_delay)
    end)
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Title, self.TitleShadow = self:InitializeMarkup()
    self.LiveLerp = 0
    self.LogoHoverLerp = 0
    self.DisconnectCutscene = false
    self.DisconnectBackgroundAlpha = 255
    self.DisconnectBlackAlpha = 0
    self:UseDefaultMenuMusic()

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    self:CreateBackgroundLayer()
    self:CreateAppearancePreview()

    self.Buttons = {}
    self:CreateTopBar()
    self:CreateBottomBar()
    self:CreateLastRoundTab()
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(0, 0)
    self.panelparrent:SetSize(ScrW(), ScrH())
    self.panelparrent:MoveToBack()
    self.panelparrent.Paint = function(this, w, h) end
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-r")
local gradient_l = surface.GetTextureID("vgui/gradient-l")
local menu_gradient_right = Color(18,18,18,65)

local clr_1 = Color(100,100,100,35)
function PANEL:Paint(w,h)
    -- the backdrop lives on self.BackgroundLayer (below the playermodel layer)
    if (self.DisconnectBlackAlpha or 0) > 0 then
        surface.SetDrawColor(0, 0, 0, self.DisconnectBlackAlpha)
        surface.DrawRect(0, 0, w, h)
    end
end

function PANEL:CreateBackgroundLayer()
    local menu = self
    local layer = vgui.Create("DPanel")
    self.BackgroundLayer = layer
    hg.MenuBackdropOwner = self
    layer:SetPos(0, 0)
    layer:SetSize(ScrW(), ScrH())
    layer:SetMouseInputEnabled(false)
    layer:SetKeyboardInputEnabled(false)
    -- the blurred backdrop is drawn in PostDrawHUD (before any menu panel), so this layer
    -- only exists to keep the old panel ordering; it paints nothing itself
    layer.Paint = function() end
end

-- draw the backdrop after the HUD but before every vgui panel, so the blur only ever
-- picks up the game - never the menu or the playermodel
hook.Add("PostDrawHUD", "ZCity_MenuMonoBackdrop", function()
    -- the menu that owns the backdrop (still set while it plays its closing animation)
    local menu = hg.MenuBackdropOwner
    if not IsValid(menu) or not IsValid(menu.BackgroundLayer) then return end
    local mul = (menu:GetAlpha() / 255) * (math.Clamp(menu.DisconnectBackgroundAlpha or 255, 0, 255) / 255)
    if mul <= 0 then return end
    -- keep the area behind the top and bottom bars unblurred
    local top, bottom = 0, ScrH()
    if IsValid(menu.topBar) then
        local _, by = menu.topBar:LocalToScreen(0, 0)
        top = math.max(by + menu.topBar:GetTall(), 0)
    end
    if IsValid(menu.bottomBar) then
        local _, by = menu.bottomBar:LocalToScreen(0, 0)
        bottom = math.min(by, ScrH())
    end
    cam.Start2D()
        -- black & white from the first frame when opening; fades back to colour while closing
        local colourAmt = menu.MenuClosing and (1 - mul) or 0
        hg.PaintMenuBackgroundMono(ScrW(), ScrH(), mul, top, bottom, colourAmt)
    cam.End2D()
end)

function PANEL:IsPageOpen()
    return IsValid(self.panelparrent) and #self.panelparrent:GetChildren() > 0
end

-- keeps the playermodel layer hidden behind pages that cover it
function PANEL:UpdatePreviewLayer()
    local holder = self.previewHolder
    if not IsValid(holder) or self.DisconnectCutscene or self.MenuClosing then return end
    local sel = curent_panel and Selects[curent_panel]
    local pageOpen = self:IsPageOpen()
    local want = not pageOpen or (sel and sel.KeepPreview) or false
    if want ~= holder:IsVisible() then
        holder:SetVisible(want)
        if want then holder:SetAlpha(255) end
    end

    -- the appearance editor needs the model drawn over its page; everywhere else
    -- the model sits on its own layer underneath the menu
    local onTop = pageOpen and sel and sel.PreviewOnTop or false
    if onTop and holder:GetParent() ~= self then
        holder:SetParent(self)
        holder:MoveToFront()
    elseif not onTop and holder:GetParent() == self then
        holder:SetParent(vgui.GetWorldPanel())
    end
end

function PANEL:PlayDisconnectCutscene()
    if self.DisconnectCutscene then return end
    self.DisconnectCutscene = true
    self.DisconnectFadeStart = CurTime()
    self.DisconnectBackgroundAlpha = 255
    self.DisconnectBlackAlpha = 0
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)

    StopMainMenuMusic()

    if IsValid(self.previewHolder) then
        self.previewHolder:SetVisible(true)
        self.previewHolder:SetAlpha(255)
    end

    if IsValid(self.previewModel) then
        self.previewModel.SequenceNameOverride = disconnect_cutscene.walk_sequence
        self.previewModel.SequencePlaybackRate = disconnect_cutscene.walk_playback_rate
        self.previewModel.EntityAngleOverride = disconnect_cutscene.walk_ang
        self.previewModel.ActiveSequenceName = nil
    end

    for _, child in ipairs(self:GetChildren()) do
        if child != self.previewHolder then
            child:AlphaTo(0, disconnect_cutscene.ui_fade_time, 0, function()
                if IsValid(child) then
                    child:SetVisible(false)
                end
            end)
        end
    end

    local function startBlackFade()
        if not IsValid(self) then return end
        self.DisconnectBlackStart = CurTime()
        self.DisconnectBlackAlpha = 0
        timer.Simple(disconnect_cutscene.black_fade_time + disconnect_cutscene.disconnect_delay, function()
            if IsValid(self) then
                RunConsoleCommand("disconnect")
            end
        end)
    end

    self.DisconnectWalkStart = CurTime() + disconnect_cutscene.ui_fade_time + disconnect_cutscene.walk_delay

    timer.Simple(disconnect_cutscene.ui_fade_time + disconnect_cutscene.walk_delay + disconnect_cutscene.walk_time, function()
        if IsValid(self) then
            startBlackFade()
        end
    end)
end

function PANEL:ResetCurrentPanel()
    curent_panel = nil
    if IsValid(self.previewHolder) and not self.DisconnectCutscene then
        self.previewHolder:SetVisible(true)
        self.previewHolder:SetAlpha(255)
    end
end

-- palette borrowed from the appearance editor
local menu_bar_bg = Color(28, 28, 28, 180)
local menu_bar_border = Color(180, 180, 180)
local menu_bar_btn_bg = Color(31, 31, 31, 205)
local menu_bar_btn_hover = Color(48, 48, 48, 235)
local menu_bar_accent = Color(225, 225, 225)
local menu_bar_text = Color(220, 220, 220)
local menu_bar_text_idle = Color(188, 188, 188)
local menu_bar_text_dim = Color(140, 140, 140)

-- slide-out tab on the left with the last round's stats, between the profile card and the
-- bottom bar. Click the handle to open / close it; the choice is remembered.
function PANEL:CreateLastRoundTab()
    if not hg.CreateLastRoundCard then return end
    local menu = self
    local top = MenuUnit(menu_profile.top + menu_profile.height + 12)
    local bottom = ScrH() - MenuUnit(150) - MenuUnit(12)
    local h = bottom - top
    if h < MenuUnit(240) then return end

    local drawerW = math.min(MenuUnit(560), math.floor(ScrW() * 0.36))
    local tabW = MenuUnit(34)
    local tabH = math.min(MenuUnit(190), h)

    local root = vgui.Create("DPanel", self)
    self.lastRoundTab = root
    root:SetSize(drawerW + tabW, h)
    root:SetPos(-(drawerW + tabW), top)
    root.Paint = function() end
    root.OpenFrac = hg.LastRoundTabOpen and 1 or 0
    root.Appear = 0

    local card = hg.CreateLastRoundCard(root)
    card:SetPos(0, 0)
    card:SetSize(drawerW, h)

    local tab = vgui.Create("DButton", root)
    tab:SetText("")
    tab:SetPos(drawerW, math.floor((h - tabH) / 2))
    tab:SetSize(tabW, tabH)
    tab.Paint = function(this, w, th)
        this.HoverLerp = LerpFT(0.2, this.HoverLerp or 0, this:IsHovered() and 1 or 0)
        local hl = this.HoverLerp
        draw.RoundedBoxEx(3, 0, 0, w, th, hl > 0.5 and menu_bar_btn_hover or menu_bar_btn_bg, false, true, false, true)
        surface.SetDrawColor(menu_bar_border.r, menu_bar_border.g, menu_bar_border.b, 45 + 100 * hl)
        surface.DrawOutlinedRect(0, 0, w, th, 1)
        surface.SetDrawColor(menu_bar_accent.r, menu_bar_accent.g, menu_bar_accent.b, 210 * hl)
        surface.DrawRect(w - MenuUnit(3), 0, MenuUnit(3), th)

        -- arrow showing which way it will move, then "STATS" stacked down the tab
        local col = hl > 0.5 and menu_bar_text or menu_bar_text_idle
        local chars = {hg.LastRoundTabOpen and "<" or ">", "", "S", "T", "A", "T", "S"}
        surface.SetFont("ZCity_MenuBar_Tiny")
        local _, ch = surface.GetTextSize("S")
        local step = ch * 0.95
        local y = th / 2 - step * (#chars - 1) / 2
        for _, c in ipairs(chars) do
            if c ~= "" then draw.SimpleText(c, "ZCity_MenuBar_Tiny", w / 2 - MenuUnit(1), y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
            y = y + step
        end
    end
    tab.DoClick = function()
        hg.LastRoundTabOpen = not hg.LastRoundTabOpen
        surface.PlaySound(SOUND_MENU_SELECT)
    end
    tab.OnCursorEntered = function()
        surface.PlaySound(SOUND_MENU_HOVER)
    end

    root.Think = function(this)
        -- slides in with the bars when the menu opens, back out when it closes
        local wantAppear = (IsValid(menu) and not menu.MenuClosing) and 1 or 0
        this.Appear = LerpFT(0.15, this.Appear, wantAppear)
        this.OpenFrac = LerpFT(0.2, this.OpenFrac, hg.LastRoundTabOpen and 1 or 0)
        local closedX = -drawerW
        local hiddenX = -(drawerW + tabW)
        local restX = Lerp(this.OpenFrac, closedX, 0)
        local x = Lerp(this.Appear, hiddenX, restX)
        this:SetPos(math.Round(x), top)
    end
end

function PANEL:RunSelect(key)
    local tbl = Selects[key]
    if not tbl then return end
    if self.DisconnectCutscene or self.SwitchingPanel then return end
    surface.PlaySound(SOUND_MENU_SELECT)

    if tbl.BypassTransition then
        tbl.Func(self)
        return
    end

    for _, child in ipairs(self:GetChildren()) do
        if child ~= self.panelparrent then
            child:SetAlpha(0)
            child:SetVisible(false)
        end
    end
    if IsValid(self.previewHolder) and not tbl.KeepPreview then
        self.previewHolder:SetVisible(false)
    end

    self.SwitchingPanel = true
    if IsValid(self.panelparrent) then
        self.panelparrent:Remove()
    end
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(0, 0)
    self.panelparrent:SetSize(ScrW(), ScrH())
    self.panelparrent:MoveToFront()
    self.panelparrent.Paint = function(this, w, h) end
    tbl.Func(self, self.panelparrent)
    curent_panel = key
    self.SwitchingPanel = false
end

function PANEL:MakeMenuButton(parent, key, big)
    local tbl = Selects[key]
    if not tbl then return end
    if tbl.GamemodeOnly and not isfunction(hg.DrawLoadoutMenu) then return end

    local luaMenu = self
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn.Label = tbl.Title
    btn.Font = big and "ZCity_MenuBar_ButtonBig" or "ZCity_MenuBar_Button"
    btn.HoverLerp = 0
    btn.OpenTime = CurTime()

    function btn:Think()
        local hovered = self:IsHovered()
        if hovered and not self.WasHovered then
            surface.PlaySound(SOUND_MENU_HOVER)
        end
        self.WasHovered = hovered
        -- Think stops while hidden behind a page; replay the reveal when we come back
        if self.LastThink and RealTime() - self.LastThink > 0.25 then
            self.OpenTime = CurTime()
        end
        self.LastThink = RealTime()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, hovered and 1 or 0)
    end


    function btn:Paint(w, h)
        local hl = self.HoverLerp or 0
        local hovered = self:IsHovered()
        draw.RoundedBox(3, 0, 0, w, h, hovered and menu_bar_btn_hover or menu_bar_btn_bg)
        surface.SetDrawColor(menu_bar_border.r, menu_bar_border.g, menu_bar_border.b, 45 + 100 * hl)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- accent strip on the left, like the editor's active rows
        if hl > 0.01 then
            surface.SetDrawColor(menu_bar_accent.r, menu_bar_accent.g, menu_bar_accent.b, 210 * hl)
            surface.DrawRect(0, 0, MenuUnit(3), h)
        end

        local text = self.Label
        local chars = math.min(#text, math.floor((CurTime() - (self.OpenTime or 0)) * 22))
        local shown = text:sub(1, chars) .. string.rep("#", #text - chars)
        draw.SimpleText(shown, self.Font, w / 2, h / 2, hovered and menu_bar_text or menu_bar_text_idle, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function btn:DoClick()
        luaMenu:RunSelect(key)
    end

    self.Buttons[#self.Buttons + 1] = btn
    return btn
end

function PANEL:CreateTopBar()
    local luaMenu = self
    local barH = MenuUnit(64)
    local bar = vgui.Create("DPanel", self)
    self.topBar = bar
    bar:SetSize(ScrW(), barH)
    bar:SetPos(0, -barH)
    bar:MoveTo(0, 0, 0.35, 0, 0.3)

    bar.Band, bar.Medal = nil, nil
    bar.NextAwards = 0

    -- credits, just under the top bar (top-left of the menu)
    local credits = {
        "Authors: uzelezz, Sadsalat,",
        "Mr.Point, Zac90, Deka, Mannytko",
        "Release 1.4.1",
        "GitHub: github.com/uzelezz123/Z-City",
    }
    bar.PaintOver = function(this, w, h)
        surface.SetFont("ZCity_MenuBar_Tiny")
        local _, lh = surface.GetTextSize("A")
        lh = lh + MenuUnit(2)
        local pad = MenuUnit(14)
        DisableClipping(true)
        for i, line in ipairs(credits) do
            draw.SimpleText(line, "ZCity_MenuBar_Tiny", pad, h + pad + (i - 1) * lh, menu_bar_text_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        DisableClipping(false)
    end

    bar.Paint = function(this, w, h)
        surface.SetDrawColor(menu_bar_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(menu_bar_border.r, menu_bar_border.g, menu_bar_border.b, 50)
        surface.DrawRect(0, h - 1, w, 1)

        local nameText, xpText, ply = luaMenu:GetProfileInfo()
        if this.NextAwards <= CurTime() then
            this.NextAwards = CurTime() + 1
            if IsValid(ply) and ply.GetAwards then
                this.Band, this.Medal = ply:GetAwards()
            end
            this.Band = this.Band or menu_profile_fallback_band
            this.Medal = this.Medal or menu_profile_fallback_medal
        end

        local pad = MenuUnit(14)
        draw.SimpleText(nameText, "ZCity_MenuBar_Name", pad, h * 0.32, menu_bar_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local icon = MenuUnit(22)
        local iconY = h * 0.72 - icon / 2
        if this.Band and this.Band.icon then
            surface.SetMaterial(this.Band.icon)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(pad, iconY, icon, icon)
        end
        if this.Medal and this.Medal.icon then
            surface.SetMaterial(this.Medal.icon)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(pad, iconY, icon, icon)
        end
        draw.SimpleText("xp: " .. string.gsub(xpText, " XP$", ""), "ZCity_MenuBar_XP", pad + icon + MenuUnit(6), h * 0.72, menu_bar_text_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- logo in the middle; falls back to the title text if the image is missing
        if not menu_bar_logo:IsError() then
            -- logo is a bit taller than the bar on purpose; it hangs just below it
            local lh = MenuUnit(76)
            local lw = lh * (menu_bar_logo:Width() / math.max(1, menu_bar_logo:Height()))
            DisableClipping(true)
            surface.SetMaterial(menu_bar_logo)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(math.floor(w / 2 - lw / 2), -MenuUnit(4), lw, lh)
            DisableClipping(false)
        else
            draw.SimpleText(string.upper(menu_bar_title), "ZCity_MenuBar_Title", w / 2, h / 2, menu_bar_accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local buttons = {}
    for _, key in ipairs(menu_bar_top_buttons) do
        local btn = self:MakeMenuButton(bar, key, false)
        if btn then buttons[#buttons + 1] = btn end
    end

    bar.PerformLayout = function(this, w, h)
        local pad = MenuUnit(6)
        local gap = MenuUnit(10)
        local btnW = MenuUnit(160)
        local btnH = math.min(h - pad * 2, MenuUnit(52))
        local btnY = math.floor((h - btnH) / 2)
        local x = w - pad
        for i = #buttons, 1, -1 do
            x = x - btnW
            buttons[i]:SetPos(x, btnY)
            buttons[i]:SetSize(btnW, btnH)
            x = x - gap
        end
    end
end

function PANEL:CreateBottomBar()
    local barH = MenuUnit(150)
    local bar = vgui.Create("DPanel", self)
    self.bottomBar = bar
    bar:SetSize(ScrW(), barH)
    bar:SetPos(0, ScrH())
    bar:MoveTo(0, ScrH() - barH, 0.35, 0, 0.3)

    bar.Paint = function(this, w, h)
        surface.SetDrawColor(menu_bar_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(menu_bar_border.r, menu_bar_border.g, menu_bar_border.b, 50)
        surface.DrawRect(0, 0, w, 1)

    end

    local big, small = {}, {}
    for _, key in ipairs(menu_bar_big_buttons) do
        local btn = self:MakeMenuButton(bar, key, true)
        if btn then big[#big + 1] = btn end
    end
    for _, key in ipairs(menu_bar_small_buttons) do
        local btn = self:MakeMenuButton(bar, key, false)
        if btn then small[#small + 1] = btn end
    end

    local function LayoutRow(row, y, rowH, w, pad, gap)
        local n = #row
        if n == 0 then return end
        local btnW = (w - pad * 2 - gap * (n - 1)) / n
        for i, btn in ipairs(row) do
            btn:SetPos(math.floor(pad + (i - 1) * (btnW + gap)), y)
            btn:SetSize(math.floor(btnW), rowH)
        end
    end

    bar.PerformLayout = function(this, w, h)
        local pad = MenuUnit(10)
        local gap = MenuUnit(14)
        local rowGap = MenuUnit(10)
        local rowH = math.floor((h - pad * 2 - rowGap) / 2)
        LayoutRow(big, pad, rowH, w, pad, gap)
        LayoutRow(small, pad + rowH + rowGap, rowH, w, pad, gap)
    end
end

function PANEL:Close()
    if self.DisconnectCutscene then return end
    self.MenuClosing = true
    StopMainMenuMusic()

    -- reverse of the open animation: top bar back up, bottom bar back down
    if IsValid(self.topBar) then
        self.topBar:Stop()
        self.topBar:MoveTo(0, -self.topBar:GetTall(), 0.35, 0, 0.3)
    end
    if IsValid(self.bottomBar) then
        self.bottomBar:Stop()
        self.bottomBar:MoveTo(0, ScrH(), 0.35, 0, 0.3)
    end
    -- accessories are cleaned up in OnRemove so he keeps them while falling
    if IsValid(self.previewHolder) then
        self.previewHolder.AppearanceFollow = false
        -- vanish almost instantly, no movement
        self.previewHolder:Stop()
        self.previewHolder:AlphaTo(0, 0.1, 0)
    end
    self:AlphaTo(0, appearance_preview.exit_time, 0, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

function PANEL:OnRemove()
    StopMainMenuMusic()
    if IsValid(self.previewModel) and IsValid(self.previewModel.Entity) then
        CleanupPreviewAccessories(self.previewModel.Entity)
    end
    if IsValid(self.previewHolder) then self.previewHolder:Remove() end
    if IsValid(self.BackgroundLayer) then self.BackgroundLayer:Remove() end
end

function PANEL:SetMenuMusic(path)
    QueueMainMenuMusic(self, path)
end

function PANEL:UseDefaultMenuMusic()
    self:SetMenuMusic(menu_music_default_path)
end

function PANEL:UseAppearanceMenuMusic()
    self:SetMenuMusic(menu_music_appearance_path)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    local run = hook.Run("OnShowZCityPause")
    if run != nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        if MainMenu.DisconnectCutscene then
            return false
        end
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)
