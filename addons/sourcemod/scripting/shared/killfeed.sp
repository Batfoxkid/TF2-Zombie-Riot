#pragma semicolon 1
#pragma newdecls required

enum struct KillFeed
{
	int attacker;
	char attacker_name[64];
	int attacker_team;

	int userid;
	char victim_name[64];
	int victim_team;

	int assister;
	//char assister_name[64];
	//int assister_team;

	int weaponid;
	char weapon[32];
	int weapon_def_index;
	int damagebits;
	int inflictor_entindex;
	int customkill;
	bool silent_kill;
}

static const char BuildingName[][] =
{
	"Building",
	"Barricade",
	"Elevation",
	"AmmoBox",
	"Armortable",
	"Perk Machine",
	"Pack-a-Punch",
	"Railgun",
	"Sentry",
	"Mortar",
	"Healing Station",
	"Barracks"
};

static int Bots[2];
static int ForceTeam[MAXTF2PLAYERS];
static char KillIcon[MAXENTITIES][32];
static ArrayList FeedList;
static Handle FeedTimer;

void KillFeed_PluginStart()
{
	FeedList = new ArrayList(sizeof(KillFeed));

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsFakeClient(client))
		{
			for(int i; i < sizeof(Bots); i++)
			{
				if(!Bots[i])
				{
					Bots[i] = client;
					break;
				}
			}
		}
	}
}

void KillFeed_ClientPutInServer(int client)
{
	if(IsFakeClient(client))
	{
		ForceTeam[client] = 3;
	
		for(int i; i < sizeof(Bots); i++)
		{
			if(!Bots[i])
			{
				Bots[i] = client;
				break;
			}
		}
	}
}

void KillFeed_ClientDisconnect(int client)
{
	for(int i; i < sizeof(Bots); i++)
	{
		if(Bots[i] == client)
		{
			// Shift Array
			for(int a = (i + 1); a < sizeof(Bots); a++)
			{
				Bots[a - 1] = Bots[a];
			}

			// Replace "Bot"
			Bots[sizeof(Bots) - 1] = 0;
			for(int target = 1; target <= MaxClients; target++)
			{
				if(client != target)
				{
					bool found;
					for(int a; a < (sizeof(Bots) - 1); a++)
					{
						if(target == Bots[i])
						{
							found = true;
							break;
						}
					}

					if(!found && IsClientInGame(target) && IsFakeClient(target))
					{
						Bots[sizeof(Bots) - 1] = target;
						break;
					}
				}
			}

			break;
		}
	}
}

void KillFeed_EntityCreated(int entity)
{
	KillIcon[entity][0] = 0;
}

stock void KillFeed_SetKillIcon(int entity, const char[] icon)
{
	strcopy(KillIcon[entity], sizeof(KillIcon[]), icon);
}

int KillFeed_GetBotTeam(int client)
{
	return ForceTeam[client];
}

void KillFeed_SetBotTeam(int client, int team)
{
	ForceTeam[client] = team;
	ChangeClientTeam(client, team);
}

#if defined ZR
static bool BuildingFullName(int entity, char[] buffer, int length)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	if(owner < 1 || owner > MaxClients || !IsClientInGame(owner))
		return false;

	int index = i_WhatBuilding[entity];
	if(index >= sizeof(BuildingName))
		index = 0;
	
	Format(buffer, length, "%s (%N)", BuildingName[index], owner);
	return true;
}
#endif

void KillFeed_Show(int victim, int inflictor, int attacker, int lasthit, int weapon, int damagetype, bool silent = false)
{
	// TODO: Possibly headshot kill icon

	int botNum;
	KillFeed feed;

	if(victim <= MaxClients)
	{
		feed.userid = GetClientUserId(victim);
	}
	else if(!b_NpcHasDied[victim])
	{
		if(!Bots[botNum])
			return;
		
		feed.userid = GetClientUserId(Bots[botNum]);
		feed.victim_team = GetEntProp(victim, Prop_Send, "m_iTeamNum");
		strcopy(feed.victim_name, sizeof(feed.victim_name), NPC_Names[i_NpcInternalId[victim]]);
		
		botNum++;

#if defined ZR
		if(i_HasBeenHeadShotted[victim])
		{
			feed.customkill = TF_CUSTOM_HEADSHOT;
		}
		else if(i_HasBeenBackstabbed[victim])
		{
			feed.customkill = TF_CUSTOM_BACKSTAB;
		}
#endif

	}
#if defined ZR
	else if(i_IsABuilding[victim])
	{
		if(!Bots[botNum])
			return;
		
		if(!BuildingFullName(victim, feed.victim_name, sizeof(feed.victim_name)))
			return;
		
		feed.userid = GetClientUserId(Bots[botNum]);
		feed.victim_team = GetEntProp(victim, Prop_Send, "m_iTeamNum");
		botNum++;
	}
#endif
	else
	{
		return;
	}
	
	if(attacker > 0)
	{
		if(attacker <= MaxClients)
		{
			feed.attacker = GetClientUserId(attacker);
		}
		else if(!b_NpcHasDied[attacker])
		{
			if(!Bots[botNum])
				return;
			
			feed.attacker = GetClientUserId(Bots[botNum]);
			feed.attacker_team = GetEntProp(attacker, Prop_Send, "m_iTeamNum");
			strcopy(feed.attacker_name, sizeof(feed.attacker_name), NPC_Names[i_NpcInternalId[attacker]]);
			
			botNum++;
		}
#if defined ZR
		else if(i_IsABuilding[attacker])
		{
			feed.attacker = -1;
		}
#endif
	}

	if(lasthit > 0)
	{
		if(attacker == lasthit)
		{
			// Self last hit
			feed.assister = -1;
		}
		else
		{
			// Assister
			feed.assister = GetClientUserId(lasthit);
		}
	}
	else if(lasthit == -69)
	{
		// "Finished off"
		feed.assister = -1;

#if defined ZR
		if(i_IsABuilding[victim])
		{
			feed.customkill = TF_CUSTOM_CARRIED_BUILDING;
			strcopy(feed.weapon, sizeof(feed.weapon), "building_carried_destroyed");
		}
		else
#endif
		{
			feed.customkill = TF_CUSTOM_SUICIDE;
		}
	}
	else if(attacker > MaxClients && attacker != victim)
	{
		// NPC did a solo
		feed.assister = -1;
	}
	else if(victim > MaxClients)
	{
		// "Finished off"
		feed.assister = -1;
		feed.customkill = TF_CUSTOM_SUICIDE;
	}

	feed.weaponid = weapon;
	feed.damagebits = damagetype;
	feed.silent_kill = silent;
	
	if(inflictor > MaxClients)
	{
		// NPC/Building's Icon

		feed.inflictor_entindex = inflictor;
		feed.weapon_def_index = -1;

		if(lasthit != -69)
			strcopy(feed.weapon, sizeof(feed.weapon), KillIcon[inflictor]);
	}
	else if(weapon > MaxClients)
	{
		// Weapon's Icon

		feed.inflictor_entindex = weapon;
		feed.weapon_def_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		if(lasthit != -69)
		{
			if(KillIcon[weapon][0])
			{
				strcopy(feed.weapon, sizeof(feed.weapon), KillIcon[weapon]);
			}
			else
			{
				TF2Econ_GetItemDefinitionString(feed.weapon_def_index, "item_iconname", feed.weapon, sizeof(feed.weapon));
			}
		}
	}

	FeedList.PushArray(feed);

	if(!FeedTimer)
		ShowNextFeed();
}

static void ShowNextFeed()
{
	if(FeedList.Length)
	{
		KillFeed feed;
		FeedList.GetArray(0, feed);
		FeedList.Erase(0);

		int victim = GetClientOfUserId(feed.userid);
		int attacker = GetClientOfUserId(feed.attacker);

		bool botUsed;
		if(feed.victim_name[0] && victim)
		{
			SetClientName(victim, feed.victim_name);
			SetEntPropString(victim, Prop_Data, "m_szNetname", feed.victim_name);
			KillFeed_SetBotTeam(victim, feed.victim_team);
			botUsed = true;
		}

		if(feed.attacker_name[0] && attacker)
		{
			SetClientName(attacker, feed.attacker_name);
			SetEntPropString(attacker, Prop_Data, "m_szNetname", feed.attacker_name);
			KillFeed_SetBotTeam(attacker, feed.attacker_team);
			botUsed = true;
		}
		
		Event event = CreateEvent("player_death", true);

		event.SetInt("attacker", feed.attacker);
		event.SetInt("userid", feed.userid);
		event.SetInt("victim_entindex", victim);
		event.SetInt("assister", feed.assister);
		event.SetInt("weaponid", feed.weaponid);
		event.SetString("weapon", feed.weapon);
		event.SetInt("weapon_def_index", feed.weapon_def_index);
		event.SetInt("damagebits", feed.damagebits);
		event.SetInt("inflictor_entindex", feed.inflictor_entindex);
		event.SetInt("customkill", feed.customkill);

		if(feed.silent_kill)
		{
			if(victim)
				event.FireToClient(victim);
			
			if(attacker)
				event.FireToClient(attacker);
		}
		else
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client))
					event.FireToClient(client);
			}
		}

		event.Cancel();

		if(botUsed)
		{
			FeedTimer = CreateTimer(0.3, KillFeed_Timer);
		}
		else
		{
			ShowNextFeed();
		}
	}
}

public Action KillFeed_Timer(Handle timer)
{
	FeedTimer = null;
	ShowNextFeed();
	return Plugin_Continue;
}