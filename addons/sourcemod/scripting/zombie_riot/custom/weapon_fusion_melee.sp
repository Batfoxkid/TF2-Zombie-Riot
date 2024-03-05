#pragma semicolon 1
#pragma newdecls required

#define EMPOWER_RANGE 200.0
static Handle h_TimerFusionWeaponManagement[MAXPLAYERS+1] = {null, ...};
#define NEARL_ACTIVE_SOUND "mvm/mvm_tele_activate.wav"
#define NEARL_EXTRA_DAMAGE_SOUND "misc/ks_tier_04_kill_01.wav"
#define NEARL_STUN_RANGE 200.0

#define SICCERINO_FAST_ATTACK_SOUND "items/powerup_pickup_agility.wav"
#define SICCERINO_PREPARE_SICCORS_SOUND "mvm/mvm_tele_activate.wav"
#define SICCERINO_DEBUFF_FADE 6.5
static const char g_Siccerino_snapSound[][] = {
	"physics/metal/sawblade_stick1.wav",
	"physics/metal/sawblade_stick2.wav",
	"physics/metal/sawblade_stick3.wav",
};

static float f_AniSoundSpam[MAXTF2PLAYERS];
static float Duration[MAXTF2PLAYERS];
static int Weapon_Id[MAXTF2PLAYERS];

static float f_NearlDurationCheckApply[MAXTF2PLAYERS];
static float f_NearlThinkDelay[MAXTF2PLAYERS];
static int i_NearlWeaponUsedWith[MAXTF2PLAYERS];

static float f_SpeedFistsOfSpeed[MAXTF2PLAYERS];
static int i_SpeedFistsOfSpeedHit[MAXTF2PLAYERS];
static int i_PreviousBladePap[MAXTF2PLAYERS];

static float f_SiccerinoExtraDamage[MAXTF2PLAYERS][MAXENTITIES];

public void Fusion_Melee_OnMapStart()
{
	for (int i = 0; i < (sizeof(g_Siccerino_snapSound));	i++) { PrecacheSound(g_Siccerino_snapSound[i]);	}
	Zero(Duration);
	Zero(Weapon_Id);
	Zero(f_AniSoundSpam);
	PrecacheSound(EMPOWER_SOUND);
	PrecacheSound(SICCERINO_FAST_ATTACK_SOUND);
	PrecacheSound(SICCERINO_PREPARE_SICCORS_SOUND);
	PrecacheSound(NEARL_ACTIVE_SOUND);
	PrecacheSound(NEARL_EXTRA_DAMAGE_SOUND);
	PrecacheSound("weapons/rescue_ranger_charge_01.wav");
	PrecacheSound("weapons/rescue_ranger_charge_02.wav");
	Zero(f_NearlDurationCheckApply);
	Zero(f_NearlThinkDelay);
	Zero(f_SpeedFistsOfSpeed);
}

void EntitySpawnToDefaultSiccerino(int entity)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		f_SiccerinoExtraDamage[client][entity] = 1.0;
	}
}

bool IsFusionWeapon(int Index)
{
	if(Index == WEAPON_FUSION
	 || Index == WEAPON_FUSION_PAP1
	 || Index == WEAPON_FUSION_PAP2
	 || Index == WEAPON_NEARL 
	 || Index == WEAPON_SICCERINO)
		return true;

	return false;
}

#define MINYAW_RAID_SHIELD -60.0
#define MAXYAW_RAID_SHIELD 60.0

public float Player_OnTakeDamage_Fusion(int victim, float &damage, int attacker, int weapon, float damagePosition[3])
{
	// need position of either the inflictor or the attacker
	float actualDamagePos[3];
	float victimPos[3];
	float angle[3];
	float eyeAngles[3];
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);

	bool BlockAnyways = false;
	if(damagePosition[0]) //Make sure if it doesnt
	{
		if(IsValidEntity(attacker))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", actualDamagePos);
		}
		else
		{
			BlockAnyways = true;
		}
	}
	else
	{
		actualDamagePos = damagePosition;
	}

	GetVectorAnglesTwoPoints(victimPos, actualDamagePos, angle);
	GetClientEyeAngles(victim, eyeAngles);


	// need the yaw offset from the player's POV, and set it up to be between (-180.0..180.0]
	float yawOffset = fixAngle(angle[1]) - fixAngle(eyeAngles[1]);
	if (yawOffset <= -180.0)
		yawOffset += 360.0;
	else if (yawOffset > 180.0)
		yawOffset -= 360.0;
		
	// now it's a simple check
	if ((yawOffset >= MINYAW_RAID_SHIELD && yawOffset <= MAXYAW_RAID_SHIELD) || BlockAnyways)
	{
		damage *= 0.9;
		
		if(f_AniSoundSpam[victim] < GetGameTime())
		{
			f_AniSoundSpam[victim] = GetGameTime() + 0.2;
			switch(GetRandomInt(1,2))
			{
				case 1:
				{
					EmitSoundToClient(victim, "weapons/rescue_ranger_charge_01.wav", victim, _, 85, _, 0.8, GetRandomInt(90, 100));
				}
				case 2:
				{
					EmitSoundToClient(victim, "weapons/rescue_ranger_charge_02.wav", victim, _, 85, _, 0.8, GetRandomInt(90, 100));
				}
			}
		}
	}
	return damage;
}

public float Npc_OnTakeDamage_PaP_Fusion(int attacker, int victim, float damage, int weapon)
{
	CClotBody npc = view_as<CClotBody>(victim);
	
	if(IsValidEntity(npc.m_iTarget))
	{
		char npc_classname[60];
		NPC_GetPluginById(i_NpcInternalId[npc.m_iTarget], npc_classname, sizeof(npc_classname));
		if(StrEqual(npc_classname, "npc_nearl_sword"))
		{
			damage *= 2.0;
			DisplayCritAboveNpc(victim, attacker, false); //Display crit above head, false for no sound
			EmitSoundToClient(attacker,NEARL_EXTRA_DAMAGE_SOUND, victim, SNDCHAN_AUTO, 90, _, 0.8);
			EmitSoundToClient(attacker,NEARL_EXTRA_DAMAGE_SOUND, victim, SNDCHAN_AUTO, 90, _, 0.8);
		}
	}
	return damage;
}

public void Fusion_Melee_Empower_State(int client, int weapon, bool crit, int slot)
{
	if (Ability_Check_Cooldown(client, slot) < 0.0)
	{
		Rogue_OnAbilityUse(weapon);
		Ability_Apply_Cooldown(client, slot, 60.0); //Semi long cooldown, this is a strong buff.

		Duration[client] = GetGameTime() + 10.0; //Just a test.

		EmitSoundToAll(EMPOWER_SOUND, client, SNDCHAN_STATIC, 90, _, 0.6);
		Weapon_Id[client] = EntIndexToEntRef(weapon);
		CreateTimer(0.1, Empower_ringTracker, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Empower_ringTracker_effect, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.0, Empower_ringTracker_effect, client, TIMER_FLAG_NO_MAPCHANGE); //Make it happen atleast once instantly
		f_EmpowerStateSelf[client] = GetGameTime() + 0.6;
		spawnRing(client, EMPOWER_RANGE * 2.0, 0.0, 0.0, EMPOWER_HIGHT_OFFSET, EMPOWER_MATERIAL, 231, 181, 59, 125, 30, 0.51, EMPOWER_WIDTH, 6.0, 10);
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



public void Fusion_Melee_Empower_State_PAP(int client, int weapon, bool crit, int slot)
{
	if(Ability_Check_Cooldown(client, slot) < 0.0 && !(GetClientButtons(client) & IN_DUCK))
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Crouch for ability");	
		return;
	}
	if (Ability_Check_Cooldown(client, slot) < 0.0)
	{
		Rogue_OnAbilityUse(weapon);
		Ability_Apply_Cooldown(client, slot, 60.0); //Semi long cooldown, this is a strong buff.

		Duration[client] = GetGameTime() + 10.0; //Just a test.

		EmitSoundToAll(EMPOWER_SOUND, client, SNDCHAN_STATIC, 90, _, 0.6);
		Weapon_Id[client] = EntIndexToEntRef(weapon);
		CreateTimer(0.1, Empower_ringTracker, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Empower_ringTracker_effect, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.0, Empower_ringTracker_effect, client, TIMER_FLAG_NO_MAPCHANGE); //Make it happen atleast once instantly
		f_EmpowerStateSelf[client] = GetGameTime() + 0.6;
		spawnRing(client, EMPOWER_RANGE * 2.0, 0.0, 0.0, EMPOWER_HIGHT_OFFSET, EMPOWER_MATERIAL, 231, 181, 59, 125, 30, 0.51, EMPOWER_WIDTH, 6.0, 10);
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


static Action Empower_ringTracker(Handle ringTracker, int client)
{
	if (IsValidClient(client) && Duration[client] > GetGameTime())
	{
		int ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if(EntRefToEntIndex(Weapon_Id[client]) == ActiveWeapon)
		{
			spawnRing(client, EMPOWER_RANGE * 2.0, 0.0, 0.0, EMPOWER_HIGHT_OFFSET, EMPOWER_MATERIAL, 231, 181, 59, 125, 10, 0.11, EMPOWER_WIDTH, 6.0, 10);
			
			f_EmpowerStateSelf[client] = GetGameTime() + 0.6;

			float chargerPos[3];
			float targPos[3];
			GetClientAbsOrigin(client, chargerPos);
			for (int targ = 1; targ <= MaxClients; targ++)
			{
				if (IsValidClient(targ) && IsValidClient(client))
				{
					GetClientAbsOrigin(targ, targPos);
					if (targ != client && GetVectorDistance(chargerPos, targPos, true) <= (EMPOWER_RANGE * EMPOWER_RANGE))
					{
						f_EmpowerStateOther[targ] = GetGameTime() + 0.6;
					}
				}
			}

			//Buff allied npcs too! Is cool!
			for(int entitycount_again; entitycount_again<i_MaxcountNpcTotal; entitycount_again++)
			{
				int baseboss_index_allied = EntRefToEntIndex(i_ObjectsNpcsTotal[entitycount_again]);
				if (IsValidEntity(baseboss_index_allied) && GetTeam(baseboss_index_allied) == TFTeam_Red)
				{
					GetEntPropVector(baseboss_index_allied, Prop_Data, "m_vecAbsOrigin", chargerPos);
					if (GetVectorDistance(chargerPos, targPos, true) <= (EMPOWER_RANGE * EMPOWER_RANGE))
					{
						f_EmpowerStateOther[baseboss_index_allied] = GetGameTime() + 0.6;
					}
				}
			}
		}
		else
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

static Action Empower_ringTracker_effect(Handle ringTracker, int client)
{
	if (IsValidClient(client) && Duration[client] > GetGameTime() && IsValidEntity(EntRefToEntIndex(Weapon_Id[client])))
	{
		int ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if(EntRefToEntIndex(Weapon_Id[client]) == ActiveWeapon)
		{
			//	spawnRing(client, EMPOWER_RANGE * 2.0, 0.0, 0.0, EMPOWER_HIGHT_OFFSET, EMPOWER_MATERIAL, 231, 181, 59, 125, 30, 0.5, EMPOWER_WIDTH, 6.0, 10);
			spawnRing(client, 0.0, 0.0, 0.0, EMPOWER_HIGHT_OFFSET, EMPOWER_MATERIAL, 231, 181, 59, 125, 1, 0.51, EMPOWER_WIDTH, 6.1, 1, EMPOWER_RANGE * 2.0);
		}
		else
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


public void Fusion_Melee_Nearl_Radiant_Knight(int client, int weapon, bool crit, int slot)
{
	if (Ability_Check_Cooldown(client, slot) < 0.0)
	{
		i_NearlWeaponUsedWith[client] = EntIndexToEntRef(weapon);
		if(f_NearlDurationCheckApply[client] > GetGameTime())
		{
			float fPos[3];
			float fAng[3];
			bool validpos = NearlCheckIfValidPos(client, 0.12,fPos,fAng);
			SDKUnhook(client, SDKHook_PostThink, NearlRadiantKnightCheck);
			f_NearlDurationCheckApply[client] = 0.0;

			if(validpos)
			{
				Rogue_OnAbilityUse(weapon);
				Ability_Apply_Cooldown(client, slot, 60.0); //Semi long cooldown, this is a strong buff.
				float damage = 500.0;
				damage *= Attributes_Get(weapon, 2, 1.0);

				i_ExplosiveProjectileHexArray[weapon] = 0;
				i_ExplosiveProjectileHexArray[weapon] |= EP_DEALS_CLUB_DAMAGE;

				Explode_Logic_Custom(damage, client, client, weapon, fPos, NEARL_STUN_RANGE, _, _, _, 15);

				bool RaidActive = false;

				if(RaidbossIgnoreBuildingsLogic(1))
					RaidActive = true;

				int maxhealth = SDKCall_GetMaxHealth(client);
				maxhealth *= 2; //2x health cus no resistance.
				
				if(Items_HasNamedItem(client, "Cured Silvester"))
				{
					SetDefaultHudPosition(client, 255, 215, 0, 2.0);
					SetGlobalTransTarget(client);
					ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Silvester Shares His Power");	
					float flPos[3];
					float flAng[3];
					int viewmodelModel;
					viewmodelModel = EntRefToEntIndex(i_Viewmodel_PlayerModel[client]);

					if(!IsValidEntity(viewmodelModel))
					{
						GetAttachment(viewmodelModel, "head", flPos, flAng);
						flPos[2] += 10.0;
						int particle_halo = ParticleEffectAt(flPos, "unusual_symbols_parent_lightning", 10.0);
						AddEntityToThirdPersonTransitMode(client, particle_halo);
						SetParent(viewmodelModel, particle_halo, "head");
					}
					maxhealth = RoundToCeil(float(maxhealth) * 1.05);
					ApplyTempAttrib(weapon, 2, 2.6, 10.0); //way higher damage.
					ApplyTempAttrib(weapon, 6, 1.45, 10.0); //slower attack speed
					ApplyTempAttrib(weapon, 412, 0.58, 10.0); //Less damage taken from all sources decreaced by 40%
				}
				else
				{
					ApplyTempAttrib(weapon, 2, 2.5, 10.0); //way higher damage.
					ApplyTempAttrib(weapon, 6, 1.5, 10.0); //slower attack speed
					ApplyTempAttrib(weapon, 412, 0.60, 10.0); //Less damage taken from all sources decreaced by 40%
				}

				int spawn_index = NPC_CreateByName("npc_nearl_sword", -1, fPos, fAng, GetTeam(client));
				if(spawn_index > MaxClients)
				{

					float Duration_Stun = 1.2;
					float Duration_Stun_Boss = 0.6;
					b_LagCompNPC_No_Layers = true;
					StartLagCompensation_Base_Boss(client);
					float EnemyPos[3];
					for(int entitycount_again; entitycount_again<i_MaxcountNpcTotal; entitycount_again++)
					{
						int baseboss_index = EntRefToEntIndex(i_ObjectsNpcsTotal[entitycount_again]);
						if (IsValidEntity(baseboss_index) && GetTeam(baseboss_index) != TFTeam_Red)
						{
							GetEntPropVector(baseboss_index, Prop_Data, "m_vecAbsOrigin", EnemyPos);
							if (GetVectorDistance(EnemyPos, fPos, true) <= (NEARL_STUN_RANGE * NEARL_STUN_RANGE))
							{
								if(!b_thisNpcIsABoss[baseboss_index] && !RaidActive)
								{
									FreezeNpcInTime(baseboss_index,Duration_Stun);
								}
								else
								{
									FreezeNpcInTime(baseboss_index,Duration_Stun_Boss);
								}
								CClotBody npc_set_aggro = view_as<CClotBody>(baseboss_index);
								npc_set_aggro.m_iTarget = spawn_index;
								npc_set_aggro.m_flGetClosestTargetTime = GetGameTime(npc_set_aggro.index) + 1.0;
							}
						}
					}
					FinishLagCompensation_Base_boss();

					fPos[2] += 40.0;
					ParticleEffectAt(fPos, "asplode_hoodoo_embers", 1.0);
					fPos[2] -= 40.0;
					CClotBody npc = view_as<CClotBody>(spawn_index);
					npc.m_iWearable4 =	ParticleEffectAt(fPos, "powerup_supernova_ready", 10.0);
					fPos[2] += 50.0;
					npc.m_iWearable5 =	ParticleEffectAt(fPos, "powerup_supernova_ready", 10.0);
					fPos[2] += 3000.0;
					int particle = ParticleEffectAt(fPos, "kartimpacttrail", 1.0);
					SetEdictFlags(particle, (GetEdictFlags(particle) | FL_EDICT_ALWAYS));	
					EmitSoundToAll(NEARL_ACTIVE_SOUND, client, SNDCHAN_STATIC, 90, _, 0.6);
					CreateTimer(0.1, Nearl_Falling_Shot, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
					SetEntProp(spawn_index, Prop_Data, "m_iHealth", maxhealth);
					SetEntProp(spawn_index, Prop_Data, "m_iMaxHealth", maxhealth);
					CreateTimer(10.0, Timer_SlayNearlSword, EntIndexToEntRef(spawn_index), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		else
		{
			SDKUnhook(client, SDKHook_PostThink, NearlRadiantKnightCheck);
			SDKHook(client, SDKHook_PostThink, NearlRadiantKnightCheck);
			f_NearlDurationCheckApply[client] = GetGameTime() + 2.0;
		}
		/*

		*/
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

public void NearlRadiantKnightCheck(int client)
{
	if(f_NearlDurationCheckApply[client] < GetGameTime())
	{
		SDKUnhook(client, SDKHook_PostThink, NearlRadiantKnightCheck);
		return;
	}
	if(f_NearlThinkDelay[client] > GetGameTime())
	{
		return;
	}
	int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int Weapon_Was = EntRefToEntIndex(i_NearlWeaponUsedWith[client]);
	if(weapon_holding == Weapon_Was)
	{
		f_NearlThinkDelay[client] = GetGameTime() + 0.1;
		float fPos[3];
		float fAng[3];
		NearlCheckIfValidPos(client, 0.12,fPos,fAng);
	}
	else
	{
		SDKUnhook(client, SDKHook_PostThink, NearlRadiantKnightCheck);
		return;		
	}
}


public bool NearlCheckIfValidPos(int client, float duration, float fPos[3], float fAng[3])
{
	GetClientEyeAngles(client, fAng);
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 120.0; //Default is on average 70. so lets keep it like that.
	fAng[0] = 0.0; //We dont care about them looking down or up
	fAng[2] = 0.0; //This shoulddnt be accounted for!

	float tmp[3];
	float actualBeamOffset[3];
	float BEAM_BeamOffset[3];
	BEAM_BeamOffset[0] = 120.0;
	BEAM_BeamOffset[1] = 0.0;
	BEAM_BeamOffset[2] = 0.0;
	
	tmp[0] = BEAM_BeamOffset[0];
	tmp[1] = BEAM_BeamOffset[1];
	tmp[2] = 0.0;
	VectorRotate(tmp, fAng, actualBeamOffset);
	actualBeamOffset[2] = BEAM_BeamOffset[2];
	fPos[0] += actualBeamOffset[0];
	fPos[1] += actualBeamOffset[1];
	fPos[2] += actualBeamOffset[2];

	static float m_vecMaxs[3];
	static float m_vecMins[3];
	m_vecMaxs = view_as<float>( { 10.0, 10.0, 70.0 } );
	m_vecMins = view_as<float>( { -10.0, -10.0, 0.0 } );	

	Handle hTrace;
	static float m_vecLookdown[3];
	m_vecLookdown = view_as<float>( { 90.0, 0.0, 0.0 } );
	hTrace = TR_TraceRayFilterEx(fPos, m_vecLookdown, ( MASK_ALL ), RayType_Infinite, HitOnlyWorld, client);	
	TR_GetEndPosition(fPos, hTrace);
	delete hTrace;
	fPos[2] += 4.0;
	int HitWorld = IsSpaceOccupiedIgnorePlayers(fPos, m_vecMins, m_vecMaxs, client);
	if (HitWorld) //The boss will start to merge with player, STOP!
	{
		TE_DrawBox(client, fPos, m_vecMins, m_vecMaxs, duration, view_as<int>({255, 0, 0, 255}));
		return false;
	}
	if(IsPointHazard(fPos)) //Retry.
	{
		TE_DrawBox(client, fPos, m_vecMins, m_vecMaxs, duration, view_as<int>({255, 0, 0, 255}));
		return false;
	}
	TE_DrawBox(client, fPos, m_vecMins, m_vecMaxs, duration, view_as<int>({255, 215, 0, 255}));
	return true;
}

public Action Timer_SlayNearlSword(Handle cut_timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(IsValidEntity(entity)) //Dont do this in a think pls.
	{
		SDKHooks_TakeDamage(entity, 0, 0, 99999999.9);
	}
	return Plugin_Handled;
}

public Action Nearl_Falling_Shot(Handle timer, int ref)
{
	int particle = EntRefToEntIndex(ref);
	if(particle>MaxClients && IsValidEntity(particle))
	{
		float position[3];
		GetEntPropVector(particle, Prop_Send, "m_vecOrigin", position);
		position[2] -= 3700.0;
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}


void Npc_OnTakeDamage_SpeedFists(int attacker, int victim, float &damage)
{
	if(b_thisNpcIsARaid[victim])
	{
		damage *= 1.10;
	}
	if(f_SpeedFistsOfSpeed[attacker] > GetGameTime())
	{
		i_SpeedFistsOfSpeedHit[attacker] += 1;
		if(i_SpeedFistsOfSpeedHit[attacker] > 10)
		{
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 1.0);
		}
	}
	else
	{
		i_SpeedFistsOfSpeedHit[attacker] = 1;
	}
	f_SpeedFistsOfSpeed[attacker] = GetGameTime() + 0.5;
}


#define MAX_FUSION_ENERGY_EFFECTS 25
static int i_FusionEnergyEffect[MAXENTITIES][MAX_FUSION_ENERGY_EFFECTS];

void FusionWeaponRemoveEffects(int iNpc)
{
	for(int loop = 0; loop<MAX_FUSION_ENERGY_EFFECTS; loop++)
	{
		int entity = EntRefToEntIndex(i_FusionEnergyEffect[iNpc][loop]);
		if(IsValidEntity(entity))
		{
			RemoveEntity(entity);
		}
		i_FusionEnergyEffect[iNpc][loop] = INVALID_ENT_REFERENCE;
	}
}

bool FusionWeaponCheckEffects_IfNotAvaiable(int iNpc, int weapon)
{
	int thingsToLoop;
	switch(i_CustomWeaponEquipLogic[weapon])
	{
		case WEAPON_FUSION:
		{
			thingsToLoop = 7;
		}
		case WEAPON_FUSION_PAP1:
		{
			thingsToLoop = 14;
		}
		case WEAPON_FUSION_PAP2:
		{
			thingsToLoop = 24;
		}
		case WEAPON_NEARL:
		{
			thingsToLoop = 24;
		}
		case WEAPON_SICCERINO:
		{
			thingsToLoop = 12;
		}
	}
	for(int loop = 0; loop <=thingsToLoop; loop++)
	{
		int entity = EntRefToEntIndex(i_FusionEnergyEffect[iNpc][loop]);
		if(!IsValidEntity(entity))
		{
			return true;
		}
	}
	return false;
}

void ApplyExtraFusionWeaponEffects(int client, bool remove = false, int weapon)
{
	if(remove)
	{
		FusionWeaponRemoveEffects(client);
		return;
	}
	int viewmodelModel;
	viewmodelModel = EntRefToEntIndex(i_Viewmodel_PlayerModel[client]);

	if(!IsValidEntity(viewmodelModel))
	{
		FusionWeaponRemoveEffects(client);
		return;
	}

	if(FusionWeaponCheckEffects_IfNotAvaiable(client, weapon))
	{
		FusionWeaponRemoveEffects(client);
		FusionWeaponEffects(client, client, viewmodelModel, "effect_hand_r", weapon);
	}
}



void FusionWeaponEffects(int owner, int client, int Wearable, char[] attachment = "effect_hand_r", int weapon)
{
	switch(i_CustomWeaponEquipLogic[weapon])
	{
		case WEAPON_FUSION:
		{
			FusionWeaponEffectPap0(owner, client, Wearable, attachment);
		}
		case WEAPON_FUSION_PAP1:
		{
			FusionWeaponEffectPap1(owner, client, Wearable, attachment);
		}
		case WEAPON_FUSION_PAP2:
		{
			FusionWeaponEffectPap2(owner, client, Wearable, attachment);
		}
		case WEAPON_NEARL:
		{
			FusionWeaponEffectPap3(owner, client, Wearable, attachment);
		}
		case WEAPON_SICCERINO:
		{
			FusionWeaponEffectPap_Siccerino(owner, client, Wearable, attachment);
		}
	}
}

void FusionWeaponEffectPap0(int owner, int client, int Wearable, char[] attachment = "effect_hand_r")
{
	int red = 255;
	int green = 255;
	int blue = 0;
	float flPos[3];
	float flAng[3];
	int particle_1 = InfoTargetParentAt({0.0,0.0,0.0},"", 0.0); //This is the root bone basically

	int particle_2 = InfoTargetParentAt({0.0,-15.0,0.0},"", 0.0); //First offset we go by
	int particle_3 = InfoTargetParentAt({-15.0,0.0,0.0},"", 0.0); //First offset we go by
	int particle_4 = InfoTargetParentAt({0.0,10.0,0.0},"", 0.0); //First offset we go by
	int particle_5 = InfoTargetParentAt({10.0,50.0,0.0},"", 0.0); //First offset we go by

	SetParent(particle_1, particle_2, "",_, true);
	SetParent(particle_1, particle_3, "",_, true);
	SetParent(particle_1, particle_4, "",_, true);
	SetParent(particle_1, particle_5, "",_, true);

	Custom_SDKCall_SetLocalOrigin(particle_1, flPos);
	SetEntPropVector(particle_1, Prop_Data, "m_angRotation", flAng); 
	SetParent(Wearable, particle_1, attachment,_);


	int Laser_1 = ConnectWithBeamClient(particle_2, particle_3, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2 = ConnectWithBeamClient(particle_3, particle_4, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3 = ConnectWithBeamClient(particle_4, particle_5, red, green, blue, 2.0, 1.0, 1.0, LASERBEAM, owner);
	

	i_FusionEnergyEffect[client][0] = EntIndexToEntRef(particle_1);
	i_FusionEnergyEffect[client][1] = EntIndexToEntRef(particle_2);
	i_FusionEnergyEffect[client][2] = EntIndexToEntRef(particle_3);
	i_FusionEnergyEffect[client][3] = EntIndexToEntRef(particle_4);
	i_FusionEnergyEffect[client][4] = EntIndexToEntRef(particle_5);
	i_FusionEnergyEffect[client][5] = EntIndexToEntRef(Laser_1);
	i_FusionEnergyEffect[client][6] = EntIndexToEntRef(Laser_2);
	i_FusionEnergyEffect[client][7] = EntIndexToEntRef(Laser_3);
}


void FusionWeaponEffectPap1(int owner, int client, int Wearable, char[] attachment = "effect_hand_r")
{
	int red = 255;
	int green = 255;
	int blue = 0;
	float flPos[3];
	float flAng[3];
	int particle_1 = InfoTargetParentAt({0.0,0.0,0.0},"", 0.0); //This is the root bone basically
	
	int particle_2 = InfoTargetParentAt({0.0,-15.0,0.0},"", 0.0); //First offset we go by
	int particle_3 = InfoTargetParentAt({-15.0,0.0,0.0},"", 0.0); //First offset we go by
	int particle_4 = InfoTargetParentAt({-5.0,10.0,0.0},"", 0.0); //First offset we go by
	int particle_5 = InfoTargetParentAt({-2.0,50.0,0.0},"", 0.0); //First offset we go by

	
	int particle_2_1 = InfoTargetParentAt({0.0,-15.0,0.0},"", 0.0); //First offset we go by
	int particle_3_1 = InfoTargetParentAt({15.0,0.0,0.0},"", 0.0); //First offset we go by
	int particle_4_1 = InfoTargetParentAt({5.0,10.0,0.0},"", 0.0); //First offset we go by
	int particle_5_1 = InfoTargetParentAt({2.0,50.0,0.0},"", 0.0); //First offset we go by

	SetParent(particle_1, particle_2, "",_, true);
	SetParent(particle_1, particle_3, "",_, true);
	SetParent(particle_1, particle_4, "",_, true);
	SetParent(particle_1, particle_5, "",_, true);
	
	SetParent(particle_1, particle_2_1, "",_, true);
	SetParent(particle_1, particle_3_1, "",_, true);
	SetParent(particle_1, particle_4_1, "",_, true);
	SetParent(particle_1, particle_5_1, "",_, true);

	Custom_SDKCall_SetLocalOrigin(particle_1, flPos);
	SetEntPropVector(particle_1, Prop_Data, "m_angRotation", flAng); 
	SetParent(Wearable, particle_1, attachment,_);


	int Laser_1 = ConnectWithBeamClient(particle_2, particle_3, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2 = ConnectWithBeamClient(particle_3, particle_4, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3 = ConnectWithBeamClient(particle_4, particle_5, red, green, blue, 2.0, 1.0, 1.0, LASERBEAM, owner);

	int Laser_1_1 = ConnectWithBeamClient(particle_2_1, particle_3_1, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2_1 = ConnectWithBeamClient(particle_3_1, particle_4_1, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3_1 = ConnectWithBeamClient(particle_4_1, particle_5_1, red, green, blue, 2.0, 1.0, 1.0, LASERBEAM, owner);
	

	i_FusionEnergyEffect[client][0] = EntIndexToEntRef(particle_1);
	i_FusionEnergyEffect[client][1] = EntIndexToEntRef(particle_2);
	i_FusionEnergyEffect[client][2] = EntIndexToEntRef(particle_3);
	i_FusionEnergyEffect[client][3] = EntIndexToEntRef(particle_4);
	i_FusionEnergyEffect[client][4] = EntIndexToEntRef(particle_5);
	i_FusionEnergyEffect[client][5] = EntIndexToEntRef(Laser_1);
	i_FusionEnergyEffect[client][6] = EntIndexToEntRef(Laser_2);
	i_FusionEnergyEffect[client][7] = EntIndexToEntRef(Laser_3);
	
	i_FusionEnergyEffect[client][8] = EntIndexToEntRef(particle_2_1);
	i_FusionEnergyEffect[client][9] = EntIndexToEntRef(particle_3_1);
	i_FusionEnergyEffect[client][10] = EntIndexToEntRef(particle_4_1);
	i_FusionEnergyEffect[client][11] = EntIndexToEntRef(particle_5_1);
	i_FusionEnergyEffect[client][12] = EntIndexToEntRef(Laser_1_1);
	i_FusionEnergyEffect[client][13] = EntIndexToEntRef(Laser_2_1);
	i_FusionEnergyEffect[client][14] = EntIndexToEntRef(Laser_3_1);
}



void FusionWeaponEffectPap2(int owner, int client, int Wearable, char[] attachment = "effect_hand_r")
{
	int red = 255;
	int green = 255;
	int blue = 0;
	float flPos[3];
	float flAng[3];
	int particle_1 = InfoTargetParentAt({0.0,0.0,0.0},"", 0.0); //This is the root bone basically
	
	int particle_2 = InfoTargetParentAt({0.0,-15.0,0.0},"", 0.0); //First offset we go by
	int particle_3 = InfoTargetParentAt({-15.0,0.0,0.0},"", 0.0); //First offset we go by
	int particle_4 = InfoTargetParentAt({-5.0,10.0,0.0},"", 0.0); //First offset we go by
	int particle_5 = InfoTargetParentAt({-2.0,50.0,0.0},"", 0.0); //First offset we go by

	
	int particle_2_1 = InfoTargetParentAt({0.0,-15.0,0.0},"", 0.0); //First offset we go by
	int particle_3_1 = InfoTargetParentAt({15.0,0.0,0.0},"", 0.0); //First offset we go by
	int particle_4_1 = InfoTargetParentAt({5.0,10.0,0.0},"", 0.0); //First offset we go by
	int particle_5_1 = InfoTargetParentAt({2.0,50.0,0.0},"", 0.0); //First offset we go by

	SetParent(particle_1, particle_2, "",_, true);
	SetParent(particle_1, particle_3, "",_, true);
	SetParent(particle_1, particle_4, "",_, true);
	SetParent(particle_1, particle_5, "",_, true);
	
	SetParent(particle_1, particle_2_1, "",_, true);
	SetParent(particle_1, particle_3_1, "",_, true);
	SetParent(particle_1, particle_4_1, "",_, true);
	SetParent(particle_1, particle_5_1, "",_, true);

	Custom_SDKCall_SetLocalOrigin(particle_1, flPos);
	SetEntPropVector(particle_1, Prop_Data, "m_angRotation", flAng); 
	SetParent(Wearable, particle_1, attachment,_);


	int Laser_1 = ConnectWithBeamClient(particle_2, particle_3, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2 = ConnectWithBeamClient(particle_3, particle_4, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3 = ConnectWithBeamClient(particle_4, particle_5, red, green, blue, 2.0, 1.0, 1.0, LASERBEAM, owner);

	int Laser_1_1 = ConnectWithBeamClient(particle_2_1, particle_3_1, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2_1 = ConnectWithBeamClient(particle_3_1, particle_4_1, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3_1 = ConnectWithBeamClient(particle_4_1, particle_5_1, red, green, blue, 2.0, 1.0, 1.0, LASERBEAM, owner);
	

	i_FusionEnergyEffect[client][0] = EntIndexToEntRef(particle_1);
	i_FusionEnergyEffect[client][1] = EntIndexToEntRef(particle_2);
	i_FusionEnergyEffect[client][2] = EntIndexToEntRef(particle_3);
	i_FusionEnergyEffect[client][3] = EntIndexToEntRef(particle_4);
	i_FusionEnergyEffect[client][4] = EntIndexToEntRef(particle_5);
	i_FusionEnergyEffect[client][5] = EntIndexToEntRef(Laser_1);
	i_FusionEnergyEffect[client][6] = EntIndexToEntRef(Laser_2);
	i_FusionEnergyEffect[client][7] = EntIndexToEntRef(Laser_3);
	
	i_FusionEnergyEffect[client][8] = EntIndexToEntRef(particle_2_1);
	i_FusionEnergyEffect[client][9] = EntIndexToEntRef(particle_3_1);
	i_FusionEnergyEffect[client][10] = EntIndexToEntRef(particle_4_1);
	i_FusionEnergyEffect[client][11] = EntIndexToEntRef(particle_5_1);
	i_FusionEnergyEffect[client][12] = EntIndexToEntRef(Laser_1_1);
	i_FusionEnergyEffect[client][13] = EntIndexToEntRef(Laser_2_1);
	i_FusionEnergyEffect[client][14] = EntIndexToEntRef(Laser_3_1);

	
	int particle_1_l = InfoTargetParentAt({0.0,0.0,0.0},"", 0.0); //This is the root bone basically
	int particle_2_l = InfoTargetParentAt({-5.0,-5.0,25.0},"", 0.0); 
	int particle_3_l = InfoTargetParentAt({-5.0,-5.0,-25.0},"", 0.0);
	int particle_4_l = InfoTargetParentAt({-5.0,15.0,0.0},"", 0.0); 
	int particle_5_l = InfoTargetParentAt({-5.0,-15.0,0.0},"", 0.0);

	SetParent(particle_1_l, particle_2_l, "",_, true);
	SetParent(particle_1_l, particle_3_l, "",_, true);
	SetParent(particle_1_l, particle_4_l, "",_, true);
	SetParent(particle_1_l, particle_5_l, "",_, true);


	red = 255;
	green = 255;
	blue = 255;

	int Laser_1_l = ConnectWithBeamClient(particle_2_l, particle_4_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2_l = ConnectWithBeamClient(particle_3_l, particle_5_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3_l = ConnectWithBeamClient(particle_2_l, particle_5_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_4_l = ConnectWithBeamClient(particle_3_l, particle_4_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_5_l = ConnectWithBeamClient(particle_4_l, particle_5_l, red, green, blue, 1.0, 1.0, 1.0, LASERBEAM, owner);

	SetParent(particle_1_l, particle_2_l, "",_, true);


	Custom_SDKCall_SetLocalOrigin(particle_1_l, flPos);
	SetEntPropVector(particle_1_l, Prop_Data, "m_angRotation", flAng); 
	SetParent(Wearable, particle_1_l, "effect_hand_l",_);

	i_FusionEnergyEffect[client][15] = EntIndexToEntRef(particle_1_l);
	i_FusionEnergyEffect[client][16] = EntIndexToEntRef(particle_2_l);
	i_FusionEnergyEffect[client][17] = EntIndexToEntRef(particle_3_l);
	i_FusionEnergyEffect[client][18] = EntIndexToEntRef(particle_4_l);
	i_FusionEnergyEffect[client][19] = EntIndexToEntRef(particle_5_l);
	i_FusionEnergyEffect[client][20] = EntIndexToEntRef(Laser_1_l);
	i_FusionEnergyEffect[client][21] = EntIndexToEntRef(Laser_2_l);
	i_FusionEnergyEffect[client][22] = EntIndexToEntRef(Laser_3_l);
	i_FusionEnergyEffect[client][23] = EntIndexToEntRef(Laser_4_l);
	i_FusionEnergyEffect[client][24] = EntIndexToEntRef(Laser_5_l);

}

void FusionWeaponEffectPap3(int owner, int client, int Wearable, char[] attachment = "effect_hand_r")
{
	int red = 255;
	int green = 255;
	int blue = 0;
	float flPos[3];
	float flAng[3];
	int particle_1 = InfoTargetParentAt({0.0,0.0,0.0},"", 0.0); //This is the root bone basically
	
	int particle_2 = InfoTargetParentAt({0.0,-15.0,0.0},"", 0.0); //First offset we go by
	int particle_3 = InfoTargetParentAt({-15.0,0.0,0.0},"", 0.0); //First offset we go by
	int particle_4 = InfoTargetParentAt({-5.0,10.0,0.0},"", 0.0); //First offset we go by
	int particle_5 = InfoTargetParentAt({-2.0,50.0,0.0},"", 0.0); //First offset we go by

	
	int particle_2_1 = InfoTargetParentAt({0.0,-15.0,0.0},"", 0.0); //First offset we go by
	int particle_3_1 = InfoTargetParentAt({15.0,0.0,0.0},"", 0.0); //First offset we go by
	int particle_4_1 = InfoTargetParentAt({5.0,10.0,0.0},"", 0.0); //First offset we go by
	int particle_5_1 = InfoTargetParentAt({2.0,50.0,0.0},"", 0.0); //First offset we go by

	SetParent(particle_1, particle_2, "",_, true);
	SetParent(particle_1, particle_3, "",_, true);
	SetParent(particle_1, particle_4, "",_, true);
	SetParent(particle_1, particle_5, "",_, true);
	
	SetParent(particle_1, particle_2_1, "",_, true);
	SetParent(particle_1, particle_3_1, "",_, true);
	SetParent(particle_1, particle_4_1, "",_, true);
	SetParent(particle_1, particle_5_1, "",_, true);

	Custom_SDKCall_SetLocalOrigin(particle_1, flPos);
	SetEntPropVector(particle_1, Prop_Data, "m_angRotation", flAng); 
	SetParent(Wearable, particle_1, attachment,_);


	int Laser_1 = ConnectWithBeamClient(particle_2, particle_3, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2 = ConnectWithBeamClient(particle_3, particle_4, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3 = ConnectWithBeamClient(particle_4, particle_5, red, green, blue, 2.0, 1.0, 1.0, LASERBEAM, owner);

	int Laser_1_1 = ConnectWithBeamClient(particle_2_1, particle_3_1, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2_1 = ConnectWithBeamClient(particle_3_1, particle_4_1, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3_1 = ConnectWithBeamClient(particle_4_1, particle_5_1, red, green, blue, 2.0, 1.0, 1.0, LASERBEAM, owner);
	

	i_FusionEnergyEffect[client][0] = EntIndexToEntRef(particle_1);
	i_FusionEnergyEffect[client][1] = EntIndexToEntRef(particle_2);
	i_FusionEnergyEffect[client][2] = EntIndexToEntRef(particle_3);
	i_FusionEnergyEffect[client][3] = EntIndexToEntRef(particle_4);
	i_FusionEnergyEffect[client][4] = EntIndexToEntRef(particle_5);
	i_FusionEnergyEffect[client][5] = EntIndexToEntRef(Laser_1);
	i_FusionEnergyEffect[client][6] = EntIndexToEntRef(Laser_2);
	i_FusionEnergyEffect[client][7] = EntIndexToEntRef(Laser_3);
	
	i_FusionEnergyEffect[client][8] = EntIndexToEntRef(particle_2_1);
	i_FusionEnergyEffect[client][9] = EntIndexToEntRef(particle_3_1);
	i_FusionEnergyEffect[client][10] = EntIndexToEntRef(particle_4_1);
	i_FusionEnergyEffect[client][11] = EntIndexToEntRef(particle_5_1);
	i_FusionEnergyEffect[client][12] = EntIndexToEntRef(Laser_1_1);
	i_FusionEnergyEffect[client][13] = EntIndexToEntRef(Laser_2_1);
	i_FusionEnergyEffect[client][14] = EntIndexToEntRef(Laser_3_1);

	
	int particle_1_l = InfoTargetParentAt({0.0,0.0,0.0},"", 0.0); //This is the root bone basically
	int particle_2_l = InfoTargetParentAt({-5.0,-5.0,25.0},"", 0.0); 
	int particle_3_l = InfoTargetParentAt({-5.0,-5.0,-25.0},"", 0.0);
	int particle_4_l = InfoTargetParentAt({-5.0,15.0,0.0},"", 0.0); 
	int particle_5_l = InfoTargetParentAt({-5.0,-15.0,0.0},"", 0.0);

	SetParent(particle_1_l, particle_2_l, "",_, true);
	SetParent(particle_1_l, particle_3_l, "",_, true);
	SetParent(particle_1_l, particle_4_l, "",_, true);
	SetParent(particle_1_l, particle_5_l, "",_, true);


	red = 255;
	green = 255;
	blue = 125;

	int Laser_1_l = ConnectWithBeamClient(particle_2_l, particle_4_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2_l = ConnectWithBeamClient(particle_3_l, particle_5_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3_l = ConnectWithBeamClient(particle_2_l, particle_5_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_4_l = ConnectWithBeamClient(particle_3_l, particle_4_l, red, green, blue, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_5_l = ConnectWithBeamClient(particle_4_l, particle_5_l, red, green, blue, 3.0, 3.0, 1.0, LASERBEAM, owner);

	SetParent(particle_1_l, particle_2_l, "",_, true);


	Custom_SDKCall_SetLocalOrigin(particle_1_l, flPos);
	SetEntPropVector(particle_1_l, Prop_Data, "m_angRotation", flAng); 
	SetParent(Wearable, particle_1_l, "effect_hand_l",_);

	i_FusionEnergyEffect[client][15] = EntIndexToEntRef(particle_1_l);
	i_FusionEnergyEffect[client][16] = EntIndexToEntRef(particle_2_l);
	i_FusionEnergyEffect[client][17] = EntIndexToEntRef(particle_3_l);
	i_FusionEnergyEffect[client][18] = EntIndexToEntRef(particle_4_l);
	i_FusionEnergyEffect[client][19] = EntIndexToEntRef(particle_5_l);
	i_FusionEnergyEffect[client][20] = EntIndexToEntRef(Laser_1_l);
	i_FusionEnergyEffect[client][21] = EntIndexToEntRef(Laser_2_l);
	i_FusionEnergyEffect[client][22] = EntIndexToEntRef(Laser_3_l);
	i_FusionEnergyEffect[client][23] = EntIndexToEntRef(Laser_4_l);
	i_FusionEnergyEffect[client][24] = EntIndexToEntRef(Laser_5_l);

}


void FusionWeaponEffectPap_Siccerino(int owner, int client, int Wearable, char[] attachment = "effect_hand_r")
{
	float flPos[3];
	float flAng[3];
	int particle_1 = InfoTargetParentAt({0.0,0.0,0.0},"", 0.0); //This is the root bone basically
	
	int particle_2 = InfoTargetParentAt({0.0,-15.0,0.0}, "", 0.0); //First offset we go by
	int particle_3 = InfoTargetParentAt({-15.0,0.0,0.0}, "", 0.0); //First offset we go by
	int particle_4 = InfoTargetParentAt({0.0,10.0,0.0}, "", 0.0); //First offset we go by
	int particle_5 = InfoTargetParentAt({10.0,50.0,0.0}, "", 0.0); //First offset we go by

	int particle_3_i = InfoTargetParentAt({15.0,0.0,0.0}, "", 0.0); //First offset we go by
	int particle_5_i = InfoTargetParentAt({-10.0,50.0,0.0}, "", 0.0); //First offset we go by

	SetParent(particle_1, particle_2, "",_, true);
	SetParent(particle_1, particle_3, "",_, true);
	SetParent(particle_1, particle_4, "",_, true);
	SetParent(particle_1, particle_5, "",_, true);

	
	SetParent(particle_1, particle_3_i, "",_, true);
	SetParent(particle_1, particle_5_i, "",_, true);

	Custom_SDKCall_SetLocalOrigin(particle_1, flPos);
	SetEntPropVector(particle_1, Prop_Data, "m_angRotation", flAng); 
	SetParent(Wearable, particle_1, attachment,_); 


	int Laser_1 = ConnectWithBeamClient(particle_2, particle_3, 35, 255, 35, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2 = ConnectWithBeamClient(particle_3, particle_4, 35, 255, 35, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3 = ConnectWithBeamClient(particle_4, particle_5, 35, 255, 35, 2.0, 1.0, 1.0, LASERBEAM, owner);
	int Laser_1_i = ConnectWithBeamClient(particle_2, particle_3_i, 35, 255, 35, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_2_i = ConnectWithBeamClient(particle_3_i, particle_4, 35, 255, 35, 2.0, 2.0, 1.0, LASERBEAM, owner);
	int Laser_3_i = ConnectWithBeamClient(particle_4, particle_5_i, 35, 255, 35, 2.0, 1.0, 1.0, LASERBEAM, owner);
	

	i_FusionEnergyEffect[client][0] = EntIndexToEntRef(particle_1);
	i_FusionEnergyEffect[client][1] = EntIndexToEntRef(particle_2);
	i_FusionEnergyEffect[client][2] = EntIndexToEntRef(particle_3);
	i_FusionEnergyEffect[client][3] = EntIndexToEntRef(particle_4);
	i_FusionEnergyEffect[client][4] = EntIndexToEntRef(particle_5);
	i_FusionEnergyEffect[client][5] = EntIndexToEntRef(particle_3_i);
	i_FusionEnergyEffect[client][6] = EntIndexToEntRef(particle_5_i);
	i_FusionEnergyEffect[client][7] = EntIndexToEntRef(Laser_1);
	i_FusionEnergyEffect[client][8] = EntIndexToEntRef(Laser_2);
	i_FusionEnergyEffect[client][9] = EntIndexToEntRef(Laser_3);
	i_FusionEnergyEffect[client][10] = EntIndexToEntRef(Laser_1_i);
	i_FusionEnergyEffect[client][11] = EntIndexToEntRef(Laser_2_i);
	i_FusionEnergyEffect[client][12] = EntIndexToEntRef(Laser_3_i);

}



public void Enable_FusionWeapon(int client, int weapon) // Enable management, handle weapons change but also delete the timer if the client have the max weapon
{
	if (h_TimerFusionWeaponManagement[client] != null)
	{
		//This timer already exists.
		if(IsFusionWeapon(i_CustomWeaponEquipLogic[weapon]))
		{
		//	ApplyExtraFusionWeaponEffects(client,_ ,weapon);
			//Is the weapon it again?
			//Yes?
			delete h_TimerFusionWeaponManagement[client];
			h_TimerFusionWeaponManagement[client] = null;
			DataPack pack;
			h_TimerFusionWeaponManagement[client] = CreateDataTimer(0.1, Timer_Management_FusionWeapon, pack, TIMER_REPEAT);
			pack.WriteCell(client);
			pack.WriteCell(EntIndexToEntRef(weapon));
		}
		return;
	}
		
	if(IsFusionWeapon(i_CustomWeaponEquipLogic[weapon]))
	{
	//	ApplyExtraFusionWeaponEffects(client,_ ,weapon);
		DataPack pack;
		h_TimerFusionWeaponManagement[client] = CreateDataTimer(0.1, Timer_Management_FusionWeapon, pack, TIMER_REPEAT);
		pack.WriteCell(client);
		pack.WriteCell(EntIndexToEntRef(weapon));
	}
}


public Action Timer_Management_FusionWeapon(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(weapon))
	{
		ApplyExtraFusionWeaponEffects(client,true ,0);
		h_TimerFusionWeaponManagement[client] = null;
		return Plugin_Stop;
	}	
	if(i_PreviousBladePap[client] != i_CustomWeaponEquipLogic[weapon])
	{
		ApplyExtraFusionWeaponEffects(client,true ,0);
		i_PreviousBladePap[client] = i_CustomWeaponEquipLogic[weapon];
		return Plugin_Continue;
	}
	i_PreviousBladePap[client] = i_CustomWeaponEquipLogic[weapon];
	int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon_holding == weapon) //Only show if the weapon is actually in your hand right now.
	{
		ApplyExtraFusionWeaponEffects(client,_ ,weapon_holding);
		SensalTimerHudShow(client, weapon);
	}
	else
	{
		ApplyExtraFusionWeaponEffects(client,true ,0);
	}
		
	return Plugin_Continue;
}

public void Siccerino_ability_m2(int client, int weapon, bool crit, int slot)
{
	if (Ability_Check_Cooldown(client, slot) < 0.0)
	{
		Rogue_OnAbilityUse(weapon);
		Ability_Apply_Cooldown(client, slot, 30.0); //Semi long cooldown, this is a strong buff.

		EmitSoundToAll(SICCERINO_FAST_ATTACK_SOUND, client, SNDCHAN_STATIC, 90, _, 0.6);
		ApplyTempAttrib(weapon, 1, 0.25, 5.0); //way higher damage.
		ApplyTempAttrib(weapon, 6, 0.15, 5.0); //slower attack speed
		i_MeleeAttackFrameDelay[weapon] = 0;
		CreateTimer(5.0, Siccerino_revert_toNormal, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
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

static Action Siccerino_revert_toNormal(Handle ringTracker, int ref)
{
	int weapon = EntRefToEntIndex(ref);
	if (IsValidEntity(weapon))
	{
		i_MeleeAttackFrameDelay[weapon] = 12;
	}
	return Plugin_Stop;
}

#define SICCERINO_BONUS_DAMAGE 0.025
#define SICCERINO_BONUS_DAMAGE_MAX 2.0
#define SICCERINO_BONUS_DAMAGE_MAX_RAID 1.5

float Siccerino_Melee_DmgBonus(int victim, int attacker, int weapon)
{
	if(i_CustomWeaponEquipLogic[weapon] == WEAPON_SICCERINO)
	{
		if(b_thisNpcIsARaid[victim])
		{
			if(f_SiccerinoExtraDamage[attacker][victim] >= SICCERINO_BONUS_DAMAGE_MAX_RAID)
			{
				return SICCERINO_BONUS_DAMAGE_MAX_RAID;
			}
		}
		else if(f_SiccerinoExtraDamage[attacker][victim] >= SICCERINO_BONUS_DAMAGE_MAX)
		{
			return SICCERINO_BONUS_DAMAGE_MAX;
		}
		return f_SiccerinoExtraDamage[attacker][victim];
	}	
	return 1.0;
}
public float Npc_OnTakeDamage_Siccerino(int attacker, int victim, float damage, int weapon)
{
	damage *= f_SiccerinoExtraDamage[attacker][victim];
	
	f_SiccerinoExtraDamage[attacker][victim] += SICCERINO_BONUS_DAMAGE;
	DataPack pack;
	CreateDataTimer(SICCERINO_DEBUFF_FADE, Siccerino_revert_damageBonus, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(attacker));
	pack.WriteCell(EntIndexToEntRef(victim));		
	pack.WriteFloat(SICCERINO_BONUS_DAMAGE);		

	return damage;
}

public Action Siccerino_revert_damageBonus(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	int enemy = EntRefToEntIndex(pack.ReadCell());
	float number = pack.ReadFloat();
	if(IsValidClient(client) && IsValidEntity(enemy))
	{
		f_SiccerinoExtraDamage[client][enemy] -= number;
		if(f_SiccerinoExtraDamage[client][enemy] <= 1.0)
		{
			f_SiccerinoExtraDamage[client][enemy] = 1.0;
		}
	}
	return Plugin_Stop;
}

float f_SuperSliceTimeUntillAttack[MAXTF2PLAYERS];
float f_SuperSliceTimeUntillAttack_CD[MAXTF2PLAYERS];

public void Siccerino_ability_R(int client, int weapon, bool crit, int slot)
{
	if(Ability_Check_Cooldown(client, slot) < 0.0 && !(GetClientButtons(client) & IN_DUCK))
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Crouch for ability");	
		return;
	}
	if (Ability_Check_Cooldown(client, slot) < 0.0)
	{
		Rogue_OnAbilityUse(weapon);
		Ability_Apply_Cooldown(client, slot, 15.0); //Semi long cooldown, this is a strong buff.

		EmitSoundToAll(SICCERINO_PREPARE_SICCORS_SOUND, client, SNDCHAN_STATIC, 70, _, 0.6);
		f_SuperSliceTimeUntillAttack[client] = GetGameTime() + 1.5;
		f_SuperSliceTimeUntillAttack_CD[client] = GetGameTime();
		SDKUnhook(client, SDKHook_PreThink, Siccerino_SuperSlice);
		SDKHook(client, SDKHook_PreThink, Siccerino_SuperSlice);
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

static int BEAM_BuildingHit[MAX_TARGETS_HIT];
static float BEAM_Targets_Hit[MAXTF2PLAYERS];

static void Siccerino_SuperSlice(int client)
{
	if (!IsPlayerAlive(client))
	{
		SDKUnhook(client, SDKHook_PreThink, Siccerino_SuperSlice);
		return;
	}
	int weapon_active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(i_CustomWeaponEquipLogic[weapon_active] != WEAPON_SICCERINO)
	{
		SDKUnhook(client, SDKHook_PreThink, Siccerino_SuperSlice);
		return;
	}
	if(f_SuperSliceTimeUntillAttack_CD[client] > GetGameTime())
	{
		return;
	}
	f_SuperSliceTimeUntillAttack_CD[client] = GetGameTime() + 0.05;
	float TimeUntillSnap = f_SuperSliceTimeUntillAttack[client] - GetGameTime();
	static float belowBossEyes[3];
	belowBossEyes[0] = 0.0;
	belowBossEyes[1] = 0.0;
	belowBossEyes[2] = 0.0;
	float Angles[3];
	GetClientEyeAngles(client, Angles);

	if(TimeUntillSnap <= 0.0)
	{
		DrawBigSiccerinoSiccors(Angles, client, belowBossEyes, 0.0);
		//do damage
		SDKUnhook(client, SDKHook_PreThink, Siccerino_SuperSlice);
	}
	else if(TimeUntillSnap < 0.25)
	{
		//start closing in
		DrawBigSiccerinoSiccors(Angles, client, belowBossEyes, TimeUntillSnap * 4.0);
	}
	else
	{
		//2 beams
		DrawBigSiccerinoSiccors(Angles, client, belowBossEyes);
		//Just angle.
	}
}

void DrawBigSiccerinoSiccors(float Angles[3], int client, float belowBossEyes[3], float AngleDeviation = 1.0)
{
	Angles[1] -= (30.0 * AngleDeviation);
	float vecForward[3];
	GetAngleVectors(Angles, vecForward, NULL_VECTOR, NULL_VECTOR);
	float LaserFatness = 5.0;
	
	if(AngleDeviation == 0.0)
	{
		LaserFatness = 25.0;
	}

	float VectorTarget_2[3];
	float VectorForward = 350.0; //a really high number.
	
	GetBeamDrawStartPoint_Stock(client, belowBossEyes,{0.0,0.0,0.0}, Angles);
	VectorTarget_2[0] = belowBossEyes[0] + vecForward[0] * VectorForward;
	VectorTarget_2[1] = belowBossEyes[1] + vecForward[1] * VectorForward;
	VectorTarget_2[2] = belowBossEyes[2] + vecForward[2] * VectorForward;
	Passanger_Lightning_Effect(belowBossEyes, VectorTarget_2, 1, LaserFatness, {50,200,50});

	Angles[1] += (60.0 * AngleDeviation);
	GetAngleVectors(Angles, vecForward, NULL_VECTOR, NULL_VECTOR);
	
	GetBeamDrawStartPoint_Stock(client, belowBossEyes,{0.0,0.0,0.0}, Angles);
	VectorTarget_2[0] = belowBossEyes[0] + vecForward[0] * VectorForward;
	VectorTarget_2[1] = belowBossEyes[1] + vecForward[1] * VectorForward;
	VectorTarget_2[2] = belowBossEyes[2] + vecForward[2] * VectorForward;
	Passanger_Lightning_Effect(belowBossEyes, VectorTarget_2, 1, LaserFatness, {50,200,50});

	if(AngleDeviation == 0.0)
	{
		
		EmitSoundToAll(g_Siccerino_snapSound[GetRandomInt(0, sizeof(g_Siccerino_snapSound) - 1)],
		 client, SNDCHAN_STATIC, 90, _, 1.0);
		for (int building = 0; building < MAX_TARGETS_HIT; building++)
		{
			BEAM_BuildingHit[building] = false;
		}
		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(client);
		Handle trace;
		static float hullMin[3];
		static float hullMax[3];
		hullMin = {-20.0,-20.0,-20.0};
		hullMax = {20.0,20.0,20.0};
		trace = TR_TraceHullFilterEx(belowBossEyes, VectorTarget_2, hullMin, hullMax, 1073741824, Siccerino_TraceUsers, client);	// 1073741824 is CONTENTS_LADDER?
		delete trace;
		BEAM_Targets_Hit[client] = 1.0;
		int weapon_active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		float damage = 350.0;
		damage *= Attributes_Get(weapon_active, 2, 1.0);
		float playerPos[3];

		for (int building = 0; building < MAX_TARGETS_HIT; building++)
		{
			if (BEAM_BuildingHit[building])
			{
				if(IsValidEntity(BEAM_BuildingHit[building]))
				{
					WorldSpaceCenter(BEAM_BuildingHit[building], playerPos);

					f_SiccerinoExtraDamage[client][BEAM_BuildingHit[building]] += 0.35;
					DataPack pack1;
					CreateDataTimer(SICCERINO_DEBUFF_FADE, Siccerino_revert_damageBonus, pack1, TIMER_FLAG_NO_MAPCHANGE);
					pack1.WriteCell(EntIndexToEntRef(client));
					pack1.WriteCell(EntIndexToEntRef(BEAM_BuildingHit[building]));		
					pack1.WriteFloat(0.35);	
					float damage_force[3]; CalculateDamageForce(vecForward, 10000.0, damage_force);
					DataPack pack = new DataPack();
					pack.WriteCell(EntIndexToEntRef(BEAM_BuildingHit[building]));
					pack.WriteCell(EntIndexToEntRef(client));
					pack.WriteCell(EntIndexToEntRef(client));
					pack.WriteFloat(damage/BEAM_Targets_Hit[client]);
					pack.WriteCell(DMG_CLUB);
					pack.WriteCell(EntIndexToEntRef(weapon_active));
					pack.WriteFloat(damage_force[0]);
					pack.WriteFloat(damage_force[1]);
					pack.WriteFloat(damage_force[2]);
					pack.WriteFloat(playerPos[0]);
					pack.WriteFloat(playerPos[1]);
					pack.WriteFloat(playerPos[2]);
					pack.WriteCell(0);
					RequestFrame(CauseDamageLaterSDKHooks_Takedamage, pack);
					
					BEAM_Targets_Hit[client] *= LASER_AOE_DAMAGE_FALLOFF;
				}
				else
					BEAM_BuildingHit[building] = false;
			}
		}
		FinishLagCompensation_Base_boss();
	}
}

static bool Siccerino_TraceUsers(int entity, int contentsMask, int client)
{
	if (IsValidEntity(entity))
	{
		entity = Target_Hit_Wand_Detection(client, entity);
		if(0 < entity)
		{
			for(int i=1; i <= (MAX_TARGETS_HIT -1 ); i++)
			{
				if(!BEAM_BuildingHit[i])
				{
					BEAM_BuildingHit[i] = entity;
					break;
				}
			}
			
		}
	}
	return false;
}