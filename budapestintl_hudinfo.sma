#include <amxmodx>
#include <engine>
#include <geoip>
#include <fakemeta>
#include <csstats>
#include <sqlx>
#include <cromchat>

#define PLUGIN  "Budapest-Intl Rank System"
#define VERSION "1.1"
#define AUTHOR  "KingMo"
#define MAX_BUFFER_LENGTH 2047

new TotalPlayedTime[33]
new PlayerCountry[33][32]
new Handle:g_SqlTuple
new g_Error[512]
new g_SyncHudMessage
new bool:g_bRankSystem
new iconstatus

new Host[] = ""
new User[] = ""
new Pass[] = ""
new Db[] = ""

new g_HudOn[33]

native crxranks_get_user_rank(id, buffer[], len)
native crxranks_get_user_xp(id)

public plugin_natives()
{
  set_native_filter("native_filter")
  g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db)
}

public native_filter(const szNative[], id, iTrap)
{
  if(!iTrap)
  {
    if(equal(szNative, "crxranks_get_user_rank"))
      return PLUGIN_HANDLED
    if(equal(szNative, "crxranks_get_user_xp"))
      return PLUGIN_HANDLED
  }
  return PLUGIN_CONTINUE
}

public plugin_precache()
{
	if(LibraryExists("crxranks", LibType_Library))
		g_bRankSystem = true
}

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  g_SyncHudMessage = CreateHudSyncObj()
  new iEnt = create_entity("info_target")
  entity_set_string(iEnt, EV_SZ_classname, "task_entity")
  register_think("task_entity", "HudEntity")
  entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0)
  //register_forward(FM_PlayerPreThink,"fw_prethink")
  iconstatus = get_user_msgid("StatusIcon")
  //register_event("StatusValue", "EventStatusValue", "b", "1>0", "2>0")
  register_clcmd("say /info","ToggleInfoHUD")
  register_clcmd("say /toptime","show_toptime",0,"- Top players by played time.")
  CC_SetPrefix("&x04[Budapest-Intl]")
  set_task(1.0, "MySql_Init")
}

public fw_prethink(id)
{
  if(!(pev(id,pev_button) & FL_ONGROUND))
  {    
    message_begin(MSG_ONE,iconstatus,{0,0,0},id)
    write_byte(0) // status (0=hide, 1=show, 2=flash)
    write_string("c4") // sprite name
    write_byte(0) // red
    write_byte(255) // green
    write_byte(0) // blue
    message_end()
    message_begin(MSG_ONE,iconstatus,{0,0,0},id)
    write_byte(0) // status (0=hide, 1=show, 2=flash)
    write_string("defuser") // sprite name
    write_byte(0) // red
    write_byte(255) // green
    write_byte(0) // blue
    message_end()
  }   
}

public MySql_Init()
{
    // we tell the API that this is the information we want to connect to,
    // just not yet. basically it's like storing it in global variables
    g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db)
   
    // ok, we're ready to connect
    SQL_SetCharset(g_SqlTuple, "utf8");
    new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,charsmax(g_Error))
    if(SqlConnection == Empty_Handle)
        // stop the plugin with an error message
        set_fail_state(g_Error)
       
    new Handle:Queries
    // Create table if not already done
    Queries = SQL_PrepareQuery(SqlConnection,"CREATE TABLE IF NOT EXISTS `budapestintl` ( `steamid` varchar(32) COLLATE utf8_unicode_ci NOT NULL, `playedtime` int(11) NOT NULL DEFAULT '0', `nickname` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL, `country` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci; ALTER TABLE `budapestintl` ADD PRIMARY KEY (`steamid`); COMMIT;")

    if(!SQL_Execute(Queries))
    {
        // if there were any problems
        SQL_QueryError(Queries,g_Error,charsmax(g_Error))
        set_fail_state(g_Error)
       
    }
    
    // close the handle
    SQL_FreeHandle(Queries)
   
    // you free everything with SQL_FreeHandle
    SQL_FreeHandle(SqlConnection)   
}


public DrawRankHUD(viewerid, vieweeid)
{
  new szRankName[2][64], szHudMessage[256], USER_COUNTRY[20], USER_NAME[25]
  new Float:USER_KDRATIO
  static iLen
  
  // Branding
  iLen = formatex(szHudMessage, charsmax(szHudMessage), "[Budapest International]^n")
  
  // Get User Name
  USER_NAME = "Budapest-Intl"
  get_user_name(vieweeid, USER_NAME, charsmax(USER_NAME))
  iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Name: %s^n", USER_NAME)
  
  // Get User Rank
  szRankName[0] = "Unranked"
  szRankName[1] = "Silver I"
  if(g_bRankSystem)
  {
    crxranks_get_user_rank(vieweeid, szRankName[0], charsmax(szRankName[]))
  }
  iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Rank: %s^n", szRankName[0])
  
  // Get User XP
  if(g_bRankSystem)
  {
    iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "XP: %i^n", crxranks_get_user_xp(vieweeid))
  }
  
  // Get User K/D Ratio
  new stats[8]
  new hits[8]
  get_user_stats(vieweeid,stats,hits)
  USER_KDRATIO = float(stats[0])/float(stats[1])
  iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "K/D: %.2f^n", USER_KDRATIO)
  
  // Get Played Time and Time of Day
  static timesec, timemin, timehr, days
  timemin = ((get_user_time(vieweeid, 1) + (TotalPlayedTime[vieweeid])) / 60) % 60
  timehr = ((get_user_time(vieweeid, 1) + (TotalPlayedTime[vieweeid])) / 3600) % 24
  timesec = ((get_user_time(vieweeid, 1) + (TotalPlayedTime[vieweeid])) - (60*timemin) - (3600*timehr)) % 60
  days = ((get_user_time(vieweeid, 1) + (TotalPlayedTime[vieweeid])) / 86400) % 365
  //get_time("%I:%M%p", ctime, 63)
  iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Online: %dd %dh %dm %ds^n", days, timehr, timemin, timesec)
  //iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Time: %s^n", ctime)
  
  formatex(USER_COUNTRY, 31, PlayerCountry[vieweeid]);
  iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Country: %s", USER_COUNTRY)

  set_hudmessage(0, 255, 0, 0.01, 0.28, 0, 0.8, 0.8)
  ShowSyncHudMsg(viewerid, g_SyncHudMessage, "%s", szHudMessage)
}

public ToggleInfoHUD(id){
  if(!g_HudOn[id])
  {
    g_HudOn[id] = 1
    CC_SendMessage(id, "You have enabled the info HUD.")
  }
  else
  {
    g_HudOn[id] = 0		
    CC_SendMessage(id, "You have disabled the info HUD.")
  }
  
  return PLUGIN_HANDLED
}

public HudEntity(iEnt)
{
  static iPlayers[32], iPlayersAlive[32], iNum, id, alive_id, iAliveNum
  //ach
  get_players(iPlayersAlive, iAliveNum, "ah")
  get_players(iPlayers, iNum, "ch")
  
  for (new i = 0; i < iNum; i++)
	{
    id = iPlayers[i]
    
    // Draw HUD for alive players
    if (is_user_alive(id))
    {
      if(is_user_connected(id) && g_HudOn[id]){
        DrawRankHUD(id, id)
      }
      
    // Draw HUD for dead players
    }else
    {
      for (new j = 0; j < iAliveNum; j++)
      {
        alive_id = iPlayersAlive[j]
        DrawRankHUD(id, alive_id) 
      }
    }
  }
  entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.6)
}

/*public EventStatusValue(const id)
{
	static szMessage[34], iPlayer, iAux
	get_user_aiming(id, iPlayer, iAux)
	
	if (is_user_alive(iPlayer))
	{
    static szRankName[64]
    //get_user_rank_name(iPlayer, szRankName, charsmax(szRankName))
    szRankName = "Rank Name"
    formatex(szMessage, charsmax(szMessage), "1 PLAYER: %%p2 | Rank: %s | XP: %i", szRankName, 500)
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText") , _, id)
    write_byte(0)
    write_string(szMessage)
    message_end()
	}
}*/

public client_disconnected(id)
{
  if(!is_user_bot(id)){
    Save_MySql(id)
    g_HudOn[id] = 0
  }
}

public client_putinserver(id)
{
	if(!is_user_bot(id)){
    Load_MySql(id)
  }
}

public plugin_end()
{
  SQL_FreeHandle(g_SqlTuple)
}


public GetSecureName ( const name [ ] )
{
    new secureName [ 32 ]
    copy ( secureName, charsmax ( secureName ) , name )
   
    replace_all (secureName, charsmax (secureName) , "\" , "")
    replace_all (secureName, charsmax (secureName), "'", "")
    replace_all (secureName, charsmax (secureName), "`","")
    replace_all (secureName, charsmax (secureName), "^"","^"")
   
    return secureName
}

public Load_MySql(id)
{
    new szSteamId[32], szTemp[512]
    get_user_authid(id, szSteamId, charsmax(szSteamId))
    
    new Data[1]
    Data[0] = id
    
    format(szTemp,charsmax(szTemp),"SELECT * FROM `budapestintl` WHERE (`budapestintl`.`steamid` = '%s')", szSteamId)
    SQL_SetCharset(g_SqlTuple, "utf8");
    SQL_ThreadQuery(g_SqlTuple,"register_client",szTemp,Data,1)
}

public register_client(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    if(FailState == TQUERY_CONNECT_FAILED)
    {
        log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error)
    }
    else if(FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("Load Query failed. [%d] %s", Errcode, Error)
    }

    new id
    id = Data[0]
    
    SQL_SetCharset(g_SqlTuple, "utf8");
    if(SQL_NumResults(Query) < 1) 
    {
        //.if there are no results found
        
        new szSteamId[32]
        get_user_authid(id, szSteamId, charsmax(szSteamId)) // get user's steamid
        
        //  if its still pending we can't do anything with it
        if (equal(szSteamId,"ID_PENDING"))
            return PLUGIN_HANDLED
            
        new szTemp[512]
        
        new szNickname[32]
        new szUserIP[32]
        new szCountry[32]
        
        // Get User Country
        get_user_ip(id, szUserIP, charsmax(szUserIP), 1)
        #if defined geoip_country_ex
          geoip_country_ex(szUserIP, szCountry, charsmax(szCountry))
        #else
          geoip_country(szUserIP, szCountry, charsmax(szCountry))
        #endif
        if(strlen(szCountry) < 1){
          szCountry = "Unknown"
        }
  
        formatex(PlayerCountry[id], 31, szCountry);
        
        // Get User Nickname
        get_user_name(id, szNickname, 31)		
        
        // now we will insert the values into our table.
        format(szTemp,charsmax(szTemp),"INSERT INTO `budapestintl` ( `steamid` , `playedtime`, `nickname`, `country` )VALUES ('%s','0','%s','%s');", szSteamId, GetSecureName(szNickname), szCountry)
        SQL_SetCharset(g_SqlTuple, "utf8");
        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp)
    } 
    else 
    {
        // if there are results found
        SQL_SetCharset(g_SqlTuple, "utf8");
        new col = SQL_FieldNameToNum(Query,"playedtime")
        TotalPlayedTime[id] = SQL_ReadResult(Query, col)
        
        new col2 = SQL_FieldNameToNum(Query,"country")
        new szPlayerCountry[32]
        SQL_ReadResult(Query, col2, szPlayerCountry, charsmax(szPlayerCountry))
        formatex(PlayerCountry[id], 31, szPlayerCountry)
    }
    
    return PLUGIN_HANDLED
}


public Save_MySql(id)
{
  new szSteamId[32], szTemp[512]
  new szNickname[32]
  new szUserIP[32]
  new szCountry[32]
  // Get User Country
  get_user_ip(id, szUserIP, charsmax(szUserIP), 1)
  #if defined geoip_country_ex
    geoip_country_ex(szUserIP, szCountry, charsmax(szCountry))
  #else
    geoip_country(szUserIP, szCountry, charsmax(szCountry))
  #endif
  if(strlen(szCountry) < 1){
    szCountry = "Unknown"
  }
  // Get User Nickname
  get_user_name(id, szNickname, 31)		    
  get_user_authid(id, szSteamId, charsmax(szSteamId))
  TotalPlayedTime[id] = TotalPlayedTime[id] + (get_user_time(id))
  // Here we will update the user hes information in the database where the steamid matches.
  format(szTemp,charsmax(szTemp),"UPDATE `budapestintl` SET `playedtime` = `playedtime` + '%i', `nickname` = '%s', `country` = '%s' WHERE `budapestintl`.`steamid` = '%s';",get_user_time(id), GetSecureName(szNickname), szCountry, szSteamId)
  SQL_SetCharset(g_SqlTuple, "utf8");
  SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp)
}

public show_toptime(id)
{
  new line[256]
  new motd[2048]
  new PlayerNickname[32]
  new PlayedTime
  add(motd,2048,"<html><head><meta charset=^"UTF-8^">")
  add(motd,2048,"<style>.header{font-weight: bold;}</style>")
  add(motd,2048,"<body style=^"background: #000; color: #FFB000;^">")
  new len = add(motd,2048,"<table border=0 cellspacing=0 cellpadding=1 width=90% align=center>")
  len += add(motd[len],2048-len,"<tr><td class=header>#</td><td class=header>Name</td><td class=header>Played Time</td></tr>")
  new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,charsmax(g_Error))
  if(SqlConnection == Empty_Handle)
    set_fail_state(g_Error)
  new Handle:szTemp
  szTemp = SQL_PrepareQuery(SqlConnection,"SELECT `nickname`, `playedtime` FROM `budapestintl` ORDER BY `budapestintl`.`playedtime` DESC")
  SQL_SetCharset(g_SqlTuple, "utf8")
  if(!SQL_Execute(szTemp))
  {
    SQL_QueryError(szTemp,g_Error,charsmax(g_Error))
    set_fail_state(g_Error)
  }
  new nicknamecol = SQL_FieldNameToNum(szTemp,"nickname")
  new playedtimecol = SQL_FieldNameToNum(szTemp,"playedtime")
  new timesec, timemin, timehr, days
  for(new i = 0; i < 15; ++i) {
    if(SQL_MoreResults(szTemp)){
      //SQL_SetCharset(g_SqlTuple, "utf8")
      SQL_ReadResult(szTemp, nicknamecol, PlayerNickname, charsmax(PlayerNickname))
      PlayedTime = SQL_ReadResult(szTemp, playedtimecol)
      timemin = (PlayedTime / 60) % 60
      timehr = (PlayedTime / 3600) % 24
      timesec = ((PlayedTime) - (60*timemin) - (3600*timehr)) % 60
      days = (PlayedTime / 86400) % 365
      if(days > 0){
        format(line,255,"<tr><td> %d. <td> %s <td> %dd %dh %dm %ds", (i+1), PlayerNickname, days, timehr, timemin, timesec)
      }else{
        format(line,255,"<tr><td> %d. <td> %s <td> %dh %dm %ds", (i+1), PlayerNickname, timehr, timemin, timesec)
      }
      len += add(motd[len], 2048-len, line )
      SQL_NextRow(szTemp)
    }
  }
  format(line, 255, "</table>" )
  len += format( motd[len], 2048-len, line )
  add(motd,2048,"</body></html>")
  show_motd( id, motd, "Top Time [Budapest-Intl]") 
  SQL_FreeHandle(szTemp)
  SQL_FreeHandle(SqlConnection)
  return PLUGIN_CONTINUE
}

public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    SQL_FreeHandle(Query)
    
    return PLUGIN_HANDLED
}