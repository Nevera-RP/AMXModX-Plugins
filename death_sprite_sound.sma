#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>

enum PluginInfo {
	piAutor[128],
	piWersja[128],
	piNazwa[128]
};
new gPluginInfo[PluginInfo] = {
	"MisieQ",
	"1.1",
	"Death Sprite & Sound"
};

enum Sprites {
	sZwykeZabicie,
	sWiecejOdOsiem,
	sKnifeKill,
	sHeadShot,
	sGrenadeKill,
	sOsiem,
	sSiedem,
	sSzesc,
	sPiec,
	sCztery,
	sTrzy,
	sDwa,
	sJeden	
};
enum SpritesData {sdModel[128], sdPointer}  
stock const gPluginSprites[Sprites][SpritesData] = {
	{ "sprites/DSS/normal_kill.spr", 0},
	{ "sprites/DSS/more_than_8_kill.spr", 0},
	{ "sprites/DSS/knife_kill.spr", 0},
	{ "sprites/DSS/headshot.spr", 0},
	{ "sprites/DSS/grenade_kill.spr", 0},
	{ "sprites/DSS/8_kill.spr", 0},
	{ "sprites/DSS/7_kill.spr", 0},
	{ "sprites/DSS/6_kill.spr", 0},
	{ "sprites/DSS/5_kill.spr", 0},
	{ "sprites/DSS/4_kill.spr", 0},
	{ "sprites/DSS/3_kill.spr", 0},
	{ "sprites/DSS/2_kill.spr", 0},
	{ "sprites/DSS/1_kill.spr", 0}
};

enum PluginSounds {
	psUnstoppable,
	psLastKill,
	psKnifeKill,
	psHeadShot,
	psGrenadeKill,
	psFirstBlood,
	ps8,
	ps7,
	ps6,
	ps5,
	ps4,
	ps3,
	ps2,
	ps1
};

stock const gPluginSounds[PluginSounds][128] = {
	"DSS/unstoppable.wav",
	"DSS/last_kill.wav",
	"DSS/knife_kill.wav",
	"DSS/headshot.wav",
	"DSS/grenade_kill.wav",
	"DSS/firstblood.wav",
	"DSS/8_kill.wav",
	"DSS/7_kill.wav",
	"DSS/6_kill.wav",
	"DSS/5_kill.wav",
	"DSS/4_kill.wav",
	"DSS/3_kill.wav",
	"DSS/2_kill.wav",
	"DSS/1_kill.wav"
};

enum Kill {
	Jedno,
	Dwa,
	Trzy,
	Cztery,
	Piec,
	Szesc,
	Siedem,
	Osiem,
	WiecejOdOsiem,
	OstatnieZabicie,
	PierwszeZabicie,
	Nozem,
	Granatem,
	HeadShotem,
	Zwykle
};
new gKill[Kill];

enum _:cvar { DZWIEK };
new gPcvar[cvar];

new gPoziom[32];
new bool:Zabicie[32];
new bool:Dzwiek;

public plugin_init() {
	register_plugin(gPluginInfo[piNazwa], gPluginInfo[piWersja], gPluginInfo[piAutor]);
	
	register_logevent("LogEvent_Round_Start", 2, "0=World triggered", "1=Round_Start");
	
	register_event("DeathMsg", "Event_DeathMsg", "a");
	
	gPcvar[DZWIEK] = register_cvar("dss_sound", "1");
	
	register_dictionary("dss.txt");
	
	register_cvar("dss_version", gPluginInfo[piWersja], FCVAR_SERVER | FCVAR_SPONLY);
	set_cvar_string("dss_version", gPluginInfo[piWersja]);
}

public plugin_precache() {
	for(new i = 0; i < sizeof(gPluginSprites); i++) {
		gPluginSprites[Sprites: i][sdPointer] = precache_model(gPluginSprites[Sprites: i][sdModel]); 
	}
	for(new i = 0; i < sizeof(gPluginSounds); i++) {
		precache_sound(gPluginSounds[PluginSounds: i]);
	}
}

public client_disconnect(id) {
	gPoziom[id] = 0;
}

public client_putinserver(id) {
	gPoziom[id] = 0;
}

public LogEvent_Round_Start() {
	gKill[PierwszeZabicie] = 1;
}

public Event_DeathMsg() {
	new attacker = read_data(1);
	new victim = read_data(2);
	new hs = read_data(3);
	new bron[3];
	
	read_data(4, bron, sizeof bron - 1);
	
	if(!get_pcvar_num(gPcvar[DZWIEK])) {
		Dzwiek = false;
	}
	else {
		Dzwiek = true;
	}
	
	if (bron[0] != 'k' && bron[1] != 'r' && !can_see_fm(attacker, victim)) {
		if(hs) {
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[psHeadShot]);
			}
		}
	}
	else if (hs && bron[0] != 'k' && bron[1] != 'r') {
		PokazSprite(victim, sHeadShot);
		if(Dzwiek) {
			client_cmd(attacker, "spk %s", gPluginSounds[psHeadShot]);
		}
	}
	else if (bron[0] == 'k') {
		PokazSprite(victim, sKnifeKill);
		if(Dzwiek) {
			client_cmd(attacker, "spk %s", gPluginSounds[psKnifeKill]);
		}
	}
	else if (bron[1] == 'r') {
		PokazSprite(victim, sGrenadeKill);
		if(Dzwiek) {
			client_cmd(attacker, "spk %s", gPluginSounds[psGrenadeKill]);
		}
	}
	
	new players_ct[32], players_t[32];
	new ict, ite;
	
	get_players(players_ct,ict,"ae","CT");  
	get_players(players_t,ite,"ae","TERRORIST");
	
	if (ict == 0 || ite == 0) {
		gKill[OstatnieZabicie] = 1;
	}
	
	gPoziom[attacker] += 1;
	gPoziom[victim] = 0;
	
	if((victim == attacker) || (get_user_team(attacker) == get_user_team(victim)) || !victim || !attacker)
		return PLUGIN_CONTINUE;
	
	if (gKill[PierwszeZabicie] && attacker!=victim && attacker>0) {	
		gKill[PierwszeZabicie] = 0;
		if(Dzwiek) {
			client_cmd(0, "spk %s", gPluginSounds[psFirstBlood]);
		}
	}
	
	if (gKill[OstatnieZabicie] == 1) {
		gKill[OstatnieZabicie] = 0;
		if(Dzwiek) {
			client_cmd(0, "spk %s", gPluginSounds[psLastKill]);
		}
	}  
	
	switch (gPoziom[attacker]) {
		case 1: {
			PokazSprite(victim, sJeden);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps1]);
			}
			Zabicie[victim] = true;			
		}
		case 2: {
			PokazSprite(victim, sDwa);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps2]);
			}
			Zabicie[victim] = true;
		}
		case 3: {
			PokazSprite(victim, sTrzy);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps3]);
			}
			Zabicie[victim] = true;
		}
		case 4: {
			PokazSprite(victim, sCztery);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps4]);
			}
			Zabicie[victim] = true;
		}
		case 5: {
			PokazSprite(victim, sPiec);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps5]);
			}
			Zabicie[victim] = true;
		}
		case 6: {
			PokazSprite(victim, sSzesc);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps6]);
			}
			Zabicie[victim] = true;
		}
		case 7: {
			PokazSprite(victim, sSiedem);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps7]);
			}
			Zabicie[victim] = true;
		}
		case 8: {
			PokazSprite(victim, sOsiem);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[ps8]);
			}	
			Zabicie[victim] = true;
		}
		case 9: {
			PokazSprite(victim, sWiecejOdOsiem);
			if(Dzwiek) {
				client_cmd(attacker, "spk %s", gPluginSounds[psUnstoppable]);
			}
			Zabicie[victim] = true;			
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PokazSprite(attacker, Sprites: sprite) {	
	if(!is_user_connected(attacker))
		return PLUGIN_CONTINUE;
	
	static origin[3];
	get_user_origin(attacker, origin);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_SPRITE);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]+65);
	write_short(gPluginSprites[sprite][sdPointer]); 
	write_byte(10);
	write_byte(250);
	message_end();
	
	return PLUGIN_CONTINUE;
}

bool:can_see_fm(entindex1, entindex2) {
	if (!entindex1 || !entindex2)
		return false;

	if (pev_valid(entindex1) && pev_valid(entindex1)) {
		new flags = pev(entindex1, pev_flags);
		if (flags & EF_NODRAW || flags & FL_NOTARGET) {
			return false;
		}

		new Float:lookerOrig[3];
		new Float:targetBaseOrig[3];
		new Float:targetOrig[3];
		new Float:temp[3];

		pev(entindex1, pev_origin, lookerOrig);
		pev(entindex1, pev_view_ofs, temp);
		lookerOrig[0] += temp[0];
		lookerOrig[1] += temp[1];
		lookerOrig[2] += temp[2];

		pev(entindex2, pev_origin, targetBaseOrig);
		pev(entindex2, pev_view_ofs, temp);
		targetOrig[0] = targetBaseOrig [0] + temp[0];
		targetOrig[1] = targetBaseOrig [1] + temp[1];
		targetOrig[2] = targetBaseOrig [2] + temp[2];

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0);
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater)) {
			return false;
		} 
		else {
			new Float:flFraction;
			get_tr2(0, TraceResult:TR_flFraction, flFraction);
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) {
				return true;
			}
			else {
				targetOrig[0] = targetBaseOrig [0];
				targetOrig[1] = targetBaseOrig [1];
				targetOrig[2] = targetBaseOrig [2];
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0);
				get_tr2(0, TraceResult:TR_flFraction, flFraction);
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) {
					return true;
				}
				else {
					targetOrig[0] = targetBaseOrig [0];
					targetOrig[1] = targetBaseOrig [1];
					targetOrig[2] = targetBaseOrig [2] - 17.0;
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0);
					get_tr2(0, TraceResult:TR_flFraction, flFraction);
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) {
						return true;
					}
				}
			}
		}
	}
	return false;
}