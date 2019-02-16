/*
AMX MOD X Script 
version 0.8
by Enigmaya
developed & tested on cs1.5+amxx1.0 
and successful compiled on amxx1.6 .

thanks 
**Twilight Suzuka (know how to set animation) 
**XxAvalanchexX (answerd me many questions about model's sequence)
**Zenith77 (fix bug,fake player dont float in mid air/fix english :) )

Url:
http://forum.dt-club.net/showthread.php?t=24478 
http://www.amxmodx.org/forums/viewtopic.php?t=20280

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <amxmisc>
#include <fakemeta>

Description 
----------
Creats a Fake Player model 

at   your origin 
with you model
with you view angle
with you action
-----------run(move to you aiming straight ) 
-----------duck
-----------stand
-----------swim
-----------open out both arm
-----------use default animation
with you gun in your hand.
-----------T     glock18,ak47,knife
-----------CT   usp,m4a1,knife
can view from the fake player.
when round end,remove all fake players.
report on radar when enemy close the fake-player,and then turn the round to aiming at the enemy and run to him.
if there is no enemy , he will find way be himself.
can run up or down the stairs or slope.

command:
=============
amx_createmoney 1000 <sets the money when player use this ability>
amx_create_enable 1 <Toggles on/off 1 = ON || 0 = OFF >
amx_playermaxcreate 1 <Sets the amount of Fake Players you can create per round >
amx_roundmaxcreate 10 <Sets the amount of Fake Players in this server you can create per round >

user cmd:
amx_create_s  < build a static Fake Player where you are>
amx_create_d  < build a dynamic Fake Player where you are>
amx_create_b  <build a Fake Player on you side(see screenshot )>
say /spycam   <view from fake player><if you created more than 1,pass 'E' to see another>
say /fakehelp <show help>

update log:
v0.3 2005 10.16
--add function: view from fake player.

v0.4 2005 10.23
--add function: build a Fake Player on you side, with light and beam.

v0.5 2005 10.29
--add function: report on radar when enemy close the fake-player.

v0.6 2005 10.29
--add function: fake-player could turn the round and run to the enemy.

v0.7 2005 10.29
--add function: show help, (say /fakehelp)
--rework some code.

v0.8 2005 10.30
--add function: dynamic fake-player can find way be himself.no longer through the wall.
--add function: dynamic fake-player can run up or down the stairs or slope.
--add function: when you dead,the dynamic fake-player you created will stop think and run.
*/



#include <amxmodx>
#include <cstrike>
#include <engine>
#include <amxmisc>
#include <fakemeta>

#define FAKEPLAYERSPEED 200   //dynamic fake-player run speed

new models[32][33],num
new ent_count[33]
new body_ents[33][999]
new weapon_ents[33][999]
new creators[33]
new round_count=0
new explode
new dot
new bool:dynamic_ent[999]
new g_MaxPlayers
new g_msgHostagePos
new g_msgHostageK

public plugin_init()
{
	register_plugin("fake_player"," 0.8", "Enigmaya")
	register_clcmd("amx_create_s","create_static",0, "- build a static Fake-Player where you are")
	register_clcmd("amx_create_d","create_dynamic",0, "- build a dynamic Fake-Player where you are")
	register_clcmd("amx_create_b","create_body",0, "- build a Fake-Player on you side")
	register_clcmd("say /fakehelp", "dis_motd")
	register_clcmd("say /spycam", "connect_spycam")
	register_clcmd("say_team /spycam", "connect_spycam")
	register_cvar("amx_create_enable","1")
	register_event("ResetHUD","remove_ent","b")
	register_cvar("amx_createmoney","1000")
	register_cvar("amx_pmaxcreate","2")
	register_cvar("amx_rmaxcreate","10") 
	register_think("fake_player","ent_think")
	
	g_MaxPlayers = get_global_int(GL_maxClients)	
	g_msgHostagePos = get_user_msgid("HostagePos")
	g_msgHostageK = get_user_msgid("HostageK")	
}

//--------------------------------show moth---------------------------------
public dis_motd(id)
{
	const SIZE=1536
	new msg[SIZE+1],len=0
	
	len += format(msg[len], SIZE - len, "Command:^n^n")
	len += format(msg[len], SIZE - len, "amx_create_s < build a static Fake-Player where you are >^n")
	len += format(msg[len], SIZE - len, "amx_create_d < build a dynamic Fake-Player where you are >^n")
	len += format(msg[len], SIZE - len, "amx_create_b < build a Fake-Player on you side >^n")
	len += format(msg[len], SIZE - len, "say /spycam  < view from fake player> <if you created more than 1,pass 'E' to see another >^n^n")
	len += format(msg[len], SIZE - len, "Suggest:^n^n")
	len += format(msg[len], SIZE - len, "bind to any button you choose. like this < bind ^"key^" command >^n")
	len += format(msg[len], SIZE - len, "Example: < bind ^"j^" amx_create_s  /  bind ^"n^" say /spycam >^n")
	
	show_motd ( id, msg, "Fake Player help" )
	return PLUGIN_HANDLED
}	

//--------------------------------precache model------------------------------------------
public plugin_precache() 
{
    explode = precache_model("sprites/shockwave.spr")
    dot = precache_model("sprites/laserdot.spr")
    // get custom models
    num = get_models(models,32)

    // loop through them
    for(new i=0;i<num;i++) 
    {
      new modelstring[64];
      format(modelstring,63,"models/player/%s/%s.mdl",models[i],models[i])
      precache_model(modelstring)
    }
}

//-------------------CUSTOM MODEL LIST----------------------------------------------------

public get_models(array[32][],len) 
{
//-------code form Avalanche's "CS User Model Menuz" plugin------------

    // get a list of custom models

    new dirpos, output[64], outlen, filledamt

    // go through custom models
    while((dirpos = read_dir("models/player",dirpos,output,255,outlen)) != 0) 
    {

      if(containi(output,".") == -1) 
      { // if not a file (but a directory)

        // check if model is actually there
        new modelfile[64]
        format(modelfile,63,"models/player/%s/%s.mdl",output,output)

        // if it exists
        if(file_exists(modelfile)) 
	{
          format(array[filledamt],len,"%s",output)
          filledamt += 1
        }

        // if we are out of array space now
        if(filledamt > 32) 
	{
          return filledamt
        }

      }

    }

    return filledamt
}


public client_putinserver(id){
	creators[id]=0
	ent_count[id]=0
	new par[1]
	par[0]=id
	set_task(8.0,"show",0,par,1,"a",0)
}

public show(par[1])
{
	client_print(par[0],print_chat,"[AMXX] *-* In this server you can build Fake-Player! say '/fakehelp' know more.")
}

//-------------------------------create fake player-----------------------------------------------------
//***********static*************
public create_static(id)
{
	if( !check_availability(id) )
		return PLUGIN_HANDLED
	
	new entid=try_build(id)
	if( !entid )
		return PLUGIN_HANDLED
		
	set_static_sequence(id,entid)
	entity_set_float(entid,EV_FL_nextthink,halflife_time() + 0.5) 
	return PLUGIN_HANDLED	
}

//***********dynamic*************
public create_dynamic(id)
{
	if( !check_availability(id) )
		return PLUGIN_HANDLED
	
	new entid=try_build(id)
	if( !entid )
		return PLUGIN_HANDLED
		
	set_dynamic_sequence(id,entid)
	entity_set_float(entid,EV_FL_nextthink,halflife_time() + 0.5) 
	dynamic_ent[entid]=true
	return PLUGIN_HANDLED		
}

try_build(id)
{
	new Float:pOri[3]
	entity_get_vector(id, EV_VEC_origin, pOri)
	new entid=build_now(pOri, id)
	new entwid=add_weapon(id,entid)
	if( entid && entwid ){
		drop_to_floor(entid)
		return entid	
	}
	new par[2]
	par[0]=entid
	par[1]=entwid
	remove_entid(par)
	return 0
}

//**********set_sequence***********
set_static_sequence(id,entPlayer)
{
	new button=get_user_button (id)
	new motion=1//stand
	if( IN_DUCK & button )
		motion=2//duck
	else if(IN_ATTACK & button )
		motion=8//swim
	if( entity_get_int(id,EV_INT_weaponanim)==1 ){
		motion=3//special
	}	
	entity_set_int(entPlayer,EV_INT_sequence,motion)	
}

set_dynamic_sequence(id,entPlayer)
{
	new Float:Vel[3]
	VelocityByAim(id,FAKEPLAYERSPEED,Vel)
	
	new motion=4//run
	//if( entity_get_int(id,EV_INT_weaponanim)==1 ){
		//motion=3//special
		//VelocityByAim(id,80,Vel)
	//}
	Vel[2]=float(0)
	entity_set_vector(entPlayer,EV_VEC_velocity,Vel)//set Velocity
	entity_set_int(entPlayer,EV_INT_sequence,motion)		
}

//**********dispart body***********
public create_body(id)
{
	if( !check_availability(id) )
		return PLUGIN_HANDLED
	
	new Float:playerOrigin[3]
	entity_get_vector(id, EV_VEC_origin, playerOrigin)

  	new Float:vNewOrigin[3]
	new Float:vTraceDirection[3]
	new Float:vTraceEnd[3]
	new Float:vTraceResult[3]
	
	//*******change the angle to set fake player stand on the left, set back later
	new Float:ang[3]
	entity_get_vector(id,EV_VEC_v_angle,ang)
	ang[1]+=90
	entity_set_vector(id,EV_VEC_v_angle,ang)

	//amxx1.6 use  VelocityByAim
	velocity_by_aim(id, 40, vTraceDirection)
	
	//******set back
	ang[1]-=90
	entity_set_vector(id,EV_VEC_v_angle,ang)

	vTraceEnd[0] = vTraceDirection[0] + playerOrigin[0]
	vTraceEnd[1] = vTraceDirection[1] + playerOrigin[1]
	vTraceEnd[2] = vTraceDirection[2] + playerOrigin[2]
	trace_line(id, playerOrigin, vTraceEnd, vTraceResult) 
	vNewOrigin[0] = vTraceResult[0]
	vNewOrigin[1] = vTraceResult[1]
	vNewOrigin[2] = playerOrigin[2]

	//amxx1.6 use PointContents
	if ( point_contents(vNewOrigin) != CONTENTS_EMPTY  || TraceCheckCollides(vNewOrigin, 20.0) ) {
		client_print(id, print_center, "You can't build here!")
		return PLUGIN_HANDLED
	}
	
	new entid=build_now(vNewOrigin, id)
	new entwid=add_weapon(id,entid)
	if( entid && entwid ){
		//take money
		new pmoney=cs_get_user_money(id)-get_cvar_num("amx_createmoney")
		cs_set_user_money(id,pmoney,1)
		entity_set_int(entid,EV_INT_sequence,1)
		set_base(id,playerOrigin,vNewOrigin,entid,entwid)
	}
	return PLUGIN_HANDLED
}

//-----------------------------check_availability-------------------------
check_availability(id)
{
	if( !get_cvar_num("amx_create_enable") ){
		client_print(id,print_chat,"[AMXX] Sorry, this plugin is currently disabled!") 
		return 0
	}
	
	else if( !is_user_alive(id) ){
		client_print(id,print_chat,"[AMXX] You must be alive to build a fake player.") 
		return 0
	}
	
	else if( round_count==get_cvar_num("amx_rmaxcreate") ){
		client_print(id,print_chat,"[AMXX] Sorry, The amount of fake players has reached its max !") 
		return 0
	}
		
	else if( creators[id]==get_cvar_num("amx_pmaxcreate") ){
		client_print(id,print_chat,"[AMXX] You have already created to many times!") 
		return 0
	}
	
	else if( cs_get_user_money(id)<get_cvar_num("amx_createmoney") ){
		client_print(id,print_chat,"[AMXX] You do not have enough money (needed: %i $ )",get_cvar_num("amx_createmoney") )
		return 0
	}	
	
	else if ( !entity_is_on_ground(id) ) {
		client_print(id, print_center, "You must stand on the ground to build it!")
		return 0
	}
	return 1
}	

stock entity_is_on_ground(entity) 
{
	return entity_get_int(entity, EV_INT_flags) & FL_ONGROUND
}

set_base(id,Float:pOri[3],Float:eOri[3],entid,entwid)
{
	new par[2]
	par[0]=entid
	par[1]=entwid
	//par[2]=id

	entity_set_int(entid, EV_INT_movetype,MOVETYPE_TOSS)
	show_explode(id)
	change_origin(id,entid,pOri,eOri)
	set_task(5.0,"remove_entid",77890,par,2)
	return PLUGIN_CONTINUE
}

show_explode(id)
{
	new ori[3]
	get_user_origin(id,ori)
	
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(3)
        write_coord(ori[0])
        write_coord(ori[1])
        write_coord(ori[2])
        write_short(explode)
        write_byte(50)
        write_byte(15)
        write_byte(0)
        message_end()
	
	message_begin( MSG_PAS, SVC_TEMPENTITY, ori )
	write_byte( 21 ) //TE_BEAMCYLINDER
	write_coord( ori[0])
	write_coord( ori[1])
	write_coord( ori[2] + 10)
	write_coord( ori[0])
	write_coord( ori[1])
	write_coord( ori[2] + 10 + 80)
	write_short( explode )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 3 ) // life
	write_byte( 60 )  // width
	write_byte( 0 )	// noise
	write_byte( 255 )  // red
	write_byte( 255 )  // green
	write_byte( 255 )  // blue
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()
	
	return 
}

public remove_entid(par[2])
{
	remove_entity(par[0])
	remove_entity(par[1])
	//creators[ par[2] ]--
	return PLUGIN_HANDLED
}
	
public change_origin(id,entid,Float:pOri[3],Float:eOri[3])
{
	if(!is_user_alive(id) )
		return PLUGIN_HANDLED
		
	new ran=random(2)
	
   	switch(ran){
		case 0:{
			pOri[2]+=70.0
			eOri[2]+=65.0
			entity_set_origin(id,pOri)
			entity_set_origin(entid,eOri)
		}
		case 1:{
			pOri[2]+=65.0
			eOri[2]+=70.0
			entity_set_origin(id,eOri)
			entity_set_origin(entid,pOri)
		}
	}
	return PLUGIN_CONTINUE
}	


//--------Code from JGHg's "Sentry Gun"------------
bool:TraceCheckCollides(Float:origin[3], const Float:BOUNDS) 
{
	new Float:traceEnds[8][3], Float:traceHit[3], hitEnt

	// x, z, y
	traceEnds[0][0] = origin[0] - BOUNDS
	traceEnds[0][1] = origin[1] - BOUNDS
	traceEnds[0][2] = origin[2] - BOUNDS

	traceEnds[1][0] = origin[0] - BOUNDS
	traceEnds[1][1] = origin[1] - BOUNDS
	traceEnds[1][2] = origin[2] + BOUNDS

	traceEnds[2][0] = origin[0] + BOUNDS
	traceEnds[2][1] = origin[1] - BOUNDS
	traceEnds[2][2] = origin[2] + BOUNDS

	traceEnds[3][0] = origin[0] + BOUNDS
	traceEnds[3][1] = origin[1] - BOUNDS
	traceEnds[3][2] = origin[2] - BOUNDS
	//
	traceEnds[4][0] = origin[0] - BOUNDS
	traceEnds[4][1] = origin[1] + BOUNDS
	traceEnds[4][2] = origin[2] - BOUNDS

	traceEnds[5][0] = origin[0] - BOUNDS
	traceEnds[5][1] = origin[1] + BOUNDS
	traceEnds[5][2] = origin[2] + BOUNDS

	traceEnds[6][0] = origin[0] + BOUNDS
	traceEnds[6][1] = origin[1] + BOUNDS
	traceEnds[6][2] = origin[2] + BOUNDS

	traceEnds[7][0] = origin[0] + BOUNDS
	traceEnds[7][1] = origin[1] + BOUNDS
	traceEnds[7][2] = origin[2] - BOUNDS

	for (new i = 0; i < 8; i++) {
		if (point_contents(traceEnds[i]) != CONTENTS_EMPTY)
			return true

		hitEnt = trace_line(0, origin, traceEnds[i], traceHit)
		if (hitEnt != 0)
			return true
		for (new j = 0; j < 3; j++) {
			if (traceEnds[i][j] != traceHit[j])
				return true
		}
	}

	return false
}

//----------------------------------build fake-player------------------------------
public build_now(Float:Ori[3],id)
{
	new Float:Vel[3],Float:angle[3],pmodel[33]  
	
	new entPlayer= create_entity("info_target")
	if( !entPlayer )
		return 0
		
	entity_set_string(entPlayer, EV_SZ_classname, "fake_player")

	//--------set model----------
	cs_get_user_model ( id, pmodel, 32 )
	new mstring[64]
        format(mstring,63,"models/player/%s/%s.mdl",pmodel,pmodel)
	entity_set_model(entPlayer, mstring)
	
	//-------base option-------
	new Float:maxs[3] = {16.0,16.0,36.0} 
    	new Float:mins[3] = {-16.0,-16.0,-36.0} 
    	entity_set_size(entPlayer,mins,maxs) 
	entity_set_int(entPlayer, EV_INT_solid, SOLID_SLIDEBOX)//SOLID_BBOX)    
	entity_set_int(entPlayer, EV_INT_movetype,MOVETYPE_NOCLIP)
	entity_set_edict(entPlayer, EV_ENT_owner, id)
	
	//-------set origin--------
	//entity_get_vector(id,EV_VEC_origin,Ori)
	entity_set_origin(entPlayer, Ori)
	
	//--------set animation-------
	entity_set_float(entPlayer,EV_FL_animtime,2.0) 
    	entity_set_float(entPlayer,EV_FL_framerate,1.0) 
	
	//-----------set angle-----------
	VelocityByAim(id,FAKEPLAYERSPEED,Vel)
	Vel[2]=float(0)
	vector_to_angle(Vel,angle)
	entity_set_vector(entPlayer,EV_VEC_angles,angle)
	entity_set_vector(entPlayer,EV_VEC_v_angle,angle)

	//-------set sequence---------
	/*
	new button=get_user_button (id)
	new motion
	if( !button )
		motion=1//stand
	else if( IN_DUCK & button )
		motion=2//duck
	else if( (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) & button ){
		motion=4//run
		entity_set_vector(entPlayer,EV_VEC_velocity,Vel)//set Velocity
 	}	
	else if(IN_ATTACK & button )
		motion=8//swim
	if( entity_get_int(id,EV_INT_weaponanim)==1 ){
		motion=3//special
		VelocityByAim(id,80,Vel)
		Vel[2]=float(0)
		entity_set_vector(entPlayer,EV_VEC_velocity,Vel)//set Velocity
	}	
	entity_set_int(entPlayer,EV_INT_sequence,motion)
	*/
	
	//------------set to floor---------
	//drop_to_floor(entPlayer)
			
	body_ents[id][creators[id]] = entPlayer
	dynamic_ent[entPlayer]=false//initialize bool:dynamic_ent
	return entPlayer
}

add_weapon(id,entPlayer)
{
	new entWeapon = create_entity("info_target")
	if( !entWeapon )
		return 0	
	entity_set_string(entWeapon, EV_SZ_classname, "weapon")
	entity_set_int(entWeapon, EV_INT_movetype, MOVETYPE_FOLLOW)
	entity_set_int(entWeapon, EV_INT_solid, SOLID_NOT)
	entity_set_edict(entWeapon, EV_ENT_aiment, entPlayer)
	
	//------set weapon model-----------
	new teamstr[20]
	get_user_team(id,teamstr,20)
	new w=entity_get_int(id,EV_INT_weaponanim)
	switch(w){
		case 3:{
			entity_set_model(entWeapon, "models/p_knife.mdl")
		}	
		case 8:{
			if( equal(teamstr,"CT") )
				entity_set_model(entWeapon, "models/p_usp.mdl") 
			else if( equal(teamstr,"TERRORIST" ) )
				entity_set_model(entWeapon, "models/p_glock18.mdl") 
		}
		default :{
			if( equal(teamstr,"CT") )
				entity_set_model(entWeapon, "models/p_m4a1.mdl") 
			else if( equal(teamstr,"TERRORIST" ) )
				entity_set_model(entWeapon, "models/p_ak47.mdl") 
		}			
	}
	//entity_set_float(entPlayer,EV_FL_nextthink,halflife_time() + 0.5)  
	weapon_ents[id][creators[id]++]= entWeapon
	round_count++
	return entWeapon
}	


public connect_spycam(id)
{	
	if( !creators[id] )
		return PLUGIN_HANDLED
		
	new parms[3]
	parms[0] = id
	client_print(id,print_chat,"Total: %i :: View NO: %i. ^n[ if you created more than one fake player, press'E' to see another fake player's view. ]",creators[id],ent_count[id])
	engfunc( EngFunc_SetView,id,body_ents[id][ent_count[id]] )
	set_task(0.2,"check_button",0,parms,3)
	if( !task_exists(7789,0) )
		set_task(5.0, "DestroySpyCam", 7789, parms, 3)
	return PLUGIN_CONTINUE
}

public check_button(parms[3])
{
	//change view to the next fake player  (cycle)
	new id=parms[0]
	if( get_user_button(id) & IN_USE ){
		ent_count[id]=++ent_count[id]%creators[id]
		remove_task(7789,0)
		connect_spycam(id)
		return PLUGIN_CONTINUE
	}
	if( get_user_button(id) & (IN_DUCK|IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) ){
		DestroySpyCam(parms)
		return PLUGIN_HANDLED
	}
	//check again
	set_task(0.1,"check_button",7799,parms,3)
	return PLUGIN_CONTINUE
}

public DestroySpyCam(parms[3])
{
	if( task_exists(7799,0) )
		remove_task(7799,0)
		
	new id = parms[0]
	
	// If user is still around, set his view back
	if (is_user_connected(id))
		engfunc(EngFunc_SetView, id, id)
	ent_count[id]=0
}

public remove_ent()
{
	if(!round_count)
		return PLUGIN_HANDLED
	
	new players[32]
	get_players(players,num)
	for(new t=0;t<num;t++){
		if( creators[ players[t] ] ){
			for(new i=0;i<creators[ players[t] ];i++){
				remove_entity( body_ents[ players[t] ] [ i ]  )
				remove_entity( weapon_ents[ players[t] ] [ i ]  )
			}
			creators[ players[t] ]=0
			ent_count[ players[t] ]=0
		}	
	}
	round_count=0
	
	return PLUGIN_HANDLED
}

//-----------------------fake-player think--------------------------


public ent_think(entid)
{
	if ( is_valid_ent(entid) )
	{
		new id=entity_get_edict(entid,EV_ENT_owner)
		if( !is_user_alive(id) || !creators[id] ){
			stop_fake(entid)
			return PLUGIN_CONTINUE
		}	
		drop_to_floor(entid) 
				
		new Float:fOri[3],Float:angle[3],Float:targetOri[3]
		new Float:hitOri[3],Float:Vel[3],hitent
		entity_get_vector(entid,EV_VEC_origin,fOri)	
		new targetid=FindClosesEnemy(entid,id)
		if( targetid ){
				
			//could see target?
			entity_get_vector(targetid, EV_VEC_origin, targetOri)
				
			hitent=trace_line(entid, fOri, targetOri, hitOri)	
			if( hitent==targetid ){
											
				//turn to target
				new Float:rOri[3],Float:dis
				DirectedVec(targetOri,fOri,rOri)
				rOri[2]=0.0
				vector_to_angle(rOri,angle)
				entity_set_vector(entid,EV_VEC_angles,angle)
					
				//run to target 
				if( dynamic_ent[entid] ){
					stop_fake(entid)
					dis=entity_range(entid,targetid)
					if( dis>150 ){
						entity_set_vector(entid,EV_VEC_v_angle,angle)
						VelocityByAim(entid,FAKEPLAYERSPEED,Vel)
						Vel[2]=0.0
						entity_set_vector(entid,EV_VEC_velocity,Vel)
						entity_set_int(entid,EV_INT_sequence,4)
					}
				}	
				ShowOnRadar(id,fOri)
				entity_set_float(entid,EV_FL_nextthink,halflife_time() + 0.1)
				return PLUGIN_CONTINUE
			}	
		}//if( targetid )
			
		//make dynamic fake-player find a way by himself
		if ( dynamic_ent[entid] ){
			find_way(entid,fOri)
		}
		entity_set_float(entid,EV_FL_nextthink,halflife_time() + 0.1)
	}	
	return PLUGIN_CONTINUE
}

stop_fake(entid)
{
	new Float:Vel[3]
	Vel[0]=0.0
	Vel[1]=0.0
	Vel[2]=0.0
	entity_set_vector(entid,EV_VEC_velocity,Vel)
	entity_set_int(entid,EV_INT_sequence,1)
}

FindClosesEnemy(entid,id)
{
	new Team = get_user_team(id)
	new Float:Dist
	new Float:maxdistance=4000.0
	new indexid=0
	
	for(new i=1;i<=g_MaxPlayers;i++){
		if( is_valid_ent(i) && Team != get_user_team(i) ){
			Dist = entity_range(entid,i)
			if(Dist <= maxdistance){
				maxdistance=Dist
				indexid=i
			}
		}	
	}	
	return indexid
}

ShowOnRadar(id,Float:fOri[3])
{
	message_begin(MSG_ONE, g_msgHostagePos, {0,0,0}, id)
	write_byte(id)	
	write_byte(20)			
	write_coord( floatround(fOri[0]) )	//X Coordinate
	write_coord( floatround(fOri[0]) )	//Y Coordinate
	write_coord( floatround(fOri[0]) )	//Z Coordinate
	message_end()

	message_begin(MSG_ONE, g_msgHostageK, {0,0,0}, id)
	write_byte(20)
	message_end()
}

stock DirectedVec(Float:start[3],Float:end[3],Float:reOri[3])
{
//-------code from Hydralisk's 'Admin Advantage'-------//	
	new Float:v3[3]
	v3[0]=start[0]-end[0]
	v3[1]=start[1]-end[1]
	v3[2]=start[2]-end[2]
	new Float:vl = vector_length(v3)
	reOri[0] = v3[0] / vl
	reOri[1] = v3[1] / vl
	reOri[2] = v3[2] / vl
}

stock make_dot(vec[3])
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)  
	write_byte( 17 ) 
	write_coord(vec[0]) 
	write_coord(vec[1]) 
	write_coord(vec[2])
	write_short( dot ) 
	write_byte( 10 ) 
	write_byte( 255 ) 
	message_end()	
}

find_way(entid,Float:fOri[3])
{
	new Float:vTrace[3],Float:vTraceEnd[3],Float:hitOri[3],Float:Vel[3],Float:angle[3]
	// set a entPos to trace a line
	velocity_by_aim(entid, 64, vTrace) 
	vTraceEnd[0] = vTrace[0] + fOri[0] 
	vTraceEnd[1] = vTrace[1] + fOri[1]
	vTraceEnd[2] = vTrace[2] + fOri[2]+25
	new hitent=trace_line(entid, fOri, vTraceEnd, hitOri)

	//check the trace return values to check is player hit something...
	//doesn't check the hit entity, 
	//because if hit nothing,will return 0. and if hit the wall,also return 0.
	new Float:gdis=vector_distance(fOri,hitOri)
	
	//set another entPos to trace another line
	velocity_by_aim(entid, 45, vTrace) 
	vTraceEnd[0] = vTrace[0] + fOri[0] 
	vTraceEnd[1] = vTrace[1] + fOri[1]
	vTraceEnd[2] = vTrace[2] + fOri[2]-45// lower than first dot
	trace_line(entid, fOri, vTraceEnd, hitOri)
	
	new Float:gdis2=vector_distance(fOri,hitOri)
	
	if( gdis2<43 ){
		entity_get_vector(entid,EV_VEC_origin,fOri)
		fOri[2]+=10
		entity_set_vector(entid,EV_VEC_origin,fOri)
	}	

	entity_get_vector(entid,EV_VEC_velocity,Vel)
	if( hitent || gdis<60 ){
		//stop
		stop_fake(entid)
						
		//turn random angle 
		entity_get_vector(entid,EV_VEC_v_angle,angle)
		new Float:fnum=random_float(-90.0,90.0)
		angle[1]+=fnum
		//angle[1]+=90.0
		entity_set_vector(entid,EV_VEC_v_angle,angle)
		return
	}
	if( Vel[0]==0.0 || Vel[1]==0.0 ){
		VelocityByAim(entid,FAKEPLAYERSPEED,Vel)
		Vel[2]=0.0
		vector_to_angle(Vel,angle)
		entity_set_vector(entid,EV_VEC_angles,angle)	
		entity_set_vector(entid,EV_VEC_velocity,Vel)
		entity_set_int(entid,EV_INT_sequence,4)	
	}	
}
