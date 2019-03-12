#include <amxmodx>
#include <hl_player_models_api>

#define PLUGIN  "Skin Menu"
#define VERSION "1.0"
#define AUTHOR  "rtxa"

new g_SkinMenu;

new const g_Skins[][] =
{
	"barney",
	"gina",
	"gman",
	"gordon",
	"hgrunt",
	"recon",
	"robo",
	"scientist",
	"zombie"
};

public plugin_precache()
{
	for (new i; i < sizeof(g_Skins); i++)
		precache_model(fmt("models/player/%s/%s.mdl", g_Skins[i], g_Skins[i]));
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say !skins", "CmdSkinMenu");
	CreateSkinMenu();
}

public plugin_end()
{
	menu_destroy(g_SkinMenu);
}

public CmdSkinMenu(id)
{
	menu_display(id, g_SkinMenu);
}

CreateSkinMenu()
{
	g_SkinMenu = menu_create("Skin Menu", "HandlerSkinMenu");
	for (new i; i < sizeof(g_Skins); i++)
		menu_additem(g_SkinMenu, g_Skins[i]);

}

public HandlerSkinMenu(id, menu, item)
{
	if (item != MENU_EXIT)
		hl_set_player_model(id, g_Skins[item]);
	return PLUGIN_HANDLED;
}
