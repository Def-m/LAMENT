if not hg then return end

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end

local TRAITOR_MENU_FONT = "ZCity_Traitor_Loadout"
local TRAITOR_POINTS_FONT = "ZCity_Traitor_Points"
local ARENA_META_FONT = "ZCity_Arena_Meta"
local ARENA_DESC_FONT = "ZCity_Arena_Description"
local TRAITOR_PRESET_BUTTON_HEIGHT = 34
local TRAITOR_LIST_BUTTON_HEIGHT = 38
local TRAITOR_ADDON_BUTTON_HEIGHT = 32
local TRAITOR_BUTTON_SPACING = 4
local TRAITOR_LIST_WIDTH = 0.6
local TRAITOR_HEADER_HEIGHT = 70
local TRAITOR_LIST_SLIDE_SPEED = 10
local TRAITOR_PREVIEW_SLIDE_SPEED = 10
local TRAITOR_CONTENT_FADE_SPEED = 12
local TRAITOR_LIST_START_OFFSET = 80
local TRAITOR_PREVIEW_START_OFFSET = 80

local function CreateTraitorMenuFonts()
    surface.CreateFont(TRAITOR_MENU_FONT, {
        font = "IBM Plex Mono",
        size = ScreenScale(10),
        weight = 400,
        antialias = true
    })

    surface.CreateFont(TRAITOR_POINTS_FONT, {
        font = "IBM Plex Mono",
        size = ScreenScale(12),
        weight = 400,
        antialias = true
    })

	surface.CreateFont(ARENA_META_FONT, {
		font = "IBM Plex Mono",
		size = ScreenScale(7),
		weight = 400,
		antialias = true
	})

	surface.CreateFont(ARENA_DESC_FONT, {
		font = "IBM Plex Mono",
		size = ScreenScale(5),
		weight = 400,
		antialias = true
	})

	local scale = math.min(ScrW(), ScrH()) / 1000
	surface.CreateFont("ZCity_Loadout_Title", { font = "IBM Plex Mono", size = math.max(16, math.floor(32 * scale)), weight = 400, antialias = true })
	surface.CreateFont("ZCity_Loadout_CardTitle", { font = "IBM Plex Mono", size = math.max(20, math.floor(46 * scale)), weight = 500, antialias = true })
	surface.CreateFont("ZCity_Loadout_Small", { font = "IBM Plex Mono", size = math.max(13, math.floor(19 * scale)), weight = 400, antialias = true })
	surface.CreateFont("ZCity_Loadout_Tiny", { font = "IBM Plex Mono", size = math.max(12, math.floor(16 * scale)), weight = 400, antialias = true })
end

hook.Add("OnScreenSizeChanged", "ZCity_TraitorLoadout_Fonts", CreateTraitorMenuFonts)
CreateTraitorMenuFonts()

local LOADOUT_STYLE = {
    background = Color(8, 8, 8, 255),
    topBar = Color(24, 24, 24, 210),
    panel = Color(28, 28, 28, 180),
    panelActive = Color(48, 48, 48, 220),
    panelHover = Color(60, 60, 60, 235),
    border = Color(180, 180, 180, 90),
    borderDim = Color(180, 180, 180, 45),
    accent = Color(225, 225, 225, 255),
    text = Color(220, 220, 220, 255),
    dim = Color(140, 140, 140, 255),
    scrollbar = Color(25, 25, 25, 200),
    scrollbarGrip = Color(80, 80, 80, 255),
    scrollbarGripHover = Color(120, 120, 120, 255)
}

local color_whitey = Color(240, 240, 240, 255)
local clr_verygray = LOADOUT_STYLE.background
local menu_gradient_right = Color(80, 80, 80, 15)
local clr_1 = Color(100, 100, 100, 40)

local tex_gradient_r = Material("vgui/gradient-r")
local tex_gradient_l = Material("vgui/gradient-l")
local tex_gradient_d = Material("vgui/gradient-d")

-- same backdrop as the main menu / appearance editor
local function LoadoutBackdrop(self, w, h)
	if hg.PaintMenuBackground then
		hg.PaintMenuBackground(w, h, 1)
		return
	end
	draw.RoundedBox(0, 0, 0, w, h, clr_verygray)
	surface.SetDrawColor(menu_gradient_right)
	surface.SetMaterial(tex_gradient_r)
	surface.DrawTexturedRect(0, 0, w, h)
	surface.SetDrawColor(clr_1)
	surface.SetMaterial(tex_gradient_d)
	surface.DrawTexturedRect(0, 0, w, h)
end

-- header strip like the round stats / settings pages
local function LoadoutHeader(parent, title, hint)
	local header = vgui.Create("DPanel", parent)
	header:SetPos(0, 0)
	header:SetSize(ScrW(), MenuUnit(64))
	header.OpenTime = CurTime()
	header.Paint = function(self, w, h)
		surface.SetDrawColor(LOADOUT_STYLE.panel)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(LOADOUT_STYLE.border.r, LOADOUT_STYLE.border.g, LOADOUT_STYLE.border.b, 50)
		surface.DrawRect(0, h - 1, w, 1)
		local chars = math.min(#title, math.floor((CurTime() - self.OpenTime) * 18))
		draw.SimpleText(title:sub(1, chars) .. string.rep("#", #title - chars), "ZCity_Loadout_Title", MenuUnit(25), h / 2, color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		if hint then
			draw.SimpleText(hint, "ZCity_Loadout_Tiny", w - MenuUnit(25), h / 2, LOADOUT_STYLE.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end
	return header
end

-- appearance-editor style button
local function LoadoutButton(parent, label, onClick)
	local btn = vgui.Create("DButton", parent)
	btn:SetText("")
	btn.HoverLerp = 0
	btn.Think = function(self)
		self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
	end
	btn.Paint = function(self, w, h)
		local hov = self:IsHovered()
		local hl = self.HoverLerp or 0
		draw.RoundedBox(3, 0, 0, w, h, hov and Color(48, 48, 48, 235) or Color(31, 31, 31, 205))
		surface.SetDrawColor(LOADOUT_STYLE.border.r, LOADOUT_STYLE.border.g, LOADOUT_STYLE.border.b, 45 + 100 * hl)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		if hl > 0.01 then
			surface.SetDrawColor(LOADOUT_STYLE.accent.r, LOADOUT_STYLE.accent.g, LOADOUT_STYLE.accent.b, 210 * hl)
			surface.DrawRect(0, 0, MenuUnit(3), h)
		end
		draw.SimpleText(label, "ZCity_Loadout_Tiny", w / 2, h / 2, hov and LOADOUT_STYLE.text or Color(188, 188, 188), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btn.DoClick = function()
		surface.PlaySound("ui/rem_click.wav")
		onClick()
	end
	return btn
end

-- footer strip with a return button
local function LoadoutFooter(parent, label, onClick)
	local footer = vgui.Create("DPanel", parent)
	local fh = MenuUnit(56)
	footer:SetPos(0, ScrH() - fh)
	footer:SetSize(ScrW(), fh)
	footer.Paint = function(self, w, h)
		surface.SetDrawColor(LOADOUT_STYLE.panel)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(LOADOUT_STYLE.border.r, LOADOUT_STYLE.border.g, LOADOUT_STYLE.border.b, 50)
		surface.DrawRect(0, 0, w, 1)
	end
	local btn = LoadoutButton(footer, label, onClick)
	local pad = MenuUnit(10)
	btn:SetPos(pad, pad)
	btn:SetSize(MenuUnit(200), fh - pad * 2)
	return footer
end

-- card used on the mode / role pickers
local function PaintLoadoutCard(self, w, h, title, points, desc, accent)
	local hl = self.HoveredLerp or 0
	local hov = self:IsHovered()
	surface.SetDrawColor(hov and LOADOUT_STYLE.panelActive or LOADOUT_STYLE.panel)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(LOADOUT_STYLE.border.r, LOADOUT_STYLE.border.g, LOADOUT_STYLE.border.b, 50 + 95 * hl)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
	local ac = accent or LOADOUT_STYLE.accent
	surface.SetDrawColor(ac.r, ac.g, ac.b, accent and (140 + 100 * hl) or (210 * hl))
	surface.DrawRect(0, 0, MenuUnit(3), h)

	draw.SimpleText(title, "ZCity_Loadout_CardTitle", w * 0.5, h * 0.42, color_whitey, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	surface.SetFont("ZCity_Loadout_CardTitle")
	local tw = surface.GetTextSize(title)
	surface.SetDrawColor(255, 255, 255, 24)
	surface.DrawLine(w * 0.5 - tw * 0.5, h * 0.5, w * 0.5 + tw * 0.5, h * 0.5)
	draw.SimpleText(string.upper(points), "ZCity_Loadout_Small", w * 0.5, h * 0.56, LOADOUT_STYLE.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(desc, "ZCity_Loadout_Tiny", w * 0.5, h * 0.63, LOADOUT_STYLE.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local SOUND_TYPEWRITER = "shitty/tap-resonant.wav"
local SOUND_TYPEWRITER_LEVEL = 55
local SOUND_TYPEWRITER_VOLUME = 0.25
local SOUND_TYPEWRITER_PITCH = 102
local SOUND_SETTINGS_CLICK = "ui/rem_click.wav"
local SOUND_MENU_SELECT = "ui/rem_select.wav"

local function PlayTypewriterSound()
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:EmitSound(SOUND_TYPEWRITER, SOUND_TYPEWRITER_LEVEL, SOUND_TYPEWRITER_PITCH, SOUND_TYPEWRITER_VOLUME)
        return
    end
    surface.PlaySound(SOUND_TYPEWRITER)
end

local function SetupAnimatedLabel(lbl, text, delay, charSpeed)
    lbl:SetText(string.rep("#", #text))
    lbl:SetMouseInputEnabled(true)
    lbl:SizeToContents()
    lbl.OpenTime = CurTime() + (delay or 0)
    lbl.HoverLerp = 0
    lbl.LineLerp = 0
    lbl.HoverScale = 0.008
    lbl.LabelText = text
    lbl.CharSpeed = charSpeed or 15
end

local function ThinkAnimatedLabel(self)
    local isHovered = self:IsHovered()
    self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, isHovered and 1 or 0)
    self.LineLerp = LerpFT(0.2, self.LineLerp or 0, isHovered and 1 or 0)

    local elapsed = CurTime() - (self.OpenTime or CurTime())
    local charsToShow = math.floor(math.max(elapsed, 0) * (self.CharSpeed or 15))
    local target = self.LabelText or ""
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
        if i <= charsToShow then
            ntxt = ntxt .. target:sub(i, i)
        else
            ntxt = ntxt .. "#"
        end
    end

    if self:GetText() ~= ntxt then
        self:SetText(ntxt)
        self:SizeToContents()
    end
end

local function PaintAnimatedLabel(self, w, h)
    local isHovered = self:IsHovered()
    local flash = isHovered and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
    local textColor = color_whitey
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

CreateClientConVar("hmcd_traitor_loadout", "", true, true, "Saved traitor loadout")
CreateClientConVar("hmcd_soe_traitor_loadout", "", true, true, "Saved SOE traitor loadout")
CreateClientConVar("hmcd_improvision_traitor_loadout", "", true, true, "Saved Improvision traitor loadout")
CreateClientConVar("hmcd_hero_loadout", "", true, true, "Saved hero loadout")
CreateClientConVar("hmcd_soe_hero_loadout", "", true, true, "Saved SOE hero loadout")
CreateClientConVar("zcity_arena_loadout", "", true, true, "Saved Arena loadout")

function SkillsetBlocksGun(config, skillset, id)
	local sk = config.skillsets and config.skillsets[skillset]
	if not sk or not sk.meleeOnly then return false end
	local w = weapons.GetStored(id)
	if w and w.Category and w.Category:StartWith("Weapons -") and w.Category ~= "Weapons - Melee" then
		return true
	end
	return false
end

local RoleConfigs = {
    traitor = {
        title = "EXECUTIONER",
        buttonTitle = "Executioner",
        maxPoints = 30,
        convar = "hmcd_traitor_loadout",
        saveFile = "zcity_traitor_loadout.txt",
        presetFile = "zcity_traitor_presets.txt",
        skillsets = {
            ["none"] = {cost = 0, name = "None", desc = "You spent time collecting supplies and weapons instead of building a real specialty."},
            ["infiltrator"] = {cost = 15, name = "Infiltrator", desc = "Break necks and disguise as victims."},
            ["assassin"] = {cost = 15, name = "Assassin", desc = "Better gun control and more endurance."},
            ["damned"] = {cost = 30, name = "Damned", desc = "You start with nothing."},
            ["chemist"] = {cost = 10, name = "Chemist", desc = "Detect chemicals in the air."},
            ["martialartist"] = {cost = 30, name = "Martial Artist", desc = "High stamina. Armed with nunchucks. Uses WWE-style moves via the radial menu."},
            ["brawler"] = {cost = 30, name = "Brawler", desc = "Devastating 1.85x melee. Can choke or execute victims with melee weapons, but no firearms and fragile from behind.", meleeOnly = true}
        },
        items = {
            ["weapon_p22"] = {cost = 6, name = "Walther P22"},
            ["weapon_pb"] = {cost = 8, name = "PB"},
            ["weapon_usp"] = {cost = 5, name = "HK USP", desc = "Pistol chambered in 9x19 mm."},
            ["weapon_taser"] = {cost = 6, name = "Taser"},
            ["weapon_6x5"] = {cost = 2, name = "6x5 Bayonet"},
            ["weapon_buck200knife"] = {cost = 2, name = "Buck 120 General"},
            ["weapon_hg_ritual"] = {cost = 5, name = "Ritual Knife"},
            ["weapon_hg_akula"] = {cost = 2, name = "Akula Dagger"},
            ["weapon_hg_wire"] = {cost = 3, name = "Fiber Wire"},
            ["weapon_hg_eft_rgd5"] = {cost = 4, name = "RGD-5 Grenade"},
            ["weapon_adrenaline"] = {cost = 3, name = "Epipen"},
            ["weapon_hg_shuriken"] = {cost = 1, name = "Shuriken"},
            ["weapon_hg_smokenade_tpik"] = {cost = 2, name = "Smoke Grenade"},
            ["weapon_traitor_ied"] = {cost = 5, name = "IED"},
            ["weapon_traitor_poison1"] = {cost = 2, name = "Tetrodotoxin Syringe"},
            ["weapon_traitor_poison2"] = {cost = 2, name = "VX vial"},
            ["weapon_traitor_poison3"] = {cost = 4, name = "Cyanide Canister"},
            ["weapon_traitor_poison4"] = {cost = 2, name = "Curare vial"},
            ["weapon_traitor_poison_consumable"] = {cost = 3, name = "Potassium Cyanide Powder"},
            ["weapon_traitor_suit"] = {cost = 1, name = "Executioner Suit"},
            ["weapon_hg_jam"] = {cost = 1, name = "Door Jam"},
            ["weapon_walkie_talkie"] = {cost = 1, name = "Walkie-Talkie"}
        },
        addons = {
            ["weapon_p22_silencer"] = {cost = 2, name = "Silencer", parent = "weapon_p22", attachment = "supressor1", attachmentGroup = "suppressor"},
            ["weapon_usp_silencer"] = {cost = 2, name = "Silencer", parent = "weapon_usp", attachment = "supressor2", attachmentGroup = "suppressor"},
            ["weapon_usp_rmr"] = {cost = 2, name = "RMR", parent = "weapon_usp", attachment = "holo16", attachmentGroup = "optic"},
            ["weapon_usp_laser"] = {cost = 1, name = "Laser", parent = "weapon_usp", attachment = "laser3", attachmentGroup = "laser"},
            ["weapon_taser_ammo"] = {cost = 2, name = "Extra Ammo", parent = "weapon_taser", desc = "Start with an extra magazine."},
            ["weapon_p22_ammo"] = {cost = 2, name = "Extra Ammo", parent = "weapon_p22", desc = "Start with an extra magazine."},
            ["weapon_pb_ammo"] = {cost = 4, name = "Extra Ammo", parent = "weapon_pb", desc = "Start with an extra magazine."},
        },
        addonOrder = {
            ["weapon_p22"] = {"weapon_p22_silencer", "weapon_p22_ammo"},
            ["weapon_pb"] = {"weapon_pb_ammo"},
            ["weapon_usp"] = {"weapon_usp_silencer", "weapon_usp_rmr", "weapon_usp_laser"}
        },
        exclusions = {
            ["weapon_6x5"] = {["weapon_buck200knife"] = true, ["weapon_hg_ritual"] = true, ["weapon_hg_akula"] = true},
            ["weapon_buck200knife"] = {["weapon_6x5"] = true, ["weapon_hg_ritual"] = true, ["weapon_hg_akula"] = true},
            ["weapon_hg_ritual"] = {["weapon_buck200knife"] = true, ["weapon_6x5"] = true, ["weapon_hg_akula"] = true},
            ["weapon_hg_akula"] = {["weapon_buck200knife"] = true, ["weapon_6x5"] = true, ["weapon_hg_ritual"] = true},
        },
        defaultPresets = {
            {
                name = "Legacy",
                loadout = {
                    skillset = "none",
                    weapons = {
                        "weapon_p22",
                        "weapon_p22_silencer",
                        "weapon_6x5",
                        "weapon_hg_eft_rgd5",
                        "weapon_adrenaline",
                        "weapon_hg_shuriken",
                        "weapon_hg_smokenade_tpik",
                        "weapon_traitor_ied",
                        "weapon_traitor_poison1",
                        "weapon_traitor_suit",
                        "weapon_hg_jam",
                        "weapon_walkie_talkie"
                    }
                }
            },
            {
                name = "Infiltrator",
                loadout = {
                    skillset = "infiltrator",
                    weapons = {
                        "weapon_buck200knife",
                        "weapon_adrenaline",
                        "weapon_hg_smokenade_tpik"
                    }
                }
            },
            {
                name = "Assassin",
                loadout = {
                    skillset = "assassin",
                    weapons = {
                        "weapon_p22",
                        "weapon_p22_silencer",
                        "weapon_6x5",
                        "weapon_adrenaline"
                    }
                }
            },
            {
                name = "Chemist",
                loadout = {
                    skillset = "chemist",
                    weapons = {
                        "weapon_buck200knife",
                        "weapon_adrenaline",
                        "weapon_traitor_poison1",
                        "weapon_traitor_poison2",
                        "weapon_traitor_poison3",
                        "weapon_traitor_poison4",
                        "weapon_traitor_poison_consumable"
                    }
                }
            }
        }
    },
	traitor_improvision = {
		title = "IMPROVISION EXECUTIONER",
		buttonTitle = "Improvision Executioner",
		maxPoints = 30,
		convar = "hmcd_improvision_traitor_loadout",
		saveFile = "zcity_improvision_traitor_loadout.txt",
		presetFile = "zcity_improvision_traitor_presets.txt",
		addonOrder = {},
		items = {
			["weapon_hg_crossbow"] = {cost = 8, name = "Homemade Crossbow", desc = "The high-lethality exception."},
            ["weapon_hg_bow"] = {cost = 5, name = "Hunting Bow", desc = "A bow that can be used to hunt."},
			["weapon_zoraki"] = {cost = 3, name = "Zoraki Stalker M906"},
			["weapon_mp-80"] = {cost = 3, name = "MP-80-13T"},
			["weapon_tranquilizer"] = {cost = 6, name = "Tranquilizer Gun"}
		},
		addons = {},
		exclusions = {
			["weapon_hg_crossbow"] = {["weapon_zoraki"] = true, ["weapon_mp-80"] = true, ["weapon_tranquilizer"] = true},
			["weapon_hg_bow"] = {["weapon_zoraki"] = true, ["weapon_mp-80"] = true, ["weapon_tranquilizer"] = true},
			["weapon_zoraki"] = {["weapon_hg_crossbow"] = true, ["weapon_hg_bow"] = true, ["weapon_mp-80"] = true, ["weapon_tranquilizer"] = true},
			["weapon_mp-80"] = {["weapon_hg_crossbow"] = true, ["weapon_hg_bow"] = true, ["weapon_zoraki"] = true, ["weapon_tranquilizer"] = true},
			["weapon_tranquilizer"] = {["weapon_hg_crossbow"] = true, ["weapon_hg_bow"] = true, ["weapon_zoraki"] = true, ["weapon_mp-80"] = true}
		},
		defaultPresets = {
			{
				name = "Tranquilizer",
				loadout = {weapons = {"weapon_tranquilizer"}}
			}
		},
		defaultLoadout = {weapons = {"weapon_tranquilizer"}}
	},
    hero = {
        title = "JUDGE",
        buttonTitle = "Judge",
        maxPoints = 16,
        convar = "hmcd_hero_loadout",
        saveFile = "zcity_hero_loadout.txt",
        presetFile = "zcity_hero_presets.txt",
        items = {
            ["weapon_px4beretta"] = {cost = 4, name = "Beretta PX4", desc = "Reliable sidearm with room for extra ammo."},
            ["weapon_chiappa_rhino"] = {cost = 7, name = "Chiappa Rhino", desc = "Reliable sidearm with room for extra ammo."},
            ["weapon_glock17"] = {cost = 5, name = "Glock 17", desc = "Flexible pistol with strong attachment options."},
            ["weapon_m9beretta"] = {cost = 5, name = "Beretta M9", desc = "Reliable 9mm service pistol."},
            ["weapon_fn45"] = {cost = 5, name = "FNX-45", desc = "Polymer-framed .45 ACP pistol."},
            ["weapon_m1911"] = {cost = 4, name = "Colt M1911", desc = "Classic .45 ACP pistol."},
            ["weapon_m590a1"] = {cost = 10, name = "M590A1", desc = "Close range stopper with extra shell support."},
            ["weapon_kar98"] = {cost = 8, name = "Karabiner 98k", desc = "Heavy marksman pick that can take a scope and extra rounds."},
            ["weapon_vpo136"] = {cost = 10, name = "VPO-136", desc = "Reliable 7.62x39 carbine with a fixed 10-round magazine."},
            ["weapon_bandage_sh"] = {cost = 2, name = "Bandage"},
            ["weapon_medkit_sh"] = {cost = 6, name = "Medkit"},
            ["weapon_painkillers_tpik"] = {cost = 2, name = "Painkillers"},
            ["ent_armor_vest3"] = {cost = 4, name = "UNTAR Body Armor II", icon = "entities/ent_jack_gmod_ezarmor_untar.png", desc = "Body armor that soaks torso hits."},
            ["ent_armor_helmet3"] = {cost = 2, name = "Untar Helmet I", icon = "entities/ent_jack_gmod_ezarmor_untarhelm.png", desc = "Ballistic helmet that protects the head."},
            ["ent_armor_helmet6"] = {cost = 2, name = "SSh-68 Helmet I", icon = "entities/ent_jack_gmod_ezarmor_ssh68.png", desc = "Steel helmet that protects the head."},
            ["ent_armor_mask1"] = {cost = 2, name = "Ballistic Mask", icon = "entities/ent_jack_gmod_ezarmor_ballisticmask.png", desc = "Face armor that shields against hits."},
            ["ent_armor_mask2"] = {cost = 2, name = "M40 Gas Mask", icon = "vgui/icons/gasmask", desc = "Face mask offering light protection."},
            ["weapon_mr43"] = {cost = 8, name = "MR-43 Long Barrel", desc = "Long barrel pump-action shotgun."},
            ["weapon_mr43_short"] = {cost = 7, name = "MR-43 Sawed-Off", desc = "Compact sawed-off pump-action shotgun."},
            ["weapon_mp18"] = {cost = 6, name = "MP-18", desc = "Bolt-action rifle chambered in 7.62x54mm."},
            ["weapon_handcuffs"] = {cost = 1, name = "Handcuffs", desc = "Restrains a target."},
            ["weapon_handcuffs_key"] = {cost = 0, name = "Handcuff Key", desc = "Unlocks handcuffs."}
        },
        addons = {
            ["hero_px4_ammo"] = {cost = 2, name = "Extra Ammo", parent = "weapon_px4beretta", desc = "Start with extra magazine."},
            ["hero_glock_silencer"] = {cost = 2, name = "Suppressor", parent = "weapon_glock17", attachment = "supressor2", desc = "Suppress the Glock 17."},
            ["hero_glock_rmr"] = {cost = 2, name = "RMR", parent = "weapon_glock17", attachment = "holo16", desc = "Adds a compact red dot."},
            ["hero_glock_laser"] = {cost = 1, name = "Laser", parent = "weapon_glock17", attachment = "laser3", desc = "Adds a visible aiming laser."},
            ["hero_glock_ammo"] = {cost = 2, name = "Extra Ammo", parent = "weapon_glock17", desc = "Start with extra magazine."},
            ["hero_m590a1_ammo"] = {cost = 2, name = "Extra Shells", parent = "weapon_m590a1", desc = "Start with extra shells."},
            ["hero_kar98_scope"] = {cost = 2, name = "Scope", parent = "weapon_kar98", attachment = "optic12", desc = "Adds the Kar98 scope."},
            ["hero_kar98_ammo"] = {cost = 2, name = "Extra Ammo", parent = "weapon_kar98", desc = "Start with extra rifle rounds."},
            ["hero_mr43_long_ammo"] = {cost = 2, name = "Extra Shells", parent = "weapon_mr43", desc = "Start with extra shells."},
            ["hero_mr43_ammo"] = {cost = 2, name = "Extra Shells", parent = "weapon_mr43_short", desc = "Start with extra shells."},
            ["hero_mp18_ammo"] = {cost = 2, name = "Extra Ammo", parent = "weapon_mp18", desc = "Start with extra rounds."},
            ["hero_chiappa_ammo"] = {cost = 2, name = "Extra Ammo", parent = "weapon_chiappa_rhino", desc = "Start with extra revolver rounds."}
        },
        addonOrder = {
            ["weapon_px4beretta"] = {"hero_px4_ammo"},
            ["weapon_glock17"] = {"hero_glock_silencer", "hero_glock_rmr", "hero_glock_laser", "hero_glock_ammo"},
            ["weapon_m590a1"] = {"hero_m590a1_ammo"},
            ["weapon_mr43"] = {"hero_mr43_long_ammo"},
            ["weapon_mr43_short"] = {"hero_mr43_ammo"},
            ["weapon_kar98"] = {"hero_kar98_scope", "hero_kar98_ammo"},
            ["weapon_mp18"] = {"hero_mp18_ammo"},
            ["weapon_chiappa_rhino"] = {"hero_chiappa_ammo"},
        },
        exclusions = {},
        defaultPresets = {
            {
                name = "Street Cop",
                loadout = {
                    weapons = {
                        "weapon_glock17",
                        "hero_glock_rmr",
                        "hero_glock_laser",
                        "hero_glock_ammo"
                    }
                }
            },
            {
                name = "Shotgunner",
                loadout = {
                    weapons = {
                        "weapon_m590a1",
                        "hero_m590a1_ammo",
                        "weapon_walkie_talkie"
                    }
                }
            },
            {
                name = "Hunter",
                loadout = {
                    weapons = {
                        "weapon_kar98",
                        "hero_kar98_scope",
                        "hero_kar98_ammo"
                    }
                }
            }
        }
    }
}

RoleConfigs.hero.items["weapon_walkie_talkie"] = {cost = 1, name = "Walkie-Talkie", desc = "Coordinate with the rest of the round."}

RoleConfigs.traitor_improvision.skillsets = table.Copy(RoleConfigs.traitor.skillsets)
for _, itemId in ipairs({
    "weapon_traitor_poison1",
    "weapon_adrenaline",
    "weapon_walkie_talkie",
    "weapon_hg_jam",
    "weapon_traitor_poison_consumable"
}) do
    RoleConfigs.traitor_improvision.items[itemId] = table.Copy(RoleConfigs.traitor.items[itemId])
end

local function AddTraitorAmmoUpgrade(config, weaponId, addonId, cost, desc)
    if not config.items[weaponId] then return end

    config.addons[addonId] = {
        cost = cost,
        name = "Extra Ammo",
        parent = weaponId,
        desc = desc or "Start with an extra magazine."
    }
    config.addonOrder[weaponId] = config.addonOrder[weaponId] or {}
    table.insert(config.addonOrder[weaponId], addonId)
end

AddTraitorAmmoUpgrade(RoleConfigs.traitor, "weapon_usp", "weapon_usp_ammo", 2)
AddTraitorAmmoUpgrade(RoleConfigs.traitor, "weapon_taser", "weapon_taser_ammo", 2)
AddTraitorAmmoUpgrade(RoleConfigs.traitor_improvision, "weapon_hg_crossbow", "weapon_hg_crossbow_ammo", 2, "Start with 4 extra bolts.")
AddTraitorAmmoUpgrade(RoleConfigs.traitor_improvision, "weapon_zoraki", "weapon_zoraki_ammo", 2)
AddTraitorAmmoUpgrade(RoleConfigs.traitor_improvision, "weapon_mp-80", "weapon_mp-80_ammo", 2)
AddTraitorAmmoUpgrade(RoleConfigs.traitor_improvision, "weapon_tranquilizer", "weapon_tranquilizer_ammo", 2)

do
    local heroWeaponIds = {
        "weapon_px4beretta",
        "weapon_chiappa_rhino",
        "weapon_glock17",
        "weapon_m9beretta",
        "weapon_fn45",
        "weapon_m1911",
        "weapon_m590a1",
        "weapon_mr43",
        "weapon_mr43_short",
        "weapon_kar98",
        "weapon_mp18",
        "weapon_vpo136"
    }

    for _, weaponId in ipairs(heroWeaponIds) do
        RoleConfigs.hero.exclusions[weaponId] = RoleConfigs.hero.exclusions[weaponId] or {}
        for _, otherId in ipairs(heroWeaponIds) do
            if otherId ~= weaponId then
                RoleConfigs.hero.exclusions[weaponId][otherId] = true
            end
        end
    end

    -- Armor pieces sharing a body placement can't be worn together, so make them mutually exclusive.
    local armorSlots = {
        {"ent_armor_helmet1", "ent_armor_helmet7"},
        {"ent_armor_mask1", "ent_armor_mask2", "ent_armor_mask3"}
    }

    for _, slot in ipairs(armorSlots) do
        for _, armorId in ipairs(slot) do
            RoleConfigs.hero.exclusions[armorId] = RoleConfigs.hero.exclusions[armorId] or {}
            for _, otherId in ipairs(slot) do
                if otherId ~= armorId then
                    RoleConfigs.hero.exclusions[armorId][otherId] = true
                end
            end
        end
    end
end

local function AddVariantRoleConfig(sourceRole, targetRole, title, convar, saveFile, presetFile)
	local config = table.Copy(RoleConfigs[sourceRole])
	config.title = title
	config.convar = convar
	config.saveFile = saveFile
	config.presetFile = presetFile
	config.fallbackRole = sourceRole
	RoleConfigs[targetRole] = config
end

AddVariantRoleConfig("traitor", "traitor_soe", "SOE EXECUTIONER", "hmcd_soe_traitor_loadout", "zcity_soe_traitor_loadout.txt", "zcity_soe_traitor_presets.txt")
AddVariantRoleConfig("hero", "hero_soe", "SOE JUDGE", "hmcd_soe_hero_loadout", "zcity_soe_hero_loadout.txt", "zcity_soe_hero_presets.txt")

RoleConfigs.traitor_soe.items["weapon_revolver357"] = {cost = 7, name = "Colt King Cobra"}
RoleConfigs.traitor_soe.items["weapon_dracovska"] = {cost = 8, name = "VSKA Draco"}
AddTraitorAmmoUpgrade(RoleConfigs.traitor_soe, "weapon_revolver357", "weapon_revolver357_ammo", 2)
AddTraitorAmmoUpgrade(RoleConfigs.traitor_soe, "weapon_dracovska", "weapon_dracovska_ammo", 2)

local standardHeroArmor = {
    "ent_armor_vest3",
    "ent_armor_helmet3",
    "ent_armor_helmet6",
    "ent_armor_mask1",
    "ent_armor_mask2"
}
for _, armorId in ipairs(standardHeroArmor) do
    RoleConfigs.hero.items[armorId] = nil
end

local heroArmorOptions = {
    ["ent_armor_vest2"] = {
        cost = 4,
        name = "PACA Body Armor II",
        icon = "entities/ent_jack_gmod_ezarmor_paca.png",
        desc = "Lightweight body armor."
    },
    ["ent_armor_vest_riot"] = {
        cost = 2,
        name = "MVD Riot Vest",
        icon = "entities/ent_jack_gmod_ezarmor_stab.png",
        desc = "Riot vest with strong melee and stab protection."
    }
}

for _, roleConfig in ipairs({RoleConfigs.hero, RoleConfigs.hero_soe}) do
    for armorId, info in pairs(heroArmorOptions) do
        roleConfig.items[armorId] = table.Copy(info)
    end
end

local vestSlot = {"ent_armor_vest2", "ent_armor_vest_riot", "ent_armor_vest3"}
for _, roleConfig in ipairs({RoleConfigs.hero, RoleConfigs.hero_soe}) do
    for _, armorId in ipairs(vestSlot) do
        if roleConfig.items[armorId] then
            roleConfig.exclusions[armorId] = roleConfig.exclusions[armorId] or {}
            for _, otherId in ipairs(vestSlot) do
                if otherId ~= armorId and roleConfig.items[otherId] then
                    roleConfig.exclusions[armorId][otherId] = true
                end
            end
        end
    end
end

local function IsArmorItem(id)
    return isstring(id) and string.StartWith(id, "ent_armor_")
end

local function GetSortedIdsByCost(sourceTable)
    local ids = {}
    for id in pairs(sourceTable or {}) do
        table.insert(ids, id)
    end
    table.sort(ids, function(a, b)
        local aInfo = sourceTable[a]
        local bInfo = sourceTable[b]
        if aInfo.cost == bInfo.cost then
            return aInfo.name < bInfo.name
        end
        return aInfo.cost > bInfo.cost
    end)
    return ids
end

for _, config in pairs(RoleConfigs) do
    config.itemOrder = GetSortedIdsByCost(config.items)
    config.skillsetOrder = GetSortedIdsByCost(config.skillsets)
end

local function HasWeaponConflict(config, selectedWeapons, weaponId)
    local exclusions = config.exclusions and config.exclusions[weaponId]
    if exclusions then
        for _, selectedId in ipairs(selectedWeapons) do
            if selectedId ~= weaponId and exclusions[selectedId] then
                return true
            end
        end
    end

    for _, selectedId in ipairs(selectedWeapons) do
        if selectedId ~= weaponId then
            local selectedExclusions = config.exclusions and config.exclusions[selectedId]
            if selectedExclusions and selectedExclusions[weaponId] then
                return true
            end
        end
    end

    return false
end

local function ReadSavedLoadout(config)
    if config.saveFile then
        local data = file.Read(config.saveFile, "DATA")
        if data and data ~= "" then
            local ok, parsed = pcall(util.JSONToTable, data)
            if ok and istable(parsed) then
                return parsed
            end
        end
    end
    local savedData = GetConVar(config.convar):GetString()
    if savedData and savedData ~= "" then
        local ok, parsed = pcall(util.JSONToTable, savedData)
        if ok and istable(parsed) then
            return parsed
        end
    end
	if config.fallbackRole and RoleConfigs[config.fallbackRole] then
		return ReadSavedLoadout(RoleConfigs[config.fallbackRole])
	end
    return {}
end

local function SanitizeLoadout(config, rawLoadout)
    local normalizedLoadout = {weapons = {}}
    if config.skillsets then
        normalizedLoadout.skillset = "none"
    end

    if type(rawLoadout) ~= "table" then
        rawLoadout = {}
    end

    if config.skillsets and type(rawLoadout.skillset) == "string" and config.skillsets[rawLoadout.skillset] then
        normalizedLoadout.skillset = rawLoadout.skillset
    end

    local totalPoints = 0
    if config.skillsets and config.skillsets[normalizedLoadout.skillset] then
        totalPoints = config.skillsets[normalizedLoadout.skillset].cost
    end

    local usedWeapons = {}
    local rawWeaponIds = {}
    if type(rawLoadout.weapons) == "table" then
        for k, v in pairs(rawLoadout.weapons) do
            local weaponId
            if type(v) == "string" then
                weaponId = v
            elseif type(k) == "string" and v == true then
                weaponId = k
            end

            if weaponId and not usedWeapons[weaponId] and (config.items[weaponId] or config.addons[weaponId]) and not SkillsetBlocksGun(config, normalizedLoadout.skillset, weaponId) then
                usedWeapons[weaponId] = true
                table.insert(rawWeaponIds, weaponId)
            end
        end
    end

    usedWeapons = {}
    for _, weaponId in ipairs(rawWeaponIds) do
        local baseInfo = config.items[weaponId]
        if baseInfo and not usedWeapons[weaponId] and not HasWeaponConflict(config, normalizedLoadout.weapons, weaponId) then
            local weaponCost = baseInfo.cost
            if totalPoints + weaponCost <= config.maxPoints then
                usedWeapons[weaponId] = true
                table.insert(normalizedLoadout.weapons, weaponId)
                totalPoints = totalPoints + weaponCost
            end
        end
    end

    local usedAttachmentGroups = {}
    for _, weaponId in ipairs(rawWeaponIds) do
        local addonInfo = config.addons[weaponId]
        local groupKey = addonInfo and addonInfo.attachmentGroup and (addonInfo.parent .. ":" .. addonInfo.attachmentGroup)
        if addonInfo and not usedWeapons[weaponId] and usedWeapons[addonInfo.parent] and not (groupKey and usedAttachmentGroups[groupKey]) and not SkillsetBlocksGun(config, normalizedLoadout.skillset, weaponId) then
            local weaponCost = addonInfo.cost
            if totalPoints + weaponCost <= config.maxPoints then
                usedWeapons[weaponId] = true
                table.insert(normalizedLoadout.weapons, weaponId)
                totalPoints = totalPoints + weaponCost
                if groupKey then usedAttachmentGroups[groupKey] = true end
            end
        end
    end

    return normalizedLoadout
end

local function GetLoadoutPoints(config, loadout)
    local currentPoints = 0

    for _, wep in pairs(loadout.weapons or {}) do
        if config.items[wep] then
            currentPoints = currentPoints + config.items[wep].cost
        elseif config.addons[wep] then
            currentPoints = currentPoints + config.addons[wep].cost
        end
    end

    if config.skillsets and config.skillsets[loadout.skillset] then
        currentPoints = currentPoints + config.skillsets[loadout.skillset].cost
    end

    return currentPoints
end

local function RandomHomicideLoadout(config)
    local loadout = {weapons = {}}

    if config.skillsets then
        local skillPool = {}
        for id in pairs(config.skillsets) do skillPool[#skillPool + 1] = id end
        if math.random() < 0.55 and config.skillsets.none then
            loadout.skillset = "none"
        else
            loadout.skillset = skillPool[math.random(#skillPool)]
        end
    end

    local totalPoints = 0
    if config.skillsets and config.skillsets[loadout.skillset] then
        totalPoints = config.skillsets[loadout.skillset].cost
    end

    local function ShuffleList(list)
        for i = #list, 2, -1 do
            local j = math.random(i)
            list[i], list[j] = list[j], list[i]
        end
        return list
    end

    -- Force one real weapon (cost >= 4) if affordable.
    local weaponPool = {}
    for id, info in pairs(config.items or {}) do
        if not IsArmorItem(id) and (info.cost or 0) >= 4 and not SkillsetBlocksGun(config, loadout.skillset, id) then
            weaponPool[#weaponPool + 1] = id
        end
    end
    ShuffleList(weaponPool)
    for _, weaponId in ipairs(weaponPool) do
        if totalPoints + config.items[weaponId].cost <= config.maxPoints then
            table.insert(loadout.weapons, weaponId)
            totalPoints = totalPoints + config.items[weaponId].cost
            break
        end
    end

    -- Greedy fill with the rest of the items and addons.
    local pool = {}
    for id, info in pairs(config.items or {}) do
        pool[#pool + 1] = {id = id, cost = info.cost, addon = false}
    end
    for id, info in pairs(config.addons or {}) do
        pool[#pool + 1] = {id = id, cost = info.cost, addon = true, parent = info.parent}
    end
    ShuffleList(pool)

    local used = {}
    for _, weaponId in ipairs(loadout.weapons) do used[weaponId] = true end

    for _, entry in ipairs(pool) do
        if used[entry.id] then continue end
        if entry.addon and not used[entry.parent] then continue end
        if HasWeaponConflict(config, loadout.weapons, entry.id) then continue end
        if totalPoints + entry.cost > config.maxPoints then continue end
        table.insert(loadout.weapons, entry.id)
        used[entry.id] = true
        totalPoints = totalPoints + entry.cost
    end

    return SanitizeLoadout(config, loadout)
end

local RoleState = {}

for roleId, config in pairs(RoleConfigs) do
	local savedLoadout = SanitizeLoadout(config, ReadSavedLoadout(config))
	if config.defaultLoadout and #savedLoadout.weapons == 0 then
		savedLoadout = SanitizeLoadout(config, config.defaultLoadout)
	end
    RoleState[roleId] = {loadout = savedLoadout}
end

local function SaveLoadout(roleId)
    local config = RoleConfigs[roleId]
    local state = RoleState[roleId]
    state.loadout = SanitizeLoadout(config, state.loadout)
    local dataStr = util.TableToJSON(state.loadout)
    if not isstring(dataStr) or dataStr == "" then
        dataStr = "{\"weapons\":[]}"
        if config.skillsets then
            dataStr = "{\"weapons\":[],\"skillset\":\"none\"}"
        end
    end

    if config.saveFile then
        file.Write(config.saveFile, dataStr)
    end

    local cv = GetConVar(config.convar)
    if cv then
        cv:SetString(dataStr)
    end
end

for roleId in pairs(RoleConfigs) do
    SaveLoadout(roleId)
end

local function CloseToMainMenu(panel)
    if not IsValid(panel) then return end

    local luaMenu = panel:GetParent()
    panel:AlphaTo(0, 0.2, 0, function()
        if IsValid(panel) then
            panel:Remove()
        end
    end)

    if not IsValid(luaMenu) then
        return
    end

    for _, child in ipairs(luaMenu:GetChildren()) do
        if child ~= panel then
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
end

local function OpenRoleEditor(parentPanel, roleId, returnPanel, selectedVariant)
    local host = IsValid(parentPanel:GetParent()) and parentPanel:GetParent() or parentPanel
    local editorPanel = vgui.Create("DPanel", host)
    editorPanel:SetPos(0, 0)
    editorPanel:SetSize(ScrW(), ScrH())
    editorPanel:MoveToFront()
    editorPanel.ReturnToPanel = returnPanel
    returnPanel:SetVisible(false)
    returnPanel:SetAlpha(0)
    editorPanel:SetMouseInputEnabled(true)

    local config = RoleConfigs[roleId]
    local state = RoleState[roleId]
	local isHero = roleId == "hero" or roleId == "hero_soe"
	local variantOptions = isHero and {
		{ id = "standard", name = "Standard", roleId = "hero" },
		{ id = "soe", name = "State of Emergency", roleId = "hero_soe" },
	} or {
		{ id = "improvision", name = "Improvision", roleId = "traitor_improvision" },
		{ id = "standard", name = "Standard", roleId = "traitor" },
		{ id = "soe", name = "State of Emergency", roleId = "traitor_soe" },
	}
	selectedVariant = selectedVariant or (
		(roleId == "hero_soe" or roleId == "traitor_soe") and "soe"
		or roleId == "traitor_improvision" and "improvision"
		or "standard"
	)

    editorPanel:SetAlpha(0)
    editorPanel.Paint = function(self, w, h)
		LoadoutBackdrop(self, w, h)
    end
    editorPanel:AlphaTo(255, 0.15, 0)

    local sw, sh = ScrW(), ScrH()
    local headerHeight = MenuUnit(54)
    local sidebarWidth = math.Clamp(math.floor(sw * 0.22), MenuUnit(230), MenuUnit(360))
    local sidebarHeight = sh - headerHeight
    local UpdateUI
    local RefreshItemEditor
    local previewIconMat
    local selectedPreviewId
    local activeSidebarTab = "overview"
    local itemEditorSelectedId

    local topBar = vgui.Create("DPanel", editorPanel)
    topBar:SetPos(0, 0)
    topBar:SetSize(sw, headerHeight)
    topBar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, LOADOUT_STYLE.topBar)
        surface.SetDrawColor(LOADOUT_STYLE.accent.r, LOADOUT_STYLE.accent.g, LOADOUT_STYLE.accent.b, 100)
        surface.DrawRect(0, h - MenuUnit(1), w, MenuUnit(1))
    end

    local function StyleTopButton(btn, selected, accent)
        btn.Label = string.upper(btn:GetText() or "")
        btn:SetText("")
        btn.HoverLerp = 0
        btn.Think = function(self)
            self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        end
        btn.Paint = function(self, w, h)
            local isSelected = selected
            if isfunction(selected) then isSelected = selected() end
            local hov = self:IsHovered()
            local bg = isSelected and Color(58, 58, 58, 235) or Color(31, 31, 31, 205)
            if hov then bg = Color(48, 48, 48, 235) end
            draw.RoundedBox(3, 0, 0, w, h, bg)
            surface.SetDrawColor(LOADOUT_STYLE.border.r, LOADOUT_STYLE.border.g, LOADOUT_STYLE.border.b, isSelected and 145 or (45 + 80 * (self.HoverLerp or 0)))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if isSelected or (self.HoverLerp or 0) > 0.01 then
                surface.SetDrawColor(LOADOUT_STYLE.accent.r, LOADOUT_STYLE.accent.g, LOADOUT_STYLE.accent.b, isSelected and 210 or 210 * self.HoverLerp)
                surface.DrawRect(0, 0, MenuUnit(3), h)
            end
            local tc = isSelected and color_whitey or (hov and LOADOUT_STYLE.text or Color(188, 188, 188))
            draw.SimpleText(self.Label, "ZCity_Loadout_Tiny", w / 2, h / 2, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local exitBtn = vgui.Create("DButton", topBar)
    exitBtn:SetPos(MenuUnit(6), MenuUnit(5))
    exitBtn:SetSize(sw * 0.13, headerHeight - MenuUnit(10))
    exitBtn:SetText("EXIT")
    StyleTopButton(exitBtn)
    exitBtn.DoClick = function()
        surface.PlaySound(SOUND_SETTINGS_CLICK)
        if IsValid(editorPanel.ReturnToPanel) then
            local returnPanel = editorPanel.ReturnToPanel
            editorPanel:AlphaTo(0, 0.2, 0, function()
                if IsValid(editorPanel) then editorPanel:Remove() end
            end)
            returnPanel:SetVisible(true)
            returnPanel:AlphaTo(255, 0.2, 0)
            return
        end
        CloseToMainMenu(editorPanel)
    end

    local clearBtn = vgui.Create("DButton", topBar)
    clearBtn:SetPos(sw * 0.145, MenuUnit(5))
    clearBtn:SetSize(sw * 0.065, headerHeight - MenuUnit(10))
    clearBtn:SetText("CLEAR")
    StyleTopButton(clearBtn)
    clearBtn.DoClick = function()
        surface.PlaySound(SOUND_SETTINGS_CLICK)
        local emptyLoadout = {weapons = {}}
        if config.skillsets then emptyLoadout.skillset = "none" end
        state.loadout = SanitizeLoadout(config, emptyLoadout)
        SaveLoadout(roleId)
        if UpdateUI then UpdateUI() end
    end

    local randomBtn = vgui.Create("DButton", topBar)
    randomBtn:SetPos(sw * 0.215, MenuUnit(5))
    randomBtn:SetSize(sw * 0.075, headerHeight - MenuUnit(10))
    randomBtn:SetText("RANDOM")
    StyleTopButton(randomBtn, false, Color(225, 225, 225, 180))
    randomBtn.DoClick = function()
        surface.PlaySound(SOUND_MENU_SELECT)
        state.loadout = RandomHomicideLoadout(config)
        SaveLoadout(roleId)
        if UpdateUI then UpdateUI() end
    end

    local variantWeights = {
        Standard = 1,
        ["State of Emergency"] = 1.5,
        Improvision = 1.2
    }
    local variantGap = MenuUnit(5)
    local variantStart = randomBtn:GetX() + randomBtn:GetWide() + MenuUnit(8)
    local variantEnd = sw - sidebarWidth - MenuUnit(8)
    local variantWidthBudget = math.max(0, variantEnd - variantStart - variantGap * (#variantOptions - 1))
    local variantTotalWeight = 0
    for _, variant in ipairs(variantOptions) do
        variantTotalWeight = variantTotalWeight + (variantWeights[variant.name] or 1)
    end
    local variantX = variantStart

    for index, variant in ipairs(variantOptions) do
        local btn = vgui.Create("DButton", topBar)
        local variantWidth
        if index == #variantOptions then
            variantWidth = variantEnd - variantX
        else
            local weight = variantWeights[variant.name] or 1
            variantWidth = math.floor(variantWidthBudget * weight / variantTotalWeight)
        end
        btn:SetPos(variantX, MenuUnit(5))
        btn:SetSize(variantWidth, headerHeight - MenuUnit(10))
        btn:SetText(variant.name)
        StyleTopButton(btn, selectedVariant == variant.id, Color(220, 220, 220, 135))
        btn.DoClick = function()
            if variant.roleId == roleId then return end
            surface.PlaySound(SOUND_MENU_SELECT)
            editorPanel:Remove()
            OpenRoleEditor(returnPanel, variant.roleId, returnPanel, variant.id)
        end
        variantX = variantX + variantWidth + variantGap
    end

    local sidebar = vgui.Create("DPanel", editorPanel)
    sidebar:SetPos(sw - sidebarWidth, headerHeight)
    sidebar:SetSize(sidebarWidth, sidebarHeight)
    sidebar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 230))
        surface.SetDrawColor(LOADOUT_STYLE.accent.r, LOADOUT_STYLE.accent.g, LOADOUT_STYLE.accent.b, 50)
        surface.DrawRect(0, 0, 1, h)
    end

    local sidebarContent = vgui.Create("DPanel", sidebar)
    sidebarContent:Dock(FILL)
    sidebarContent:DockMargin(MenuUnit(8), MenuUnit(5), MenuUnit(8), MenuUnit(5))
    sidebarContent.Paint = function() end

    local presetsScroll = vgui.Create("DScrollPanel", sidebarContent)
    presetsScroll:SetPos(0, 0)
    presetsScroll:SetSize(sidebarContent:GetWide(), sidebarContent:GetTall())
    presetsScroll:SetVisible(false)
    local presetBar = presetsScroll:GetVBar()
    presetBar:SetHideButtons(true)
    presetBar.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.scrollbar)
    end
    presetBar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(3, 2, 2, w - 4, h - 4, LOADOUT_STYLE.scrollbarGrip)
    end

    local previewPanel = vgui.Create("DPanel", sidebarContent)
    previewPanel:SetPos(0, 0)
    previewPanel:SetSize(sidebarContent:GetWide(), sidebarContent:GetTall())
    previewPanel.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.panel)
        surface.SetDrawColor(LOADOUT_STYLE.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local itemEditorPanel = vgui.Create("DPanel", sidebarContent)
    itemEditorPanel:SetPos(0, 0)
    itemEditorPanel:SetSize(sidebarContent:GetWide(), sidebarContent:GetTall())
    itemEditorPanel:SetVisible(false)
    itemEditorPanel.Paint = previewPanel.Paint

    sidebarContent.PerformLayout = function(self, w, h)
        presetsScroll:SetPos(0, 0)
        presetsScroll:SetSize(w, h)
        previewPanel:SetPos(0, 0)
        previewPanel:SetSize(w, h)
        itemEditorPanel:SetPos(0, 0)
        itemEditorPanel:SetSize(w, h)
    end

    local sidebarTabs = {
        {id = "overview", name = "ITEM"},
        {id = "presets", name = "PRESETS"},
        {id = "itemEditor", name = "EDIT"}
    }

    local function SetSidebarTab(tabId)
        activeSidebarTab = tabId
        previewPanel:SetVisible(tabId == "overview")
        presetsScroll:SetVisible(tabId == "presets")
        itemEditorPanel:SetVisible(tabId == "itemEditor")
        if tabId == "itemEditor" and RefreshItemEditor and itemEditorSelectedId then
            RefreshItemEditor(itemEditorSelectedId)
        end
    end

    local tabGap = MenuUnit(3)
    local tabLeft = sw - sidebarWidth + MenuUnit(8)
    local tabWidth = (sidebarWidth - MenuUnit(16) - tabGap * (#sidebarTabs - 1)) / #sidebarTabs
    for index, tab in ipairs(sidebarTabs) do
        local tabId = tab.id
        local btn = vgui.Create("DButton", topBar)
        btn:SetPos(tabLeft + (index - 1) * (tabWidth + tabGap), MenuUnit(5))
        btn:SetSize(tabWidth, headerHeight - MenuUnit(10))
        btn:SetText(tab.name)
        btn:SetFont(TRAITOR_MENU_FONT)
        StyleTopButton(btn, function() return activeSidebarTab == tabId end)
        btn.DoClick = function()
            SetSidebarTab(tabId)
            surface.PlaySound(SOUND_MENU_SELECT)
        end
    end

    local contentPanel = vgui.Create("DPanel", editorPanel)
    contentPanel:SetPos(0, headerHeight)
    contentPanel:SetSize(sw - sidebarWidth, sidebarHeight)
    contentPanel.Paint = function() end

    local listsContainer = vgui.Create("DPanel", contentPanel)
    listsContainer:Dock(FILL)
    listsContainer:DockMargin(MenuUnit(4), MenuUnit(4), MenuUnit(4), MenuUnit(4))
    listsContainer.Paint = function() end

    local loadoutScroll = vgui.Create("DScrollPanel", listsContainer)
    loadoutScroll:Dock(FILL)
    local lsbar = loadoutScroll:GetVBar()
    lsbar:SetHideButtons(true)
    lsbar.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.scrollbar)
    end
    lsbar.btnGrip.Paint = function(self, w, h)
        local gripColor = self:IsHovered() and LOADOUT_STYLE.scrollbarGripHover or LOADOUT_STYLE.scrollbarGrip
        draw.RoundedBox(3, 2, 2, w - 4, h - 4, gripColor)
    end

    local iconPanel = vgui.Create("DPanel", previewPanel)
    iconPanel:Dock(TOP)
    iconPanel:SetTall(MenuUnit(220))
    iconPanel:DockMargin(MenuUnit(6), MenuUnit(6), MenuUnit(6), MenuUnit(5))
    iconPanel.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.background)
        surface.SetDrawColor(LOADOUT_STYLE.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if not previewIconMat or previewIconMat:IsError() then
            draw.SimpleText("ITEM IMAGE", TRAITOR_MENU_FONT, w / 2, h / 2, Color(210, 210, 210, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(previewIconMat)
        local matW, matH = math.max(previewIconMat:Width(), 1), math.max(previewIconMat:Height(), 1)
        local scale = math.min((w - MenuUnit(12)) / matW, (h - MenuUnit(12)) / matH)
        local drawW, drawH = matW * scale, matH * scale
        surface.DrawTexturedRect((w - drawW) * 0.5, (h - drawH) * 0.5, drawW, drawH)
    end

    local lblPreviewName = vgui.Create("DLabel", previewPanel)
    lblPreviewName:Dock(TOP)
    lblPreviewName:SetTall(MenuUnit(38))
    lblPreviewName:DockMargin(MenuUnit(6), 0, MenuUnit(6), MenuUnit(5))
    lblPreviewName:SetFont(TRAITOR_MENU_FONT)
    lblPreviewName:SetTextColor(color_whitey)
    lblPreviewName:SetContentAlignment(5)
    lblPreviewName:SetText("Select an item")

    local lblPreviewDesc = vgui.Create("DLabel", previewPanel)
    lblPreviewDesc:Dock(TOP)
    lblPreviewDesc:SetTall(MenuUnit(105))
    lblPreviewDesc:DockMargin(MenuUnit(6), 0, MenuUnit(6), MenuUnit(6))
    lblPreviewDesc:SetFont(TRAITOR_MENU_FONT)
    lblPreviewDesc:SetTextColor(LOADOUT_STYLE.text)
    lblPreviewDesc:SetContentAlignment(7)
    lblPreviewDesc:SetWrap(true)
    lblPreviewDesc:SetAutoStretchVertical(true)
    lblPreviewDesc:SetText("")
    lblPreviewDesc.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.panel)
        surface.SetDrawColor(LOADOUT_STYLE.borderDim)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local lblPoints = vgui.Create("DLabel", previewPanel)
    lblPoints:Dock(TOP)
    lblPoints:SetTall(MenuUnit(34))
    lblPoints:DockMargin(MenuUnit(8), 0, MenuUnit(8), MenuUnit(6))
    lblPoints:SetFont(TRAITOR_POINTS_FONT)
    lblPoints:SetTextColor(color_whitey)
    lblPoints:SetContentAlignment(5)

    local function LoadUserPresets()
        local data = file.Read(config.presetFile, "DATA")
        if data then
            return util.JSONToTable(data) or {}
        end
        return {}
    end

    local function SaveUserPresets(presets)
        file.Write(config.presetFile, util.TableToJSON(presets))
    end

    local function RefreshPresetsUI()
        presetsScroll:Clear()

        local lblPresets = vgui.Create("DLabel", presetsScroll)
        lblPresets:Dock(TOP)
        lblPresets:DockMargin(MenuUnit(6), MenuUnit(10), MenuUnit(6), MenuUnit(5))
        lblPresets:SetFont(TRAITOR_MENU_FONT)
        lblPresets:SetTextColor(LOADOUT_STYLE.text)
        lblPresets:SetContentAlignment(5)
        lblPresets:SetText("LOADOUT PRESETS")
        lblPresets:SizeToContentsY()

        local lblTitlePresets = vgui.Create("DLabel", presetsScroll)
        lblTitlePresets:Dock(TOP)
        lblTitlePresets:SetText("DEFAULT PRESETS")
        lblTitlePresets:SetFont(TRAITOR_MENU_FONT)
        lblTitlePresets:SetTextColor(LOADOUT_STYLE.dim)
        lblTitlePresets:SetContentAlignment(5)
        lblTitlePresets:SizeToContentsY()
        lblTitlePresets:DockMargin(0, MenuUnit(10), 0, MenuUnit(5))

        for _, preset in ipairs(config.defaultPresets or {}) do
            local btn = vgui.Create("DButton", presetsScroll)
            btn:Dock(TOP)
            btn:SetTall(MenuUnit(TRAITOR_PRESET_BUTTON_HEIGHT))
            btn:DockMargin(MenuUnit(5), 0, MenuUnit(5), MenuUnit(2))
            btn:SetText(preset.name)
            btn:SetFont(TRAITOR_MENU_FONT)
            btn:SetTextColor(LOADOUT_STYLE.text)
            btn.Paint = function(s, w, h)
                local bgColor = s:IsHovered() and LOADOUT_STYLE.panelHover or Color(31, 31, 31, 205)
                draw.RoundedBox(3, 0, 0, w, h, bgColor)
                surface.SetDrawColor(LOADOUT_STYLE.borderDim)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            btn.DoClick = function()
                state.loadout = SanitizeLoadout(config, table.Copy(preset.loadout or {}))
                SaveLoadout(roleId)
                UpdateUI()
                surface.PlaySound(SOUND_MENU_SELECT)
            end
        end

        local lblCustomPresets = vgui.Create("DLabel", presetsScroll)
        lblCustomPresets:Dock(TOP)
        lblCustomPresets:SetText("CUSTOM PRESETS")
        lblCustomPresets:SetFont(TRAITOR_MENU_FONT)
        lblCustomPresets:SetTextColor(LOADOUT_STYLE.dim)
        lblCustomPresets:SetContentAlignment(5)
        lblCustomPresets:SizeToContentsY()
        lblCustomPresets:DockMargin(0, MenuUnit(10), 0, MenuUnit(5))

        local userPresets = LoadUserPresets()
        local btnCreate = vgui.Create("DButton", presetsScroll)
        btnCreate:Dock(TOP)
        btnCreate:SetTall(MenuUnit(TRAITOR_PRESET_BUTTON_HEIGHT))
        btnCreate:DockMargin(MenuUnit(5), 0, MenuUnit(5), MenuUnit(5))
        btnCreate:SetText("+ SAVE CURRENT AS PRESET")
        btnCreate:SetFont(TRAITOR_MENU_FONT)
        btnCreate:SetTextColor(LOADOUT_STYLE.text)
        btnCreate.Paint = function(s, w, h)
            local bgColor = s:IsHovered() and LOADOUT_STYLE.panelHover or Color(31, 31, 31, 205)
            draw.RoundedBox(3, 0, 0, w, h, bgColor)
            surface.SetDrawColor(LOADOUT_STYLE.borderDim)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        btnCreate.DoClick = function()
            Derma_StringRequest("New Preset", "Enter a name for the new preset:", "Custom Preset " .. (#userPresets + 1), function(text)
                table.insert(userPresets, {name = text, loadout = table.Copy(state.loadout)})
                SaveUserPresets(userPresets)
                RefreshPresetsUI()
                surface.PlaySound(SOUND_MENU_SELECT)
            end)
        end

        for i, preset in ipairs(userPresets) do
            local pnl = vgui.Create("DPanel", presetsScroll)
            pnl:Dock(TOP)
            pnl:SetTall(MenuUnit(TRAITOR_PRESET_BUTTON_HEIGHT))
            pnl:DockMargin(MenuUnit(5), 0, MenuUnit(5), MenuUnit(2))
            pnl.Paint = function(s, w, h)
                draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.panel)
                surface.SetDrawColor(LOADOUT_STYLE.borderDim)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            local lblName = vgui.Create("DLabel", pnl)
            lblName:Dock(LEFT)
            lblName:DockMargin(MenuUnit(5), 0, 0, 0)
            lblName:SetText(preset.name)
            lblName:SetFont(TRAITOR_MENU_FONT)
            lblName:SetTextColor(LOADOUT_STYLE.text)
            lblName:SizeToContentsX()

            local btnDelete = vgui.Create("DButton", pnl)
            btnDelete:Dock(RIGHT)
            btnDelete:SetWide(MenuUnit(30))
            btnDelete:SetText("X")
            btnDelete:SetFont(TRAITOR_MENU_FONT)
            btnDelete:SetTextColor(LOADOUT_STYLE.dim)
            btnDelete.Paint = function(s, w, h)
                if s:IsHovered() then
                    draw.RoundedBox(3, 0, 0, w, h, Color(120, 40, 35, 100))
                end
            end
            btnDelete.DoClick = function()
                table.remove(userPresets, i)
                SaveUserPresets(userPresets)
                RefreshPresetsUI()
                surface.PlaySound(SOUND_MENU_SELECT)
            end

            local btnLoad = vgui.Create("DButton", pnl)
            btnLoad:Dock(RIGHT)
            btnLoad:SetText("LOAD")
            btnLoad:SetFont(TRAITOR_MENU_FONT)
            btnLoad:SetTextColor(LOADOUT_STYLE.text)
            btnLoad:SizeToContentsX()
            btnLoad:SetWide(btnLoad:GetWide() + MenuUnit(10))
            btnLoad.Paint = function(s, w, h)
                if s:IsHovered() then
                    draw.RoundedBox(3, 0, 0, w, h, Color(60, 60, 60, 150))
                end
            end
            btnLoad.DoClick = function()
                state.loadout = SanitizeLoadout(config, table.Copy(preset.loadout or {}))
                SaveLoadout(roleId)
                UpdateUI()
                surface.PlaySound(SOUND_MENU_SELECT)
            end
        end
    end

    RefreshPresetsUI()

    local function GetLoadoutIcon(info, id)
        local swep = weapons.GetStored(id)
        local icon = swep and (swep.WepSelectIcon or swep.IconOverride)

        if isstring(icon) and icon ~= "" then
            return Material(icon)
        end
        if type(icon) == "IMaterial" then
            return icon
        end

        if info and info.attachment and hg.attachmentsIcons and hg.attachmentsIcons[info.attachment] then
            return Material(hg.attachmentsIcons[info.attachment])
        end
        if info and isstring(info.icon) and info.icon ~= "" then
            return Material(info.icon)
        end
    end

    local editorListTitle = vgui.Create("DLabel", itemEditorPanel)
    editorListTitle:Dock(TOP)
    editorListTitle:SetTall(MenuUnit(24))
    editorListTitle:DockMargin(MenuUnit(6), MenuUnit(4), MenuUnit(6), MenuUnit(2))
    editorListTitle:SetFont("ZCity_Menu_Settings_Small")
    editorListTitle:SetTextColor(color_whitey)
    editorListTitle:SetContentAlignment(5)
    editorListTitle:SetText("ITEMS WITH ATTACHMENTS")

    local editorItemScroll = vgui.Create("DScrollPanel", itemEditorPanel)
    editorItemScroll:Dock(TOP)
    editorItemScroll:SetTall(MenuUnit(92))
    editorItemScroll:DockMargin(MenuUnit(6), 0, MenuUnit(6), MenuUnit(5))
    local editorItemBar = editorItemScroll:GetVBar()
    editorItemBar:SetHideButtons(true)
    editorItemBar.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.scrollbar)
    end
    editorItemBar.btnGrip.Paint = function(self, w, h)
        local gripColor = self:IsHovered() and LOADOUT_STYLE.scrollbarGripHover or LOADOUT_STYLE.scrollbarGrip
        draw.RoundedBox(3, 2, 2, w - 4, h - 4, gripColor)
    end

    local editorItemColumns = sidebarWidth >= MenuUnit(300) and 2 or 1
    local editorItemGap = MenuUnit(4)
    local editorItemRowHeight = MenuUnit(26)
    local editorItemButtonWidth = math.max(MenuUnit(90), math.floor((sidebarWidth - MenuUnit(36) - editorItemGap * (editorItemColumns - 1)) / editorItemColumns))
    local editorItemGrid = vgui.Create("DIconLayout", editorItemScroll:GetCanvas())
    editorItemGrid:Dock(TOP)
    editorItemGrid:SetSpaceX(editorItemGap)
    editorItemGrid:SetSpaceY(MenuUnit(2))
    local editorItemCount = 0

    for _, itemId in ipairs(config.itemOrder or {}) do
        if config.items[itemId] and config.addonOrder[itemId] and #config.addonOrder[itemId] > 0 then
            local parentId = itemId
            local itemInfo = config.items[parentId]
            local itemButton = editorItemGrid:Add("DButton")
            itemButton:SetSize(editorItemButtonWidth, editorItemRowHeight)
            itemButton:SetText("")
            itemButton.Paint = function(self, w, h)
                local selected = itemEditorSelectedId == parentId
                local bg = selected and LOADOUT_STYLE.panelActive or LOADOUT_STYLE.panel
                if self:IsHovered() then bg = LOADOUT_STYLE.panelHover end
                draw.RoundedBox(3, 0, 0, w, h, bg)
                surface.SetDrawColor(selected and LOADOUT_STYLE.accent or LOADOUT_STYLE.borderDim)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                if selected then
                    surface.SetDrawColor(LOADOUT_STYLE.accent)
                    surface.DrawRect(0, 0, MenuUnit(2), h)
                end
                draw.SimpleText(itemInfo.name, "ZCity_Menu_Settings_Small", MenuUnit(6), h / 2, color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            itemButton.DoClick = function()
                itemEditorSelectedId = parentId
                if RefreshItemEditor then RefreshItemEditor(parentId) end
                surface.PlaySound(SOUND_MENU_SELECT)
            end
            editorItemCount = editorItemCount + 1
        end
    end

    local editorItemRows = math.ceil(editorItemCount / editorItemColumns)
    local editorItemGridHeight = editorItemRows * editorItemRowHeight + math.max(editorItemRows - 1, 0) * MenuUnit(2)
    editorItemGrid:SetTall(editorItemGridHeight)
    editorItemScroll:SetTall(math.min(editorItemGridHeight, math.max(MenuUnit(92), sidebarHeight * 0.35)))

    local editorIconMat
    local editorIconPanel = vgui.Create("DPanel", itemEditorPanel)
    editorIconPanel:Dock(TOP)
    editorIconPanel:SetTall(MenuUnit(145))
    editorIconPanel:DockMargin(MenuUnit(6), 0, MenuUnit(6), MenuUnit(4))
    editorIconPanel.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.background)
        surface.SetDrawColor(LOADOUT_STYLE.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if not editorIconMat or editorIconMat:IsError() then
            draw.SimpleText("ITEM IMAGE", TRAITOR_MENU_FONT, w / 2, h / 2, Color(210, 210, 210, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(editorIconMat)
        local matW, matH = math.max(editorIconMat:Width(), 1), math.max(editorIconMat:Height(), 1)
        local scale = math.min((w - MenuUnit(12)) / matW, (h - MenuUnit(12)) / matH)
        local drawW, drawH = matW * scale, matH * scale
        surface.DrawTexturedRect((w - drawW) * 0.5, (h - drawH) * 0.5, drawW, drawH)
    end

    local editorPreviewName = vgui.Create("DLabel", itemEditorPanel)
    editorPreviewName:Dock(TOP)
    editorPreviewName:SetTall(MenuUnit(30))
    editorPreviewName:DockMargin(MenuUnit(6), 0, MenuUnit(6), MenuUnit(3))
    editorPreviewName:SetFont(TRAITOR_MENU_FONT)
    editorPreviewName:SetTextColor(color_whitey)
    editorPreviewName:SetContentAlignment(5)
    editorPreviewName:SetText("Select an item")

    local editorAttachmentHeader = vgui.Create("DPanel", itemEditorPanel)
    editorAttachmentHeader:Dock(TOP)
    editorAttachmentHeader:SetTall(MenuUnit(26))
    editorAttachmentHeader:DockMargin(MenuUnit(6), 0, MenuUnit(6), MenuUnit(3))
    editorAttachmentHeader.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, Color(31, 31, 31, 205))
        draw.SimpleText("ATTACHMENTS", "ZCity_Menu_Settings_Small", w / 2, h / 2, LOADOUT_STYLE.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local editorPoints = vgui.Create("DLabel", itemEditorPanel)
    editorPoints:Dock(BOTTOM)
    editorPoints:SetTall(MenuUnit(30))
    editorPoints:DockMargin(MenuUnit(8), 0, MenuUnit(8), MenuUnit(4))
    editorPoints:SetFont(TRAITOR_POINTS_FONT)
    editorPoints:SetTextColor(color_whitey)
    editorPoints:SetContentAlignment(5)

    local editorAttachmentScroll = vgui.Create("DScrollPanel", itemEditorPanel)
    editorAttachmentScroll:Dock(FILL)
    editorAttachmentScroll:DockMargin(MenuUnit(6), 0, MenuUnit(6), MenuUnit(4))
    local editorAttachmentBar = editorAttachmentScroll:GetVBar()
    editorAttachmentBar:SetHideButtons(true)
    editorAttachmentBar.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, LOADOUT_STYLE.scrollbar)
    end
    editorAttachmentBar.btnGrip.Paint = function(self, w, h)
        local gripColor = self:IsHovered() and LOADOUT_STYLE.scrollbarGripHover or LOADOUT_STYLE.scrollbarGrip
        draw.RoundedBox(3, 2, 2, w - 4, h - 4, gripColor)
    end

    local function UpdatePreview(id, isSkill)
        previewIconMat = nil
        if isSkill then
            selectedPreviewId = nil
        else
            selectedPreviewId = id
        end

        if isSkill then
            local info = config.skillsets[id]
            if info then
                lblPreviewName:SetText(info.name .. " (" .. info.cost .. " pts)")
                lblPreviewDesc:SetText(info.desc or "")
            end
            return
        end

        local info = config.items[id] or config.addons[id]
        if not info then return end

        lblPreviewName:SetText(info.name .. " (" .. info.cost .. " pts)")

        local desc = info.desc or "No description available."
        local swep = weapons.GetStored(id)
        if swep then
            if isstring(swep.Instructions) and swep.Instructions ~= "" then
                desc = swep.Instructions
            end
        end
        previewIconMat = GetLoadoutIcon(info, id)
        lblPreviewDesc:SetText(desc)
    end

    local function PopulateAddonRows(scroll, id)
        scroll:Clear()
        local info = config.items[id] or config.addons[id]
        local parentId = config.items[id] and id or info and info.parent
        local addonIds = parentId and config.addonOrder[parentId]
        if not addonIds or #addonIds == 0 then
            local emptyLabel = vgui.Create("DLabel", scroll)
            emptyLabel:Dock(TOP)
            emptyLabel:DockMargin(MenuUnit(6), MenuUnit(8), MenuUnit(6), 0)
            emptyLabel:SetFont(TRAITOR_MENU_FONT)
            emptyLabel:SetTextColor(LOADOUT_STYLE.dim)
            emptyLabel:SetContentAlignment(5)
            emptyLabel:SetText("NO ATTACHMENTS AVAILABLE")
            emptyLabel:SizeToContentsY()
            return
        end

        for _, addonId in ipairs(addonIds) do
            local addonInfo = config.addons[addonId]
            if addonInfo then
                local currentAddonId = addonId
                local currentAddonInfo = addonInfo
                local btn = vgui.Create("DButton", scroll)
                btn:Dock(TOP)
                btn:SetTall(MenuUnit(TRAITOR_PRESET_BUTTON_HEIGHT))
                btn:DockMargin(0, 0, MenuUnit(4), MenuUnit(4))
                btn:SetText("")
                btn.Paint = function(self, w, h)
                    local selected = table.HasValue(state.loadout.weapons, currentAddonId)
                    local parentSelected = table.HasValue(state.loadout.weapons, parentId)
                    local disabled = not parentSelected and not selected
                    local bg = selected and LOADOUT_STYLE.panelActive or LOADOUT_STYLE.panel
                    if self:IsHovered() and not disabled then bg = LOADOUT_STYLE.panelHover end
                    draw.RoundedBox(3, 0, 0, w, h, bg)
                    surface.SetDrawColor(selected and LOADOUT_STYLE.accent or LOADOUT_STYLE.borderDim)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    if selected then
                        surface.SetDrawColor(LOADOUT_STYLE.accent)
                        surface.DrawRect(0, 0, MenuUnit(2), h)
                    end
                    draw.SimpleText(currentAddonInfo.name, TRAITOR_MENU_FONT, MenuUnit(7), h / 2, disabled and LOADOUT_STYLE.dim or LOADOUT_STYLE.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(currentAddonInfo.cost .. " PTS", TRAITOR_MENU_FONT, w - MenuUnit(7), h / 2, LOADOUT_STYLE.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                btn.DoClick = function()
                    if not table.HasValue(state.loadout.weapons, parentId) then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end

                    if table.HasValue(state.loadout.weapons, currentAddonId) then
                        table.RemoveByValue(state.loadout.weapons, currentAddonId)
                    else
                        local points = GetLoadoutPoints(config, state.loadout)
                        local replacedIndexes = {}
                        if currentAddonInfo.attachmentGroup then
                            for index = #state.loadout.weapons, 1, -1 do
                                local selectedInfo = config.addons[state.loadout.weapons[index]]
                                if selectedInfo and selectedInfo.parent == parentId and selectedInfo.attachmentGroup == currentAddonInfo.attachmentGroup then
                                    points = points - selectedInfo.cost
                                    replacedIndexes[#replacedIndexes + 1] = index
                                end
                            end
                        end

                        if points + currentAddonInfo.cost > config.maxPoints then
                            surface.PlaySound("buttons/button10.wav")
                            return
                        end

                        for _, index in ipairs(replacedIndexes) do
                            table.remove(state.loadout.weapons, index)
                        end
                        table.insert(state.loadout.weapons, currentAddonId)
                    end

                    SaveLoadout(roleId)
                    UpdateUI()
                    surface.PlaySound(SOUND_MENU_SELECT)
                end
            end
        end
    end

    RefreshItemEditor = function(id)
        local info = config.items[id]
        if not info then return end

        itemEditorSelectedId = id
        editorIconMat = GetLoadoutIcon(info, id)
        editorPreviewName:SetText(info.name)
        editorPoints:SetText("POINTS: " .. GetLoadoutPoints(config, state.loadout) .. " / " .. config.maxPoints)
        PopulateAddonRows(editorAttachmentScroll, id)
    end

    UpdateUI = function()
        loadoutScroll:Clear()
        state.loadout = SanitizeLoadout(config, state.loadout)

        local currentPoints = GetLoadoutPoints(config, state.loadout)
        lblPoints:SetText("POINTS: " .. currentPoints .. " / " .. config.maxPoints)
        lblPoints:SetTextColor(LOADOUT_STYLE.text)

        local function AddCategory(title, itemIds, buildCards)
            local categoryPoints = 0
            for _, itemId in ipairs(itemIds or {}) do
                local isSelected = table.HasValue(state.loadout.weapons, itemId)
                    or config.skillsets and state.loadout.skillset == itemId
                if isSelected then
                    local itemInfo = config.items[itemId] or config.skillsets and config.skillsets[itemId]
                    categoryPoints = categoryPoints + (itemInfo and itemInfo.cost or 0)
                end
            end

            local section = vgui.Create("DPanel", loadoutScroll)
            section:Dock(TOP)
            section:SetTall(MenuUnit(210))
            section:DockMargin(MenuUnit(4), MenuUnit(8), MenuUnit(8), 0)
            section.Paint = function(self, w, h)
                surface.SetDrawColor(20, 20, 20, 120)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(LOADOUT_STYLE.border.r, LOADOUT_STYLE.border.g, LOADOUT_STYLE.border.b, 30)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            local header = vgui.Create("DPanel", section)
            header:Dock(TOP)
            header:SetTall(MenuUnit(30))
            header:DockMargin(0, 0, 0, MenuUnit(5))
            header.Paint = function(self, w, h)
                local pts = categoryPoints .. " POINTS"
                surface.SetFont("ZCity_Loadout_Tiny")
                local tw = surface.GetTextSize(title)
                local pw = surface.GetTextSize(pts)
                draw.SimpleText(title, "ZCity_Loadout_Tiny", MenuUnit(8), h / 2, Color(132, 132, 132), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(pts, "ZCity_Loadout_Tiny", w - MenuUnit(8), h / 2, LOADOUT_STYLE.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(255, 255, 255, 24)
                surface.DrawLine(MenuUnit(8) + tw + MenuUnit(8), math.floor(h / 2), w - MenuUnit(8) - pw - MenuUnit(8), math.floor(h / 2))
            end

            local scroller = vgui.Create("DHorizontalScroller", section)
            scroller:Dock(FILL)
            scroller:DockMargin(MenuUnit(2), 0, MenuUnit(2), MenuUnit(2))
            scroller:SetOverlap(0)
            buildCards(scroller)
        end

        local function AddCard(scroller, id, info, isSkill)
            local card = vgui.Create("DButton", scroller)
            local cardWidth = math.Clamp(math.floor((sw - sidebarWidth) * 0.22), MenuUnit(150), MenuUnit(275))
            card:SetSize(cardWidth, MenuUnit(165))
            card:SetText("")
            scroller:AddPanel(card)
            local cardIcon = not isSkill and GetLoadoutIcon(info, id)
            card.Paint = function(self, w, h)
                local selected = isSkill and state.loadout.skillset == id or not isSkill and table.HasValue(state.loadout.weapons, id)
                local disabled = not isSkill and not selected and HasWeaponConflict(config, state.loadout.weapons, id)
                local bg = selected and LOADOUT_STYLE.panelActive or LOADOUT_STYLE.panel
                if self:IsHovered() and not disabled then bg = LOADOUT_STYLE.panelHover end
                draw.RoundedBox(3, 0, 0, w, h, bg)
                surface.SetDrawColor(selected and LOADOUT_STYLE.accent or LOADOUT_STYLE.borderDim)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                if selected then
                    surface.SetDrawColor(LOADOUT_STYLE.accent)
                    surface.DrawRect(0, 0, MenuUnit(3), h)
                elseif self:IsHovered() and not disabled then
                    surface.SetDrawColor(LOADOUT_STYLE.accent.r, LOADOUT_STYLE.accent.g, LOADOUT_STYLE.accent.b, 120)
                    surface.DrawRect(0, 0, MenuUnit(3), h)
                end

                if not isSkill then
                    if cardIcon and not cardIcon:IsError() then
                        surface.SetDrawColor(255, 255, 255, disabled and 90 or 235)
                        surface.SetMaterial(cardIcon)
                        local iconSize = math.min(w - MenuUnit(20), h - MenuUnit(48))
                        surface.DrawTexturedRect((w - iconSize) / 2, MenuUnit(6), iconSize, iconSize)
                    else
                        draw.SimpleText("ITEM", TRAITOR_MENU_FONT, w / 2, h / 2 - MenuUnit(10), LOADOUT_STYLE.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                else
                    draw.SimpleText("ABILITY", TRAITOR_MENU_FONT, w / 2, h / 2 - MenuUnit(10), LOADOUT_STYLE.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                draw.SimpleText(info.cost .. " PTS", "ZCity_Loadout_Tiny", MenuUnit(10), MenuUnit(7), LOADOUT_STYLE.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(string.upper(info.name or ""), "ZCity_Loadout_Small", w / 2, h - MenuUnit(22), disabled and LOADOUT_STYLE.dim or color_whitey, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                if selected then
                    draw.SimpleText("EQUIPPED", "ZCity_Loadout_Tiny", w - MenuUnit(10), MenuUnit(7), LOADOUT_STYLE.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                end
                if disabled then
                    draw.RoundedBox(3, 0, 0, w, h, Color(0, 0, 0, 105))
                end
            end
            card.OnCursorEntered = function()
                if activeSidebarTab == "overview" then
                    UpdatePreview(id, isSkill)
                end
            end
            card.DoClick = function()
                if isSkill then
                    local old = config.skillsets[state.loadout.skillset]
                    local delta = info.cost - (old and old.cost or 0)
                    if GetLoadoutPoints(config, state.loadout) + delta > config.maxPoints then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end
                    state.loadout.skillset = id
                else
                    local selected = table.HasValue(state.loadout.weapons, id)
                    if not selected and HasWeaponConflict(config, state.loadout.weapons, id) then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end
                    if selected then
                        table.RemoveByValue(state.loadout.weapons, id)
                        for _, addonId in ipairs(config.addonOrder[id] or {}) do
                            table.RemoveByValue(state.loadout.weapons, addonId)
                        end
                    else
                        if GetLoadoutPoints(config, state.loadout) + info.cost > config.maxPoints then
                            surface.PlaySound("buttons/button10.wav")
                            return
                        end
                        table.insert(state.loadout.weapons, id)
                    end
                end

                state.loadout = SanitizeLoadout(config, state.loadout)
                SaveLoadout(roleId)
                UpdateUI()
                surface.PlaySound(SOUND_MENU_SELECT)
            end
        end

        local isTraitorLoadout = roleId == "traitor" or roleId == "traitor_soe" or roleId == "traitor_improvision"
        local categories = {
            ["HEAVY WEAPONS"] = {},
            ["LIGHT WEAPONS"] = {},
            ["TOOLS & MEDICAL"] = {},
            ["ARMOR"] = {}
        }
        if isTraitorLoadout then categories["MELEE"] = {} end
        for _, id in ipairs(config.itemOrder or {}) do
            if config.items[id] and not SkillsetBlocksGun(config, state.loadout.skillset, id) then
                local category = "TOOLS & MEDICAL"
                if IsArmorItem(id) then
                    category = "ARMOR"
                else
                    local swep = weapons.GetStored(id)
                    local classCategory = string.lower((swep and swep.Category) or "")
                    if isTraitorLoadout and classCategory:find("melee", 1, true) then
                        category = "MELEE"
                    elseif id == "weapon_vpo136" or id == "weapon_hg_crossbow" or id == "weapon_hg_bow" or classCategory:find("shotgun", 1, true) or classCategory:find("rifle", 1, true)
                        or classCategory:find("sniper", 1, true) or classCategory:find("machine", 1, true)
                        or classCategory:find("smg", 1, true) or classCategory:find("heavy", 1, true) then
                        category = "HEAVY WEAPONS"
                    elseif classCategory:find("pistol", 1, true) or classCategory:find("handgun", 1, true)
                        or classCategory:find("melee", 1, true) or classCategory:find("sidearm", 1, true) then
                        category = "LIGHT WEAPONS"
                    end
                end
                table.insert(categories[category], id)
            end
        end

        local categoryOrder = {}
        if selectedVariant ~= "standard" then
            table.insert(categoryOrder, "HEAVY WEAPONS")
        end
        table.insert(categoryOrder, "LIGHT WEAPONS")
        if isTraitorLoadout then table.insert(categoryOrder, "MELEE") end
        table.insert(categoryOrder, "TOOLS & MEDICAL")
        table.insert(categoryOrder, "ARMOR")
        for _, categoryName in ipairs(categoryOrder) do
            local itemIds = categories[categoryName]
            if #itemIds > 0 then
                AddCategory(categoryName, itemIds, function(scroller)
                    for _, id in ipairs(itemIds) do
                        AddCard(scroller, id, config.items[id], false)
                    end
                end)
            end
        end

        if config.skillsets and next(config.skillsets) then
            local skillIds = {}
            for _, id in ipairs(config.skillsetOrder or {}) do
                if config.skillsets[id] then table.insert(skillIds, id) end
            end
            if #skillIds > 0 then
                AddCategory("TRAITOR ABILITIES", skillIds, function(scroller)
                    for _, id in ipairs(skillIds) do
                        AddCard(scroller, id, config.skillsets[id], true)
                    end
                end)
            end
        end

        local previewId = selectedPreviewId
        if not previewId or not config.items[previewId] then
            for _, itemId in ipairs(state.loadout.weapons) do
                if config.items[itemId] then
                    previewId = itemId
                    break
                end
            end
            if not previewId then
                for _, itemId in ipairs(config.itemOrder or {}) do
                    if config.items[itemId] then
                        previewId = itemId
                        break
                    end
                end
            end
        end

        if previewId and config.items[previewId] then
            UpdatePreview(previewId, false)
        end

        if itemEditorSelectedId then
            RefreshItemEditor(itemEditorSelectedId)
        end
    end


    UpdateUI()
end

local function OpenHomicideMenu(rootPanel)
    local host = IsValid(rootPanel:GetParent()) and rootPanel:GetParent() or rootPanel
    local parentPanel = vgui.Create("DPanel", host)
    parentPanel:SetPos(0, 0)
    parentPanel:SetSize(ScrW(), ScrH())
    parentPanel:MoveToFront()
    rootPanel:SetVisible(false)
    parentPanel:SetAlpha(0)
    parentPanel.Paint = function(self, w, h)
		LoadoutBackdrop(self, w, h)
    end
    parentPanel:AlphaTo(255, 0.15, 0)

    local sw, sh = ScrW(), ScrH()

    LoadoutHeader(parentPanel, "HOMICIDE", "CHOOSE A ROLE DOSSIER")

    local cardArea = vgui.Create("DPanel", parentPanel)
    cardArea:SetSize(sw, sh)
    cardArea:SetPos(0, 0)
    cardArea.Paint = function() end
    local cardAreaX = sw * 0.11
    local cardAreaY = sh * 0.22
    local cardAreaW = sw * 0.78
    local cardAreaH = sh * 0.58
    local cardWidth = cardAreaW * 0.47
    local cardHeight = cardAreaH
    local cardOffscreenOffset = MenuUnit(80)
    local cardHoverScale = 1.01
    local cardTitleY = 0.38
    local cardPointsY = 0.5
    local cardDescY = 0.62

    local cardData = {
        {
            roleId = "hero",
            title = "JUDGE",
            desc = "Configure the Judge loadout",
            points = "16 POINTS",
			accent = Color(142, 62, 190),
            align = "left"
        },
        {
            roleId = "traitor",
            title = "EXECUTIONER",
            desc = "Configure the Executioner loadout",
            points = "30 POINTS",
			accent = Color(190, 42, 42),
            align = "right"
        }
    }

	local cardWidth = cardAreaW * 0.47

    for cardIndex, info in ipairs(cardData) do
        local card = vgui.Create("DButton", cardArea)
        card:SetText("")
        card:SetSize(cardWidth, cardHeight)
        card.BaseW = cardWidth
        card.BaseH = cardHeight
        card.HoveredLerp = 0
        card.AppearLerp = 0
        card.StartTime = CurTime()
        card.TargetX = info.align == "left" and cardAreaX or cardAreaX + cardAreaW - card.BaseW
        card.TargetY = cardAreaY
        card:SetPos(cardIndex == 1 and -card.BaseW - cardOffscreenOffset or sw + cardOffscreenOffset, card.TargetY)
        card.Think = function(self)
            self.HoveredLerp = LerpFT(0.2, self.HoveredLerp or 0, self:IsHovered() and 1 or 0)
            self.AppearLerp = math.Clamp((CurTime() - self.StartTime) / 0.28, 0, 1)
            local scale = 1 + (cardHoverScale - 1) * self.HoveredLerp
            local targetW = self.BaseW * scale
            local targetH = self.BaseH * scale
            local targetY = self.TargetY - (targetH - self.BaseH) * 0.5
            local targetX = self.TargetX - (targetW - self.BaseW) * 0.5
            local curX, curY = self:GetPos()
            local curW, curH = self:GetSize()
            self:SetSize(Lerp(FrameTime() * 10, curW, targetW), Lerp(FrameTime() * 10, curH, targetH))
            self:SetPos(Lerp(FrameTime() * 10, curX, targetX), Lerp(FrameTime() * 10, curY, targetY))
        end
        card.Paint = function(self, w, h)
            PaintLoadoutCard(self, w, h, info.title, info.points, info.desc, info.accent)
        end
        card.DoClick = function()
            surface.PlaySound(SOUND_MENU_SELECT)
            OpenRoleEditor(parentPanel, info.roleId, parentPanel)
        end
    end

    LoadoutFooter(parentPanel, "<- RETURN", function()
        parentPanel:Remove()
        if IsValid(rootPanel) then
            rootPanel:SetVisible(true)
            rootPanel:AlphaTo(255, 0.15, 0)
        end
    end)
end

local function GetArenaMode()
    return zb and zb.modes and zb.modes.tdm
end

local function ReadArenaLoadout()
    local raw = file.Read("zcity_arena_loadout.txt", "DATA")
    if not raw or raw == "" then raw = GetConVar("zcity_arena_loadout"):GetString() end
    local ok, parsed = pcall(util.JSONToTable, raw or "")
    return ok and istable(parsed) and parsed or {weapons = {}, attachments = {}, armor = {}, medical = {}}
end

local function ArenaWeaponAvailable(info)
    if not info or not info.unlock then return true end
    if not hg or not hg.achievements or not hg.achievements.IsUnlocked then return true end
    local unlocked = hg.achievements.IsUnlocked(info.unlock)
    if unlocked == nil then return true end
    return unlocked == true
end

local function SanitizeArenaLoadout(loadout)
    local mode = GetArenaMode()
    local catalog = mode and mode.ArenaWeapons or {}
    local maxWeight = mode and mode.ArenaMaxWeight or 60
    local normalized = {weapons = {}, attachments = {}, armor = {}, medical = {}}
    local usedSlots, weight = {}, 0

    for _, weaponId in ipairs(istable(loadout.weapons) and loadout.weapons or {}) do
        local info = catalog[weaponId]
        if info and not usedSlots[info.slot] and weight + info.weight <= maxWeight and ArenaWeaponAvailable(info) then
            normalized.weapons[#normalized.weapons + 1] = weaponId
            usedSlots[info.slot] = true
            weight = weight + info.weight
        end
    end

    local requested = istable(loadout.attachments) and loadout.attachments or {}
    for _, weaponId in ipairs(normalized.weapons) do
        local info = catalog[weaponId]
        local allowed, usedPlacements = {}, {}
        for _, attachmentId in ipairs(info.attachments or {}) do allowed[attachmentId] = true end
        for _, attachmentId in ipairs(istable(requested[weaponId]) and requested[weaponId] or {}) do
            local placement
            for placementId, definitions in pairs(hg.attachments or {}) do
                if definitions[attachmentId] then placement = placementId break end
            end
			local attachmentWeight = mode:GetArenaAttachmentWeight(attachmentId)
            if allowed[attachmentId] and placement and not usedPlacements[placement] and weight + attachmentWeight <= maxWeight then
                normalized.attachments[weaponId] = normalized.attachments[weaponId] or {}
                normalized.attachments[weaponId][#normalized.attachments[weaponId] + 1] = attachmentId
                usedPlacements[placement] = true
                weight = weight + attachmentWeight
            end
        end
    end

	local usedArmorSlots, selectedArmorIds = {}, {}
	for _, armorId in ipairs(istable(loadout.armor) and loadout.armor or {}) do
		local info = mode and mode.ArenaArmor and mode.ArenaArmor[armorId]
		if info and not info.helmets and not usedArmorSlots[info.slot] and weight + info.weight <= maxWeight then
			normalized.armor[#normalized.armor + 1] = armorId
			usedArmorSlots[info.slot] = true
			selectedArmorIds[armorId] = true
			weight = weight + info.weight
		end
	end
	for _, armorId in ipairs(istable(loadout.armor) and loadout.armor or {}) do
		local info = mode and mode.ArenaArmor and mode.ArenaArmor[armorId]
		if not info or not info.helmets or usedArmorSlots[info.slot] or weight + info.weight > maxWeight then continue end
		local compatible = false
		for helmetId in pairs(info.helmets) do
			if selectedArmorIds[helmetId] then compatible = true break end
		end
		if not compatible then continue end
		normalized.armor[#normalized.armor + 1] = armorId
		usedArmorSlots[info.slot] = true
		selectedArmorIds[armorId] = true
		weight = weight + info.weight
	end

	local usedMedical = {}
	for _, medicalId in ipairs(istable(loadout.medical) and loadout.medical or {}) do
		local info = mode and mode.ArenaMedical and mode.ArenaMedical[medicalId]
		if info and not usedMedical[medicalId] and weight + info.weight <= maxWeight then
			normalized.medical[#normalized.medical + 1] = medicalId
			usedMedical[medicalId] = true
			weight = weight + info.weight
		end
	end

    return normalized, weight
end

local ArenaLoadout = ReadArenaLoadout()

local function SaveArenaLoadout()
    ArenaLoadout = SanitizeArenaLoadout(ArenaLoadout)
	local json = util.TableToJSON(ArenaLoadout) or "{\"weapons\":[],\"attachments\":{},\"armor\":[],\"medical\":[]}"
    file.Write("zcity_arena_loadout.txt", json)
    GetConVar("zcity_arena_loadout"):SetString(json)
	net.Start("arena_loadout_sync")
		net.WriteString(json)
	net.SendToServer()
end

local function RandomArenaLoadout()
    local mode = GetArenaMode()
    if not mode or not mode.ArenaWeapons then return SanitizeArenaLoadout(ArenaLoadout) end
    local maxWeight = mode.ArenaMaxWeight or 60
    local loadout = {weapons = {}, attachments = {}, armor = {}, medical = {}}
    local weight = 0

    local function ShuffleList(list)
        for i = #list, 2, -1 do
            local j = math.random(i)
            list[i], list[j] = list[j], list[i]
        end
        return list
    end

    local function RandomFrom(list)
        return list[math.random(#list)]
    end

    local function CollectWeapons(slot)
        local result = {}
        for id, info in pairs(mode.ArenaWeapons) do
            if info.slot == slot and ArenaWeaponAvailable(info) then result[#result + 1] = id end
        end
        return result
    end

    local primary = RandomFrom(CollectWeapons("primary"))
    loadout.weapons[#loadout.weapons + 1] = primary
    weight = weight + mode.ArenaWeapons[primary].weight

    local secondary = RandomFrom(CollectWeapons("secondary"))
    loadout.weapons[#loadout.weapons + 1] = secondary
    weight = weight + mode.ArenaWeapons[secondary].weight

    if math.random() < 0.35 then
        local grenades = CollectWeapons("grenade")
        local grenade = RandomFrom(grenades)
        if weight + mode.ArenaWeapons[grenade].weight <= maxWeight then
            loadout.weapons[#loadout.weapons + 1] = grenade
            weight = weight + mode.ArenaWeapons[grenade].weight
        end
    end

    for _, weaponId in ipairs(loadout.weapons) do
        local info = mode.ArenaWeapons[weaponId]
        local byPlacement = {}
        for _, attachmentId in ipairs(info.attachments or {}) do
            local placement
            for placementId, definitions in pairs(hg.attachments or {}) do
                if definitions[attachmentId] then placement = placementId break end
            end
            if placement then
                byPlacement[placement] = byPlacement[placement] or {}
                byPlacement[placement][#byPlacement[placement] + 1] = attachmentId
            end
        end
        local placements = {}
        for placement in pairs(byPlacement) do placements[#placements + 1] = placement end
        ShuffleList(placements)
        local attachmentCount = math.random(0, math.min(3, #placements))
        for i = 1, attachmentCount do
            local pool = byPlacement[placements[i]]
            local attachmentId = pool[math.random(#pool)]
            local attachmentWeight = mode:GetArenaAttachmentWeight(attachmentId)
            if weight + attachmentWeight <= maxWeight then
                loadout.attachments[weaponId] = loadout.attachments[weaponId] or {}
                loadout.attachments[weaponId][#loadout.attachments[weaponId] + 1] = attachmentId
                weight = weight + attachmentWeight
            end
        end
    end

    local vests, helmets = {}, {}
    for armorId, info in pairs(mode.ArenaArmor or {}) do
        if info.slot == "vest" then vests[#vests + 1] = armorId
        elseif info.slot == "helmet" then helmets[#helmets + 1] = armorId end
    end
    if #vests > 0 and #helmets > 0 then
        local vest = vests[math.random(#vests)]
        local helmet = helmets[math.random(#helmets)]
        local vestWeight = mode.ArenaArmor[vest].weight
        local helmetWeight = mode.ArenaArmor[helmet].weight
        if weight + vestWeight + helmetWeight <= maxWeight then
            loadout.armor[#loadout.armor + 1] = vest
            loadout.armor[#loadout.armor + 1] = helmet
            weight = weight + vestWeight + helmetWeight

            if math.random() < 0.6 then
                local visors = {}
                for armorId, info in pairs(mode.ArenaArmor or {}) do
                    if info.slot == "visor" and info.helmets and info.helmets[helmet] then
                        visors[#visors + 1] = armorId
                    end
                end
                if #visors > 0 then
                    local visor = visors[math.random(#visors)]
                    if weight + mode.ArenaArmor[visor].weight <= maxWeight then
                        loadout.armor[#loadout.armor + 1] = visor
                        weight = weight + mode.ArenaArmor[visor].weight
                    end
                end
            end
        end
    end

    local medicalIds = {}
    for medicalId in pairs(mode.ArenaMedical or {}) do
        medicalIds[#medicalIds + 1] = medicalId
    end
    ShuffleList(medicalIds)
    local medicalCount = math.random(3, math.min(#medicalIds, 6))
    for i = 1, medicalCount do
        local medicalId = medicalIds[i]
        local medicalWeight = mode.ArenaMedical[medicalId].weight
        if weight + medicalWeight <= maxWeight then
            loadout.medical[#loadout.medical + 1] = medicalId
            weight = weight + medicalWeight
        end
    end

    return SanitizeArenaLoadout(loadout)
end

timer.Simple(1, function()
	if IsValid(LocalPlayer()) and GetArenaMode() then SaveArenaLoadout() end
end)

local function ReadArenaPresets()
	local ok, presets = pcall(util.JSONToTable, file.Read("zcity_arena_presets.txt", "DATA") or "")
	return ok and istable(presets) and presets or {}
end

local ArenaPresets = ReadArenaPresets()

local ArenaDefaultPresets = {
	{
		name = "RIFLEMAN",
		desc = "M4A1 / class III armor / drum",
		accent = Color(62, 112, 190),
		loadout = {
			weapons = {"weapon_m4a1", "weapon_p22"},
			armor = {"vest7", "helmet14", "visor_exfil_black"},
			medical = {"weapon_bandage_sh", "weapon_tourniquet", "weapon_bigbandage_sh", "weapon_medkit_sh", "weapon_painkillers_tpik", "weapon_bloodbag"},
			attachments = {weapon_m4a1 = {"optic5", "supressor5", "mag7"}},
		},
	},
	{
		name = "BREACHER",
		desc = "AK-74 / face shield / frag",
		accent = Color(190, 72, 42),
		loadout = {
			weapons = {"weapon_ak74", "weapon_cz75", "weapon_hg_eft_v40"},
			armor = {"vest7", "helmet12", "visor_lshz2dtm"},
			medical = {"weapon_bandage_sh", "weapon_tourniquet", "weapon_bigbandage_sh", "weapon_medkit_sh", "weapon_morphine", "weapon_adrenaline"},
			attachments = {weapon_ak74 = {"optic4", "supressor3", "mag8", "stock_ak_zenit_pt3"}},
		},
	},
	{
		name = "SCOUT",
		desc = "MP7 / armored helmet / light vest",
		accent = Color(42, 160, 140),
		loadout = {
			weapons = {"weapon_mp7", "weapon_glock17"},
			armor = {"vest4", "helmet17", "visor_fast_shield"},
			medical = {"weapon_bandage_sh", "weapon_tourniquet", "weapon_bigbandage_sh", "weapon_bloodbag"},
			attachments = {
				weapon_mp7 = {"optic5", "laser2", "supressor2"},
				weapon_glock17 = {"laser3"},
			},
		},
	},
	{
		name = "MARKSMAN",
		desc = "SVD / class III armor / full aid",
		accent = Color(142, 82, 190),
		loadout = {
			weapons = {"weapon_svd", "weapon_p22"},
			armor = {"vest7", "helmet9"},
			medical = {"weapon_bandage_sh", "weapon_tourniquet", "weapon_bigbandage_sh", "weapon_medkit_sh", "weapon_painkillers_tpik", "weapon_morphine", "weapon_adrenaline", "weapon_bloodbag", "weapon_needle", "weapon_betablock_tpik"},
			attachments = {
				weapon_svd = {"optic4", "supressor9"},
				weapon_p22 = {"laser2"},
			},
		},
	},
	{
		name = "HEAVY",
		desc = "M249 / class VI armor",
		accent = Color(190, 142, 62),
		loadout = {
			weapons = {"weapon_m249", "weapon_p22"},
			armor = {"vest18", "helmet11"},
			medical = {"weapon_bandage_sh", "weapon_tourniquet"},
			attachments = {weapon_m249 = {"optic5"}},
		},
	},
	{
		name = "SHOTGUNNER",
		desc = "SPAS-12 / class III / frag",
		accent = Color(62, 170, 90),
		loadout = {
			weapons = {"weapon_spas12", "weapon_p226", "weapon_hg_grenade_tpik"},
			armor = {"vest8", "helmet8", "visor_fast"},
			medical = {"weapon_bandage_sh", "weapon_tourniquet", "weapon_bigbandage_sh", "weapon_medkit_sh", "weapon_adrenaline", "weapon_bloodbag"},
			attachments = {weapon_spas12 = {"supressor5", "holo2"}},
		},
	},
}

local function SaveArenaPresets()
	file.Write("zcity_arena_presets.txt", util.TableToJSON(ArenaPresets, true) or "{}")
end

local function RestorePanel(panel, returnPanel)
    hg.ArenaMenuRefresh = nil
    panel:Remove()
    if IsValid(returnPanel) then
        returnPanel:SetVisible(true)
        returnPanel:AlphaTo(255, 0.15, 0)
    end
end

local function OpenArenaEditor(rootPanel)
    local mode = GetArenaMode()
    if not mode or not mode.ArenaWeapons then return end

    if hg and hg.achievements and hg.achievements.LoadAchievements then
        hg.achievements.LoadAchievements()
    end

    local host = IsValid(rootPanel:GetParent()) and rootPanel:GetParent() or rootPanel
    local panel = vgui.Create("DPanel", host)
    panel:SetPos(0, 0)
    panel:SetSize(ScrW(), ScrH())
    panel:MoveToFront()
	panel:SetAlpha(0)
	panel:AlphaTo(255, 0.15, 0)
	surface.PlaySound(SOUND_MENU_SELECT)
    rootPanel:SetVisible(false)
    panel.Paint = function(self, w, h)
		LoadoutBackdrop(self, w, h)
    end

	local sidebarWidth = math.floor(ScrW() / 4.2)
	local sidebar = vgui.Create("DPanel", panel)
	sidebar:SetPos(-sidebarWidth, 0)
	sidebar:SetSize(sidebarWidth, ScrH())
	sidebar:MoveTo(0, 0, 0.22, 0, 0.2)
	sidebar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 15, 120))
		surface.SetDrawColor(color_whitey.r, color_whitey.g, color_whitey.b, 90)
		surface.DrawRect(w - MenuUnit(1), 0, MenuUnit(1), h)
	end

	local sidebarHeader = vgui.Create("DPanel", sidebar)
	sidebarHeader:Dock(TOP)
	sidebarHeader:SetTall(MenuUnit(TRAITOR_HEADER_HEIGHT))
	sidebarHeader.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 20, 120))
		surface.SetDrawColor(color_whitey.r, color_whitey.g, color_whitey.b, 140)
		surface.DrawRect(0, h - MenuUnit(1), w, MenuUnit(1))
	end

	local title = vgui.Create("DLabel", sidebarHeader)
	title:SetPos(MenuUnit(15), MenuUnit(18))
	title:SetFont("ZCity_Menu_Settings_Small")
	title:SetTextColor(color_whitey)
	title:SetText("ARENA")
	title:SizeToContents()

	local sidebarInfo = vgui.Create("DLabel", sidebar)
	sidebarInfo:Dock(TOP)
	sidebarInfo:DockMargin(MenuUnit(15), MenuUnit(22), MenuUnit(15), 0)
	sidebarInfo:SetTall(MenuUnit(120))
	sidebarInfo:SetFont(TRAITOR_MENU_FONT)
	sidebarInfo:SetTextColor(Color(200, 200, 200))
	sidebarInfo:SetWrap(true)
 	sidebarInfo:SetText("Primary + sidearm.\nLMB equip / RMB modify.\n" .. (mode.ArenaMaxWeight or 60) .. " weight maximum.")

    local weightLabel = vgui.Create("DLabel", sidebar)
	 weightLabel:SetPos(MenuUnit(15), MenuUnit(215))
	 weightLabel:SetFont(TRAITOR_MENU_FONT)
	 weightLabel:SetTextColor(color_whitey)
	local RefreshWeapons
	local RefreshPresetList

	local randomBtn = vgui.Create("DButton", sidebar)
	randomBtn:SetPos(MenuUnit(15), MenuUnit(240))
	randomBtn:SetSize(sidebarWidth - MenuUnit(30), MenuUnit(26))
	randomBtn:SetText("")
	randomBtn.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and Color(95, 90, 50, 170) or Color(30, 30, 30, 150))
		draw.SimpleText("RANDOM LOADOUT", TRAITOR_MENU_FONT, w / 2, h / 2, Color(215, 200, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local presetLabel = vgui.Create("DLabel", sidebar)
	presetLabel:SetPos(MenuUnit(15), MenuUnit(272))
	presetLabel:SetFont(TRAITOR_MENU_FONT)
	presetLabel:SetTextColor(Color(170, 185, 185))
	presetLabel:SetText("PRESETS")
	presetLabel:SizeToContents()

	local savePreset = vgui.Create("DButton", sidebar)
	savePreset:SetPos(MenuUnit(15), MenuUnit(299))
	savePreset:SetSize(sidebarWidth - MenuUnit(30), MenuUnit(30))
	savePreset:SetText("")
	savePreset.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and Color(100, 100, 100, 150) or Color(30, 30, 30, 150))
		draw.SimpleText("+ SAVE CURRENT", TRAITOR_MENU_FONT, MenuUnit(10), h / 2, color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local presetList = vgui.Create("DScrollPanel", sidebar)
	presetList:SetPos(MenuUnit(15), MenuUnit(337))
	presetList:SetSize(sidebarWidth - MenuUnit(30), ScrH() - MenuUnit(411))

    local list = vgui.Create("DScrollPanel", panel)
	 list:SetPos(sidebarWidth + MenuUnit(20), MenuUnit(20))
	 list:SetSize((ScrW() - sidebarWidth) * 0.59, ScrH() - MenuUnit(40))
	 list:SetAlpha(0)
	 list:AlphaTo(255, 0.2, 0.08)

    local detail = vgui.Create("DPanel", panel)
	 local detailX = sidebarWidth + (ScrW() - sidebarWidth) * 0.62
	 detail:SetPos(ScrW() + MenuUnit(80), MenuUnit(20))
	 detail:SetSize((ScrW() - sidebarWidth) * 0.35, ScrH() - MenuUnit(40))
	 detail:MoveTo(detailX, MenuUnit(20), 0.22, 0.05, 0.2)
	 local previewMaterial
	 local previewName = "No item selected"
	 detail.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 180))
		surface.SetDrawColor(200, 200, 200, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("ATTACHMENTS", TRAITOR_MENU_FONT, MenuUnit(16), MenuUnit(20), color_whitey)
		draw.SimpleText(previewName, ARENA_META_FONT, MenuUnit(16), MenuUnit(44), Color(170, 185, 185))
		if previewMaterial then
			surface.SetDrawColor(255, 255, 255, 235)
			surface.SetMaterial(previewMaterial)
			local iconSize = math.min(w - MenuUnit(40), MenuUnit(145))
			surface.DrawTexturedRect((w - iconSize) * 0.5, MenuUnit(62), iconSize, iconSize)
		end
    end

    local attachmentList = vgui.Create("DScrollPanel", detail)
	attachmentList:SetPos(MenuUnit(14), MenuUnit(215))
	attachmentList:SetSize(detail:GetWide() - MenuUnit(28), detail:GetTall() - MenuUnit(229))

    local selectedWeapon
	randomBtn.DoClick = function()
		ArenaLoadout = RandomArenaLoadout()
		SaveArenaLoadout()
		selectedWeapon = nil
		attachmentList:Clear()
		RefreshWeapons()
		surface.PlaySound(SOUND_MENU_SELECT)
	end
	local function PreviewItem(itemId, info, isArmor)
		previewName = info.name
		previewMaterial = nil
		if isArmor then
			local icon = hg.armorIcons and hg.armorIcons[itemId]
			if icon then previewMaterial = Material(icon) end
			return
		end

		local swep = weapons.GetStored(itemId)
		if not swep then return end
		local icon = swep.WepSelectIcon or swep.IconOverride
		if isstring(icon) and icon ~= "" then previewMaterial = Material(icon) end
		if type(icon) == "IMaterial" then previewMaterial = icon end
	end
	local function RestoreSelectedPreview()
		local selectedInfo = selectedWeapon and mode.ArenaWeapons[selectedWeapon]
		if selectedInfo then PreviewItem(selectedWeapon, selectedInfo, false) end
	end

    local function RefreshAttachments(weaponId)
        attachmentList:Clear()
        selectedWeapon = weaponId
        local info = mode.ArenaWeapons[weaponId]
        if not info then return end
		PreviewItem(weaponId, info, false)

        local byPlacement = {}
        for _, attachmentId in ipairs(info.attachments or {}) do
            local placement = "other"
            for placementId, definitions in pairs(hg.attachments or {}) do
                if definitions[attachmentId] then placement = placementId break end
            end
            byPlacement[placement] = byPlacement[placement] or {}
            byPlacement[placement][#byPlacement[placement] + 1] = attachmentId
        end

        for placement, ids in SortedPairs(byPlacement) do
            local header = attachmentList:Add("DLabel")
            header:Dock(TOP)
            header:DockMargin(0, MenuUnit(10), 0, MenuUnit(4))
            header:SetFont(TRAITOR_MENU_FONT)
			header:SetTextColor(Color(220, 220, 220))
            header:SetText(string.upper(placement))
            header:SizeToContentsY()

            for _, attachmentId in ipairs(ids) do
                local button = attachmentList:Add("DButton")
				local attachmentMaterial = hg.attachmentsIcons and hg.attachmentsIcons[attachmentId] and Material(hg.attachmentsIcons[attachmentId])
                button:Dock(TOP)
                button:DockMargin(0, 0, 0, MenuUnit(4))
			button:SetTall(MenuUnit(30))
                button:SetText("")
                button.Paint = function(self, w, h)
                    local selected = table.HasValue(ArenaLoadout.attachments[weaponId] or {}, attachmentId)
					draw.RoundedBox(0, 0, 0, w, h, selected and Color(100, 100, 100, 150) or Color(30, 30, 30, 150))
					if attachmentMaterial then
						surface.SetDrawColor(255, 255, 255, 230)
						surface.SetMaterial(attachmentMaterial)
						surface.DrawTexturedRect(MenuUnit(5), MenuUnit(3), h - MenuUnit(6), h - MenuUnit(6))
					end
					draw.SimpleText((hg.attachmentslaunguage and hg.attachmentslaunguage[attachmentId]) or attachmentId, ARENA_META_FONT, MenuUnit(34), h / 2, color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					local attachmentWeight = mode:GetArenaAttachmentWeight(attachmentId)
					local weightText = attachmentWeight < 0 and "+" .. math.abs(attachmentWeight) .. " W" or "-" .. attachmentWeight .. " W"
					draw.SimpleText(weightText, TRAITOR_MENU_FONT, w - MenuUnit(10), h / 2, Color(200, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                button.DoClick = function()
                    ArenaLoadout.attachments[weaponId] = ArenaLoadout.attachments[weaponId] or {}
                    local selected = ArenaLoadout.attachments[weaponId]
                    if table.HasValue(selected, attachmentId) then
                        table.RemoveByValue(selected, attachmentId)
                    else
                        for _, otherId in ipairs(table.Copy(selected)) do
                            for _, definitions in pairs(hg.attachments or {}) do
                                if definitions[otherId] and definitions[attachmentId] and definitions[otherId][1] == definitions[attachmentId][1] then
                                    table.RemoveByValue(selected, otherId)
                                end
                            end
                        end
                        selected[#selected + 1] = attachmentId
                    end
                    SaveArenaLoadout()
                    RefreshAttachments(weaponId)
                    RefreshWeapons()
					surface.PlaySound(SOUND_MENU_SELECT)
                end
            end
        end
    end

    RefreshWeapons = function()
        list:Clear()
		local currentWeight
        ArenaLoadout, currentWeight = SanitizeArenaLoadout(ArenaLoadout)
        weightLabel:SetText("META WEIGHT  " .. currentWeight .. " / " .. mode.ArenaMaxWeight)
        weightLabel:SizeToContents()

        for _, category in ipairs(mode.ArenaCategoryOrder or {}) do
            local header = list:Add("DLabel")
            header:Dock(TOP)
            header:DockMargin(0, MenuUnit(12), 0, MenuUnit(5))
			header:SetFont(TRAITOR_MENU_FONT)
			header:SetTextColor(Color(220, 220, 220))
            header:SetText(string.upper(category))
            header:SizeToContentsY()

            for weaponId, info in SortedPairsByMemberValue(mode.ArenaWeapons, "name") do
                if info.category ~= category then continue end
                if not ArenaWeaponAvailable(info) then continue end
                local button = list:Add("DButton")
                button:Dock(TOP)
			button:DockMargin(0, 0, 0, MenuUnit(4))
			button:SetTall(MenuUnit(42))
                button:SetText("")
                button.Paint = function(self, w, h)
                    local selected = table.HasValue(ArenaLoadout.weapons, weaponId)
                    local hover = self:IsHovered()
					draw.RoundedBox(0, 0, 0, w, h, selected and Color(100, 100, 100, 150) or (hover and Color(150, 150, 150, 150) or Color(30, 30, 30, 150)))
				draw.SimpleText(info.name, TRAITOR_MENU_FONT, MenuUnit(12), h * 0.4, color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					local description = info.slot == "grenade" and "GRENADE" or string.upper(info.slot) .. " / " .. info.clips .. " magazines"
					draw.SimpleText(description, ARENA_DESC_FONT, MenuUnit(12), h * 0.75, Color(150, 175, 175), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(info.weight .. " W", TRAITOR_MENU_FONT, w - MenuUnit(12), h / 2, Color(200, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
				button.OnCursorEntered = function() PreviewItem(weaponId, info, false) end
				button.OnCursorExited = RestoreSelectedPreview
                button.DoClick = function()
                    if table.HasValue(ArenaLoadout.weapons, weaponId) then
                        table.RemoveByValue(ArenaLoadout.weapons, weaponId)
                        ArenaLoadout.attachments[weaponId] = nil
                        if selectedWeapon == weaponId then attachmentList:Clear() end
                    else
                        for _, otherId in ipairs(table.Copy(ArenaLoadout.weapons)) do
                            local other = mode.ArenaWeapons[otherId]
                            if other and other.slot == info.slot then
                                table.RemoveByValue(ArenaLoadout.weapons, otherId)
                                ArenaLoadout.attachments[otherId] = nil
                            end
                        end
                        ArenaLoadout.weapons[#ArenaLoadout.weapons + 1] = weaponId
                    end
                    SaveArenaLoadout()
                    RefreshWeapons()
                    if table.HasValue(ArenaLoadout.weapons, weaponId) then RefreshAttachments(weaponId) end
					surface.PlaySound(SOUND_MENU_SELECT)
                end
                button.DoRightClick = function()
                    if table.HasValue(ArenaLoadout.weapons, weaponId) then RefreshAttachments(weaponId) end
                end
            end
        end

		local function AddArmorHeader(text, marginTop)
			local header = list:Add("DLabel")
			header:Dock(TOP)
			header:DockMargin(0, MenuUnit(marginTop or 12), 0, MenuUnit(5))
			header:SetFont(TRAITOR_MENU_FONT)
			header:SetTextColor(Color(220, 220, 220))
			header:SetText(text)
			header:SizeToContentsY()
		end

		local function ToggleArmor(armorId, info)
			ArenaLoadout.armor = ArenaLoadout.armor or {}
			if table.HasValue(ArenaLoadout.armor, armorId) then
				table.RemoveByValue(ArenaLoadout.armor, armorId)
			else
				for _, otherId in ipairs(table.Copy(ArenaLoadout.armor)) do
					local other = mode.ArenaArmor[otherId]
					if other and other.slot == info.slot then table.RemoveByValue(ArenaLoadout.armor, otherId) end
				end
				ArenaLoadout.armor[#ArenaLoadout.armor + 1] = armorId
			end
			SaveArenaLoadout()
			RefreshWeapons()
			surface.PlaySound(SOUND_MENU_SELECT)
		end

		local function AddArmorButton(armorId, info, compact)
			local button = list:Add("DButton")
			local armorMaterial = hg.armorIcons and hg.armorIcons[armorId] and Material(hg.armorIcons[armorId])
			button:Dock(TOP)
			button:DockMargin(compact and MenuUnit(24) or 0, 0, compact and MenuUnit(8) or 0, MenuUnit(compact and 3 or 4))
			button:SetTall(MenuUnit(compact and 30 or 38))
			button:SetText("")
			button.Paint = function(self, w, h)
				local selected = table.HasValue(ArenaLoadout.armor or {}, armorId)
				local base = compact and Color(22, 30, 34, 205) or Color(30, 30, 30, 150)
				draw.RoundedBox(0, 0, 0, w, h, selected and Color(80, 112, 105, 210) or (self:IsHovered() and Color(105, 120, 122, 190) or base))
				if compact then
					surface.SetDrawColor(selected and Color(105, 220, 180) or Color(90, 120, 125))
					surface.DrawRect(0, 0, MenuUnit(2), h)
				end
				if armorMaterial then
					surface.SetDrawColor(255, 255, 255, 230)
					surface.SetMaterial(armorMaterial)
					surface.DrawTexturedRect(MenuUnit(6), MenuUnit(compact and 3 or 4), h - MenuUnit(compact and 6 or 8), h - MenuUnit(compact and 6 or 8))
				end
				draw.SimpleText(info.name, compact and ARENA_DESC_FONT or TRAITOR_MENU_FONT, MenuUnit(compact and 34 or 42), h / 2, color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(info.weight .. " W", compact and ARENA_DESC_FONT or TRAITOR_MENU_FONT, w - MenuUnit(12), h / 2, Color(200, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
			button.OnCursorEntered = function() PreviewItem(armorId, info, true) end
			button.OnCursorExited = RestoreSelectedPreview
			button.DoClick = function() ToggleArmor(armorId, info) end
		end

		AddArmorHeader("VESTS")
		for armorId, info in SortedPairsByMemberValue(mode.ArenaArmor or {}, "name") do
			if info.slot == "vest" then AddArmorButton(armorId, info, false) end
		end

		AddArmorHeader("HELMETS")
		for armorId, info in SortedPairsByMemberValue(mode.ArenaArmor or {}, "name") do
			if info.slot ~= "helmet" then continue end
			AddArmorButton(armorId, info, false)

			if not table.HasValue(ArenaLoadout.armor or {}, armorId) then continue end
			local hasAddons = false
			for addonId, addonInfo in SortedPairsByMemberValue(mode.ArenaArmor or {}, "name") do
				if addonInfo.slot == "visor" and (not addonInfo.helmets or addonInfo.helmets[armorId]) then
					if not hasAddons then
						local addonHeader = list:Add("DLabel")
						addonHeader:Dock(TOP)
						addonHeader:DockMargin(MenuUnit(24), MenuUnit(2), 0, MenuUnit(3))
						addonHeader:SetFont(ARENA_DESC_FONT)
						addonHeader:SetTextColor(Color(145, 175, 175))
						addonHeader:SetText("HELMET ADDONS")
						addonHeader:SizeToContentsY()
						hasAddons = true
					end
					AddArmorButton(addonId, addonInfo, true)
				end
			end
		end

		local medicalHeader = list:Add("DLabel")
		medicalHeader:Dock(TOP)
		medicalHeader:DockMargin(0, MenuUnit(12), 0, MenuUnit(5))
		medicalHeader:SetFont(TRAITOR_MENU_FONT)
		medicalHeader:SetTextColor(Color(220, 220, 220))
		medicalHeader:SetText("MEDICAL")
		medicalHeader:SizeToContentsY()

		for medicalId, info in SortedPairsByMemberValue(mode.ArenaMedical or {}, "name") do
			local button = list:Add("DButton")
			button:Dock(TOP)
			button:DockMargin(0, 0, 0, MenuUnit(4))
			button:SetTall(MenuUnit(38))
			button:SetText("")
			button.Paint = function(self, w, h)
				local selected = table.HasValue(ArenaLoadout.medical or {}, medicalId)
				draw.RoundedBox(0, 0, 0, w, h, selected and Color(100, 100, 100, 150) or (self:IsHovered() and Color(150, 150, 150, 150) or Color(30, 30, 30, 150)))
				draw.SimpleText(info.name, TRAITOR_MENU_FONT, MenuUnit(12), h / 2, color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(info.weight .. " W", TRAITOR_MENU_FONT, w - MenuUnit(12), h / 2, Color(200, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
			button.OnCursorEntered = function() PreviewItem(medicalId, info, false) end
			button.OnCursorExited = RestoreSelectedPreview
			button.DoClick = function()
				ArenaLoadout.medical = ArenaLoadout.medical or {}
				if table.HasValue(ArenaLoadout.medical, medicalId) then
					table.RemoveByValue(ArenaLoadout.medical, medicalId)
				else
					ArenaLoadout.medical[#ArenaLoadout.medical + 1] = medicalId
				end
				SaveArenaLoadout()
				RefreshWeapons()
				surface.PlaySound(SOUND_MENU_SELECT)
			end
		end
    end

	RefreshPresetList = function()
		presetList:Clear()

		local function AddCard(name, desc, accent, loadout, custom)
			local _, presetWeight = SanitizeArenaLoadout(loadout)
			local card = presetList:Add("DButton")
			card:Dock(TOP)
			card:DockMargin(0, 0, 0, MenuUnit(6))
			card:SetTall(MenuUnit(64))
			card:SetText("")
			card.Paint = function(self, w, h)
				local hover = self:IsHovered()
				draw.RoundedBox(0, 0, 0, w, h, Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 235))
				surface.SetDrawColor(accent.r, accent.g, accent.b, hover and 255 or 150)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				surface.DrawRect(0, 0, MenuUnit(3), h)
				draw.SimpleText(string.upper(name), TRAITOR_MENU_FONT, MenuUnit(10), MenuUnit(17), color_whitey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(desc, ARENA_META_FONT, MenuUnit(10), MenuUnit(36), Color(175, 185, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(presetWeight .. " / " .. (mode.ArenaMaxWeight or 60) .. " W", ARENA_META_FONT, w - MenuUnit(8), h - MenuUnit(10), Color(200, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
			card.DoClick = function()
				ArenaLoadout = table.Copy(loadout)
				SaveArenaLoadout()
				selectedWeapon = nil
				attachmentList:Clear()
				RefreshWeapons()
				surface.PlaySound(SOUND_MENU_SELECT)
			end
			if custom then
				card.DoRightClick = function()
					Derma_Query("Delete preset '" .. name .. "'?", "Arena presets", "Delete", function()
						ArenaPresets[name] = nil
						SaveArenaPresets()
						RefreshPresetList()
					end, "Cancel")
				end
			end
		end

		for _, preset in ipairs(ArenaDefaultPresets) do
			AddCard(preset.name, preset.desc, preset.accent, preset.loadout, false)
		end
		for name, loadout in SortedPairs(ArenaPresets) do
			AddCard(name, "Custom preset", Color(190, 142, 62), loadout, true)
		end
	end

	savePreset.DoClick = function()
		Derma_StringRequest("Save Arena preset", "Preset name", "", function(name)
			name = string.Trim(name or "")
			if name == "" then return end
			local sanitized = SanitizeArenaLoadout(ArenaLoadout)
			ArenaPresets[name] = table.Copy(sanitized)
			SaveArenaPresets()
			RefreshPresetList()
			surface.PlaySound(SOUND_MENU_SELECT)
		end)
	end

    local back = vgui.Create("DLabel", sidebar)
	 back:SetPos(MenuUnit(15), ScrH() - MenuUnit(62))
    back:SetFont("ZCity_Menu_Settings_Small")
    back:SetTextColor(color_whitey)
	SetupAnimatedLabel(back, "<- Loadout modes", 0, 15)
    back.Think = ThinkAnimatedLabel
    back.Paint = PaintAnimatedLabel
	back.DoClick = function() RestorePanel(panel, rootPanel) end

	RefreshPresetList()
    RefreshWeapons()
    hg.ArenaMenuRefresh = function()
        if IsValid(list) then RefreshWeapons() end
    end
end

local function AddModeCard(parent, x, y, w, h, title, points, description, align, onClick)
    local card = vgui.Create("DButton", parent)
    card:SetPos(x, y)
    card:SetSize(w, h)
    card:SetText("")
	card.BaseW = w
	card.BaseH = h
	card.HoveredLerp = 0
	card.TargetX = x
	card.TargetY = y
	card:SetPos(align == "left" and -w - MenuUnit(80) or ScrW() + MenuUnit(80), y)
	card.Think = function(self)
		self.HoveredLerp = LerpFT(0.2, self.HoveredLerp or 0, self:IsHovered() and 1 or 0)
		local scale = 1 + 0.01 * self.HoveredLerp
		local targetW = self.BaseW * scale
		local targetH = self.BaseH * scale
		local targetX = self.TargetX - (targetW - self.BaseW) * 0.5
		local targetY = self.TargetY - (targetH - self.BaseH) * 0.5
		local curX, curY = self:GetPos()
		local curW, curH = self:GetSize()
		self:SetSize(Lerp(FrameTime() * 10, curW, targetW), Lerp(FrameTime() * 10, curH, targetH))
		self:SetPos(Lerp(FrameTime() * 10, curX, targetX), Lerp(FrameTime() * 10, curY, targetY))
	end
	card.Paint = function(self, cw, ch)
		PaintLoadoutCard(self, cw, ch, title, points, description, nil)
    end
    card.DoClick = function()
        surface.PlaySound(SOUND_MENU_SELECT)
        onClick()
    end
end

function hg.DrawLoadoutMenu(parentPanel)
    parentPanel:SetAlpha(0)
	parentPanel.Paint = function(self, w, h)
		LoadoutBackdrop(self, w, h)
	end
    parentPanel:AlphaTo(255, 0.15, 0)

    LoadoutHeader(parentPanel, "LOADOUT", "CHOOSE A GAME MODE TO CONFIGURE")

    local gap = MenuUnit(24)
    local x = ScrW() * 0.09
    local y = ScrH() * 0.22
    local totalW = ScrW() * 0.82
    local cardW = (totalW - gap) * 0.5
    local cardH = ScrH() * 0.55
	AddModeCard(parentPanel, x, y, cardW, cardH, "HOMICIDE", "2 LOADOUTS", "Judge and Executioner", "left", function() OpenHomicideMenu(parentPanel) end)
	AddModeCard(parentPanel, x + cardW + gap, y, cardW, cardH, "ARENA", "50 META WEIGHT", "Weapons, armor, medical", "right", function() OpenArenaEditor(parentPanel) end)

    LoadoutFooter(parentPanel, "<- RETURN", function() CloseToMainMenu(parentPanel) end)
end

hg.DrawTraitorLoadout = hg.DrawLoadoutMenu
