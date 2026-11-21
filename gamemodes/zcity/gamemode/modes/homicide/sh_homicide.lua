local MODE = MODE
MODE.name = "hmcd"
MODE.PrintName = "Homicide"

--\\
MODE.TraitorExpectedAmtBits = 13
--//

--\\Sub Roles
MODE.ConVarName_SubRole_Traitor = "hmcd_subrole_traitor"

if(CLIENT)then
	MODE.ConVar_SubRole_Traitor = CreateClientConVar(MODE.ConVarName_SubRole_Traitor, "traitor_custom", true, true, "Select traitor role in homicide")
end

local HeroWeaponData = {
	["weapon_px4beretta"] = {extraClips = 0},
	["weapon_glock17"] = {extraClips = 0},
	["weapon_usp"] = {extraClips = 0},
	["weapon_chiappa_rhino"] = {extraClips = 0},
	["weapon_m9beretta"] = {extraClips = 0},
	["weapon_fn45"] = {extraClips = 0},
	["weapon_m1911"] = {extraClips = 0},
	["weapon_m590a1"] = {extraClips = 0, sling = true},
	["weapon_mr43"] = {extraClips = 0, sling = true},
	["weapon_mr43_short"] = {extraClips = 0},
	["weapon_kar98"] = {extraClips = 0, sling = true},
	["weapon_mp18"] = {extraClips = 0},
	["weapon_vpo136"] = {extraClips = 0, sling = true},
}

local HeroUpgradeData = {
	["hero_px4_ammo"] = {parent = "weapon_px4beretta", type = "ammo", extraClips = 1},
	["hero_glock_silencer"] = {parent = "weapon_glock17", type = "attachment", attachment = "supressor2"},
	["hero_glock_rmr"] = {parent = "weapon_glock17", type = "attachment", attachment = "holo16"},
	["hero_glock_laser"] = {parent = "weapon_glock17", type = "attachment", attachment = "laser3"},
	["hero_glock_ammo"] = {parent = "weapon_glock17", type = "ammo", extraClips = 1},
	["hero_usp_ammo"] = {parent = "weapon_usp", type = "ammo", extraClips = 1},
	["hero_usp_rmr"] = {parent = "weapon_usp", type = "attachment", attachment = "holo16"},
	["hero_usp_supressor"] = {parent = "weapon_usp", type = "attachment", attachment = "supressor1"},
	["hero_m590a1_ammo"] = {parent = "weapon_m590a1", type = "ammo", extraClips = 1},
	["hero_mr43_long_ammo"] = {parent = "weapon_mr43", type = "ammo", extraClips = 1},
	["hero_mr43_ammo"] = {parent = "weapon_mr43_short", type = "ammo", extraClips = 1},
	["hero_mp18_ammo"] = {parent = "weapon_mp18", type = "ammo", extraClips = 8},
	["hero_chiappa_ammo"] = {parent = "weapon_chiappa_rhino", type = "ammo", extraClips = 1},
	["hero_m9_silencer"] = {parent = "weapon_m9beretta", type = "attachment", attachment = "supressor2"},
	["hero_m9_rmr"] = {parent = "weapon_m9beretta", type = "attachment", attachment = "holo16"},
	["hero_m9_laser"] = {parent = "weapon_m9beretta", type = "attachment", attachment = "laser3"},
	["hero_m9_ammo"] = {parent = "weapon_m9beretta", type = "ammo", extraClips = 1},
	["hero_fn45_silencer"] = {parent = "weapon_fn45", type = "attachment", attachment = "supressor2"},
	["hero_fn45_rmr"] = {parent = "weapon_fn45", type = "attachment", attachment = "holo16"},
	["hero_fn45_laser"] = {parent = "weapon_fn45", type = "attachment", attachment = "laser5"},
	["hero_fn45_ammo"] = {parent = "weapon_fn45", type = "ammo", extraClips = 1},
	["hero_m1911_silencer"] = {parent = "weapon_m1911", type = "attachment", attachment = "supressor4"},
	["hero_m1911_ammo"] = {parent = "weapon_m1911", type = "ammo", extraClips = 1},
	["hero_kar98_scope"] = {parent = "weapon_kar98", type = "attachment", attachment = "optic12"},
	["hero_kar98_ammo"] = {parent = "weapon_kar98", type = "ammo", extraClips = 1},
	["hero_mosin_silencer"] = {parent = "weapon_mosin", type = "attachment", attachment = "supressor9"},
	["hero_mosin_scope"] = {parent = "weapon_mosin", type = "attachment", attachment = "optic12"},
	["hero_mosin_ammo"] = {parent = "weapon_mosin", type = "ammo", extraClips = 1},
}

local HeroMedicalItems = {
	["weapon_bandage_sh"] = true,
	["weapon_medkit_sh"] = true,
	["weapon_painkillers_tpik"] = true,
}

local function ParseLoadoutString(dataStr)
	local loadout = {}
	if dataStr and dataStr ~= "" then
		local ok, parsed = pcall(util.JSONToTable, dataStr)
		if ok and istable(parsed) then
			loadout = parsed
		end
	end
	return loadout
end

local LegacyTraitorLoadout = {
	skillset = "none",
	weapons = {
		"weapon_p22",
		"weapon_p22_silencer",
		"weapon_buck200knife",
		"weapon_hg_rgd_tpik",
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

local TraitorSkillsetSubRoles = {
	["infiltrator"] = "traitor_infiltrator",
	["assassin"] = "traitor_assasin",
	["chemist"] = "traitor_chemist",
	["martialartist"] = "traitor_martialartist",
	["brawler"] = "traitor_brawler",
}

local ImprovisionWeapons = {
	["weapon_hg_crossbow"] = true,
	["weapon_zoraki"] = true,
	["weapon_mp-80"] = true,
	["weapon_tranquilizer"] = true,
}

local ImprovisionLoadoutItems = {
	["weapon_traitor_poison1"] = true,
	["weapon_adrenaline"] = true,
	["weapon_walkie_talkie"] = true,
	["weapon_hg_jam"] = true,
	["weapon_traitor_poison_consumable"] = true,
	["weapon_hg_crossbow_ammo"] = true,
	["weapon_zoraki_ammo"] = true,
	["weapon_mp-80_ammo"] = true,
	["weapon_tranquilizer_ammo"] = true,
}

local TraitorAmmoUpgrades = {
	["weapon_p22_ammo"] = {weapon = "weapon_p22"},
	["weapon_pb_ammo"] = {weapon = "weapon_pb"},
	["weapon_usp_ammo"] = {weapon = "weapon_usp"},
	["weapon_taser_ammo"] = {weapon = "weapon_taser"},
	["weapon_revolver357_ammo"] = {weapon = "weapon_revolver357"},
	["weapon_draco_ammo"] = {weapon = "weapon_draco"},
	["weapon_dracovska_ammo"] = {weapon = "weapon_dracovska"},
	["weapon_hg_crossbow_ammo"] = {weapon = "weapon_hg_crossbow", ammo = 4},
	["weapon_zoraki_ammo"] = {weapon = "weapon_zoraki"},
	["weapon_mp-80_ammo"] = {weapon = "weapon_mp-80"},
	["weapon_tranquilizer_ammo"] = {weapon = "weapon_tranquilizer"},
}

local function FindAttachmentDefinition(attachmentId)
	for attachmentPlacement, definitions in pairs(hg and hg.attachments or {}) do
		if istable(definitions) and definitions[attachmentId] then
			return attachmentPlacement, definitions[attachmentId]
		end
	end
end

-- returns the attachments that could not be installed (so they can be retried)
local function ApplyCodeAttachments(weapon, attachments)
	if not IsValid(weapon) or not hg or not hg.SetAttachment then return attachments end
	if not istable(weapon.attachments) then
		if not weapon.ClearAttachments then return attachments end
		weapon:ClearAttachments()
		if not istable(weapon.attachments) then return attachments end
	end

	local failed = {}
	local changed = false
	for _, attachmentId in ipairs(attachments) do
		local placement, definition = FindAttachmentDefinition(attachmentId)
		if not placement then continue end -- unknown attachment, never retry
		if hg.IsAttachmentCompatible and not hg.IsAttachmentCompatible(weapon, placement, attachmentId, definition) then continue end
		hg.SetAttachment(weapon.attachments, attachmentId, weapon:GetClass())
		local installed = weapon.attachments[placement]
		if istable(installed) and installed[1] == attachmentId then
			changed = true
		else
			failed[#failed + 1] = attachmentId
		end
	end

	if changed then
		if weapon.UpdateAttachmentModifiers then weapon:UpdateAttachmentModifiers() end
		if weapon.SyncAtts then
			weapon:SyncAtts()
		elseif weapon.SetNetVar then
			weapon:SetNetVar("attachments", weapon.attachments)
		end
	end

	return failed
end

-- applies attachments once the weapon has finished initializing, and retries
-- once more in case something reset the weapon's attachments right after spawn
local function ApplyLoadoutAttachments(ply, weaponClass, attachments)
	if not istable(attachments) or #attachments == 0 then return end
	local pending = table.Copy(attachments)
	local function attempt(retries)
		if not IsValid(ply) or not ply:HasWeapon(weaponClass) then return end
		local weapon = ply:GetWeapon(weaponClass)
		if not IsValid(weapon) then return end
		pending = ApplyCodeAttachments(weapon, pending)
		if #pending > 0 and retries > 0 then
			timer.Simple(1, function() attempt(retries - 1) end)
		end
	end
	timer.Simple(0.5, function() attempt(2) end)
	-- weapon init can overwrite the table shortly after; re-check everything once
	timer.Simple(2, function()
		if not IsValid(ply) or not ply:HasWeapon(weaponClass) then return end
		local weapon = ply:GetWeapon(weaponClass)
		if not IsValid(weapon) or not istable(weapon.attachments) then return end
		local missing = {}
		for _, attachmentId in ipairs(attachments) do
			local placement = FindAttachmentDefinition(attachmentId)
			local installed = placement and weapon.attachments[placement]
			if placement and not (istable(installed) and installed[1] == attachmentId) then
				missing[#missing + 1] = attachmentId
			end
		end
		if #missing > 0 then ApplyCodeAttachments(weapon, missing) end
	end)
end

-- traitor menu addons that are attachments rather than items
local TraitorAttachmentAddons = {
	["weapon_p22_silencer"] = {weapon = "weapon_p22", attachment = "supressor1"},
	["weapon_pl15_silencer"] = {weapon = "weapon_pl15", attachment = "supressor2"},
	["weapon_usp_silencer"] = {weapon = "weapon_usp", attachment = "supressor2"},
	["weapon_usp_rmr"] = {weapon = "weapon_usp", attachment = "holo16"},
	["weapon_usp_laser"] = {weapon = "weapon_usp", attachment = "laser3"},
}

local function ParseLoadoutAttachmentId(id)
	if not isstring(id) then return end
	return string.match(id, "^loadout_attachment:([^:]+):([^:]+)$")
end

local function ApplyTraitorLoadout(ply)
	local convarName = MODE.Type == "improvision" and "hmcd_improvision_traitor_loadout"
		or MODE.Type == "soe" and "hmcd_soe_traitor_loadout"
		or "hmcd_traitor_loadout"
	local loadout = ParseLoadoutString(ply:GetInfo(convarName))
	if not loadout.skillset and not istable(loadout.weapons) then
		loadout = MODE.Type == "improvision" and {skillset = "none", weapons = {"weapon_tranquilizer"}} or LegacyTraitorLoadout
	end

	local skillset = loadout.skillset or "none"
	local weaponsList = istable(loadout.weapons) and loadout.weapons or {}
	if MODE.Type == "improvision" then
		local selectedWeapon
		local filteredWeapons = {}
		for _, weaponId in ipairs(weaponsList) do
			local attachmentParent = ParseLoadoutAttachmentId(weaponId)
			if ImprovisionWeapons[weaponId] then
				selectedWeapon = selectedWeapon or weaponId
			elseif ImprovisionLoadoutItems[weaponId] then
				table.insert(filteredWeapons, weaponId)
			elseif attachmentParent and ImprovisionWeapons[attachmentParent] then
				table.insert(filteredWeapons, weaponId)
			end
		end
		table.insert(filteredWeapons, selectedWeapon or "weapon_tranquilizer")
		weaponsList = filteredWeapons
	end
	ply.SubRole = TraitorSkillsetSubRoles[skillset] or ply.SubRole

	ply.organism.stamina.max = 220
	ply.organism.recoilmul = 1
	ply.MeleeDamageMul = nil

	if skillset == "infiltrator" then
		-- Infiltrator specifics
	elseif skillset == "assassin" then
		ply.organism.recoilmul = 0.8
		ply.organism.stamina.max = 300
	elseif skillset == "chemist" then
		if CleanChemicalsOfPlayer then CleanChemicalsOfPlayer(ply) end
	elseif skillset == "martialartist" then
		ply.organism.stamina.max = 340
		ply.organism.legstrength = 1.5		-- stronger kicks
		ply.organism.meleespeed = 1.35		-- faster fists
		ply.organism.painresist = 0.6		-- pain resistance
		ply.MeleeDamageMul = 1.4			-- stronger fists and nunchaku
		ply:Give("weapon_hg_nunchuks")
	elseif skillset == "brawler" then
		ply.organism.stamina.max = 300
		ply.MeleeDamageMul = 1.85
		ply.organism.painresist = 0.8
	end

	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_flashlight"] = true
	ply:SetNetVar("Inventory", inv)

	local hasP22 = false
	local hasPL15 = false
	local hasTaser = false
	local loadoutAttachments = {}

	for _, wep in pairs(weaponsList) do
		local attachmentParent, attachmentId = ParseLoadoutAttachmentId(wep)
		if attachmentParent and attachmentId then
			loadoutAttachments[attachmentParent] = loadoutAttachments[attachmentParent] or {}
			table.insert(loadoutAttachments[attachmentParent], attachmentId)
			continue
		end

		local attachmentAddon = TraitorAttachmentAddons[wep]
		if attachmentAddon then
			loadoutAttachments[attachmentAddon.weapon] = loadoutAttachments[attachmentAddon.weapon] or {}
			table.insert(loadoutAttachments[attachmentAddon.weapon], attachmentAddon.attachment)
		elseif TraitorAmmoUpgrades[wep] then
			local upgrade = TraitorAmmoUpgrades[wep]
			timer.Simple(1.5, function()
				if not IsValid(ply) or not ply:HasWeapon(upgrade.weapon) then return end
				local weapon = ply:GetWeapon(upgrade.weapon)
				if not IsValid(weapon) then return end

				local ammoType = weapon:GetPrimaryAmmoType()
				local ammoAmount = upgrade.ammo or weapon:GetMaxClip1()
				if ammoType >= 0 and ammoAmount > 0 then
					ply:GiveAmmo(ammoAmount, ammoType, true)
				end
			end)
		else
			if(ply.SubRole == "traitor_brawler")then
				local wstore = weapons.GetStored(wep)
				if(wstore and wstore.Category == "Weapons - Melee")then
					ply:Give(wep)
				end
			else
				local w = ply:Give(wep)
				if wep == "weapon_zoraki" then
					timer.Simple(1, function() if IsValid(w) then w:ApplyAmmoChanges(2) end end)
				elseif wep == "weapon_p22" then
					hasP22 = true
				elseif wep == "weapon_pl15" then
					hasPL15 = true
				elseif wep == "weapon_taser" then
					hasTaser = true
				end
			end
		end

	end

	for weaponClass, attachments in pairs(loadoutAttachments) do
		ApplyLoadoutAttachments(ply, weaponClass, attachments)
	end
end

local function ApplyHeroLoadout(ply)
	local convarName = MODE.Type == "soe" and "hmcd_soe_hero_loadout" or "hmcd_hero_loadout"
	local loadout = ParseLoadoutString(ply:GetInfo(convarName))
	local weaponsList = istable(loadout.weapons) and loadout.weapons or {}

	-- every gun the player paid for gets given, not just the first one
	local selectedWeapons, selectedSet = {}, {}
	for _, weaponId in ipairs(weaponsList) do
		if HeroWeaponData[weaponId] and not selectedSet[weaponId] then
			selectedSet[weaponId] = true
			selectedWeapons[#selectedWeapons + 1] = weaponId
		end
	end
	if #selectedWeapons == 0 then
		selectedWeapons[1] = "weapon_px4beretta"
		selectedSet["weapon_px4beretta"] = true
	end

	ply.organism.recoilmul = 1

	local needsSling = false
	for _, weaponId in ipairs(selectedWeapons) do
		if HeroWeaponData[weaponId].sling then needsSling = true break end
	end

	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_flashlight"] = true
	if needsSling then
		inv["Weapons"]["hg_sling"] = true
	end
	ply:SetNetVar("Inventory", inv)

	local givenWeapons = {}
	for _, weaponId in ipairs(selectedWeapons) do
		local weapon = ply:Give(weaponId)
		if not IsValid(weapon) then weapon = ply:GetWeapon(weaponId) end
		if IsValid(weapon) then
			givenWeapons[weaponId] = weapon
			local baseClips = HeroWeaponData[weaponId].extraClips or 0
			if baseClips > 0 and weapon:GetPrimaryAmmoType() >= 0 then
				ply:GiveAmmo(weapon:GetMaxClip1() * baseClips, weapon:GetPrimaryAmmoType(), true)
			end
		end
	end

	local attachments = {}

	for _, weaponId in ipairs(weaponsList) do
		if HeroMedicalItems[weaponId] then
			ply:Give(weaponId)
			continue
		end

		if weaponId == "weapon_walkie_talkie" then
			ply:Give("weapon_walkie_talkie")
			continue
		end

		-- handcuffs always come with their key
		if weaponId == "weapon_handcuffs" then
			ply:Give("weapon_handcuffs")
			ply:Give("weapon_handcuffs_key")
			continue
		end

		if weaponId == "weapon_handcuffs_key" then
			ply:Give("weapon_handcuffs_key")
			continue
		end

		if string.StartWith(weaponId, "ent_armor_") then
			if hg and hg.AddArmor then
				hg.AddArmor(ply, weaponId)
			end
			continue
		end

		local attachmentParent, attachmentId = ParseLoadoutAttachmentId(weaponId)
		if attachmentParent then
			if givenWeapons[attachmentParent] and attachmentId then
				attachments[attachmentParent] = attachments[attachmentParent] or {}
				table.insert(attachments[attachmentParent], attachmentId)
			end
			continue
		end

		local upgradeInfo = HeroUpgradeData[weaponId]
		local parentWeapon = upgradeInfo and givenWeapons[upgradeInfo.parent]
		if not IsValid(parentWeapon) then
			continue
		end

		if upgradeInfo.type == "ammo" then
			if parentWeapon:GetPrimaryAmmoType() >= 0 then
				ply:GiveAmmo(parentWeapon:GetMaxClip1() * (upgradeInfo.extraClips or 0), parentWeapon:GetPrimaryAmmoType(), true)
			end
		elseif upgradeInfo.type == "attachment" and upgradeInfo.attachment then
			attachments[upgradeInfo.parent] = attachments[upgradeInfo.parent] or {}
			table.insert(attachments[upgradeInfo.parent], upgradeInfo.attachment)
		end
	end

	for weaponClass, list in pairs(attachments) do
		ApplyLoadoutAttachments(ply, weaponClass, list)
	end
end

MODE.ApplyTraitorLoadout = ApplyTraitorLoadout
MODE.ApplyHeroLoadout = ApplyHeroLoadout

MODE.SubRoles = {
	["traitor_custom"] = {
		Name = "Executioner",
		Description = [[You are the custom executioner.
Your abilities and loadout are based on your selected preset or loadout.]],
		Objective = "Use your loadout to eliminate everyone before the Judge stops you.",
		SpawnFunction = function(ply)
			ApplyTraitorLoadout(ply)
		end,
	},
	["traitor_zombie"] = {
		Name = "Zombie",
		Description = [[Can infect other players silently.
Infected players can be cured by a doctor.
If all players are cured zombie will lose.
Instead of dying will be randomly transported to another infected player's body.
Has no weapons or any tools.
Despite being zombie, still bears appearance of a normal human.]],
		Objective = "You're the zombie. Infect everyone to win. Avoid doctor.",
		SpawnFunction = function(ply)
		end,
	},
	["traitor_infiltrator"] = {
		Name = "Infiltrator",
		Description = "Break necks and disguise as victims.",
		Objective = "Silently eliminate your victims by breaking necks and using disguises.",
		SpawnFunction = function(ply)
		end,
	},
	["traitor_assasin"] = {
		Name = "Assassin",
		Description = "Better gun control and more endurance.",
		Objective = "Use your superior combat skills to eliminate everyone before the Judge stops you.",
		SpawnFunction = function(ply)
		end,
	},
	["traitor_chemist"] = {
		Name = "Chemist",
		Description = "Detect chemicals in the air.",
		Objective = "Use your chemical expertise to eliminate everyone before the Judge stops you.",
		SpawnFunction = function(ply)
		end,
	},
	["traitor_martialartist"] = {
		Name = "Martial Artist",
		Description = "A nimble martial artist with high stamina and nunchucks. Performs WWE-style moves via the radial menu.",
		Objective = "Use your superior strength and WWE moves to eliminate everyone before the Judge stops you.",
		SpawnFunction = function(ply)
		end,
	},
	["traitor_brawler"] = {
		Name = "Brawler",
		Description = "A bare-knuckle brawler. Devastating 1.85x melee and can choke or execute victims with melee weapons, but no firearms and fragile from behind.",
		Objective = "Use your fists and grapples to eliminate everyone before the Judge stops you.",
		SpawnFunction = function(ply)
		end,
	},
}
--//

--\\Professions
MODE.ProfessionsRoundTypes = {
	["standard"] = true,
	["suicidelunatic"] = true,
}

MODE.Professions = {
	["doctor"] = {
		Name = "Doctor",
		SpawnFunction = function(ply)	--; TODO MAKE IT WORK
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["huntsman"] = {
		Name = "Huntsman",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["engineer"] = {
		Name = "Engineer",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["cook"] = {
		Name = "Cook",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["builder"] = {
		Name = "Builder",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["reporter"] = {
		Name = "Reporter",
		SpawnFunction = function(ply)
			ply:Give("weapon_tpik_microphone")
			hg.AddArmor(ply, "ent_armor_vest3")
			hg.AddArmor(ply, "ent_armor_helmet3")
		end,
	},
}

MODE.ProfessionsPool = {
	["doctor"] = { Chance = 1 },
	["huntsman"] = { Chance = 1 },
	["engineer"] = { Chance = 1 },
	["cook"] = { Chance = 1 },
	["builder"] = { Chance = 1 },
	["reporter"] = { Chance = 1 },
}
--//

--\\
--; Названия перменных чуть чуть конченные получились, нужно будет подумать как улучшить
--; ужас
MODE.FadeScreenTime = 1.5
MODE.DefaultRoundStartTime = 6
MODE.RoleChooseRoundStartTime = 10

MODE.RoleChooseRoundTypes = {
	["standard"] = {
		TraitorDefaultRole = "traitor_custom",
		Traitor = {
			["traitor_custom"] = true,
			["traitor_martialartist"] = true,
		},
		Professions = MODE.ProfessionsPool,
	},
	["improvision"] = {
		TraitorDefaultRole = "traitor_custom",
		Traitor = {
			["traitor_custom"] = true,
		},
	},
}
--//

MODE.Roles = {}
MODE.Roles.standard = {
	traitor = {
		objective = "You've been preparing for this for a long time. Eliminate everyone before the Judge stops you.",
		name = "Executioner",
		color = Color(190,0,0)
	},

	gunner = {
		objective = "You're the Judge. Use your loadout to stop the Executioner.",
		name = "Judge",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Victim",
		color = Color(0,120,190)
	},
}

MODE.Roles.soe = {
	traitor = {
		objective = "Eliminate everyone before the Vigilante stops you.",
		name = "Executioner",
		color = Color(190, 0, 0)
	},
	gunner = {
		objective = "You are the Vigilante. Stop the Executioner.",
		name = "Vigilante",
		color = Color(158, 0, 190)
	},
	innocent = {
		name = "Victim",
		color = Color(0, 120, 190)
	},
}

MODE.Roles.improvision = table.Copy(MODE.Roles.soe)
MODE.Roles.improvision.traitor.objective = "Use your limited weapon options to eliminate everyone before the Vigilante stops you."

MODE.Roles.suicidelunatic = {
	traitor = {
		objective = "You are the Suicide Lunatic. You have a bomb strapped to your chest. Walk into a crowd and detonate.",
		name = "Lunatic",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Innocent",
		color = Color(0,120,190)
	},

	innocent = {
		name = "Innocent",
		color = Color(0,120,190)
	},
}

MODE.Roles.supermario = {
	traitor = {
		objective = "You're the evil Mario! Jump around and take down everyone.",
		name = "Traitor Mario",
		color = Color(190,0,0)
	},

	gunner = {
		objective = "You're the hero Mario! Use your jumping ability to stop the traitor.",
		name = "Hero Mario",
		color = Color(158,0,190)
	},

	innocent = {
		objective = "You're a bystander Mario, survive and avoid the traitor's traps!",
		name = "Innocent Mario",
		color = Color(0,120,190)
	},
}

function MODE.GetPlayerTraceToOther(ply, aim_vector, dist)
	local trace = hg.eyeTrace(ply, dist, nil, aim_vector)
	
	if(trace)then
		local aim_ent = trace.Entity
		local other_ply = nil
		
		if(IsValid(aim_ent))then
			if(aim_ent:IsPlayer())then
				other_ply = aim_ent
			elseif(aim_ent:IsRagdoll())then
				if(IsValid(aim_ent.ply))then
					other_ply = aim_ent.ply
				end
			end
		end
		
		return aim_ent, other_ply, trace
	else
		return nil
	end
end
