#include <amxmodx>
#include <amxmisc>
#include <geoip>

new ShowAll, ShowMethod

public plugin_init()
{
	/* Register plugin */
	register_plugin("Country Welcome","1.7","SweatyBanana")
	
	/* Register LANG file */
	register_dictionary("cwlang.txt")
	
	/* Register cvars */
	ShowAll = register_cvar("amx_country_showall", "0")
	ShowMethod = register_cvar("amx_country_method", "5")
}

public client_putinserver(id)
{
	/* Create variables */
	new ShowWho = get_pcvar_num(ShowAll),ShowHow = get_pcvar_num(ShowMethod)
	static Name[33],Country[33],Ip[16]
	
	/* Get user information */
	get_user_ip(id,Ip,31,true)
	get_user_name(id,Name,32)
	geoip_country(Ip,Country)
	
	/* Check who to display to */
	if(ShowWho==0)
	{
		ShowMessages(0,ShowHow,Name,Country)
		return PLUGIN_CONTINUE
	}

	new Players[32],Playersnum
	get_players(Players,Playersnum,"c")

	for(new Count = 0;Count < Playersnum;Count++)
	{
		new Player = Players[Count]

		if(is_user_admin(Player) && Player != id)
			ShowMessages(Player,ShowHow,Name,Country)
	}
	return PLUGIN_CONTINUE
}

/* Show the messages */
ShowMessages(id,ShowHow,Name[],Country[])
{
	if(ShowHow & 1) /* Console */
		client_print(id, print_console,"%L",LANG_SERVER,"MESSAGE",Name,Name,Country)

	if(ShowHow & 2) /* Chat */
		client_print(id, print_chat,"%L",LANG_SERVER,"MESSAGE",Name,Name,Country)

	if(ShowHow & 4) /* TSAY */
	{
		set_hudmessage(id, 225, 0, 0.05, 0.45, 0, 6.0, 6.0, 0.5, 0.15, 3)
		show_hudmessage(id,"%L",LANG_SERVER,"MESSAGE",Name,Name,Country)
	}

	if(ShowHow & 8) /* CSAY */
	{
		set_hudmessage(id, 255, 0, -1.0, 0.3, 0, 1.0, 5.0, 0.1, 0.2, 4)
		show_hudmessage(id,"%L",LANG_SERVER,"MESSAGE",Name,Name,Country)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
