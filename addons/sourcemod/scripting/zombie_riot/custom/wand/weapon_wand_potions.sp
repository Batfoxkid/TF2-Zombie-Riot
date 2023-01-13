#pragma semicolon 1
#pragma newdecls required

#define PARTICLE_JARATE		""
#define PARTICLE_MADMILK	""
#define PARTICLE_SHRINK		""
#define SOUND_JAREXPLODE	"weapons/weapons/jar_explode.wav"
#define SOUND_TRANSFORM1	"ambient/halloween/thunder_04.wav"
#define SOUND_TRANSFORM2	"ambient/halloween/thunder_01.wav"
#define SOUND_SHRINK		"items/powerup_pickup_plague_infected.wav"

void Wand_Potions_Precache()
{
	PrecacheSound(SOUND_JAREXPLODE);
	PrecacheSound(SOUND_TRANSFORM1);
	PrecacheSound(SOUND_TRANSFORM2);
	PrecacheSound(SOUND_SHRINK);
}

public void Weapon_Wand_PotionBasicM1(int client, int weapon, bool &crit, int slot)
{
	PotionM1(client, weapon, Weapon_Wand_PotionBasicTouch);
}

public void Weapon_Wand_PotionBasicM2(int client, int weapon, bool &crit, int slot)
{
	PotionM2(client, weapon, slot, 3.0, Weapon_Wand_PotionBasicTouch);
}

public void Weapon_Wand_PotionBuffM2(int client, int weapon, bool &crit, int slot)
{
	PotionM2(client, weapon, slot, 4.5, Weapon_Wand_PotionBuffTouch);
}

public void Weapon_Wand_PotionBuffAllM2(int client, int weapon, bool &crit, int slot)
{
	PotionM2(client, weapon, slot, 6.0, Weapon_Wand_PotionBuffAllTouch);
}

public void Weapon_Wand_PotionBuffPermaM2(int client, int weapon, bool &crit, int slot)
{
	PotionM2(client, weapon, slot, 6.0, Weapon_Wand_PotionBuffPermaTouch);
}

public void Weapon_Wand_PotionUnstableM1(int client, int weapon, bool &crit, int slot)
{
	PotionM1(client, weapon, Weapon_Wand_PotionUnstableTouch);
}

public void Weapon_Wand_PotionLeadM1(int client, int weapon, bool &crit, int slot)
{
	PotionM1(client, weapon, Weapon_Wand_PotionLeadTouch);
}

public void Weapon_Wand_PotionGoldM1(int client, int weapon, bool &crit, int slot)
{
	PotionM1(client, weapon, Weapon_Wand_PotionGoldTouch);
}

public void Weapon_Wand_PotionShrinkM2(int client, int weapon, bool &crit, int slot)
{
	if(IsValidEntity(EntRefToEntIndex(RaidBossActive)))
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		return;
	}

	PotionM2(client, weapon, slot, 45.0, Weapon_Wand_PotionShrinkTouch);
}

static void PotionM2(int client, int weapon, int slot, float cooldown, SDKHookCB touch)
{
	if(Ability_Check_Cooldown(client, slot) > 0.0)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_Check_Cooldown(client, slot));
		return;
	}

	if(PotionM1(client, weapon, touch))
		Ability_Apply_Cooldown(client, slot, 6.0);
}

static bool PotionM1(int client, int weapon, SDKHookCB touch)
{
	int mana_cost;
	Address address = TF2Attrib_GetByDefIndex(weapon, 733);
	if(address != Address_Null)
		mana_cost = RoundToCeil(TF2Attrib_GetValue(address));
	
	if(Current_Mana[client] < mana_cost)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client, SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.5);
		return false;
	}

	Mana_Regen_Delay[client] = GetGameTime() + 1.0;
	Mana_Hud_Delay[client] = 0.0;
	Current_Mana[client] -= mana_cost;
	delay_hud[client] = 0.0;

	int entity = CreateEntityByName("tf_projectile_pipe");
	if(entity > MaxClients)
	{
		float pos[3], ang[3], vel[3];
		GetClientEyeAngles(client, ang);
		GetClientEyePosition(client, pos);

		float speed = 1000.0;
		address = TF2Attrib_GetByDefIndex(weapon, 103);
		if(address != Address_Null)
			speed *= TF2Attrib_GetValue(address);
		
		vel[0] = Cosine(DegToRad(ang[0])) * Cosine(DegToRad(ang[1])) * speed;
		vel[1] = Cosine(DegToRad(ang[0])) * Sine(DegToRad(ang[1])) * speed;
		vel[2] = Sine(DegToRad(ang[0])) * -speed;

		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", TFTeam_Red);
		SetEntProp(entity, Prop_Send, "m_nSkin", 0);
		SetEntPropEnt(entity, Prop_Send, "m_hThrower", client);
		SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", weapon);
		SetEntPropEnt(entity, Prop_Send, "m_hLauncher", weapon);

		int model = GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex");
		for(int i; i < 4; i++)
		{
			SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, i);
		}
		
		DispatchSpawn(entity);
		TeleportEntity(entity, pos, ang, vel);
		IsCustomTfGrenadeProjectile(entity, 1999999.0);	// Block normal explosion
		SDKHook(entity, SDKHook_StartTouchPost, touch);
	}
	return true;
}

public void Weapon_Wand_PotionBasicTouch(int entity, int target)
{
	if(target)
	{
		if(target <= MaxClients)
			return;
		
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") == TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionBasicTouch);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	ParticleEffectAt(pos1, PARTICLE_JARATE, 2.0);
	EmitSoundToAll(SOUND_JAREXPLODE, entity, _, _, _, _, _, _, pos1);
	
	float damage = 32.5;
	address = TF2Attrib_GetByDefIndex(weapon, 410);
	if(address != Address_Null)
		damage *= TF2Attrib_GetValue(address);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

	int count;
	int i = MaxClients + 1;
	while((i = FindEntityByClassname(i, "base_boss")) != -1)
	{
		if(!b_NpcHasDied[i] && GetEntProp(i, Prop_Send, "m_iTeamNum") != 2)
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS))
			{
				SDKHooks_TakeDamage(i, entity, owner, damage, DMG_SLASH, weapon, _, pos1);
				StartBleedingTimer(i, owner, damage / 8.0, 8, weapon);
				if(++count > 4)
					break;
			}
		}
	}

	RemoveEntity(entity);
}

public void Weapon_Wand_PotionBuffTouch(int entity, int target)
{
	if(target)
	{
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") != TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionBuffTouch);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	ParticleEffectAt(pos1, PARTICLE_MADMILK, 2.0);
	EmitSoundToAll(SOUND_JAREXPLODE, entity, _, _, _, _, _, _, pos1);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS))
			{
				i_ExtraPlayerPoints[owner] += 10;
				TF2_AddCondition(client, TFCond_Buffed, 5.5, owner);
				break;
			}
		}
	}

	RemoveEntity(entity);
}

public void Weapon_Wand_PotionBuffAllTouch(int entity, int target)
{
	if(target)
	{
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") != TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionBuffAllTouch);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	ParticleEffectAt(pos1, PARTICLE_MADMILK, 2.0);
	EmitSoundToAll(SOUND_JAREXPLODE, entity, _, _, _, _, _, _, pos1);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS))
			{
				i_ExtraPlayerPoints[owner] += 12;
				TF2_AddCondition(client, TFCond_Buffed, 7.5, owner);
			}
		}
	}

	RemoveEntity(entity);
}

public void Weapon_Wand_PotionBuffPermaTouch(int entity, int target)
{
	if(target)
	{
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") != TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionBuffPermaTouch);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	ParticleEffectAt(pos1, PARTICLE_MADMILK, 2.0);
	EmitSoundToAll(SOUND_JAREXPLODE, entity, _, _, _, _, _, _, pos1);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS))
			{
				i_ExtraPlayerPoints[owner] += 20;
				TF2_AddCondition(client, TFCond_Buffed, _, owner);
			}
		}
	}

	RemoveEntity(entity);
}

public void Weapon_Wand_PotionUnstableTouch(int entity, int target)
{
	if(target)
	{
		if(target <= MaxClients)
			return;
		
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") == TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionUnstableTouch);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	ParticleEffectAt(pos1, PARTICLE_JARATE, 2.0);
	EmitSoundToAll(SOUND_JAREXPLODE, entity, _, _, _, _, _, _, pos1);
	
	float damage = 32.5;
	address = TF2Attrib_GetByDefIndex(weapon, 410);
	if(address != Address_Null)
		damage *= TF2Attrib_GetValue(address);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

	int count;
	int i = MaxClients + 1;
	while((i = FindEntityByClassname(i, "base_boss")) != -1)
	{
		if(!b_NpcHasDied[i] && GetEntProp(i, Prop_Send, "m_iTeamNum") != 2)
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS))
			{
				SDKHooks_TakeDamage(i, entity, owner, damage, DMG_SLASH, weapon, _, pos1);
				StartBleedingTimer(i, owner, damage / 8.0, 8, weapon);

				f_BombEntityWeaponDamageApplied[i][owner] = damage / 8.0;
				i_HowManyBombsOnThisEntity[i][owner] += 2;
				Apply_Particle_Teroriser_Indicator(i);

				if(++count > 4)
					break;
			}
		}
	}

	RemoveEntity(entity);
}

public void Weapon_Wand_PotionTransM2(int client, int weapon, bool &crit, int slot)
{
	if(Ability_Check_Cooldown(client, slot) > 0.0)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_Check_Cooldown(client, slot));
		return;
	}

	Mana_Regen_Delay[client] = GetGameTime() + 10.0;
	Mana_Hud_Delay[client] = 0.0;
	delay_hud[client] = 0.0;
	Ability_Apply_Cooldown(client, slot, 45.0);

	EmitSoundToClient(client, SOUND_TRANSFORM1);
	i_ClientHasCustomGearEquipped[client] = true;

	ApplyTempAttrib(weapon, 6, 0.2);
	ApplyTempAttrib(weapon, 410, 0.5);
}

public void Weapon_Wand_PotionTransBuffM2(int client, int weapon, bool &crit, int slot)
{
	if(Ability_Check_Cooldown(client, slot) > 0.0)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_Check_Cooldown(client, slot));
		return;
	}

	Mana_Regen_Delay[client] = GetGameTime() + 10.0;
	Mana_Hud_Delay[client] = 0.0;
	delay_hud[client] = 0.0;
	Ability_Apply_Cooldown(client, slot, 45.0);

	EmitSoundToClient(client, SOUND_TRANSFORM2);
	i_ClientHasCustomGearEquipped[client] = true;

	ApplyTempAttrib(weapon, 6, 0.2);
	ApplyTempAttrib(weapon, 410, 0.5);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	
	int count;
	for(int target = 1; target <= MaxClients; target++)
	{
		if(client != target && IsClientInGame(target) && IsPlayerAlive(target))
		{
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < 40000) // 200 HU
			{
				i_ExtraPlayerPoints[owner] += 10;

				int weapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
				if(weapon != -1)
				{
					ApplyTempAttrib(weapon, 2, 0.666);
					ApplyTempAttrib(weapon, 6, 0.333);
					ApplyTempAttrib(weapon, 97, 0.333);
					ApplyTempAttrib(weapon, 410, 0.666);
					EmitSoundToClient(target, SOUND_TRANSFORM2);

					if(++count > 2)
						break;
				}
			}
		}
	}
}

static void ApplyTempAttrib(int entity, int index, float multi)
{
	Address address = TF2Attrib_GetByDefIndex(entity, index);
	if(address != Address_Null)
	{
		TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) * multi);

		DataPack pack;
		CreateDataTimer(10.0, StreetFighter_RestoreAttrib, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteCell(index);
		pack.WriteFloat(multi);
	}
}

public Action Weapon_Wand_PotionRestoreAttrib(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity != INVALID_ENT_REFERENCE)
	{
		Address address = TF2Attrib_GetByDefIndex(entity, pack.ReadCell());
		if(address != Address_Null)
			TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) / pack.ReadFloat());
	}
	return Plugin_Stop;
}

public void Weapon_Wand_PotionLeadTouch(int entity, int target)
{
	if(target)
	{
		if(target <= MaxClients)
			return;
		
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") == TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionLeadTouch);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	ParticleEffectAt(pos1, PARTICLE_JARATE, 2.0);
	EmitSoundToAll(SOUND_JAREXPLODE, entity, _, _, _, _, _, _, pos1);
	
	float damage = 32.5;
	address = TF2Attrib_GetByDefIndex(weapon, 410);
	if(address != Address_Null)
		damage *= TF2Attrib_GetValue(address);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

	int count;
	int i = MaxClients + 1;
	while((i = FindEntityByClassname(i, "base_boss")) != -1)
	{
		if(!b_NpcHasDied[i] && GetEntProp(i, Prop_Send, "m_iTeamNum") != 2)
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS))
			{
				if(view_as<CClotBody>(i).m_iBleedType == BLEEDTYPE_METAL)
				{
					SDKHooks_TakeDamage(i, entity, owner, damage, DMG_SLASH, weapon, _, pos1);
					StartBleedingTimer(i, owner, damage / 4.0, 20, weapon);
				}
				else
				{
					SDKHooks_TakeDamage(i, entity, owner, damage, DMG_SLASH, weapon, _, pos1);
					StartBleedingTimer(i, owner, damage / 8.0, 8, weapon);
				}

				if(++count > 4)
					break;
			}
		}
	}

	RemoveEntity(entity);
}

public void Weapon_Wand_PotionGoldTouch(int entity, int target)
{
	if(target)
	{
		if(target <= MaxClients)
			return;
		
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") == TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionGoldTouch);

	float pos1[3], pos2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
	ParticleEffectAt(pos1, PARTICLE_JARATE, 2.0);
	EmitSoundToAll(SOUND_JAREXPLODE, entity, _, _, _, _, _, _, pos1);
	
	float damage = 32.5;
	address = TF2Attrib_GetByDefIndex(weapon, 410);
	if(address != Address_Null)
		damage *= TF2Attrib_GetValue(address);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

	int count;
	int i = MaxClients + 1;
	while((i = FindEntityByClassname(i, "base_boss")) != -1)
	{
		if(!b_NpcHasDied[i] && GetEntProp(i, Prop_Send, "m_iTeamNum") != 2)
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS))
			{
				if(view_as<CClotBody>(i).m_iBleedType == BLEEDTYPE_METAL)
				{
					SDKHooks_TakeDamage(i, entity, owner, damage, DMG_SLASH, weapon, _, pos1);
					StartBleedingTimer(i, owner, damage / 4.0, 20, weapon);
				}
				else
				{
					SDKHooks_TakeDamage(i, entity, owner, damage, DMG_SLASH, weapon, _, pos1);
					StartBleedingTimer(i, owner, damage / 8.0, 8, weapon);
				}

				float time = GetGameTime() + 3.0;
				if(f_CrippleDebuff[i] < time)
					f_CrippleDebuff[i] = time;
				
				if(++count > 4)
					break;
			}
		}
	}

	RemoveEntity(entity);
}

public void Weapon_Wand_PotionShrinkTouch(int entity, int target)
{
	if(target)
	{
		if(target <= MaxClients)
			return;
		
		if(GetEntProp(target, Prop_Send, "m_iTeamNum") == TFTeam_Red)
			return;
	}

	SDKUnhook(entity, SDKHook_StartTouchPost, Weapon_Wand_PotionShrinkTouch);

	if(!IsValidEntity(EntRefToEntIndex(RaidBossActive)))
	{
		float pos1[3], pos2[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos1);
		ParticleEffectAt(pos1, PARTICLE_SHRINK, 2.0);
		EmitSoundToAll(SOUND_SHRINK, entity, _, _, _, _, _, _, pos1);
		
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

		int count;
		int i = MaxClients + 1;
		while((i = FindEntityByClassname(i, "base_boss")) != -1)
		{
			if(!b_NpcHasDied[i] && !b_thisNpcIsABoss[i] && GetEntProp(i, Prop_Send, "m_iTeamNum") != 2)
			{
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos2);
				if(GetVectorDistance(pos1, pos2, true) < (EXPLOSION_RADIUS * EXPLOSION_RADIUS * 2))
				{
					f_MaimDebuff[i] = FAR_FUTURE;
					f_CrippleDebuff[i] = FAR_FUTURE;

					float scale = GetEntPropFloat(i, Prop_Send, "m_flModelScale");
					SetEntPropFloat(i, Prop_Send, "m_flModelScale", scale * 0.35);
					
					if(++count > 1)
						break;
				}
			}
		}
	}

	RemoveEntity(entity);
}