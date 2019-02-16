#include < amxmodx >
#include < cstrike >
#include < fakemeta >

enum Cvars
{
botname1,
botname2,
botname3,
minplayers,
starttime,
endtime,
onecon,
onebot,
norounds
};

new const cvar_names[ Cvars ][] =
{
"amx_botname",
"amx_botname2",
"amx_botname3",
"amx_minplayers",
"amx_starttime",
"amx_endtime",
"amx_onecon",
"amx_onebot",
"amx_norounds"
};

new const cvar_defaults[ Cvars ][] =
{
"Bot",
"Bot 2",
"Bot 3",
"10",
"00",
"12",
"0",
"0",
"0"
};

new cvar_pointer[ Cvars ];
new bool:g_isTime = false;
new bool:g_ePlayers = false;
new bool:g_isFirstRound = true;
new g_BotNum = 0, g_maxplayers, g_bID1, g_bID2, g_bID3;

new const g_ConfigFile[] = "addons/amxmodx/configs/kgbbots.cfg"

public plugin_init() 
{
register_logevent("Event_RoundEnd", 2, "1=Round_End");
register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");

for ( new Cvars:i = botname1 ; i < Cvars ; i++ )
cvar_pointer[ i ] = register_cvar( cvar_names[ i ] , cvar_defaults[ i ] );

g_maxplayers = get_maxplayers();
server_cmd("exec %s", g_ConfigFile)
set_task(3.0, "isit")
}

public isit() {
if(get_pcvar_num(cvar_pointer[norounds]))
set_task(30.0, "CheckConditions",0,"",0,"b")
}

public plugin_precache() 
{
if(!file_exists(g_ConfigFile)) 
{
	write_file(g_ConfigFile, "KGB Bots - Beállítások^n")
	write_file(g_ConfigFile, "amx_botname ^"KGB Bot1^"   //Első bot neve")
	write_file(g_ConfigFile, "amx_botname2 ^"KGB Bot2^"   //Második bot neve")
	write_file(g_ConfigFile, "amx_botname3 ^"KGB Bot3^"   //Második bot neve")
	write_file(g_ConfigFile, "amx_minplayers ^"10^"   //Ennyi játékostól dobja ki a szerver a botokat. Ha,kevesebb lesz a létszám akkor vissza jönnek!")
	write_file(g_ConfigFile, "amx_starttime ^"0^"   //Hány órától legyenek fent a botok a szerón")
	write_file(g_ConfigFile, "amx_endtime ^"12^"   //Hány órán át legyenek botok?")
	write_file(g_ConfigFile, "amx_onecon ^"0^"   //A kezdési idő és minplayers létszám feltételeknek muszáj együttesen teljesülniük a botok berakásához[0 -nem, 1 -igen]")
	write_file(g_ConfigFile, "amx_onebot ^"0^"   //Egy bot menjen csak fel a szerverre?[0 -nem, 1 -igen]") 
	write_file(g_ConfigFile, "amx_norounds ^"0^"   //Végtelen köridő (0-1) (ellenőrzés 30mp-enként)[0 -nem, 1 -igen]")
}
}

public Event_RoundEnd()
{
if (!g_isFirstRound)
	return;
	
	g_isFirstRound = false;
}

public Event_NewRound()
{
	if(g_isFirstRound)
		return;
	
	CheckConditions();
}

public CheckConditions()
{
	static iHours, m, s
	time(iHours, m, s)
	
	new iMin = get_pcvar_num(cvar_pointer[ starttime ]);
	new iMax = get_pcvar_num(cvar_pointer[ endtime ]);
	
	if(iMin == iMax)
		g_isTime = true;
	else if(iMin > iMax) 
	{
		switch(iHours) 
		{
			case 0..11: 
			{
				if(iMin >= iHours && iMax > iHours)
					g_isTime = true;
			}
			case 12..23: 
			{
				if(iMin <= iHours && iMax < iHours)
					g_isTime = true;
			}
		}
	}
	else if(iMin <= iHours && iMax > iHours)
		g_isTime = true;
	else 
		g_isTime = false;
	
	new iNum, iPlayers[32];
	get_players(iPlayers, iNum, "c");
	
	if(iNum <= get_pcvar_num(cvar_pointer[minplayers]))
		g_ePlayers = true;
	else
		g_ePlayers = false;
	
	if(g_maxplayers - iNum < 2)
		g_ePlayers = false;
	
	if(get_pcvar_num(cvar_pointer[minplayers]) == 0)
		g_ePlayers = true
	
	new iCondition = get_pcvar_num(cvar_pointer[ onecon ]);
	if( (!g_ePlayers && g_isTime || !g_isTime && g_ePlayers) && iCondition) 
	{
		g_isTime = true;
		g_ePlayers = true;
	}
	
	
	
	if((g_isTime && g_ePlayers) && !g_BotNum)
	{
		if(!get_pcvar_num(cvar_pointer[onebot]))
			set_task(1.5, "Task_AddBot")
		set_task(2.8, "Task_AddBot")
		set_task(4.2, "Task_AddBot")
	}
	else if((!g_isTime || !g_ePlayers) && 0 < g_BotNum <= 3 )
	{
		g_BotNum = 0;
		server_cmd("kick #%d", g_bID1)
		server_cmd("kick #%d", g_bID2)
		server_cmd("kick #%d", g_bID3)
	}
}

public Task_AddBot()
{
	static iBot;
	new iBotName[35];
	
	switch(g_BotNum)
	{
		case 0: get_pcvar_string(cvar_pointer[ botname1 ], iBotName, charsmax( iBotName ));
			case 1:	get_pcvar_string(cvar_pointer[ botname2 ], iBotName, charsmax( iBotName ));
			case 2:	get_pcvar_string(cvar_pointer[ botname3 ], iBotName, charsmax( iBotName ));
			case 3: return;
		}
	
	iBot = engfunc( EngFunc_CreateFakeClient, iBotName );
	
	if(!iBot)
		return;
	
	dllfunc( MetaFunc_CallGameEntity, "player", iBot );
	set_pev( iBot, pev_flags, FL_FAKECLIENT );
	
	set_pev( iBot, pev_model, "" );
	set_pev( iBot, pev_viewmodel2, "" );
	set_pev( iBot, pev_modelindex, 0 );
	
	set_pev( iBot, pev_renderfx, kRenderFxNone );
	set_pev( iBot, pev_rendermode, kRenderTransAlpha );
	set_pev( iBot, pev_renderamt, 0.0 );
	
	set_pdata_int( iBot, 114, 3 );
	cs_set_user_team( iBot, CS_TEAM_UNASSIGNED );
	
	switch(g_BotNum) 
	{
		case 0: g_bID1 = get_user_userid(iBot);
			case 1: g_bID2 = get_user_userid(iBot);
				case 2: g_bID3 = get_user_userid(iBot);
		}
	g_BotNum++;
}