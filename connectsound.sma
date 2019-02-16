/*
* Plays a welcome sound to the player who connects
*
* by White Panther
*
* v1.0
*
* v1.1:
*	- addition to add easily own sounds
*
* v1.2.1:
*	- bug with not playing sounds to client fixed
*	- added file exist check for soundfile
*
* v1.2.3:
*	- fixed
*		- docu bug
*	- changes:
*		- way of giving id to timer
*/

#include <amxmodx>

// change this number to the amount of sounds u have
#define Maxsounds 2

// add here your sounds, sounds must be somewhere in <ModDir>/sound
// format must be like: {"misc/sound1","ambience/sound2"}
new soundlist[Maxsounds][] = {"misc/welcomebudapest", "misc/prepare"}

new plugin_author[] = "White Panther"
new plugin_version[] = "1.2.3"

public plugin_init( )
{
	register_plugin("Connect Sound", plugin_version, plugin_author)
	register_cvar("connectsound_version", plugin_version, FCVAR_SERVER)
}

public plugin_precache( )
{
	new temp[128], soundfile[128]
	for ( new a = 0; a < Maxsounds; a++ )
	{
		format(temp, 127, "sound/%s.wav", soundlist[a])
		if ( file_exists(temp) )
		{
			format(soundfile, 127, "%s.wav", soundlist[a])
			precache_sound(soundfile)
		}
	}
}

public client_putinserver( id )
{
	set_task(1.0, "consound", 100 + id)
}

public consound( timerid_id )
{
	new id = timerid_id - 100
	new Usertime
	Usertime = get_user_time(id, 0)
	if ( Usertime <= 0 )
	{
		set_task(1.0, "consound", timerid_id)
	}else
	{
		new i = random(Maxsounds)
		client_cmd(id, "spk ^"%s^"", soundlist[0])
	}
	
	return PLUGIN_CONTINUE
}