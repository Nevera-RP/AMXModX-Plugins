#define PLUGINNAME	"Command logger"
#define VERSION		"0.2"
#define AUTHOR		"JGHG"
/*
	http://www.amxmodx.org/forums/viewtopic.php?p=69822

	Logs client console commands.

	Can log everything, or only those lines containing phrases registered with this server command: commandlogger_register
	Can log to AMXX logs, HL logs or a custom logfile.

	Installation
	************
	Compile as usual. If you need to register more than 64 phrases for the filter, edit the MAXCMDS define accordingly below.
	When adding this to plugins.ini, add it to the very top! This is *extremely* important.
	Also if you run several metamod plugins aside from AMX Mod X, be sure to put AMX Mod X first in metamod's plugins.ini.


	Usage
	*****
	To set where to log, specify this cvar: commandlogger_logto

	commandlogger_logto 0 (default, logs to AMXx logs)
	commandlogger_logto 1 (logs to HL logs)
	commandlogger_logto 2 (logs to custom file)

	If you specify to log to custom file, you should set the path with this cvar: commandlogger_filepath

	commandlogger_filepath customfilepath.log (default, the file will be always be created in the folder addons/amxmodx/logs/)

	By default, the filter is turned on. You can specify this with this cvar: commandlogger_filter

	commandlogger_filter 0 (don't use filter, log all commands, probably you won't need to use this as it will log a ton of commands)
	commandlogger_filter 1 (default, use filter, this only logs the command lines that contain phrases which you must register first, this is case insensitive)

	To add a phrase for the filter, use this server command: commandlogger_register
	commandlogger_register "entmod_create"
	commandlogger_register "amx_ban"

	You must use quotes around phrases that contain spaces.


	History:
	050601	-	Some problems with logging commands/arguments containingg percent characters. Should be fixed.
	041030	-	First release.
*/
#include <amxmodx>
#include <amxmisc>

#define MAXCMDS				64 // If you need to register more tahn 64 cmds for the filter, increase this number accordingly, then recompile.
#define CMDSIZE 			63
#define BUFFERSIZE			511
#define CVAR_CUSTOMLOGFILE	"commandlogger_filepath"
#define CVAR_LOGSETTING		"commandlogger_logto"
#define CVAR_FILTER			"commandlogger_filter"

new g_reggedCmdsNum = 0
new g_reggedCmds[MAXCMDS][CMDSIZE + 1]
new g_cmdLine[BUFFERSIZE + 1]

public client_command(id) {
	read_argv(0, g_cmdLine, 511)
	new tempargs[512]
	read_args(tempargs, 511)
	format(g_cmdLine, 511, "%s %s", g_cmdLine, tempargs)

	if (get_cvar_num(CVAR_FILTER)) {
		new bool:hit = false
		// Match contents against registered cmds
		for (new i = 0; i < g_reggedCmdsNum; i++) {
			if (containi(g_cmdLine, g_reggedCmds[i]) != -1) {
				hit = true
				break
			}
		}

		if (!hit)
			return PLUGIN_CONTINUE
	}

	new name[32], steamid[32]
	get_user_name(id, name, 31)
	get_user_authid(id, steamid, 31)

	format(g_cmdLine, BUFFERSIZE, "%s/%s command: ^"%s^"", name, steamid, g_cmdLine)

	new formated[BUFFERSIZE * 2 + 1]
	format_cmd(formated, BUFFERSIZE * 2, g_cmdLine)
	//server_print("log formats %s into %s", g_cmdLine, formated)
	switch(get_cvar_num(CVAR_LOGSETTING)) {
		case 1: { // HL logs
			log_message(formated)
			//server_print("Logged %s to HL logs", g_cmdLine)
		}
		case 2: { // Custom logfile
			new customfile[128]
			get_cvar_string(CVAR_CUSTOMLOGFILE, customfile, 127)
			log_to_file(customfile, formated)
			//server_print("Logged %s to custom file %s", g_cmdLine, customfile)
		}
		default: { // AMXX logs
			log_amx(formated)
			//server_print("Logged %s to AMXX logs", g_cmdLine)
		}
	}

	return PLUGIN_CONTINUE
}

format_cmd(to[], const TO_LEN, source[]) {
	new toLen = 0
	new const SOURCELENGTH = strlen(source)

	for (new i = 0; i < SOURCELENGTH; i++) {
		if (source[i] != '%')
			toLen += format(to[toLen], TO_LEN - toLen, "%c", source[i])
		else
			toLen += format(to[toLen], TO_LEN - toLen, "%%%%")
	}
	to[toLen] = 0
}

public regfn(id, level, cid) {
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[CMDSIZE + 1]
	read_argv(1, arg, CMDSIZE)

	if (g_reggedCmdsNum + 1 > MAXCMDS) {
		server_print("[%s] WARNING: Couldn't register ^"%s^" because maximum number of commands to log (%d) has been reached!", PLUGINNAME, arg, MAXCMDS)
		return PLUGIN_HANDLED
	}

	g_reggedCmds[g_reggedCmdsNum] = arg
	server_print("[%s] ^"%s^" added to filter.", PLUGINNAME, g_reggedCmds[g_reggedCmdsNum])
	g_reggedCmdsNum++

	return PLUGIN_HANDLED
}

public plugin_init() {
	register_plugin(PLUGINNAME, VERSION, AUTHOR)

	register_cvar(CVAR_CUSTOMLOGFILE, "customfilepath.log")
	register_cvar(CVAR_LOGSETTING, "0")
	register_cvar(CVAR_FILTER, "1")

	//register_srvcmd("0cl", "client_command") (used to test from server console, you don't need it)

	register_srvcmd("commandlogger_register", "regfn", -1, "<cmd> - registers cmd to log use of it by clients")
}
