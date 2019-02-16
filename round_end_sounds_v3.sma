#include <amxmodx>

#define PLUGIN "Round End Sounds V3"
#define VERSION "3.0"
#define AUTHOR "DeRoiD"

#define Prefix "!g[Budapest-Intl]"
#define File "addons/amxmodx/configs/musiclist.ini"

#pragma semicolon 1

new MusicData[40][3][64], Mp3File[96], MusicNum, PreviousMusic = -1, bool:Off[33], MaxFileLine;
new SayText, Ad;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("round_end_sounds_v3.txt");
	
	register_clcmd("say /music", "Toggle");
	//register_clcmd("say /musiclist", "MusicList");
	SayText = get_user_msgid("SayText");
	
	//set_task(78.9, "Advertising", 789, _, _, "b");
	
	register_logevent("PlayMusic", 2, "1=Round_End");
	LoadMusic();
}
public Advertising()
{
	new Players[32], PlayersNum, id;
	get_players(Players, PlayersNum, "c");
	for(new i; i < PlayersNum; i++)
	{
		id = Players[i];
		new Message[256];
		if(Ad == 0)
		{
			formatex(Message, 255, "%s %L", Prefix, LANG_SERVER, "ADVERTISING_1");
			Ad = 1;
		}
		else if(Ad == 1)
		{
			formatex(Message, 255, "%s %L", Prefix, LANG_SERVER, "ADVERTISING_2");
			Ad = 0;
		}
		SendMessage(id, Message);
	}
}
public MusicList(id)
{
	new Motd[1024], Line[256];
	formatex(Line, 255, "<body bgcolor=^"black^">^n");
	add(Motd, 1023, Line, 255);
	formatex(Line, 255, "<span style=^"color:#FFA500;^">^n");
	add(Motd, 1023, Line, 255);
	
	if(MusicNum > 0)
	{
		for(new Num = 1; Num < MusicNum; Num++)
		{
			formatex(Line, 255, "<span style=^"color:#00FFFF;^">^n");
			add(Motd, 1023, Line, 255);
			formatex(Line, 255, "<p align=^"center^"><span style=^"font-size: 15px;^"><strong>%s - %s</strong></span></p>^n", MusicData[Num][0], MusicData[Num][1]);
			add(Motd, 1023, Line, 255);
		}
	}
	formatex(Line, 255, "</span>^n</body>");
	add(Motd, 1023, Line, 255);
	show_motd(id, Motd, "Music List");
}
public Toggle(id)
{
	new Message[256] ;
	if(Off[id])
	{
		formatex(Message, 255, "%s!y %L", Prefix, LANG_SERVER, "ON");
		SendMessage(id, Message);
		Off[id] = false;
	}
	else
	{
		client_cmd(id, "mp3 stop");
		formatex(Message, 255, "%s!y %L", Prefix, LANG_SERVER, "OFF");
		SendMessage(id, Message);
		Off[id] = true;
	}
}
public LoadMusic()
{
	new Len, Line[196], Data[3][64];
	MaxFileLine = file_size(File, 1);
	for(new Num; Num < MaxFileLine; Num++)
	{
		MusicNum++;
		read_file(File, Num, Line, 196, Len);
		parse(Line, Data[0], 63, Data[1], 63, Data[2], 63);
		remove_quotes(Line);
		if(Line[0] == ';' || 2 > strlen(Line))
		{
			continue;
		}
		remove_quotes(Data[0]);
		remove_quotes(Data[1]);
		remove_quotes(Data[2]);
		format(MusicData[MusicNum][0], 63, "%s", Data[0]);
		format(MusicData[MusicNum][1], 63, "%s", Data[1]);
		format(MusicData[MusicNum][2], 63, "%s", Data[2]);
	}
	log_amx("Round end sounds v3");
	log_amx("%d loaded music.", MusicNum);
	log_amx("Plugin by: DeRoiD");
}
public PlayMusic() {
	new Num = random_num(1, MusicNum);
	if(MusicNum > 1)
	{
		if(Num == PreviousMusic)
		{
			PlayMusic();
			return PLUGIN_HANDLED;
		}
	}
	formatex(Mp3File, charsmax(Mp3File), "sound/%s", MusicData[Num][2]);
	new Players[32], PlayersNum, id;
	get_players(Players, PlayersNum, "c");
	for(new i; i < PlayersNum; i++)
	{
		id = Players[i];
		if(Off[id])
		{
			continue;
		}
		client_cmd(id, "mp3 play %s", Mp3File);
		new Message[256] ;
		if(strlen(MusicData[Num][0]) > 1 && strlen(MusicData[Num][1]) > 1)
		{
			formatex(Message, 255, "%s!y %L", Prefix, LANG_SERVER, "PLAY", MusicData[Num][0], MusicData[Num][1]);
		}
		else
		{
			formatex(Message, 255, "%s!y %L", Prefix, LANG_SERVER, "UNKNOWN");
		}
		SendMessage(id, Message);
	}
	PreviousMusic = Num;
	return PLUGIN_HANDLED;
}
public plugin_precache() {
	new Len, Line[196], Data[3][64], Download[40][64];
	MaxFileLine = file_size(File, 1);
	for(new Num = 0; Num < MaxFileLine; Num++)
	{
		read_file(File, Num, Line, 196, Len);
		parse(Line, Data[0], 63, Data[1], 63, Data[2], 63);
		remove_quotes(Line);
		if(Line[0] == ';' || 2 > strlen(Line))
		{
			continue;
		}
		remove_quotes(Data[2]);
		format(Download[Num], 63, "sound/%s", Data[2]);
		precache_generic(Download[Num]);
	}
}
stock SendMessage(id, const MessageData[]) {
	static Message[256];
	vformat(Message, 255, MessageData, 3);
	replace_all(Message, 255, "!g", "^4");
	replace_all(Message, 255, "!y", "^1");
	replace_all(Message, 255, "!t", "^3");
	message_begin(MSG_ONE_UNRELIABLE, SayText, _, id);
	write_byte(id);
	write_string(Message);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1038\\ f0\\ fs16 \n\\ par }
*/
