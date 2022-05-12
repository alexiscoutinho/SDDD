printl("Activating Special Delivery Death's Door")

if (!IsModelPrecached("models/infected/smoker.mdl"))
	PrecacheModel("models/infected/smoker.mdl")
if (!IsModelPrecached("models/infected/smoker_l4d1.mdl"))
	PrecacheModel("models/infected/smoker_l4d1.mdl")
if (!IsModelPrecached("models/infected/boomer.mdl"))
	PrecacheModel("models/infected/boomer.mdl")
if (!IsModelPrecached("models/infected/boomer_l4d1.mdl"))
	PrecacheModel("models/infected/boomer_l4d1.mdl")
if (!IsModelPrecached("models/infected/boomette.mdl"))
	PrecacheModel("models/infected/boomette.mdl")
if (!IsModelPrecached("models/infected/hunter.mdl"))
	PrecacheModel("models/infected/hunter.mdl")
if (!IsModelPrecached("models/infected/hunter_l4d1.mdl"))
	PrecacheModel("models/infected/hunter_l4d1.mdl")
if (!IsModelPrecached("models/infected/limbs/exploded_boomette.mdl")) {
	PrecacheModel("models/infected/limbs/exploded_boomette.mdl")
	::community1_no_female_boomers <- true
}
if (!IsModelPrecached("models/infected/spitter.mdl"))
	PrecacheModel("models/infected/spitter.mdl")
if (!IsModelPrecached("models/infected/jockey.mdl"))
	PrecacheModel("models/infected/jockey.mdl")
if (!IsModelPrecached("models/infected/charger.mdl"))
	PrecacheModel("models/infected/charger.mdl")

MutationOptions <- {
	ActiveChallenge = 1

	cm_CommonLimit = 0
	cm_DominatorLimit = 8
	cm_MaxSpecials = 8
	cm_ProhibitBosses = false
	cm_SpecialRespawnInterval = 0
	cm_AggressiveSpecials = false

	SpecialInitialSpawnDelayMin = 0
	SpecialInitialSpawnDelayMax = 5
	ShouldAllowSpecialsWithTank = true
	EscapeSpawnTanks = true
	MobMinSize = 0
	MobMaxSize = 0
	NoMobSpawns = true

	SmokerLimit = 2
	BoomerLimit = 2
	HunterLimit = 2
	SpitterLimit = 2
	JockeyLimit = 2
	ChargerLimit = 2

	cm_ShouldHurry = true
	cm_AllowPillConversion = false
	cm_AllowSurvivorRescue = false
	SurvivorMaxIncapacitatedCount = 0
	TempHealthDecayRate = 0.0

	weaponsToConvert = {
		weapon_pipe_bomb = "weapon_molotov_spawn"
		weapon_first_aid_kit = "weapon_pain_pills_spawn"
		weapon_adrenaline = "weapon_pain_pills_spawn"
	}

	function ConvertWeaponSpawn( classname ) {
		if (classname in weaponsToConvert)
			return weaponsToConvert[ classname ]
		return 0
	}

	DefaultItems = [
		"weapon_pistol_magnum",
	]

	function GetDefaultItem( idx ) {
		if (idx < DefaultItems.len())
			return DefaultItems[ idx ]
		return 0
	}
}

MutationState <- {
	SIModelsBase = [
		["models/infected/smoker.mdl", "models/infected/smoker_l4d1.mdl"],
		["models/infected/boomer.mdl", "models/infected/boomer_l4d1.mdl", "models/infected/boomette.mdl"],
		["models/infected/hunter.mdl", "models/infected/hunter_l4d1.mdl"],
		["models/infected/spitter.mdl"],
		["models/infected/jockey.mdl"],
		["models/infected/charger.mdl"],
	]
	SIModels = [
		["models/infected/smoker.mdl", "models/infected/smoker_l4d1.mdl"],
		["models/infected/boomer.mdl", "models/infected/boomer_l4d1.mdl", "models/infected/boomette.mdl"],
		["models/infected/hunter.mdl", "models/infected/hunter_l4d1.mdl"],
		["models/infected/spitter.mdl"],
		["models/infected/jockey.mdl"],
		["models/infected/charger.mdl"],
	]
	ModelCheck = [false, false, false, false, false, false]
	LastBoomerModel = ""
	BoomersChecked = 0
	LeftSafeAreaThink = false
}

function LeftSafeAreaThink() {
	for (local player; player = Entities.FindByClassname( player, "player" );) {
		if (NetProps.GetPropInt( player, "m_iTeamNum" ) != 2)
			continue

		if (ResponseCriteria.GetValue( player, "instartarea" ) == "0") {
			SessionOptions.cm_MaxSpecials = 8
			SessionState.LeftSafeAreaThink = false
			break
		}
	}
}

function OnGameEvent_round_start_post_nav( params ) {
	for (local spawner; spawner = Entities.FindByClassname( spawner, "info_zombie_spawn" );) {
		local population = NetProps.GetPropString( spawner, "m_szPopulation" )

		if (population == "boomer" || population == "hunter" || population == "smoker" || population == "jockey"
			|| population == "charger" || population == "spitter" || population == "new_special" || population == "church"
			|| population == "tank" || population == "witch" || population == "witch_bride" || population == "river_docks_trap")
			continue
		else
			spawner.Kill()
	}

	if (Director.GetMapName() == "c1m1_hotel")
		DirectorOptions.cm_TankLimit <- 0
	else if (Director.GetMapName() == "c5m5_bridge" || Director.GetMapName() == "c6m3_port")
		DirectorOptions.cm_MaxSpecials = 0
	else if (Director.GetMapName() == "c7m1_docks")
		DirectorOptions.cm_ProhibitBosses = true
}

function OnGameEvent_player_left_safe_area( params ) {
	DirectorOptions.TempHealthDecayRate = 0.27

	local player = GetPlayerFromUserID( params.userid )
	if (!player)
		return

	if (ResponseCriteria.GetValue( player, "instartarea" ) == "1") {
		SessionOptions.cm_MaxSpecials = 0
		SessionState.LeftSafeAreaThink = true
	}
}

function OnGameEvent_triggered_car_alarm( params ) {
	if (!Director.IsTankInPlay()) {
		DirectorOptions.cm_AggressiveSpecials = true
		ZSpawn( {type = 8} )
		DirectorOptions.cm_AggressiveSpecials = false
	}

	StartAssault()
}

function OnGameEvent_finale_start( params ) {
	if (Director.GetMapName() == "c6m3_port")
		DirectorOptions.cm_MaxSpecials = 8
}

function OnGameEvent_gauntlet_finale_start( params ) {
	if (Director.GetMapName() == "c5m5_bridge")
		DirectorOptions.cm_MaxSpecials = 8
}

function OnGameEvent_player_spawn( params ) {
	local player = GetPlayerFromUserID( params.userid )

	if (!player || player.IsSurvivor())
		return

	local zombieType = player.GetZombieType()
	if (zombieType > 6)
		return

	local modelName = player.GetModelName()

	if (!SessionState.ModelCheck[ zombieType - 1 ]) {
		if (zombieType == 2 && !("community1_no_female_boomers" in getroottable())) {
			if (SessionState.LastBoomerModel != modelName) {
				SessionState.LastBoomerModel = modelName
				SessionState.BoomersChecked++
			}
			if (SessionState.BoomersChecked > 1)
				SessionState.ModelCheck[ zombieType - 1 ] = true
		}
		else
			SessionState.ModelCheck[ zombieType - 1 ] = true

		if (SessionState.SIModelsBase[ zombieType - 1 ].find( modelName ) == null) {
			SessionState.SIModelsBase[ zombieType - 1 ].append( modelName )
			SessionState.SIModels[ zombieType - 1 ].append( modelName )
		}
	}

	if (SessionState.SIModelsBase[ zombieType - 1 ].len() == 1)
		return

	local zombieModels = SessionState.SIModels[ zombieType - 1 ]
	if (zombieModels.len() == 0)
		SessionState.SIModels[ zombieType - 1 ].extend( SessionState.SIModelsBase[ zombieType - 1 ] )
	local foundModel = zombieModels.find( modelName )
	if (foundModel != null) {
		zombieModels.remove( foundModel )
		return
	}

	local randomElement = RandomInt( 0, zombieModels.len() - 1 )
	local randomModel = zombieModels[ randomElement ]
	zombieModels.remove( randomElement )

	player.SetModel( randomModel )
}

function OnGameEvent_round_start( params ) {
	Convars.SetValue( "pain_pills_decay_rate", 0.0 )
}

function OnGameEvent_player_hurt_concise( params ) {
	local player = GetPlayerFromUserID( params.userid )
	if (!player || !player.IsSurvivor() || player.IsHangingFromLedge())
		return

	if (NetProps.GetPropInt( player, "m_bIsOnThirdStrike" ) == 0 && player.GetHealth() < player.GetMaxHealth() / 4) {
		player.SetReviveCount( 0 )
		NetProps.SetPropInt( player, "m_isGoingToDie", 1 )
	}
}

function OnGameEvent_defibrillator_used( params ) {
	local player = GetPlayerFromUserID( params.subject )
	if (!player || !player.IsSurvivor())
		return

	player.SetHealth( 24 )
	player.SetHealthBuffer( 36 )
	player.SetReviveCount( 0 )
	NetProps.SetPropInt( player, "m_isGoingToDie", 1 )
}

function CheckHealthAfterLedgeHang( userid ) {
	local player = GetPlayerFromUserID( userid )
	if (!player || !player.IsSurvivor())
		return

	if (player.GetHealth() < player.GetMaxHealth() / 4) {
		player.SetReviveCount( 0 )
		NetProps.SetPropInt( player, "m_isGoingToDie", 1 )
	}
}

function OnGameEvent_revive_success( params ) {
	local player = GetPlayerFromUserID( params.subject )
	if (!params.ledge_hang || !player || !player.IsSurvivor())
		return

	if (NetProps.GetPropInt( player, "m_bIsOnThirdStrike" ) == 0)
		EntFire( "worldspawn", "RunScriptCode", "g_ModeScript.CheckHealthAfterLedgeHang(" + params.subject + ")", 0.1 )
}

function OnGameEvent_bot_player_replace( params ) {
	local player = GetPlayerFromUserID( params.player )
	if (!player || NetProps.GetPropInt( player, "m_bIsOnThirdStrike" ) == 1)
		return

	StopSoundOn( "Player.Heartbeat", player )
}

if (!Director.IsSessionStartMap()) {
	function PlayerSpawnDeadAfterTransition( userid ) {
		local player = GetPlayerFromUserID( userid )
		if (!player)
			return

		player.SetHealth( 24 )
		player.SetHealthBuffer( 26 )
		player.SetReviveCount( 0 )
		NetProps.SetPropInt( player, "m_isGoingToDie", 1 )
	}

	function PlayerSpawnAliveAfterTransition( userid ) {
		local player = GetPlayerFromUserID( userid )
		if (!player)
			return

		local maxHealth = player.GetMaxHealth()
		local oldHealth = player.GetHealth()
		local maxHeal = maxHealth / 2
		local healAmount = 0

		if (oldHealth < maxHeal)
			healAmount = floor( (maxHeal - oldHealth) * 0.8 + 0.5 )

		if (healAmount > 0) {
			player.SetHealth( oldHealth + healAmount )
			local bufferHealth = player.GetHealthBuffer() - healAmount
			if (bufferHealth < 0.0)
				bufferHealth = 0.0
			player.SetHealthBuffer( bufferHealth )
		}
		NetProps.SetPropInt( player, "m_bIsOnThirdStrike", 0 )
		NetProps.SetPropInt( player, "m_isGoingToDie", 0 )
	}

	function OnGameEvent_player_transitioned( params ) {
		local player = GetPlayerFromUserID( params.userid )
		if (!player || !player.IsSurvivor())
			return

		if (NetProps.GetPropInt( player, "m_lifeState" ) == 2)
			EntFire( "worldspawn", "RunScriptCode", "g_ModeScript.PlayerSpawnDeadAfterTransition(" + params.userid + ")", 0.1 )
		else
			EntFire( "worldspawn", "RunScriptCode", "g_ModeScript.PlayerSpawnAliveAfterTransition(" + params.userid + ")", 0.1 )
	}
}

function Update() {
	if (SessionState.LeftSafeAreaThink)
		LeftSafeAreaThink()
	if (Director.GetCommonInfectedCount() > 0) {
		for (local infected; infected = Entities.FindByClassname( infected, "infected" );)
			infected.Kill()
	}
}