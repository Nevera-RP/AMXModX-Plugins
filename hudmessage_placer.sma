 /* Hudmessage placer

About:
This plugin is made to help place hud messages on the screen, it allows you to change the color on the hud message & the possion with a menu, while showing you what the
"current" settings are.

Usage:
amx_hudmenupos	  <-> Open the menu to change Color say pos
amx_hudmenucolor  <-> Open the menu to change Color say color

Modules required:
Engine

Forum topic: http://www.amxmodx.org/forums/viewtopic.php?t=2288

Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicR & CheesyPeteza )  

Changelog
 1.1.1
	- Fixed: client_connect was used instead of client_disconnect to force a reset incase the menu was still open.
	- Added: g_IsMenuOpen[0] witch knows if anyone menu open. Witch should lower cpu usage


 1.1.0
	- Changed: Menu should no longer be "lagging" as it gets reopend every 0.1 sec
	- Changed: Plugin no longer tries to color menus as Green & blue dont work
	- Added: Test Hudmessage is ONLY shown to players who have the menu open
	- Fixed: Going over 255 & bellow 0 when changing colors

 1.0.0
	- First release
*/
#include <amxmodx> 
#include <engine>
#include <amxmisc>

new Float:g_hudcord[2]
new g_hudcolor[3]
new g_IsMenuOpen[33]

public plugin_init()
	{ 
	register_plugin("Hudmessage placer","1.1.0","EKS")
	register_menucmd(register_menuid("\yHud Menu Pos:"), 1023, "MenuCommandHudPos" )
	register_menucmd(register_menuid("\yHud Menu Color:"), 1023, "MenuCommandHudColor" )
	register_clcmd("amx_hudmenupos","ShowMenuHudPos")
	register_clcmd("amx_hudmenucolor","ShowMenuHudColor")

	new parm[2]
	set_task(0.1,"show_message",1,parm,1,"b")
	g_hudcord[0] = 0.5
	g_hudcord[1] = 0.5

	g_hudcolor[0] = 0
	g_hudcolor[1] = 255
	g_hudcolor[2] = 0
	}

public show_message()
	{
	new Message[256]
	format(Message,255,"Hud message")
	set_hudmessage(g_hudcolor[0], g_hudcolor[1], g_hudcolor[2], g_hudcord[0], g_hudcord[1], 0, 0.1, 0.1, 0.5, 0.15,4)
	
	for(new i=1;i<=get_maxplayers() && g_IsMenuOpen[i];i++)
		{
		if(g_IsMenuOpen[i] == 1)
			{
			show_hudmessage(0,Message)
			ShowMenuHudPos(i)
			}
		else if(g_IsMenuOpen[i] == 2)
			{
			show_hudmessage(0,Message)
			ShowMenuHudColor(i)
			}
		}
	}
/*
1 = move right
2 = move left
3 = move down
4 = move up
*/
change_hudpos(temp)
	{
	if(temp == 1)
		{
		if(g_hudcord[0] == (1.0))
			g_hudcord[0] = 0.0
		g_hudcord[0] = g_hudcord[0] + 0.01
		}
	if(temp == 2)
		{
		if(g_hudcord[0] == 0)
			g_hudcord[0] = 1.0
		g_hudcord[0] = g_hudcord[0] - 0.01
		}
	if(temp == 3)
		{
		if(g_hudcord[1] == 1.0)
			g_hudcord[1] = 0.0
		g_hudcord[1] = g_hudcord[1] + 0.01
		}
	if(temp == 4)
		{
		if(g_hudcord[1] == 0)
			g_hudcord[1] = 1.0
		g_hudcord[1] = g_hudcord[1] - 0.01
		}
	}

change_hudcolor(temp)
	{
	if(temp == 1)
		{
		if(g_hudcolor[0] == 255)
			g_hudcolor[0] = -1
		g_hudcolor[0] = g_hudcolor[0] + 1
		}
	if(temp == 2)
		{
		if(g_hudcolor[0] == 0)
			g_hudcolor[0] = 256
		g_hudcolor[0] = g_hudcolor[0] - 1
		}
	if(temp == 3)
		{
		if(g_hudcolor[1] == 255)
			g_hudcolor[1] = -1
		g_hudcolor[1] = g_hudcolor[1] + 1
		}
	if(temp == 4)
		{
		if(g_hudcolor[1] == 0)
			g_hudcolor[1] = 256
		g_hudcolor[1] = g_hudcolor[1] - 1
		}
	if(temp == 5)
		{
		if(g_hudcolor[2] == 255)
			g_hudcolor[2] = -1
		g_hudcolor[2] = g_hudcolor[2] + 1
		}
	if(temp == 6)
		{
		if(g_hudcolor[2] == 0)
			g_hudcolor[2] = 256
		g_hudcolor[2] = g_hudcolor[2] - 1
		}
	}

public ShowMenuHudPos(id)
	{
	new szMenuBody[256]
	new keys
	g_IsMenuOpen[id] = 1
	g_IsMenuOpen[0]++

	format( szMenuBody, 255, "\yHud Menu Pos:^n Color: %d/%d/%d Pos:%0.2f/%0.2f",g_hudcolor[0],g_hudcolor[1],g_hudcolor[2],g_hudcord[0],g_hudcord[1])
	add( szMenuBody, 255, "^n\w1. Move right" )
	add( szMenuBody, 255, "^n\w2. Move left" )
	add( szMenuBody, 255, "^n\w3. Move down" )
	add( szMenuBody, 255, "^n\w4. Move up" )
	add( szMenuBody, 255, "^n^n\w0. Exit" )

	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	show_menu( id, keys, szMenuBody, -1 )
	}

public MenuCommandHudPos(id,key)
	{
	new temp
	switch( key )
		{
		case 0: temp = 1
		case 1: temp = 2
		case 2: temp = 3
		case 3: temp = 4
		} 
	if(key == 9)
		{
		g_IsMenuOpen[id] = 0
		g_IsMenuOpen[0]--
		return PLUGIN_HANDLED
		}
	change_hudpos(temp)
	return PLUGIN_CONTINUE
	}

public ShowMenuHudColor(id)
	{
	new szMenuBody[256]
	new keys
	g_IsMenuOpen[id] = 2
	g_IsMenuOpen[0]++

	format( szMenuBody, 255, "\yHud Menu Color:^n Color: %d/%d/%d Pos:%0.2f/%0.2f",g_hudcolor[0],g_hudcolor[1],g_hudcolor[2],g_hudcord[0],g_hudcord[1])
	add( szMenuBody, 255, "^n\w 1. Red up" )
	add( szMenuBody, 255, "^n\w 2. Red down" )
	add( szMenuBody, 255, "^n\w 3. Green up" )
	add( szMenuBody, 255, "^n\w 4. Green down" )
	add( szMenuBody, 255, "^n\w 5. Blue up" )
	add( szMenuBody, 255, "^n\w 6. Blue down" )
	add( szMenuBody, 255, "^n\w 0. Exit" )

	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	show_menu( id, keys, szMenuBody, -1 )
	}

public MenuCommandHudColor(id,key)
	{
	new temp
	switch( key )
		{
		case 0: temp = 1
		case 1: temp = 2
		case 2: temp = 3
		case 3: temp = 4
		case 4: temp = 5
		case 5: temp = 6
		} 
	if(key == 9)
		{
		g_IsMenuOpen[id] = 0
		g_IsMenuOpen[0]--
		return PLUGIN_HANDLED
		}
	change_hudcolor(temp)
	return PLUGIN_CONTINUE
	}
public client_disconnect(id) 
		{
		if(g_IsMenuOpen[id])
			{
			g_IsMenuOpen[id] = 0
			g_IsMenuOpen[0]--
			}
		}