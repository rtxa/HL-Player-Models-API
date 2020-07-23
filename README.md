# HL Player Models API

![Author](https://img.shields.io/badge/Author-rtxA-red) ![Version](https://img.shields.io/badge/Version-1.2-red) ![Last Update](https://img.shields.io/badge/Last%20Update-02/07/2020-red) [![Source Code](https://img.shields.io/badge/GitHub-Source%20Code-blueviolet)](https://github.com/rtxa/HL-Player-Models-API)

## ☉ Introduction

This API for __Half-Life__ was made with the aim in mind of being able to use differents skins in __Teamplay__ mode. Normally this is not possible without breaking the gameplay or making a lot of changes that will imply modify every plugin making it unpractical.

Now with this you can add classes for a __Zombie Mod__, etc.

## ☉ Description

This let you set custom models to the players and reset them to the default model. The custom model will stay until the player disconnects or you reset it manually.

## ☰ Natives

```pawn
/**
 * Sets a custom player model.
 *
 * @param id      Player index
 * @param model   Model path
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

## ☰ Requirements

- [Last AMXX 1.9](https://www.amxmodx.org/downloads-new.php) or newer.
- [Orpheu 2.6.3](https://github.com/Arkshine/Orpheu/releases) or ReAPI if you are using ReHLDS.

## ⚙ Installation

1. __Download__ the attached files and __extract__ them in your scripting folder, then type *#include \<hl_player_models_api\>* in your plugin to be able to __use__ the functions.
2. __Compile__ *hl_player_models_api.sma* and __add__ it to your plugin list in plugins.ini to __turn on__ the API.

The API is ready to use.

## ☉ Notes

- Remember to install Orpheu or ReAPI (ReHLDS) in order to use the API.
- Any custom model that is going to be set to the player has to be previously __precached__.
- It's not necessary the models to be located in models/player/x/x.mdl. Also, you can use an sprite as a player model if you want.
- If you want to know what model is using a player, save the number that precache_model() gives you, associate the value with a name. Then, you will be able to know the player's model by his modelindex. 

## ⛏ To do

- ☑ Add support for ReApi (ReHLDS).
- ☐ (Debatable) Probably the server will crash if you try to change the team of 32 players at the same time (Fullupdate spam?). Make a queue and delay team changes to avoid any issue (That will make the plugin much more safer for team changing unlike natives from HL Stocks).

### ⚛ Sample plugin

I leave you this sample plugin called “Skin Menu” so you can test it. The skin list can be set in AMX Mod X config's folder creating this file using following format.

**skin-list.cfg**

```php
Normal Barney;  models/player/barney/barney.mdl
Postal;         models/madskillz/postal.mdl
Banana Dancer;  models/madskillz/bananadancer.mdl
Bender;         models/madskillz/bender.mdl
Scream;         models/madskillz/scream.mdl
Droid;          models/madskillz/droid.mdl
Cool Barney;    models/madskillz/clanfn.mdl
```

* say !skins [Displays a menu where he can choose a custom skin]
* say !rskin [Reset player to his original skin]
