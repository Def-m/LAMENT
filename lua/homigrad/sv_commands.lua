COMMANDS = COMMANDS or {}

local validUserGroupSuperAdmin = {
	superadmin = true,
	owner = true,
	coowner = true,
	["co-owner"] = true,
	["owner/co-owner"] = true,
}

local validUserGroup = {
	admin = true,
}

local function UserGroupMatches(ply, acceptedGroups)
	if not IsValid(ply) then return false end

	local group = string.lower(tostring(ply:GetUserGroup() or "user"))
	local groups = ULib and ULib.ucl and ULib.ucl.groups
	local visited = {}

	while group ~= "" and not visited[group] do
		if acceptedGroups[group] then return true end

		visited[group] = true
		local groupData = groups and groups[group]
		local parent = groupData and groupData.inherit_from
		if not isstring(parent) or parent == "" then break end

		group = string.lower(parent)
	end

	return false
end

function COMMAND_GETACCES(ply)
	if ply == Entity(0) then return 2 end

	if UserGroupMatches(ply, validUserGroupSuperAdmin) then
		return 2
	elseif UserGroupMatches(ply, validUserGroup) then
		return 1
	end

	return 0
end

function COMMAND_ACCES(ply,cmd)
	local access = cmd[2] or 1
	if access ~= 0 and COMMAND_GETACCES(ply) < access then return end

	return true
end

function COMMAND_GETARGS(input)
	local text = istable(input) and table.concat(input, " ") or tostring(input or "")
	local newArgs = {}
	local current = {}
	local inQuotes = false

	local function PushArgument()
		if #current == 0 then return end
		newArgs[#newArgs + 1] = table.concat(current)
		current = {}
	end

	for index = 1, #text do
		local character = string.sub(text, index, index)

		if character == "\"" then
			inQuotes = not inQuotes
		elseif string.match(character, "%s") and not inQuotes then
			PushArgument()
		else
			current[#current + 1] = character
		end
	end

	PushArgument()
	return newArgs
end

function COMMAND_Input(ply,args)
	if not istable(args) or not args[1] then return false end

	args[1] = string.lower(tostring(args[1]))
	local cmd = COMMANDS[args[1]]
	if not cmd then return false end
	if not COMMAND_ACCES(ply,cmd) then
		if IsValid(ply) then
			ply:ChatPrint("You do not have permission to use this command.")
		end
		return true,false
	end

	table.remove(args,1)

	return true,cmd[1](ply,args)
end
-- Мдаааа А ПЛЕЙРСЕЙ ДЛЯ КОГО НУЖЕН????
hook.Add("HG_PlayerSay","commands-chat",function(ply, txtTbl, text)
	text = string.Trim(isstring(text) and text or (istable(txtTbl) and txtTbl[1]) or "")
	if string.sub(text, 1, 1) ~= "!" then return end

	local commandText = string.Trim(string.sub(text, 2))
	if commandText == "" then return end

	local handled = COMMAND_Input(ply, COMMAND_GETARGS(commandText))
	if handled and istable(txtTbl) then
		-- Execute recognized commands without broadcasting the command text.
		txtTbl[1] = ""
	end
end)

COMMANDS.help = {function(ply,args)
	local text = ""

	if args[1] then
		local commandName = string.lower(tostring(args[1]))
		local cmd = COMMANDS[commandName]
		if not cmd or not COMMAND_ACCES(ply, cmd) then
			ply:ChatPrint("Unknown command or insufficient permission: !" .. commandName)
			return
		end
		local argsList = cmd[3]
		if argsList then argsList = " - " .. argsList else argsList = "" end

		text = text .. "	" .. commandName .. argsList .. "\n"
	else
		local list = {}
		for name in pairs(COMMANDS) do list[#list + 1] = name end
		table.sort(list,function(a,b) return a > b end)
        
		for _,name in pairs(list) do
			local cmd = COMMANDS[name]
            if not COMMAND_ACCES(ply,cmd) then continue end
            
			local argsList = cmd[3]
			if argsList then argsList = " - " .. argsList else argsList = "" end
            
			text = text .. "	" .. name .. argsList .. "\n"
		end
	end

	text = string.sub(text,1,#text - 1)

	ply:ChatPrint(text)
end,0}

if SERVER then
    util.AddNetworkString("PunishLightningEffect")
    util.AddNetworkString("AnotherLightningEffect")
    util.AddNetworkString("PluvCommand")

    COMMANDS.zc_god = {function(ply)
        if not ply.organism then return end
        
        ply.organism.godmode = !ply.organism.godmode
		ply:Notify(ply.organism.godmode and "now i'm immortal..." or "now i'm mortal")
		return
    end,1}

	COMMANDS.zc_cloak = {function(ply)
        if not ply.organism then return end
		ply.cloak = !ply.cloak
        ply:SetMaterial(ply.cloak and "NULL" or nil)
		ply:DrawShadow(!ply.cloak)
		ply:SetCollisionGroup(ply.cloak and COLLISION_GROUP_DEBRIS or COLLISION_GROUP_PLAYER)
		ply:RemoveAllDecals()
		ply:Notify(ply.cloak and "now i'm invisible..." or "now i'm visible") -- walking by the wall
		return
    end,1}

    COMMANDS.punish = {function(ply, args)
        if #args < 1 then
            ply:ChatPrint("Give me the name of this OwO .")
            return
        end

        local targetNickPartial = string.lower(args[1]) 
        local target = nil
        for _, player in player.Iterator() do
            if string.find(string.lower(player:Nick()), targetNickPartial) then 
                target = player
                break
            end
        end

        if not IsValid(target) then
            ply:ChatPrint("I don't see that OwO .")
            return
        end

        target = hg.GetCurrentCharacter(target)

        net.Start("AnotherLightningEffect")
        net.WriteEntity(target)
        net.Broadcast()

        net.Start("PunishLightningEffect")
        net.WriteEntity(target)
        net.Broadcast()

        target:EmitSound("snd_jack_hmcd_lightning.wav")

        local dmg = DamageInfo()
        dmg:SetDamage(1000)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(ply)
        dmg:SetDamageType(DMG_SHOCK)
        target:TakeDamageInfo(dmg)

        ply:ChatPrint("Fatass " .. target:Nick() .. " has been punished.")
    end, 2, "ник игрока"}

    COMMANDS.pluv = {function(ply, args)
        net.Start("PluvCommand")
        net.Send(ply)
    end, 0}

    COMMANDS.notify = {function(ply, args)
        if #args < 2 then
            ply:ChatPrint("Usage: !notify <player> <message>")
            return
        end

        local targetNickPartial = string.lower(args[1]) 
        local target = nil
        for _, player in player.Iterator() do
            if string.find(string.lower(player:Nick()), targetNickPartial) then 
                target = player
                break
            end
        end

        if not IsValid(target) then
            ply:ChatPrint("Player not found: " .. args[1])
            return
        end
        
        table.remove(args, 1) 
        local message = table.concat(args, " ")
        
        if message == "" then
            ply:ChatPrint("Message cannot be empty!")
            return
        end
        
        target:Notify(message, 0)
        ply:ChatPrint("Sent notification to " .. target:GetName() .. ": " .. message)

    end, 2, "name; message"}

local VIP_MODEL_WHITELIST = {
        ["models/gacommissions/tungtungtungsahur.mdl"] = true,
        ["models/nikita488/player/joker.mdl"] = true,
        ["models/blop/expie/expie.mdl"] = true,
        ["models/player/skeleton.mdl"] = true,
        ["models/player/big_boss.mdl"] = true,
        ["models/player/corpse1.mdl"] = true,
        ["models/player/charple.mdl"] = true,
        ["models/dannio/pm/rizzler_costco.mdl"] = true,
        ["models/dannio/pm/aj_costco.mdl"] = true,
        ["models/player/efeber/tonysop.mdl"] = true,
        ["models/player/h3_masterchief_player.mdl"] = true,
        ["models/deadspace2023/dsrisaaclv3.mdl"] = true,
        ["models/player/group01/clark_playermodel.mdl"] = true,
        ["models/player/ntwffelixkranken.mdl"] = true,
        ["models/player/ntwfrosemary.mdl"] = true,
        ["models/i6nis/freddy_player.mdl"] = true,
        ["models/i6nis/bonnie_player.mdl"] = true,
        ["models/i6nis/chica_player.mdl"] = true,
        ["models/i6nis/foxy_player.mdl"] = true,
        ["models/player/chimpanzee/chimp.mdl"] = true,
        ["models/player/rickality/rick2.mdl"] = true,
        ["models/ats/mgs2snake/mgs2snake.mdl"] = true,
        ["models/player/pizzaroll/l4dtank.mdl"] = true,
        ["models/player/old_snake.mdl"] = true,
        ["models/electric/clown/clown_pm.mdl"] = true,
        ["models/dannio/pm/bigjustice_costco.mdl"] = true,
        ["models/player/walterv2.mdl"] = true,
        ["models/player/jessev2.mdl"] = true,
        ["models/gustavo_fring/gustavo_los_pollos.mdl"] = true,
    }

	local function NormalizeSetModelPath(mdl)
		mdl = string.Trim(string.lower(tostring(mdl or "")))
		mdl = string.Replace(mdl, "\\", "/")
		return mdl
	end

	local SETMODEL_STAFF_GROUPS = {
		mod = true,
		moderator = true,
		admin = true,
		superadmin = true,
		owner = true,
		coowner = true,
		["co-owner"] = true,
		["owner/co-owner"] = true,
	}

	local SETMODEL_BLOCKED_ROUNDS = {
		juggernaut = "Juggernaut",
		tdm = "TDM",
		riot = "Riot",
		chudbeasts = "Chud Beasts",
	}

	-- ULX servers commonly use custom groups which inherit from moderator/admin.
	-- Walk the ULib inheritance chain instead of relying on IsAdmin(), since that
	-- can promote a moderator into the full-admin targeting branch on some setups.
	local function SetModelGroupMatches(ply, acceptedGroups)
		local group = string.lower(tostring(ply:GetUserGroup() or "user"))
		local groups = ULib and ULib.ucl and ULib.ucl.groups
		local visited = {}

		while group ~= "" and not visited[group] do
			if acceptedGroups[group] then return true end

			visited[group] = true
			local groupData = groups and groups[group]
			local parent = groupData and groupData.inherit_from
			if not isstring(parent) or parent == "" then break end

			group = string.lower(parent)
		end

		return false
	end

	local function FindZCityAppearanceModel(mdl)
		mdl = NormalizeSetModelPath(mdl)
		if not hg or not hg.Appearance or not hg.Appearance.PlayerModels then return nil end

		for sex = 1, 2 do
			for appearanceName, data in pairs(hg.Appearance.PlayerModels[sex] or {}) do
				if istable(data) and NormalizeSetModelPath(data.mdl) == mdl then
					return appearanceName, data
				end
			end
		end
	end

	local function SaveSetModelOriginalAppearance(ply)
		if ply.ChudSetModelOriginalAppearance then return end

		if ply.CurAppearance then
			ply.ChudSetModelOriginalAppearance = table.Copy(ply.CurAppearance)
		end

		ply.ChudSetModelOriginalModel = ply:GetModel()
	end

	local function RestoreSetModelAppearance(ply)
		if not IsValid(ply) then return false end
		if not hg or not hg.Appearance or not hg.Appearance.ForceApplyAppearance then return false end

		local appearance = ply.ChudSetModelOriginalAppearance or ply.CurAppearance
		if not appearance then return false end

		hg.Appearance.ForceApplyAppearance(ply, table.Copy(appearance))

		ply.ChudSetModelOriginalAppearance = nil
		ply.ChudSetModelOriginalModel = nil
		return true
	end

	local function IsUsableZCityRagdollModel(mdl)
		if not util.IsValidModel(mdl) then
			return false, "That model is invalid or is not installed on the server."
		end

		-- Z-City creates player ragdolls constantly. A model without ragdoll physics
		-- can make the player invisible/broken and causes C_ServerRagdoll errors.
		if util.IsValidRagdoll and not util.IsValidRagdoll(mdl) then
			return false, "That model is not Z-City compatible because it has no valid ragdoll physics."
		end

		return true
	end

	local function ApplyTemporaryZCityModel(ply, mdl)
		local appearanceName = FindZCityAppearanceModel(mdl)
		if not appearanceName then return false end

		SaveSetModelOriginalAppearance(ply)

		local originalAppearance = ply.ChudSetModelOriginalAppearance or ply.CurAppearance
		local temporaryAppearance = originalAppearance and table.Copy(originalAppearance) or hg.Appearance.GetRandomAppearance()
		temporaryAppearance.AModel = appearanceName

		-- Apply the model using Z-City's own appearance code so clothes/submaterials
		-- are correct, then keep the original appearance saved for !setmodel default.
		hg.Appearance.ForceApplyAppearance(ply, temporaryAppearance)
		if originalAppearance then
			ply.CurAppearance = table.Copy(originalAppearance)
		end

		return true
	end

	local function ApplyTemporaryCustomModel(ply, mdl)
		SaveSetModelOriginalAppearance(ply)

		-- Do not edit CurAppearance/AClothes/AAttachments. Those are the player's
		-- normal Z-City appearance and are needed to restore them later.
		ply:SetModel(mdl)
		ply:SetSubMaterial()

		if ply.SetSkin then
			ply:SetSkin(0)
		end

		for _, bodygroup in ipairs(ply:GetBodyGroups() or {}) do
			ply:SetBodygroup(bodygroup.id or 0, 0)
		end

		-- Accessories from the normal Z-City model can be attached to incompatible
		-- bones on custom playermodels. Hide them temporarily; default restores them.
		ply:SetNetVar("Accessories", {})
	end

	COMMANDS.setmodel = {function(ply, args)
		local canModerateModels = SetModelGroupMatches(ply, SETMODEL_STAFF_GROUPS)
		local activeRound = zb and string.lower(tostring(zb.CROUND or "")) or ""
		local blockedRoundName = SETMODEL_BLOCKED_ROUNDS[activeRound]
		if blockedRoundName then
			ply:ChatPrint("!setmodel is disabled during " .. blockedRoundName .. ".")
			return
		end
		if not args[1] then
			ply:ChatPrint("Usage: !setmodel <model/default> OR !setmodel <player/*> <model/default>")
			return
		end
		local targets = {ply}
		local requestedModel = table.concat(args, " ")
		local allPlayers = false
        local joined = NormalizeSetModelPath(requestedModel)
        -- A full model path (including spaces) is a self request. Only parse a
        -- player selector when the input does not begin with a model path.
        local selfModelPath = string.sub(joined, 1, 7) == "models/"
        if #args > 1 and not selfModelPath then
            -- Model paths may contain spaces after the target selector too.
            local modelIndex = #args
            for i = 2, #args do
                if string.sub(NormalizeSetModelPath(args[i]), 1, 7) == "models/" then
                    modelIndex = i
                    break
                end
            end
            local targetName = table.concat(args, " ", 1, modelIndex - 1)
            requestedModel = table.concat(args, " ", modelIndex)
            local selector = string.lower(string.Trim(targetName))
            if selector == "*" then
                if not canModerateModels then
                    ply:ChatPrint("Only moderators and above can change other players' models. Use !setmodel <model> for yourself.")
                    return
                end
                allPlayers = true
                targets = player.GetAll()
            elseif selector == "^" or selector == "@me" or selector == string.lower(ply:Nick()) or selector == string.lower(ply:SteamID()) or selector == ply:SteamID64() then
                targets = {ply}
            else
                if not canModerateModels then
                    ply:ChatPrint("Only moderators and above can change other players' models. Use !setmodel <model> for yourself.")
                    return
                end
                local matches = player.GetListByName(targetName)
                local target = matches and matches[1]
                if not IsValid(target) then
                    ply:ChatPrint("Player not found: " .. targetName)
                    return
                end
                targets = {target}
            end
        end

		local mdl = NormalizeSetModelPath(requestedModel)
		local zcityAppearanceName
		if mdl ~= "default" then
			zcityAppearanceName = FindZCityAppearanceModel(mdl)
			if not canModerateModels and not VIP_MODEL_WHITELIST[mdl] and not zcityAppearanceName then
				ply:ChatPrint("That model is not in the approved self-service model list. Use an approved model or !setmodel default.")
				return
			end
			local usable, reason = IsUsableZCityRagdollModel(mdl)
			if not usable then
				ply:ChatPrint(reason)
				return
			end
		end

		local changed, skipped = 0, 0
		for _, target in ipairs(targets) do
			if IsValid(target) and target:Alive() then
				local applied = true
				if mdl == "default" then
					applied = RestoreSetModelAppearance(target)
				elseif zcityAppearanceName then
					applied = ApplyTemporaryZCityModel(target, mdl)
				else
					ApplyTemporaryCustomModel(target, mdl)
				end
				if applied then changed = changed + 1 else skipped = skipped + 1 end
			else
				skipped = skipped + 1
			end
		end
		if allPlayers then
			ply:ChatPrint("Updated models for " .. changed .. " players" .. (skipped > 0 and ("; skipped " .. skipped .. " dead/unavailable players") or "") .. ".")
		elseif changed > 0 then
			local who = targets[1] == ply and "Your" or (targets[1]:Name() .. "'s")
			ply:ChatPrint(mdl == "default" and (who .. " normal Z-City appearance was restored.") or (who .. " model was set to " .. mdl))
		else
			ply:ChatPrint("The player must be alive and have an available appearance to change models.")
		end
	end, 0}

	--// Aliases
	COMMANDS.model = COMMANDS.setmodel
	COMMANDS.playermodel = COMMANDS.setmodel
	COMMANDS.setplayermodel = COMMANDS.setmodel
end
