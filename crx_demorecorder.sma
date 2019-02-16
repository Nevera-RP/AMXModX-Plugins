#include <amxmodx>

#define CC_COLORS_TYPE CC_COLORS_SHORT
#include <cromchat>

#define PLUGIN_VERSION "2.0"
#define MAX_MESSAGE_LENGTH 192
#define MAX_DEMO_NAME_LENGTH 64
#define MAX_TIME_LENGTH 32
#define DEMO_MESSAGES 2
#define REPLACER_SYMBOL "_"

#define ARG_NAME "<name>"
#define ARG_NAME_FULL "<name>.dem"
#define ARG_TIME "<time>"

new const g_szSymbols[][] = { " ", ":", ".", "*", "/", "|", "\", "?", ">", "<" }

enum _:Cvars
{
	dem_delay,
	dem_msg_delay,
	dem_name,
	dem_message,
	dem_message2,
	dem_time_format
}

enum _:CvarValues
{
	Float:cv_dem_delay,
	Float:cv_dem_msg_delay,
	cv_dem_name[MAX_DEMO_NAME_LENGTH],
	cv_dem_message[MAX_MESSAGE_LENGTH],
	cv_dem_message2[MAX_MESSAGE_LENGTH],
	cv_dem_time_format[MAX_TIME_LENGTH]
}

new g_eCvars[Cvars], g_eCvarValues[CvarValues]

public plugin_init()
{
	register_plugin("Simple Demo Recorder", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXDemoRecorder", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	
	g_eCvars[dem_delay] = register_cvar("dem_delay", "15.0")
	g_eCvars[dem_msg_delay] = register_cvar("dem_msg_delay", "0.1")
	g_eCvars[dem_name] = register_cvar("dem_name", "Budapest-Intl")
	g_eCvars[dem_message] = register_cvar("dem_message", "!g[Budapest-Intl] !nWe are now recording in your !gcstrike !nfolder: !t<name>")
	g_eCvars[dem_message2] = register_cvar("dem_message2", "!g[Budapest-Intl] !nDemo recording has been started at: !t<time>")
	g_eCvars[dem_time_format] = register_cvar("dem_time_format", "%X")
}

public plugin_cfg()
{
	g_eCvarValues[cv_dem_delay] = _:get_pcvar_float(g_eCvars[dem_delay])
	g_eCvarValues[cv_dem_msg_delay] = _:get_pcvar_float(g_eCvars[dem_msg_delay])
	get_pcvar_string(g_eCvars[dem_name], g_eCvarValues[cv_dem_name], charsmax(g_eCvarValues[cv_dem_name]))
	get_pcvar_string(g_eCvars[dem_message], g_eCvarValues[cv_dem_message], charsmax(g_eCvarValues[cv_dem_message]))
	get_pcvar_string(g_eCvars[dem_message2], g_eCvarValues[cv_dem_message2], charsmax(g_eCvarValues[cv_dem_message2]))
	get_pcvar_string(g_eCvars[dem_time_format], g_eCvarValues[cv_dem_time_format], charsmax(g_eCvarValues[cv_dem_time_format]))
	
	for(new i; i < sizeof(g_szSymbols); i++)
		replace_all(g_eCvarValues[cv_dem_name], charsmax(g_eCvarValues[cv_dem_name]), g_szSymbols[i], REPLACER_SYMBOL)
		
	add(g_eCvarValues[cv_dem_name], charsmax(g_eCvarValues[cv_dem_name]), ".dem")
}

public client_putinserver(id)
	set_task(g_eCvarValues[cv_dem_delay], "StartRecording", id)

public StartRecording(id)
{
	if(!is_user_connected(id))
		return
	
	client_cmd(id, "stop; record ^"%s^"", g_eCvarValues[cv_dem_name])
	set_task(g_eCvarValues[cv_dem_msg_delay], "SendMessages", id)
}

public SendMessages(id)
{
	if(!is_user_connected(id))
		return
		
	new szMessage[DEMO_MESSAGES][MAX_MESSAGE_LENGTH]
	copy(szMessage[0], charsmax(szMessage[]), g_eCvarValues[cv_dem_message])
	copy(szMessage[1], charsmax(szMessage[]), g_eCvarValues[cv_dem_message2])
	
	for(new i; i < DEMO_MESSAGES; i++)
	{
		apply_replacements(szMessage[i], charsmax(szMessage[]))
		CC_SendMessage(id, szMessage[i])
	}
}

apply_replacements(szMessage[], const iLen)
{
	replace_all(szMessage, iLen, ARG_NAME, g_eCvarValues[cv_dem_name])
	
	if(contain(szMessage, ARG_TIME) != -1)
	{
		new szTime[MAX_TIME_LENGTH]
		get_time(g_eCvarValues[cv_dem_time_format], szTime, charsmax(szTime))
		replace_all(szMessage, iLen, ARG_TIME, szTime)
	}
}
