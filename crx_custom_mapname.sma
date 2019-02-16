#include <amxmodx>
#include <reapi>

#define PLUGIN_VERSION "1.0"

new g_pMap

public plugin_init()
{
	register_plugin("Custom Mapname", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXCustomMapname", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	RegisterHookChain(RH_Cvar_DirectSet, "ReAPI_HC_Cvar_DirectSet")
	g_pMap = register_cvar("sv_mapname", "")
}

public plugin_cfg()
{
	new szMap[32]
	get_pcvar_string(g_pMap, szMap, charsmax(szMap))
	ReAPI_HC_Cvar_DirectSet(g_pMap, szMap)
}

public ReAPI_HC_Cvar_DirectSet(pCvar, szValue[])
{
	if(pCvar == g_pMap)
		szValue[0] ? rh_set_mapname(szValue) : rh_reset_mapname()
}