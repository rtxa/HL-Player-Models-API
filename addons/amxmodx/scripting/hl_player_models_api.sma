/*
*
* HL Player Models API 1.2 by rtxA
*
* Description:
* This let you set custom models to the players and reset them to the default model.
* The custom model will stay until the player disconnects or you reset it manually.
*
* Useful for:
* - Team Deathmatch servers because you can't change player models without breaking the system that determines player's team.
* - You can set player model by modelindex, this has two advantages:
*   * When you need to update models and make sure player use new model when he is using an old one.
*   * If you want to set admin models and avoid players to use them normally in deathmatch, you can use other directories instead of models/player/ to do that.
* 
* Credits: 
* ConnorMcLeod by the Orpheu signatures and some code snippets.
* PRoSToTeMa by some useful ideas I found in an issue on GitHub.
*
*/
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <orpheu>
#include <orpheu_memory>
#include <reapi>

#define PLUGIN  "HL Player Models API"
#define VERSION "1.2"
#define AUTHOR  "rtxA"

#define MAX_TEAMS 32
#define TEAMNAME_LENGTH 16
#define TEAMLIST_LENGTH MAX_TEAMS * TEAMNAME_LENGTH

#define MAX_INFO_STRING 256

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
	
	if (module_exists("reapi") && is_rehlds())
	{
		RegisterHookChain(RH_SV_WriteFullClientUpdate, "ReApi_WriteFullClientUpdate");
	} 
	else
	{
		OrpheuRegisterHook(OrpheuGetFunction("SV_FullClientUpdate"), "Orpheu_FullClientUpdate", OrpheuHookPre);
	}

	register_forward(FM_PlayerPostThink, "OnPlayerPostThinkPost", true);
}	

public OnPlayerPostThinkPost(id)
{
	if (g_HasCustomModel[id])
	{
		set_pev(id, pev_modelindex, g_CustomModelIndex[id]);
	}
}

public client_disconnected(id)
{
	g_HasCustomModel[id] = false;
}

public ReApi_WriteFullClientUpdate(id, buffer)
{	
	if (g_HasCustomModel[id])
	{
		set_key_value(buffer, "model", "");
	}
	return HC_CONTINUE;
}

// void SV_FullClientUpdate(client_t * client, sizebuf_t *buf)
public OrpheuHookReturn:Orpheu_FullClientUpdate(client /*, buffer */)
{
	new userid = OrpheuMemoryGetAtAddress(client, "userid");
	new id = find_player("k", userid);
	
	if (g_HasCustomModel[id])
	{
		new userinfo[MAX_INFO_STRING];
		copy_infokey_buffer(engfunc(EngFunc_GetInfoKeyBuffer, id), userinfo, charsmax(userinfo));
		Info_RemoveKeyValue(userinfo, "model");
		UTIL_UpdateUserInfo(0, id, userid, userinfo);
		return OrpheuSupercede;
	}
	return OrpheuIgnored;
}

countChar(const s[], len, ch) 
{ 
	new num;
	for (new i; i < len; i++)
	{ 
		if (s[i] == ch)
		num++; 
	} 
	return num; 
} 

Info_RemoveKeyValue(s[MAX_INFO_STRING], const key[])
{
	new idx;

	//  we're looking the position of the slash that contains the key
	while ((idx = strfind(s, fmt("\%s", key))) != -1)
	{	
		// always has to be an impar number ("\key\value")
		if (countChar(s, idx + 1, '\') % 2)
			break;
		else
			idx++;
	}

	if (idx == -1)
		return;

	// set the cursor exactly at the first char of the value key
	new pos = idx + strlen(key) + 2 

	// copy keyvalue, we already have the key from the function parameters
	new str[256];
	copyc(str, charsmax(str), s[pos], '\');

	// now let's get key and value key together and remove it
	replace(s, MAX_INFO_STRING, fmt("\%s\%s", key, str), "");
}

UTIL_UpdateUserInfo(id, clId, clUserid, clUserInfo[])
{
	message_begin(id ? MSG_ONE : MSG_ALL, SVC_UPDATEUSERINFO, _, id);
	write_byte(clId-1);
	write_long(clUserid);
	write_string(clUserInfo);
	write_long(0);
	write_long(0);
	write_long(0);
	write_long(0);
	message_end();
}

reset_model_info(id)
{
	new model[16];
	get_user_info(id, "model", model, charsmax(model));
	set_user_info(id, "model", "");
	set_user_info(id, "model", model);
	// after this, SV_FullClientUpdate forward will be called
}

_hl_set_player_model(id, const model[])
{
	g_CustomModelIndex[id] = engfunc(EngFunc_ModelIndex, model);
	g_HasCustomModel[id] = true;
	reset_model_info(id);
}

_hl_reset_player_model(id)
{
	g_HasCustomModel[id] = false;
	reset_model_info(id);
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

public plugin_natives()
{
	register_library("hl_player_models_api");
	register_native("hl_set_player_model", "native_set_player_model");
	register_native("hl_reset_player_model", "native_reset_player_model");
	register_native("hl_set_player_team", "native_set_player_team");
	register_native("hl_get_player_team", "native_get_player_team");

	set_native_filter("native_filter");
	set_module_filter("module_filter");
}

public native_filter(const name[], index, trap) {
	static const natives[][] = { "is_rehlds", "RegisterHookChain", "set_key_value" };
	for (new i; i < sizeof(natives); i++) {
		// use orpheu instead if native isn't found
		if (equal(name, natives[i]) && !trap) {
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public module_filter(const name[]) {
	// use orpheu instead if module isn't found
	if (equal(name, "reapi")) {
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public native_set_player_model(plugin_id, argc)
{
	new id = get_param(1);
	new model[256]; get_string(2, model, charsmax(model));

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