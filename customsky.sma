#include <amxmodx>
#include <amxmisc>

#define PLUGIN 	"custom sky"
#define VERSION "1.1"
#define AUTHOR 	"cheap_suit"

#define max_suffix 6
new g_suffix[max_suffix][3] = { "up", "dn", "ft", "bk", "lf", "rt" }

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(PLUGIN, VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	
	register_cvar("sv_customsky", "1")
	register_cvar("sv_customskyname", "test_")
	
	switch(get_cvar_num("sv_customsky"))
	{
		case 1:
		{
			static configsdir[32]
			get_configsdir(configsdir, 31)
			
			static file[64]
			formatex(file, 63, "%s/custom_sky.cfg", configsdir)
			
			static mapname[32]
			get_mapname(mapname, 31)
			
			if(!file_exists(file)) 
			{
				write_file(file, "; Custom map sky config")
				write_file(file, "; Format: <mapname>  <skyname>")
			}
	
			new line = 0, length = 0
			static text[64], maptext[32], tgatext[32]
			while(read_file(file, line++, text, 127, length)) 
			{
				if((text[0] == ';') || !length)
					continue
						
				parse(text, maptext, 31, tgatext, 31)
				if(equal(maptext, mapname))
				{
					precache_sky(tgatext)
					break
				}
			}
		}
		case 2:
		{
			static cvar_skyname[32]
			get_cvar_string("sv_customskyname", cvar_skyname, 31)
			
			if(strlen(cvar_skyname) > 0)
				precache_sky(cvar_skyname)
		}
	}
}

public precache_sky(const skyname[])
{
	new bool:found = true
	static tgafile[35]
	
	for(new i = 0; i < max_suffix; ++i)
	{
		formatex(tgafile, 34, "gfx/env/%s%s.tga", skyname, g_suffix[i])
		if(file_exists(tgafile))
			precache_generic(tgafile)
		else
		{
			log_amx("Cannot locate file '%s'", tgafile)
			found = false
			break
		}
	}
	
	if(found)
		set_cvar_string("sv_skyname", skyname)
}
