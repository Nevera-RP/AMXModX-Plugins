#include <amxmodx>
#include <reapi>

// #define ONLY_FLAG
#define FLAG_ACCESS	ADMIN_LEVEL_H

public plugin_init()
{
	register_plugin("[ReAPI] No Team Flash", "1.0", "ReHLDS Team");
	RegisterHookChain(RG_PlayerBlind, "PlayerBlind", false);
}

public PlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, const alpha, Float:color[3])
{
	if(index == attacker) return HC_CONTINUE;

#if defined ONLY_FLAG
	if(!(get_user_flags(index) & FLAG_ACCESS)) return HC_CONTINUE;
#endif

	return (get_member(index, m_iTeam) == get_member(attacker, m_iTeam)) ? HC_SUPERCEDE : HC_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1038\\ f0\\ fs16 \n\\ par }
*/
