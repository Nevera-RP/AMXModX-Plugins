#include < amxmodx >
#include < amxmisc >

new const g_szPlugin[ ]   = "AdvancedMusicPlayer";
new const g_szVersion[ ]  = "3.0";
new const g_szAuthor[ ]   = "Baws";

enum Color 
{
        NORMAL = 1,
        GREEN,
        TEAM_COLOR,
        GREY,
        RED,
        BLUE
};

enum _SongEnum 
{
        Name[ 128 ],
        Url[ 512 ]
}

new g_SongInformation[ _SongEnum ];

new Array:g_hArray;

new g_Song[ 33 ];
new g_SongCount;

new g_FileName[ 256 ];
new g_MusicPlayer[ 256 ];

new g_Volume[ 33 ];
new bool:g_Repeat[ 33 ];
new bool:g_SettingsSave[ 33 ];
new g_LastId;
new bool:g_Copied;

new g_pcvarConnectMsg;
new g_pcvarShowCommands;

public plugin_init( ) 
{
        register_plugin( g_szPlugin, g_szVersion, g_szAuthor );
        register_cvar( g_szPlugin, g_szVersion, FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY );
    
        register_clcmd( "say", "Cmd_Say" );
        register_clcmd( "say_team", "Cmd_Say" );

        register_clcmd( "search", "Cmd_Search1" );

        register_concmd( "amx_addsong", "AddSong", ADMIN_CFG, "- Usage: amx_addsong ^"Song name^" ^"Url/Link^" | Attention: Put them with quotes." );
    
        g_pcvarConnectMsg = register_cvar( "sv_connectmessage", "1" );
        g_pcvarShowCommands = register_cvar( "sv_showcommands", "0" );
    
        register_dictionary_colored( "AdvMusicPlayer.txt" );
    
        Initialize( );
}

public client_putinserver( id ) 
{
        g_Song[ id ] = 0;
	
        new iRep[ 3 ], iVol[ 5 ];
        get_user_info( id, "hlmp_rep", iRep, 2 )
        get_user_info( id, "hlmp_vol", iVol, 4 )

        g_Volume[ id ] = 50;
        g_Repeat[ id ] = false;

        if( get_pcvar_num( g_pcvarConnectMsg ) == 1 )
                set_task( 15.0, "ConnectMsg", id );
}

public ConnectMsg( id ) 
{
        if( !get_pcvar_num( g_pcvarConnectMsg ) )
                return;
    
        new szName[ 32 ];
        get_user_name( id, szName, charsmax( szName ) );
        client_print_color( id, NORMAL, "%L", id, "ADV_CONNECT_MSG", szName );
}

public AddSong( id, level, cid ) 
{
        if( !cmd_access( id, level, cid, 3 ) )
                return PLUGIN_HANDLED;
    
        read_argv( 1, g_SongInformation[ Name ], charsmax( g_SongInformation[ Name ] ) );
        read_argv( 2, g_SongInformation[ Url ], charsmax( g_SongInformation[ Url ] ) );
    
        trim( g_SongInformation[ Name ] );
        trim( g_SongInformation[ Url ] );
    
        if( !g_SongInformation[ Name ][ 0 ] || !g_SongInformation[ Url ][ 0 ] ) 
        {
                cmd_access( id, level, cid, 999 );
                return PLUGIN_HANDLED;
        }
    
        ArrayPushArray( g_hArray, g_SongInformation );
        g_SongCount++;
    
        new iFile = fopen( g_FileName, "a+" );
    
        if( !iFile ) 
        {
                log_amx( "[%s] Could not open file ^"%s^".", g_szPlugin, g_FileName );
                return PLUGIN_HANDLED;
        }
    
        fprintf( iFile, "^n^"%s^" ^"%s^"", g_SongInformation[ Name ], g_SongInformation[ Url ] );
        fclose( iFile );
    
        console_print( id, "%L", id, "ADV_SONG_ADDED",  g_SongInformation[ Name ] );
    
        return PLUGIN_HANDLED;
}

public Cmd_Say( id ) 
{
        new szText[ 194 ];
        read_args( szText, charsmax( szText ) );
        remove_quotes( szText );
    
        if( szText[ 0 ] != '/' )
                return PLUGIN_CONTINUE;
		
        if( get_pcvar_num( g_pcvarShowCommands ) == 1 )
        {
                if( equali( szText[ 1 ], "musichelp", 9 ) ) 
                {
                        new Motd[ 1056 ], Len;

                        Len = formatex( Motd, charsmax( Motd ), "<html><head><style type=^"text/css^">pre{color:#CDCCCB;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body>" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<center><b><i>%L</i></b></center>^n", id, "ADV_MOTD1_MUSIC_HELP" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>^n", id, "ADV_MOTD1_PLAYER_COMMANDS" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/music - <i>%L</i>^n", id, "ADV_MOTD1_MUSIC_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/search ^"song/name^" - <i>%L</i>^n", id, "ADV_MOTD1_SEARCH_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/replay - <i>%L</i>^n", id, "ADV_MOTD1_REPLAY_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/copy - <i>%L</i>^n", id, "ADV_MOTD1_COPY_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/stop - <i>%L</i>^n", id, "ADV_MOTD1_STOP_COMMAND" );
                        formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
			
                        if( get_user_flags( id ) & ADMIN_CFG )
                        {
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>^n", id, "ADV_MOTD1_ADMIN_COMMAND", g_szPlugin );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "amx_addsong - <i>%L</i>^n", id, "ADV_MOTD1_ADDSONG_COMMAND" );
                                formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
                        }
        
                        show_motd( id, Motd, g_szPlugin );
                        return PLUGIN_CONTINUE;
                }
		
                else if( equali( szText[ 1 ], "music", 5 ) ) 
                {
                        if( g_SettingsSave[ id ] == false )
                        {
                                g_Volume[ id ] = 50;
                                g_Repeat[ id ] = false;
                        }

                        SettingsMenu( id );
                        return PLUGIN_CONTINUE;
                }
    
                else if( equali( szText[ 1 ], "stop", 4 ) ) 
                {
                        new Motd[ 386 ], Len;
        
                        Len = formatex( Motd, charsmax( Motd ), "<html><head><style type=^"text/css^">pre{color:#CDCCCB;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body><center>" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>", id, "ADV_MOTD2_MUSIC_STOPPED" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_BROUGHT_TO_YOU", g_szAuthor );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_POWERFUL_PLAYER", g_szPlugin );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_HOPE_FUN_LISTENING" );
                        formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
        
                        show_motd( id, Motd, g_szPlugin );
                        return PLUGIN_CONTINUE;
                }
    
                else if( equali( szText[ 1 ], "replay", 6 ) ) 
                {
        
                        if( g_Song[ id ] != 0 )
                                Play_Song( id, g_Song[ id ] );
                        else
                                client_print_color( id, NORMAL, "%L", id, "ADV_NO_SONG_PLAYED" );
			
                        return PLUGIN_CONTINUE;
                }
    
                else if( equali( szText[ 1 ], "copy", 4 ) ) 
                {
                        Cmd_CopySong( id );
        
                        return PLUGIN_CONTINUE;
                }
    
                else if( equali( szText[ 1 ], "search", 6 ) ) 
                {
                        new szName[ 64 ];
                        strbreak( szText, "", 0, szName, charsmax( szName ) );
        
                        Cmd_Search( id, szName );
        
                        return PLUGIN_CONTINUE;
                }
        }
        else
        {    
                if( equali( szText[ 1 ], "musichelp", 9 ) ) 
                {
                        new Motd[ 1056 ], Len;

                        Len = formatex( Motd, charsmax( Motd ), "<html><head><style type=^"text/css^">pre{color:#CDCCCB;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body>" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<center><b><i>%L</i></b></center>^n", id, "ADV_MOTD1_MUSIC_HELP" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>^n", id, "ADV_MOTD1_PLAYER_COMMANDS" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/music - <i>%L</i>^n", id, "ADV_MOTD1_MUSIC_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/search ^"song/name^" - <i>%L</i>^n", id, "ADV_MOTD1_SEARCH_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/replay - <i>%L</i>^n", id, "ADV_MOTD1_REPLAY_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/copy - <i>%L</i>^n", id, "ADV_MOTD1_COPY_COMMAND" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/stop - <i>%L</i>^n", id, "ADV_MOTD1_STOP_COMMAND" );
                        formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
			
                        if( get_user_flags( id ) & ADMIN_CFG )
                        {
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>^n", id, "ADV_MOTD1_ADMIN_COMMAND", g_szPlugin );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "amx_addsong - <i>%L</i>^n", id, "ADV_MOTD1_ADDSONG_COMMAND" );
                                formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
                        }
        
                        show_motd( id, Motd, g_szPlugin );
                        return PLUGIN_HANDLED;
                }
		
                else if( equali( szText[ 1 ], "music", 5 ) ) 
                {
                        if( g_SettingsSave[ id ] == false )
                        {
                                g_Volume[ id ] = 50;
                                g_Repeat[ id ] = false;
                        }
			
                        SettingsMenu( id );
                        return PLUGIN_HANDLED;
                }
    
                else if( equali( szText[ 1 ], "stop", 4 ) ) 
                {
                        new Motd[ 386 ], Len;
        
                        Len = formatex( Motd, charsmax( Motd ), "<html><head><style type=^"text/css^">pre{color:#CDCCCB;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body><center>" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>", id, "ADV_MOTD2_MUSIC_STOPPED" );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_BROUGHT_TO_YOU", g_szAuthor );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_POWERFUL_PLAYER", g_szPlugin );
                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_HOPE_FUN_LISTENING" );
                        formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
        
                        show_motd( id, Motd, g_szPlugin );
                        return PLUGIN_HANDLED;
                }
    
                else if( equali( szText[ 1 ], "replay", 6 ) ) 
                {
        
                        if( g_Song[ id ] != 0 )
                                Play_Song( id, g_Song[ id ] );
                        else
                                client_print_color( id, NORMAL, "%L", id, "ADV_NO_SONG_PLAYED" );
			
                        return PLUGIN_HANDLED;
                }
    
                else if( equali( szText[ 1 ], "copy", 4 ) ) 
                {
                        Cmd_CopySong( id );
        
                        return PLUGIN_HANDLED;
                }
    
                else if( equali( szText[ 1 ], "search", 6 ) ) 
                {
                        new szName[ 64 ];
                        strbreak( szText, "", 0, szName, charsmax( szName ) );
        
                        Cmd_Search( id, szName );
        
                        return PLUGIN_HANDLED;
                }
        }
    
        return PLUGIN_CONTINUE;
}

public Cmd_Search1( id )
{
        new iArg[ 33 ];
        read_argv( 1, iArg, charsmax( iArg ) );
	
        Cmd_Search( id, iArg );
}

public SettingsMenu( id )
{
        new hMenu, iText[ 33 ];

        formatex ( iText, charsmax( iText ), "\y%L", id, "ADV_MENU1_SETTINGS_TITLE" )
        hMenu = menu_create( iText, "SettingsMenu_Handler" )
	
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_PLAY_SONG" )
        menu_additem( hMenu, iText )
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_STOP_SONG" )
        menu_additem( hMenu, iText )
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_MUSIC_COMMANDS" )
        menu_additem( hMenu, iText )
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_SEARCH_SONGS" )
        menu_additem( hMenu, iText )
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_REPEAT", id, g_Repeat[ id ] ? "ADV_MENU1_REPEAT_ON" : "ADV_MENU1_REPEAT_OFF" )
        menu_additem( hMenu, iText )		
        menu_addtext( hMenu, "\r--------------------", 0 )
        formatex( iText, charsmax( iText ), "    \y%L", id, "ADV_MENU1_VOLUME", g_Volume[ id ] )
        menu_addtext( hMenu, iText, 0 )
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_VOLUME_UP" )
        menu_additem( hMenu, iText )
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_VOLUME_DOWN" )
        menu_additem( hMenu, iText )
        menu_addtext( hMenu, "\r--------------------", 0 )
        formatex( iText, charsmax( iText ), "%L", id, "ADV_MENU1_SETTINGS", id, g_SettingsSave[ id ] ? "ADV_MENU1_SETTINGS_SAVED" : "ADV_MENU1_SETTINGS_NOT_SAVED" )
        menu_additem( hMenu, iText )
	
        menu_display( id, hMenu, 0 );
        return;
}

public SettingsMenu_Handler( id, hMenu, item )
{
        if( item != MENU_EXIT )
        {
                switch( item )
                {
                        case 0: SongList( id );
                        case 1:
                        {
                                new Motd[ 386 ], Len;
        
                                Len = formatex( Motd, charsmax( Motd ), "<html><head><style type=^"text/css^">pre{color:#CDCCCB;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body><center>" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>", id, "ADV_MOTD2_MUSIC_STOPPED" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_BROUGHT_TO_YOU", g_szAuthor );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_POWERFUL_PLAYER", g_szPlugin );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "%L^n", id, "ADV_MOTD2_HOPE_FUN_LISTENING" );
                                formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
        
                                show_motd( id, Motd, g_szPlugin );
                                SettingsMenu( id );
                        }
                        case 2:
                        {
                                new Motd[ 1056 ], Len;

                                Len = formatex( Motd, charsmax( Motd ), "<html><head><style type=^"text/css^">pre{color:#CDCCCB;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body>" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<center><b><i>%L</i></b></center>^n", id, "ADV_MOTD1_MUSIC_HELP" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>^n", id, "ADV_MOTD1_PLAYER_COMMANDS" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/music - <i>%L</i>^n", id, "ADV_MOTD1_MUSIC_COMMAND" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/search ^"song/name^" - <i>%L</i>^n", id, "ADV_MOTD1_SEARCH_COMMAND" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/replay - <i>%L</i>^n", id, "ADV_MOTD1_REPLAY_COMMAND" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/copy - <i>%L</i>^n", id, "ADV_MOTD1_COPY_COMMAND" );
                                Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "/stop - <i>%L</i>^n", id, "ADV_MOTD1_STOP_COMMAND" );
                                formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
			
                                if( get_user_flags( id ) & ADMIN_CFG )
                                {
                                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "<b>%L</b>^n", id, "ADV_MOTD1_ADMIN_COMMAND", g_szPlugin );
                                        Len += formatex( Motd[ Len ], charsmax( Motd ) - Len, "amx_addsong - <i>%L</i>^n", id, "ADV_MOTD1_ADDSONG_COMMAND" );
                                        formatex( Motd[ Len ], charsmax( Motd ) - Len, "</center></body></pre></html>" );
                                }
        
                                show_motd( id, Motd, g_szPlugin );
                                SettingsMenu( id );
                        }
                        case 3: 
                        {
                                client_cmd( id, "messagemode search" );
                                client_print( id, print_center, "%L", id, "ADV_TYPE_SONG_NAME" );
                        }
                        case 4: 
                        {
                                if( g_Repeat[ id ] == true )
                                        g_Repeat[ id ] = false;
                                else
                                        g_Repeat[ id ] = true;

                                g_SettingsSave[ id ] = false;
                                SettingsMenu( id )
                        }
                        case 5: 
                        {
                                if( g_Volume[ id ] >= 100 )
                                {
                                       SettingsMenu( id )
                                       return PLUGIN_HANDLED;
                                }
			    
                                g_Volume[ id ] += 10

                                g_SettingsSave[ id ] = false;
                                SettingsMenu( id )
                        }
                        case 6: 
                        {
                                if( g_Volume[ id ] <= 10 )
                                {
                                       SettingsMenu( id )
                                       return PLUGIN_HANDLED;
                                }
			    
                                g_Volume[ id ] -= 10

                                g_SettingsSave[ id ] = false;
                                SettingsMenu( id )
                        }
                        case 7: 
                        {
                                if( g_SettingsSave[ id ] == false )
                                        g_SettingsSave[ id ] = true;
			
                                SettingsMenu( id )
                        }
                }
        }

        menu_destroy( hMenu );
        return PLUGIN_CONTINUE;
}

public SongList( id ) 
{
        if( !g_SongCount )
                return;

        new iSongListMenu[ 33 ];
        formatex ( iSongListMenu, charsmax( iSongListMenu ), "\y%L", id, "ADV_MENU2_SONG_LIST_TITLE" ) 
        new hMenu = menu_create( iSongListMenu, "SongList_Handler" );
    
        for( new i = 1 ; i < g_SongCount + 1 ; i++ ) 
        {
                ArrayGetArray( g_hArray, i, g_SongInformation );
                menu_additem( hMenu, g_SongInformation[ Name ] );
        }
    
        menu_display( id, hMenu );
        return;
}

public SongList_Handler( id, hMenu, item )
{
        if( item != MENU_EXIT )
                Play_Song( id, item + 1 );
       
        menu_destroy( hMenu )
        return PLUGIN_HANDLED;
}

Cmd_Search( id, const iText[ ] )
{
        new iCmdSearchMenu[ 33 ];
        formatex ( iCmdSearchMenu, charsmax( iCmdSearchMenu ), "\y%L", id, "ADV_MENU3_CMD_SEARCH_TITLE" ) 
        new hMenu = menu_create( iCmdSearchMenu, "Search_Handler" );
	
        new bool:bSearchFound, szNum[ 6 ];
    
        for( new i = 1 ; i < g_SongCount + 1 ; i++ )
        {
                num_to_str( i, szNum, 5 )
                ArrayGetArray( g_hArray, i, g_SongInformation );
        
                if( containi( g_SongInformation[ Name ], iText ) == -1 )
				    continue;

                bSearchFound = true;
                menu_additem( hMenu, g_SongInformation[ Name ], szNum );
        }
    
        if ( !bSearchFound ) 
        {
                client_print_color( id, NORMAL, "%L", id, "ADV_NOT_FOUND", iText );
		
                menu_destroy( hMenu );
                return;
        }
    
        client_print_color( id, NORMAL, "%L", id, "ADV_SEARCHED_FOR", iText );
        menu_display( id, hMenu )
        return;
}

public Search_Handler( id, hMenu, item )
{
        new sChoice;
		
        if( item != MENU_EXIT )
        {
                new szData[ 6 ], access, callback;
                menu_item_getinfo( hMenu, item, access, szData, charsmax( szData ), "", 0, callback )
  
                sChoice = str_to_num( szData );

                Play_Song( id, sChoice );
        }

        menu_destroy( hMenu )
        return PLUGIN_HANDLED;

}

public Cmd_CopySong( id )
{
	    if( g_Song[ 0 ] )
	    {
                g_Copied = true;
                Play_Song( id, g_Song[ 0 ] );
	    }
	    else
		        client_print_color( id, NORMAL, "%L", id, "ADV_NO_SONG_TO_COPY" );
}

Play_Song( id, iSongId ) 
{
		static Motd[ 8192 ];

		new Len, iFile = fopen( g_MusicPlayer, "r" );

		if( !iFile ) 
		{
				log_amx( "[%s] Could not open file ^"%s^".", g_szPlugin, g_MusicPlayer );
				return;
		}

		while( !feof( iFile ) )
				Len += fgets( iFile, Motd[ Len ], charsmax( Motd ) - Len );

		ArrayGetArray( g_hArray, iSongId, g_SongInformation );

		replace( Motd, charsmax( Motd ), "[MEDIA_NAME]", g_SongInformation[ Name ] );
		replace( Motd, charsmax( Motd ), "[MEDIA_URL]", g_SongInformation[ Url ] );
		new iVol[ 33 ];
		formatex( iVol, charsmax( iVol ), "volume=%i", g_Volume[ id ] );
		replace( Motd, charsmax( Motd ), "volume=70", iVol );

		if( g_Repeat[ id ] == true )
				replace( Motd, charsmax( Motd ), "repeat=never", "repeat=always" )

		show_motd( id, Motd, g_szPlugin );
		
		new szName[ 32 ];
		get_user_name( id, szName, charsmax( szName ) );
		
		if( g_Copied )
		{
			new szLastName[ 32 ];
			get_user_name( g_LastId, szLastName, charsmax( szLastName ) );
			
			ArrayGetString( g_hArray, iSongId, g_SongInformation[ Name ], charsmax( g_SongInformation[ Name ] ) )
			client_print_color( 0, NORMAL, "%L", id, "ADV_SONG_COPIED", szName, g_SongInformation[ Name ], szLastName );
			
			g_Copied = false;
		}
		else
		{
			client_print_color( 0, NORMAL, "%L", id, "ADV_LISTENING_TO", szName, g_SongInformation[ Name ] );
		}
		
		g_LastId = id;
		g_Song[ id ] = g_Song[ 0 ] = iSongId;
}

Initialize( ) 
{
        g_hArray = ArrayCreate( sizeof g_SongInformation );
        ArrayPushArray( g_hArray, "" );
    
        new Len = get_localinfo( "amxx_configsdir", g_FileName, charsmax( g_FileName ) );
        copy( g_FileName[ Len ], charsmax( g_FileName ) - Len, "/songlist.ini" );
    
        copy( g_MusicPlayer, charsmax( g_MusicPlayer ), g_FileName );
        copy( g_MusicPlayer[ Len ], charsmax( g_MusicPlayer ) - Len, "/AdvMusicPlayer.html" );
    
        if( !file_exists( g_FileName ) ) 
        {
                new iTempFile = fopen( g_FileName, "w" );
        
                if( !iTempFile ) 
                {
                        log_amx( "[%s] Could not open file ^"%s^".", g_szPlugin, g_FileName );
                        return;
                }
        
                fprintf( iTempFile, "; %s^n", g_szPlugin );
                fprintf( iTempFile, "; Format: ^"Song Name^"  ^"Url/Link^"^n" );
                fprintf( iTempFile, "; eg. ^"Eminem - Mockingbird^" ^"http://www.youtube.com/watch?v=S9bCLPwzSC0^"^n" );
        
                fclose( iTempFile );
        
                server_print( "%L", "ADV_FILE_ADDED", g_FileName );
        
                return;
        }
    
        new iFile = fopen( g_FileName, "r" );
    
        if( !iFile ) 
        {
                log_amx( "[%s] Could not open file ^"%s^".", g_szPlugin, g_FileName );
                return;
        }
    
        new iText[ 1024 ];
    
        while( !feof( iFile ) ) 
        {
        
                fgets( iFile, iText, charsmax( iText ) );
                trim( iText );
        
                if( !iText[ 0 ] || iText[ 0 ] == ';' )
                        continue;
        
                parse( iText, g_SongInformation[ Name ], charsmax( g_SongInformation[ Name ] ), g_SongInformation[ Url ], charsmax( g_SongInformation[ Url ] ) );
                trim( g_SongInformation[ Name ] );
                trim( g_SongInformation[ Url ] );
        
                if( !g_SongInformation[ Name ][ 0 ] || !g_SongInformation[ Url ][ 0 ] )
                        continue;
        
                ArrayPushArray( g_hArray, g_SongInformation );
        
                g_SongCount++;
        }
    
        fclose( iFile );
}

public plugin_end( )
        ArrayDestroy( g_hArray );

register_dictionary_colored( const iFile[ ] )
{
        if( !register_dictionary( iFile ) )
                return 0;
    
        new iLangDir[ 128 ];
        get_localinfo( "amxx_datadir", iLangDir, charsmax( iLangDir ) );
        formatex( iLangDir, charsmax( iLangDir ), "%s/lang/%s", iLangDir, iFile );
    
        new iTempFile = fopen( iLangDir, "rt" );
    
        if( !iTempFile )
        {
                log_amx( "Failed to open: %s", iLangDir );
                return 0;
        }
    
        new szBuffer[ 512 ], szLang[ 3 ], szKey[ 64 ], szTranslation[ 256 ], TransKey:iKey;
    
        while( !feof( iTempFile ) )
        {
                arrayset( szBuffer, 0, sizeof szBuffer );
                fgets( iTempFile, szBuffer, 511 );
                trim( szBuffer );
        
                if( szBuffer[ 0 ] == '[' )
                {
                        strtok( szBuffer[ 1 ], szLang, 2, szBuffer, 1, ']' );
                }

                else if( szBuffer[ 0 ] )
                {
                        strbreak( szBuffer, szKey, 63, szTranslation, 255 );
                        iKey = GetLangTransKey( szKey );
            
                        if( iKey != TransKey_Bad )
                        {
                                replace_all( szTranslation, 255, "!g", "^4" );
                                replace_all( szTranslation, 255, "!t", "^3" );
                                replace_all( szTranslation, 255, "!n", "^1" );
                
                                AddTranslation( szLang, iKey, szTranslation[ 2 ] );
                        }
                }
        }
    
        fclose( iTempFile );
    
        return 1;
}

#if AMXX_VERSION_NUM < 183
client_print_color( id, Color:type, const msg[ ], { Float, Sql, Result, _ }:... )
{
        static SayText;

        if( !SayText )
        SayText = get_user_msgid( "SayText" );
    
        static message[ 256 ];
    
        switch( type )
        {
                case GREEN: // Green
                {
                        message[ 0 ] = 0x04;
                }
                case TEAM_COLOR: // Team Color. Ie. Red (Terrorist) or blue (Counter-Terrorist).
                {
                        message[ 0 ] = 0x03;
                }
                default: // Yellow.
                {
                        message[ 0 ] = 0x01;
                }
        }

        vformat( message[ 1 ], 251, msg, 4 );

        message[ 192 ] = '^0';

        if( id )
        {
                if( is_user_connected( id ) )
                {
                        message_begin( MSG_ONE, SayText, { 0, 0, 0 }, id );
                        write_byte( id );
                        write_string( message );
                        message_end( );
                }
        } 
    
        else 
        {
                static Players[ 32 ]; new Count, Index;
                get_players( Players, Count );
        
                for( new i = 0 ; i < Count ; i++ )
                {
                        Index = Players[ i ];
            
                        message_begin( MSG_ONE, SayText, { 0, 0, 0 }, Index );
                        write_byte( Index );
                        write_string( message );
                        message_end( );
                }
        }
}
#endif