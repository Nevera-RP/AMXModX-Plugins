/*---------------------------------------------------------------------------
 |               Quake Sounds & Sprites (v1.2)  © 2011			    |
 |                    					     	            |
 |     		 Plugin by Dusan (Uncut*) Stojadinovic	   		    |
 |									    |
 |     Made 16. II 2011. 		    Contact - uncut.wz@gmail.com    |
 --------------------------------------------------------------------------*/

#include <amxmodx>
#include <amxmisc>

new const PLUGIN[] 	= "Quake Sounds & Sprites"
new const VERSION[] 	= "1.0"
new const AUTHOR[] 	= "Uncut*"


new bool:vec_bio_fb, bool:kills[32], bool:firstblood[32], bool:headshot[32], bool:hum[32]
new hs, gl, hu, mg, mk, rp, uk, ws, dk, fs
new c_on, c_hum, c_hs, c_spr, c_first

new killovi[32]
new HS[32]

public plugin_precache()
{
			
	hs = precache_model("sprites/uncut/heads.spr")
	gl = precache_model("sprites/uncut/godlike.spr")
	hu = precache_model("sprites/uncut/hum.spr")
	mg = precache_model("sprites/uncut/mega.spr")
	mk = precache_model("sprites/uncut/multi.spr")
	rp = precache_model("sprites/uncut/rampage.spr")
	uk = precache_model("sprites/uncut/ultrakills.spr")
	ws = precache_model("sprites/uncut/wickedsick.spr")
	fs = precache_model("sprites/uncut/first.spr")		
	dk = precache_model("sprites/uncut/double.spr")
		
			
	//precache_sound("costum/doublekill.wav")
	//precache_sound("costum/firstblood.wav")
	//precache_sound("costum/headhunter.wav")
	//precache_sound("costum/multikill.wav")
	//precache_sound("costum/megakill.wav")
	//precache_sound("costum/ultrakill.wav")
	//precache_sound("costum/killingspree.wav")
	//precache_sound("costum/wickedsick.wav")
	//precache_sound("costum/rampage.wav")
	//precache_sound("costum/godlike.wav")
	//precache_sound("costum/holyshit.wav")
	//precache_sound("costum/headshot.wav")
	//precache_sound("costum/humiliation.wav")
		
	
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("quakesprite", "1.0" , (FCVAR_SERVER|FCVAR_SPONLY))
	register_cvar("uncut", "1.0" , (FCVAR_SERVER|FCVAR_SPONLY))
	
	c_on = register_cvar("amx_qsprite_on", "1")
	c_hum = register_cvar("amx_qsprite_hum", "1")
	c_hs = register_cvar("amx_qsprite_hs", "1")
	c_spr = register_cvar("amx_qsprite_spr", "1")
	c_first = register_cvar("amx_qsprite_first", "1")
	
	
	//register_clcmd("say /quake", "motd_reklame")
	//register_clcmd("say /sprite", "motd_reklame")
		
	register_event("DeathMsg", "death_poruka", "a")
	register_event("DeathMsg", "death_headshot", "a", "3=1")
	register_event("DeathMsg","death_noz","a","4&kni")
	register_logevent("restartrunde", 2, "1=Round_Start")

	//set_task(240.0,"reklama" , _ , _ , _ , "b")  

	
}
public restartrunde() vec_bio_fb = false
public client_disconnect(id){
	killovi[id]= 0
	HS[id]= 0
}
public client_putinserver(id){
	killovi[id]= 0
	HS[id]= 0
}
	
public death_poruka(){
	
	
	new nime[32], zime[32]
	
	new napadac = read_data(1)
	new zrtva = read_data(2)
	
	killovi[napadac] += 1
	killovi[zrtva]= 0
	HS[zrtva]= 0
	
	
	get_user_name(napadac, nime,31)
	get_user_name(zrtva, zime,31)
	
	if((zrtva == napadac) || (get_user_team(napadac) == get_user_team(zrtva)) || !zrtva || !napadac)
			return PLUGIN_CONTINUE
			
	
	
	if(!vec_bio_fb && get_pcvar_num(c_first) == 1){
		vec_bio_fb = true
		stavi_sprajt(zrtva, fs)
		firstblood[zrtva] = true
		
				
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 0.0, 5.0)
		show_hudmessage(0, "%s je prva zrtva!!",zime)
	}
	if(killovi[napadac] == 2){
		if(!firstblood[zrtva]){
			stavi_sprajt(zrtva, dk)
			kills[zrtva] = true
			
		}
		
		
	}
	if(killovi[napadac] == 3 ){
		if(!firstblood[zrtva]){
			stavi_sprajt(zrtva, mk)
			kills[zrtva] = true
		}
		
		
	}
	if(killovi[napadac] == 5){
		if(!firstblood[zrtva]){
			stavi_sprajt(zrtva, mg)
			kills[zrtva] = true
		}
		
		
	}
	if(killovi[napadac] == 7){
		if(!firstblood[zrtva]){
			stavi_sprajt(zrtva, uk)
			kills[zrtva] = true
		}
		
		
	}
	if(killovi[napadac] == 9){
	
		
	}
	if(killovi[napadac] == 10){
		if(!firstblood[zrtva]){
			stavi_sprajt(zrtva, rp)
			kills[zrtva] = true
		}
		
		
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 0.0, 5.0)
		show_hudmessage(0, "%s Rampage (10kills)!!",nime)
		
	}
	if(killovi[napadac] == 12 ){
		
		if(!firstblood[zrtva]){
			kills[zrtva] = true
			stavi_sprajt(zrtva, gl)
		}
		
		
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 0.0, 5.0)
		show_hudmessage(0, "%s God Like (12kills)!!",nime)

	}
	if(killovi[napadac] == 15){
		
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 0.0, 5.0)
		show_hudmessage(0, "%s Holy Shit (15kills)!!", nime)

	}
	
	return PLUGIN_CONTINUE
}
public death_headshot(){
	
	
	new nime[32], zime[32]
	
	new napadac = read_data(1)
	new zrtva = read_data(2)
	
	
	get_user_name(napadac, nime,31)
	get_user_name(zrtva, zime,31)
	
	if(get_pcvar_num(c_hs) != 1 || get_pcvar_num(c_on) != 1)
		return PLUGIN_CONTINUE
	
	
	HS[napadac] += 1
	HS[zrtva]= 0
	killovi[zrtva]= 0
	
	if((zrtva == napadac) || (get_user_team(napadac) == get_user_team(zrtva)) || !zrtva || !napadac)
			return PLUGIN_CONTINUE
			
	if(HS[napadac] == 3) {

				
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 0.0, 5.0)
		show_hudmessage(0, "%s je Headhunter!!",nime)
		
			}
	if(HS[napadac] == 5) {
				
		if(!firstblood[zrtva] && !kills[zrtva] && !hum[zrtva])
			stavi_sprajt(zrtva, ws)
			
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 0.0, 5.0)
		show_hudmessage(0, "%s je WickedSick!!",nime)
				
	}	
		
	else {
		if(!firstblood[zrtva] && !kills[zrtva] && !hum[zrtva]){
			headshot[zrtva] = true
			stavi_sprajt(zrtva, hs)
		}
			
	}
		
	return PLUGIN_CONTINUE
}
public death_noz(){
	
	
	new nime[32], zime[32]
	
	new napadac = read_data(1)
	new zrtva = read_data(2)
	
	HS[zrtva]= 0
	killovi[zrtva]= 0
	
	if(get_pcvar_num(c_hum) == 0 || get_pcvar_num(c_on) != 1)
		return PLUGIN_CONTINUE
	
	get_user_name(napadac, nime,31)
	get_user_name(zrtva, zime,31)
	
	if((zrtva == napadac) || (get_user_team(napadac) == get_user_team(zrtva)) || !zrtva || !napadac)
		return PLUGIN_CONTINUE
	
	if(!firstblood[zrtva] && !kills[zrtva]){
		stavi_sprajt(zrtva, hu)
		hum[zrtva] = true
	}
	
	
	set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 0.0, 5.0)
	show_hudmessage(0, "%s je zaklao %s | Humiliation!!",nime,zime)
		
	return PLUGIN_CONTINUE
}
	
public stavi_sprajt(id, sprajt){
	
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE
		
	if(get_pcvar_num(c_spr) != 1 || get_pcvar_num(c_on) != 1)
		return PLUGIN_CONTINUE
	
	
	
	static origin[3]
	get_user_origin(id, origin)
		
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+60)
	write_short(sprajt)
	write_byte(10)
	write_byte(250)
	message_end()
	
	set_task(0.2, "podesi_boolove", id)
	
	return PLUGIN_CONTINUE
}
public podesi_boolove(id){
	
	kills[id] = false
	firstblood[id] = false
	headshot[id] = false
	hum[id] = false
}
