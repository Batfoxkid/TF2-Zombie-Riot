#pragma semicolon 1
#pragma newdecls required

#define ROGUE2_ITEM1	"Rogue2 Item1"
#define ROGUE2_ITEM2	"Rogue2 Item2"
#define ROGUE2_ITEM3	"Rogue2 Item3"

static void GiveCash(int cash)
{
	CurrentCash += cash;
	GlobalExtraCash += cash;
	CPrintToChatAll("{green}%t", "Cash Gained!", cash);
}

public float Rogue_Encounter_MissingMountains()
{
	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_MissingMountains, "Missing Mountains Lore");
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Missing Mountains Option 1");
	strcopy(vote.Desc, sizeof(vote.Desc), "Artifact Config Info");
	strcopy(vote.Config, sizeof(vote.Config), "Peek into the Eternal Night");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Missing Mountains Option 2");
	strcopy(vote.Desc, sizeof(vote.Desc), "Artifact Config Info");
	strcopy(vote.Config, sizeof(vote.Config), "Dead Tree's Echo");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Missing Mountains Option 3");
	strcopy(vote.Desc, sizeof(vote.Desc), "Missing Mountains Desc 3");
	vote.Config[0] = 0;
	list.PushArray(vote);

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_MissingMountains(const Vote vote, int index)
{
	switch(index)
	{
		case 0:
		{
			PrintToChatAll("%t", "Missing Mountains Lore 1");
			Rogue_GiveNamedArtifact(vote.Config);
		}
		case 1:
		{
			PrintToChatAll("%t", "Missing Mountains Lore 2");
			Rogue_GiveNamedArtifact(vote.Config);
		}
		default:
		{
			if(Rogue_GetChaosLevel() > 2)
			{
				PrintToChatAll("%t", "Missing Mountains Lore 3b");
			}
			else
			{
				Rogue_AddIngots(14);
				PrintToChatAll("%t", "Missing Mountains Lore 3a");
			}
		}
	}
}

public float Rogue_Encounter_Clairvoyance()
{
	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_Clairvoyance, "Clairvoyance Lore");
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Clairvoyance Option 1");
	strcopy(vote.Desc, sizeof(vote.Desc), "Artifact Config Info");
	strcopy(vote.Config, sizeof(vote.Config), "Frozen Whetstone");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Clairvoyance Option 2");
	strcopy(vote.Desc, sizeof(vote.Desc), "Artifact Config Info");
	strcopy(vote.Config, sizeof(vote.Config), "Clairvoyant's Reveal");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Clairvoyance Option 3");
	strcopy(vote.Desc, sizeof(vote.Desc), "Unknown Artifact Desc");
	vote.Config[0] = 0;
	list.PushArray(vote);

	if(Rogue_HasNamedArtifact("Waldch Assistance"))
	{
		strcopy(vote.Name, sizeof(vote.Name), "Clairvoyance Option 4");
		strcopy(vote.Desc, sizeof(vote.Desc), "Unknown Artifact Desc");
		vote.Config[0] = 0;
		list.PushArray(vote);
	}

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_Clairvoyance(const Vote vote, int index)
{
	switch(index)
	{
		case 0:
		{
			PrintToChatAll("%t", "Clairvoyance Lore 1");
			Rogue_GiveNamedArtifact(vote.Config);
		}
		case 1:
		{
			PrintToChatAll("%t", "Clairvoyance Lore 2");
			Rogue_GiveNamedArtifact(vote.Config);
		}
		case 3:
		{
			PrintToChatAll("%t", "Clairvoyance Lore 4");

			Artifact artifact;
			if(Rogue_GetRandomArtfiact(artifact, false, 24) != -1)
				Rogue_GiveNamedArtifact(artifact.Name);
		}
		default:
		{
			if(Rogue_GetChaosLevel() > 1)
			{
				PrintToChatAll("%t", "Clairvoyance Lore 3b");
			}
			else
			{
				PrintToChatAll("%t", "Clairvoyance Lore 3a");

				Artifact artifact;
				if(Rogue_GetRandomArtfiact(artifact, false, 24) != -1)
					Rogue_GiveNamedArtifact(artifact.Name);
				
			}
		}
	}
}

public float Rogue_Encounter_Printer()
{
	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_Printer, "Printer Lore");
	Vote vote;

	ArrayList collection = Rogue_GetCurrentCollection();

	if(collection)
	{
		collection = collection.Clone();
		collection.Sort(Sort_Random, Sort_Integer);
		
		Artifact artifact;
		int found;
		int length = collection.Length;
		for(int i; i < length; i++)
		{
			Rogue_GetCurrentArtifacts().GetArray(collection.Get(i), artifact);

			if(artifact.FuncCollect == INVALID_FUNCTION &&
			   artifact.FuncRemove != INVALID_FUNCTION)
			{
				strcopy(vote.Name, sizeof(vote.Name), artifact.Name);
				strcopy(vote.Desc, sizeof(vote.Desc), "Artifact Info");
				strcopy(vote.Config, sizeof(vote.Config), artifact.Name);
				list.PushArray(vote);
				
				if(++found > 2)
					break;
			}
		}

		delete collection;
	}

	strcopy(vote.Name, sizeof(vote.Name), "Printer Option 2");
	strcopy(vote.Desc, sizeof(vote.Desc), "Unknown Artifact Desc");
	vote.Config[0] = 0;
	list.PushArray(vote);

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_Printer(const Vote vote, int index)
{
	if(vote.Config[0])
	{
		if(Rogue_GetChaosLevel() > 3)
		{
			CPrintToChatAll("%t", "Printer Lore 1b", vote.Config);
			Rogue_RemoveNamedArtifact(vote.Config);
			Rogue_AddIngots(30);
		}
		else
		{
			PrintToChatAll("%t", "Printer Lore 1a");
			Rogue_GiveNamedArtifact(vote.Config);
		}
	}
	else
	{
		PrintToChatAll("%t", "Printer Lore 2");

		Artifact artifact;
		if(Rogue_GetRandomArtfiact(artifact, true) != -1)
			Rogue_GiveNamedArtifact(artifact.Name);
	}
}

public float Rogue_Encounter_WishFulfilled()
{
	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_WishFulfilled, "Wish Fulfilled Lore");
	Vote vote;

	Artifact artifact;
	int chaos = Rogue_GetChaosLevel();

	for(int i = 3; i > 0; i--)
	{
		if(chaos > i)
		{
			strcopy(vote.Name, sizeof(vote.Name), "Unknown Artifact");
			strcopy(vote.Desc, sizeof(vote.Desc), "Unknown Artifact Desc");
			vote.Config[0] = 0;
			list.PushArray(vote);
		}
		else if(Rogue_GetRandomArtfiact(artifact, true) != -1)
		{
			strcopy(vote.Name, sizeof(vote.Name), artifact.Name);
			strcopy(vote.Desc, sizeof(vote.Desc), "Artifact Info");
			vote.Config[0] = 1;
			list.PushArray(vote);
		}
	}

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_WishFulfilled(const Vote vote, int index)
{
	if(vote.Config[0])
	{
		Rogue_GiveNamedArtifact(vote.Name);
	}
	else
	{
		Artifact artifact;
		if(Rogue_GetRandomArtfiact(artifact, true) != -1)
			Rogue_GiveNamedArtifact(artifact.Name);
	}
}

public float Rogue_Encounter_Prophecy1()
{
	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_Prophecy1, "Prophecy Lore 1");
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Prophecy Option 1a");
	strcopy(vote.Desc, sizeof(vote.Desc), "Prophecy Desc 1a");
	list.PushArray(vote);

	bool found;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && Items_HasNamedItem(client, ROGUE2_ITEM1))
		{
			found = true;
			break;
		}
	}

	strcopy(vote.Name, sizeof(vote.Name), "Prophecy Option 1b");
	strcopy(vote.Desc, sizeof(vote.Desc), "Prophecy Desc 1b");
	if(!found)
	{
		vote.Locked = true;
		strcopy(vote.Append, sizeof(vote.Append), " (???)");
	}
	list.PushArray(vote);

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_Prophecy1(const Vote vote, int index)
{
	if(index)
	{
		PrintToChatAll("%t", "Prophecy Lore 1b");
		Rogue_GiveNamedArtifact("Waldch Assistance", true);
	}
	else
	{
		PrintToChatAll("%t", "Prophecy Lore 1a");
	}
}

public float Rogue_Encounter_Prophecy2()
{
	bool waldch = Rogue_HasNamedArtifact("Waldch Assistance");
	bool kalm;
	if(waldch)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && GetClientTeam(client) == 2 && Items_HasNamedItem(client, ROGUE2_ITEM2))
			{
				kalm = true;
				break;
			}
		}
	}

	Vote vote;

	if(kalm)
	{
		ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_Prophecy2, "Prophecy Lore 3");

		strcopy(vote.Name, sizeof(vote.Name), "Prophecy Option 3a");
		strcopy(vote.Desc, sizeof(vote.Desc), "Prophecy Desc 3a");
		list.PushArray(vote);

		strcopy(vote.Name, sizeof(vote.Name), "Prophecy Option 3b");
		strcopy(vote.Desc, sizeof(vote.Desc), "Prophecy Desc 3b");
		vote.Config[0] = 1;
		list.PushArray(vote);
	}
	else
	{
		ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_Prophecy2, "Prophecy Lore 2");

		strcopy(vote.Name, sizeof(vote.Name), "Prophecy Option 2a");
		strcopy(vote.Desc, sizeof(vote.Desc), "Prophecy Desc 2a");
		list.PushArray(vote);

		strcopy(vote.Name, sizeof(vote.Name), "Prophecy Option 2b");
		strcopy(vote.Desc, sizeof(vote.Desc), "Prophecy Desc 2b");
		vote.Locked = waldch;
		list.PushArray(vote);

		strcopy(vote.Name, sizeof(vote.Name), "Prophecy Option 2c");
		strcopy(vote.Desc, sizeof(vote.Desc), "Prophecy Desc 2c");
		vote.Locked = waldch;
		list.PushArray(vote);
	}

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_Prophecy2(const Vote vote, int index)
{
	if(vote.Config[0])
	{
		//Rogue_RemoveNamedArtifact("Waldch Assistance");
		Rogue_GiveNamedArtifact("Kahmlstein Guidance");

		Rogue_RemoveChaos(50);
	}
	else
	{
		switch(index)
		{
			case 0:
			{
				PrintToChatAll("%t", "Prophecy Lore 2a");
				Rogue_RemoveChaos(20);
			}
			case 1:
			{
				PrintToChatAll("%t", "Prophecy Lore 2b");
				Rogue_AddChaos(20);
				Store_RandomizeNPCStore(2, 10);
			}
			case 2:
			{
				PrintToChatAll("%t", "Prophecy Lore 2c");
				Rogue_AddChaos(20);
				GiveCash(4000);
			}
		}
	}
}

public float Rogue_Encounter_LostVillager()
{
	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_LostVillager, "Lost Villager Lore");
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Lost Villager Option 2");
	strcopy(vote.Desc, sizeof(vote.Desc), "Lost Villager Desc 2");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Lost Villager Option 1");
	strcopy(vote.Desc, sizeof(vote.Desc), "Lost Villager Desc 1");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Lost Villager Option 3");
	strcopy(vote.Desc, sizeof(vote.Desc), "Lost Villager Desc 3");
	list.PushArray(vote);

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_LostVillager(const Vote vote, int index)
{
	if(vote.Config[0])
	{
		switch(index)
		{
			case 0:
			{
				PrintToChatAll("%t", "Lost Villager Lore 1a");
				Store_RandomizeNPCStore(2, 4);
			}
			case 1:
			{
				PrintToChatAll("%t", "Lost Villager Lore 1b");
				Rogue_AddIngots(15);
			}
			case 2:
			{
				PrintToChatAll("%t", "Lost Villager Lore 1c");
				Rogue_RemoveChaos(15);
			}
		}
	}
	else
	{
		switch(index)
		{
			case 0:
			{
				PrintToChatAll("%t", "Lost Villager Lore 2");
				GiveCash(2000);
			}
			case 1:
			{
				PrintToChatAll("%t", "Lost Villager Lore 1");
				
				ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_LostVillager, "Lost Villager Lore 1");
				Vote vote2;
				vote2.Config[0] = 1;

				strcopy(vote2.Name, sizeof(vote2.Name), "Lost Villager Option 1a");
				strcopy(vote2.Desc, sizeof(vote2.Desc), "Lost Villager Desc 1a");
				list.PushArray(vote2);

				strcopy(vote2.Name, sizeof(vote2.Name), "Lost Villager Option 1b");
				strcopy(vote2.Desc, sizeof(vote2.Desc), "Lost Villager Desc 1b");
				list.PushArray(vote2);

				strcopy(vote2.Name, sizeof(vote2.Name), "Lost Villager Option 1c");
				strcopy(vote2.Desc, sizeof(vote2.Desc), "Lost Villager Desc 1c");
				list.PushArray(vote2);

				Rogue_StartGenericVote(20.0);
			}
			case 2:
			{
				PrintToChatAll("%t", "Lost Villager Lore 3");
				Rogue_AddChaos(15);
				GiveCash(2000);
				Rogue_AddIngots(15);
				Store_RandomizeNPCStore(2, 4);
			}
		}
	}
}

public float Rogue_Encounter_DowntimeRecreation()
{
	GiveCash(4000);

	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_DowntimeRecreation, "Downtime Recreation Lore");
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Downtime Recreation Option 2");
	strcopy(vote.Desc, sizeof(vote.Desc), "Leave this encounter");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Downtime Recreation Option 1");
	strcopy(vote.Desc, sizeof(vote.Desc), "Downtime Recreation Desc 1");
	vote.Locked = Rogue_GetIngots() < 4;
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Downtime Recreation Option 3");
	strcopy(vote.Desc, sizeof(vote.Desc), "Downtime Recreation Desc 3");
	list.PushArray(vote);

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
static void DowntimeRecreation(const char[] title)
{
	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_DowntimeRecreation, title);
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Downtime Recreation Option 2b");
	strcopy(vote.Desc, sizeof(vote.Desc), "Leave this encounter");
	list.PushArray(vote);

	strcopy(vote.Name, sizeof(vote.Name), "Downtime Recreation Option 1");
	strcopy(vote.Desc, sizeof(vote.Desc), "Downtime Recreation Desc 1");
	vote.Locked = Rogue_GetIngots() < 4;
	list.PushArray(vote);

	Rogue_StartGenericVote(10.0);
}
public void Rogue_Vote_DowntimeRecreation(const Vote vote, int index)
{
	switch(index)
	{
		case 0:
		{
			PrintToChatAll("%t", "Downtime Recreation Lore 2");
		}
		case 1:
		{
			char title;
			switch(GetURandomInt() % 19)
			{
				case 0, 1, 2, 3:
				{
					Rogue_AddIngots(2);
					title = 'b';
				}
				case 4, 5, 6:
				{
					Rogue_AddIngots(-4);
					Store_RandomizeNPCStore(2, 1);
					title = 'e';
				}
				case 7, 8:
				{
					Rogue_AddIngots(-4);

					Artifact artifact;
					if(Rogue_GetRandomArtfiact(artifact, true) != -1)
						Rogue_GiveNamedArtifact(artifact.Name);
					
					title = 'c';
				}
				case 9:
				{
					Rogue_AddIngots(26);
					PrintToChatAll("%t", "Downtime Recreation Lore 1d");
					return;
				}
				default:
				{
					title = 'a';
				}
			}

			char buffer[64];
			FormatEx(buffer, sizeof(buffer), "Downtime Recreation Lore 1%c", title);
			DowntimeRecreation(buffer);
		}
		case 2:
		{
			PrintToChatAll("%t", "Downtime Recreation Lore 3");
			Rogue_AddChaos(15);
			Rogue_AddIngots(30);
		}
	}
}

public float Rogue_Encounter_FortituousOpportunity()
{
	GiveCash(4000);

	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_FortituousOpportunity, "Fortituous Opportunity Lore");
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Fortituous Opportunity Option 2");
	strcopy(vote.Desc, sizeof(vote.Desc), "Fortituous Opportunity Desc 2");
	vote.Config[0] = 0;
	list.PushArray(vote);

	ArrayList collection = Rogue_GetCurrentCollection();

	if(collection)
	{
		collection = collection.Clone();
		collection.Sort(Sort_Random, Sort_Integer);
		
		Artifact artifact;
		int found;
		int length = collection.Length;
		for(int i; i < length; i++)
		{
			Rogue_GetCurrentArtifacts().GetArray(collection.Get(i), artifact);

			if(artifact.FuncCollect == INVALID_FUNCTION &&
			   artifact.FuncRemove != INVALID_FUNCTION)
			{
				strcopy(vote.Name, sizeof(vote.Name), artifact.Name);
				strcopy(vote.Desc, sizeof(vote.Desc), "Artifact Info");
				strcopy(vote.Config, sizeof(vote.Config), artifact.Name);
				list.PushArray(vote);
				
				if(++found > 2)
					break;
			}
		}

		delete collection;
	}

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_FortituousOpportunity(const Vote vote, int index)
{
	if(vote.Config[0])
	{
		CPrintToChatAll("%t", "Fortituous Opportunity Lore 1", vote.Config);
		Rogue_RemoveNamedArtifact(vote.Config);
		
		Artifact artifact;
		if(Rogue_GetRandomArtfiact(artifact, true) != -1)
			Rogue_GiveNamedArtifact(artifact.Name);
	}
	else
	{
		PrintToChatAll("%t", "Fortituous Opportunity Lore 2");
		Rogue_AddIngots(4);
	}
}

static bool HasSent;
static int SentUser1 = -1;
static int SentUser2 = -1;
public float Rogue_Encounter_EmergencyDispatch()
{
	GiveCash(4000);

	ArrayList list = Rogue_CreateGenericVote(Rogue_Vote_EmergencyDispatch, "Emergency Dispatch Lore");
	Vote vote;

	strcopy(vote.Name, sizeof(vote.Name), "Emergency Dispatch Option 2");
	strcopy(vote.Desc, sizeof(vote.Desc), "Emergency Dispatch Desc 2");
	list.PushArray(vote);

	int count;
	int[] players = new int[MaxClients];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!b_IsPlayerABot[client] && b_HasBeenHereSinceStartOfWave[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && TeutonType[client] != TEUTON_WAITING)
		{
			players[count++] = client;
		}
	}
	
	if(count < 5)
	{
		strcopy(vote.Name, sizeof(vote.Name), "Emergency Dispatch Option 1");
		strcopy(vote.Desc, sizeof(vote.Desc), "Emergency Dispatch Desc 1a");
		strcopy(vote.Append, sizeof(vote.Append), "Bob The Second");
		vote.Config[0] = -1;
		vote.Config[1] = -1;
		list.PushArray(vote);
	}
	else
	{
		int pos;
		SortIntegers(players, count, Sort_Random);

		strcopy(vote.Name, sizeof(vote.Name), "Emergency Dispatch Option 1");
		strcopy(vote.Desc, sizeof(vote.Desc), "Emergency Dispatch Desc 1b");

		for(int i; i < 3; i++)
		{
			int client1 = players[pos++];
			int client2 = players[pos++];
			
			if(count > (6 + (i*3)))
			{
				Format(vote.Append, sizeof(vote.Append), " %N and %N", client1, client2);
				vote.Config[0] = GetClientUserId(client1);
				vote.Config[1] = GetClientUserId(client2);
			}
			else
			{
				Format(vote.Append, sizeof(vote.Append), " %N", client1);
				vote.Config[0] = GetClientUserId(client1);
				vote.Config[1] = -1;
			}

			list.PushArray(vote);
		}
	}

	Rogue_StartGenericVote(20.0);

	return 30.0;
}
public void Rogue_Vote_EmergencyDispatch(const Vote vote, int index)
{
	if(index)
	{
		int client1 = GetClientOfUserId(vote.Config[0]);
		int client2 = GetClientOfUserId(vote.Config[1]);

		if(!client1 && client2)
		{
			client1 = client2;
			client2 = 0;
		}

		if(client2)
		{
			CPrintToChatAll("%t", "Emergency Dispatch Lore 1b", client1, client2);
			TF2_RespawnPlayer(client1);
			TF2_RespawnPlayer(client2);
		}
		else if(client1)
		{
			CPrintToChatAll("%t", "Emergency Dispatch Lore 1a", client1);
			TF2_RespawnPlayer(client1);
		}
		else
		{
			CPrintToChatAll("%t", "Emergency Dispatch Lore 1c");
		}

		SentUser1 = client1 ? GetClientUserId(client1) : -1;
		SentUser2 = client2 ? GetClientUserId(client2) : -1;
		HasSent = true;
	}
	else
	{
		PrintToChatAll("%t", "Emergency Dispatch Lore 2");
		GiveCash((Rogue_GetFloor() + 1) * 1000);
	}
}
public bool Rogue_BlueParadox_CanTeutonUpdate(int client)
{
	if(HasSent)
	{
		int userid = GetClientUserId(client);
		if(SentUser1 == userid || SentUser2 == userid)
		{
			TeutonType[client] = TEUTON_DEAD;
			return false;
		}
	}

	return true;
}
public void Rogue_BlueParadox_NewFloor(int floor)
{
	if(HasSent)
	{
		int client1 = GetClientOfUserId(SentUser1);
		int client2 = GetClientOfUserId(SentUser2);

		if(!client1 && client2)
		{
			client1 = client2;
			client2 = 0;
		}

		GiveCash(1000 * floor);

		if(client2)
		{
			CPrintToChatAll("%t", "Emergency Dispatch Return 2", client1, client2);

			TF2_RespawnPlayer(client1);
			CPrintToChat(client1, "{green}%t", "Credits_Menu_New", 2000 * floor);
			CashRecievedNonWave[client1] += 2000 * floor;
			CashSpent[client1] -= 2000 * floor;

			TF2_RespawnPlayer(client2);
			CPrintToChat(client2, "{green}%t", "Credits_Menu_New", 2000 * floor);
			CashRecievedNonWave[client2] += 2000 * floor;
			CashSpent[client2] -= 2000 * floor;
		}
		else if(client1)
		{
			CPrintToChatAll("%t", "Emergency Dispatch Return 1", client1);

			TF2_RespawnPlayer(client1);
			CPrintToChat(client1, "{green}%t", "Credits_Menu_New", 2000 * floor);
			CashRecievedNonWave[client1] += 2000 * floor;
			CashSpent[client1] -= 2000 * floor;
		}
		else
		{
			CPrintToChatAll("%t", "Emergency Dispatch Return 3");

			Rogue_GiveIngots(5);
		}
	}
}
public void Rogue_BlueParadox_Reset()
{
	HasSent = false;
}