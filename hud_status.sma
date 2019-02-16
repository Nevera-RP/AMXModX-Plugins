#include <amxmodx>
#include <fakemeta>
#include <dhudmessage>

#define DHUD_RELOAD_TIME 2.0

enum _:TEAMS {TT, CT};
new g_iScore[TEAMS], g_iRoundNum, g_iAlive[TEAMS];

public plugin_init()
{
	register_plugin("HUD Status", "1.0", "DUKKHAZ0R");
	register_event("TeamScore", "eTeamScore", "a");
	register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w");
	register_event("HLTV", "eRoundStart", "a", "1=0", "2=0");
	set_task(DHUD_RELOAD_TIME, "HUDReloader", .flags="b");
}

public eTeamScore()
{
	static sTeam[20]; read_data(1, sTeam, charsmax(sTeam));
	switch(sTeam[0]) {
		case 'T': g_iScore[TT] = read_data(2);
		case 'C': g_iScore[CT] = read_data(2);
	}
}

public eRestart()
	g_iRoundNum = 0;

public eRoundStart()
	++g_iRoundNum;
	
public HUDReloader()
{
	static pl[32];
#if AMXX_VERSION_NUM < 182
	g_iAlive[TT] = g_iAlive[CT] = 0;
	static pnum, i; get_players(pl, pnum, "a");
	for(i = 0; i < pnum; i++)
	{
		switch(get_pdata_int(pl[i], 114))
		{
			case 1: g_iAlive[TT]++;
			case 2: g_iAlive[CT]++;
		}
	}
#else
	get_players(pl, g_iAlive[TT], "e", "TERRORIST");
	get_players(pl, g_iAlive[CT], "e", "CT");
#endif
	set_dhudmessage(255, 0, 0, 0.41, 0.01, 0, _, DHUD_RELOAD_TIME, _, _, false);
	show_dhudmessage(0, "TR %d", g_iScore[TT]);
	set_dhudmessage(0, 255, 255, 0.55, 0.01, 0, _, DHUD_RELOAD_TIME, _, _, false);
	show_dhudmessage(0, "%d CT", g_iScore[CT]);
	set_dhudmessage(255, 255, 0, -1.0, 0.01, 0, _, DHUD_RELOAD_TIME, _, _, false);
	show_dhudmessage(0, "[ %d ]", g_iRoundNum);
}