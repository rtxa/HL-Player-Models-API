# HL Player Models API
#### Author: rtxa | Version: 1.0

This API for __Half-Life__ was made with the aim in mind to be able to use differents models in __Teamplay__ mode. Now with this you can add classes for __Zombie Mod__, etc.

## Introduction
This let you set custom models to the players and reset them to the default model. The custom model will stay until the player disconnects or you reset it manually.

## Functions
```pawn
/**
 * Sets a custom player model.
 *
 * @param id      Player index
 * @param model   Model short-name
 */
native hl_set_player_model(id, const model[])

/**
 * Restores default model of player.
 *
 * @param id	Player index
 */
native hl_reset_player_model(id)

/**
 * Returns the team id of the player, and optionally retrieves the name of
 * the team.
 *
 * @param id            Player index
 * @param team          Buffer to store team name
 * @param len           Maximum buffer length
 */
native hl_get_player_team(id, team[] = "", len = 0)

/**
 * Sets the player's team without killing him.
 *
 * @param id        Player index
 * @param teamid	Team id
 */
native hl_set_player_team(id, teamid)
```

## Requirements
- AMX Mod X 1.9.0 Build 5208 or newer.
- Fakemeta.
- Hamsandwich.

## Installation
1. __Download__ the attached files and __extract__ them in your scripting folder, then type *#include \<hl_player_models_api\>* in your plugin to be able to __use__ the functions.
2. __Compile__ *hl_player_models_api.sma* and __add__ it to your plugin list in plugins.ini to __turn on__ the API.

## Notes
- Any custom model that is going to be set to the player has to be previously __precached__.
- Any plugin that use functions for get and set player team, __must__ use the functions from this API to work correctly.
- Bots that identify player's team according by his *__model__* will not work correctly, modify them to use *__m_szTeamName__* instead.
- You can't get *__model__* key from players with custom models using *__get_user_info(id, "model", ...)__*, instead you should get it from *__pev_modelindex__* o *__pev_model__*.

### Sample plugin
I leave you this sample plugin called “Skin Menu”, what it does is open a menu to the player where he can choose choose a custom model (contains all default player models that comes with Half-Life).

