/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 01-05-08
*
*  ============
*   Changelog:
*  ============
*
*  v1.1
*    -Added advertise_len cvar
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"1.1"

#include <amxmodx>
#include <amxmisc>

new configfile[200]
new logfile[200]

public plugin_init()
{
	register_plugin("GHW Say Commands",VERSION,"GHW_Chronic")
	register_cvar("say_commands_toggle","1")
	register_concmd("amx_say_commands_toggle","cmd_toggle",ADMIN_LEVEL_C,"<1/on 0/off> Toggle the custom Say Commands off/on")
	register_clcmd("say","hook_say")
	register_clcmd("say_team","hook_say")
	register_clcmd("client_commands","list_commands")
	new configsdir[200]
	get_configsdir(configsdir,199)
	format(configfile,199,"%s/say_commands.ini",configsdir)
	format(logfile,199,"%s/say_commands_log.log",configsdir)
	register_cvar("advrtise_len","500.0")
}

public client_putinserver(id)
{
	if(get_cvar_num("advrtise_len")>0) set_task(get_cvar_float("advrtise_len"),"advertise",id)
}

public client_disconnect(id)
{
	remove_task(id)
}

public advertise(id)
{
	if(get_cvar_num("say_commands_toggle"))
	{
		client_print(id,print_chat,"[AMXX] Type client_commands in console to view a list of useful client commands.")
	}
	set_task(260.6,"advertise",id)
	return PLUGIN_HANDLED
}

public cmd_toggle(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
	{
		return PLUGIN_HANDLED
	}
	new arg1[32]
	read_argv(1,arg1,31)
	if(get_cvar_num("say_commands_toggle"))
	{
		if(equali(arg1,"on") || equali(arg1,"1"))
		{
			console_print(id,"Custom Say Commands Plugin is already toggled on.")
		}
		else
		{
			console_print(id,"Custom Say Commands Plugin has been toggled off.")
			set_cvar_num("say_commands_toggle",0)
		}
	}
	else if(!get_cvar_num("say_commands_toggle"))
	{
		if(equali(arg1,"on") || equali(arg1,"1"))
		{
			console_print(id,"Custom Say Commands Plugin has been toggled on.")
			set_cvar_num("say_commands_toggle",1)
		}
		else
		{
			console_print(id,"Custom Say Commands Plugin is already toggled off.")
		}
	}
	return PLUGIN_HANDLED
}

public hook_say(id)
{
	if(!get_cvar_num("say_commands_toggle") || !file_exists(configfile))
	{
		return PLUGIN_CONTINUE
	}
	for(new i=0;i<=file_size(configfile,1) - 1;i++)
	{
		new read[32]
		new trash
		read_file(configfile,i,read,31,trash)
		if(containi(read,"]")==0)
		{
			new text[200]
			read_args(text,199)
			remove_quotes(text)
			replace(read,31,"]","")
			new read2[32]
			read_file(configfile,i+1,read2,31,trash)
			new bool:continuea=false
			if(equali(read2,"exact") && containi(text,read)==0)
			{
				continuea=true
			}
			if(equali(read2,"contain") && containi(text,read)!=-1)
			{
				continuea=true
			}
			if(continuea)
			{
				new read3[32]
				read_file(configfile,i+2,read3,31,trash)
				new show = PLUGIN_CONTINUE
				if(equali(read3,"don't show"))
				{
					show = PLUGIN_HANDLED
				}

				new read4[32]
				read_file(configfile,i+3,read4,31,trash)
				if(equali(read4,"MOTD"))
				{
					new read5[200]
					read_file(configfile,i+4,read5,199,trash)

					new name[32]
					get_user_name(id,name,31)
					new hostname[32]
					get_cvar_string("hostname",hostname,31)
					new ip[32]
					get_user_ip(0,ip,31,0)
					new ping1, loss1, ping[8], loss[8]
					get_user_ping(id,ping1,loss1)
					format(ping,7,"%d",ping1)
					format(loss,7,"%d",loss1)
					new date[32]
					format_time(date,31,"%m-%d-%Y",-1)
					new time[32]
					format_time(time,31,"%H:%M",-1)
					new map[32]
					get_mapname(map,31)
					new frags1 = get_user_frags(id)
					new deaths1 = get_user_deaths(id)
					new frags[8], deaths[8]
					format(frags,7,"%d",frags1)
					format(deaths,7,"%d",deaths1)
					new authid[32]
					get_user_authid(id,authid,31)
					new team[32]
					get_user_team(id,team,31)
					while(contain(read5,"%name")!=-1)
					{
						replace(read5,199,"%name",name)
					}
					while(contain(read5,"%hostname")!=-1)
					{
						replace(read5,199,"%hostname",hostname)
					}
					while(contain(read5,"%ip")!=-1)
					{
						replace(read5,199,"%ip",ip)
					}
					while(contain(read5,"%ping")!=-1)
					{
						replace(read5,199,"%ping",ping)
					}
					while(contain(read5,"%loss")!=-1)
					{
						replace(read5,199,"%loss",loss)
					}
					while(contain(read5,"%date")!=-1)
					{
						replace(read5,199,"%date",date)
					}
					while(contain(read5,"%time")!=-1)
					{
						replace(read5,199,"%time",time)
					}
					while(contain(read5,"%map")!=-1)
					{
						replace(read5,199,"%map",map)
					}
					while(contain(read5,"%frags")!=-1)
					{
						replace(read5,199,"%frags",frags)
					}
					while(contain(read5,"%deaths")!=-1)
					{
						replace(read5,199,"%deaths",deaths)
					}
					while(contain(read5,"%authid")!=-1)
					{
						replace(read5,199,"%authid",authid)
					}
					while(contain(read5,"%team")!=-1)
					{
						replace(read5,199,"%team",team)
					}
					while(contain(text,read)!=-1)
					{
						replace(text,199,read,"")
					}
					while(contain(read5,"%text")!=-1)
					{
						replace(read5,199,"%text",text)
					}

					if(containi(read5,"HTTP://")==0)
					{
						new motdtext[500]
						format(motdtext,499,"<body bgcolor=#000><iframe src=^"%s^" border=0 frameborder=0 width=100%% height=100%%></body>",read5)
						show_motd(id,motdtext,"Budapest International")
					}
					else
					{
						show_motd(id,read5,"Budapest International")
					} 
					new read6[32]
					read_file(configfile,i+5,read6,31,trash)
					if(equali(read6,"log"))
					{
						new authida[32]
						get_user_authid(id,authida,31)
						new namea[32]
						get_user_name(id,namea,31)
						new tolog[300]
						format(tolog,299,"%s (%s) : %s",namea,authida,text)
						write_file(logfile,"",-1)
						write_file(logfile,tolog,-1)
					}
					return show;
				}
				if(equali(read4,"text") || equali(read4,"center"))
				{
					new printwhere = print_chat
					if(equali(read4,"center"))
					{
						printwhere = print_center
					}
					new read5[32]
					read_file(configfile,i+4,read5,31,trash)
					new read6[200]
					read_file(configfile,i+5,read6,199,trash)




					new name[32]
					get_user_name(id,name,31)
					new hostname[32]
					get_cvar_string("hostname",hostname,31)
					new ip[32]
					get_user_ip(0,ip,31,0)
					new ping1, loss1, ping[8], loss[8]
					get_user_ping(id,ping1,loss1)
					format(ping,7,"%d",ping1)
					format(loss,7,"%d",loss1)
					new date[32]
					format_time(date,31,"%m-%d-%Y",-1)
					new time[32]
					format_time(time,31,"%H:%M",-1)
					new map[32]
					get_mapname(map,31)
					new frags1 = get_user_frags(id)
					new deaths1 = get_user_deaths(id)
					new frags[8], deaths[8]
					format(frags,7,"%d",frags1)
					format(deaths,7,"%d",deaths1)
					new authid[32]
					get_user_authid(id,authid,31)
					new team[32]
					get_user_team(id,team,31)
					while(contain(read6,"%name")!=-1)
					{
						replace(read6,199,"%name",name)
					}
					while(contain(read6,"%hostname")!=-1)
					{
						replace(read6,199,"%hostname",hostname)
					}
					while(contain(read6,"%ip")!=-1)
					{
						replace(read6,199,"%ip",ip)
					}
					while(contain(read6,"%ping")!=-1)
					{
						replace(read6,199,"%ping",ping)
					}
					while(contain(read6,"%loss")!=-1)
					{
						replace(read6,199,"%loss",loss)
					}
					while(contain(read6,"%date")!=-1)
					{
						replace(read6,199,"%date",date)
					}
					while(contain(read6,"%time")!=-1)
					{
						replace(read6,199,"%time",time)
					}
					while(contain(read6,"%map")!=-1)
					{
						replace(read6,199,"%map",map)
					}
					while(contain(read6,"%frags")!=-1)
					{
						replace(read6,199,"%frags",frags)
					}
					while(contain(read6,"%deaths")!=-1)
					{
						replace(read6,199,"%deaths",deaths)
					}
					while(contain(read6,"%authid")!=-1)
					{
						replace(read6,199,"%authid",authid)
					}
					while(contain(read6,"%team")!=-1)
					{
						replace(read6,199,"%team",team)
					}

					while(contain(text,read)!=-1)
					{
						replace(text,199,read,"")
					}
					while(contain(read6,"%text")!=-1)
					{
						replace(read6,199,"%text",text)
					}


					if(equali(read5,"All"))
					{
						client_print(0,printwhere,"%s",read6)
					}
					else if(equali(read5,"Player"))
					{
						client_print(id,printwhere,"%s",read6)
					}
					else
					{
						for(new i2=1;i2<=32;i2++)
						{
							if(is_user_connected(i2))
							{
								new team[32]
								get_user_team(i2,team,31)
								if(containi(team,read5)!=-1)
								{
									client_print(i2,printwhere,"%s",read6)
								}
							}
						}
					}
					new read7[32]
					read_file(configfile,i+6,read7,31,trash)
					if(equali(read7,"log"))
					{
						new authida[32]
						get_user_authid(id,authida,31)
						new namea[32]
						get_user_name(id,namea,31)
						new tolog[300]
						format(tolog,299,"%s (%s) : %s",namea,authida,text)
						write_file(logfile,"",-1)
						write_file(logfile,tolog,-1)
					}
					return show;
				}
				if(equali(read4,"hud"))
				{
					new read5[200]
					read_file(configfile,i+4,read5,199,trash)
					new red, green, blue
					if(equali(read5,"White"))
					{
						red=255
						green=255
						blue=255
					}
					else if(equali(read5,"Indigo"))
					{
						red=0
						green=255
						blue=255
					}
					else if(equali(read5,"Pink"))
					{
						red=255
						green=0
						blue=128
					}
					else if(equali(read5,"Orange"))
					{
						red=255
						green=128
						blue=64
					}
					else if(equali(read5,"Yellow"))
					{
						red=255
						green=255
					}
					else if(equali(read5,"green"))
					{
						green=255
					}
					else if(equali(read5,"blue"))
					{
						blue=255
					}
					else
					{
						red=255
					}
					set_hudmessage(red,green,blue,-1.0,0.32,0,6.0,5.0)
					new read6[32]
					read_file(configfile,i+5,read6,31,trash)
					new read7[200]
					read_file(configfile,i+6,read7,199,trash)



					new name[32]
					get_user_name(id,name,31)
					new hostname[32]
					get_cvar_string("hostname",hostname,31)
					new ip[32]
					get_user_ip(0,ip,31,0)
					new ping1, loss1, ping[8], loss[8]
					get_user_ping(id,ping1,loss1)
					format(ping,7,"%d",ping1)
					format(loss,7,"%d",loss1)
					new date[32]
					format_time(date,31,"%m-%d-%Y",-1)
					new time[32]
					format_time(time,31,"%H:%M",-1)
					new map[32]
					get_mapname(map,31)
					new frags1 = get_user_frags(id)
					new deaths1 = get_user_deaths(id)
					new frags[8], deaths[8]
					format(frags,7,"%d",frags1)
					format(deaths,7,"%d",deaths1)
					new authid[32]
					get_user_authid(id,authid,31)
					new team[32]
					get_user_team(id,team,31)
					while(contain(read7,"%name")!=-1)
					{
						replace(read7,199,"%name",name)
					}
					while(contain(read7,"%hostname")!=-1)
					{
						replace(read7,199,"%hostname",hostname)
					}
					while(contain(read7,"%ip")!=-1)
					{
						replace(read7,199,"%ip",ip)
					}
					while(contain(read7,"%ping")!=-1)
					{
						replace(read7,199,"%ping",ping)
					}
					while(contain(read7,"%loss")!=-1)
					{
						replace(read7,199,"%loss",loss)
					}
					while(contain(read7,"%date")!=-1)
					{
						replace(read7,199,"%date",date)
					}
					while(contain(read7,"%time")!=-1)
					{
						replace(read7,199,"%time",time)
					}
					while(contain(read7,"%map")!=-1)
					{
						replace(read7,199,"%map",map)
					}
					while(contain(read7,"%frags")!=-1)
					{
						replace(read7,199,"%frags",frags)
					}
					while(contain(read7,"%deaths")!=-1)
					{
						replace(read7,199,"%deaths",deaths)
					}
					while(contain(read7,"%authid")!=-1)
					{
						replace(read7,199,"%authid",authid)
					}
					while(contain(read7,"%team")!=-1)
					{
						replace(read7,199,"%team",team)
					}
					while(contain(text,read)!=-1)
					{
						replace(text,199,read,"")
					}
					while(contain(read7,"%text")!=-1)
					{
						replace(read7,199,"%text",text)
					}



					if(equali(read6,"All"))
					{
						show_hudmessage(0,"%s",read7)
					}
					else if(equali(read6,"Player"))
					{
						show_hudmessage(id,"%s",read7)
					}
					else
					{
						for(new i2=1;i2<=32;i2++)
						{
							if(is_user_connected(i2))
							{
								new team[32]
								get_user_team(i2,team,31)
								if(containi(team,read6)!=-1)
								{
									show_hudmessage(i2,"%s",text)
								}
							}
						}
					}
					new read8[32]
					read_file(configfile,i+7,read8,31,trash)
					if(equali(read8,"log"))
					{
						new authida[32]
						get_user_authid(id,authida,31)
						new namea[32]
						get_user_name(id,namea,31)
						new tolog[300]
						format(tolog,299,"%s (%s) : %s",namea,authida,tolog)
						write_file(logfile,"",-1)
						write_file(logfile,tolog,-1)
					}
					return show;
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}

public list_commands(id)
{
	if(!get_cvar_num("say_commands_toggle") || !file_exists(configfile))
	{
		console_print(id,"Say Commands you can do:")
		console_print(id,"-----|-----")
		console_print(id,"None.")
		console_print(id,"-----|-----")
		return PLUGIN_HANDLED
	}
	console_print(id,"Say Commands you can do:")
	console_print(id,"-----|-----")
	for(new i=0;i<=file_size(configfile,1) - 1;i++)
	{
		new read[32]
		new trash
		read_file(configfile,i,read,31,trash)
		if(containi(read,"]")==0)
		{
			replace(read,31,"]","")
			new read2[32]
			read_file(configfile,i+1,read2,31,trash)
			if(equali(read2,"exact"))
			{
				console_print(id,"%s",read)
			}
		}
	}
	console_print(id,"-----|-----")
	return PLUGIN_HANDLED
}
