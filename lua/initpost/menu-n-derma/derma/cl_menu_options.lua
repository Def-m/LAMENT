hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}

function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString, category )
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.tbl[strCategory][strConVar] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false, category }
end
local hg_firstperson_death = CreateClientConVar("hg_firstperson_death", "0", true, false, "Toggle first-person death camera view", 0, 0)
local hg_font_default = "Lora"
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", hg_font_default, true, false, "change every text font to selected because ui customization is cool")
local hg_oldradialmenu = CreateClientConVar("hg_oldradialmenu", "0", true, false, "use the old radial menu style", 0, 1)
local hg_hold_shift_sprint = ConVarExists("hg_hold_shift_sprint") and GetConVar("hg_hold_shift_sprint") or CreateClientConVar("hg_hold_shift_sprint", "0", true, true, "Disable jogging, holding shift will make you sprint.", 0, 1)
local hg_quickdraw_alt = ConVarExists("hg_quickdraw_alt") and GetConVar("hg_quickdraw_alt") or CreateClientConVar("hg_quickdraw_alt", "0", true, true, "Off: hold Shift while equipping a pistol to draw it fast and one-handed. On: hold Alt instead.", 0, 1)
local hg_reduce_screeneffects = ConVarExists("hg_reduce_screeneffects") and GetConVar("hg_reduce_screeneffects") or CreateClientConVar("hg_reduce_screeneffects", "0", true, false, "Reduce screen shader effects by 50%", 0, 1)

local function ForceHGFirstPersonDeath()
	if hg_firstperson_death:GetBool() then
		RunConsoleCommand("hg_firstperson_death", "0")
	end
end

local function ForceHGFont()
	if hg_font:GetString() != hg_font_default then
		RunConsoleCommand("hg_font", hg_font_default)
	end
end

ForceHGFirstPersonDeath()
ForceHGFont()

cvars.AddChangeCallback("hg_firstperson_death", function(_, _, newValue)
	if newValue != "0" then
		RunConsoleCommand("hg_firstperson_death", "0")
	end
end, "hg_firstperson_death_lock")

cvars.AddChangeCallback("hg_font", function(_, _, newValue)
	if newValue != hg_font_default then
		RunConsoleCommand("hg_font", hg_font_default)
	end
end, "hg_font_lock")

hook.Add("InitPostEntity", "hg_font_force_join", function()
	ForceHGFirstPersonDeath()
	ForceHGFont()
	timer.Simple(1, ForceHGFirstPersonDeath)
	timer.Simple(5, ForceHGFirstPersonDeath)
	timer.Simple(1, ForceHGFont)
	timer.Simple(5, ForceHGFont)
end)

local hg_attachment_draw_distance = CreateClientConVar("hg_attachment_draw_distance", 0, true, nil, "distance to draw attachments", 0, 4096)

xbars = 17
ybars = 30

gradient_l = Material("vgui/gradient-l")

local logoistMat = Material("vgui/logoist.png", "noclamp smooth")

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local sw, sh = ScrW(), ScrH()

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end

local SOUND_SETTINGS_CLICK = "ui/rem_click.wav"
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

local settings_header_height = 78

local function CreateSettingsFonts()
    local scale = math.min(ScrW(), ScrH()) / 1000

    surface.CreateFont("ZCity_Menu_Small", {
        font = "Verily Serif Mono",
        size = ScreenScale(20),
        weight = 200,
    })
    surface.CreateFont("ZCity_Menu_Tiny", {
        font = "Verily Serif Mono",
        size = ScreenScale(8),
        weight = 200,
    })
    surface.CreateFont("ZCity_Menu_Settings_Medium", {
        font = "Verily Serif Mono",
        size = math.max(16, math.floor(32 * scale)),
        weight = 300,
    })
    surface.CreateFont("ZCity_Menu_Settings_Small", {
        font = "Verily Serif Mono",
        size = math.max(14, math.floor(22 * scale)),
        weight = 300,
    })
    surface.CreateFont("ZCity_Menu_Settings_Button", {
        font = "Verily Serif Mono",
        size = math.max(16, math.floor(27 * scale)),
        weight = 300,
    })
    surface.CreateFont("ZCity_Menu_Settings_Tiny", {
        font = "Verily Serif Mono",
        size = math.max(12, math.floor(16 * scale)),
        weight = 300,
    })
    surface.CreateFont("ZCity_Menu_Settings_Category", {
        font = "Verily Serif Mono",
        size = ScreenScale(15),
        weight = 100
    })
end
hook.Add("OnScreenSizeChanged", "ZCity_Settings_Fonts", CreateSettingsFonts)
CreateSettingsFonts()

hg.settings:AddOpt("Gameplay","hg_old_notificate", "Old Notifications")
hg.settings:AddOpt("Gameplay","hg_showthoughts", "Show thoughts")
hg.settings:AddOpt("Gameplay","hg_newthoughts", "New stacked thoughts")
hg.settings:AddOpt("Gameplay","hg_hints", "Show hints")
hg.settings:AddOpt("Gameplay","hg_gary", "HG GARY")
hg.settings:AddOpt("Gameplay","hg_deathfadeout", "Death fade out")
hg.settings:AddOpt("Gameplay","deatheffect_enabled", "Cinematic Death Screen")
hg.settings:AddOpt("Gameplay","hg_hold_shift_sprint", "Hold shift to sprint")
if not game.IsDedicated() then
	hg.settings:AddOpt("Serverside gameplay","hg_toughnpcs", "Tough npcs")
	hg.settings:AddOpt("Serverside gameplay","hg_thirdperson", "Thirdperson (WIP)")
	hg.settings:AddOpt("Serverside gameplay","hg_legacycam", "Legacy camera")
	hg.settings:AddOpt("Serverside gameplay","hg_ragdollcombat", "Ragdoll combat mode")
	hg.settings:AddOpt("Serverside gameplay","hg_movement_stamina_debuff", "Movement stamina debuff")
	hg.settings:AddOpt("Serverside gameplay","hg_furcity", "Furcity")
	hg.settings:AddOpt("Serverside gameplay","hg_appearance_access_for_all", "Appearance full access for all", nil, nil, "bool")
	hg.settings:AddOpt("Serverside gameplay","hg_healanims", "Heal & food animations")
	hg.settings:AddOpt("Serverside gameplay","hg_aimtoshoot", "DarkRP-like shoot system (aim to shoot)")
	hg.settings:AddOpt("Serverside gameplay","hg_slings", "Sling system")
    hg.settings:AddOpt("Serverside gameplay","homicide_traitoramount", "Homicide: Traitor Amount", nil, nil, "int")
end

hg.settings:AddOpt("Debug","hg_show_hitposmuzzle", "Show weapon hitpos")
hg.settings:AddOpt("Debug","hg_setzoompos", "Edit weapon zoompos, check console for results")
hg.settings:AddOpt("Debug","hg_show_hitbox", "Show hitboxes")

hg.settings:AddOpt("Optimization","hg_potatopc", "Potato PC Mode")
hg.settings:AddOpt("Optimization","hg_reduce_screeneffects", "Reduce screen effects 50%")
hg.settings:AddOpt("Optimization","hg_anims_draw_distance", "Animations Draw Distance", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_anim_fps", "Animations FPS", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_attachment_draw_distance", "Attachment Draw Distance", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_maxsmoketrails", "Maximum Smoke Trails", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_tpik_distance", "TPIK Render Distance", true, nil, "int")

hg.settings:AddOpt("Blood","hg_blood_draw_distance", "Blood Draw Distance")
hg.settings:AddOpt("Blood","hg_blood_fps", "Blood FPS")
hg.settings:AddOpt("Blood","hg_blood_sprites", "Blood Sprites (DISABLED FOR EVERYONE)")
hg.settings:AddOpt("Blood","hg_old_blood", "Old blood")

hg.settings.tbl["UI"] = hg.settings.tbl["UI"] or {}
hg.settings.tbl["UI"]["hg_font"] = nil
hg.settings:AddOpt("UI","hg_oldradialmenu", "Old Radial Menu")

hg.settings:AddOpt("Weapons","hg_weaponshotblur_enable", "Shooting Blur")
hg.settings:AddOpt("Weapons","hg_dynamic_mags", "Dynamic Ammo Inspect")
hg.settings:AddOpt("Weapons","hg_zoomsensitivity", "Scope sensitivity")
hg.settings:AddOpt("Weapons","hg_highpitchgunfire", "Toggle high pitched gunfire sounds inside buildings")
hg.settings:AddOpt("Weapons","hg_nofovzoom", "Disable/Enable FOV Zoom")
hg.settings:AddOpt("Weapons","hg_quickdraw_alt", "Pistol quick draw uses Alt instead of Shift")

hg.settings:AddOpt("View","hg_fov", "Field Of View")
hg.settings:AddOpt("View","hg_newspectate", "Smooth Spectator Camera")
hg.settings:AddOpt("View","hg_cshs_fake", "C'sHS Ragdoll Camera")
hg.settings:AddOpt("View","hg_gun_cam", "Gun Camera (ADMIN ONLY)")
hg.settings:AddOpt("View","hg_realismcam", "Realism camera (shitty)")
hg.settings:AddOpt("View","hg_gopro", "GoPro camera")
hg.settings:AddOpt("View","hg_newfakecam", "New fake camera")
hg.settings:AddOpt("View","deatheffect_enabled", "Cinematic Death Screen")
hg.settings:AddOpt("View","hg_leancam_mul", "Lean camera mul", true, nil, "int")
hg.settings:AddOpt("View","hg_gun_cam", "Gun camera (WIP Admin only)")
hg.settings:AddOpt("Sound","hg_dmusic", "Dynamic Music")
hg.settings:AddOpt("Sound","hg_quietshots", "Enable/Disable Quietshoot Sounds")
hg.settings:AddOpt("Sound","hg_success_sound_alt", "Alternate Success Sound", nil, nil, "bool")


function hg.CreateCategory(ctgName, ParentPanel, yPos)
    local pppanel = vgui.Create('DPanel', ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide() / 1.05, ParentPanel:GetTall() * 0.07)
    pppanel:SetPos(ParentPanel:GetWide() / 2 -pppanel:GetWide() / 2, yPos)
    pppanel.Paint = function(self,w,h)
        surface.SetDrawColor(60,60,60,145)
        surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(42, 42, 42, 184)
		surface.DrawRect(0, h-5, w, 5)
    
        draw.SimpleText(ctgName, 'ZCity_Menu_Settings_Category', w / 2, h / 2, color3, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    return pppanel
end

function hg.GetConVarType(convar)
    local stringv = convar:GetString()
    local floatVal = convar:GetFloat()
    local intVal = convar:GetInt()
    local boolVal = convar:GetBool()

    if (stringv == '0' and not boolVal) or (stringv == '1' and boolVal) then
        return 'bool'
    end

    if tonumber(stringv) and math.floor(stringv) == floatVal then
        if intVal == floatVal then
            return "int"
        end
    end

    return "string"
end

local function SetConVarValue(convar, value)
    if not convar then
        return
    end

    local name = convar.GetName and convar:GetName()
    if not name or name == "" then
        return
    end

    if isbool(value) then
        RunConsoleCommand(name, value and "1" or "0")
        return
    end

    RunConsoleCommand(name, tostring(value))
end

local clr_1 = Color(255,255,255,104)
local clr_2 = Color(122,122,122,104)
local clr_3 = Color(28,28,28)
local clr_4 = Color(0, 0, 0, 30)
local clr_5 = Color(30, 29, 29, 30)
local clr_6 = Color(255, 255, 255, 100)
local clr_7 = Color(255, 255, 255, 200)
local clr_8 = Color(70, 130, 180)

local settings_color_blacky = Color(25,25,30,220)
local settings_color_whitey = Color(255,255,255,240)
local settings_color_dim = Color(60,60,60,180)
local settings_color_text = Color(225,225,225)
local settings_color_text_dim = Color(160,160,160)
local settings_color_accent = Color(192,57,43)

local tex_gradient_d = surface.GetTextureID("vgui/gradient-d")
local tex_gradient_r = surface.GetTextureID("vgui/gradient-r")
local tex_gradient_l = surface.GetTextureID("vgui/gradient-l")
local info_row_gradient = Material("vgui/gradient-l")
local settings_menu_gradient_right = Color(18,18,18,65)
local settings_clr_1 = Color(100,100,100,35)
local settings_clr_verygray = Color(10,10,19,235)

local settings_sw, settings_sh = ScrW(), ScrH()
local settings_active_category = nil
local settings_buttons = {}
local settings_category_buttons = {}
local settings_content_panel = nil
local settings_sidebar_panel = nil
local settings_main_panel = nil
local settings_header_label = nil
local isValidMainMenuPanel = false
local settings_entry_width = nil

-- main menu look: same palette, font and buttons as the ESC menu's bars
local mm_bar_bg = Color(28, 28, 28, 180)
local mm_border = Color(180, 180, 180)
local mm_btn_bg = Color(31, 31, 31, 205)
local mm_btn_hover = Color(48, 48, 48, 235)
local mm_accent = Color(225, 225, 225)
local mm_text = Color(220, 220, 220)
local mm_text_idle = Color(188, 188, 188)
local mm_text_dim = Color(140, 140, 140)
local SOUND_MM_HOVER = "ui/rem_hover.wav"
local SOUND_MM_SELECT = "ui/rem_click.wav" -- same click as the loadout menu RETURN button

local function CreateSettingsMMFonts()
    local scale = math.min(ScrW(), ScrH()) / 1000
    surface.CreateFont("ZCity_SetMM_Title", {font = "IBM Plex Mono", size = math.max(18, math.floor(38 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_SetMM_Button", {font = "IBM Plex Mono", size = math.max(14, math.floor(22 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_SetMM_Row", {font = "IBM Plex Mono", size = math.max(14, math.floor(21 * scale)), weight = 400, antialias = true})
    surface.CreateFont("ZCity_SetMM_Small", {font = "IBM Plex Mono", size = math.max(11, math.floor(15 * scale)), weight = 400, antialias = true})
end
hook.Add("OnScreenSizeChanged", "ZCity_SettingsMM_Fonts", CreateSettingsMMFonts)
CreateSettingsMMFonts()

-- a box like the main menu buttons: dark rounded box, thin border, light strip on the left when lit
local function MMBox(w, h, hl, active)
    local lit = math.max(hl or 0, active and 1 or 0)
    draw.RoundedBox(3, 0, 0, w, h, lit > 0.5 and mm_btn_hover or mm_btn_bg)
    surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 45 + 100 * lit)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    if lit > 0.01 then
        surface.SetDrawColor(mm_accent.r, mm_accent.g, mm_accent.b, 210 * lit)
        surface.DrawRect(0, 0, MenuUnit(3), h)
    end
end

-- text that types itself in behind '#' placeholders, like the main menu buttons
local function MMReveal(text, openTime)
    local chars = math.Clamp(math.floor((CurTime() - (openTime or 0)) * 22), 0, #text)
    return text:sub(1, chars) .. string.rep("#", #text - chars)
end

-- a main-menu style button
local function MMButton(parent, label, onClick, font, alignLeft)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn.Label = label
    btn.Font = font or "ZCity_SetMM_Button"
    btn.HoverLerp = 0
    btn.OpenTime = CurTime()
    function btn:Think()
        local hovered = self:IsHovered()
        if hovered and not self.WasHovered then surface.PlaySound(SOUND_MM_HOVER) end
        self.WasHovered = hovered
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, hovered and 1 or 0)
    end
    function btn:Paint(w, h)
        local active = self.IsActive and self:IsActive() or false
        MMBox(w, h, self.HoverLerp, active)
        local col = (self:IsHovered() or active) and mm_text or mm_text_idle
        local text = isfunction(self.Label) and self.Label(self) or self.Label
        if not self.NoReveal then text = MMReveal(text, self.OpenTime) end
        if alignLeft then
            draw.SimpleText(text, self.Font, MenuUnit(16), h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(text, self.Font, w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return true
    end
    function btn:DoClick()
        surface.PlaySound(SOUND_MM_SELECT)
        if onClick then onClick(self) end
    end
    return btn
end

-- setting / keybind rows: a card like the menu buttons that lights up while hovered
local function MMRowPaint(self, w, h)
    local hovered = self:IsHovered() or self:IsChildHovered()
    self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, hovered and 1 or 0)
    MMBox(w, h, self.HoverLerp)
end

-- the main menu's bar / panel background
local function MMPanelPaint(self, w, h)
    draw.RoundedBox(3, 0, 0, w, h, mm_bar_bg)
    surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 50)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

local function MMScrollbar(scroll)
    local sbar = scroll:GetVBar()
    sbar:SetWide(MenuUnit(4))
    sbar:SetHideButtons(true)
    function sbar:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 80)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnGrip:Paint(w, h)
        surface.SetDrawColor(mm_accent.r, mm_accent.g, mm_accent.b, self:IsHovered() and 200 or 90)
        surface.DrawRect(0, 0, w, h)
    end
end

-- page shell shared by the information page: main menu top bar with RETURN, a list on the left and a
-- panel on the right (same layout as the settings page)
local function MMBuildPage(ParentPanel, pageTitle, listTitle, hintText)
    local function GoBack()
        if not IsValid(ParentPanel) then return end
        local luaMenu = ParentPanel:GetParent()
        ParentPanel:AlphaTo(0, 0.2, 0, function()
            if IsValid(ParentPanel) then ParentPanel:Remove() end
        end)
        if IsValid(luaMenu) then
            for _, child in ipairs(luaMenu:GetChildren()) do
                if child ~= ParentPanel then
                    child:SetVisible(true)
                    child:AlphaTo(255, 0.2, 0)
                end
            end
            if luaMenu.panelparrent then
                luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                luaMenu.panelparrent:SetPos(0, 0)
                luaMenu.panelparrent:SetSize(ScrW(), ScrH())
                luaMenu.panelparrent:MoveToFront()
                luaMenu.panelparrent:SetMouseInputEnabled(false)
                luaMenu.panelparrent.Paint = function() end
            end
            if luaMenu.ResetCurrentPanel then
                luaMenu:ResetCurrentPanel()
            end
        else
            ParentPanel:Remove()
        end
    end

    local sw, sh = ScrW(), ScrH()
    local barH = MenuUnit(64)
    local topBar = vgui.Create("DPanel", ParentPanel)
    topBar:SetSize(sw, barH)
    topBar:SetPos(0, -barH)
    topBar:MoveTo(0, 0, 0.35, 0, 0.3)
    topBar.OpenTime = CurTime()
    topBar.Paint = function(self, w, h)
        surface.SetDrawColor(mm_bar_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 50)
        surface.DrawRect(0, h - 1, w, 1)
        draw.SimpleText(MMReveal(pageTitle, self.OpenTime), "ZCity_SetMM_Title", MenuUnit(14), h / 2, mm_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local backBtn = MMButton(topBar, "RETURN", GoBack)
    topBar.PerformLayout = function(self, w, h)
        local pad = MenuUnit(6)
        local bw = MenuUnit(160)
        local bh = math.min(h - pad * 2, MenuUnit(52))
        backBtn:SetSize(bw, bh)
        backBtn:SetPos(w - pad - bw, math.floor((h - bh) / 2))
    end

    local gap = MenuUnit(12)
    local bodyY = barH + gap
    local bodyH = sh - bodyY - gap
    local sidebarWidth = math.floor(sw / 3.6)

    local function SlideThink(self)
        local curX, curY = self:GetPos()
        if math.abs(curX - self.TargetX) > 0.5 then
            self:SetPos(Lerp(FrameTime() * 8, curX, self.TargetX), curY)
        else
            self:SetPos(self.TargetX, curY)
        end
    end

    local sidebar = vgui.Create("DPanel", ParentPanel)
    sidebar:SetSize(sidebarWidth - gap, bodyH)
    sidebar:SetPos(-sidebarWidth, bodyY)
    sidebar.TargetX = gap
    sidebar.Think = SlideThink
    sidebar.Paint = MMPanelPaint

    local sidebarHeader = vgui.Create("DPanel", sidebar)
    sidebarHeader:Dock(TOP)
    sidebarHeader:SetTall(MenuUnit(40))
    sidebarHeader.OpenTime = CurTime()
    sidebarHeader.Paint = function(self, w, h)
        draw.SimpleText(MMReveal(listTitle, self.OpenTime), "ZCity_SetMM_Small", MenuUnit(14), h * 0.6, mm_text_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 50)
        surface.DrawRect(MenuUnit(10), h - 1, w - MenuUnit(20), 1)
    end

    local mainW = sw - sidebarWidth - gap * 2
    local mainPanel = vgui.Create("DPanel", ParentPanel)
    mainPanel:SetSize(mainW, bodyH)
    mainPanel:SetPos(sw, bodyY)
    mainPanel.TargetX = sidebarWidth + gap
    mainPanel.Think = SlideThink
    mainPanel.Paint = MMPanelPaint

    local header = vgui.Create("DPanel", mainPanel)
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, MenuUnit(4))
    header:SetTall(MenuUnit(76))
    header.Paint = function(self, w, h)
        surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 50)
        surface.DrawRect(MenuUnit(10), h - 1, w - MenuUnit(20), 1)
    end

    local headerTitle = vgui.Create("DLabel", header)
    headerTitle:SetPos(MenuUnit(16), MenuUnit(8))
    headerTitle:SetTall(MenuUnit(42))
    headerTitle:SetContentAlignment(1)
    headerTitle:SetFont("ZCity_SetMM_Title")
    headerTitle:SetTextColor(mm_text)
    headerTitle:SetText(pageTitle)
    headerTitle:SetWide(mainW - MenuUnit(32))

    local headerHint = vgui.Create("DLabel", header)
    headerHint:SetPos(MenuUnit(16), MenuUnit(50))
    headerHint:SetContentAlignment(1)
    headerHint:SetFont("ZCity_SetMM_Small")
    headerHint:SetTextColor(mm_text_dim)
    headerHint:SetText(hintText or "")
    headerHint:SizeToContents()

    local contentHolder = vgui.Create("DPanel", mainPanel)
    contentHolder:Dock(FILL)
    contentHolder:DockMargin(0, 0, 0, MenuUnit(8))
    contentHolder.Paint = function() end

    return { topBar = topBar, sidebar = sidebar, main = mainPanel, title = headerTitle, hint = headerHint, content = contentHolder, back = GoBack }
end

local info_sections = {
    {title = "Rank", key = "rank"},
    {title = "Credits", key = "credits"}
}
local info_credit_entries = {
    {name = "Wiley", merit = "The main developer of judge.", steamid = "76561199162536724", img = "wiley"},
    {name = "CodeOrange", merit = "Contributor of judge.", steamid = "76561198893264087", img = "codeorange"},
    {name = "Lazzy", merit = "Main weapons developer.", steamid = "76561198876700603", img = "lazzy"},
    {name = "Kazoo", merit = "Developer of \"Remorseism\".", steamid = "76561199404982388", img = "kazoo"},
    {name = "fuzyaker", merit = "Manhunt execution animations", img = "fuzyaker", url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3782848810"}
}
local info_fallback_band = {
    icon = Material("vgui/mats_jack_awards/10")
}
local info_fallback_medal = {
    icon = Material("vgui/mats_jack_awards/pt")
}
local info_stat_rows = {
    {"Kills", "Kills"},
    {"Headshots", "Headshots"},
    {"Deaths", "Deaths"},
    {"Suicides", "Suicides"}
}
local info_active_section = nil
local info_section_buttons = {}
local info_content_panel = nil
local info_header_label = nil
local info_achievement_rarity_colors = {
    Uncommon = Color(92, 184, 92),
    Rare = Color(65, 135, 230),
    Epic = Color(156, 82, 220),
    Legendary = Color(240, 151, 40),
    Mythic = Color(235, 62, 122),
    Exotic = Color(235, 55, 45)
}

local function InfoFormatAchievementDate(timestamp)
    timestamp = tonumber(timestamp)
    return timestamp and os.date("%d.%m.%Y %H:%M", timestamp) or "date unknown"
end

local function InfoGetObtainedAchievements()
    local results = {}
    if not hg or not hg.achievements or not hg.achievements.achievements_data then return results end
    local created = hg.achievements.achievements_data.created_achevements or {}
    local localach = hg.achievements.GetLocalAchievements and hg.achievements.GetLocalAchievements() or {}

    for key, ach in pairs(created) do
        local playerData = localach and localach[key] or nil
        local value = playerData and playerData.value or ach.start_value or 0
        if value >= (ach.needed_value or 1) then
            local entry = table.Copy(ach)
            entry.obtained_at = playerData and playerData.obtained_at
            entry.rarity = hg.achievements.achievements_data.rarity and hg.achievements.achievements_data.rarity[key]
            results[#results + 1] = entry
        end
    end

    table.sort(results, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)

    return results
end

local function InfoHasLocalAchievement(key)
    if not hg or not hg.achievements or not hg.achievements.achievements_data then return false end
    local created = hg.achievements.achievements_data.created_achevements or {}
    local ach = created[key]
    if not ach then return false end
    local localach = hg.achievements.GetLocalAchievements and hg.achievements.GetLocalAchievements() or {}
    local playerData = localach and localach[key] or nil
    return (playerData and playerData.value or ach.start_value or 0) >= (ach.needed_value or 1)
end

local info_stat_methods = {
    Kills = "GetKills",
    Deaths = "GetDeaths",
    Suicides = "GetSuicides"
}

local function InfoGetPlayerStat(ply, key)
    if not IsValid(ply) then return 0 end

    local cached = ply.SvDB and ply.SvDB[key]
    if cached ~= nil then
        return tonumber(cached) or 0
    end

    if key == "Headshots" then
        return tonumber(ply:GetNWInt("Headshots", 0)) or 0
    end

    local methodName = info_stat_methods[key]
    local method = methodName and ply[methodName]
    if isfunction(method) then
        return tonumber(method(ply)) or 0
    end

    return 0
end

local INFO_STORED_STAT_NET = "get_svPData"
local INFO_RANK_NET = "zb_xp_get"

local function InfoCanStartNet(messageName)
    return util.NetworkStringToID(messageName) ~= 0
end

local function InfoRequestStoredStat(ply, key)
    if not IsValid(ply) or not InfoCanStartNet(INFO_STORED_STAT_NET) then return end
    net.Start(INFO_STORED_STAT_NET)
        net.WriteEntity(ply)
        net.WriteString(key)
    net.SendToServer()
end

local function InfoRefreshLocalRankData()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if InfoCanStartNet(INFO_RANK_NET) then
        net.Start(INFO_RANK_NET)
            net.WriteEntity(ply)
        net.SendToServer()
    end

    for _, statData in ipairs(info_stat_rows) do
        InfoRequestStoredStat(ply, statData[2])
    end

    if hg and hg.achievements and hg.achievements.LoadAchievements then
        hg.achievements.LoadAchievements()
    end
end

hook.Add("RoundInfoCalled", "InfoRankRoundRefresh", function()
    timer.Simple(0, function()
        if zb and zb.ROUND_STATE == 3 then
            InfoRefreshLocalRankData()
        end
    end)
end)

hg.Leaderboard = hg.Leaderboard or {Rows = {}, NextRequest = 0}

function hg.Leaderboard.Request(limit)
    if not InfoCanStartNet("zb_sql_leaderboard") then return end
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
    if not row or not zb or not zb.Experience or not zb.Experience.GetAwards then return info_fallback_band, info_fallback_medal end
    return zb.Experience.GetAwards({skill = row.skill or 0, exp = row.xp or 0})
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

local function SettingsCreateCategoryButton(pParent, strTitle, categoryKey)
    local btn = MMButton(pParent, string.upper(strTitle), function()
        settings_active_category = categoryKey
        SettingsRefreshContent()
    end, "ZCity_SetMM_Button", true)
    btn:Dock(TOP)
    btn:SetTall(MenuUnit(48))
    btn:DockMargin(MenuUnit(10), MenuUnit(8), MenuUnit(10), 0)
    btn.CategoryKey = categoryKey
    btn.IsActive = function(self) return settings_active_category == self.CategoryKey end
    settings_category_buttons[#settings_category_buttons + 1] = btn
    return btn
end

function SettingsRefreshCategoryButtons()
    for _, btn in ipairs(settings_category_buttons) do
        if IsValid(btn) then
            btn.OpenTime = CurTime()
        end
    end
end

function SettingsRefreshContent()
    if not IsValid(settings_content_panel) then return end
    settings_content_panel:Clear()

    if settings_active_category == "Keybinds" then
        if IsValid(settings_header_label) then
            settings_header_label:SetText("KEYBINDS")
        end
        if hg.FillKeybinds then
            hg.FillKeybinds(settings_content_panel)
        end
        return
    end

    if not settings_active_category or not hg.settings.tbl[settings_active_category] then
        return
    end

    if IsValid(settings_header_label) then
        settings_header_label:SetText(settings_active_category:upper())
    end

    local scroll = vgui.Create("DScrollPanel", settings_content_panel)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 0, 0, 0)
    scroll.Paint = function(self, w, h) end
    MMScrollbar(scroll)

    local yOffset = MenuUnit(10)
    local sidebarWidth = math.floor(settings_sw / 3.6)
    local entryWidth = settings_entry_width or (settings_sw - sidebarWidth)

    for convarName, settingData in SortedPairs(hg.settings.tbl[settings_active_category]) do
        if convarName == "hg_reduce_screeneffects" and not GetConVar("hg_potatopc"):GetBool() then continue end
        local convar = GetConVar(settingData[2])
        if not convar then continue end

        local row = vgui.Create("DPanel", scroll)
        row:SetSize(entryWidth - MenuUnit(20), MenuUnit(56))
        row:Dock(TOP)
        row:DockMargin(MenuUnit(10), MenuUnit(4), MenuUnit(10), MenuUnit(4))
        row.Paint = MMRowPaint

        local title = vgui.Create("DLabel", row)
        title:SetPos(MenuUnit(16), MenuUnit(7))
        title:SetFont("ZCity_SetMM_Row")
        title:SetTextColor(mm_text)
        title:SetText(settingData[3])
        title:SizeToContents()

        local help = vgui.Create("DLabel", row)
        help:SetPos(MenuUnit(16), MenuUnit(31))
        help:SetFont("ZCity_SetMM_Small")
        help:SetTextColor(mm_text_dim)
        help:SetText(convar:GetHelpText() or "")
        help:SizeToContents()
        help:SetWide(entryWidth - MenuUnit(220))

        local convarType = settingData[6] or hg.GetConVarType(convar)
        local ctrlX = entryWidth - MenuUnit(32)
        local ctrlW = MenuUnit(170)

        if convarType == 'bool' then
            local toggle = vgui.Create("DButton", row)
            toggle:SetSize(MenuUnit(46), MenuUnit(22))
            toggle:SetPos(ctrlX - toggle:GetWide(), MenuUnit(17))
            toggle:SetText("")
            local animProgress = convar:GetBool() and 1 or 0
            local targetProgress = animProgress
            function toggle:Paint(w, h)
                animProgress = Lerp(FrameTime() * 8, animProgress, targetProgress)
                -- monochrome like the main menu: dark when off, light when on
                local bg = Lerp(animProgress, 40, 200)
                draw.RoundedBox(3, 0, 0, w, h, Color(20, 20, 20, 230))
                draw.RoundedBox(3, 1, 1, w - 2, h - 2, Color(bg, bg, bg, 210))
                surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, self:IsHovered() and 160 or 70)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                local slsize = h - MenuUnit(6)
                local slPos = Lerp(animProgress, MenuUnit(3), w - slsize - MenuUnit(3))
                local k = Lerp(animProgress, 220, 28)
                draw.RoundedBox(2, slPos, MenuUnit(3), slsize, slsize, Color(k, k, k))
            end
            function toggle:DoClick()
                local newValue = not convar:GetBool()
                if convar.GetName then
                    RunConsoleCommand(convar:GetName(), newValue and "1" or "0")
                end
                surface.PlaySound(SOUND_MM_SELECT)
                targetProgress = newValue and 1 or 0
            end

        elseif convarType == 'int' then
            local decimals = settingData[4] and 2 or 0
            local min = convar:GetMin() or 0
            local max = convar:GetMax() or 100
            
            local sliderBg = vgui.Create("DButton", row)
            sliderBg:SetSize(ctrlW - MenuUnit(50), MenuUnit(24))
            sliderBg:SetPos(ctrlX - sliderBg:GetWide(), MenuUnit(16))
            sliderBg:SetText("")
            
            local curVal = decimals > 0 and convar:GetFloat() or convar:GetInt()
            local frac = math.Clamp((curVal - min) / math.max(0.0001, max - min), 0, 1)
            
            function sliderBg:Paint(w, h)
                local trackY = h / 2 - MenuUnit(1)
                surface.SetDrawColor(20, 20, 20, 230)
                surface.DrawRect(0, trackY, w, MenuUnit(2))
                
                surface.SetDrawColor(settings_color_whitey.r, settings_color_whitey.g, settings_color_whitey.b, 220)
                surface.DrawRect(0, trackY, w * frac, MenuUnit(2))
                
                local knobX = math.Clamp(w * frac - MenuUnit(3), 0, w - MenuUnit(6))
                surface.SetDrawColor(245, 245, 245)
                draw.RoundedBox(MenuUnit(2), knobX, h / 2 - MenuUnit(4), MenuUnit(6), MenuUnit(8), Color(245, 245, 245))
            end
            
            local isDragging = false
            
            function sliderBg:OnMousePressed(mouseCode)
                if mouseCode == MOUSE_LEFT then
                    isDragging = true
                    self:MouseCapture(true)
                end
            end
            
            function sliderBg:OnMouseReleased(mouseCode)
                if mouseCode == MOUSE_LEFT then
                    isDragging = false
                    self:MouseCapture(false)
                end
            end
            
            function sliderBg:OnCursorMoved(x, y)
                if isDragging then
                    frac = math.Clamp(x / self:GetWide(), 0, 1)
                    local val = min + frac * (max - min)
                    if decimals > 0 then
                        val = math.Round(val, decimals)
                    else
                        val = math.Round(val)
                    end
                    if convar and convar.GetName then
                        RunConsoleCommand(convar:GetName(), tostring(val))
                    end
                end
            end
            
            function sliderBg:Think()
                if not isDragging and convar then
                    local cur = decimals > 0 and convar:GetFloat() or convar:GetInt()
                    frac = math.Clamp((cur - min) / math.max(0.0001, max - min), 0, 1)
                end
            end

            local valLabel = vgui.Create("DTextEntry", row)
            valLabel:SetSize(MenuUnit(60), MenuUnit(20))
            valLabel:SetPos(ctrlX - sliderBg:GetWide() - MenuUnit(70), MenuUnit(18))
            valLabel:SetFont("ZCity_SetMM_Small")
            valLabel:SetTextColor(mm_text)
            valLabel:SetText(tostring(curVal))
            valLabel:SetNumeric(true)
            valLabel.Paint = function(self, w, h)
                self:DrawTextEntryText(settings_color_text, Color(120, 130, 180), settings_color_text)
            end
            
            function valLabel:OnValueChange(val)
                if not isDragging and convar and convar.GetName then
                    local numVal = tonumber(val)
                    if numVal then
                        if decimals > 0 then
                            numVal = math.Round(numVal, decimals)
                        else
                            numVal = math.Round(numVal)
                        end
                        RunConsoleCommand(convar:GetName(), tostring(numVal))
                    end
                end
            end
            
            function valLabel:Think()
                if convar and not self:HasFocus() then
                    local cur = decimals > 0 and convar:GetFloat() or convar:GetInt()
                    if self:GetText() ~= tostring(cur) then
                        self:SetText(tostring(cur))
                    end
                end
            end

        elseif convarType == 'string' then
            local textEntry = vgui.Create("DTextEntry", row)
            textEntry:SetSize(ctrlW, MenuUnit(24))
            textEntry:SetPos(ctrlX - ctrlW, MenuUnit(16))
            textEntry:SetText(convar:GetString())
            textEntry:SetUpdateOnType(true)
            textEntry:SetFont("ZCity_SetMM_Small")
            textEntry.Paint = function(self, w, h)
                draw.RoundedBox(3, 0, 0, w, h, Color(20, 20, 20, 240))
                surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, self:HasFocus() and 160 or 70)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                self:DrawTextEntryText(color_white, Color(120, 130, 180), color_white)
            end
            function textEntry:OnValueChange(val)
                if convar and convar.GetName then
                    RunConsoleCommand(convar:GetName(), val)
                end
            end
        end

        yOffset = yOffset + row:GetTall() + MenuUnit(8)
    end
end

function hg.DrawSettings(ParentPanel)
    settings_sw, settings_sh = ScrW(), ScrH()
    isValidMainMenuPanel = IsValid(ParentPanel)

    ParentPanel:SetAlpha(0)
    -- the main menu's blurred black & white backdrop shows through, just a touch darker
    ParentPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 70)
        surface.DrawRect(0, 0, w, h)
    end
    ParentPanel:AlphaTo(255, 0.15, 0)

    settings_category_buttons = {}
    settings_buttons = {}

    local isSuperAdmin = LocalPlayer():IsSuperAdmin()

    local allowedCategories = {}
    for categoryName, _ in pairs(hg.settings.tbl) do
        if (categoryName == "Debug" or categoryName == "Serverside gameplay") and not isSuperAdmin then
            continue
        end
        allowedCategories[categoryName] = true
    end
    allowedCategories["Keybinds"] = true

    if not settings_active_category or not allowedCategories[settings_active_category] then
        for categoryName, _ in pairs(allowedCategories) do
            settings_active_category = categoryName
            break
        end
    end

    local function GoBack()
        if not IsValid(ParentPanel) then return end
        local luaMenu = ParentPanel:GetParent()
        ParentPanel:AlphaTo(0, 0.2, 0, function()
            if IsValid(ParentPanel) then ParentPanel:Remove() end
        end)
        if IsValid(luaMenu) then
            for _, child in ipairs(luaMenu:GetChildren()) do
                if child ~= ParentPanel then
                    child:SetVisible(true)
                    child:AlphaTo(255, 0.2, 0)
                end
            end
            if luaMenu.panelparrent then
                luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                luaMenu.panelparrent:SetPos(0, 0)
                luaMenu.panelparrent:SetSize(ScrW(), ScrH())
                luaMenu.panelparrent:MoveToFront()
                luaMenu.panelparrent:SetMouseInputEnabled(false)
                luaMenu.panelparrent.Paint = function() end
            end
            if luaMenu.ResetCurrentPanel then
                luaMenu:ResetCurrentPanel()
            end
        else
            ParentPanel:Remove()
        end
    end

    -- top bar, same as the main menu's: title on the left, button on the right
    local barH = MenuUnit(64)
    local topBar = vgui.Create("DPanel", ParentPanel)
    topBar:SetSize(settings_sw, barH)
    topBar:SetPos(0, -barH)
    topBar:MoveTo(0, 0, 0.35, 0, 0.3)
    topBar.OpenTime = CurTime()
    topBar.Paint = function(self, w, h)
        surface.SetDrawColor(mm_bar_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 50)
        surface.DrawRect(0, h - 1, w, 1)
        draw.SimpleText(MMReveal("SETTINGS", self.OpenTime), "ZCity_SetMM_Title", MenuUnit(14), h / 2, mm_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local backBtn = MMButton(topBar, "RETURN", GoBack)
    topBar.PerformLayout = function(self, w, h)
        local pad = MenuUnit(6)
        local bw = MenuUnit(160)
        local bh = math.min(h - pad * 2, MenuUnit(52))
        backBtn:SetSize(bw, bh)
        backBtn:SetPos(w - pad - bw, math.floor((h - bh) / 2))
    end

    local gap = MenuUnit(12)
    local bodyY = barH + gap
    local bodyH = settings_sh - bodyY - gap
    local sidebarWidth = math.floor(settings_sw / 3.6)

    -- categories on the left
    local sidebar = vgui.Create("DPanel", ParentPanel)
    settings_sidebar_panel = sidebar
    sidebar:SetSize(sidebarWidth - gap, bodyH)
    sidebar:SetPos(-sidebarWidth, bodyY)
    sidebar.TargetX = gap
    sidebar.Think = function(self)
        local curX, curY = self:GetPos()
        if math.abs(curX - self.TargetX) > 0.5 then
            self:SetPos(Lerp(FrameTime() * 8, curX, self.TargetX), curY)
        else
            self:SetPos(self.TargetX, curY)
        end
    end
    sidebar.Paint = MMPanelPaint

    local sidebarHeader = vgui.Create("DPanel", sidebar)
    sidebarHeader:Dock(TOP)
    sidebarHeader:SetTall(MenuUnit(40))
    sidebarHeader.OpenTime = CurTime()
    sidebarHeader.Paint = function(self, w, h)
        draw.SimpleText(MMReveal("CATEGORIES", self.OpenTime), "ZCity_SetMM_Small", MenuUnit(14), h * 0.6, mm_text_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 50)
        surface.DrawRect(MenuUnit(10), h - 1, w - MenuUnit(20), 1)
    end

    for categoryName, _ in SortedPairs(hg.settings.tbl) do
        if (categoryName == "Debug" or categoryName == "Serverside gameplay") and not isSuperAdmin then
            continue
        end
        SettingsCreateCategoryButton(sidebar, categoryName, categoryName)
    end
    SettingsCreateCategoryButton(sidebar, "Keybinds", "Keybinds")

    -- the selected category's options
    local mainW = settings_sw - sidebarWidth - gap * 2
    settings_entry_width = mainW
    local mainPanel = vgui.Create("DPanel", ParentPanel)
    settings_main_panel = mainPanel
    mainPanel:SetSize(mainW, bodyH)
    mainPanel:SetPos(settings_sw, bodyY)
    mainPanel.TargetX = sidebarWidth + gap
    mainPanel.Think = function(self)
        local curX, curY = self:GetPos()
        if math.abs(curX - self.TargetX) > 0.5 then
            self:SetPos(Lerp(FrameTime() * 8, curX, self.TargetX), curY)
        else
            self:SetPos(self.TargetX, curY)
        end
    end
    mainPanel.Paint = MMPanelPaint

    local header = vgui.Create("DPanel", mainPanel)
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, MenuUnit(4))
    header:SetTall(MenuUnit(76))
    header.Paint = function(self, w, h)
        surface.SetDrawColor(mm_border.r, mm_border.g, mm_border.b, 50)
        surface.DrawRect(MenuUnit(10), h - 1, w - MenuUnit(20), 1)
    end

    local headerTitle = vgui.Create("DLabel", header)
    headerTitle:SetPos(MenuUnit(16), MenuUnit(8))
    headerTitle:SetTall(MenuUnit(42))
    headerTitle:SetContentAlignment(1)
    headerTitle:SetFont("ZCity_SetMM_Title")
    headerTitle:SetTextColor(mm_text)
    headerTitle:SetText(settings_active_category and settings_active_category:upper() or "SETTINGS")
    headerTitle:SetWide(mainW - MenuUnit(32))
    settings_header_label = headerTitle

    local headerHint = vgui.Create("DLabel", header)
    headerHint:SetPos(MenuUnit(16), MenuUnit(50))
    headerHint:SetContentAlignment(1)
    headerHint:SetFont("ZCity_SetMM_Small")
    headerHint:SetTextColor(mm_text_dim)
    headerHint:SetText("Preferences.")
    headerHint:SizeToContents()

    local contentHolder = vgui.Create("DPanel", mainPanel)
    contentHolder:Dock(FILL)
    contentHolder:DockMargin(0, 0, 0, MenuUnit(8))
    contentHolder.Paint = function(self, w, h) end
    settings_content_panel = contentHolder

    SettingsRefreshContent()
end

local keybinds_content_panel = nil
local keybinds_header_label = nil

local function KeybindsFormatKey(key)
    if not key or key == KEY_NONE or key == -999 then return "NONE" end
    local keyName = input.GetKeyName(key)
    return keyName and string.upper(keyName) or tostring(key)
end

local function KeybindsSetBind(bindName, slot, key)
    hg.Binds.CurrentBinds[bindName] = hg.Binds.CurrentBinds[bindName] or {KEY_NONE, nil}
    hg.Binds.CurrentBinds[bindName][slot] = key == KEY_NONE and nil or key
    hg.Binds.SaveThem()
end

local function KeybindsResetDefaults()
    for bindName, keys in pairs(hg.Binds.StandartBinds or {}) do
        hg.Binds.CurrentBinds[bindName] = {keys[1], keys[2]}
    end
    hg.Binds.SaveThem()
end

local function KeybindsCreateSidebarButton(pParent, strTitle)
    local btn = vgui.Create("DLabel", pParent)
    btn:SetText(string.rep("#", #strTitle))
    btn:SetMouseInputEnabled(true)
    btn:SizeToContents()
    btn:SetFont("ZCity_Menu_Settings_Small")
    btn:SetTall(MenuUnit(42))
    btn:Dock(TOP)
    btn:DockMargin(MenuUnit(15), MenuUnit(2), 0, 0)
    btn.RColor = Color(225,225,225)
    btn.OpenTime = CurTime()
    btn.LineLerp = 0
    btn.HoverLerp = 0

    function btn:Think()
        local isHovered = self:IsHovered()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, isHovered and 1 or 0)
        self.LineLerp = LerpFT(0.2, self.LineLerp or 0, isHovered and 1 or 0)
        self:DockMargin(math.Round(MenuUnit(15) + self.HoverLerp * MenuUnit(2)), MenuUnit(2), 0, 0)

        local targetText = "[ " .. strTitle .. " ]"
        local charsToShow = math.min(#targetText, math.floor((CurTime() - self.OpenTime) * 15))
        local ntxt = ""
        for i = 1, #targetText do
            ntxt = ntxt .. (i <= charsToShow and targetText:sub(i, i) or "#")
        end
        if self:GetText() ~= ntxt then
            self:SetText(ntxt)
            self:SizeToContents()
        end
    end

    function btn:Paint(w, h)
        local isHovered = self:IsHovered()
        local flash = isHovered and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
        local textColor = self.RColor
        local outlineColor = Color(0, 0, 0, 255)
        if isHovered then
            local v = flash * 255
            textColor = Color(v, v, v, 255)
            outlineColor = Color(255 - v, 255 - v, 255 - v, 255)
        end
        surface.SetFont(self:GetFont())
        local tw, th = surface.GetTextSize(self:GetText())
        draw.SimpleTextOutlined(self:GetText(), self:GetFont(), 0, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outlineColor)
        if self.LineLerp and self.LineLerp > 0.01 then
            surface.SetDrawColor(255, 255, 255, 255 * self.LineLerp)
            surface.DrawRect(0, h / 2 + th / 2, tw * self.LineLerp, math.max(1, MenuUnit(1)))
        end
        return true
    end
end

local function KeybindsCreateBinder(parent, bindName, slot, x, y)
    local binder = vgui.Create("DBinder", parent)
    binder:SetSize(MenuUnit(120), MenuUnit(28))
    binder:SetPos(x, y)
    binder:SetValue((hg.Binds.CurrentBinds[bindName] or {})[slot] or KEY_NONE)
    binder:SetFont("ZCity_SetMM_Small")

    function binder:Paint(w, h)
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or self.Trapping) and 1 or 0)
        MMBox(w, h, self.HoverLerp)
        draw.SimpleText(self.Trapping and "PRESS A BUTTON" or KeybindsFormatKey(self:GetValue()), "ZCity_SetMM_Small", w / 2, h / 2, self.HoverLerp > 0.5 and mm_text or mm_text_idle, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end

    function binder:OnChange(key)
        KeybindsSetBind(bindName, slot, key)
    end

    return binder
end

function KeybindsRefreshContent()
    if not IsValid(keybinds_content_panel) then return end
    keybinds_content_panel:Clear()

    if IsValid(keybinds_header_label) then
        keybinds_header_label:SetText("KEYBINDS")
    end

    local scroll = vgui.Create("DScrollPanel", keybinds_content_panel)
    scroll:Dock(FILL)
    scroll.Paint = function() end
    MMScrollbar(scroll)

    local entryWidth = keybinds_content_panel:GetWide()
    if entryWidth <= 0 then entryWidth = settings_sw end

    for bindName, bindData in SortedPairs(hg.Binds.CurrentBinds or {}) do
        local row = vgui.Create("DPanel", scroll)
        row:SetSize(entryWidth - MenuUnit(20), MenuUnit(68))
        row:Dock(TOP)
        row:DockMargin(MenuUnit(10), MenuUnit(4), MenuUnit(10), MenuUnit(4))
        row.Paint = MMRowPaint

        local title = vgui.Create("DLabel", row)
        title:SetPos(MenuUnit(16), MenuUnit(9))
        title:SetFont("ZCity_SetMM_Row")
        title:SetTextColor(mm_text)
        title:SetText(hg.Binds.Names[bindName] or bindName)
        title:SizeToContents()

        local help = vgui.Create("DLabel", row)
        help:SetPos(MenuUnit(16), MenuUnit(36))
        help:SetFont("ZCity_SetMM_Small")
        help:SetTextColor(mm_text_dim)
        help:SetText(bindName)
        help:SizeToContents()

        local clear = MMButton(row, "CLEAR", nil, "ZCity_SetMM_Small")
        clear.NoReveal = true
        clear:SetSize(MenuUnit(62), MenuUnit(28))
        clear.DoClick = function()
            surface.PlaySound(SOUND_MM_SELECT)
            hg.Binds.CurrentBinds[bindName] = {KEY_NONE, nil}
            hg.Binds.SaveThem()
            KeybindsRefreshContent()
        end

        local binder1 = KeybindsCreateBinder(row, bindName, 1, 0, MenuUnit(20))
        local binder2 = KeybindsCreateBinder(row, bindName, 2, 0, MenuUnit(20))

        row.PerformLayout = function(self, w, h)
			clear:SetPos(w - MenuUnit(350), MenuUnit(20))
			binder1:SetPos(w - MenuUnit(274), MenuUnit(20))
			binder2:SetPos(w - MenuUnit(140), MenuUnit(20))
        end
    end
end

-- Keybinds as a category inside the settings page
function hg.FillKeybinds(panel)
    if not IsValid(panel) then return end
    settings_sw, settings_sh = ScrW(), ScrH()

    local bar = vgui.Create("DPanel", panel)
    bar:Dock(TOP)
    bar:SetTall(MenuUnit(48))
    bar:DockMargin(MenuUnit(10), MenuUnit(8), MenuUnit(10), 0)
    bar.Paint = function() end

    local hint = vgui.Create("DLabel", bar)
    hint:Dock(FILL)
    hint:SetFont("ZCity_SetMM_Small")
    hint:SetTextColor(mm_text_dim)
    hint:SetText("Console binds still work; these are alternatives.")
    hint:SetContentAlignment(4)

    local resetBtn = MMButton(bar, "RESET DEFAULTS", nil, "ZCity_SetMM_Small")
    resetBtn:Dock(RIGHT)
    resetBtn:DockMargin(0, MenuUnit(8), 0, MenuUnit(8))
    resetBtn:SetWide(MenuUnit(170))

    local list = vgui.Create("DPanel", panel)
    list:Dock(FILL)
    list.Paint = function() end

    keybinds_content_panel = list
    keybinds_header_label = nil

    resetBtn.DoClick = function()
        surface.PlaySound(SOUND_MM_SELECT)
        KeybindsResetDefaults()
        keybinds_content_panel = list
        KeybindsRefreshContent()
    end

    KeybindsRefreshContent()
end

function hg.DrawKeybinds(ParentPanel)
    settings_sw, settings_sh = ScrW(), ScrH()

    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function(self, w, h)
        if hg.DrawBlur then hg.DrawBlur(self, 5) end
        draw.RoundedBox(0, 0, 0, w, h, settings_clr_verygray)
        surface.SetDrawColor(settings_menu_gradient_right)
        surface.SetTexture(tex_gradient_r)
        surface.DrawTexturedRect(0,0,w,h)
        surface.SetDrawColor(settings_clr_verygray)
        surface.SetTexture(tex_gradient_l)
        surface.DrawTexturedRect(0,0,w,h)
        surface.SetDrawColor(settings_clr_1)
        surface.SetTexture(tex_gradient_d)
        surface.DrawTexturedRect(0,0,w,h)
    end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local mainPanel = vgui.Create("DPanel", ParentPanel)
    mainPanel:SetSize(settings_sw, settings_sh)
    mainPanel:SetPos(settings_sw, 0)
    mainPanel.TargetX = 0
    mainPanel.Think = function(self)
        local curX, curY = self:GetPos()
        if math.abs(curX - self.TargetX) > 0.5 then self:SetPos(Lerp(FrameTime() * 8, curX, self.TargetX), curY) else self:SetPos(self.TargetX, curY) end
    end
    mainPanel.Paint = function() end

    local header = vgui.Create("DPanel", mainPanel)
    header:Dock(TOP)
    header:SetTall(MenuUnit(settings_header_height))
    header.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 20, 120))
        surface.SetDrawColor(settings_color_whitey.r, settings_color_whitey.g, settings_color_whitey.b, 140)
        surface.DrawRect(0, h - MenuUnit(1), w, MenuUnit(1))
    end

    local headerTitle = vgui.Create("DLabel", header)
    headerTitle:SetPos(MenuUnit(25), MenuUnit(18))
    headerTitle:SetFont("ZCity_Menu_Settings_Medium")
    headerTitle:SetTextColor(settings_color_whitey)
    headerTitle:SetText("KEYBINDS")
    headerTitle:SetWide(settings_sw - MenuUnit(50))
    keybinds_header_label = headerTitle

    local headerHint = vgui.Create("DLabel", header)
    headerHint:SetPos(MenuUnit(25), MenuUnit(45))
    headerHint:SetFont("ZCity_Menu_Settings_Tiny")
    headerHint:SetTextColor(settings_color_text_dim)
    headerHint:SetText("If you have the buttons already binded via console you can still use these as alternatives.")
    headerHint:SizeToContents()

	local backBtn = vgui.Create("DLabel", ParentPanel)
	backBtn:SetPos(MenuUnit(15), settings_sh - MenuUnit(62))
	backBtn:SetFont("ZCity_Menu_Settings_Small")
	backBtn:SetTextColor(settings_color_text)
	backBtn:SetText(string.rep("#", #"<- Return"))
	backBtn:SetMouseInputEnabled(true)
	backBtn:SizeToContents()
	backBtn:SetTall(MenuUnit(42))
	backBtn.OpenTime = CurTime()
	backBtn.HoverLerp = 0
	backBtn.LineLerp = 0
	backBtn.HoverScale = 0.008
	backBtn:MoveToFront()
	function backBtn:DoClick()
        surface.PlaySound(SOUND_SETTINGS_CLICK)
        if not IsValid(ParentPanel) then return end
        local luaMenu = ParentPanel:GetParent()
        ParentPanel:AlphaTo(0, 0.2, 0, function()
            if IsValid(ParentPanel) then ParentPanel:Remove() end
        end)
        if IsValid(luaMenu) then
            for _, child in ipairs(luaMenu:GetChildren()) do
                if child ~= ParentPanel then
                    child:SetVisible(true)
                    child:AlphaTo(255, 0.2, 0)
                end
            end
            if luaMenu.panelparrent then
                luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                luaMenu.panelparrent:SetPos(0, 0)
                luaMenu.panelparrent:SetSize(ScrW(), ScrH())
                luaMenu.panelparrent:MoveToFront()
                luaMenu.panelparrent:SetMouseInputEnabled(false)
                luaMenu.panelparrent.Paint = function() end
            end
            if luaMenu.ResetCurrentPanel then luaMenu:ResetCurrentPanel() end
        end
    end
	function backBtn:Think()
		local isHovered = self:IsHovered()
		self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, isHovered and 1 or 0)
		self.LineLerp = LerpFT(0.2, self.LineLerp or 0, isHovered and 1 or 0)
		local elapsed = CurTime() - self.OpenTime
		local charsToShow = math.floor(elapsed * 15)
		local target = "<- Return"
		local len = #target
		if charsToShow > len then charsToShow = len end
		if self.TypewriterTarget ~= target then
			self.TypewriterTarget = target
			self.LastTypewriterChars = 0
		end
		if charsToShow > 0 and charsToShow > (self.LastTypewriterChars or 0) then
			PlayTypewriterSound()
		end
		self.LastTypewriterChars = charsToShow
		local ntxt = ""
		for i = 1, len do
			if i <= charsToShow then ntxt = ntxt .. target:sub(i, i)
			else ntxt = ntxt .. "#" end
		end
		if self:GetText() ~= ntxt then
			self:SetText(ntxt)
			self:SizeToContents()
		end
	end
	function backBtn:Paint(w, h)
		local isHovered = self:IsHovered()
		local flash = isHovered and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
		local textColor = settings_color_text
		local outlineColor = Color(0, 0, 0, 255)
		if isHovered then
			local v = flash * 255
			textColor = Color(v, v, v, 255)
			local inv = 255 - v
			outlineColor = Color(inv, inv, inv, 255)
		end
		surface.SetFont(self:GetFont())
		local tw, th = surface.GetTextSize(self:GetText())
		local scale = 1 + (self.HoverLerp or 0) * (self.HoverScale or 0.02)
		local matrix = Matrix()
		matrix:Translate(Vector(0, h * (1 - scale) * 0.5, 0))
		matrix:Scale(Vector(scale, scale, 1))
		cam.PushModelMatrix(matrix)
		draw.SimpleTextOutlined(self:GetText(), self:GetFont(), 0, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outlineColor)
		if self.LineLerp and self.LineLerp > 0.01 then
			surface.SetDrawColor(255, 255, 255, 255 * self.LineLerp)
			surface.DrawRect(0, h / 2 + th / 2, tw * self.LineLerp, math.max(1, MenuUnit(1)))
		end
		cam.PopModelMatrix()
		return true
	end

    local resetBtn = vgui.Create("DButton", header)
    resetBtn:SetSize(MenuUnit(120), MenuUnit(28))
	resetBtn:SetPos(settings_sw - resetBtn:GetWide() - MenuUnit(15), MenuUnit(21))
    resetBtn:SetText("")
    resetBtn.Paint = function(self, w, h)
        surface.SetDrawColor(20, 20, 20, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(settings_color_whitey.r, settings_color_whitey.g, settings_color_whitey.b, self:IsHovered() and 210 or 120)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("Reset defaults", "ZCity_Menu_Settings_Tiny", w / 2, h / 2, settings_color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    resetBtn.DoClick = function()
        surface.PlaySound(SOUND_SETTINGS_CLICK)
        KeybindsResetDefaults()
        KeybindsRefreshContent()
    end

    local contentHolder = vgui.Create("DPanel", mainPanel)
    contentHolder:Dock(FILL)
    contentHolder.Paint = function() end
    keybinds_content_panel = contentHolder

    KeybindsRefreshContent()
end

local function InfoCreateSectionButton(pParent, strTitle, sectionKey)
    local sectionData
    for _, data in ipairs(info_sections) do
        if data.key == sectionKey then
            sectionData = data
            break
        end
    end
    local disabled = sectionData and sectionData.disabled or false
    local btn = MMButton(pParent, string.upper(strTitle), function()
        info_active_section = sectionKey
        InfoRefreshContent()
    end, "ZCity_SetMM_Button", true)
    btn:Dock(TOP)
    btn:SetTall(MenuUnit(48))
    btn:DockMargin(MenuUnit(10), MenuUnit(8), MenuUnit(10), 0)
    btn.SectionKey = sectionKey
    btn.SectionDisabled = disabled
    btn.IsActive = function(self) return not self.SectionDisabled and info_active_section == self.SectionKey end
    if disabled then
        btn:SetEnabled(false)
        btn:SetMouseInputEnabled(false)
        btn:SetAlpha(110)
    end
    info_section_buttons[#info_section_buttons + 1] = btn
    return btn
end

function InfoRefreshContent()
    if not IsValid(info_content_panel) then return end
    info_content_panel:Clear()

    local sectionKey = info_active_section or "rank"
    for _, sectionData in ipairs(info_sections) do
        if sectionData.key == sectionKey and sectionData.disabled then
            sectionKey = "rank"
            info_active_section = "rank"
            break
        end
    end

    if IsValid(info_header_label) then
        local currentTitle = "INFORMATION"
        for _, sectionData in ipairs(info_sections) do
            if sectionData.key == info_active_section then
                currentTitle = string.upper(sectionData.title)
                break
            end
        end
        info_header_label:SetText(currentTitle)
    end
    local contentWidth = info_content_panel:GetWide()
    local contentHeight = info_content_panel:GetTall()

    if sectionKey == "rank" then
        InfoRefreshLocalRankData()

        local holder = vgui.Create("DPanel", info_content_panel)
        holder:Dock(FILL)
        holder:DockMargin(MenuUnit(20), MenuUnit(20), MenuUnit(20), MenuUnit(20))
        holder.Paint = function() end

        local card = vgui.Create("DPanel", holder)
        card:Dock(FILL)
        card.Paint = function(self, w, h)
            MMBox(w, h, 0)
        end

        local scroll = vgui.Create("DScrollPanel", card)
        scroll:Dock(FILL)
        scroll:DockMargin(MenuUnit(18), MenuUnit(18), MenuUnit(18), MenuUnit(18))
        scroll.Paint = function() end

        MMScrollbar(scroll)

        local profileBlock = vgui.Create("DPanel", scroll)
        profileBlock:Dock(TOP)
        profileBlock:DockMargin(0, 0, 0, MenuUnit(18))
        profileBlock:SetTall(MenuUnit(370))
        profileBlock.Paint = function() end

        local medalPanel = vgui.Create("DPanel", profileBlock)
        medalPanel:SetSize(MenuUnit(200), MenuUnit(200))
        medalPanel.Band = nil
        medalPanel.Medal = nil
        medalPanel.Paint = function(self, w, h)
            if self.Band and self.Band.icon then
                surface.SetMaterial(self.Band.icon)
                surface.SetDrawColor(255,255,255,255)
                surface.DrawTexturedRect(0, 0, w, h)
            end
            if self.Medal and self.Medal.icon then
                surface.SetMaterial(self.Medal.icon)
                surface.SetDrawColor(255,255,255,255)
                surface.DrawTexturedRect(0, 0, w, h)
            end
        end

        local playerLabel = vgui.Create("DLabel", profileBlock)
        playerLabel:SetFont("ZCity_SetMM_Title")
        playerLabel:SetTextColor(mm_text)
        playerLabel:SetContentAlignment(5)
        playerLabel:SetText("")

        local xpLabel = vgui.Create("DLabel", profileBlock)
        xpLabel:SetFont("ZCity_SetMM_Row")
        xpLabel:SetTextColor(mm_text)
        xpLabel:SetContentAlignment(5)
        xpLabel:SetText("")

        local skillLabel = vgui.Create("DLabel", profileBlock)
        skillLabel:SetFont("ZCity_SetMM_Row")
        skillLabel:SetTextColor(mm_text_dim)
        skillLabel:SetContentAlignment(5)
        skillLabel:SetText("")

        local medalLabel = vgui.Create("DLabel", profileBlock)
        medalLabel:SetFont("ZCity_SetMM_Row")
        medalLabel:SetTextColor(mm_text)
        medalLabel:SetContentAlignment(5)
        medalLabel:SetText("")

        local bandLabel = vgui.Create("DLabel", profileBlock)
        bandLabel:SetFont("ZCity_SetMM_Small")
        bandLabel:SetTextColor(mm_text_dim)
        bandLabel:SetContentAlignment(5)
        bandLabel:SetText("")

        profileBlock.LastSkill = nil
        profileBlock.LastExp = nil
        function profileBlock:Think()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local skill = ply.skill or 0
            local exp = ply.exp or 0
            if skill == (self.LastSkill or 0) and exp == (self.LastExp or 0) then return end
            self.LastSkill = skill
            self.LastExp = exp
            local Band, Medal = zb.Experience.GetAwards({skill = skill, exp = exp})
            if Band then
                medalPanel.Band = Band
                medalPanel.Medal = Medal
            end
            playerLabel:SetText(ply:Nick())
            xpLabel:SetText("Experience: " .. math.Round(exp))
            skillLabel:SetText("Skill: " .. math.Round(skill, 3))
            medalLabel:SetText("Medal: " .. (Medal and Medal.name or "None"))
            bandLabel:SetText("Band: " .. (Band and Band.name or "None"))
        end

        profileBlock.PerformLayout = function(self, w, h)
            local medalSize = math.min(MenuUnit(200), math.max(MenuUnit(130), math.floor(w * 0.28)))
            medalPanel:SetSize(medalSize, medalSize)
            medalPanel:SetPos(math.floor((w - medalSize) * 0.5), 0)

            playerLabel:SetPos(0, medalPanel:GetY() + medalPanel:GetTall() + MenuUnit(14))
            playerLabel:SetSize(w, MenuUnit(38))
            xpLabel:SetPos(0, playerLabel:GetY() + MenuUnit(34))
            xpLabel:SetSize(w, MenuUnit(28))
            skillLabel:SetPos(0, xpLabel:GetY() + MenuUnit(26))
            skillLabel:SetSize(w, MenuUnit(28))
            medalLabel:SetPos(0, skillLabel:GetY() + MenuUnit(34))
            medalLabel:SetSize(w, MenuUnit(26))
            bandLabel:SetPos(0, medalLabel:GetY() + MenuUnit(22))
            bandLabel:SetSize(w, MenuUnit(24))
            self:SetTall(bandLabel:GetY() + bandLabel:GetTall() + MenuUnit(10))
        end

        local statsTitle = vgui.Create("DLabel", scroll)
        statsTitle:Dock(TOP)
        statsTitle:DockMargin(0, 0, 0, MenuUnit(10))
        statsTitle:SetFont("ZCity_SetMM_Row")
        statsTitle:SetTextColor(mm_text)
        statsTitle:SetText("STATISTICS")
        statsTitle:SetTall(MenuUnit(28))

        local statsGrid = vgui.Create("DPanel", scroll)
        statsGrid:Dock(TOP)
        statsGrid:DockMargin(0, 0, 0, MenuUnit(18))
        statsGrid:SetTall(MenuUnit(160))
        statsGrid.Paint = function() end

        local statCards = {}
        for _, statData in ipairs(info_stat_rows) do
            local statPanel = vgui.Create("DPanel", statsGrid)
            statPanel.Paint = function(self, w, h)
                MMBox(w, h, 0)
            end

            local title = vgui.Create("DLabel", statPanel)
            title:SetPos(MenuUnit(12), MenuUnit(10))
            title:SetFont("ZCity_SetMM_Small")
            title:SetTextColor(mm_text_dim)
            title:SetText(string.upper(statData[1]))
            title:SizeToContents()

            local value = vgui.Create("DLabel", statPanel)
            value:SetPos(MenuUnit(12), MenuUnit(30))
            value:SetFont("ZCity_SetMM_Row")
            value:SetTextColor(mm_text)
            value:SetText("0")
            value:SizeToContents()
            value.StatKey = statData[2]
            function value:Think()
                local ply = LocalPlayer()
                if not IsValid(ply) then return end
                local val = ply.SvDB and ply.SvDB[self.StatKey]
                if val == nil then return end
                local str = tostring(math.Round(val))
                if self:GetText() ~= str then
                    self:SetText(str)
                    self:SizeToContents()
                end
            end

            statCards[#statCards + 1] = {
                key = statData[2],
                panel = statPanel,
                value = value
            }
        end

        local kdPanel = vgui.Create("DPanel", statsGrid)
        kdPanel.Paint = function(self, w, h)
            MMBox(w, h, 0)
        end

        local kdTitle = vgui.Create("DLabel", kdPanel)
        kdTitle:SetPos(MenuUnit(12), MenuUnit(10))
        kdTitle:SetFont("ZCity_SetMM_Small")
        kdTitle:SetTextColor(mm_text_dim)
        kdTitle:SetText("K/D")
        kdTitle:SizeToContents()

        local kdValue = vgui.Create("DLabel", kdPanel)
        kdValue:SetPos(MenuUnit(12), MenuUnit(30))
        kdValue:SetFont("ZCity_SetMM_Row")
        kdValue:SetTextColor(mm_text)
        kdValue:SetText("0.00")
        kdValue:SizeToContents()
        function kdValue:Think()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local kills = ply.SvDB and ply.SvDB["Kills"] or 0
            local deaths = ply.SvDB and ply.SvDB["Deaths"] or 0
            local kd = deaths > 0 and math.Round(kills / deaths, 2) or kills
            local str = string.format("%.2f", kd)
            if self:GetText() ~= str then
                self:SetText(str)
                self:SizeToContents()
            end
        end

        statsGrid.PerformLayout = function(self, w, h)
            local gap = MenuUnit(8)
            local columns = w < MenuUnit(520) and 1 or 2
            local cardW = math.floor((w - gap * (columns - 1)) / columns)
            local cardH = MenuUnit(66)
            local allCards = {}
            for _, statCard in ipairs(statCards) do
                allCards[#allCards + 1] = statCard.panel
            end
            allCards[#allCards + 1] = kdPanel

            for i, pnl in ipairs(allCards) do
                local row = math.floor((i - 1) / columns)
                local col = (i - 1) % columns
                pnl:SetPos(col * (cardW + gap), row * (cardH + gap))
                pnl:SetSize(cardW, cardH)
            end

            local rows = math.ceil(#allCards / columns)
            self:SetTall(rows * cardH + math.max(0, rows - 1) * gap)
        end

        local achievementsTitle = vgui.Create("DLabel", scroll)
        achievementsTitle:Dock(TOP)
        achievementsTitle:DockMargin(0, 0, 0, MenuUnit(10))
        achievementsTitle:SetFont("ZCity_SetMM_Row")
        achievementsTitle:SetTextColor(mm_text)
        achievementsTitle:SetText("OBTAINED ACHIEVEMENTS")
        achievementsTitle:SetTall(MenuUnit(28))

        local achievementsHolder = vgui.Create("DPanel", scroll)
        achievementsHolder:Dock(TOP)
        achievementsHolder.Paint = function() end

        local achievementsEmpty = vgui.Create("DLabel", achievementsHolder)
        achievementsEmpty:Dock(TOP)
        achievementsEmpty:SetFont("ZCity_SetMM_Small")
        achievementsEmpty:SetTextColor(mm_text_dim)
        achievementsEmpty:SetContentAlignment(5)
        achievementsEmpty:SetText("NO ACHIEVEMENTS OBTAINED YET")
        achievementsEmpty:SetTall(MenuUnit(28))

        local achievementRows = {}
        local function RefreshAchievements()
            local obtained = InfoGetObtainedAchievements()
            for _, pnl in ipairs(achievementRows) do
                if IsValid(pnl) then
                    pnl:Remove()
                end
            end
            achievementRows = {}

            achievementsEmpty:SetVisible(#obtained == 0)
            achievementsHolder:SetTall(MenuUnit(28))

            if #obtained == 0 then
                return
            end

            local totalHeight = 0
            for _, ach in ipairs(obtained) do
                local row = vgui.Create("DPanel", achievementsHolder)
                row:Dock(TOP)
                row:DockMargin(0, 0, 0, MenuUnit(8))
                row:SetTall(MenuUnit(70))
                local rarityName = ach.rarity and ach.rarity.name or "Uncommon"
                local rarityColor = info_achievement_rarity_colors[rarityName] or info_achievement_rarity_colors.Uncommon
                row.Paint = function(self, w, h)
                    surface.SetDrawColor(rarityColor.r * 0.12, rarityColor.g * 0.12, rarityColor.b * 0.12, 210)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 220)
                    surface.DrawRect(0, 0, MenuUnit(3), h)
                    surface.DrawRect(0, h - MenuUnit(1), w, MenuUnit(1))
                end

                local title = vgui.Create("DLabel", row)
                title:SetPos(MenuUnit(12), MenuUnit(10))
                title:SetFont("ZCity_SetMM_Row")
                title:SetTextColor(rarityColor)
                title:SetText(ach.name or "Achievement")
                title:SizeToContents()

                local desc = vgui.Create("DLabel", row)
                desc:SetPos(MenuUnit(12), MenuUnit(30))
                desc:SetFont("ZCity_SetMM_Small")
                desc:SetTextColor(mm_text_dim)
                desc:SetText(ach.description or "")

                local obtainedAt = vgui.Create("DLabel", row)
                obtainedAt:SetPos(MenuUnit(12), MenuUnit(49))
                obtainedAt:SetFont("ZCity_SetMM_Small")
                obtainedAt:SetTextColor(rarityColor)
                obtainedAt:SetText("Obtained: " .. InfoFormatAchievementDate(ach.obtained_at))
                obtainedAt:SizeToContents()
                row.PerformLayout = function(self, w, h)
                    desc:SetWide(w - MenuUnit(24))
                end

                achievementRows[#achievementRows + 1] = row
                totalHeight = totalHeight + row:GetTall() + MenuUnit(8)
            end

            achievementsHolder:SetTall(totalHeight)
        end

        local statValues = {
            Kills = 0,
            Headshots = 0,
            Deaths = 0,
            Suicides = 0
        }
        local lastExp = -1
        local lastSkill = -1
        local lastAchievementSignature = ""
        card.Think = function()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end

            local band, medal = info_fallback_band, info_fallback_medal
            if ply.GetAwards then
                band, medal = ply:GetAwards()
            end
            band = band or info_fallback_band
            medal = medal or info_fallback_medal
            medalPanel.Band = band
            medalPanel.Medal = medal

            local playerName = ply:GetNWString("PlayerName", "")
            if playerName == "" then
                playerName = ply:Nick()
            end

            local newExp = math.floor(tonumber(ply.exp) or 0)
            local newSkill = math.Round(tonumber(ply.skill) or 0, 3)
            if lastExp ~= newExp or lastSkill ~= newSkill then
                playerLabel:SetText(string.upper(playerName))
                xpLabel:SetText(newExp .. " XP")
                skillLabel:SetText(newSkill .. " Skill")
                medalLabel:SetText("Medal: " .. string.upper((medal and medal.name) or "UNRANKED"))
                bandLabel:SetText("Band: " .. ((band and band.name and band.name ~= "") and string.upper(band.name) or "SOON"))
                lastExp = newExp
                lastSkill = newSkill
                profileBlock:InvalidateLayout(true)
            end

            for _, statData in ipairs(statCards) do
                statValues[statData.key] = InfoGetPlayerStat(ply, statData.key)
                statData.value:SetText(tostring(math.floor(statValues[statData.key] or 0)))
                statData.value:SizeToContents()
            end

            local effectiveDeaths = math.max(statValues.Deaths - statValues.Suicides, 0)
            local kd = statValues.Kills / math.max(effectiveDeaths, 1)
            kdValue:SetText(string.format("%.2f", kd))
            kdValue:SizeToContents()

            local obtained = InfoGetObtainedAchievements()
            local signature = tostring(#obtained)
            for i, ach in ipairs(obtained) do
                signature = signature .. "|" .. tostring(ach.name or i) .. ":" .. tostring(ach.obtained_at or 0) .. ":" .. tostring(ach.rarity and ach.rarity.name or "")
            end
            if signature ~= lastAchievementSignature then
                lastAchievementSignature = signature
                RefreshAchievements()
            end
        end

    elseif sectionKey == "leaderboard" then
        local scroll = vgui.Create("DScrollPanel", info_content_panel)
        scroll:Dock(FILL)
        scroll:DockMargin(MenuUnit(24), MenuUnit(24), MenuUnit(24), MenuUnit(24))
        scroll.Paint = function() end

        MMScrollbar(scroll)

        local title = vgui.Create("DLabel", scroll)
        title:Dock(TOP)
        title:DockMargin(0, 0, 0, MenuUnit(10))
        title:SetFont("ZCity_SetMM_Row")
        title:SetTextColor(mm_text)
        title:SetText("TOP 10 PLAYERS")
        title:SetTall(MenuUnit(30))

        local rows = {}
        local lastRefresh = 0

        local function RebuildRows()
            for _, row in ipairs(rows) do
                if IsValid(row) then row:Remove() end
            end
            rows = {}

            local leaders = hg.Leaderboard.Get(10)
            if #leaders == 0 then
                local empty = vgui.Create("DLabel", scroll)
                empty:Dock(TOP)
                empty:SetTall(MenuUnit(34))
                empty:SetFont("ZCity_SetMM_Small")
                empty:SetTextColor(mm_text_dim)
                empty:SetContentAlignment(5)
                empty:SetText("NO SQL LEADERBOARD DATA")
                rows[#rows + 1] = empty
                return
            end

            for rank, data in ipairs(leaders) do
                local rowRank = rank
                local rowData = data
                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP)
                row:DockMargin(0, 0, 0, MenuUnit(8))
                row:SetTall(MenuUnit(64))
                row.PlayerData = rowData
                row.HoverLerp = 0
                row.Paint = function(self, w, h)
                    self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
                    surface.SetMaterial(info_row_gradient)
                    surface.SetDrawColor(85, 85, 85, 120 + 40 * self.HoverLerp)
                    surface.DrawTexturedRect(0, 0, w, h)
                    surface.SetDrawColor(0, 0, 0, 145)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(255, 255, 255, 30 + 55 * self.HoverLerp)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    surface.SetDrawColor(settings_color_whitey.r, settings_color_whitey.g, settings_color_whitey.b, rowRank <= 3 and 185 or 95)
                    surface.DrawRect(0, 0, MenuUnit(2), h)
                    draw.SimpleText("#" .. rowRank, "ZCity_SetMM_Row", MenuUnit(15), h / 2, settings_color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.PlayerData.name, "ZCity_SetMM_Row", MenuUnit(96), MenuUnit(22), settings_color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(string.format("K/D %.2f", self.PlayerData.kd), "ZCity_SetMM_Small", MenuUnit(96), MenuUnit(43), settings_color_text_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText("XP " .. self.PlayerData.xp, "ZCity_SetMM_Small", w - MenuUnit(54), MenuUnit(22), settings_color_text_dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    draw.SimpleText("K " .. math.floor(self.PlayerData.kills) .. "  D " .. math.floor(self.PlayerData.deaths), "ZCity_SetMM_Small", w - MenuUnit(18), MenuUnit(43), settings_color_text_dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end

                local avatar = vgui.Create("AvatarImage", row)
                avatar:SetSize(MenuUnit(38), MenuUnit(38))
                avatar:SetPos(MenuUnit(42), MenuUnit(13))
                avatar:SetMouseInputEnabled(false)
                avatar:SetSteamID(rowData.steamid, 64)
                avatar.PaintOver = function(self, w, h)
                    surface.SetDrawColor(255, 255, 255, 45)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end

                local medal = vgui.Create("DPanel", row)
                medal:SetSize(MenuUnit(28), MenuUnit(28))
                row.PerformLayout = function(self, w, h)
                    medal:SetPos(w - MenuUnit(48), MenuUnit(8))
                end
                medal.Paint = function(self, w, h)
                    local band, med = hg.Leaderboard.GetAwards(rowData)
                    band = band or info_fallback_band
                    med = med or info_fallback_medal
                    if band and band.icon then
                        surface.SetMaterial(band.icon)
                        surface.SetDrawColor(255, 255, 255, 220)
                        surface.DrawTexturedRect(0, 0, w, h)
                    end
                    if med and med.icon then
                        surface.SetMaterial(med.icon)
                        surface.SetDrawColor(255, 255, 255, 240)
                        surface.DrawTexturedRect(0, 0, w, h)
                    end
                end

                rows[#rows + 1] = row
            end
        end

        scroll.Think = function()
            if lastRefresh > CurTime() then return end
            lastRefresh = CurTime() + 2
            RebuildRows()
        end
        RebuildRows()

    elseif sectionKey == "credits" then
        local logoPanel = vgui.Create("DPanel", info_content_panel)
        logoPanel:Dock(TOP)
        logoPanel:SetTall(MenuUnit(140))
        logoPanel:DockMargin(MenuUnit(24), MenuUnit(24), MenuUnit(24), 0)
        logoPanel.Paint = function(this, w, h)
            local aspect = math.max(1, logoistMat:Height()) / math.max(1, logoistMat:Width())
            local drawW = math.min(MenuUnit(360), w)
            local drawH = drawW * aspect
            local drawX = (w - drawW) * 0.5
            local drawY = (h - drawH) * 0.5
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(logoistMat)
            surface.DrawTexturedRect(drawX, drawY, drawW, drawH)
        end

        local scroll = vgui.Create("DScrollPanel", info_content_panel)
        scroll:Dock(FILL)
        scroll:DockMargin(MenuUnit(24), MenuUnit(24), MenuUnit(24), MenuUnit(24))
        scroll.Paint = function() end

        MMScrollbar(scroll)

        for _, entry in ipairs(info_credit_entries) do
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, MenuUnit(10))
            row:SetTall(MenuUnit(64))

            local avatarSize = MenuUnit(48)
            local avatarX = MenuUnit(8)
            local avatarY = (MenuUnit(64) - avatarSize) * 0.5
            local av = nil
            local avatarMat = nil

            if entry.img then
                for _, ext in ipairs({".jpg", ".png"}) do
                    local matPath = entry.img .. ext
                    if file.Exists("materials/" .. matPath, "GAME") then
                        avatarMat = Material(matPath, "noclamp smooth")
                        break
                    end
                end
            end

            if not avatarMat and entry.steamid and tostring(entry.steamid) != "0" then
                local sid64 = util.SteamIDTo64(entry.steamid) or entry.steamid
                av = vgui.Create("AvatarImage", row)
                av:SetSteamID(sid64, 64)
                av:SetPaintedManually(true)
                av:SetSize(avatarSize, avatarSize)
            end

            row.Paint = function(self, w, h)
                MMBox(w, h, 0)

                if avatarMat then
                    render.SetStencilEnable(true)
                    render.ClearStencil()
                    render.SetStencilWriteMask(1)
                    render.SetStencilTestMask(1)
                    render.SetStencilReferenceValue(1)
                    render.SetStencilCompareFunction(STENCIL_ALWAYS)
                    render.SetStencilPassOperation(STENCIL_REPLACE)
                    draw.NoTexture()
                    surface.SetDrawColor(255, 255, 255, 255)
                    draw.Circle(avatarX + avatarSize * 0.5, avatarY + avatarSize * 0.5, avatarSize * 0.5, 32)
                    render.SetStencilCompareFunction(STENCIL_EQUAL)
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.SetMaterial(avatarMat)
                    surface.DrawTexturedRect(avatarX, avatarY, avatarSize, avatarSize)
                    render.SetStencilEnable(false)
                elseif IsValid(av) then
                    render.SetStencilEnable(true)
                    render.ClearStencil()
                    render.SetStencilWriteMask(1)
                    render.SetStencilTestMask(1)
                    render.SetStencilReferenceValue(1)
                    render.SetStencilCompareFunction(STENCIL_ALWAYS)
                    render.SetStencilPassOperation(STENCIL_REPLACE)
                    draw.NoTexture()
                    surface.SetDrawColor(255, 255, 255, 255)
                    draw.Circle(avatarX + avatarSize * 0.5, avatarY + avatarSize * 0.5, avatarSize * 0.5, 32)
                    render.SetStencilCompareFunction(STENCIL_EQUAL)
                    av:PaintManual(avatarX, avatarY)
                    render.SetStencilEnable(false)
                else
                    draw.RoundedBox(avatarSize * 0.5, avatarX, avatarY, avatarSize, avatarSize, Color(40, 40, 50, 160))
                end
            end

            local textX = avatarX + avatarSize + MenuUnit(14)

            local name = vgui.Create("DLabel", row)
            name:SetPos(textX, MenuUnit(18))
            name:SetFont("ZCity_SetMM_Row")
            name:SetTextColor(mm_text)
            name:SetText(entry.name or "")
            name:SizeToContents()

            local merit = vgui.Create("DLabel", row)
            merit:SetPos(textX, MenuUnit(40))
            merit:SetFont("ZCity_SetMM_Small")
            merit:SetTextColor(mm_text_dim)
            merit:SetText(entry.merit or "")
            merit:SizeToContents()

            if entry.url then
                local linkButton = vgui.Create("DButton", row)
                linkButton:SetText("")
                linkButton:SetCursor("hand")
                linkButton:SetPos(textX, MenuUnit(40))
                linkButton:SetSize(merit:GetWide(), merit:GetTall())
                linkButton.Paint = function(self, w, h)
                    if not self:IsHovered() then return end

                    surface.SetFont("ZCity_SetMM_Small")
                    surface.SetTextColor(mm_text)
                    surface.SetTextPos(0, 0)
                    surface.DrawText(entry.merit or "")
                    surface.SetDrawColor(settings_color_text)
                    surface.DrawRect(0, h - 1, w, 1)
                end
                linkButton.DoClick = function()
                    gui.OpenURL(entry.url)
                end
            end
        end
    end
end

function hg.DrawInformation(ParentPanel)
    settings_sw, settings_sh = ScrW(), ScrH()

    ParentPanel:SetAlpha(0)
    -- the main menu's blurred black & white backdrop shows through, just a touch darker
    ParentPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 70)
        surface.DrawRect(0, 0, w, h)
    end
    ParentPanel:AlphaTo(255, 0.15, 0)

    info_section_buttons = {}

    if not info_active_section then
        info_active_section = info_sections[1] and info_sections[1].key or "rank"
    end

    local shell = MMBuildPage(ParentPanel, "INFORMATION", "SECTIONS", "View rank and credits")
    for _, sectionData in ipairs(info_sections) do
        InfoCreateSectionButton(shell.sidebar, sectionData.title, sectionData.key)
    end
    shell.title:SetText("RANK")
    info_header_label = shell.title
    info_content_panel = shell.content

    InfoRefreshContent()
end
