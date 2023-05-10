#pragma semicolon 1
#pragma newdecls required
 
static const char g_DeathSounds[][] =
{
	"npc/zombie/zombie_die1.wav",
	"npc/zombie/zombie_die2.wav",
	"npc/zombie/zombie_die3.wav"
};

static const char g_HurtSounds[][] =
{
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
	"npc/zombie/zombie_pain6.wav"
};

static const char g_IdleAlertedSounds[][] =
{
	"npc/zombie/zombie_alert1.wav",
	"npc/zombie/zombie_alert2.wav",
	"npc/zombie/zombie_alert3.wav"
};

static const char g_MeleeHitSounds[][] =
{
	"npc/fast_zombie/claw_strike1.wav",
	"npc/fast_zombie/claw_strike2.wav",
	"npc/fast_zombie/claw_strike3.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"npc/zombie/zo_attack1.wav",
	"npc/zombie/zo_attack2.wav"
};

methodmap SeaSlider < CClotBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME,_);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
	}
	public void PlayHurtSound()
	{
		EmitSoundToAll(g_HurtSound[GetRandomInt(0, sizeof(g_HurtSound) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME,_);
	}
	public void PlayDeathSound() 
	{
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME,_);
	}
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME,_);
	}
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME,_);	
	}
	
	public SeaSlider(int client, float vecPos[3], float vecAng[3], bool ally, const char[] data)
	{
		SeaSlider npc = view_as<SeaSlider>(CClotBody(vecPos, vecAng, "models/zombie/classic.mdl", "1.15", data[0] ? "540" : "420", ally, false));
		// 2800 x 0.15
		// 3600 x 0.15

		i_NpcInternalId[npc.index] = data[0] ? SEASLIDER_ALT : SEASLIDER;
		npc.SetActivity("ACT_WALK_ON_FIRE");
		
		npc.m_iBleedType = BLEEDTYPE_SEABORN;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_SEABORN;
		
		SDKHook(npc.index, SDKHook_OnTakeDamage, SeaSlider_TakeDamage);
		SDKHook(npc.index, SDKHook_Think, SeaSlider_ClotThink);
		
		npc.m_flSpeed = 275.0;	// 1.1 x 250
		npc.m_flGetClosestTargetTime = 0.0;
		
		SetEntityRenderMode(npc.index, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.index, 50, 50, 255, 255);
		
		npc.StartPathing();
		return npc;
	}
}

public void SeaSlider_ClotThink(int iNPC)
{
	SeaSlider npc = view_as<SeaSlider>(iNPC);

	if(i_NpcInternalId[npc.index] == SEASLIDER_ALT)
	{
		SetVariantInt(1);
		AcceptEntityInput(npc.index, "SetBodyGroup");
	}

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_GESTURE_FLINCH_HEAD", false);
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}
	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	if(npc.m_iTarget && !IsValidEnemy(npc.index, npc.m_iTarget))
		npc.m_iTarget = 0;
	
	if(!npc.m_iTarget || npc.m_flGetClosestTargetTime < gameTime)
	{
		npc.m_iTarget = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = gameTime + 1.0;
	}
	
	if(npc.m_iTarget > 0)
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
		float distance = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);		
		
		if(distance < npc.GetLeadRadius())
		{
			float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, npc.m_iTarget);
			PF_SetGoalVector(npc.index, vPredictedPos);
		}
		else 
		{
			PF_SetGoalEntity(npc.index, npc.m_iTarget);
		}

		npc.StartPathing();
		
		if(npc.m_flAttackHappens)
		{
			if(npc.m_flAttackHappens < gameTime)
			{
				npc.m_flAttackHappens = 0.0;
				
				Handle swingTrace;
				npc.FaceTowards(vecTarget, 15000.0);
				if(npc.DoSwingTrace(swingTrace, npc.m_iTarget, _, _, _, _))
				{
					int target = TR_GetEntityIndex(swingTrace);	
					
					float vecHit[3];
					TR_GetEndPosition(vecHit, swingTrace);

					if(target > 0) 
					{
						npc.PlayMeleeHitSound();
						SDKHooks_TakeDamage(target, npc.index, npc.index, i_NpcInternalId[npc.index] == SEASLIDER_ALT ? 54.0 : 42.0, DMG_CLUB);
						// 280 x 0.15
						// 360 x 0.15

						SeaSlider_AddNeuralDamage(target, npc.index, npc.index, i_NpcInternalId[npc.index] == SEASLIDER_ALT ? 9 : 7);
						// 280 x 0.15 x 0.15
						// 360 x 0.15 x 0.15
					}
				}

				delete swingTrace;
			}
		}

		if(distance < 10000.0)
		{
			int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
			if(IsValidEnemy(npc.index, target))
			{
				npc.m_iTarget = target;

				npc.AddGesture("ACT_RANGE_ATTACK1");

				npc.PlayMeleeSound();
				
				npc.m_flAttackHappens = gameTime + 0.45;

				//npc.m_flDoingAnimation = gameTime + 1.2;
				npc.m_flNextMeleeAttack = gameTime + 2.0;
				npc.m_flHeadshotCooldown = gameTime + 2.0;
			}
		}
	}
	else
	{
		npc.StopPathing();
	}

	npc.PlayIdleSound();
}

public Action SeaSlider_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker < 1)
		return Plugin_Continue;
		
	SeaSlider npc = view_as<SeaSlider>(victim);
	if(npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	return Plugin_Changed;
}

void SeaSlider_NPCDeath(int entity)
{
	SeaSlider npc = view_as<SeaSlider>(entity);
	if(!npc.m_bGib)
		npc.PlayDeathSound();
	
	SDKUnhook(npc.index, SDKHook_OnTakeDamage, SeaSlider_TakeDamage);
	SDKUnhook(npc.index, SDKHook_Think, SeaSlider_ClotThink);
}

void SeaSlider_AddNeuralDamage(int victim, int attacker, int damage)
{
	if(victim > MaxClients)
	{
		int health = Building_GetBuildingRepair(victim);
		if(health > 0)
		{
			health -= damage * 5;
			if(health < 0)
				health = 0;
			
			Building_SetBuildingRepair(victim, health);
		}
	}
	else if(Armor_Charge[victim] < 1)
	{
		Armor_Charge[victim] -= damage;
		if(Armor_Charge[victim] < (-MaxArmorCalculation(Armor_Level[client], victim, 1.0)))
		{
			Armor_Charge[victim] = 0;
			SDKHooks_TakeDamage(victim, attacker, attacker, 500.0, DMG_SLASH);
			TF2_StunPlayer(victim, 5.0, 0.9, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_CHEERSOUND);
		}
	}
}