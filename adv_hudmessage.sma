/*		eNUMS			*/
enum eTeams { TEAM_T, TEAM_CT };

enum _:iShows
{
	showName,
	showSrvIp,
	showMap,
	showId,
	showRank,
	showTime,
	showTeamScores
}

/*		Includes		*/
#include < amxmodx >
#include < amxmisc >
#include < csx >

new g_iShows[ 33 ][ iShows ];
new g_Name[ 32 ], g_Map[ 32 ], g_szAuthid[ 33 ][ 35 ];
new g_SyncHud;
new g_iScore[eTeams];

/*		Keys for menu		*/
new g_iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_9;

public plugin_init( ) 
{ 
	register_plugin( "Advanced HudInfo", "1.0", "Artifact" )
	
	register_event("TeamScore", "TeamScore", "a", "1=TERRORIST", "1=CT");
	
	//register_clcmd( "say /hudinfo", "show_HudMenu")
	
	register_menucmd( register_menuid( "HudMenu" ), g_iKeys, "handle_HudMenu" )

	
	get_cvar_string( "hostname", g_Name, charsmax( g_Name ) )
	
	get_mapname( g_Map, charsmax( g_Map ) )

	
	set_task( 1.0, "Task_HudInfo", 0, .flags="b" )
	
	set_task( 25.0, "Advert" )

	
	g_SyncHud = CreateHudSyncObj( );

}

public Advert( )
	client_print( 0, print_chat, "[ AMXX ] For advanced hud messages type say /hudinfo" )
	
public client_authorized( id )
	get_user_authid( id, g_szAuthid[ id ], charsmax( g_szAuthid[] ) )

public client_disconnect( id )
	g_szAuthid[ id ][ 0 ] = EOS;

/*		<-- Menu start here -->		*/
public show_HudMenu( id )
{
	new szBuffer[ 512 ];
	
	formatex( szBuffer, charsmax( szBuffer ), "Hud Menu:^n^n\r1. \wServer name \r[%s\r]^n2. \wServer IP \r[%s\r]^n3. \wMap \r[%s\r]^n4. \wMy SteamID \r[%s\r]^n5. \wShow Personal Rank \r[%s\r]^n6. \wShow the time \r[%s\r]^n7. \wShow TeamScores \r[%s\r]^n^n9. \wExit", \
	g_iShows[ id ][ showName ] ? "\yShow" : "Hide", \
	g_iShows[ id ][ showSrvIp ] ? "\yShow" : "Hide", \
	g_iShows[ id ][ showMap ] ? "\yShow" : "Hide", \
	g_iShows[ id ][ showId ] ? "\yShow" : "Hide", \
	g_iShows[ id ][ showRank ] ? "\yShow" : "Hide",
	g_iShows[ id ][ showTime ] ? "\yShow" : "Hide",
	g_iShows[ id ][ showTeamScores ] ? "\yShow" : "Hide" )
	
	show_menu( id, g_iKeys, szBuffer, -1, "HudMenu" )
	
	return PLUGIN_HANDLED;
}

public handle_HudMenu( id, iKey )
{
	if( iKey != 9 )
	{
		g_iShows[ id ][ iKey ] = !g_iShows[ id ][ iKey ];
		show_HudMenu( id );
	}
	return PLUGIN_HANDLED
}
/*		Menu end here		*/

/*		Format hud here		*/
public Task_HudInfo()
{
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum )
	
	new szTemp[ 64 ];
	new szBuffer[ 256 ];

	for ( --iNum; iNum >= 0; iNum-- )
	{
		new i = iPlayers[ iNum ]
		szBuffer[0] = EOS
		
		if( g_iShows[ i ][ showName ])
		{
			formatex( szTemp, charsmax( szTemp ), "^n[Hostname: %s]", g_Name )
			add( szBuffer, charsmax( szBuffer ), szTemp ) 
		}
		if( g_iShows[ i ][ showSrvIp ])
		{
			new g_srvip[ 32 ]
			get_user_ip( 0, g_srvip, charsmax( g_srvip ) )
			formatex( szTemp, charsmax( szTemp ), "^n[Server Ip: %s]", g_srvip )
			add( szBuffer, charsmax( szBuffer ), szTemp ) 
		}
		if( g_iShows[ i ][ showMap ])
		{
			formatex( szTemp, charsmax( szTemp ), "^n[Map: %s]", g_Map )
			add( szBuffer, charsmax( szBuffer ), szTemp )  
		}
		if( g_iShows[ i ][ showId ])
		{
			formatex( szTemp, charsmax( szTemp ), "^n[SteamID: %s]", g_szAuthid[ i ] )
			add( szBuffer, charsmax( szBuffer ), szTemp )  
		}
		if( g_iShows[ i ][ showRank ])
		{
			new izStats[8], izBody[8]
			new iRankPos, iRankMax
			iRankPos = get_user_stats(i,izStats,izBody)
			iRankMax = get_statsnum()
			formatex( szTemp, charsmax( szTemp ), "^n[Your rank is: %d / %d]", iRankPos, iRankMax )
			add( szBuffer, charsmax( szBuffer ), szTemp )  
		}
		if( g_iShows[ i ][ showTime ])
		{
			static szTime[ 10 ]
			get_time( "%H:%M:%S", szTime, charsmax( szTime ) )
			
			formatex( szTemp, charsmax( szTemp ), "^n[Time: %s]", szTime )
			add( szBuffer, charsmax( szBuffer ), szTemp )
		}
		if( g_iShows[ i ][ showTeamScores ])
		{
			formatex(szTemp, charsmax( szTemp ), "^nCT [ %d ] | TE [ %d ]", g_iScore[TEAM_CT], g_iScore[TEAM_T])
			add( szBuffer, charsmax( szBuffer ), szTemp )
		}
		set_hudmessage( 255 , 255 , 000 , 0.0, 0.15 , 0 , 1.0 , 1.0 );
		ShowSyncHudMsg( i, g_SyncHud, szBuffer );
	}
}

// Get Team Score
public TeamScore() {
	static szTeam[ 2 ];
	read_data( 1, szTeam, 1 );
	
	g_iScore[ szTeam[ 0 ] == 'T' ? TEAM_T : TEAM_CT ] = read_data( 2 );
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang9242\\ f0\\ fs16 \n\\ par }
*/
