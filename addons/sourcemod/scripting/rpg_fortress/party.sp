#pragma semicolon 1
#pragma newdecls required

#define MAX_PARTY_SIZE	6

static int PartyLeader[MAXTF2PLAYERS];
static int PartyInvitedBy[MAXTF2PLAYERS];
static int PartyOutlineRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};

void Party_PluginStart()
{
	RegConsoleCmd("rpg_party", Party_Command, "Join or create a party");
	RegConsoleCmd("sm_party", Party_Command, "Join or create a party", FCVAR_HIDDEN);
}

void Party_PluginEnd()
{
	for(int i; i < MAXTF2PLAYERS; i++)
	{
		int entity = EntRefToEntIndex(PartyOutlineRef[i]);
		if(entity != -1)
			RemoveEntity(entity);
	}
}

static bool IsInvitedBy(int client, int leader)
{
	return view_as<bool>(PartyInvitedBy[client] & (1 << (leader - 1)));
}

static void AddInvite(int client, int leader)
{
	PartyInvitedBy[client] |= (1 << (leader - 1));
}

static void RemoveInvite(int client, int leader)
{
	PartyInvitedBy[client] &= ~(1 << (leader - 1));
}

int Party_GetPartyLeader(int client)
{
	return PartyLeader[client];
}

bool Party_IsClientMember(int client, int target)
{
	return (PartyLeader[client] && PartyLeader[client] == PartyLeader[target]);
}

void Party_PlayerModel(int client, const char[] model)
{
	int entity = EntRefToEntIndex(PartyOutlineRef[client]);
	if(entity != -1)
		RemoveEntity(entity);
	
	entity = CreateEntityByName("tf_taunt_prop");
	if(IsValidEntity(entity))
	{
		SetEntProp(entity, Prop_Data, "m_iInitialTeamNum", 2);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", 2);

		DispatchSpawn(entity);

		SetEntityModel(entity, model);
		SetEntPropEnt(entity, Prop_Data, "m_hEffectEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_bGlowEnabled", true);
		SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects")|EF_BONEMERGE|EF_NOSHADOW|EF_NOINTERP);

		SetEntPropFloat(entity, Prop_Send, "m_fadeMinDist", 990.0);
		SetEntPropFloat(entity, Prop_Send, "m_fadeMaxDist", 1000.0);	
		
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);

		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 255);
		SDKHook(entity, SDKHook_SetTransmit, Party_Transmit);

		PartyOutlineRef[client] = EntIndexToEntRef(entity);
	}
}

public Action Party_Transmit(int entity, int client)
{
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(owner == -1)
	{
		RemoveEntity(entity);
	}
	else if(owner == client || client > MaxClients || !Party_IsClientMember(owner, client))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void Party_ClientDisconnect(int client)
{
	if(PartyLeader[client] == client)
	{
		int newLeader;
		for(int target = 1; target <= MaxClients; target++)
		{
			if(client != target && PartyLeader[client] == PartyLeader[target])
			{
				if(!newLeader)
					newLeader = target;
				
				SPrintToChat(target, "%N left the party, %N is now the leader!", client, newLeader);
				PartyLeader[target] = newLeader;
			}
		}
	}
	else if(PartyLeader[client])
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(client != target && PartyLeader[client] == PartyLeader[target])
				SPrintToChat(target, "%N left the party!", client);
		}
	}

	PartyLeader[client] = 0;
	PartyInvitedBy[client] = 0;
}

public Action Party_Command(int client, int args)
{
	if(client)
		ShowMenu(client);
	
	return Plugin_Handled;
}

static void ShowMenu(int client)
{
	if(Actor_InChatMenu(client))
		return;
	
	Menu menu = new Menu(Party_MenuHandle);
	menu.SetTitle("RPG Fortress\n \nParty:");

	static char index[16], buffer[96];
	if(PartyLeader[client])
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			bool joined = PartyLeader[client] == PartyLeader[target];
			if(joined || IsInvitedBy(target, PartyLeader[client]))
			{
				GetClientName(target, buffer, sizeof(buffer));

				if(client == target)
				{
					Format(buffer, sizeof(buffer), "%s [Leave]", buffer);
					menu.AddItem("-1", buffer);
				}
				else if(PartyLeader[client] == client)
				{
					if(joined)
					{
						IntToString(GetClientUserId(target), index, sizeof(index));
						Format(buffer, sizeof(buffer), "%s [Kick]", buffer);
						menu.AddItem(index, buffer);
					}
					else
					{
						IntToString(GetClientUserId(target), index, sizeof(index));
						Format(buffer, sizeof(buffer), "%s [Pending]", buffer);
						menu.AddItem(index, buffer);
					}
				}
				else if(joined)
				{
					if(PartyLeader[client] == target)
						Format(buffer, sizeof(buffer), "%s [Leader]", buffer);
					
					menu.AddItem("-1", buffer, ITEMDRAW_DISABLED);
				}
			}
		}

		int count = menu.ItemCount;
		menu.SetTitle("RPG Fortress\n \nParty:\n(%d / %d)", count, MAX_PARTY_SIZE);

		if(count < 4 && PartyLeader[client] == client)
		{
			for(int target = 1; target <= MaxClients; target++)
			{
				if(!PartyLeader[target] && !IsInvitedBy(target, client) && IsClientInGame(target) && !IsFakeClient(target) && !IsClientMuted(target, client) && !IsClientMuted(client, target))
				{
					IntToString(GetClientUserId(target), index, sizeof(index));
					GetClientName(target, buffer, sizeof(buffer));
					Format(buffer, sizeof(buffer), "%s [Invite]", buffer);
					menu.AddItem(index, buffer);
				}
			}
		}
	}
	else
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsValidClient(target) && IsInvitedBy(client, target))
			{
				IntToString(GetClientUserId(target), index, sizeof(index));
				GetClientName(target, buffer, sizeof(buffer));
				Format(buffer, sizeof(buffer), "%s [Join]", buffer);
				menu.AddItem(index, buffer);
			}
		}

		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsValidClient(target) && client != target && !PartyLeader[target] && !IsInvitedBy(client, target) && IsClientInGame(target) && !IsFakeClient(target) && !IsClientMuted(target, client) && !IsClientMuted(client, target))
			{
				IntToString(GetClientUserId(target), index, sizeof(index));
				GetClientName(target, buffer, sizeof(buffer));
				Format(buffer, sizeof(buffer), "%s [Invite]", buffer);
				menu.AddItem(index, buffer);
			}
		}

		if(!menu.ItemCount)
			menu.AddItem(index, "No players to invite or join", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Party_MenuHandle(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_ExitBack)
				FakeClientCommandEx(client, "sm_store");
		}
		case MenuAction_Select:
		{
			static char num[16];
			menu.GetItem(choice, num, sizeof(num));

			int target = StringToInt(num);
			if(target != -1)
				target = GetClientOfUserId(target);
			
			if(!target)
			{
				SPrintToChat(client, "Player no longer available");
			}
			else if(PartyLeader[client])
			{
				if(target == -1)
				{
					Party_ClientDisconnect(client);
				}
				else if(PartyLeader[client] == PartyLeader[target])
				{
					PartyLeader[target] = 0;
					SPrintToChat(target, "You were kicked from the party!", client);

					for(int other = 1; other <= MaxClients; other++)
					{
						if(PartyLeader[client] == PartyLeader[other])
							SPrintToChat(other, "%N left the party!", target);
					}
				}
				else if(IsInvitedBy(target, PartyLeader[client]))
				{
					RemoveInvite(target, PartyLeader[client]);
				}
				else
				{
					SPrintToChat(target, "%N invited you to join their party.", client);
					AddInvite(target, PartyLeader[client]);
				}
			}
			else if(IsInvitedBy(client, target))
			{
				PartyLeader[client] = target;

				for(target = 1; target <= MaxClients; target++)
				{
					if(PartyLeader[client] == PartyLeader[target])
						SPrintToChat(target, "%N joined the party!", client);
				}
			}
			else
			{
				SPrintToChat(target, "%N invited you to join their party.", client);

				PartyLeader[client] = client;
				AddInvite(target, client);
			}

			ShowMenu(client);
		}
	}
	return 0;
}