#include <amxmodx>  
#include <cstrike> 
#include <csx>  

new const PLUGIN[] = "C4 Plugin"  
new const VERSION[] = "1.1b"  
new const AUTHOR[] = "Xvil"  

new g_Cvar, g_C4

// register the cvar and the plugin  
public plugin_init() {  
    register_plugin(PLUGIN, VERSION, AUTHOR)  
    g_C4 = get_cvar_pointer("mp_c4timer")
    g_Cvar = register_cvar("bm_enabled", "1") // amx_cvar bm_enabled 1 = ON || amx_cvar bm_enabled 0 = OFF  
    register_logevent("RoundEnd",2,"1=Round_End")    
    register_logevent("logevent_round_start", 2, "1=Round_Start")    
      
}  
// plugin precache  
public plugin_precache() { 
	precache_sound("misc/ten.wav")   
	precache_sound("misc/nine.wav")  
	precache_sound("misc/eight.wav")  
	precache_sound("misc/seven.wav")  
	precache_sound("misc/six.wav")  
	precache_sound("misc/five.wav")  
	precache_sound("misc/foor.wav")  
	precache_sound("misc/three.wav")  
	precache_sound("misc/two.wav")  
	precache_sound("misc/one.wav")  
	precache_sound("radio/bot/good_job_team.wav")  
	precache_sound("radio/bot/defusing_bomb.wav")  
	precache_sound("radio/bot/im_gonna_go_plant.wav")  
	precache_sound("radio/bot/im_gonna_go_plant_the_bomb.wav")  
	precache_sound("radio/bot/defusing.wav")  
	precache_sound("radio/bot/defusing_bomb_now.wav")  
	precache_sound("radio/bot/good_one_sir.wav")  
	precache_sound("radio/bot/good_one_sir2.wav")  
      
	return PLUGIN_HANDLED  
}  

public bomb_planting(planter) {  
      
    new PLname[32]  
    new randim = random_num(0,1)  
      
    if(!get_pcvar_num(g_Cvar))  
        return PLUGIN_CONTINUE  
          
    get_user_name(planter, PLname, 31)  
    set_hudmessage(0, 0, 255, -1.0, -1.0, 0, 2.0, 1.0)  
    show_hudmessage(0, "%s is planting the bomb!", PLname)  
      
    switch(randim)  
  {  
    case 0: client_cmd(0,"spk radio/bot/im_gonna_go_plant_the_bomb.wav")  
    case 1: client_cmd(0,"spk radio/bot/im_gonna_go_plant.wav")  
  }  
      
    return PLUGIN_HANDLED  
      
}  
// called when the bomb is planted  
public bomb_planted(planter) {  
    new Name[32]
      
    if(!get_pcvar_num(g_Cvar))  
        return PLUGIN_CONTINUE  
          
    get_user_name(planter, Name, 31)  
      
    set_hudmessage(255,0,0,-1.0,-1.0,0,0.3,1.0)  
    show_hudmessage(0, "Bomb has been planted from %s", Name)  
    
    
      
     
    new time = get_pcvar_num(g_C4)
    
    float(time)
    
     
    // task for the 10 end C4 timer 
    set_task( (time - 10.0) , "Zero", 0)	
    set_task( (time - 9.0) , "one", 0)  
    set_task( (time - 8.0) , "two", 0)  
    set_task( (time - 7.0) , "three", 0)  
    set_task( (time - 6.0) , "foor", 0)  
    set_task( (time - 5.0) , "five", 0)  
    set_task( (time - 4.0) , "six", 0); 
    set_task( (time - 3.0) , "seven", 0)  
    set_task( (time - 2.0) , "eigth", 0)  
    set_task( (time - 1.0) , "nine", 0)  
    return PLUGIN_CONTINUE  
}  

public Zero()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "10")  
    client_cmd(0, "spk misc/ten.wav" )  
    return PLUGIN_CONTINUE  
}  

public one()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "9")  
    client_cmd(0, "spk misc/nine.wav" )  
    return PLUGIN_CONTINUE  
}  
public two()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "8")  
    client_cmd(0, "spk misc/eight.wav")  
    return PLUGIN_CONTINUE  
}  
public three()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "7")  
    client_cmd(0, "spk misc/seven.wav")  
    return PLUGIN_CONTINUE  
}  
public foor()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "6")  
    client_cmd(0, "spk misc/six.wav"  )  
    return PLUGIN_CONTINUE  
}  
public five()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "5")  
    client_cmd(0, "spk misc/five.wav" )  
    return PLUGIN_CONTINUE  
}  
public six()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "4")  
    client_cmd(0, "spk misc/foor.wav" )  
    return PLUGIN_CONTINUE  
}  
public seven()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "3")  
    client_cmd(0, "spk misc/three.wav")  
    return PLUGIN_CONTINUE  
}  
public eigth()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "2")  
    client_cmd(0, "spk misc/two.wav"  )  
    return PLUGIN_CONTINUE  
}  
public nine()  
{  
    set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "1")  
    client_cmd(0, "spk misc/one.wav")  
    return PLUGIN_CONTINUE  
}  
// called when the C4 explode  
public bomb_explode(planter, defuser) {  
    new PName[32]  
    new randam = random_num(0,2)  
      
    if(!get_pcvar_num(g_Cvar))  
        return PLUGIN_CONTINUE  
          
    remove_task(0,0)  
      
    get_user_name(planter, PName, 31)  
    set_hudmessage(255, 0,0, -1.0, 0.17, 0, 0.9, 1.0)  
    show_hudmessage(0, "Bomb exploded! Good job %s", PName)  
    switch(randam)  
  {  
    case 0: client_cmd(0,"spk radio/bot/good_one_sir2.wav")  
    case 1: client_cmd(0,"spk radio/bot/good_job_team.wav")  
    case 2: client_cmd(0,"spk radio/bot/good_one_sir.wav")  
  }  
      
    return PLUGIN_HANDLED  
}  
// called when the defuser is defusing the bomb  
public bomb_defusing(defuser) {  
    new DName[32];  
    new rando = random_num(0,2)  
      
    if(!get_pcvar_num(g_Cvar))  
        return PLUGIN_CONTINUE  
      
    get_user_name(defuser, DName, 31)  
    set_hudmessage(0, 0, 255, -1.0, -1.0, 0, 2.0, 1.0)  
    show_hudmessage(0, "%s is defusing the bomb!", DName)  
    switch(rando)  
  {  
    case 0: client_cmd(0,"spk radio/bot/defusing_bomb.wav")  
    case 1: client_cmd(0,"spk radio/bot/defusing.wav")  
    case 2: client_cmd(0,"spk radio/bot/defusing_bomb_now.wav")  
  }  
    return PLUGIN_CONTINUE  
}  
// called when the defuser complete  
public bomb_defused(defuser) {  
    new DefName[32]  
    new randem = random_num(0,2)  
      
    if(!get_pcvar_num(g_Cvar))  
        return PLUGIN_CONTINUE  
          
    remove_task(0,0)  
      
    get_user_name(defuser, DefName, 31)  
      
    set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 6.0, 12.0)  
    show_hudmessage(defuser, "Bomb defused! Good job %s", DefName)  
      
    switch(randem)  
  {  
    case 0: client_cmd(0,"spk radio/bot/good_one_sir2.wav")  
    case 1: client_cmd(0,"spk radio/bot/good_job_team.wav")  
    case 2: client_cmd(0,"spk radio/bot/good_one_sir.wav")  
  }  
    return PLUGIN_HANDLED  
}  


public RoundEnd()  
{  
    remove_task(0,0)  
}  


public logevent_round_start()  
{  
    remove_task(0,0)  
}  
