#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "HL Player Models API"
#define VERSION "1.0"
#define AUTHOR  "rtxa"

#define MAX_TEAMS 32
#define TEAMNAME_LENGTH 16
#define TEAMLIST_LENGTH MAX_TEAMS * TEAMNAME_LENGTH

new bool:g_IsTeamPlay;
new g_TeamList[MAX_TEAMS][TEAMNAME_LENGTH];
new g_NumTeams;

new bool:g_HasCustomModel[MAX_PLAYERS + 1];
new g_CustomModelIndex[MAX_PLAYERS + 1]

public plugin_precache()
{
	new Float:tdm; global_get(glb_teamplay, tdm);
	g_IsTeamPlay = tdm < 1.0 ? false : true;

	new teamlist[TEAMLIST_LENGTH];
	get_cvar_string("mp_teamlist", teamlist, charsmax(teamlist));
	__explode_teamlist(g_TeamList, charsmax(g_TeamList[]), teamlist);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	if (g_IsTeamPlay)
		RegisterHamPlayer(Ham_Spawn, "OnPlayerSpawn_Pre");

	register_forward(FM_SetClientKeyValue, "OnSetClientKeyValue_Pre");
	register_forward(FM_PlayerPostThink, "OnPlayerPostThink_Post", true);
	register_message(get_user_msgid("SayText"), "OnMsgSayText");
}	

public client_disconnected(id)
{
	g_HasCustomModel[id] = false;
}

public OnPlayerPostThink_Post(id)
{
	if (g_HasCustomModel[id])
		set_pev(id, pev_modelindex, g_CustomModelIndex[id]);
}

public OnPlayerSpawn_Pre(id)
{
	if (g_HasCustomModel[id])
		_hl_set_player_team(id, _hl_get_player_team(id));
}

public OnSetClientKeyValue_Pre(id, const infobuffer[], const key[], const value[])
{
	return g_HasCustomModel[id] && equal(key, "model") ? FMRES_SUPERCEDE : FMRES_IGNORED;
}

public client_infochanged(id)
{
	if (g_HasCustomModel[id])
		remove_model_info(id);
}

_hl_set_player_model(id, const model[])
{
	remove_model_info(id);
	g_CustomModelIndex[id] = engfunc(EngFunc_ModelIndex, fmt("models/player/%s/%s.mdl", model, model));
	g_HasCustomModel[id] = true;
}

_hl_reset_player_model(id)
{
	g_HasCustomModel[id] = false;
	if (g_IsTeamPlay)
		_hl_set_player_team(id, _hl_get_player_team(id));
	else
		dllfunc(DLLFunc_ClientUserInfoChanged, id, engfunc(EngFunc_GetInfoKeyBuffer, id));
}

_hl_get_player_team(id, team[] = "", len = 0)
{
	new teamname[TEAMNAME_LENGTH];
	get_ent_data_string(id, "CBasePlayer", "m_szTeamName", teamname, charsmax(teamname));
	if (len > 0)
		copy(team, len, teamname);
	return __get_team_index(teamname) + 1;
}

_hl_set_player_team(id, teamid)
{
	set_ent_data_string(id, "CBasePlayer", "m_szTeamName", g_TeamList[teamid - 1]);
	set_user_info(id, "model", g_TeamList[teamid - 1]);

	static TeamInfo;
	if (TeamInfo || (TeamInfo = get_user_msgid("TeamInfo")))
	{
		message_begin(MSG_ALL, TeamInfo);
		write_byte(id);
		write_string(pev(id, pev_iuser1) ? "" : g_TeamList[teamid - 1]);
		message_end();
	}

	static ScoreInfo;
	if (ScoreInfo || (ScoreInfo = get_user_msgid("ScoreInfo")))
	{
		message_begin(MSG_ALL, ScoreInfo);
		write_byte(id);
		write_short(get_user_frags(id));
		write_short(get_ent_data(id, "CBasePlayer", "m_iDeaths"));
		write_short(0);
		write_short(teamid);
		message_end();
	}
}

remove_model_info(id)
{
	new model[TEAMNAME_LENGTH];
	get_user_info(id, "model", model, charsmax(model));
	if (!equal(model, ""))
		set_user_info(id, "model", "");	
}

__explode_teamlist(output[][], size, input[])
{	
	new nLen, teamname[TEAMLIST_LENGTH];
	while (nLen < strlen(input) && g_NumTeams < MAX_TEAMS)
	{
		strtok(input[nLen], teamname, charsmax(teamname), "", 0, ';');
		nLen += strlen(teamname) + 1;
		if (__get_team_index(teamname) < 0)
		{
			copy(output[g_NumTeams], size, teamname);
			g_NumTeams++;
		}
	}

	if (g_NumTeams < 2)
		g_NumTeams = 0;
}

__get_team_index(const teamname[])
{
	for (new i = 0; i < g_NumTeams; i++)
		if (equali(g_TeamList[i], teamname))
			return i;
	return -1;
}

public OnMsgSayText(msg_id, msg_dest, msg_entity)
{
	new id = get_msg_arg_int(1);

	new text[192];
	get_msg_arg_string(2, text, charsmax(text));

	if (text[0] != '*')
		return PLUGIN_CONTINUE;

	// bugfixed hl sends this message
	if (contain(text, "* Model should be non-empty") != -1)
		return PLUGIN_HANDLED;

	if (g_HasCustomModel[id])
	{
		static found;
		if (equal(text, "* Not allowed to change teams in this game!^n"))
		{
			return PLUGIN_HANDLED
		}
		if (equal(text, "* Can't change team to ''^n"))
		{
			found = true;
			return PLUGIN_HANDLED;
		} 
		else if (found) // after "Can't change team...", block also "Server limits to..."
		{
			found = false;
			return PLUGIN_HANDLED;
		}	
	}

	return PLUGIN_CONTINUE;
}

public plugin_natives()
{
	register_library("hl_player_models_api");
	register_native("hl_set_player_model", "native_set_player_model");
	register_native("hl_reset_player_model", "native_reset_player_model");
	register_native("hl_set_player_team", "native_set_player_team");
	register_native("hl_get_player_team", "native_get_player_team");
}

public native_set_player_model(plugin_id, argc)
{
	new id = get_param(1);
	new model[TEAMNAME_LENGTH]; get_string(2, model, charsmax(model));

	if (!CheckPlayer(id)) 
		return;

	if (!model[0])
	{
		log_error(AMX_ERR_NATIVE, "Model can not be empty");
		return;
	}

	_hl_set_player_model(id, model);

	return;
}

public native_reset_player_model(plugin_id, argc)
{
	new id = get_param(1);

	if (!CheckPlayer(id)) 
		return;

	_hl_reset_player_model(id);

	return;
}

public native_set_player_team(plugin_id, argc)
{
	new id = get_param(1);
	new teamid = get_param(2);

	if (!g_IsTeamPlay)
	{
		log_error(AMX_ERR_NATIVE, "Can't set team. Server is not in teamplay mode");
		return;
	}

	if (teamid < 1 || teamid > g_NumTeams)
	{
		log_error(AMX_ERR_NATIVE, "Invalid team id (%d)");
		return;
	}

	if (!CheckPlayer(id))
		return;

	_hl_set_player_team(id, teamid);
}

public native_get_player_team(plugin_id, argc)
{
	new id = get_param(1);
	new team[TEAMNAME_LENGTH];
	new len = get_param(3);

	if (!CheckPlayer(id)) 
		return 0;

	new teamid = _hl_get_player_team(id, team, charsmax(team));
	set_string(2, team, len);	
	return teamid;
}

CheckPlayer(id)
{
	if (id < 1 || id > MaxClients)
	{
		log_error(AMX_ERR_NATIVE, "Player out of range (%d)", id);
	}
	else if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player %d (not in-game)", id);
		return false;
	} 
	else if (pev_valid(id) != 2)
	{
		log_error(AMX_ERR_NATIVE, "Invalid player %d (no private data)", id);
		return false;
	}

	return true;
}