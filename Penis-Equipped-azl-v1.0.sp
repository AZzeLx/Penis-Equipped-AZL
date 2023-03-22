#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required

int g_iDick[MAXPLAYERS + 1] = {-1, -1, -1, ...};

float fPos[3] = {0.0, -3.0, -40.0}, fAng[3] = {0.0, 0.0, 0.0};
char attachment[32] = "facemask";

Handle g_Penis_Cookie;
bool g_PenisEnabled[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Penis Equipped",
	author = "AZzeL ( Credite: kilinma1 )",
	description = "Iti echipezi un penis",
	version = "1.0",
	url = "https://fireon.ro"
};
	
public void OnPluginStart()
{
	g_Penis_Cookie = RegClientCookie("PenisCookie", "PenisCookie", CookieAccess_Protected);

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);

	RegConsoleCmd("penis", Command_Penis);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("models/3d/penis/penis.dx80.vtx");
	AddFileToDownloadsTable("models/3d/penis/penis.dx90.vtx");
	AddFileToDownloadsTable("models/3d/penis/penis.mdl");
	AddFileToDownloadsTable("models/3d/penis/penis.phy");
	AddFileToDownloadsTable("models/3d/penis/penis.sw.vtx");
	AddFileToDownloadsTable("models/3d/penis/penis.vvd");
	AddFileToDownloadsTable("materials/3d/penis/dick_1_normal.vtf");
	AddFileToDownloadsTable("materials/3d/penis/dick_1_diff_diffuse.vtf");
	AddFileToDownloadsTable("materials/3d/penis/dick_1_diff_diffuse.vmt");
	
	PrecacheModel("models/3d/penis/penis.mdl", true);
}

public void OnClientPutInServer(int client)
{
	g_PenisEnabled[client] = false;

	char buffer[64];
	GetClientCookie(client, g_Penis_Cookie, buffer, sizeof(buffer));
	if(StrEqual(buffer,"1"))
		g_PenisEnabled[client] = true;
}

public Action Command_Penis(int client, int args) 
{
	if(g_PenisEnabled[client])
	{
		PrintToChat(client, "\x02Penis is now off");
		g_PenisEnabled[client] = false;
		SetClientCookie(client, g_Penis_Cookie, "0");
	}
	else
	{
		PrintToChat(client, "\x04Penis is now on");
		g_PenisEnabled[client] = true;
		SetClientCookie(client, g_Penis_Cookie, "1");
	}

	return Plugin_Handled;
}

public void OnPlayerSpawn(Event hEvent, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

        if (g_PenisEnabled[client] && IsClientInGame(client))  
        {  
		Equip(client);
	}
}

public void OnPlayerDeath(Event hEvent, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	Dequip(client);
}

public void OnClientDisconnect(int client)
{
	g_iDick[client] = -1;
	Dequip(client);
}

void Equip(int client)
{	
	float or[3], ang[3], fForward[3], fRight[3], fUp[3];
	
	GetClientAbsOrigin(client, or);
	GetClientAbsAngles(client, ang);

	ang[0] += fAng[0];
	ang[1] += fAng[1];
	ang[2] += fAng[2];
	
	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fPos[0] + fForward[0]*fPos[1] + fUp[0]*fPos[2];
	or[1] += fRight[1]*fPos[0] + fForward[1]*fPos[1] + fUp[1]*fPos[2];
	or[2] += fRight[2]*fPos[0] + fForward[2]*fPos[1] + fUp[2]*fPos[2];

	int ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "model", "models/3d/penis/penis.mdl");
	DispatchKeyValue(ent, "spawnflags", "256");
	DispatchKeyValue(ent, "solid", "0");
	
	// We give the name for our entities here
	char tName[24];
	Format(tName, sizeof(tName), "equip_%d", ent);
	DispatchKeyValue(ent, "targetname", tName);
	
	DispatchSpawn(ent);	
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	g_iDick[client] = EntIndexToEntRef(ent);
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
	
	TeleportEntity(ent, or, ang, NULL_VECTOR); 
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	if (attachment[0])
	{
		SetVariantString(attachment);
		AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
	}
}

void Dequip(int client)
{
	if(g_iDick[client] != -1)
	{
		int entity = EntRefToEntIndex(g_iDick[client]);
		if(entity != INVALID_ENT_REFERENCE && IsValidEdict(entity))
			AcceptEntityInput(entity, "Kill");
		
		g_iDick[client] = -1;
	}
}

public Action ShouldHide(int ent, int client)
{
	int owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if(owner == client) return Plugin_Handled;

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
		if(owner == GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"))
			return Plugin_Handled;
	
	return Plugin_Continue;
}