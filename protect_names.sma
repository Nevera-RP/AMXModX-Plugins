#include < amxmodx >
#include < amxmisc >
#include < regex >
#include < fakemeta >

enum ( <<= 1 )
{
	MATCH_EQUAL = 1,
	MATCH_CONTAIN,
	MATCH_CASESENSITIVE,
	MATCH_REGEX
};

enum
{
	RESTRICT_IP = 1,
	RESTRICT_STEAMID,
	RESTRICT_FLAGS
};

enum _:name_t
{
	m_szName[ 32 ],
	m_iMatchFlags,
	m_iszPattern,
	m_pPattern,
	m_szRestricted[ 64 ],
	m_iRestrictFlags,
	m_szReplacement[ 32 ]
};

// Note:
// If m_iRestrictFlags & RESTRICT_FLAGS
// 	iAccessFlags = iRestrictFlags >> 2

new Array:g_aNameDatas;
new g_iNumNames;

new bool:g_bIsDedicatedServer;

new g_pCvarPunish;
new g_pCvarCommand;
new g_pCvarReason;

new g_pCvarMode;
new g_pCvarPasswordField;
new g_pCvarDefaultAccess;

public plugin_init( )
{
	register_plugin( "Protect Names", "0.0.2", "Exolent" );
	
	register_forward( FM_ClientUserInfoChanged, "FwdClientUserInfoChanged" );
	
	g_pCvarPunish  = register_cvar( "protect_name_punish" , "0" );
	g_pCvarCommand = register_cvar( "protect_name_command", "kick %userid% \'%reason%\'" );
	g_pCvarReason  = register_cvar( "protect_name_reason" , "%name% is protected and you are not allowed to use it!" );
	
	g_pCvarMode = register_cvar( "amx_mode", "1" );
	g_pCvarPasswordField = register_cvar( "amx_password_field", "_pw" );
	g_pCvarDefaultAccess = register_cvar( "amx_default_access", "" );
	
	g_aNameDatas = ArrayCreate( name_t );
	
	LoadNames( );
	
	g_bIsDedicatedServer = bool:is_dedicated_server( );
}

public plugin_end( )
{
	new eNameData[ name_t ];
	
	for( new i = 0; i < g_iNumNames; i++ )
	{
		ArrayGetArray( g_aNameDatas, i, eNameData );
		
		if( eNameData[ m_iMatchFlags ] & MATCH_REGEX )
		{
			regex_free( Regex:eNameData[ m_pPattern ] );
		}
	}
	
	ArrayDestroy( g_aNameDatas );
}

public client_authorized( iPlayer )
{
	CheckName( iPlayer );
}

public client_putinserver( iPlayer )
{
	if( !g_bIsDedicatedServer && iPlayer == 1 )
	{
		CheckName( iPlayer );
	}
}

public FwdClientUserInfoChanged( iPlayer )
{
	new szOldName[ 32 ], szNewName[ 32 ];
	pev( iPlayer, pev_netname, szOldName, charsmax( szOldName ) );
	
	if( szOldName[ 0 ] )
	{
		get_user_info( iPlayer, "name", szNewName, charsmax( szNewName ) )
		
		if( !equal( szOldName, szNewName ) )
		{
			return CheckName( iPlayer, szNewName );
		}
	}
	else if( get_user_info( iPlayer, "name", szNewName, charsmax( szNewName ) ) )
	{
		return CheckName( iPlayer, szNewName );
	}
	
	return FMRES_IGNORED;
}

CheckName( iPlayer, szCurrentName[ 32 ] = "" )
{
	if( !szCurrentName[ 0 ] )
	{
		get_user_name( iPlayer, szCurrentName, charsmax( szCurrentName ) );
	}
	
	new szIP[ 16 ], szSteamID[ 35 ];
	get_user_ip( iPlayer, szIP, charsmax( szIP ), 1 );
	get_user_authid( iPlayer, szSteamID, charsmax( szSteamID ) );
	
	new iFlags = PredictNewFlags( iPlayer, szCurrentName, szSteamID, szIP );
	
	new eNameData[ name_t ];
	new bCaseSensitive;
	
	for( new i = 0; i < g_iNumNames; i++ )
	{
		ArrayGetArray( g_aNameDatas, i, eNameData );
		
		if( eNameData[ m_iMatchFlags ] & MATCH_REGEX )
		{
			// Using bCaseSensitive as a temporary return value to not use another variable
			
			if( regex_match_c( szCurrentName, Regex:eNameData[ m_pPattern ], bCaseSensitive ) <= 0 )
			{
				continue;
			}
		}
		else
		{
			bCaseSensitive = !!( eNameData[ m_iMatchFlags ] & MATCH_CASESENSITIVE );
			
			if( ( eNameData[ m_iMatchFlags ] & MATCH_EQUAL )
				? strcmp( szCurrentName, eNameData[ m_szName ], !bCaseSensitive ) != 0
				: strfind( szCurrentName, eNameData[ m_szName ], !bCaseSensitive ) == -1 )
			{
				continue;
			}
		}
		
		// Name matched this restriction if made it this far
		
		if( ( eNameData[ m_iRestrictFlags ] & 3 ) == RESTRICT_FLAGS )
		{
			// Using bCaseSensitive as a temporary return value to not use another variable
			
			bCaseSensitive = eNameData[ m_iRestrictFlags ] >> 2;
			
			if( ( iFlags & bCaseSensitive ) == bCaseSensitive )
			{
				continue;
			}
		}
		else
		{
			if( equal( eNameData[ m_szRestricted ], ( eNameData[ m_iRestrictFlags ] == RESTRICT_IP ) ? szIP : szSteamID ) )
			{
				continue;
			}
		}
		
		// Player does not have access to name if made it this far
		
		new szUserID[ 13 ];
		formatex( szUserID, charsmax( szUserID ), "#%d", get_user_userid( iPlayer ) );
		
		if( eNameData[ m_iMatchFlags ] & MATCH_REGEX )
		{
			static szPattern[ 512 ];
			global_get( glb_pStringBase, eNameData[ m_iszPattern ], szPattern, charsmax( szPattern ) );
			
			log_amx( "%s<%s><%s><%s> used a restricted name, which matched RegEx pattern %s", szCurrentName, szUserID, szSteamID, szIP, szPattern );
		}
		else
		{
			log_amx( "%s<%s><%s><%s> used a restricted name, which matched %s", szCurrentName, szUserID, szSteamID, szIP, eNameData[ m_szName ] );
		}
		
		new szReason[ 192 ];
		get_pcvar_string( g_pCvarReason, szReason, charsmax( szReason ) );
		
		FixFormatting( szReason, charsmax( szReason ), szCurrentName, szSteamID, szUserID, szIP );
		
		if( get_pcvar_num( g_pCvarPunish ) )
		{
			new szCommand[ 192 ];
			get_pcvar_string( g_pCvarCommand, szCommand, charsmax( szCommand ) );
			
			FixFormatting( szCommand, charsmax( szCommand ), szCurrentName, szSteamID, szUserID, szIP, szReason );
			
			server_cmd( "%s", szCommand );
			server_exec( );
		}
		else
		{
			set_user_info( iPlayer, "name", eNameData[ m_szReplacement ] );
			
			if( szReason[ 0 ] )
			{
				client_print( iPlayer, print_chat, "* %s", szReason );
			}
		}
		
		return FMRES_HANDLED;
	}
	
	return FMRES_IGNORED;
}

PredictNewFlags( iPlayer, const szName[ ], const szSteamID[ ], const szIP[ ] )
{
	// Code here mimics admin.sma's method of accessing admins
	// This is done since some name checking is done before admin.sma gives access
	
	new iMode = get_pcvar_num( g_pCvarMode );
	
	if( !iMode )
	{
		return 0;
	}
	
	new iNumAdmins = admins_num( );
	new iIndex = -1;
	new iFlags;
	new szAuth[ 44 ]; // Size from admin.sma
	new iLen;
	
	for( new i = 0; i < iNumAdmins; i++ )
	{
		iFlags = admins_lookup( i, AdminProp_Flags );
		
		admins_lookup( i, AdminProp_Auth, szAuth, charsmax( szAuth ) );
		
		if( iFlags & FLAG_AUTHID )
		{
			if( equal( szAuth, szSteamID ) )
			{
				iIndex = i;
				break;
			}
		}
		else if( iFlags & FLAG_IP )
		{
			iLen = strlen( szAuth ) - 1;
			
			if( szAuth[ iLen ] != '.' )
			{
				iLen = 0;
			}
			
			if( equal( szAuth, szIP, iLen ) )
			{
				iIndex = i;
				break;
			}
		}
		else
		{
			if( ( iFlags & FLAG_TAG )
				? ( strfind( szName, szAuth, _:( !( iFlags & FLAG_CASE_SENSITIVE ) ) ) != -1 )
				: ( strcmp( szName, szAuth,  _:( !( iFlags & FLAG_CASE_SENSITIVE ) ) ) !=  0 ) )
			{
				iIndex = i;
				break;
			}
		}
	}
	
	new iAccess;
	
	if( iIndex >= 0 )
	{
		if( ~iFlags & FLAG_NOPASS )
		{
			new szPasswordField[ 32 ]; // Size from admin.sma
			get_pcvar_string( g_pCvarPasswordField, szPasswordField, charsmax( szPasswordField ) );
			
			new szPassword[ 32 ]; // Size from admin.sma
			get_user_info( iPlayer, szPasswordField, szPassword, charsmax( szPassword ) );
			
			new szAccessPassword[ sizeof( szPassword ) ];
			admins_lookup( iIndex, AdminProp_Password, szAccessPassword, charsmax( szAccessPassword ) );
			
			if( !equal( szPassword, szAccessPassword ) )
			{
				return 0;
			}
		}
		
		iAccess = admins_lookup( iIndex, AdminProp_Access );
	}
	else if( iMode != 2 )
	{
		new szFlags[ 27 ];
		get_pcvar_string( g_pCvarDefaultAccess, szFlags, charsmax( szFlags ) );
		
		iAccess = read_flags( szFlags );
		
		if( !iAccess )
		{
			iAccess = ADMIN_USER;
		}
	}
	
	return iAccess;
}

FixFormatting( szString[ ], iMaxLen, const szName[ ], const szSteamID[ ], const szUserID[ ], const szIP[ ], const szReason[ ] = "" )
{
	replace_all( szString, iMaxLen, "\'", "^"" );
	replace_all( szString, iMaxLen, "%name%", szName );
	replace_all( szString, iMaxLen, "%steamid%", szSteamID );
	replace_all( szString, iMaxLen, "%userid%", szUserID );
	replace_all( szString, iMaxLen, "%ip%", szIP );
	replace_all( szString, iMaxLen, "%reason%", szReason );
}

LoadNames( )
{
	new szFile[ 64 ];
	get_configsdir( szFile, charsmax( szFile ) );
	add( szFile, charsmax( szFile ), "/protect_names.ini" );
	
	new pFile = fopen( szFile, "rt" );
	
	if( pFile )
	{
		new iLine;
		
		new szMatchType[ 16 ];
		new szMatchString[ 512 ];
		new szRestrictType[ 16 ];
		new szRestrictedString[ 64 ];
		new szReplacement[ 32 ];
		new szLine[ sizeof( szMatchType ) + sizeof( szMatchString ) + sizeof( szRestrictType ) + sizeof( szRestrictedString ) + sizeof( szReplacement ) + 10 ];
		
		new eNameData[ name_t ];
		new szError[ 128 ], iReturn;
		
		while( !feof( pFile ) )
		{
			iLine++;
			
			fgets( pFile, szLine, charsmax( szLine ) );
			trim( szLine );
			
			if( !szLine[ 0 ] || szLine[ 0 ] == ';'
			||  szLine[ 0 ] == '/' && szLine[ 1 ] == '/'
			||  parse( szLine,
				szMatchType, charsmax( szMatchType ),
				szMatchString, charsmax( szMatchString ),
				szRestrictType, charsmax( szRestrictType ),
				szRestrictedString, charsmax( szRestrictedString ),
				szReplacement, charsmax( szReplacement ) ) < 5 )
			{
				continue;
			}
			
			// Default match and restrict flags to none
			
			eNameData[ m_iMatchFlags ] = 0;
			eNameData[ m_iRestrictFlags ] = 0;
			
			// Read the match type and string
			
			if( equali( szMatchType, "contain", 7 ) )
			{
				eNameData[ m_iMatchFlags ] |= MATCH_CONTAIN;
				
				if( szMatchType[ 7 ] != 'I' && szMatchType[ 7 ] != 'i' )
				{
					eNameData[ m_iMatchFlags ] |= MATCH_CASESENSITIVE;
				}
				
				copy( eNameData[ m_szName ], charsmax( eNameData[ m_szName ] ), szMatchString );
			}
			else if( equali( szMatchType, "equal", 5 ) )
			{
				eNameData[ m_iMatchFlags ] |= MATCH_EQUAL;
				
				if( szMatchType[ 5 ] != 'I' && szMatchType[ 5 ] != 'i' )
				{
					eNameData[ m_iMatchFlags ] |= MATCH_CASESENSITIVE;
				}
				
				copy( eNameData[ m_szName ], charsmax( eNameData[ m_szName ] ), szMatchString );
			}
			else if( equali( szMatchType, "regex", 5 ) )
			{
				eNameData[ m_iMatchFlags ] |= MATCH_REGEX;
				
				if( szMatchType[ 5 ] == '/' )
				{
					format( szMatchType, charsmax( szMatchType ), "%s", szMatchType[ 6 ] );
				}
				else
				{
					szMatchType[ 0 ] = EOS;
				}
				
				eNameData[ m_pPattern ] = _:regex_compile( szMatchString, iReturn, szError, charsmax( szError ), szMatchType );
				
				if( Regex:eNameData[ m_pPattern ] < REGEX_OK )
				{
					log_amx( "Error on pattern compiling for line #%d: %s", iLine, szError );
					continue;
				}
				
				eNameData[ m_iszPattern ] = engfunc( EngFunc_AllocString, szMatchString );
			}
			else
			{
				continue;
			}
			
			// Read the restricted type
			
			if( equali( szRestrictType, "steam", 5 ) )
			{
				eNameData[ m_iRestrictFlags ] = RESTRICT_STEAMID;
				
				copy( eNameData[ m_szRestricted ], charsmax( eNameData[ m_szRestricted ] ), szRestrictedString );
			}
			else if( equali( szRestrictType, "ip", 2 ) || equali( szRestrictType, "address", 7 ) )
			{
				eNameData[ m_iRestrictFlags ] = RESTRICT_IP;
				
				copy( eNameData[ m_szRestricted ], charsmax( eNameData[ m_szRestricted ] ), szRestrictedString );
			}
			else if( equali( szRestrictType, "flag", 4 ) )
			{
				eNameData[ m_iRestrictFlags ] = RESTRICT_FLAGS | ( read_flags( szRestrictedString ) << 2 );
			}
			else
			{
				continue;
			}
			
			copy( eNameData[ m_szReplacement ], charsmax( eNameData[ m_szReplacement ] ), szReplacement );
			
			// Everything was parsed, so add to the array
			
			ArrayPushArray( g_aNameDatas, eNameData );
			g_iNumNames++;
		}
		
		fclose( pFile );
	}
	
	if( !g_iNumNames )
	{
		set_fail_state( "No names were loaded to protect" );
	}
}
