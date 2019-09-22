/*  SM Jailbreak Soccer
 *
 *  Copyright (C) 2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <devzones>
#include <myjailbreak>
#include <myjbwarden>
#include <warden>

#define MINUTES 30

ConVar cvar_end;
int goleador;
int balon;

bool soccer;


int g_iTime;

bool pending;

float PositionReal[3];
bool real;

#define DATA "1.0"

Handle timers;

public Plugin myinfo = 
{
	name = "SM Jailbreak Soccer",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	cvar_end = FindConVar("mp_round_restart_delay");
	
	HookEvent("round_prestart", Event_RoundStart);
	
	HookEvent("player_spawn", PlayerSpawn);
	
	RegAdminCmd("sm_soccer", Command_Soccer, ADMFLAG_CUSTOM1);
	
	
	for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
	
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.dx80.vtx");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.dx90.vtx");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.mdl");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.phy");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.sw.vtx");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.vvd");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.xbox.vtx");
	AddFileToDownloadsTable("materials/models/forlix/soccer/soccerball.vmt");
	AddFileToDownloadsTable("materials/models/forlix/soccer/soccerball.vtf");

	PrecacheModel("models/forlix/soccer/soccerball.mdl");
}

public OnPluginEnd()
{
	if (!soccer && !pending)return;
	
	
	Terminar();
}

public Action Command_Soccer(int client, int args)
{
	DoVoteMenu(client);
	return Plugin_Handled;
}

void DoVoteMenu(int client)
{
	if (IsVoteInProgress())
	{
		PrintToChat(client, " \x03Vote in progress, wait to end.");
		return;
	}
	
	if (MyJailbreak_IsEventDayPlanned())
	{
		PrintToChat(client, " \x03You cant use this because already exist a day planned.");
		return;
	}
	
	if (MyJailbreak_IsEventDayRunning())
	{
		PrintToChat(client, " \x03You cant use this because already exist a day running.");
		return;
	}
	
	if (!HasPermission(client, "z") && GetTime() < (g_iTime+(MINUTES*60)))
	{
		PrintToChat(client, " \x03You cant use still this command, wait %i seconds more.", (g_iTime+(MINUTES*60)) - GetTime());
		return;
	}

	if(!Zone_CheckIfZoneExists("soccerzone"))
	{
		PrintToChat(client, " \x03This map dont support soccer day because the zones with !zones are not created.");
		return;
	}
	
	LogToFile("addons/sourcemod/logs/futbol.log", "%L started a vote.", client);
	
	g_iTime = GetTime();
	
	Menu menu = new Menu(Handle_VoteMenu);
	menu.SetTitle("The next round should be a Soccer Day?");
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");

	menu.DisplayVoteToAll(20);
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		delete menu;
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			//Empezar();
			
			//CS_TerminateRound(GetConVarFloat(cvar_end), CSRoundEnd_Draw);
			
			pending = true;
			
			SetCvarString("sm_ratio_T_per_CT", "1.0");
			ServerCommand("sm_cvar sm_ratio_T_per_CT 1.0");
			
			MyJailbreak_SetEventDayName("SOCCER");
			MyJailbreak_SetEventDayPlanned(true);
			
			PrintCenterTextAll("SOCCER DAY IN THE NEXT ROUND!");
			
			PrintToChatAll(" \x03SOCCER DAY IN THE NEXT ROUND!");
			
			LogToFile("addons/sourcemod/logs/futbol.log", "Vote accepted.");
		}
		else
		{
			PrintToChatAll(" \x03The vote for the soccer day was refused.");
			
			LogToFile("addons/sourcemod/logs/futbol.log", "The vote for the soccer day was refused.");
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!soccer)return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	
	SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
	SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	
	
	CreateTimer(1.2, Timer_Weapons, GetClientUserId(client));
	
	decl Float:Position[3];
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		if(Zone_GetZonePosition("soccer2", false, Position)) TeleportEntity(client, Position, NULL_VECTOR, NULL_VECTOR);
	}
	else if(GetClientTeam(client) == CS_TEAM_T)
	{
		if(Zone_GetZonePosition("soccer1", false, Position)) TeleportEntity(client, Position, NULL_VECTOR, NULL_VECTOR);
	}
	
}

public Action Timer_Weapons(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (!IsValidClient(client) || !IsPlayerAlive(client))return;
	
	StripAllPlayerWeapons(client);
	
	GivePlayerItem(client, "weapon_knife");
	
	//SetEntProp(client, Prop_Data, "m_CollisionGroup", 1);
	//SetEntProp(client, Prop_Data, "m_nSolidType", 0);
	//SetEntProp(client, Prop_Send, "m_usSolidFlags", 4);
}

Empezar()
{	
	soccer = true;
	if(warden_exist())
	{
		FakeClientCommand(warden_get(), "sm_uw");
	}
	SetCvar("sm_weapons_enable", 0);
	SetCvar("sm_warden_enable", 0);
	SetCvar("sm_hosties_startweapons_on", 0);
	SetCvar("sm_hosties_lr", 0);
	SetCvar("sm_menu_enable", 0);
	SetCvarString("sm_ratio_T_per_CT", "1.0");
	ServerCommand("sm_cvar sm_ratio_T_per_CT 1.0");
}

Terminar()
{
	if(IsValidEntity(balon) && balon > 0) 
		SDKUnhook(balon, SDKHook_OnTakeDamage, boladamage);
	
	soccer = false;
	
	MyJailbreak_SetEventDayRunning(false, 0);
	MyJailbreak_SetEventDayName("none");
	
	SetCvar("sm_weapons_enable", 1);
	SetCvar("sm_warden_enable", 1);
	SetCvar("sm_hosties_startweapons_on", 1);
	SetCvarString("sm_ratio_T_per_CT", "1.5");
	ServerCommand("sm_cvar sm_ratio_T_per_CT 1.5");
	
	SetCvar("sm_hosties_lr", 1);
	SetCvar("sm_menu_enable", 1);
}

public Action Event_RoundStart(Event event, const char[] szName, bool bDontBroadcast)
{
	if (!pending && !soccer)return;
	
	Empezar();
	
	MyJailbreak_SetEventDayPlanned(false);
	MyJailbreak_SetEventDayRunning(true, 0);
	
	CreateTimer(2.0, Timer_Balon);
	
	pending = false;
	
}

public Action Timer_Balon(Handle timer)
{
	if (!soccer)return;
	new Float:position[3];
	
	balon = -1;
	int entity = -1;
	real = false;
	while ((entity = FindEntityByClassname(entity, "prop_physics")) != -1)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		
		if(Zone_isPositionInZone("soccerzone", position[0], position[1], position[2]))
		{
			real = true;
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", PositionReal);
			AcceptEntityInput(entity, "Kill");
		}
	}
	

	new ent = CreateEntityByName("prop_physics_override"); 
			
	SetEntityModel(ent, "models/forlix/soccer/soccerball.mdl"); 
	DispatchKeyValue(ent, "StartDisabled", "false"); 
	//DispatchKeyValue(ent, "Solid", "6"); 
	DispatchKeyValue(ent, "spawnflags", "257"); 
	DispatchKeyValue(ent, "classname", "futbol");
	DispatchKeyValue(ent, "targetname", "ballon");
	DispatchSpawn(ent); 
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0); 
	AcceptEntityInput(ent, "EnableCollision"); 
	
	//SetEntProp(ent, Prop_Data, "m_MoveCollide", 1);
	
	decl Float:Position[3];
	if(Zone_GetZonePosition("soccerzone", false, Position)) 
	{
		if(real)
		{
			PositionReal[2] += 20.0;
			TeleportEntity(ent, PositionReal, NULL_VECTOR, NULL_VECTOR);
		}
		else TeleportEntity(ent, Position, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
	}
	
	//SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5); 
	
	balon = ent;
	SDKHook(balon, SDKHook_OnTakeDamage, boladamage);
	
	
	ClearTimer(timers);
	
	timers = CreateTimer(3.0, Timer_End);
	
	SetEntityRenderColor(balon, 0, 0, 255, 255);
	//PrintToChatAll("El balon es %i", balon);
}

stock ClearTimer(&Handle:Timer) 
{ 
    if (Timer != INVALID_HANDLE) 
    { 
        KillTimer(Timer); 
        Timer = INVALID_HANDLE; 
    } 
}  

public Action Timer_End(Handle timer)
{
	timers = INVALID_HANDLE;
	
	if(soccer && IsValidEntity(balon))
		SetEntityRenderColor(balon, 255, 255, 255, 255);
}

public Action:boladamage(edict, &inflictor, &attacker, &Float:damage, &damagetype)
{
	goleador = attacker;
	
	if (timers != INVALID_HANDLE) 
		return Plugin_Handled;
		
	return Plugin_Continue;
}

MatarTerros()
{
  for (new i = 1; i <= MaxClients; i++)
  {
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
	{
                 ForcePlayerSuicide(i);
	}
  }
}

MatarCTs()
{
  for (new i = 1; i <= MaxClients; i++)
  {
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
	{
                 ForcePlayerSuicide(i);
	}
  }
}

public Zone_OnClientLeave(client, String:zone[])
{
	if(soccer)
	{
		if(IsValidClient(client) && StrContains(zone, "soccerzone", false) == 0)
		{
			decl Float:Position[3];
			if(GetClientTeam(client) == CS_TEAM_CT)
			{
				if(Zone_GetZonePosition("soccer2", false, Position)) TeleportEntity(client, Position, NULL_VECTOR, NULL_VECTOR);
			}
			else if(GetClientTeam(client) == CS_TEAM_T)
			{
				if(Zone_GetZonePosition("soccer1", false, Position)) TeleportEntity(client, Position, NULL_VECTOR, NULL_VECTOR);
			}
		}
		else if(client == balon && StrContains(zone, "soccerzone", false) == 0)
		{
			ClearTimer(timers);
	
			timers = CreateTimer(3.0, Timer_End);
	
			SetEntityRenderColor(balon, 0, 0, 255, 255);
			
			if(real)
				TeleportEntity(balon, PositionReal, NULL_VECTOR, NULL_VECTOR);
			else
			{
				decl Float:Position[3];
				if(Zone_GetZonePosition("soccerzone", false, Position)) TeleportEntity(balon, Position, NULL_VECTOR, NULL_VECTOR);
			}
		}
		
	}
}

public Zone_OnClientEntry(client, String:zone[])
{
	//PrintToChatAll("entidad %i toca zona %s", client, zone);
	if(soccer && client == balon)
	{
		if(StrContains(zone, "goal2", false) == 0)
		{
			
			
			
			char temp[255];
			Panel panel = new Panel();
			panel.SetTitle("Match results:");
 			if(IsValidClient(goleador)) 
 			{
 				Format(temp, 255, "%N scored a gol!", goleador);
 				panel.DrawItem(temp);
 				PrintToChatAll(" \x04%N \x03scored a gol!", goleador);
 			}
			PrintToChatAll(" \x03The Terrorists team wins!");
			Format(temp, 255, "The Terrorists team wins!");
 			panel.DrawItem(temp);
 
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					panel.Send(i, PanelHandler1, 20);
 
			delete panel;
			
			soccer = false;
			
			Terminar();
			
			CS_TerminateRound(GetConVarFloat(cvar_end), CSRoundEnd_TerroristWin);
			MatarCTs();
		}
		else if(StrContains(zone, "goal1", false) == 0)
		{
			
			char temp[255];
			Panel panel = new Panel();
			panel.SetTitle("Match results:");
 			if(IsValidClient(goleador)) 
 			{
 				Format(temp, 255, "%N scored a gol!", goleador);
 				panel.DrawItem(temp);
 				PrintToChatAll(" \x04%N \x03scored a gol!", goleador);
 			}
			PrintToChatAll(" \x03The Counter-Terrorists team wins!");
			Format(temp, 255, "The Counter-Terrorists team wins!");
 			panel.DrawItem(temp);
 
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					panel.Send(i, PanelHandler1, 20);
 
			delete panel;
			
			soccer = false;
			Terminar();
			
			CS_TerminateRound(GetConVarFloat(cvar_end), CSRoundEnd_CTWin);
			MatarTerros();
		}
	}
}

public int PanelHandler1(Menu menu, MenuAction action, int param1, int param2)
{

}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	for (int i = 0; i <= 6; i++)
	{
		while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
}

stock bool HasPermission(int iClient, char[] flagString) 
{
	if (StrEqual(flagString, "")) 
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++) 
		{
			if (flags & (1<<i)) 
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>(i))) 
				{
					found++;
				}
			}
		}

		if (count == found) {
			return true;
		}
	}

	return false;
} 

stock void SetCvar(char cvarName[64], int value)
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null) return;

	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);

	SetConVarInt(IntCvar, value);

	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}

stock void SetCvarString(char cvarName[64], char[] value)
{
	Handle cvar = FindConVar(cvarName);
	SetConVarString(cvar, value, true);
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (soccer)
	{
		// block switching to weapon other than knife
		decl String:sClassname[32];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		if (!StrEqual(sClassname, "weapon_knife"))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}