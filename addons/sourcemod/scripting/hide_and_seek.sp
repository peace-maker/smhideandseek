#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"

#define PREFIX "\x04Hide and Seek \x01> \x03"

// plugin cvars
new Handle:hns_cfg_enable = INVALID_HANDLE;
new Handle:hns_cfg_freezects = INVALID_HANDLE;
new Handle:hns_cfg_freezetime = INVALID_HANDLE;
new Handle:hns_cfg_changelimit = INVALID_HANDLE;
new Handle:hns_cfg_changelimittime = INVALID_HANDLE;
new Handle:hns_cfg_autochoose = INVALID_HANDLE;
new Handle:hns_cfg_whistle = INVALID_HANDLE;
new Handle:hns_cfg_whistle_times = INVALID_HANDLE;
new Handle:hns_cfg_anticheat = INVALID_HANDLE;
new Handle:hns_cfg_cheat_punishment = INVALID_HANDLE;
new Handle:hns_cfg_hider_win_frags = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_enable = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_dec = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_inc = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_bonus = INVALID_HANDLE;
new Handle:hns_cfg_opacity_enable = INVALID_HANDLE;
new Handle:hns_cfg_hidersspeed = INVALID_HANDLE;
new Handle:hns_cfg_disable_rightknife = INVALID_HANDLE;
new Handle:hns_cfg_disable_ducking = INVALID_HANDLE;
new Handle:hns_cfg_auto_thirdperson = INVALID_HANDLE;

// primary enableswitch
new bool:g_EnableHnS = true;

// config and menu handles
new Handle:mainmenu;
new Handle:kv;

// offsets
new g_WeaponParent;
new g_Render;

new bool:g_InThirdPersonView[MAXPLAYERS+1] = {false,...};

new g_FirstCTSpawn = 0;
new Handle:g_ShowCountdownTimer = INVALID_HANDLE;
new Handle:g_SpamCommandsTimer = INVALID_HANDLE;

// Cheat cVar part
new Handle:g_CheckVarTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new String:cheat_commands[][] = {"cl_radaralpha", "overview_preferred_mode"};
new bool:g_ConVarViolation[MAXPLAYERS+1][2]; // 2 = amount of cheat_commands. update if you add one.
new g_ConVarMessage[MAXPLAYERS+1][2]; // 2 = amount of cheat_commands. update if you add one.
new Handle:g_CheatPunishTimer[MAXPLAYERS+1] = {INVALID_HANDLE};

// Terrorist Modelchange stuff
new g_TotalModelsAvailable = 0;
new g_ModelChangeCount[MAXPLAYERS+1] = {0,...};
new bool:g_AllowModelChange[MAXPLAYERS+1] = {true,...};
new Handle:g_AllowModelChangeTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};

new bool:g_IsCTWaiting[MAXPLAYERS+1] = {false,...};
new Handle:g_UnfreezeCTTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};

// protected server cvars
new String:protected_cvars[][] = {"mp_flashlight", 
								  "sv_footsteps", 
								  "mp_limitteams", 
								  "mp_autoteambalance", 
								  "mp_freezetime", 
								  "sv_alltalk", 
								  "sv_nonemesis", 
								  "sv_nomvp", 
								  "sv_nostats", 
								  "mp_playerid",
								  "sv_allowminmodels"
								 };
new forced_values[] = {0, // mp_flashlight
					   0, // sv_footsteps
					   0, // mp_limitteams
					   0, // mp_autoteambalance
					   0, // mp_freezetime
					   1, // sv_alltalk
					   1, // sv_nonemesis
					   1, // sv_nomvp
					   1, // sv_nostats
					   1, // mp_playerid
					   0 //sv_allowminmodels
					  };
new previous_values[11] = {0,...}; // save previous values when forcing above, so we can restore the config if hns is disabled midgame. !same as comment next line!
new Handle:g_ProtectedConvar[11] = {INVALID_HANDLE,...}; // 11 = amount of protected_cvars. update if you add one.
new Handle:g_forceCamera = INVALID_HANDLE;

// whistle sounds
new g_WhistleCount[MAXPLAYERS+1] = {0,...};
new String:whistle_sounds[][] = {"ambient/animal/cow.wav", "ambient/animal/horse_4.wav", "ambient/animal/horse_5.wav", "ambient/machines/train_horn_3.wav", "ambient/misc/creak3.wav", "doors/door_metal_gate_close1.wav", "ambient/misc/flush1.wav"};

public Plugin:myinfo = 
{
	name = "Hide and Seek",
	author = "Vladislav Dolgov and Jannik Hartung",
	description = "Terrorists set a model and hide, CT seek terrorists.",
	version = PLUGIN_VERSION,
	url = "http://www.elistor.ru/ | http://www.wcfan.de/"
};

public OnPluginStart()
{
	CreateConVar("sm_hns_version", PLUGIN_VERSION, "Hide and seek", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Config cvars
	hns_cfg_enable = 			CreateConVar("sm_hns_enable", "1", "Enable the Hide and Seek Mod?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_freezects = 		CreateConVar("sm_hns_freezects", "1", "Should CTs get freezed and blinded on spawn?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_freezetime = 		CreateConVar("sm_hns_freezetime", "25.0", "How long should the CTs are freezed after spawn?", FCVAR_PLUGIN, true, 1.00, true, 120.00);
	hns_cfg_changelimit = 		CreateConVar("sm_hns_changelimit", "2", "How often a T is allowed to choose his model ingame? 0 = unlimited", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_changelimittime = 	CreateConVar("sm_hns_changelimittime", "30.0", "How long should a T be allowed to change his model again after spawn?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_autochoose = 		CreateConVar("sm_hns_autochoose", "0", "Should the plugin choose models for the hiders automatically?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_whistle = 			CreateConVar("sm_hns_whistle", "1", "Are terrorists allowed to whistle?", FCVAR_PLUGIN);
	hns_cfg_whistle_times = 	CreateConVar("sm_hns_whistle_times", "5", "How many times a hider is allowed to whistle per round?", FCVAR_PLUGIN);
	hns_cfg_anticheat = 		CreateConVar("sm_hns_anticheat", "1", "Check player cheat convars, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_cheat_punishment = 	CreateConVar("sm_hns_cheat_punishment", "1", "How to punish players with wrong cvar values after 15 seconds? 0: Disabled. 1: Switch to Spectator. 2: Kick", FCVAR_PLUGIN, true, 0.00, true, 2.00);
	hns_cfg_hider_win_frags = 	CreateConVar("sm_hns_hider_win_frags", "5", "How many frags should surviving terrorists gain?", FCVAR_PLUGIN, true, 0.00, true, 10.00);
	hns_cfg_hp_seeker_enable = 	CreateConVar("sm_hns_hp_seeker_enable", "1", "Should CT lose HP when shooting, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_hp_seeker_dec = 	CreateConVar("sm_hns_hp_seeker_dec", "5", "How many hp should a CT lose on shooting?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_hp_seeker_inc = 	CreateConVar("sm_hns_hp_seeker_inc", "15", "How many hp should a CT gain when hitting a hider?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_hp_seeker_bonus = 	CreateConVar("sm_hns_hp_seeker_bonus", "50", "How many hp should a CT gain when killing a hider?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_opacity_enable = 	CreateConVar("sm_hns_opacity_enable", "0", "Should T get more invisible on low hp, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_hidersspeed  = 		CreateConVar("sm_hns_hidersspeed", "1.00", "Hiders speed (Default: 1.00).", FCVAR_PLUGIN, true, 0.00, true, 3.00);
	hns_cfg_disable_rightknife =CreateConVar("sm_hns_disable_rightknife", "1", "Disable rightclick for CTs with knife? Prevents knifing without losing heatlh. (Default: 1).", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_disable_ducking =	CreateConVar("sm_hns_disable_ducking", "0", "Disable ducking. (Default: 0).", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_auto_thirdperson =	CreateConVar("sm_hns_auto_thirdperson", "1", "Enable thirdperson view for hiders automatically (Default: 1).", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	
	g_EnableHnS = GetConVarBool(hns_cfg_enable);
	HookConVarChange(hns_cfg_enable, Cfg_OnChangeEnable);
	
	if(g_EnableHnS)
	{
		// !ToDo: Exclude hooks and other EnableHnS dependand functions into one seperate function.
		// Now you need to add the hooks to the Cfg_OnChangeEnable callback too..
		HookConVarChange(hns_cfg_hidersspeed, OnChangeHiderSpeed);
		HookConVarChange(hns_cfg_anticheat, OnChangeAntiCheat);
		
		// Hooking events
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		HookEvent("player_hurt", Event_OnPlayerHurt);
		HookEvent("weapon_fire", Event_OnWeaponFire);
		HookEvent("player_death", Event_OnPlayerDeath);
		HookEvent("round_start", Event_OnRoundStart);
		HookEvent("round_end", Event_OnRoundEnd);
		HookEvent("item_pickup", Event_OnItemPickup);
	}
	
	
	// Register console commands
	RegConsoleCmd("hide", Menu_SelectModel);
	RegConsoleCmd("hidemenu", Menu_SelectModel);
	RegConsoleCmd("tp", Third_Person);
	RegConsoleCmd("thirdperson", Third_Person);
	RegConsoleCmd("third", Third_Person);
	RegConsoleCmd("jointeam", Command_JoinTeam);
	RegConsoleCmd("whistle", Play_Whistle);
	RegConsoleCmd("whoami", Display_ModelName);
	RegConsoleCmd("overview_mode", Block_Cmd);
	
	RegAdminCmd("sm_hns_force_whistle", ForceWhistle, ADMFLAG_CHAT, "Force a player to whistle");
		
	// Loading translations
	LoadTranslations("plugin.hide_and_seek");
	LoadTranslations("common.phrases"); // for FindTarget()
	
	
	// set the default values for cvar checking
	for(new x=0;x<MaxClients;x++)
		for(new y=0;y<sizeof(cheat_commands);y++)
		{
			g_ConVarViolation[x][y] = false;
			g_ConVarMessage[x][y] = 0;
		}
	
	if(g_EnableHnS)
	{
		// set bad server cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			g_ProtectedConvar[i] = FindConVar(protected_cvars[i]);
			previous_values[i] = GetConVarInt(g_ProtectedConvar[i]);
			SetConVarInt(g_ProtectedConvar[i], forced_values[i], true);
			HookConVarChange(g_ProtectedConvar[i], OnCvarChange);
		}
		// start advertising spam
		g_SpamCommandsTimer = CreateTimer(120.0, SpamCommands, 0);
	}
	
	// hook forcecamera
	g_forceCamera = FindConVar("mp_forcecamera");
	
	// get the offsets
	// for weapon stripping without sdkhooks
	g_WeaponParent = 	FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	if(g_WeaponParent == -1)
		SetFailState("Couldnt find the m_hOwnerEntity offset!");
	
	// for transparency
	g_Render = 			FindSendPropOffs("CAI_BaseNPC", "m_clrRender");
	if(g_Render == -1)
		SetFailState("Couldnt find the m_clrRender offset!");
	
	AutoExecConfig(true, "plugin.hide_and_seek");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SDKHook");
	MarkNativeAsOptional("SDKUnhook");
	return APLRes_Success;
}

/*
* 
* Generic Events
* 
*/ 
public OnMapStart()
{
	if(!g_EnableHnS)
		return;
	
	mainmenu = BuildMainMenu();
	for(new i=0;i<sizeof(whistle_sounds);i++)
		PrecacheSound(whistle_sounds[i], true);
	
	PrecacheSound("radio/go.wav", true);
	
	// prevent us from bugging after mapchange
	g_FirstCTSpawn = 0;
	
	if(g_ShowCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_ShowCountdownTimer);
		g_ShowCountdownTimer = INVALID_HANDLE;
	}
	
	new bool:foundHostageZone = false;
	
	// check if there is a hostage rescue zone
	new maxent = GetMaxEntities(), String:eName[64];
	for (new i=MaxClients;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, eName, sizeof(eName));
			if(StrContains(eName, "func_hostage_rescue") != -1)
			{
				foundHostageZone = true;
			}
		}
	}
	
	// add a hostage rescue zone if there isn't one, so T will win after round time
	if(!foundHostageZone)
	{
		new ent = CreateEntityByName("func_hostage_rescue");
		if (ent>0)
		{
			new Float:orign[3] = {-1000.0,...};
			DispatchKeyValue(ent, "targetname", "hidenseek_roundend");
			DispatchKeyValueVector(ent, "orign", orign);
			DispatchSpawn(ent);
		}
	}
}

public OnMapEnd()
{
	if(!g_EnableHnS)
		return;
	
	CloseHandle(kv);
	CloseHandle(mainmenu);
}

public OnClientPutInServer(client)
{
	if(!g_EnableHnS)
		return;
	
	if(!IsFakeClient(client) && GetConVarBool(hns_cfg_anticheat))
		g_CheckVarTimer[client] = CreateTimer(1.0, StartVarChecker, client, TIMER_REPEAT);
	
	// Hook weapon pickup
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnClientDisconnect(client)
{
	if(!g_EnableHnS)
		return;
	
	// set the default values for cvar checking
	if(!IsFakeClient(client))
	{
		for(new i=0;i<sizeof(cheat_commands);i++)
		{
			g_ConVarViolation[client][i] = false;
			g_ConVarMessage[client][i] = 0;
		}
	
		g_InThirdPersonView[client] = false;
		g_ModelChangeCount[client] = 0;
		g_IsCTWaiting[client] = false;
		g_WhistleCount[client] = 0;
		if (g_CheatPunishTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_CheatPunishTimer[client]);
			g_CheatPunishTimer[client] = INVALID_HANDLE;
		}
		if (g_AllowModelChange[client] && g_AllowModelChangeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_AllowModelChangeTimer[client]);
			g_AllowModelChangeTimer[client] = INVALID_HANDLE;
		}
		if(g_UnfreezeCTTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_UnfreezeCTTimer[client]);
			g_UnfreezeCTTimer[client] = INVALID_HANDLE;
		}
	}
	g_AllowModelChange[client] = true;
	
	/*if (g_CheckVarTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_CheckVarTimer[client]);
		g_CheckVarTimer[client] = INVALID_HANDLE;
	}*/
}

// prevent players from ducking
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	decl String:weaponName[30];
	// don't allow ct's to shoot in the beginning of the round
	new team = GetClientTeam(client);
	GetClientWeapon(client, weaponName, sizeof(weaponName));
	if(team == 3 && g_IsCTWaiting[client] && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
	{
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
	} // disable rightclick knifing for cts
	else if(team == 3 && GetConVarBool(hns_cfg_disable_rightknife) && buttons & IN_ATTACK2 && !strcmp(weaponName, "weapon_knife"))
	{
		buttons &= ~IN_ATTACK2;
	}
	
	// disable ducking for everyone
	if(buttons & IN_DUCK && GetConVarBool(hns_cfg_disable_ducking))
		buttons &= ~IN_DUCK;
	
	return Plugin_Continue;
}

// SDKHook Callback
public Action:OnWeaponCanUse(client, weapon)
{
	// Allow only CTs to use a weapon
	if(g_EnableHnS && GetClientTeam(client) != 3)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


/*
* 
* Hooked Events
* 
*/
// Player Spawn event
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if(team <= 1 || !IsPlayerAlive(client))
		return Plugin_Continue;
	else if(team == 2) // Team T
	{
		// set the mp_forcecamera value correctly, so he can use thirdperson again
		if(!IsFakeClient(client) && GetConVarInt(g_forceCamera) == 1)
			SendConVarValue(client, g_forceCamera, "0");
		
		// reset model change count
		g_ModelChangeCount[client] = 0;
		g_InThirdPersonView[client] = false;
		if(!IsFakeClient(client) && g_AllowModelChangeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_AllowModelChangeTimer[client]);
			g_AllowModelChangeTimer[client] = INVALID_HANDLE;
		}
		g_AllowModelChange[client] = true;
		
		// hacky way of avoiding Ts to pickup weapons if no sdkhooks extension is loaded.
		if(!LibraryExists("sdkhooks"))
			CreateTimer(0.0, StripWeapons, client);
		
		// set the speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(hns_cfg_hidersspeed));
		
		// reset the transparent
		if(GetConVarBool(hns_cfg_opacity_enable))
		{
			SetEntData(client,g_Render+3,255,1,true);
			SetEntityRenderMode(client, RENDER_TRANSTEXTURE);
		}
		
		// Assign a model to bots immediately and disable all menus or timers.
		if(IsFakeClient(client))
			g_AllowModelChangeTimer[client] = CreateTimer(0.1, DisableModelMenu, client);
		else
		{
			g_AllowModelChangeTimer[client] = CreateTimer(GetConVarFloat(hns_cfg_changelimittime), DisableModelMenu, client);
			// Set them to thirdperson automatically
			if(GetConVarBool(hns_cfg_auto_thirdperson))
				Third_Person(client, 2);
		}
		
		g_WhistleCount[client] = 0;
		
		if(GetConVarBool(hns_cfg_autochoose))
			SetRandomModel(client);
		else
			DisplayMenu(mainmenu, client, RoundToFloor(GetConVarFloat(hns_cfg_changelimittime)));
		
		if(GetConVarBool(hns_cfg_freezects))
			PrintToChat(client, "%s%t", PREFIX, "seconds to hide", RoundToFloor(GetConVarFloat(hns_cfg_freezetime)));
		else
			PrintToChat(client, "%s%t", PREFIX, "seconds to hide", 0);
	}
	else if(team == 3) // Team CT
	{
		if(!IsFakeClient(client) && GetConVarInt(g_forceCamera) == 1)
			SendConVarValue(client, g_forceCamera, "1");
		
		new currentTime = GetTime();
		new Float:freezeTime = GetConVarFloat(hns_cfg_freezetime);
		// don't keep late spawning cts blinded longer than the others :)
		if(g_FirstCTSpawn == 0)
		{
			if(g_ShowCountdownTimer != INVALID_HANDLE)
			{
				KillTimer(g_ShowCountdownTimer);
				g_ShowCountdownTimer = INVALID_HANDLE;
			}
			else if(GetConVarBool(hns_cfg_freezects))
			{
				// show time in center
				g_ShowCountdownTimer = CreateTimer(0.01, ShowCountdown, RoundToFloor(GetConVarFloat(hns_cfg_freezetime)));
			}
			g_FirstCTSpawn = currentTime;
		}
		// only freeze spawning players if the freezetime is still running.
		if(GetConVarBool(hns_cfg_freezects) && (float(currentTime - g_FirstCTSpawn) < freezeTime))
		{
			// Start freezing player
			CreateTimer(0.05, FreezePlayer, client);
			
			if(g_UnfreezeCTTimer[client] != INVALID_HANDLE)
			{
				KillTimer(g_UnfreezeCTTimer[client]);
				g_UnfreezeCTTimer[client] = INVALID_HANDLE;
			}
			
			// Stop freezing player
			g_UnfreezeCTTimer[client] = CreateTimer(freezeTime-float(currentTime - g_FirstCTSpawn), UnFreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			
			PrintToChat(client, "%s%t", PREFIX, "Wait for t to hide", RoundToFloor(freezeTime-float(currentTime - g_FirstCTSpawn)));
			g_IsCTWaiting[client] = true;
		}
	}
	
	return Plugin_Continue;
}

// subtract 5hp for every shot a seeker is giving
public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hns_cfg_hp_seeker_enable))
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new decreaseHP = GetConVarInt(hns_cfg_hp_seeker_dec);
	new clientHealth = GetClientHealth(client);
	
	// he can take it
	if((clientHealth-decreaseHP) > 0)
	{
		SetEntityHealth(client, (clientHealth-decreaseHP));
	}
	else // slay him
	{
		ForcePlayerSuicide(client);
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// remove bombzones and hostages so no normal gameplay could end the round
	new maxent = GetMaxEntities(), String:eName[64];
	for (new i=MaxClients;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, eName, sizeof(eName));
			if ( StrContains(eName, "hostage_entity") != -1 || StrContains(eName, "func_bomb_target") != -1 )
			{
				RemoveEdict(i);
			}
		}
	}
}
// give terrorists frags
public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_FirstCTSpawn = 0;
	
	if(g_ShowCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_ShowCountdownTimer);
		g_ShowCountdownTimer = INVALID_HANDLE;
	}
	
	new winnerTeam = GetEventInt(event, "winner");
	
	if(winnerTeam == 2)
	{
		new increaseFrags = GetConVarInt(hns_cfg_hider_win_frags);
		
		if(increaseFrags == 0)
			return Plugin_Continue;
		
		new bool:aliveTerrorists = false;
		// increase playerscore of all alive Terrorists
		for(new i=1;i<MaxClients;i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				// increase kills by x
				SetEntProp(i, Prop_Data, "m_iFrags", GetClientFrags(i) + increaseFrags);
				aliveTerrorists = true;
			}
		}
		
		if(aliveTerrorists)
			PrintToChatAll("%s%t", PREFIX, "got frags", increaseFrags);
	}
	return Plugin_Continue;
}

// set a normal model right before death to avoid errors
public Action:Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new remainingHeatlh = GetEventInt(event, "health");
	
	if(GetClientTeam(client) == 2)
	{
		// prevent errors in console because of missing death animation of prop ;)
		if(remainingHeatlh <= 0)
			SetEntityModel(client, "models/player/t_guerilla.mdl");
		else if(GetConVarBool(hns_cfg_opacity_enable))
		{
			new alpha = 150 + RoundToNearest(10.5*float(remainingHeatlh/10));			
			
			SetEntData(client,g_Render+3,alpha,1,true);
			SetEntityRenderMode(client, RENDER_TRANSTEXTURE);
		}
		
		// attacker is a human?
		if(GetConVarBool(hns_cfg_hp_seeker_enable) && attacker > 0 && attacker < MaxClients && IsPlayerAlive(attacker))
		{
			new decrease = GetConVarInt(hns_cfg_hp_seeker_dec);
			
			SetEntityHealth(attacker, GetClientHealth(attacker)+GetConVarInt(hns_cfg_hp_seeker_inc)+decrease);
			
			// the hider died? give extra health! need to add the decreased value again, since he fired his gun and lost hp.
			// possible "bug": seeker could be slayed because weapon_fire is called earlier than player_hurt.
			if(remainingHeatlh <= 0)
				SetEntityHealth(attacker, GetClientHealth(attacker)+GetConVarInt(hns_cfg_hp_seeker_bonus)+decrease);
		}
	}
	return Plugin_Continue;
}

// remove ragdolls on death...
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// set the mp_forcecamera value correctly, so he can watch his teammates
	// This doesn't work. Even if the convar is set to 0, the hiders are only able to spectate their teammates..
	if(GetConVarInt(g_forceCamera) == 1)
	{
		if(!IsFakeClient(client) && GetClientTeam(client) != 2)
			SendConVarValue(client, g_forceCamera, "1");
		else if(!IsFakeClient(client))
			SendConVarValue(client, g_forceCamera, "0");
	}
	
	if (!IsValidEntity(client) || IsPlayerAlive(client))
		return;
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0) 
		return;
	
	RemoveEdict(ragdoll);
}

// let t drop every weapon
public Action:Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(LibraryExists("sdkhooks"))
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == 2)
	{
		CreateTimer(0.01, StripWeapons, client);
	}
}

/*
* 
* Timer Callbacks
* 
*/

// Freeze player function
public Action:FreezePlayer(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_NONE);
	PerformBlind(client, 255);
}

// Unfreeze player function
public Action:UnFreezePlayer(Handle:timer, any:client)
{
	
	g_UnfreezeCTTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	if(!IsConVarCheater(client))
		PerformBlind(client, 0);
	
	g_IsCTWaiting[client] = false;
	
	EmitSoundToClient(client, "radio/go.wav");
	
	PrintToChat(client, "%s%t", PREFIX, "Go search");
		
	return Plugin_Handled;
}

public Action:DisableModelMenu(Handle:timer, any:client)
{
	
	g_AllowModelChangeTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	g_AllowModelChange[client] = false;
	
	if(IsPlayerAlive(client))
		PrintToChat(client, "%s%t", PREFIX, "Modelmenu Disabled");
	
	// didn't he chose a model?
	if(GetClientTeam(client) == 2 && g_ModelChangeCount[client] == 0)
	{
		// give him a random one.
		SetRandomModel(client);
	}
	
	return Plugin_Handled;
}

public Action:StartVarChecker(Handle:timer, any:client)
{	
	if (!IsClientInGame(client))
		return Plugin_Handled;
	
	// allow watching
	if(GetClientTeam(client) < 2)
	{
		PerformBlind(client, 0);
		return Plugin_Continue;
	}
	
	// check all defined cvars for value "0"
	for(new i=0;i<sizeof(cheat_commands);i++)
		QueryClientConVar(client, cheat_commands[i], ConVarQueryFinished:ClientConVar, client);
	
	if(IsConVarCheater(client))
	{
		// Blind and Freeze player
		PerformBlind(client, 255);
		SetEntityMoveType(client, MOVETYPE_NONE);
		
		if(GetConVarInt(hns_cfg_cheat_punishment) != 0 && g_CheatPunishTimer[client] == INVALID_HANDLE)
		{
			g_CheatPunishTimer[client] = CreateTimer(15.0, PerformCheatPunishment, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(!g_IsCTWaiting[client])
	{
		if(IsPlayerAlive(client))
			SetEntityMoveType(client, MOVETYPE_WALK);
		PerformBlind(client, 0);
	}
	
	return Plugin_Continue;
}

public Action:PerformCheatPunishment(Handle:timer, any:client)
{
	g_CheatPunishTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client) || !IsConVarCheater(client))
		return Plugin_Handled;
	
	new punishmentType = GetConVarInt(hns_cfg_cheat_punishment);
	if(punishmentType == 1 && GetClientTeam(client) != 1 )
	{
		ChangeClientTeam(client, 1);
		PrintToChatAll("%s%N %t", PREFIX, client, "Spectator Cheater");
	}
	else if(punishmentType == 2)
	{
		for(new i=0;i<sizeof(cheat_commands);i++)
			if(g_ConVarViolation[client][i])
				PrintToConsole(client, "Hide and Seek: %t %s 0", "Print to console", cheat_commands[i]);
		KickClient(client, "Hide and Seek: %t", "Kick bad cvars");
	}
	return Plugin_Handled;
}

// teach the players the /whistle and /tp commands
public Action:SpamCommands(Handle:timer, any:data)
{
	if(GetConVarBool(hns_cfg_whistle) && data == 1)
		PrintToChatAll("%s%t", PREFIX, "T type /whistle");
	else if(!GetConVarBool(hns_cfg_whistle) || data == 0)
	{
		for(new i=1;i<=MaxClients;i++)
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
				PrintToChat(i, "%s%t", PREFIX, "T type /tp");
	}
	g_SpamCommandsTimer = CreateTimer(120.0, SpamCommands, (data==0?1:0));
	return Plugin_Handled;
}

// show all players a countdown
// CT: I'm coming!
public Action:ShowCountdown(Handle:timer, any:seconds)
{
	PrintCenterTextAll("%d", seconds);
	seconds--;
	if(seconds <= 0)
	{
		g_ShowCountdownTimer = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	g_ShowCountdownTimer = CreateTimer(1.0, ShowCountdown, seconds);
	
	return Plugin_Handled;
}

/*
* 
* Console Command Handling
* 
*/

// say /hide /hidemenu
public Action:Menu_SelectModel(client,args)
{
	if (!g_EnableHnS || mainmenu == INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) == 2)
	{
		new changeLimit = GetConVarInt(hns_cfg_changelimit);
		if(g_AllowModelChange[client] && (changeLimit == 0 || g_ModelChangeCount[client] < (changeLimit+1)))
		{
			if(GetConVarBool(hns_cfg_autochoose))
				SetRandomModel(client);
			else
				DisplayMenu(mainmenu, client, RoundToFloor(GetConVarFloat(hns_cfg_changelimittime)));
		}
		else
			PrintToChat(client, "%s%t", PREFIX, "Modelmenu Disabled");
	}
	else
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can select models");
	}
	return Plugin_Handled;
}

// say /tp /third /thirdperson
public Action:Third_Person(client, args)
{
	if (!g_EnableHnS || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// Only allow Terrorists to use thirdperson view
	if(GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(!g_InThirdPersonView[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		g_InThirdPersonView[client] = true;
		// hacky way of not showing the message if autochoose is enabled
		if(args != 2)
			PrintToChat(client, "%s%t", PREFIX, "Type again for ego");
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		g_InThirdPersonView[client] = false;
	}
	
	return Plugin_Handled;
}

// jointeam command
// handle the team sizes
public Action:Command_JoinTeam(client, args)
{
	if (!g_EnableHnS || !client || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	StripQuotes(text);
	
	new ClientCount = GetClientCount();
	new TeamClientCount = GetTeamClientCount(3);
	
	// player wants to join the CT team
	if(strcmp(text, "3", false) == 0)
	{
		// up to 5 clients on server?
		if (ClientCount <= 5)
		{
			// only allow 1 ct
			if(TeamClientCount >= 1)
			{
				PrintCenterText(client, "%t", "CT team is full");
				return Plugin_Handled;					
			}
		}
		else if (6 <= ClientCount <= 8)
		{
			if(TeamClientCount >= 2)
			{
				PrintCenterText(client, "%t", "CT team is full");
				return Plugin_Handled;					
			}
		}
		else if (9 <= ClientCount <= 14)
		{
			if(TeamClientCount >= 3)
			{
				PrintCenterText(client, "%t", "CT team is full");
				return Plugin_Handled;					
			}
		}
		else if (15 <= ClientCount <= 18)
		{
			if(TeamClientCount >= 4)
			{
				PrintCenterText(client, "%t", "CT team is full");
				return Plugin_Handled;					
			}
		}
		else
		{
			if(TeamClientCount >= 5)
			{
				PrintCenterText(client, "%t", "CT team is full");
				return Plugin_Handled;					
			}
		}
	}
	else if(strcmp(text, "2", false) == 0)
	{
		if(!IsFakeClient(client) && GetConVarInt(g_forceCamera) == 1)
			SendConVarValue(client, g_forceCamera, "0");
		return Plugin_Continue;
	}
	// allow all other teamchanges...
	
	if(!IsFakeClient(client) && GetConVarInt(g_forceCamera) == 1)
		SendConVarValue(client, g_forceCamera, "1");
	
	return Plugin_Continue;
}

// say /whistle
// plays a random sound loudly
public Action:Play_Whistle(client,args)
{
	// check if whistling is enabled
	if(!g_EnableHnS || !GetConVarBool(hns_cfg_whistle) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// only Ts are allowed to whistle
	if(GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	new cvarWhistleTimes = GetConVarInt(hns_cfg_whistle_times);
	
	if(g_WhistleCount[client] < cvarWhistleTimes)
	{
		EmitSoundToAll(whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds)-1)], client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		PrintToChatAll("%s%N %t", PREFIX, client, "whistled");
		g_WhistleCount[client]++;
		PrintToChat(client, "%s%t", PREFIX, "whistles left", (cvarWhistleTimes-g_WhistleCount[client]));
	}
	else
	{
		PrintToChat(client, "%s%t", PREFIX, "whistle limit exceeded", cvarWhistleTimes);
	}
	
	return Plugin_Handled;
}
// say /whoami
// displays the model name in chat again
public Action:Display_ModelName(client,args)
{
	// only enable command, if player already chose a model
	if(!g_EnableHnS || !IsPlayerAlive(client) || g_ModelChangeCount[client] == 0)
		return Plugin_Handled;
	
	// only Ts can use a model
	if(GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	decl String:modelName[128];
	GetClientModel(client, modelName, sizeof(modelName));
	
	if (!KvGotoFirstSubKey(kv))
	{
		return Plugin_Handled;
	}
	
	decl String:name[30], String:path[100], String:fullPath[100];
	do
	{
		KvGetString(kv, "name", name, sizeof(name));
		KvGetString(kv, "path", path, sizeof(path));
		FormatEx(fullPath, sizeof(fullPath), "models/%s.mdl", path);
		if(StrEqual(fullPath, modelName))
		{
			KvGetString(kv, "name", name, sizeof(name));
			PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", name);
		}
	} while (KvGotoNextKey(kv));
	KvRewind(kv);
	
	return Plugin_Handled;
}

public Action:Block_Cmd(client,args)
{
	// only block if anticheat is enabled
	if(g_EnableHnS && GetConVarBool(hns_cfg_anticheat))
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

// Admin Command
// sm_hns_force_whistle
// Forces a terrorist player to whistle
public Action:ForceWhistle(client, args)
{
	if(!g_EnableHnS || !GetConVarBool(hns_cfg_whistle))
	{
		ReplyToCommand(client, "Disabled.");
		return Plugin_Handled;
	}
	
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: sm_hns_force_whistle <#userid|steamid|name>");
		return Plugin_Handled;
	}
	
	decl String:player[70];
	GetCmdArg(1, player, sizeof(player));
	
	new target = FindTarget(client, player);
	
	if(GetClientTeam(target) == 2 && IsPlayerAlive(target))
	{
		EmitSoundToAll(whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds)-1)], target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		PrintToChatAll("%s%N %t", PREFIX, target, "whistled");
	}
	else
	{
		ReplyToCommand(client, "Hide and Seek: %t", "Only terrorists can use");
	}
	
	return Plugin_Handled;
}


/*
* 
* Menu Handler
* 
*/
public Menu_Group(Handle:menu, MenuAction:action, client, param2)
{
	// make sure again, the player is a Terrorist
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && g_AllowModelChange[client])
	{
		if (action == MenuAction_Select)
		{
			decl String:info[100], String:info2[100];
			new bool:found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
			if(found)
			{
				SetEntityModel(client, info);
				PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", info2);
				g_ModelChangeCount[client]++;
			}
		} else if(action == MenuAction_Cancel)
		{
			
			PrintToChat(client, "%s%t", PREFIX, "Type !hide");
		}
	}
}

/*
* 
* Helper Functions
* 
*/

// read the hide_and_seek.cfg config
// add all models to the menu
Handle:BuildMainMenu()
{
	g_TotalModelsAvailable = 0;
	
	new Handle:menu = CreateMenu(Menu_Group);
	
	kv = CreateKeyValues("Models");
	new String:file[256], String:map[64], String:title[64], String:finalOutput[100];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, 255, "configs/hide_and_seek/maps/%s.cfg", map);
	FileToKeyValues(kv, file);
	
	if (!KvGotoFirstSubKey(kv))
	{
		return INVALID_HANDLE;
	}
	
	decl String:name[30];
	decl String:path[100];
	do
	{
		KvGetString(kv, "name", name, sizeof(name));
		KvGetString(kv, "path", path, sizeof(path));
		FormatEx(finalOutput, sizeof(finalOutput), "models/%s.mdl", path);
		PrecacheModel(finalOutput, true);
		AddMenuItem(menu, finalOutput, name);
		g_TotalModelsAvailable++;
	} while (KvGotoNextKey(kv));
	KvRewind(kv);
	
	FormatEx(title, sizeof(title), "%t:", "Title Select Model");
	SetMenuTitle(menu, title);
	SetMenuExitButton(menu, false);
	
	return menu;
}

// Check if a player has a bad convar value set
bool:IsConVarCheater(client)
{
	for(new i=0;i<sizeof(cheat_commands);i++)
	{
		if(g_ConVarViolation[client][i])
		{
			return true;
		}
	}
	return false;
}

// Fade a players screen to black (amount=0) or removes the fade (amount=255)
PerformBlind(client, amount)
{	
	new Handle:message = StartMessageOne("Fade", client);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0)
	{
		BfWriteShort(message, 0x0010);
	}
	else
	{
		BfWriteShort(message, 0x0008);
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	EndMessage();
}

public Action:StripWeapons(Handle:timer, any:client)
{
	new maxent = GetMaxEntities(), String:eName[64];
	for (new i=MaxClients;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, eName, sizeof(eName));
			if((StrContains(eName, "weapon_") != -1 || StrContains(eName, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == client)
			{
				RemoveEdict(i);
			}
		}
	}
}

SetRandomModel(client)
{
	// give him a random one.
	decl String:ModelPath[80], String:finalPath[100], String:ModelName[60], String:RandomNumber[4];
	IntToString(GetRandomInt(1, g_TotalModelsAvailable), RandomNumber, sizeof(RandomNumber));
	KvJumpToKey(kv, RandomNumber);
	KvGetString(kv, "name", ModelName, sizeof(ModelName));
	KvGetString(kv, "path", ModelPath, sizeof(ModelPath));
	FormatEx(finalPath, sizeof(finalPath), "models/%s.mdl", ModelPath);
	KvRewind(kv);
	SetEntityModel(client, finalPath);
	PrintToChat(client, "%s%t", PREFIX, "Did not choose model");
	PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", ModelName);
	g_ModelChangeCount[client]++;
}

/*
* 
* Handle ConVars
* 
*/
// Monitor the protected cvars and... well protect them ;)
public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:cvarName[50];
	GetConVarName(convar, cvarName, sizeof(cvarName));
	for(new i=0;i<sizeof(protected_cvars);i++)
	{
		if(StrEqual(protected_cvars[i], cvarName) && StringToInt(newValue) != forced_values[i])
		{
			SetConVarInt(convar, forced_values[i]);
			PrintToServer("Hide and Seek: %T", "protected cvar", LANG_SERVER);
			break;
		}
	}
}

// directly change the hider speed on change
public OnChangeHiderSpeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for(new i=1;i<MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(hns_cfg_hidersspeed));
	}
}

// directly change the hider speed on change
public OnChangeAntiCheat(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StrEqual(oldValue, newValue))
		return;
	
	// disable anticheat
	if(StrEqual(newValue, "0"))
	{
		for(new i=1;i<MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_CheckVarTimer[i] != INVALID_HANDLE)
			{
				KillTimer(g_CheckVarTimer[i]);
				g_CheckVarTimer[i] = INVALID_HANDLE;
			}
		}
	}
	// enable anticheat
	else if(StrEqual(newValue, "1"))
	{
		for(new i=1;i<MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_CheckVarTimer[i] == INVALID_HANDLE)
			{
				g_CheckVarTimer[i] = CreateTimer(1.0, StartVarChecker, i, TIMER_REPEAT);
			}
		}
	}
}

// disable/enable plugin and restart round
public Cfg_OnChangeEnable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// don't execute if it's unchanged
	if(StrEqual(oldValue, newValue))
		return;
	
	// disable - it's been enabled before.
	if(StrEqual(newValue, "0"))
	{
		UnhookConVarChange(hns_cfg_anticheat, OnChangeAntiCheat);
		UnhookConVarChange(hns_cfg_hidersspeed, OnChangeHiderSpeed);
		
		// Unhooking events
		UnhookEvent("player_spawn", Event_OnPlayerSpawn);
		UnhookEvent("player_hurt", Event_OnPlayerHurt);
		UnhookEvent("weapon_fire", Event_OnWeaponFire);
		UnhookEvent("player_death", Event_OnPlayerDeath);
		UnhookEvent("round_start", Event_OnRoundStart);
		UnhookEvent("round_end", Event_OnRoundEnd);
		UnhookEvent("item_pickup", Event_OnItemPickup);
		
		// unprotect the cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			// reset old cvar values
			UnhookConVarChange(g_ProtectedConvar[i], OnCvarChange);
			SetConVarInt(g_ProtectedConvar[i], previous_values[i], true);
		}
		
		// stop advertising spam
		if(g_SpamCommandsTimer != INVALID_HANDLE)
		{
			KillTimer(g_SpamCommandsTimer);
			g_SpamCommandsTimer = INVALID_HANDLE;
		}
		
		// stop countdown
		if(g_ShowCountdownTimer != INVALID_HANDLE)
		{
			KillTimer(g_ShowCountdownTimer);
			g_ShowCountdownTimer = INVALID_HANDLE;
		}
		
		// close handles
		if(kv != INVALID_HANDLE)
			CloseHandle(kv);
		if(mainmenu != INVALID_HANDLE)
			CloseHandle(mainmenu);
		
		for(new c=1;c<MaxClients;c++)
		{
			if(!IsClientInGame(c))
				continue;
			
			// stop cheat checking
			if(!IsFakeClient(c) && g_CheckVarTimer[c] != INVALID_HANDLE)
			{
				KillTimer(g_CheckVarTimer[c]);
				g_CheckVarTimer[c] = INVALID_HANDLE;
			}
			
			// Unhook weapon pickup
			SDKUnhook(c, SDKHook_WeaponCanUse, OnWeaponCanUse);
			
			// reset every players vars
			OnClientDisconnect(c);
		}
		
		g_EnableHnS = false;
		// restart game to reset the models and scores
		ServerCommand("mp_restartgame 1");
	}
	else if(StrEqual(newValue, "1"))
	{
		// hook the convars again
		HookConVarChange(hns_cfg_hidersspeed, OnChangeHiderSpeed);
		HookConVarChange(hns_cfg_anticheat, OnChangeAntiCheat);
		
		// Hook events again
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		HookEvent("player_hurt", Event_OnPlayerHurt);
		HookEvent("weapon_fire", Event_OnWeaponFire);
		HookEvent("player_death", Event_OnPlayerDeath);
		HookEvent("round_start", Event_OnRoundStart);
		HookEvent("round_end", Event_OnRoundEnd);
		HookEvent("item_pickup", Event_OnItemPickup);
		
		// set bad server cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			g_ProtectedConvar[i] = FindConVar(protected_cvars[i]);
			previous_values[i] = GetConVarInt(g_ProtectedConvar[i]);
			SetConVarInt(g_ProtectedConvar[i], forced_values[i], true);
			HookConVarChange(g_ProtectedConvar[i], OnCvarChange);
		}
		// start advertising spam
		g_SpamCommandsTimer = CreateTimer(120.0, SpamCommands, 0);
		
		for(new c=1;c<MaxClients;c++)
		{
			if(!IsClientInGame(c))
				continue;
			
			// start cheat checking
			if(!IsFakeClient(c) && GetConVarBool(hns_cfg_anticheat) && g_CheckVarTimer[c] == INVALID_HANDLE)
			{
				g_CheckVarTimer[c] = CreateTimer(1.0, StartVarChecker, c, TIMER_REPEAT);
			}
			
			// Hook weapon pickup
			SDKHook(c, SDKHook_WeaponCanUse, OnWeaponCanUse);
		}
		
		g_EnableHnS = true;
		// build the menu and setup the hostage_rescue zone
		OnMapStart();
		
		// restart game to reset the models and scores
		ServerCommand("mp_restartgame 1");
	}
}

// check the given cheat cvars on every client
public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if(!IsClientInGame(client))
		return;
	
	new bool:match = StrEqual(cvarValue, "0");
	
	for(new i=0;i<sizeof(cheat_commands);i++)
	{
		if(!StrEqual(cheat_commands[i], cvarName))
			continue;
		
		if(!match)
		{
			g_ConVarViolation[client][i] = true;
			if(g_ConVarMessage[client][i] == 0)
			{
				PrintToChat(client, "%s%t\x04 %s 0", PREFIX, "Print to console", cvarName);
				PrintHintText(client, "%t %s 0", "Print to console", cvarName);
			}
			g_ConVarMessage[client][i]++;
			if(g_ConVarMessage[client][i] > 5)
				g_ConVarMessage[client][i] = 0;
		}
		else
			g_ConVarViolation[client][i] = false;
	}
}