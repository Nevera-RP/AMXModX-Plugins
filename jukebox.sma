#include <amxmodx>
#include <amxmisc>
#include <nvault>

#define ADMIN_FLAG ADMIN_CFG
#define PREFIX "Jukebox"
#define MAX_SONGS_IN_QUEUE 10
#define TASK_ID 7878789

new const g_szBar[][] =
{
	"====================",
	"|===================",
	"||==================",
	"|||=================",
	"||||================",
	"|||||===============",
	"||||||==============",
	"|||||||=============",
	"||||||||============",
	"|||||||||===========",
	"||||||||||==========",
	"|||||||||||=========",
	"||||||||||||========",
	"|||||||||||||=======",
	"||||||||||||||======",
	"|||||||||||||||=====",
	"||||||||||||||||====",
	"|||||||||||||||||===",
	"||||||||||||||||||==",
	"|||||||||||||||||||=",
	"||||||||||||||||||||"
}

enum _:GenresInfo
{
	GenreName[64],
	GenreSongsNum
}

enum _:SongsInfo
{
	SongName[128],
	SongUrl[256],
	SongGenre,
	SongTime
}

enum _:SettingsInfo
{
	bool:b_on,
	bool:b_hud,
	i_repeat,
	i_vol,
	i_queue[MAX_SONGS_IN_QUEUE],
	i_search_menu,
	i_menu_choice,
	i_genre,
	i_hud_color[3],
	Float:f_hud_pos[2],
	Float:f_start_time,
	Float:f_last_show_song
}

enum
{
	_edit_none,
	_edit_name,
	_edit_url,
	_edit_time,
	_edit_genre
}

enum
{
	_mode_none,
	_mode_add,
	_mode_remove,
	_mode_edit
}

enum _:SongTempInfo
{
	SongTempName[128],
	SongTempUrl[256],
	SongTempGenre[64],
	SongTempTime
}

new iRequestsFile[64], iSongsFile[64], g_PlayerSettings[33][SettingsInfo], g_EditMode[33], g_EditSetting[33], g_TempSettings[33][SongTempInfo];
new gVault, vKey[32], vData[256];
new g_MsgSayText;
new iVolumeMenu;
new Array:g_aGenres, Array:g_aSongs;
public plugin_init()
{
	register_plugin("Jukebox", "1.1", "Wicked-");
	register_cvar("jukebox_bywicked-", "1.1", FCVAR_SERVER|FCVAR_SPONLY);

	g_aGenres = ArrayCreate(GenresInfo);
	g_aSongs = ArrayCreate(SongsInfo);

	register_clcmd("say", "cmdSay");
	register_clcmd("say_team", "cmdSay");
	register_concmd("amx_requests", "ViewRequests");
	register_concmd("amx_del_requests", "DeleteRequests");

	register_concmd("Type_The_Song", "Request_Song");
	register_concmd("Type_Hud_Setting", "Hud_Setting");
	register_concmd("Type_Setting", "SongEditSetting");
	register_concmd("Find_Song", "SearchForSong");

	g_MsgSayText = get_user_msgid("SayText");

	set_task(150.0, "message" ,0, _, 0, "b");
	formatex(iRequestsFile, charsmax(iRequestsFile), "addons/amxmodx/configs/jukebox_req_songs.ini");
	formatex(iSongsFile, charsmax(iSongsFile), "addons/amxmodx/configs/jukebox_songs.ini");
	LoadSongs();
	gVault = nvault_open("jukebox");
	if(gVault == INVALID_HANDLE)
		set_fail_state("[Jukebox] nValut ERROR: =-> Invalid-Handle");
	set_task(1.0, "hud_display", 0, _, _, "b");

	iVolumeMenu = menu_create("Choose Volume:", "volumemenu_handler");
	menu_additem(iVolumeMenu, "\w15%", "15", 0);
	menu_additem(iVolumeMenu, "\w25%", "25", 0);
	menu_additem(iVolumeMenu, "\w50%", "50", 0);
	menu_additem(iVolumeMenu, "\w75%", "75", 0);
	menu_additem(iVolumeMenu, "\w100%", "100", 0);
	menu_setprop(iVolumeMenu, MPROP_EXITNAME, "Back to \rMain Menu");
	menu_setprop(iVolumeMenu, MPROP_EXIT, MEXIT_ALL);
}

public cmdReplay(id)
{
	if(g_PlayerSettings[id][i_queue][0] >= 0)
	{
		if(task_exists(id+TASK_ID))
			remove_task(id+TASK_ID)
		PlayCurrentSong(id);
	}
	else
		Jukebox_Print(id, "There's no song playing now.");
}

public plugin_natives()
{
	register_library("jukebox_bywicked")
	register_native("stop_song", "native_stop_song", 1);
}
public native_stop_song(id) StopJukebox(id);

LoadSongs()
{
	if(file_exists(iSongsFile))
	{
		new i, szData[512], iFile, str_gen[64], str_time[12], aGenreData[GenresInfo], aSongData[SongsInfo], genres_num = ArraySize(g_aGenres);
		iFile = fopen(iSongsFile, "rt");
		while(!feof(iFile))
		{
			fgets(iFile, szData, charsmax(szData));
			if(!szData[0] || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/'))
				continue;
			parse(szData, aSongData[SongName],127, aSongData[SongUrl],255, str_gen,63, str_time,11);
			for(i=0;i<genres_num;i++)
			{
				ArrayGetArray(g_aGenres, i, aGenreData);
				if(equal(aGenreData[GenreName], str_gen))
				{
					aSongData[SongGenre] = i;
					aGenreData[GenreSongsNum]++;
					ArraySetArray(g_aGenres, i, aGenreData);
					break;
				}
			}
			if(i == genres_num)
			{
				aGenreData[GenreSongsNum] = 1;
				copy(aGenreData[GenreName], 63, str_gen);
				ArrayPushArray(g_aGenres, aGenreData);
				aSongData[SongGenre] = i;
				genres_num++;
			}
			aSongData[SongTime] = str_to_num(str_time);
			ArrayPushArray(g_aSongs, aSongData);
		}
		fclose(iFile);
	}
}

UpdateSongsFile(id)
{
	if(file_exists(iSongsFile))
		delete_file(iSongsFile);
	new iFile, szData[512], i, aSongData[SongsInfo], aGenreData[GenresInfo];
	iFile = fopen(iSongsFile, "wt");
	fputs(iFile, "; ^"Song Name^" ^"Song Stream Url^" ^"Genre^" ^"Song Time In Seconds^"^n");
	fputs(iFile, "; If u put 2 or more songs with the exact same genre they will merge into one genre.^n");
	fputs(iFile, "; Link must end with .mp3^n");
	fputs(iFile, ";^n; Example:^n;^"Blue Stahli - The Pure And The Tainted^" ^"http://a.tumblr.com/tumblr_mcgfc9J6wa1rplis8o1.mp3^" ^"Rock^" ^"125^"^n");
	for(i=0;i<ArraySize(g_aSongs);i++)
	{
		ArrayGetArray(g_aSongs, i, aSongData);
		ArrayGetArray(g_aGenres, aSongData[SongGenre], aGenreData);
		formatex(szData, charsmax(szData), "^"%s^" ^"%s^" ^"%s^" ^"%d^"^n", aSongData[SongName], aSongData[SongUrl], aGenreData[GenreName], aSongData[SongTime]);
		fputs(iFile, szData);
	}
	fclose(iFile);
	if(id)
		Jukebox_Print(id, "Successfully updated songs file.");
}

public client_putinserver(id)
{
	if(is_user_bot(id))
		return;
	for(new i=0;i<MAX_SONGS_IN_QUEUE;i++)
		g_PlayerSettings[id][i_queue][i] = -1;
	new str_hud[6], str_hud_color[3][12], str_hud_position[2][12], str_vol[6], str_repeat[6];
	get_user_authid(id, vKey, charsmax(vKey));
	if(nvault_get(gVault, vKey, vData, charsmax(vData)))
	{
		replace_all(vData,charsmax(vData),"#"," ");
		parse(vData, str_hud,5, str_hud_color[0],11, str_hud_color[1],11, str_hud_color[2],11, str_hud_position[0],11, str_hud_position[1],11, str_vol,5, str_repeat,5);
		g_PlayerSettings[id][b_on] = false;
		g_PlayerSettings[id][b_hud] = str_to_num(str_hud);
		g_PlayerSettings[id][i_hud_color][0] = str_to_num(str_hud_color[0]);
		g_PlayerSettings[id][i_hud_color][1] = str_to_num(str_hud_color[1]);
		g_PlayerSettings[id][i_hud_color][2] = str_to_num(str_hud_color[2]);
		g_PlayerSettings[id][f_hud_pos][0] = _:str_to_float(str_hud_position[0]);
		g_PlayerSettings[id][f_hud_pos][1] = _:str_to_float(str_hud_position[1]);
		g_PlayerSettings[id][i_vol] = str_to_num(str_vol);
		g_PlayerSettings[id][i_repeat] = str_to_num(str_repeat);
	}
	else
	{
		g_PlayerSettings[id][b_on] = false;
		g_PlayerSettings[id][b_hud] = true;
		g_PlayerSettings[id][i_hud_color][0] = 0;
		g_PlayerSettings[id][i_hud_color][1] = 255;
		g_PlayerSettings[id][i_hud_color][2] = 0;
		g_PlayerSettings[id][f_hud_pos][0] = _:0.11;
		g_PlayerSettings[id][f_hud_pos][1] = _:0.05;
		g_PlayerSettings[id][i_vol] = 75;
		g_PlayerSettings[id][i_repeat] = 0;
	}
	g_PlayerSettings[id][i_search_menu] = 0;
	g_PlayerSettings[id][i_menu_choice] = -1;
	g_EditSetting[id] = _edit_none;
	g_EditMode[id] = _mode_none;
	set_task(0.5, "taskStopJukebox", id+5555);
}

public taskStopJukebox(id)
{
	id -= 5555;
	StopJukebox(id);
}

public client_disconnect(id)
{
	if(is_user_bot(id))
		return;
	get_user_authid(id, vKey, charsmax(vKey));
	formatex(vData, charsmax(vData),"%d#%d#%d#%d#%.3f#%.3f#%d#%d#", g_PlayerSettings[id][b_hud], g_PlayerSettings[id][i_hud_color][0], g_PlayerSettings[id][i_hud_color][1], g_PlayerSettings[id][i_hud_color][2], g_PlayerSettings[id][f_hud_pos][0], g_PlayerSettings[id][f_hud_pos][1], g_PlayerSettings[id][i_vol], g_PlayerSettings[id][i_repeat]);
	nvault_set(gVault, vKey, vData);
}

public hud_display()
{
	static id, iPlayers[32], iNum, i, aSongData[SongsInfo], szTrackTime[64], szSong2Name[128];
	get_players(iPlayers, iNum);
	for(i=0;i<iNum;i++)
	{
		id = iPlayers[i];
		if(g_PlayerSettings[id][b_hud] && is_user_connected(id))
		{
			if(g_PlayerSettings[id][i_queue][1] >= 0)
			{
				ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][1], aSongData);
				copy(szSong2Name, charsmax(szSong2Name), aSongData[SongName]);
			}
			else
				formatex(szSong2Name, charsmax(szSong2Name), "N/A");
			if(g_PlayerSettings[id][i_queue][0] >= 0)
			{
				ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][0], aSongData);
				static gSongTime;
				gSongTime = aSongData[SongTime];
				if(g_PlayerSettings[id][b_on])
				{
					static secondsPassed, PercentTime;
					secondsPassed = floatround(get_gametime() - g_PlayerSettings[id][f_start_time])
					PercentTime = floatround((float(secondsPassed)/float(gSongTime)) * 100.0)
					formatex(szTrackTime, charsmax(szTrackTime), "%d:%02d [%s] %d:%02d", (secondsPassed / 60), (secondsPassed % 60), g_szBar[PercentTime/5], (gSongTime / 60), (gSongTime % 60))
				}
				else
					formatex(szTrackTime, 63, "0.00 [%s] %d:%02d", g_szBar[0], (gSongTime / 60), (gSongTime % 60))
			}
			else
			{
				formatex(szTrackTime, 63, "0.00 [%s] 0.00", g_szBar[0]);
				formatex(aSongData[SongName], 127, "N/A");
			}
			set_hudmessage(g_PlayerSettings[id][i_hud_color][0], g_PlayerSettings[id][i_hud_color][1], g_PlayerSettings[id][i_hud_color][2], g_PlayerSettings[id][f_hud_pos][0], g_PlayerSettings[id][f_hud_pos][1], 0, 0.1, 1.0, 0.1, 0.5);
			show_hudmessage(id, "Now: %s^nTime: %s^nNext: %s", aSongData[SongName], szTrackTime, szSong2Name);
		}
	}
}

public SongEnd(id)
{
	id -= TASK_ID
	if(g_PlayerSettings[id][i_repeat] != 1)
	{
		for(new i=1;i<MAX_SONGS_IN_QUEUE;i++)
			g_PlayerSettings[id][i_queue][i-1] = g_PlayerSettings[id][i_queue][i]
		g_PlayerSettings[id][i_queue][MAX_SONGS_IN_QUEUE-1] = -1
		if(g_PlayerSettings[id][i_repeat] == 2)
			g_PlayerSettings[id][i_repeat] = 1;
	}
	if(g_PlayerSettings[id][i_queue][0] >= 0)
		PlayCurrentSong(id);
	else
		g_PlayerSettings[id][b_on] = false;
}

public cmdPlaySong(id)
{
	if(g_PlayerSettings[id][b_on])
	{
		Jukebox_Print(id, "You are currently listening to a song.");
		return PLUGIN_HANDLED;
	}
	if(g_PlayerSettings[id][i_queue][0] < 0)
	{
		Jukebox_Print(id, "First pick a song to play.");
		g_EditMode[id] = _mode_none;
		GenresMenu(id);
	}
	else
		PlayCurrentSong(id);
	return PLUGIN_HANDLED;
}

public cmdPlayNextSong(id)
{
	if(g_PlayerSettings[id][i_queue][1] >= 0)
	{
		g_PlayerSettings[id][b_on] = true;
		if(task_exists(id+TASK_ID))
			remove_task(id+TASK_ID);
		if(g_PlayerSettings[id][i_repeat])
			g_PlayerSettings[id][i_repeat] = 2;
		SongEnd(id+TASK_ID);
	}
	else
		Jukebox_Print(id, "First put another song in queue.");
	return PLUGIN_HANDLED;
}

public cmdShowSongName(id)
{
	if(g_PlayerSettings[id][i_queue][0] >= 0)
	{
		static Float:fGameTime, UseAfterTime;
		fGameTime = get_gametime();
		UseAfterTime = 15 - floatround(fGameTime-g_PlayerSettings[id][f_last_show_song]);
		if(UseAfterTime >= 0)
		{
			Jukebox_Print(id, "Don't spam the command. You can use it again after!g %d!t second%s.", UseAfterTime, UseAfterTime == 1 ? "" : "s");
			return PLUGIN_HANDLED;
		}
		new aSongData[SongsInfo], szText[128], name[32], players[32], num, player;
		get_user_name(id, name, charsmax(name));
		ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][0], aSongData);
		formatex(szText, charsmax(szText), "!t%s!n's listening to !t%s!n.", name, aSongData[SongName]);
		get_players(players, num);
		for(new i=0;i<num;i++)
		{
			player = players[i];
			if(is_user_connected(player) && is_user_alive(id) == is_user_alive(player))
				Jukebox_Print(player, szText);
		}
		g_PlayerSettings[id][f_last_show_song] = _:fGameTime;
	}
	else
		Jukebox_Print(id, "You are not listening to a song now.");
	return PLUGIN_HANDLED;
}

public MainMenu(id)
{
	static szText[256], szTrackTime[64], aSongData[SongsInfo], szSong2Name[128];
	if(g_PlayerSettings[id][i_queue][1] >= 0)
	{
		ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][1], aSongData);
		copy(szSong2Name, charsmax(szSong2Name), aSongData[SongName]);
	}
	else
		formatex(szSong2Name, charsmax(szSong2Name), "N/A");
	if(g_PlayerSettings[id][i_queue][0] >= 0)
	{
		static gSongTime;
		ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][0], aSongData);
		gSongTime = aSongData[SongTime];
		if(g_PlayerSettings[id][b_on])
		{
			static secondsPassed, PercentTime;
			secondsPassed = floatround(get_gametime() - g_PlayerSettings[id][f_start_time]);
			PercentTime = floatround((float(secondsPassed)/float(gSongTime)) * 100.0);
			formatex(szTrackTime, charsmax(szTrackTime), "%d:%02d [%s] %d:%02d", (secondsPassed / 60), (secondsPassed % 60), g_szBar[PercentTime/5], (gSongTime / 60), (gSongTime % 60));
		}
		else
			formatex(szTrackTime, 63, "0.00 [\w%s\r] %d:%02d", g_szBar[0], (gSongTime / 60), (gSongTime % 60));
	}
	else
	{
		formatex(szTrackTime, 63, "0.00 [\w%s\r] 0.00", g_szBar[0]);
		formatex(aSongData[SongName], 127, "N/A");
	}
	formatex(szText, charsmax(szText), "\wCurrent Song: \r%s^n\wSong Time Line: \r%s^n\wNext Song: \r%s^n\wVolume: \r%d%s", aSongData[SongName], szTrackTime, szSong2Name, g_PlayerSettings[id][i_vol], "%");
	new menu = menu_create(szText, "main_menu_handler");
	formatex(szText, charsmax(szText), "%s", g_PlayerSettings[id][i_queue][0] < 0 ? "Play a song" : "Add a song to queue");
	menu_additem(menu, szText, "1", 0);
	menu_additem(menu, "Find a Song", "2", 0);
	formatex(szText, charsmax(szText), "%s%s Current Song", g_PlayerSettings[id][i_queue][0] >= 0 ? "\w" : "\d", !g_PlayerSettings[id][b_on] ? "Play" : "Stop");
	menu_additem(menu, szText, "3", 0);
	formatex(szText, charsmax(szText), "%sPlay Next Song", g_PlayerSettings[id][i_queue][1] >= 0 ? "\w" : "\d");
	menu_additem(menu, szText, "4", 0);
	menu_additem(menu, "Ajust Volume", "5", 0);
	formatex(szText, charsmax(szText), "Repeat Current Song \d[\r%s\d]", g_PlayerSettings[id][i_repeat] ? "Enabled" : "Disabled");
	menu_additem(menu, szText, "6", 0);
	menu_additem(menu, "Hud Message Settings", "7", 0);
	menu_additem(menu, "Request a song to be added", "8", 0);
	if(get_user_flags(id) & ADMIN_FLAG)
		menu_additem(menu, "Songs Settings^n", "9", 0);
	else
		menu_addblank(menu, 1);
	formatex(szText, charsmax(szText), "Exit");
	menu_additem(menu, szText, "0", 0);
	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(id, menu, 0);
	g_PlayerSettings[id][i_search_menu] = 0;
	return PLUGIN_HANDLED;
}

public main_menu_handler(id, menu, item)	
{
	new data[6], access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), _,_, callback);
	new key = str_to_num(data)

	menu_destroy(menu);
	switch(key)
	{
		case 0: return PLUGIN_HANDLED;
		case 1:
		{
			g_EditMode[id] = _mode_none;
			GenresMenu(id);
			return PLUGIN_CONTINUE;
		}
		case 2: client_cmd(id, "messagemode Find_Song");
		case 3:
		{
			if(!g_PlayerSettings[id][b_on])
			{
				if(g_PlayerSettings[id][i_queue][0] >= 0)
				{
					if(task_exists(id+TASK_ID))
						remove_task(id+TASK_ID)
					PlayCurrentSong(id);
				}
				else
					Jukebox_Print(id, "First choose a song to be played.");
			}
			else
				StopJukebox(id);
		}
		case 4:
		{
			if(g_PlayerSettings[id][i_queue][1] >= 0)
			{
				g_PlayerSettings[id][b_on] = true;
				if(task_exists(id+TASK_ID))
					remove_task(id+TASK_ID);
				if(g_PlayerSettings[id][i_repeat])
					g_PlayerSettings[id][i_repeat] = 2;
				SongEnd(id+TASK_ID);
			}
			else
				Jukebox_Print(id, "First put another song in queue.");
		}
		case 5:
		{
			VolumeMenu(id);
			return PLUGIN_CONTINUE;
		}
		case 6: g_PlayerSettings[id][i_repeat] = (g_PlayerSettings[id][i_repeat] ? 0 : 1);
		case 7:
		{
			HudSettingsMenu(id);
			return PLUGIN_CONTINUE;
		}
		case 8: client_cmd(id, "messagemode Type_The_Song");
		case 9:
		{
			SongsSettingsMenu(id);
			return PLUGIN_HANDLED
		}
	}
	MainMenu(id);
	return PLUGIN_HANDLED;
}

public SongsSettingsMenu(id)
{
	new menu = menu_create("Songs Settings:", "songsetings_menu_handler");
	menu_additem(menu, "Add Song", "1", 0);
	menu_additem(menu, "Remove Song", "2", 0);
	menu_additem(menu, "Edit Song", "3", 0);
	menu_setprop(menu, MPROP_EXITNAME, "Back to \rMain Menu");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public songsetings_menu_handler(id, menu, item)	
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		MainMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[6], access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), _,_, callback);
	new key = str_to_num(data);
	menu_destroy(menu);
	switch(key)
	{
		case 1:
		{
			g_EditMode[id] = _mode_add;
			AddSongMenu(id);
		}
		case 2:
		{
			g_EditMode[id] = _mode_remove;
			GenresMenu(id);
		}
		case 3:
		{
			g_EditMode[id] = _mode_edit;
			GenresMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}

AddSongMenu(id)
{
	static szText[256];
	new menu = menu_create("Add Song Menu:", "add_song_menu_handler");
	formatex(szText, charsmax(szText), "Song Name:^n\r%s", g_TempSettings[id][SongTempName]);
	menu_additem(menu, szText, "1", 0);
	formatex(szText, charsmax(szText), "Song Url:^n\r%s", g_TempSettings[id][SongTempUrl]);
	menu_additem(menu, szText, "2", 0);
	formatex(szText, charsmax(szText), "Song Genre:^n\r%s", g_TempSettings[id][SongTempGenre]);
	menu_additem(menu, szText, "3", 0);
	formatex(szText, charsmax(szText), "Song Time:^n\r%d \d(%d:%02d)^n", g_TempSettings[id][SongTempTime], (g_TempSettings[id][SongTempTime] / 60), (g_TempSettings[id][SongTempTime] % 60));
	menu_additem(menu, szText, "4", 0);
	menu_additem(menu, "\rAdd The Song", "5", 0);
	menu_setprop(menu, MPROP_EXITNAME, "Back to \rSong Settings Menu");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public add_song_menu_handler(id, menu, item)	
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		g_EditMode[id] = _mode_none;
		SongsSettingsMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[6], access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), _,_, callback);
	new key = str_to_num(data);
	menu_destroy(menu);
	switch(key)
	{
		case 1,2,3,4:
		{
			g_EditSetting[id] = key;
			client_cmd(id, "messagemode Type_Setting");
		}
		case 5:
		{
			if(!g_TempSettings[id][SongTempName][0])
				Jukebox_Print(id, "You need to put a song name first.");
			else if(!g_TempSettings[id][SongTempUrl][0])
				Jukebox_Print(id, "You need to put a song url first.");
			else if(!g_TempSettings[id][SongTempGenre][0])
				Jukebox_Print(id, "You need to put a song genre first.");
			else if(!g_TempSettings[id][SongTempTime])
				Jukebox_Print(id, "You need to put a song time first.");
			else if(strlen(g_TempSettings[id][SongTempName]) < 5)
				Jukebox_Print(id, "The song name must be 5 or more characters long.");
			else if(strlen(g_TempSettings[id][SongTempUrl]) < 5)
				Jukebox_Print(id, "The song url must be 5 or more characters long.");
			else
			{
				new aGenreData[GenresInfo], aSongData[SongsInfo], genres_num = ArraySize(g_aGenres), i;
				copy(aSongData[SongName], 63, g_TempSettings[id][SongTempName]);
				copy(aSongData[SongUrl], 63, g_TempSettings[id][SongTempUrl]);
				for(i=0;i<genres_num;i++)
				{
					ArrayGetArray(g_aGenres, i, aGenreData);
					if(equal(aGenreData[GenreName], g_TempSettings[id][SongTempGenre]))
					{
						aSongData[SongGenre] = i;
						aGenreData[GenreSongsNum]++;
						ArraySetArray(g_aGenres, i, aGenreData);
						break;
					}
				}
				if(i == genres_num)
				{
					aGenreData[GenreSongsNum] = 1;
					copy(aGenreData[GenreName], 63, g_TempSettings[id][SongTempGenre]);
					ArrayPushArray(g_aGenres, aGenreData);
					aSongData[SongGenre] = i;
					genres_num++;
				}
				aSongData[SongTime] = g_TempSettings[id][SongTempTime];
				ArrayPushArray(g_aSongs, aSongData);
				Jukebox_Print(id, "Successfully added the song !g%s!t.", g_TempSettings[id][SongTempName]);
				UpdateSongsFile(id);
				ResetTempSettings(id);
				g_EditMode[id] = _mode_none;
				SongsSettingsMenu(id);
				return PLUGIN_HANDLED;
			}
			AddSongMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}

EditSongMenu(id)
{
	static szText[256], aSongData[SongsInfo], aGenreData[GenresInfo];
	ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_menu_choice], aSongData);
	ArrayGetArray(g_aGenres, aSongData[SongGenre], aGenreData);
	new menu = menu_create("Edit Song Menu:", "edit_song_menu_handler");
	if(g_TempSettings[id][SongTempName][0])
		formatex(szText, charsmax(szText), "Song Name:^n\r%s", g_TempSettings[id][SongTempName]);
	else
		formatex(szText, charsmax(szText), "Song Name:^n\r%s", aSongData[SongName]);
	menu_additem(menu, szText, "1", 0);
	if(g_TempSettings[id][SongTempUrl][0])
		formatex(szText, charsmax(szText), "Song Url:^n\r%s", g_TempSettings[id][SongTempUrl]);
	else
		formatex(szText, charsmax(szText), "Song Url:^n\r%s", aSongData[SongUrl]);
	menu_additem(menu, szText, "2", 0);
	if(g_TempSettings[id][SongTempGenre][0])
		formatex(szText, charsmax(szText), "Song Genre:^n\r%s", g_TempSettings[id][SongTempGenre]);
	else
		formatex(szText, charsmax(szText), "Song Genre:^n\r%s", aGenreData[GenreName]);
	menu_additem(menu, szText, "3", 0);
	if(g_TempSettings[id][SongTempTime])
		formatex(szText, charsmax(szText), "Song Time:^n\r%d \d(%d:%02d)^n", g_TempSettings[id][SongTempTime], (g_TempSettings[id][SongTempTime] / 60), (g_TempSettings[id][SongTempTime] % 60));
	else
		formatex(szText, charsmax(szText), "Song Time:^n\r%d \d(%d:%02d)^n", aSongData[SongTime], (aSongData[SongTime] / 60), (aSongData[SongTime] % 60));
	menu_additem(menu, szText, "4", 0);
	menu_additem(menu, "\rConfurm Edit", "5", 0);
	menu_setprop(menu, MPROP_EXITNAME, "Back to \rSong Settings Menu");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public edit_song_menu_handler(id, menu, item)	
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		g_EditMode[id] = _mode_none;
		SongsSettingsMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[6], access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), _,_, callback);
	new key = str_to_num(data);
	menu_destroy(menu);
	switch(key)
	{
		case 1,2,3,4:
		{
			g_EditSetting[id] = key;
			client_cmd(id, "messagemode Type_Setting");
		}
		case 5:
		{
			if(!g_TempSettings[id][SongTempName][0] && !g_TempSettings[id][SongTempUrl][0] && !g_TempSettings[id][SongTempGenre][0] && !!g_TempSettings[id][SongTempTime])
			{
				Jukebox_Print(id, "No changes were made to the song.");
				ResetTempSettings(id);
				g_EditMode[id] = _mode_none;
				SongsSettingsMenu(id);
				return PLUGIN_HANDLED;
			}
			if(g_TempSettings[id][SongTempName][0] && strlen(g_TempSettings[id][SongTempName]) < 5)
				Jukebox_Print(id, "The song name must be 5 or more characters long.");
			else if(g_TempSettings[id][SongTempUrl][0] && strlen(g_TempSettings[id][SongTempUrl]) < 5)
				Jukebox_Print(id, "The song url must be 5 or more characters long.");
			else
			{
				new aGenreData[GenresInfo], aSongData[SongsInfo], i, genres_num = ArraySize(g_aGenres);
				ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_menu_choice], aSongData);
				ArrayGetArray(g_aGenres, aSongData[SongGenre], aGenreData);
				if(g_TempSettings[id][SongTempGenre][0] && !equal(aSongData[SongGenre], g_TempSettings[id][SongTempGenre]))
				{
					if(aGenreData[GenreSongsNum] < 2)
					{
						ArrayDeleteItem(g_aGenres, aSongData[SongGenre]);
						genres_num--;
					}
					else
					{
						aGenreData[GenreSongsNum]--;
						ArraySetArray(g_aGenres, aSongData[SongGenre], aGenreData);
					}
					for(i=0;i<genres_num;i++)
					{
						ArrayGetArray(g_aGenres, i, aGenreData);
						if(equal(aGenreData[GenreName], g_TempSettings[id][SongTempGenre]))
						{
							aSongData[SongGenre] = i;
							aGenreData[GenreSongsNum]++;
							ArraySetArray(g_aGenres, i, aGenreData);
							break;
						}
					}
					if(i == genres_num)
					{
						aGenreData[GenreSongsNum] = 1;
						copy(aGenreData[GenreName], 63, g_TempSettings[id][SongTempGenre]);
						ArrayPushArray(g_aGenres, aGenreData);
						aSongData[SongGenre] = i;
						genres_num++;
					}
				}
				if(g_TempSettings[id][SongTempName][0])
					copy(aSongData[SongName], 63, g_TempSettings[id][SongTempName]);
				if(g_TempSettings[id][SongTempUrl][0])
					copy(aSongData[SongUrl], 63, g_TempSettings[id][SongTempUrl]);
				if(g_TempSettings[id][SongTempTime])
					aSongData[SongTime] = g_TempSettings[id][SongTempTime];
				ArraySetArray(g_aSongs, g_PlayerSettings[id][i_menu_choice], aSongData);
				Jukebox_Print(id, "Successfully edited the song !g%s!t.", g_TempSettings[id][SongTempName]);
				UpdateSongsFile(id);
				ResetTempSettings(id);
				g_EditMode[id] = _mode_none;
				SongsSettingsMenu(id);
				return PLUGIN_HANDLED;
			}
			EditSongMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}

ResetTempSettings(id)
{
	copy(g_TempSettings[id][SongTempName], 127, "");
	copy(g_TempSettings[id][SongTempUrl], 255, "");
	copy(g_TempSettings[id][SongTempGenre], 63, "");
	g_TempSettings[id][SongTempTime] = 0;
}

RemoveSongConfurm(id)
{
	static szText[256], aSongData[SongsInfo];
	ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_menu_choice], aSongData);
	formatex(szText, charsmax(szText), "Are you sure u want to delete the song^n\r%s\w?^n", aSongData[SongName]);
	new menu = menu_create(szText, "del_confurm_song_menu_handler");
	menu_additem(menu, "\rYes, delete the song.", "1", 0);
	menu_additem(menu, "No, don't delete the song.", "0", 0);
	menu_setprop(menu, MPROP_EXITNAME, "Back to \rSongs Menu");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public del_confurm_song_menu_handler(id, menu, item)	
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		AddSongToQueueMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[6], access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), _,_, callback);
	menu_destroy(menu);
	if(str_to_num(data))
	{
		new aGenreData[GenresInfo], aSongData[SongsInfo], genres_num = ArraySize(g_aGenres);
		ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_menu_choice], aSongData);
		ArrayGetArray(g_aGenres, aSongData[SongGenre], aGenreData);
		if(aGenreData[GenreSongsNum] < 2)
		{
			ArrayDeleteItem(g_aGenres, aSongData[SongGenre]);
			genres_num--;
		}
		else
		{
			aGenreData[GenreSongsNum]--;
			ArraySetArray(g_aGenres, aSongData[SongGenre], aGenreData);
		}
		ArrayDeleteItem(g_aSongs, g_PlayerSettings[id][i_menu_choice]);
		Jukebox_Print(id, "Successfully deleted the song !g%s!t.", _:aSongData[SongName]);
		UpdateSongsFile(id);
		ResetTempSettings(id);
		g_EditMode[id] = _mode_none;
		SongsSettingsMenu(id);
	}
	else
		AddSongToQueueMenu(id);
	return PLUGIN_HANDLED;
}

public SongEditSetting(id)
{
	if(!g_EditMode[id] || !g_EditSetting[id])
		return PLUGIN_HANDLED;
	new szArg[256];
	read_argv(1, szArg, charsmax(szArg));
	switch(g_EditSetting[id])
	{
		case 1: copy(g_TempSettings[id][SongTempName], 127, szArg);
		case 2: copy(g_TempSettings[id][SongTempUrl], 255, szArg);
		case 3: copy(g_TempSettings[id][SongTempGenre], 63, szArg);
		case 4: g_TempSettings[id][SongTempTime] = str_to_num(szArg);
	}
	if(g_EditMode[id] == _mode_add)
		AddSongMenu(id);
	else if(g_EditMode[id] == _mode_edit)
		EditSongMenu(id);
	return PLUGIN_HANDLED;
}

public DeleteRequests(id)
{
	if(!(get_user_flags(id) & ADMIN_FLAG))
	{
		client_print(id, print_console, "You don't have the flags to delete the requests.");
		return PLUGIN_HANDLED;
	}
	if(!file_exists(iRequestsFile))
	{
		client_print(id, print_console, "File with requests does not exist.");
		return PLUGIN_HANDLED;
	}
	delete_file(iRequestsFile);
	client_print(id, print_console, "File deleted successfully");
	return PLUGIN_HANDLED;
}

public ViewRequests(id)
{
	if(!(get_user_flags(id) & ADMIN_FLAG))
	{
		client_print(id, print_console, "You don't have the flags to view the requests.");
		return PLUGIN_HANDLED;
	}
	if(!file_exists(iRequestsFile))
	{
		client_print(id, print_console, "File with requests does not exist.");
		return PLUGIN_HANDLED;
	}
	new szData[512], f;
	client_print(id, print_console, "---------- Song Requests ----------");
	f = fopen(iRequestsFile, "rt");
	while(!feof(f))
	{
		fgets(f, szData, charsmax(szData))
		trim(szData);
		client_print(id, print_console, szData)
	}
	fclose(f);
	return PLUGIN_HANDLED;
}

public SearchForSong(id)
{
	new gSong[32];
	read_argv(1, gSong, 31);
	trim(gSong);
	if(strlen(gSong) < 2)
	{
		Jukebox_Print(id, "You can't search with less than 2 symbols.");
		return PLUGIN_HANDLED;
	}
	static szMenu[64], i_str[6], bool:found, aSongData[SongsInfo];
	found = false;
	formatex(szMenu, 63, "Search results for: \r%s", gSong);
	new menu = menu_create(szMenu,"search_menu_handler");
	for(new i=0;i<ArraySize(g_aSongs);i++)
	{
		ArrayGetArray(g_aSongs, i, aSongData);
		if(containi(aSongData[SongName], gSong) >= 0)
		{
			num_to_str(i, i_str, 5);
			menu_additem(menu, aSongData[SongName], i_str);
			if(!found)
				found = true;
		}
	}
	if(!found)
		Jukebox_Print(id, "No song found.");
	else
	{
		menu_setprop(menu, MPROP_EXITNAME, "Back to \rMain Menu");
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
		menu_display(id, menu, 0);
		g_PlayerSettings[id][i_search_menu] = menu;
	}
	return PLUGIN_CONTINUE;
}

public search_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		MainMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[32], access, callback;
	menu_item_getinfo(menu, item, access, data,31, _,_, callback);
	g_PlayerSettings[id][i_menu_choice] = str_to_num(data);
	ShowSongOptionsMenu(id);
	return PLUGIN_HANDLED;
}

public ShowSongOptionsMenu(id)
{
	static szText[256], song, aGenreData[GenresInfo], aSongData[SongsInfo];
	song = g_PlayerSettings[id][i_menu_choice];
	ArrayGetArray(g_aSongs, song, aSongData);
	ArrayGetArray(g_aGenres, aSongData[SongGenre], aGenreData);
	formatex(szText, charsmax(szText), "\wSong: \r%s^n\wSong Time: \r%d:%02d^n\wGenre: \r%s^n^n", aSongData[SongName], (aSongData[SongTime] / 60), (aSongData[SongTime] % 60), aGenreData[GenreName]);
	new menu = menu_create(szText, "song_options_menu_handler");
	formatex(szText, charsmax(szText), "\wPlay Now%s", g_PlayerSettings[id][i_queue][0] >= 0 ? " \d(replace with current playing song)" : "");
	menu_additem(menu, szText, "0", 0);
	if(g_PlayerSettings[id][i_queue][0] >= 0)
	{
		formatex(szText, charsmax(szText), "%sAdd Song To Queue", (g_PlayerSettings[id][i_queue][MAX_SONGS_IN_QUEUE-1] >= 0) ? "\d" : "\w");
		menu_additem(menu, szText, "1", 0);
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public song_options_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		if(g_PlayerSettings[id][i_search_menu])
			menu_display(id, g_PlayerSettings[id][i_search_menu], 0);
		else
			AddSongToQueueMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[6], access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), _,_, callback);
	menu_destroy(menu);
	if(!str_to_num(data))
	{
		if(task_exists(id+TASK_ID))
			remove_task(id+TASK_ID);
		g_PlayerSettings[id][i_queue][0] = g_PlayerSettings[id][i_menu_choice];
		PlayCurrentSong(id);
	}
	else
	{
		if(g_PlayerSettings[id][i_queue][MAX_SONGS_IN_QUEUE-1] >= 0)
		{
			if(g_PlayerSettings[id][b_on])
			{
				new aSongData[SongsInfo];
				ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][0], aSongData);
				new Float:Time = float(aSongData[SongTime] + 1) - (get_gametime() - g_PlayerSettings[id][f_start_time]);
				Jukebox_Print(id, "Queue is full. Wait !g%d!t more seconds for the current song to end or just skip it.", floatround(Time))
			}
			else
				Jukebox_Print(id, "Queue is full. You can skip the current song to free space for another.");
		}
		else
		{
			if(g_PlayerSettings[id][i_queue][0] < 0)
			{
				g_PlayerSettings[id][i_queue][0] = g_PlayerSettings[id][i_menu_choice];
				PlayCurrentSong(id);
			}
			else
			{
				for(new i=0;i<MAX_SONGS_IN_QUEUE;i++)
				{
					if(g_PlayerSettings[id][i_queue][i] < 0)
					{
						g_PlayerSettings[id][i_queue][i] = g_PlayerSettings[id][i_menu_choice];
						break;
					}
				}
			}
		}
	}
	ShowSongOptionsMenu(id);
	return PLUGIN_HANDLED;
}

public Request_Song(id)
{
	new g_szSong[64], g_szName[32], g_szAuthID[32], szData[512], iFIle, bool:suggested = false;
	get_user_name(id, g_szName, charsmax(g_szName));
	get_user_authid(id, g_szAuthID, charsmax(g_szAuthID));
	if(file_exists(iRequestsFile))
	{
		iFIle = fopen(iRequestsFile, "rt");
		while(!feof(iFIle))
		{
			fgets(iFIle, szData, charsmax(szData))
			if(!szData[0] || szData[0] == ';' || szData[0] == ' ' || ( szData[0] == '/' && szData[1] == '/' ))
				continue;
			if(containi(szData, g_szAuthID) == -1)
				continue;
			suggested = true;
			break;
		}
		fclose(iFIle);
		if(suggested)
		{
			Jukebox_Print(id, "You can't request more than 1 song. Wait for it to be viewed and removed.");
			return PLUGIN_HANDLED;
		}
	}
	read_argv(1, g_szSong, 63);
	if(strlen(g_szSong) < 5)
	{
		Jukebox_Print(id, "Your request has to have 5 or more symbols in it.")
		return PLUGIN_HANDLED;
	}
	iFIle = fopen(iRequestsFile, "at");
	formatex(szData, charsmax(szData), "^n%s(%s) requested %s", g_szName, g_szAuthID, g_szSong)
	fputs(iFIle, szData);
	fclose(iFIle);
	Jukebox_Print(id, "Song request was send.");
	return PLUGIN_CONTINUE;
}

public Hud_Setting(id)
{
	new arg[32], string[3][12];
	read_argv(1, arg, 31);
	parse(arg, string[0],11, string[1],11, string[2],11);
	new temp_num[3];
	temp_num[0] = str_to_num(string[0]);
	temp_num[1] = str_to_num(string[1]);
	temp_num[2] = str_to_num(string[2]);
	if(0 <= temp_num[0] <= 255 && 0 <= temp_num[1] <= 255 && 0 <= temp_num[2] <= 255)
	{
		if(temp_num[0] < 20 && temp_num[1] < 20 && temp_num[2] < 20)
			Jukebox_Print(id, "If the 3 numbers are all less than !g20!t hud will be invisible. Try another color.");
		else
		{
			g_PlayerSettings[id][i_hud_color][0] = temp_num[0];
			g_PlayerSettings[id][i_hud_color][1] = temp_num[1];
			g_PlayerSettings[id][i_hud_color][2] = temp_num[2];
			Jukebox_Print(id, "Changed hud color to !g%d %d %d!t.", temp_num[0], temp_num[1], temp_num[2]);
		}
	}
	else
		Jukebox_Print(id, "You need to type 3 numbers from !g0!t to !g255!t.");
	HudSettingsMenu(id);
	return PLUGIN_HANDLED;
}

public HudSettingsMenu(id)
{
	new menu = menu_create("\rHud Settings:", "hudsettings_menu_handler");
	new szText[64];
	formatex(szText, 63, "%s Hud", g_PlayerSettings[id][b_hud] ? "Hide" : "Show");
	menu_additem(menu, szText, "1");
	formatex(szText, 63, "Change Hud Colors [\r%d %d %d\w]", g_PlayerSettings[id][i_hud_color][0], g_PlayerSettings[id][i_hud_color][1], g_PlayerSettings[id][i_hud_color][2]);
	menu_additem(menu, szText, "2");
	formatex(szText, 63, "Move Hud Up");
	menu_additem(menu, szText, "3");
	formatex(szText, 63, "Move Hud Down");
	menu_additem(menu, szText, "4");
	formatex(szText, 63, "Move Hud Left");
	menu_additem(menu, szText, "5");
	formatex(szText, 63, "Move Hud Right");
	menu_additem(menu, szText, "6");
	formatex(szText, 63, "Center The Hud");
	menu_additem(menu, szText, "7");
	menu_setprop(menu, MPROP_EXITNAME, "Back to \rMain Menu");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
}

public hudsettings_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		MainMenu(id);
		return PLUGIN_HANDLED;
	}

	new data[64],name[64], access,callback
	menu_item_getinfo(menu, item, access, data,63, name, 63, callback)
	new key = str_to_num(data)

	menu_destroy(menu)
	switch(key)
	{
		case 1:
		{
			if(g_PlayerSettings[id][b_hud])
				g_PlayerSettings[id][b_hud] = false;
			else
				g_PlayerSettings[id][b_hud] = true;
		}
		case 2:
		{
			client_cmd(id, "messagemode Type_Hud_Setting");
			return PLUGIN_CONTINUE;
		}
		case 3:
		{
			if(g_PlayerSettings[id][f_hud_pos][1] == -1.0)
				g_PlayerSettings[id][f_hud_pos][1] = _:0.49
			else if(g_PlayerSettings[id][f_hud_pos][1] > 0.0)
				g_PlayerSettings[id][f_hud_pos][1] -= 0.01
		}
		case 4:
		{
			if(g_PlayerSettings[id][f_hud_pos][1] == -1.0)
				g_PlayerSettings[id][f_hud_pos][1] = _:0.51
			else if(g_PlayerSettings[id][f_hud_pos][1] < 1.0)
				g_PlayerSettings[id][f_hud_pos][1] += 0.01
		}
		case 5:
		{
			if(g_PlayerSettings[id][f_hud_pos][0] == -1.0)
				g_PlayerSettings[id][f_hud_pos][0] = _:0.49
			else if(g_PlayerSettings[id][f_hud_pos][0] > 0.0)
				g_PlayerSettings[id][f_hud_pos][0] -= 0.01
		}
		case 6:
		{
			if(g_PlayerSettings[id][f_hud_pos][0] == -1.0)
				g_PlayerSettings[id][f_hud_pos][0] = _:0.51
			else if(g_PlayerSettings[id][f_hud_pos][0] < 1.0)
				g_PlayerSettings[id][f_hud_pos][0] += 0.01
		}
		case 7:
		{
			g_PlayerSettings[id][f_hud_pos][0] = _:-1.0
			g_PlayerSettings[id][f_hud_pos][1] = _:-1.0
		}
	}
	HudSettingsMenu(id);
	return PLUGIN_HANDLED;
}

public GenresMenu(id)
{
	if(!ArraySize(g_aSongs))
	{
		Jukebox_Print(id, "There are no songs currently added.");
		MainMenu(id);
		return PLUGIN_HANDLED:
	}
	static menu, i_str[6], i, szText[64], aGenreData[GenresInfo], aSongData[SongsInfo];
	if(g_EditMode[id] == _mode_remove)
		formatex(szText, charsmax(szText), "\rREMOVE MODE ACTIVE^n\wChoose Genre:");
	else if(g_EditMode[id] == _mode_edit)
		formatex(szText, charsmax(szText), "\rEDIT MODE ACTIVE^n\wChoose Genre:");
	else
		formatex(szText, charsmax(szText), "Choose Genre:");
	menu = menu_create(szText, "genres_menu_handler");
	for(i=0;i<ArraySize(g_aGenres);i++)
	{
		ArrayGetArray(g_aGenres, i, aGenreData);
		num_to_str(i+1000, i_str, 5);
		formatex(szText, 63, "%s \d- \r%d songs", aGenreData[GenreName], aGenreData[GenreSongsNum])
		menu_additem(menu, szText, i_str);
	}
	for(i=0;i<ArraySize(g_aSongs);i++)
	{
		ArrayGetArray(g_aSongs, i, aSongData);
		if(aSongData[SongGenre] == -1)
		{
			num_to_str(i, i_str, 5);
			menu_additem(menu, aSongData[SongName], i_str);
		}
	}
	menu_setprop(menu, MPROP_EXITNAME, "Back to \rMain Menu");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public genres_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		MainMenu(id)
		return PLUGIN_HANDLED
	}
	new data[64], access,callback
	menu_item_getinfo(menu, item, access, data,63, _,_, callback)
	new iSongNum = str_to_num(data);

	if(iSongNum-1000 >= 0)
	{
		g_PlayerSettings[id][i_genre] = iSongNum - 1000;
		menu_destroy(menu);
		AddSongToQueueMenu(id);
		return PLUGIN_HANDLED;
	}

	if(g_PlayerSettings[id][i_queue][0] < 0)
	{
		g_PlayerSettings[id][i_queue][0] = iSongNum;
		PlayCurrentSong(id);
	}
	else
	{
		for(new i=0;i<MAX_SONGS_IN_QUEUE;i++)
		{
			if(g_PlayerSettings[id][i_queue][i] < 0)
			{
				g_PlayerSettings[id][i_queue][i] = iSongNum;
				break;
			}
		}
	}
	menu_destroy(menu);
	GenresMenu(id);
	return PLUGIN_HANDLED;
}

public AddSongToQueueMenu(id)
{
	static menu, i_str[6], szText[64], i, aSongData[SongsInfo];
	if(g_EditMode[id] == _mode_remove)
		formatex(szText, charsmax(szText), "\rREMOVE MODE ACTIVE^n\wChoose Song:");
	else if(g_EditMode[id] == _mode_edit)
		formatex(szText, charsmax(szText), "\rEDIT MODE ACTIVE^n\wChoose Song:");
	else
		formatex(szText, charsmax(szText), "Choose Song:");
	menu = menu_create(szText, "songs_menu_handler")
	for(i=ArraySize(g_aSongs) - 1;i >= 0;i--)
	{
		ArrayGetArray(g_aSongs, i, aSongData);
		if(aSongData[SongGenre] == g_PlayerSettings[id][i_genre])
		{
			num_to_str(i, i_str, 5);
			menu_additem(menu, aSongData[SongName], i_str);
		}
	}
	menu_setprop(menu, MPROP_EXITNAME, "Back to \rGenres Menu");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED;
}

public songs_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		GenresMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[64], access,callback
	menu_item_getinfo(menu, item, access, data,63, _,_, callback)
	g_PlayerSettings[id][i_menu_choice] = str_to_num(data);
	if(g_EditMode[id] == _mode_remove)
		RemoveSongConfurm(id);
	else if(g_EditMode[id] == _mode_edit)
		EditSongMenu(id);
	else
		ShowSongOptionsMenu(id);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public VolumeMenu(id)	menu_display(id, iVolumeMenu, 0);

public volumemenu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_cancel(id);
		MainMenu(id);
		return PLUGIN_HANDLED;
	}
	new data[6], access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), _,_, callback);
	g_PlayerSettings[id][i_vol] = str_to_num(data);
	menu_cancel(id);
	MainMenu(id);
	if(g_PlayerSettings[id][b_on] && g_PlayerSettings[id][i_queue][0] >= 0)
		PlayCurrentSong(id);
	return PLUGIN_HANDLED;
}

public message() Jukebox_Print(0, "Type !g/jukebox !tto open the jukebox main menu.");

stock PlayCurrentSong(id)
{
	static aSongData[SongsInfo];
	ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][0], aSongData);
	set_task(float(aSongData[SongTime]), "SongEnd", id+TASK_ID)
	g_PlayerSettings[id][f_start_time] = _:get_gametime();
	static szMotd[2048], n;
	n = formatex(szMotd, charsmax(szMotd), "<html><head><meta http-equiv=^"content-type^" content=^"text/html; charset=UTF-8^"></head>");
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<body bgcolor=^"#000000^"><center><font color=^"#FFB000^" size=^"4^">Now listening to:<br/><b>%s</b></font><br><hr>", aSongData[SongName]);
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<object classid=CLSID:6BF52A52-394A-11d3-B153-00C04F79FAA6 codebase=http://www.microsoft.com/ntserver/netshow/download/en/nsmp2inf.cab#Version=5,1,51,415 type=application/x-oleobject name=msplayer width=256 height=65 align=^"middle^" id=msplayer>");
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<param name=^"enableContextMenu^" value=^"0^"><param name=^"stretchToFit^" value=^"1^">");
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<param name=^"AutoRewind^" value=^"0^">");
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<param name=^"Volume^" value=^"%d^">", g_PlayerSettings[id][i_vol]);
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<param name=^"AutoStart^" value=^"1^"><param name=^"URL^" value=^"%s^">", aSongData[SongUrl]);
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<param name=^"uiMode^" value=^"full^"><param name=^"width^" value=^"256^"><param name=^"height^" value=^"65^">");
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<param name=^"TransparentAtStart^" value=^"1^"></object><hr/><br/><br/>");
	n += formatex(szMotd[n], charsmax(szMotd)-n, "<font color=^"#FFB000^" size=^"2^">Songs in Queue:<br/>");
	for(new i=1;i<MAX_SONGS_IN_QUEUE;i++)
	{
		if(g_PlayerSettings[id][i_queue][i] >= 0)
		{
			ArrayGetArray(g_aSongs, g_PlayerSettings[id][i_queue][i], aSongData);
			n += formatex(szMotd[n], charsmax(szMotd)-n, "%d. %s<br/>", i+1, aSongData[SongName]);
		}
		else
			n += formatex(szMotd[n], charsmax(szMotd)-n, "%d. N/A<br/>", i+1);
	}
	n += formatex(szMotd[n], charsmax(szMotd)-n, "</font></center></body></html>");
	g_PlayerSettings[id][b_on] = true;
	show_motd(id, szMotd, "Jukebox");
}

public StopJukebox(id)
{
	if(task_exists(id+TASK_ID))
		remove_task(id+TASK_ID)
	g_PlayerSettings[id][b_on] = false;
	show_motd(id, "<html><head><meta http-equiv=^"content-type^" content=^"text/html; charset=UTF-8^"></head><body bgcolor=^"#000000^" align=^"center^"><center><span style=^"color: #FFB000; font-size: 19pt^">Jukebox stopped.</span></center></body></html>", "Stop Jukebox");
}

public cmdSay(id)
{
	static args[32];
	read_args(args, charsmax(args));
	remove_quotes(args);
	trim(args);
	if(!args[0] || args[0] == ' ')
		return;
	if(args[0] == '/')
	{
		if(equal(args, "/jukebox") || equal(args, "/music") || equal(args, "/mp3"))	MainMenu(id);
		else if(equal(args, "/play"))	cmdPlaySong(id);
		else if(equal(args, "/stop"))	StopJukebox(id);
		else if(equal(args, "/next"))	cmdPlayNextSong(id);
		else if(equal(args, "/showsong"))	cmdShowSongName(id);
		else if(equal(args, "/replay"))	cmdReplay(id);
	}
	else
	{
		if(equal(args, "jukebox") || equal(args, "music") || equal(args, "mp3"))	MainMenu(id);
		else if(equal(args, "play"))	cmdPlaySong(id);
		else if(equal(args, "stop"))	StopJukebox(id);
		else if(equal(args, "next"))	cmdPlayNextSong(id);
		else if(equal(args, "showsong"))	cmdShowSongName(id);
		else if(equal(args, "replay"))	cmdReplay(id);
	}
}

Jukebox_Print(id, const szText[], any:...)
{
	static szNewText[192], iPlayers[32], iNum;
	formatex(szNewText, charsmax(szNewText), "!g[%s]!t %s", PREFIX, szText);
	replace_all(szNewText, charsmax(szNewText), "!g", "^x04");
	replace_all(szNewText, charsmax(szNewText), "!t", "^x03");
	replace_all(szNewText, charsmax(szNewText), "!n", "^x01");
	if(!id)
	{
		get_players(iPlayers, iNum);
		if(iNum > 0)
			MakeSayText(iPlayers[0], MSG_ALL, szNewText);
	}
	else if(is_user_connected(id))
		MakeSayText(id, MSG_ONE, szNewText);
}

MakeSayText(id, msgtype, const szText[])
{
	message_begin(msgtype, g_MsgSayText, _, id);
	write_byte(id);
	write_string(szText);
	message_end();
}