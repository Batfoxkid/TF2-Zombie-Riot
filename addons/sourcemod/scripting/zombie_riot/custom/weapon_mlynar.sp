#pragma semicolon 1
#pragma newdecls required

#define MYLNAR_RANGE_AGGRO_GAIN 100.0
#define MYLNAR_RANGE_ATTACK 250.0
#define MYLNAR_MAX_CHARGE_TIME 50.0

#define MYLNAR_MAXANGLEPITCH	90.0
#define MYLNAR_MAXANGLEYAW		90.0

Handle h_TimerMlynarManagement[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
static float f_MlynarHudDelay[MAXTF2PLAYERS];
static float f_MlynarDmgMultiPassive[MAXTF2PLAYERS] = {1.0, ...};
static float f_MlynarDmgMultiAgressiveClose[MAXTF2PLAYERS] = {1.0, ...};
static float f_MlynarDmgMultiHurt[MAXTF2PLAYERS] = {1.0, ...};
static float f_MlynarAbilityActiveTime[MAXTF2PLAYERS];
static bool b_MlynarResetStats[MAXTF2PLAYERS];
int HitEntitiesSphereMlynar[MAXENTITIES];
int i_MlynarMaxDamageGetFromSameEnemy[MAXENTITIES];
static float f_MlynarHurtDuration[MAXTF2PLAYERS];

//This will be used to tone down damage over time/on kill
static float f_MlynarDmgAfterAbility[MAXTF2PLAYERS];

void Mlynar_Map_Precache() //Anything that needs to be precaced like sounds or something.
{
	Zero(f_MlynarHudDelay);
	for(int i=1; i<=MaxClients; i++)
	{
		f_MlynarDmgMultiPassive[i] = 1.0;
		f_MlynarDmgMultiAgressiveClose[i] = 1.0;
		f_MlynarDmgMultiHurt[i] = 1.0;
		f_MlynarDmgAfterAbility[i] = 1.0;
	}
	Zero(f_MlynarAbilityActiveTime);
	Zero(b_MlynarResetStats);
}

void Reset_stats_Mlynar_Global()
{
	Zero(f_MlynarHudDelay);
}
void Mlynar_EntityCreated(int entity) 
{
	i_MlynarMaxDamageGetFromSameEnemy[entity] = 0;
}
void Reset_stats_Mlynar_Singular(int client) //This is on disconnect/connect
{
	if (h_TimerMlynarManagement[client] != INVALID_HANDLE)
	{
		KillTimer(h_TimerMlynarManagement[client]);
	}	
	h_TimerMlynarManagement[client] = INVALID_HANDLE;
	f_MlynarDmgMultiPassive[client] = 1.0;
	f_MlynarDmgMultiAgressiveClose[client] = 1.0;
	f_MlynarDmgMultiHurt[client] = 1.0;
	f_MlynarDmgAfterAbility[client] = 1.0;
	f_MlynarAbilityActiveTime[client] = 0.0;
	b_MlynarResetStats[client] = false;
}
public void Weapon_MlynarAttack(int client, int weapon, bool &result, int slot)
{
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(EntIndexToEntRef(weapon));
	RequestFrames(Weapon_MlynarAttack_Internal, 12, pack);
}
public void Mylnar_DeleteLaserAndParticle(DataPack pack)
{
	pack.Reset();
	int Projectile = EntRefToEntIndex(pack.ReadCell());
	int Laser = EntRefToEntIndex(pack.ReadCell());
	if(IsValidEntity(Projectile))
	{
		int particle = EntRefToEntIndex(i_WandParticle[Projectile]);
		if(IsValidEntity(particle))
			RemoveEntity(particle);
		
		RemoveEntity(Projectile);
	}
	if(Projectile != Laser)
	{
		if(IsValidEntity(Laser))
			RemoveEntity(Laser);
	}
	delete pack;
}
public void Weapon_MlynarAttack_Internal(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(IsValidClient(client) && IsValidCurrentWeapon(client, weapon))
	{
		//This melee is too unique, we have to code it in a different way.
		static float pos2[3], ang2[3];
		GetClientEyePosition(client, pos2);
		GetClientEyeAngles(client, ang2);
		/*
			Extra effects on bare swing
		*/
		static float AngEffect[3];
		AngEffect = ang2;

		AngEffect[1] -= 90.0;
		int MaxRepeats = 4;
		float Speed = 1500.0;
		int PreviousProjectile;
		for(int repeat; repeat <= MaxRepeats; repeat ++)
		{
			int projectile = Wand_Projectile_Spawn(client, Speed, 99999.9, 0.0, -1, weapon, "", AngEffect);
			DataPack pack2 = new DataPack();
			int laser = projectile;
			if(IsValidEntity(PreviousProjectile))
			{
				laser = ConnectWithBeam(projectile, PreviousProjectile, 255, 255, 0, 10.0, 10.0, 1.0);
			}
			SetEntityMoveType(projectile, MOVETYPE_NOCLIP);
			PreviousProjectile = projectile;
			pack2.WriteCell(EntIndexToEntRef(projectile));
			pack2.WriteCell(EntIndexToEntRef(laser));
			RequestFrames(Mylnar_DeleteLaserAndParticle, 18, pack2);
			AngEffect[1] += (180.0 / float(MaxRepeats));
		}

		float vecSwingForward[3];
		GetAngleVectors(ang2, vecSwingForward, NULL_VECTOR, NULL_VECTOR);
		ang2[0] = fixAngle(ang2[0]);
		ang2[1] = fixAngle(ang2[1]);
		
		float damage = 65.0;
		
		Address address = TF2Attrib_GetByDefIndex(weapon, 1);
		if(address != Address_Null)
			damage *= TF2Attrib_GetValue(address);

		address = TF2Attrib_GetByDefIndex(weapon, 2);
		if(address != Address_Null)
			damage *= TF2Attrib_GetValue(address);	
			
		address = TF2Attrib_GetByDefIndex(weapon, 476);
		if(address != Address_Null)
			damage *= TF2Attrib_GetValue(address);	


		damage *= f_MlynarDmgMultiPassive[client];
		damage *= f_MlynarDmgMultiAgressiveClose[client];
		damage *= f_MlynarDmgMultiHurt[client];

		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(client);
			
		for(int i=0; i < MAXENTITIES; i++)
		{
			HitEntitiesSphereMlynar[i] = false;
		}
		TR_EnumerateEntitiesSphere(pos2, MYLNAR_RANGE_ATTACK, PARTITION_NON_STATIC_EDICTS, TraceEntityEnumerator_Mlynar, client);

	//	bool Hit = false;
		for (int entity_traced = 0; entity_traced < MAXENTITIES; entity_traced++)
		{
			if (HitEntitiesSphereMlynar[entity_traced] > 0)
			{
				static float ang3[3];

				float pos1[3];
				pos1 = WorldSpaceCenter(HitEntitiesSphereMlynar[entity_traced]);
				GetVectorAnglesTwoPoints(pos2, pos1, ang3);

				// fix all angles
				ang3[0] = fixAngle(ang3[0]);
				ang3[1] = fixAngle(ang3[1]);

				// verify angle validity
				if(!(fabs(ang2[0] - ang3[0]) <= MYLNAR_MAXANGLEPITCH ||
				(fabs(ang2[0] - ang3[0]) >= (360.0-MYLNAR_MAXANGLEPITCH))))
					continue;

				if(!(fabs(ang2[1] - ang3[1]) <= MYLNAR_MAXANGLEYAW ||
				(fabs(ang2[1] - ang3[1]) >= (360.0-MYLNAR_MAXANGLEYAW))))
					continue;

				// ensure no wall is obstructing
				if(Can_I_See_Enemy_Only(client, HitEntitiesSphereMlynar[entity_traced]))
				{
					// success
			//		Hit = true;
					SDKHooks_TakeDamage(HitEntitiesSphereMlynar[entity_traced], client, client, damage, DMG_CLUB, weapon, CalculateDamageForce(vecSwingForward, 100000.0), pos1);
					EmitSoundToAll("weapons/halloween_boss/knight_axe_hit.wav", HitEntitiesSphereMlynar[entity_traced],_ ,_ ,_ ,0.75);
				}
			}
			else
			{
				break;
			}
		}
	}
	FinishLagCompensation_Base_boss();
	delete pack;
}
public void Weapon_MlynarAttackM2(int client, int weapon, bool &result, int slot)
{
	//This melee is too unique, we have to code it in a different way.
	if (Ability_Check_Cooldown(client, slot) < 0.0 || CvarInfiniteCash.BoolValue)
	{
		Rogue_OnAbilityUse(client, weapon);
		Ability_Apply_Cooldown(client, slot, MYLNAR_MAX_CHARGE_TIME);
		f_MlynarAbilityActiveTime[client] = GetGameTime() + 15.0;
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0.0);
		b_MlynarResetStats[client] = true;
	}
	else
	{
		float Ability_CD = Ability_Check_Cooldown(client, slot);
		
		if(Ability_CD <= 0.0)
			Ability_CD = 0.0;
			
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
	}
}

public void Enable_Mlynar(int client, int weapon) 
{
	if (h_TimerMlynarManagement[client] != INVALID_HANDLE)
	{
		//This timer already exists.
		if(i_CustomWeaponEquipLogic[weapon] == WEAPON_MLYNAR) 
		{
			//Is the weapon it again?
			//Yes?
			KillTimer(h_TimerMlynarManagement[client]);
			h_TimerMlynarManagement[client] = INVALID_HANDLE;
			DataPack pack;
			h_TimerMlynarManagement[client] = CreateDataTimer(0.1, Timer_Management_Mlynar, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(client);
			pack.WriteCell(EntIndexToEntRef(weapon));
		}
		return;
	}
		
	if(i_CustomWeaponEquipLogic[weapon] == WEAPON_MLYNAR) //9 Is for Passanger
	{
		DataPack pack;
		h_TimerMlynarManagement[client] = CreateDataTimer(0.1, Timer_Management_Mlynar, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(client);
		pack.WriteCell(EntIndexToEntRef(weapon));
	}
}



public Action Timer_Management_Mlynar(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if(IsValidClient(client))
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				Mlynar_Cooldown_Logic(client, EntRefToEntIndex(pack.ReadCell()));
			}
			else
				Kill_Timer_Mlynar(client);
		}
		else
			Kill_Timer_Mlynar(client);
	}
	else
		Kill_Timer_Mlynar(client);
		
	return Plugin_Continue;
}

public void Mlynar_Cooldown_Logic(int client, int weapon)
{
	if (!IsValidMulti(client))
		return;
		
	if(IsValidEntity(weapon))
	{
		if(i_CustomWeaponEquipLogic[weapon] == WEAPON_MLYNAR)
		{
			int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon_holding == weapon) //Only show if the weapon is actually in your hand right now.
			{
				//Give power overtime.
				if(f_MlynarAbilityActiveTime[client] < GetGameTime())
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 99999.9);
					if(b_MlynarResetStats[client])
					{
						f_MlynarDmgMultiPassive[client] = 1.0;
						f_MlynarDmgMultiAgressiveClose[client] = 1.0;
						f_MlynarDmgMultiHurt[client] = 1.0;
						f_MlynarDmgAfterAbility[client] = 1.0;
					}
					b_MlynarResetStats[client] = false;
					f_MlynarDmgMultiPassive[client] += 0.0015;
					if(f_MlynarDmgMultiPassive[client] > 2.0)
					{
						f_MlynarDmgMultiPassive[client] = 2.0;
					}
					float ClientPos[3];
					ClientPos = WorldSpaceCenter(client);
					//we have atleast one enemy near us, more do not equal more strength
					//but the same enemy cannot give a huge amount of power over time.
					for(int i=0; i < MAXENTITIES; i++)
					{
						HitEntitiesSphereMlynar[i] = false;
					}
					TR_EnumerateEntitiesSphere(ClientPos, MYLNAR_RANGE_AGGRO_GAIN, PARTITION_NON_STATIC_EDICTS, TraceEntityEnumerator_Mlynar, client);

					int GatherPower = 0;
					for (int entity_traced = 0; entity_traced < MAXENTITIES; entity_traced++)
					{
						if (HitEntitiesSphereMlynar[entity_traced] > 0)
						{
							//do not get power from the same enemy more then 5 times. unless its a boss or raid, then allow more.
							if(b_thisNpcIsARaid[entity_traced])
							{
								//There is no limit to how often you can gather power from a raid.
								GatherPower += 5;
							}
							else if (b_thisNpcIsABoss[entity_traced] && i_MlynarMaxDamageGetFromSameEnemy[entity_traced] < 400)
							{
								i_MlynarMaxDamageGetFromSameEnemy[entity_traced] += 1;
								GatherPower += 2;
							}
							else if(i_MlynarMaxDamageGetFromSameEnemy[entity_traced] < 100)
							{
								i_MlynarMaxDamageGetFromSameEnemy[entity_traced] += 1;
								GatherPower += 1;
							}
						}
						else
							break;
					}
					if(GatherPower > 0)
					{
						//we can gather power from upto 5 enemies at once, the more the faster.
						if(GatherPower > 5)
						{
							GatherPower = 5;
						}
						f_MlynarDmgMultiAgressiveClose[client] += (0.0015 * float(GatherPower));
						if(f_MlynarDmgMultiAgressiveClose[client] > 3.0)
						{
							f_MlynarDmgMultiAgressiveClose[client] = 3.0;
						}
					}
					//if the client was hurt by an enemy presumeably, then give extra power.
					if(f_MlynarHurtDuration[client] > GetGameTime())
					{
						f_MlynarDmgMultiHurt[client] += 0.005;
						if(IsValidEntity(EntRefToEntIndex(RaidBossActive))) //During raids, give power 2x as fast.
						{
							f_MlynarDmgMultiHurt[client] += 0.005;
						}
						if(f_MlynarDmgMultiHurt[client] > 3.0)
						{
							f_MlynarDmgMultiHurt[client] = 3.0;
						}
					}
				}

				if(f_MlynarHudDelay[client] < GetGameTime())
				{
					float cooldown = Ability_Check_Cooldown(client, 2);
					if(cooldown > 0.0)
					{
						PrintHintText(client,"Unbrilliant Glory [%.1f/%.1f]\nPower Gain: [%.1f％|%.1f％|%.1f％]", cooldown, MYLNAR_MAX_CHARGE_TIME, (f_MlynarDmgMultiPassive[client] - 1.0) * 100.0, (f_MlynarDmgMultiAgressiveClose[client] - 1.0) * 100.0, (f_MlynarDmgMultiHurt[client] - 1.0) * 100.0);	
					}
					else
					{
						PrintHintText(client,"Unbrilliant Glory [READY]\nPower Gain: [%.1f％|%.1f％|%.1f％]", (f_MlynarDmgMultiPassive[client] - 1.0) * 100.0, (f_MlynarDmgMultiAgressiveClose[client] - 1.0) * 100.0, (f_MlynarDmgMultiHurt[client] - 1.0) * 100.0);	
					}
					StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
					f_MlynarHudDelay[client] = GetGameTime() + 0.5;
				}
			}
		}
		else
		{
			Kill_Timer_Mlynar(client);
		}
	}
	else
	{
		Kill_Timer_Mlynar(client);
	}
}

public void Kill_Timer_Mlynar(int client)
{
	if (h_TimerMlynarManagement[client] != INVALID_HANDLE)
	{
		KillTimer(h_TimerMlynarManagement[client]);
		h_TimerMlynarManagement[client] = INVALID_HANDLE;
	}
}

public bool TraceEntityEnumerator_Mlynar(int entity, int filterentity)
{
	if(IsValidEnemy(filterentity, entity, true, true)) //Must detect camo.
	{
		//This will automatically take care of all the checks, very handy. force it to also target invul enemies.
		for(int i=0; i < MAXENTITIES; i++)
		{
			if(!HitEntitiesSphereMlynar[i])
			{
				HitEntitiesSphereMlynar[i] = entity;
				break;
			}
		}
	}
	//always keep going!
	return true;
}


public float Player_OnTakeDamage_Mlynar(int victim, float &damage, int attacker, int weapon, float damagePosition[3])
{
	f_MlynarHurtDuration[victim] = GetGameTime() + 0.5;
	//insert reflect code.
	return damage;
}


