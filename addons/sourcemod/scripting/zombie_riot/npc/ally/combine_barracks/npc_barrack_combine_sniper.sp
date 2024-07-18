#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"npc/metropolice/die1.wav",
	"npc/metropolice/die2.wav",
	"npc/metropolice/die3.wav",
	"npc/metropolice/die4.wav"
};

static const char g_IdleSounds[][] =
{
	"npc/combine_soldier/vo/alert1.wav",
	"npc/combine_soldier/vo/bouncerbouncer.wav",
	"npc/combine_soldier/vo/boomer.wav",
	"npc/combine_soldier/vo/contactconfirm.wav",
};

static const char g_RangedAttackSounds[][] =
{
	"weapons/csgo_awp_shoot.wav",
};

static const char g_RangedReloadSound[][] =
{
	"weapons/pistol/pistol_reload1.wav",
};

static const char g_IdleAlert[][] =
{
	"npc/combine_soldier/vo/alert1.wav",
	"npc/combine_soldier/vo/bouncerbouncer.wav",
	"npc/combine_soldier/vo/boomer.wav",
	"npc/combine_soldier/vo/contactconfim.wav",
};

void Barracks_Combine_Sniper_Precache()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_IdleSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	PrecacheSoundArray(g_RangedReloadSound);
	PrecacheSoundArray(g_IdleAlert);
	
	PrecacheModel("models/player/hwm/sniper.mdl");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Barracks Combine Sniper");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_barrack_combine_sniper");
	data.IconCustom = false;
	data.Flags = 0;
	data.Category = Type_Ally;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int ally)
{
	return Barrack_Combine_Sniper(client, vecPos, vecAng, ally);
}

methodmap Barrack_Combine_Sniper < BarrackBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_IdleSounds[GetRandomInt(0, sizeof(g_IdleSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 100);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(24.0, 48.0);
	}
	public void PlayIdleAlertSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_IdleAlert[GetRandomInt(0, sizeof(g_IdleAlert) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 100);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
	}
	public void PlayRangedSound() {
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeHitSound()");
		#endif
	}
	public void PlayPistolReload()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_RangedReloadSound[GetRandomInt(0, sizeof(g_RangedReloadSound) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
	}
	public void PlayNPCDeath()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 100);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
	}

	public Barrack_Combine_Sniper(int client, float vecPos[3], float vecAng[3], int ally)
	{
		Barrack_Combine_Sniper npc = view_as<Barrack_Combine_Sniper>(BarrackBody(client, vecPos, vecAng, "235", COMBINE_CUSTOM_MODEL, STEPTYPE_COMBINE,_,_,"models/pickups/pickup_powerup_precision.mdl"));
		
		i_NpcWeight[npc.index] = 1;
		
		func_NPCOnTakeDamage[npc.index] = BarrackBody_OnTakeDamage;
		func_NPCDeath[npc.index] = Barrack_Combine_Sniper_NPCDeath;
		func_NPCThink[npc.index] = Barrack_Combine_Sniper_ClotThink;
		npc.m_flSpeed = 150.0;

		npc.m_iAttacksTillReload = 1;
		npc.m_flNextRangedAttack = 0.0;
		
		KillFeed_SetKillIcon(npc.index, "sniperrifle");

		int skin = 1;
		
		npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/weapons/c_models/c_csgo_awp/c_csgo_awp.mdl");
		SetVariantString("1.15");
		AcceptEntityInput(npc.m_iWearable1, "SetModelScale");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/sniper/headhunters_wrap/headhunters_wrap.mdl");
		SetVariantString("1.2");
		AcceptEntityInput(npc.m_iWearable2, "SetModelScale");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/engineer/sum21_sightliner/sum21_sightliner.mdl"); //find it properly
		SetVariantString("1.2");
		AcceptEntityInput(npc.m_iWearable2, "SetModelScale");

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/sniper/sum19_bare_necessities/sum19_bare_necessities.mdl");
		SetVariantString("1.15");
		AcceptEntityInput(npc.m_iWearable1, "SetModelScale");

		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", skin);
		
		return npc;
	}
}

public void Barrack_Combine_Sniper_ClotThink(int iNPC)
{
	Barrack_Combine_Sniper npc = view_as<Barrack_Combine_Sniper>(iNPC);
	float GameTime = GetGameTime(iNPC);
	if(BarrackBody_ThinkStart(npc.index, GameTime))
	{
		int client = BarrackBody_ThinkTarget(npc.index, true, GameTime);
		BarrackBody_ThinkTarget(npc.index, true, GameTime);
		int PrimaryThreatIndex = npc.m_iTarget;
		if(PrimaryThreatIndex > 0)
		{
			npc.PlayIdleAlertSound();
			float vecTarget[3]; WorldSpaceCenter(PrimaryThreatIndex, vecTarget);
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			float flDistanceToTarget = GetVectorDistance(vecTarget, VecSelfNpc, true);

			if(flDistanceToTarget < 800000.0)
			{
				int Enemy_I_See = Can_I_See_Enemy(npc.index, PrimaryThreatIndex);
				//Target close enough to hit
				if(IsValidEnemy(npc.index, Enemy_I_See))
				{
					//Can we attack right now?
					if(npc.m_iAttacksTillReload < 1)
					{
						npc.AddGesture("ACT_RELOAD_SHOTGUN1");
						npc.m_flNextRangedAttack = GameTime + 1.5;
						npc.m_iAttacksTillReload = 1;
						npc.PlayPistolReload();
					}
					if(npc.m_flNextRangedAttack < GameTime)
					{
						npc.AddGesture("ACT_GESTURE_RANGE_ATTACK_RPG", false);
						npc.m_iTarget = Enemy_I_See;
						npc.PlayRangedSound();
						npc.FaceTowards(vecTarget, 800000.0);
						Handle swingTrace;
						if(npc.DoSwingTrace(swingTrace, PrimaryThreatIndex, { 9999.0, 9999.0, 9999.0 }))
						{
							int target = TR_GetEntityIndex(swingTrace);	
								
							float vecHit[3];
							TR_GetEndPosition(vecHit, swingTrace);
							float origin[3], angles[3];
							view_as<CClotBody>(npc.m_iWearable1).GetAttachment("muzzle", origin, angles);
							ShootLaser(npc.m_iWearable1, "bullet_tracer02_red", origin, vecHit, false );
							
							npc.m_flNextRangedAttack = GameTime + (1.5 * npc.BonusFireRate);
							npc.m_iAttacksTillReload = 0;
							npc.m_flSpeed = 0.0;
							
							SDKHooks_TakeDamage(target, npc.index, client, Barracks_UnitExtraDamageCalc(npc.index, GetClientOfUserId(npc.OwnerUserId), 8000.0, 1), DMG_CLUB, -1, _, vecHit);
						} 		
						delete swingTrace;				
					}
					else
					{
						npc.m_flSpeed = 150.0;
					}
				}
			}
		}
		else
		{
			npc.PlayIdleSound();
		}

		BarrackBody_ThinkMove(npc.index, 150.0, "ACT_IDLE_ANGRY_RPG", "ACT_RUN_RPG", 750000.0,_, true);
	}
}

void Barrack_Combine_Sniper_NPCDeath(int entity)
{
	Barrack_Combine_Sniper npc = view_as<Barrack_Combine_Sniper>(entity);
	BarrackBody_NPCDeath(npc.index);
	npc.PlayNPCDeath();
}