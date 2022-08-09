static float ability_cooldown[MAXPLAYERS+1]={0.0, ...};

static int client_slammed_how_many_times[MAXTF2PLAYERS];
static int client_slammed_how_many_times_limit[MAXTF2PLAYERS];
static float client_slammed_pos[MAXTF2PLAYERS][3];
static float client_slammed_forward[MAXTF2PLAYERS][3];
static float client_slammed_right[MAXTF2PLAYERS][3];
static float f_OriginalDamage[MAXTF2PLAYERS];

public void Wand_Elemental_2_ClearAll()
{
	Zero(ability_cooldown);
}
#define spirite "spirites/zerogxplode.spr"

#define EarthStyleShockwaveRange 250.0
void Wand_Elemental_2_Map_Precache()
{
	PrecacheSound("ambient/explosions/explode_3.wav", true);
	PrecacheSound("weapons/physcannon/energy_sing_flyby2.wav", true);
	PrecacheSound("ambient/atmosphere/terrain_rumble1.wav", true);
	PrecacheSound("ambient/explosions/explode_9.wav", true);
}

public void Weapon_Elemental_Wand_2(int client, int weapon, bool crit, int slot)
{
	if(weapon >= MaxClients)
	{
		int mana_cost = 350;
		if(mana_cost <= Current_Mana[client])
		{
			if (Ability_Check_Cooldown(client, slot) < 0.0)
			{
				Ability_Apply_Cooldown(client, slot, 15.0);
				Current_Mana[client] -= mana_cost;
				float damage = 160.0;
				Address	address = TF2Attrib_GetByDefIndex(weapon, 410);
				if(address != Address_Null)
					damage *= TF2Attrib_GetValue(address);
					
				f_OriginalDamage[client] = damage;
				client_slammed_how_many_times_limit[client] = 5;
				client_slammed_how_many_times[client] = 0;
				float vecUp[3];
				
				GetVectors(client, client_slammed_forward[client], client_slammed_right[client], vecUp); //Sorry i dont know any other way with this :(
				client_slammed_pos[client] = GetAbsOrigin(client);
				client_slammed_pos[client][2] += 5.0;
				
				float vecSwingEnd[3];
				vecSwingEnd[0] = client_slammed_pos[client][0] + client_slammed_forward[client][0] * (1 * client_slammed_how_many_times[client]);
				vecSwingEnd[1] = client_slammed_pos[client][1] + client_slammed_forward[client][1] * (1 * client_slammed_how_many_times[client]);
				vecSwingEnd[2] = client_slammed_pos[client][2] + client_slammed_forward[client][2] * 100;
				
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vecUp);
				
				
				DataPack pack = new DataPack();
				pack.WriteFloat(vecUp[0]);
				pack.WriteFloat(vecUp[1]);
				pack.WriteFloat(vecUp[2]);
				RequestFrame(MakeExplosionFrameLater, pack);
				
				Explode_Logic_Custom(damage, client, client, weapon,vecUp,_,_,_,false);
			
				CreateTimer(0.1, shockwave_explosions, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
			else
			{
				float Ability_CD = Ability_Check_Cooldown(client, slot);
		
				if(Ability_CD <= 0.0)
					Ability_CD = 0.0;
			
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
			}
		}
		else
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
		}
	}
}

public Action shockwave_explosions(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		client_slammed_how_many_times[client] += 1;
		
		float vecSwingEnd[3];
		vecSwingEnd[0] = client_slammed_pos[client][0] + client_slammed_forward[client][0] * (90 * client_slammed_how_many_times[client]);
		vecSwingEnd[1] = client_slammed_pos[client][1] + client_slammed_forward[client][1] * (90 * client_slammed_how_many_times[client]);
		vecSwingEnd[2] = client_slammed_pos[client][2] + client_slammed_forward[client][2] * 100;
		
		int ent = CreateEntityByName("env_explosion");
		if(ent != -1)
		{
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
									
			EmitAmbientSound("ambient/explosions/explode_9.wav", vecSwingEnd);
							
			DispatchKeyValueVector(ent, "origin", vecSwingEnd);
			DispatchKeyValue(ent, "spawnflags", "64");
			
			DispatchKeyValue(ent, "rendermode", "5");
			DispatchKeyValue(ent, "fireballsprite", spirite);
							
			SetEntProp(ent, Prop_Data, "m_iMagnitude", 0); 
			SetEntProp(ent, Prop_Data, "m_iRadiusOverride", 200); 
						
			DispatchSpawn(ent);
			ActivateEntity(ent);
						
			AcceptEntityInput(ent, "explode");
			AcceptEntityInput(ent, "kill");
			Explode_Logic_Custom(f_OriginalDamage[client], client, client, -1, vecSwingEnd,_,_,_,false);
		}
		if(client_slammed_how_many_times[client] > client_slammed_how_many_times_limit[client])
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}