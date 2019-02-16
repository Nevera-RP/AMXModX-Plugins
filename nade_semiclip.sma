#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Nade Semiclip"
#define VERSION "2.4"
#define AUTHOR "JustGo"

#define OFFSET_TEAM	114
#define fm_get_user_team(%1)	get_pdata_int(%1,OFFSET_TEAM)
#define is_grenade_c4(%1)	(get_pdata_int(%1, 96) & (1<<8)) // 96 is the C4 offset

#define SEMI_CLIP_DISTANCE 100.0

new cvar_nade_semiclip, g_nade_semiclip

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	RegisterHam(Ham_Think, "grenade", "Think_Grenade")
	
	register_forward(FM_SetModel, "SetModel")
	register_forward(FM_ShouldCollide, "ShouldCollide")
	
	cvar_nade_semiclip = register_cvar( "nade_semiclip", "1" )
}

public event_round_start()
{
	g_nade_semiclip = get_pcvar_num( cvar_nade_semiclip )
}

// Grenade Think Forward
public Think_Grenade(entity)
{
	if(!g_nade_semiclip)
		return HAM_IGNORED
	
	if(!pev_valid(entity))
		return HAM_IGNORED
	
	if(is_grenade_c4(entity))
		return HAM_IGNORED
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if(dmgtime <= get_gametime())
		set_pev(entity, pev_owner,pev(entity,pev_iuser2)); // fix for other plugin that gets flasher name or stuff like that.
	
	return HAM_IGNORED;
}

public SetModel(iEntity, const Model[])
{
	if(!g_nade_semiclip)
		return FMRES_IGNORED
		
	if(!is_grenade(iEntity))
		return FMRES_IGNORED
		
	static id; id = pev(iEntity, pev_owner)
	if(!pev(iEntity,pev_iuser2))  
	{
		set_pev(iEntity,pev_iuser2,id) //remeber the real nade owner
		set_pev(iEntity,pev_iuser1,fm_get_user_team(id)) // remeber the nade owner team
	}
		
	return FMRES_IGNORED
}

public ShouldCollide(playerindex, entindex)
{
	if(!g_nade_semiclip)
		return FMRES_IGNORED
		
	if(!is_user_alive(playerindex) || !is_grenade(entindex))
		return FMRES_IGNORED
		
	// Get damage time of grenade
	static Float:dmgtime
	pev(entindex, pev_dmgtime, dmgtime)
		
	if(dmgtime <= get_gametime())
		return FMRES_IGNORED
	
	if(close_enough(playerindex,entindex))
	{		
		if(g_nade_semiclip == 1 && (fm_get_user_team( playerindex ) != pev(entindex,pev_iuser1)))
			return FMRES_IGNORED
		
		set_pev(entindex,pev_owner,playerindex)
	}

	return FMRES_IGNORED
}

is_grenade(iEntity)
{
	if( !pev_valid(iEntity) )
		return 0
	
	static class[9] 
	pev(iEntity, pev_classname, class, charsmax(class)) 
	if( !equal(class, "grenade") )
		return 0
	
	if (is_grenade_c4(iEntity))
		return 0
	
	return 1
}

public bool:close_enough(ent1, ent2)
{
    static Float:origin[3], Float:origin2[3]
    
    pev(ent1, pev_origin, origin )
    pev(ent2, pev_origin, origin2 )
    
    if( get_distance_f( origin, origin2 ) <= SEMI_CLIP_DISTANCE )
        return true

    return false    
}