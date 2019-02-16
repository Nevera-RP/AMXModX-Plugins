#include <amxmodx>
#include <amxmisc>

new PLUGIN[]="Mapend Sounds"
new AUTHOR[]="ntfs"
new VERSION[]="1.33"
new soundfile[128]
new cached

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("mapend_sounds", VERSION, FCVAR_SERVER)
	set_task(1.0, "exec_sound", 0, "", 1, "d", 1)
	register_cvar("amx_mapend_sounds_advert", "1")
}

public plugin_precache()
{
	new txtlen
	new loop
	new line
	new config[64]
	get_configsdir(config, 63)
	format(config, 63, "%s/Mapend-Sounds.cfg", config)
	new lines = file_size(config, 1)	

	if (file_exists(config))
	{
		while(cached != 1 && loop < 10)		// run until a sound was found(cached),
		{ 					// or the maximum numbers of loops 
			line = random_num(0,lines)	// has been reached
			
			read_file(config,line,soundfile,128,txtlen)
			
			if(containi(soundfile,".mp3") != -1)
			{
				if((file_exists(soundfile) == 1) && (equal(soundfile[0],";",1) != 1))
				{
					precache_generic(soundfile)
					server_print("[AMXX] Mapend-Sounds: Caching ^"%s^".", soundfile)
					cached = 1
				}
				else
				{
					server_print("[AMXX] Mapend-Sounds: Skipping ^"%s^".", soundfile)
				}
			}
			loop += 1
		}
	}
	else
	{
		write_file(config,"",-1)
	}
}

public exec_sound()
{
	if(cached == 1)
	{
		client_cmd(0, "mp3 play %s", soundfile)
		server_print("[AMXX] Mapend-Sounds: Playing ^"%s^".", soundfile)
		if(get_cvar_num("amx_mapend_sounds_advert") == 1)
		{
			set_hudmessage(42, 42, 255, -1.0, 0.8, 0, 6.0, 12.0, 0.2, 0.2, -1)
			show_hudmessage(0, "- [AMXX] Mapend-Sounds: Playing Sound -")
			client_print(0, print_chat, "- [AMXX] Mapend-Sounds: Playing Sound -")
		}
	}
	else
	{
		server_print("[AMXX] Mapend-Sounds: No Soundfile!!!")
	}
}
