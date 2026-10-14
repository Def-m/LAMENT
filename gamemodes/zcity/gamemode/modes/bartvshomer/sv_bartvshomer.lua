local MODE = MODE

print("[BartVsHomer] sv_bartvshomer.lua reached (SERVER file, executing)")

local function Setup()
	MODE.name = "bartvshomer"
	MODE.PrintName = "Bart vs Homer"

	-- No map loot at all -- nothing spawns on its own.
	MODE.LootSpawn = false

	-- Back in the normal random/queue rotation. Still also choosable by hand
	-- via the Game Mode Manager or !setmode bartvshomer (the whitelist entry
	-- in sv_roundsystem.lua is what makes that menu show it).
	MODE.Chance = 0.02

	-- No karma loss in this mode. This is the same per-mode switch Event, DM,
	-- Chud Beasts etc. use -- the guilt system bails out early for any round
	-- with GuiltDisabled set, for both damage and kills.
	MODE.GuiltDisabled = true

	local BART_MODEL = "models/hellinspector/the_simpsons_game/bart.mdl"
	local HOMER_MODEL = "models/hellinspector/homerharm/homerfm_pm.mdl"
	local HOMER_HEALTH = 135

	-- 7 minute rounds. The round ends by itself when the timer hits zero.
	local ROUND_SECONDS = 420

	-- The base round system also has its own "too boring" cutoff measured
	-- from the start of the pre-round countdown, using this value. Without
	-- setting it, it silently inherits whatever the PREVIOUS mode used (300
	-- by default, 240 after TDM...) and would cut a 7 minute round short.
	-- Kept a bit above ROUND_SECONDS so our own timer is always what ends it.
	MODE.ROUND_TIME = ROUND_SECONDS + 30

	-- Tracked so the health-sync Think hook below knows who to poll, and so
	-- we don't touch anyone else's globals.
	local currentHomer = nil

	-- Forces the role's model on, clearing bodygroups so nothing from the
	-- player's own chosen appearance (different model's bodygroup indices)
	-- carries over and looks wrong on the new model.
	local function SetRoleModel(ply, mdl)
		ply:SetModel(mdl)
		ply:SetBodyGroups("00000000000000000000")
	end

	function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
		return 1, true
	end

	util.AddNetworkString("bartvshomer_start")
	util.AddNetworkString("bartvshomer_sound")

	-- Makes sure these ship to connecting clients even though this isn't a
	-- Workshop addon (only matters once someone other than the host joins;
	-- harmless for solo testing either way).
	resource.AddSingleFile("materials/bartvshomer/homer_calm.png")
	resource.AddSingleFile("materials/bartvshomer/homer_hurt.png")
	resource.AddSingleFile("sound/bartvshomer/round_start.mp3")
	resource.AddSingleFile("sound/bartvshomer/homer_doh.mp3")
	resource.AddSingleFile("sound/bartvshomer/homer_woohoo.mp3")

	local function BroadcastSound(key)
		net.Start("bartvshomer_sound")
			net.WriteString(key)
		net.Broadcast()
	end

	local homerHitCount = 0
	local homerWinSoundPlayed = false

	-- Keeps the bottom-right health HUD (cl_bartvshomer.lua) in sync for every
	-- client, not just Homer's. Polls Homer's real Health() directly every
	-- tick instead of trusting a single damage-event hook -- this custom
	-- damage system clearly does its own thing before health lands on the
	-- player entity, so reading the authoritative value straight off Homer
	-- is the only way this can't drift out of sync with what actually happened.
	--
	-- Also continuously re-enforces his 235 max here. Found the actual reason
	-- health kept dropping to 100: sv_metabolism.lua has a hunger/regen tick
	-- that runs "SetHealth(min(Health() + regen, 100))" -- hardcoded to 100,
	-- ignoring GetMaxHealth() entirely -- whenever org.satiety > 0. Forcing
	-- satiety to 0 every tick keeps that code path from ever firing on Homer.
	local lastSyncedHealth = 0

	hook.Add("Think", "BvH_HomerHealthSync", function()
		if not IsValid(currentHomer) then return end
		if zb.CROUND ~= "bartvshomer" then return end

		if currentHomer:GetMaxHealth() ~= HOMER_HEALTH then
			currentHomer:SetMaxHealth(HOMER_HEALTH)
		end

		if currentHomer.organism then
			currentHomer.organism.satiety = 0
		end

		local health = currentHomer:Health()

		-- HP is the only thing that's supposed to be able to kill Homer. His
		-- toughness (sv_bartvshomer_powers.lua) keeps his organs, blood and
		-- consciousness from ever failing, and this game normally kills
		-- through exactly those -- so on its own he'd just stand there at 0 HP.
		-- Enforce the HP rule directly instead.
		if health <= 0 and currentHomer:Alive() and zb.ROUND_STATE == 1 then
			currentHomer:Kill()
		end

		if health == lastSyncedHealth then return end

		if health < lastSyncedHealth then
			SetGlobalFloat("BvH_HomerLastHit", CurTime())

			homerHitCount = homerHitCount + 1
			if homerHitCount % 5 == 0 then
				BroadcastSound("doh")
			end
		end

		lastSyncedHealth = health
		SetGlobalFloat("BvH_HomerHealth", health)
	end)

	function MODE:Intermission()
		game.CleanUpMap()

		currentHomer = nil
		SetGlobalFloat("BvH_RoundEnd", 0)

		for i, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end

			ply:SetupTeam(ply:Team())
		end
	end

	function MODE:CheckAlivePlayers()
		local homerPlayers = {}
		local bartPlayers = {}

		for _, ply in ipairs(team.GetPlayers(1)) do
			if ply:Alive() then
				table.insert(homerPlayers, ply)
			end
		end

		for _, ply in ipairs(team.GetPlayers(0)) do
			if ply:Alive() then
				table.insert(bartPlayers, ply)
			end
		end

		return {homerPlayers, bartPlayers}
	end

	function MODE:ShouldRoundEnd()
		local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

		-- CheckAlivePlayers returns {homerPlayers, bartPlayers}, so winner == 1
		-- means Homer's side (index 1) is the one still standing.
		if endround and winner == 1 and not homerWinSoundPlayed then
			homerWinSoundPlayed = true
			BroadcastSound("woohoo")
		end

		if endround then return true end

		-- Time's up: the round ends by itself. Nobody got wiped out, so Homer
		-- didn't win -- no woohoo for a timeout.
		local roundEnd = GetGlobalFloat("BvH_RoundEnd", 0)
		if roundEnd > 0 and CurTime() >= roundEnd then
			return true
		end

		return endround
	end

	function MODE:EndRound()
		-- Hides the on-screen timer. Remorse handles the normal round-end transition.
		SetGlobalFloat("BvH_RoundEnd", 0)
	end

	function MODE:RoundStart()
		-- The reveal screen is sent from GiveEquipment, once every role is
		-- assigned. The 7 minutes only start counting here, after the pre-round
		-- countdown, when players can actually move.
		SetGlobalFloat("BvH_RoundEnd", CurTime() + ROUND_SECONDS)
	end

	function MODE:RoundThink()
	end

	function MODE:GiveEquipment()
		local players = {}
		for _, ply in player.Iterator() do
			if ply:Team() ~= TEAM_SPECTATOR then
				players[#players + 1] = ply
			end
		end

		table.Shuffle(players)

		local numPlayers = #players
		if numPlayers < 2 then return end

		-- Last player in the shuffled list becomes Homer; everyone else is Bart.
		for i = 1, numPlayers - 1 do
			local ply = players[i]
			ply:SetupTeam(0)
			zb.GiveRole(ply, "Bart", Color(255, 130, 0))
			SetRoleModel(ply, BART_MODEL)
		end

		local homer = players[numPlayers]
		homer:SetupTeam(1)
		zb.GiveRole(homer, "Homer", Color(90, 130, 220))
		SetRoleModel(homer, HOMER_MODEL)
		currentHomer = homer

		homer:SetMaxHealth(HOMER_HEALTH)
		homer:SetHealth(HOMER_HEALTH)
		lastSyncedHealth = HOMER_HEALTH
		homerHitCount = 0
		homerWinSoundPlayed = false
		SetGlobalFloat("BvH_RoundEnd", 0)
		SetGlobalFloat("BvH_HomerHealth", HOMER_HEALTH)
		SetGlobalFloat("BvH_HomerLastHit", -1000)

		-- Toughness (damage resistance, no fall damage, limb/organ regrowth)
		-- lives entirely in sv_bartvshomer_powers.lua -- independent from the
		-- real Juggernaut class/mode on purpose, so nothing here can touch
		-- Juggernaut's voice pack or UI. This just sets the baseline organism
		-- values that file's regrowth loop then maintains every tick.
		--
		-- superfighter is what actually grants the strength you're after --
		-- throwing carried players/props much harder, and heavy punch damage/
		-- knockback (see weapon_hands_sh.lua). It's a plain organism flag, not
		-- tied to PlayerClassName, so it can't drag Juggernaut's identity back
		-- in. One side effect worth knowing: sh_inertia.lua only excludes the
		-- speed/jump part of superfighter for PlayerClassName == "juggernaut"
		-- specifically, not by round, so Homer will also move faster and jump
		-- higher than the real Juggernaut does with the same flag. Say the
		-- word if you'd rather he stay at normal speed and I'll add a guard
		-- for that specifically.
		if homer.organism then
			homer.organism.blood = 8000
			homer.organism.maxBlood = 8000
			homer.organism.bleedingResistance = 0.2
			homer.organism.painResistance = 0.3
			homer.organism.superfighter = true
			homer.organism.satiety = 0
		end

		-- TODO: give Homer the "Crusher" ability/weapon here once we have its
		-- exact class name, e.g. homer:Give("weapon_xxx") or homer:SetPlayerClass("xxx").

		BroadcastSound("round_start")

		-- Send each client their role only after every assignment is finished,
		-- so the reveal screen on the client never races the team replication.
		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end

			net.Start("bartvshomer_start")
				net.WriteUInt(ply:Team() == 1 and 1 or 0, 1)
			net.Send(ply)
		end
	end

	function MODE:GetTeamSpawn()
		-- Team 0 = Barts (many), Team 1 = Homer (one). Reuses the shared TDM spawn
		-- points instead of needing a dedicated Point Editor group.
		local barts = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T"))
		local homer = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))

		return barts, homer
	end

	function MODE:CanLaunch()
		local activePlayers = 0

		for _, ply in player.Iterator() do
			if ply:Team() ~= TEAM_SPECTATOR then
				activePlayers = activePlayers + 1
			end
		end

		return activePlayers >= 2
	end
end

local ok, err = pcall(Setup)

if ok then
	print("[BartVsHomer] sv_bartvshomer.lua loaded OK -- MODE.name = " .. tostring(MODE.name))
else
	print("[BartVsHomer] !!! sv_bartvshomer.lua FAILED TO LOAD !!!")
	print("[BartVsHomer] Error: " .. tostring(err))
end
