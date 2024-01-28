#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = {
	"vo/sniper_paincrticialdeath01.mp3",
	"vo/sniper_paincrticialdeath02.mp3",
	"vo/sniper_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] = {
	"vo/sniper_painsharp01.mp3",
	"vo/sniper_painsharp02.mp3",
	"vo/sniper_painsharp03.mp3",
	"vo/sniper_painsharp04.mp3",
};
static const char g_IdleAlertedSounds[][] = {
	"vo/sniper_battlecry01.mp3",
	"vo/sniper_battlecry02.mp3",
	"vo/sniper_battlecry03.mp3",
	"vo/sniper_battlecry04.mp3",
};

static const char g_MeleeAttackSounds[][] = {
	"weapons/sniper_rifle_classic_shoot.wav",
};


void DesertQanaas_OnMapStart_NPC()
{
	for (int i = 0; i < (sizeof(g_DeathSounds));	   i++) { PrecacheSound(g_DeathSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_HurtSounds));		i++) { PrecacheSound(g_HurtSounds[i]);		}
	for (int i = 0; i < (sizeof(g_IdleAlertedSounds)); i++) { PrecacheSound(g_IdleAlertedSounds[i]); }
	for (int i = 0; i < (sizeof(g_MeleeAttackSounds)); i++) { PrecacheSound(g_MeleeAttackSounds[i]); }
	PrecacheModel("models/player/medic.mdl");
}


methodmap DesertQanaas < CClotBody
{
	public void PlayIdleAlertSound() 
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
		
	}
	
	public void PlayHurtSound() 
	{
		if(this.m_flNextHurtSound > GetGameTime(this.index))
			return;
			
		this.m_flNextHurtSound = GetGameTime(this.index) + 0.4;
		
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		
	}
	
	public void PlayDeathSound() 
	{
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	
	public void PlayMeleeSound()
	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_AUTO, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	
	public DesertQanaas(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		DesertQanaas npc = view_as<DesertQanaas>(CClotBody(vecPos, vecAng, "models/player/sniper.mdl", "1.0", "550", ally));
		
		i_NpcInternalId[npc.index] = INTERITUS_DESERT_QANAAS;
		i_NpcWeight[npc.index] = 1;
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		int iActivity = npc.LookupActivity("ACT_MP_RUN_PRIMARY");
		if(iActivity > 0) npc.StartActivity(iActivity);

		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");
		
		func_NPCDeath[npc.index] = view_as<Function>(DesertQanaas_NPCDeath);
		func_NPCOnTakeDamage[npc.index] = view_as<Function>(DesertQanaas_OnTakeDamage);
		func_NPCThink[npc.index] = view_as<Function>(DesertQanaas_ClotThink);
		
		npc.m_iChanged_WalkCycle = 0;

		if(npc.m_iChanged_WalkCycle != 1)
		{
			npc.m_bisWalking = true;
			npc.m_iChanged_WalkCycle = 1;
			npc.SetActivity("ACT_MP_RUN_PRIMARY");
			npc.StartPathing();
			npc.m_flSpeed = 200.0;
		}	
		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		
		
		//IDLE
		npc.m_iState = 0;
		npc.m_flGetClosestTargetTime = 0.0;
		
		
		int skin = 1;
		SetEntProp(npc.index, Prop_Send, "m_nSkin", skin);

		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_tfc_sniperrifle/c_tfc_sniperrifle.mdl");
		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/sniper/kerch.mdl");
		npc.m_iWearable3 = npc.EquipItem("head", "models/player/items/sniper/desert_marauder.mdl");
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/sniper/sum23_bushman/sum23_bushman.mdl");

		SetEntProp(npc.m_iWearable1, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", skin);
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", skin);
		
		return npc;
	}
}

public void DesertQanaas_ClotThink(int iNPC)
{
	DesertQanaas npc = view_as<DesertQanaas>(iNPC);
	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
	{
		return;
	}
	npc.m_flNextDelayTime = GetGameTime(npc.index) + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}
	
	if(npc.m_flNextThinkTime > GetGameTime(npc.index))
	{
		return;
	}
	npc.m_flNextThinkTime = GetGameTime(npc.index) + 0.1;

	if(npc.m_flGetClosestTargetTime < GetGameTime(npc.index))
	{
		npc.m_iTargetWalkTo = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = GetGameTime(npc.index) + GetRandomRetargetTime();
	}
	
	if(IsValidEnemy(npc.index, npc.m_iTargetWalkTo))
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenterOld(npc.m_iTargetWalkTo);
	
		float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenterOld(npc.index), true);
		int ExtraBehavior = DesertQanaasSelfDefense(npc,GetGameTime(npc.index)); 

		switch(ExtraBehavior)
		{
			case 0:
			{
				if(npc.m_iChanged_WalkCycle != 1)
				{
					npc.m_bisWalking = true;
					npc.m_iChanged_WalkCycle = 1;
					npc.SetActivity("ACT_MP_RUN_PRIMARY");
					npc.StartPathing();
					npc.m_flSpeed = 200.0;
				}	
			}
			case 1:
			{
				if(npc.m_iChanged_WalkCycle != 2)
				{
					npc.m_bisWalking = false;
					npc.m_iChanged_WalkCycle = 2;
					npc.SetActivity("ACT_MP_DEPLOYED_PRIMARY");
					npc.StopPathing();
					npc.m_flSpeed = 0.0;
				}
			}
		}

		if(flDistanceToTarget < npc.GetLeadRadius()) 
		{
			float vPredictedPos[3];
			vPredictedPos = PredictSubjectPositionOld(npc, npc.m_iTargetWalkTo);
			NPC_SetGoalVector(npc.index, vPredictedPos);
		}
		else 
		{
			NPC_SetGoalEntity(npc.index, npc.m_iTargetWalkTo);
		}
	}
	else
	{
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTargetWalkTo = GetClosestTarget(npc.index);
	}
	npc.PlayIdleAlertSound();
}

public Action DesertQanaas_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	DesertQanaas npc = view_as<DesertQanaas>(victim);
		
	if(attacker <= 0)
		return Plugin_Continue;
		
	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	
	return Plugin_Changed;
}

public void DesertQanaas_NPCDeath(int entity)
{
	DesertQanaas npc = view_as<DesertQanaas>(entity);
	if(!npc.m_bGib)
	{
		npc.PlayDeathSound();	
	}
		
	
	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);

}

int DesertQanaasSelfDefense(DesertQanaas npc, float gameTime)
{
	if(!npc.m_flAttackHappens)
	{
		if(IsValidEnemy(npc.index,npc.m_iTarget))
		{
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
			{
				npc.m_iTarget = GetClosestTarget(npc.index,_,_,_,_,_,_,true,_,_,true);
			}
		}
		else
		{
			npc.m_iTarget = GetClosestTarget(npc.index,_,_,_,_,_,_,true,_,_,true);
			if(!IsValidEnemy(npc.index,npc.m_iTarget))
			{
				return 0;
			}		
		}
		if(!IsValidEnemy(npc.index,npc.m_iTarget))
		{
			return 0;
		}
	}
	npc.FaceTowards(WorldSpaceCenterOld(npc.m_iTarget), 15000.0);

	static float ThrowPos[MAXENTITIES][3];  
	float origin[3], angles[3];
	view_as<CClotBody>(npc.m_iWearable1).GetAttachment("muzzle", origin, angles);
	if(npc.m_flDoingAnimation > gameTime)
	{
		if(Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
		{
			ThrowPos[npc.index] = WorldSpaceCenterOld(npc.m_iTarget);
		}
	}
	else
	{	
		if(npc.m_flAttackHappens)
		{
			float pos_npc[3];
			pos_npc = WorldSpaceCenterOld(npc.index);
			float AngleAim[3];
			GetVectorAnglesTwoPoints(pos_npc, ThrowPos[npc.index], AngleAim);
			Handle hTrace = TR_TraceRayFilterEx(pos_npc, AngleAim, MASK_SOLID, RayType_Infinite, BulletAndMeleeTrace, npc.index);
			int Traced_Target = TR_GetEntityIndex(hTrace);
			if(Traced_Target > 0)
			{
				ThrowPos[npc.index] = WorldSpaceCenterOld(Traced_Target);
			}
			else if(TR_DidHit(hTrace))
			{
				TR_GetEndPosition(ThrowPos[npc.index], hTrace);
			}
		}
	}
	if(npc.m_flAttackHappens)
	{
		TE_SetupBeamPoints(origin, ThrowPos[npc.index], Shared_BEAM_Laser, 0, 0, 0, 0.11, 5.0, 5.0, 0, 0.0, {0,0,255,255}, 3);
		TE_SendToAll(0.0);
	}
			
	npc.FaceTowards(ThrowPos[npc.index], 15000.0);
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < gameTime)
		{
			npc.m_flAttackHappens = 0.0;
			
			int target = Can_I_See_Enemy(npc.index, npc.m_iTarget,_ ,ThrowPos[npc.index]);
			ShootLaser(npc.m_iWearable1, "bullet_tracer02_blue_crit", origin, ThrowPos[npc.index], false );
			npc.PlayMeleeSound();
			npc.AddGesture("ACT_MP_ATTACK_STAND_PRIMARY");
			if(IsValidEnemy(npc.index, target))
			{
				float damageDealt = 50.0;
				if(ShouldNpcDealBonusDamage(target))
					damageDealt *= 10.5;

				SDKHooks_TakeDamage(target, npc.index, npc.index, damageDealt, DMG_BULLET, -1, _, ThrowPos[npc.index]);
			} 
		}
	}

	if(gameTime > npc.m_flNextMeleeAttack)
	{
		
		npc.m_flAttackHappens = gameTime + 1.25;
		npc.m_flDoingAnimation = gameTime + 0.9;
		npc.m_flNextMeleeAttack = gameTime + 2.5;
	}
	return 1;
}