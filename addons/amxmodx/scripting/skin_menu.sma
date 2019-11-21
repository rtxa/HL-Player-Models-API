#include <amxmodx>
#include <amxmisc>
#include <hl_player_models_api>

#define PLUGIN  "Skin Menu"
#define VERSION "1.2"
#define AUTHOR  "rtxa"

new g_SkinMenu;

new Array:g_ModelsPathList;
new Array:g_ModelsNameList;

public plugin_precache()
{
	parse_models_file();
}

public parse_models_file()
{
	new configsPath[256]
	get_configsdir(configsPath, charsmax(configsPath));

	new fHandle;

	fHandle = fopen(fmt("%s/skin-list.cfg", configsPath), "r");

	if (!fHandle)
	{
		log_amx("Can't open skin-list.cfg file");
		return;
	}

	new lineBuffer[512];

	g_ModelsNameList = ArrayCreate(256);
	g_ModelsPathList = ArrayCreate(256);

	while (fgets(fHandle, lineBuffer, charsmax(lineBuffer)))
	{
		new modelName[64];
		new modelNameLen;
		modelNameLen = copyc(modelName, charsmax(modelName), lineBuffer, ';');

		if (!modelNameLen)
		{
			log_amx("Can't read model's name. Discarding this line...");
			continue;
		}

		new modelPath[256];
		new modelPathIdx = modelNameLen + 2;

		if ( modelPathIdx < 256 && !lineBuffer[modelPathIdx])
		{
			log_amx("Can't read model's path. Discarding this line...");
			continue;
		}

		trim(lineBuffer[modelPathIdx]);
		copy(modelPath, charsmax(modelPath), lineBuffer[modelPathIdx])

		if (file_exists(modelPath))
		{
			precache_model(modelPath);
		}
		else
		{
			log_amx("Can't find model to precache. Discarding this line...");
			continue;
		}

		ArrayPushString(g_ModelsNameList, modelName);
		ArrayPushString(g_ModelsPathList, modelPath);
	}

	fclose(fHandle);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say !skins", "CmdSkinMenu");
	register_clcmd("say !rskin", "CmdResetSkin");
	CreateSkinMenu();
}

public plugin_end()
{
	menu_destroy(g_SkinMenu);
	ArrayDestroy(g_ModelsPathList);
	ArrayDestroy(g_ModelsNameList);
}

public CmdResetSkin(id)
{
	hl_reset_player_model(id);
}

public CmdSkinMenu(id)
{
	menu_display(id, g_SkinMenu);
}

CreateSkinMenu()
{
	g_SkinMenu = menu_create("Skin Menu", "HandlerSkinMenu");
	new name[32];
	for (new i; i < ArraySize(g_ModelsNameList); i++)
	{
		ArrayGetString(g_ModelsNameList, i, name, sizeof(name));
		menu_additem(g_SkinMenu, name);
	}

}

public HandlerSkinMenu(id, menu, item)
{
	new path[256];
	if (item != MENU_EXIT)
	{
		ArrayGetString(g_ModelsPathList, item, path, sizeof(path));
		hl_set_player_model(id, path);
	}
	return PLUGIN_HANDLED;
}
