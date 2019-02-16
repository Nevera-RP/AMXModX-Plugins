/* This is an AMXMODX Script
*
*
*   Thanks to Kensai for testing this with me and helping me figure some stuff out.
*   Thanks to GHW_Chronic for adding a large chunk for me.
*
*   version 1.3 - GHW_Chronic added a music.ini file where you put song names in to precache them.
*
*   Version 1.2 - Script works due to GHW_Chronic, added stopplay & say /stop commands as well as making the 2 amx_play commands into one.
*
*/

#include <amxmodx>
#include <amxmisc>

#define MAX_SONGS	10

new configsdir[200]
new configfile[200]
new song[MAX_SONGS][64]
new songdir[MAX_SONGS][64]
new bool:precached[MAX_SONGS]

public plugin_init()
{
	register_plugin("MP3 + Wav Player W/ music.ini Precacher","1.3","GHW_Chronic + bizzybone")
	register_concmd("amx_play","cmd_play",ADMIN_LEVEL_E," <Part Of Filename> ")
	register_concmd("amx_playlist","cmd_playlist",ADMIN_LEVEL_E," Displays a list of songs in the server playlist. ")
	register_concmd("amx_stopplay","cmd_Stop",ADMIN_LEVEL_E," Stops currently playing sounds/music. ")
	register_clcmd("say /stop","cl_cmd_stop")
}

public plugin_precache()
{
	new songdir2[64]
	get_configsdir(configsdir,199)
	format(configfile,199,"%s/REMusic.ini",configsdir)
	new trash
	for(new i=0;i<MAX_SONGS;i++)
	{
		precached[i]=false
		read_file(configfile,i,song[i],63,trash)
		if(!equali(song[i][4],""))
		{
			format(songdir[i],63,"%s",song[i])
			format(songdir2,63,"sound/%s",song[i])
			if(file_exists(songdir2))
			{
				precached[i]=true
				//precache_sound(songdir[i])
			}
		}
	}
}

public cmd_playlist(id,level,cid)
{
	console_print(id,"Songs in server playlist:")
	for(new i=0;i<MAX_SONGS;i++)
	{
		if(precached[i])
		{
			console_print(id,song[i])
		}
	}
	return PLUGIN_HANDLED
}

public cmd_Stop(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	client_cmd(0,"mp3 stop;stopsound")
	client_print(0,print_chat,"Admin Turned The Music Off.")
	return PLUGIN_HANDLED
}

public cmd_play(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
	{
		return PLUGIN_HANDLED
	}
	new arg1[32]
	read_argv(1,arg1,31)
	new songnum = MAX_SONGS
	for(new i=0;i<MAX_SONGS;i++)
	{
		if(precached[i] && containi(song[i],arg1)!=-1)
		{
			if(songnum!=MAX_SONGS)
			{
				console_print(id,"More than one file contains that phrase in it.")
				return PLUGIN_HANDLED
			}
			songnum = i
		}
	}
	if(songnum==MAX_SONGS)
	{
		console_print(id,"No file containing that phrase was found. Type amx_playlist to see songlist.")
		return PLUGIN_HANDLED
	}
	if(containi(song[songnum],".mp3"))
	{
		client_cmd(0,"mp3 play ^"sound/%s^"",songdir[songnum])
	}
	if(containi(song[songnum],".wav"))
	{
		client_cmd(0,"spk ^"%s^"",songdir[songnum])
	}
	client_print(0,print_chat,"Admin Has Played File ^"%s^" If you don't want to hear it, say /stop",song[songnum])
	return PLUGIN_HANDLED
}

public cl_cmd_stop(id)
{
	client_cmd(id,"mp3 stop;stopsound")
	client_print(id,print_chat,"Music stopped")
	return PLUGIN_HANDLED
}
