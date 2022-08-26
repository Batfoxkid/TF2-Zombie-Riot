
static char g_DeathSounds[][] = {
	"npc/fast_zombie/wake1.wav",
};

static char g_HurtSounds[][] = {
	"npc/fast_zombie/wake1.wav",
};

static char g_leap_prepare[][] = {
	"npc/fast_zombie/leap1.wav",
};

static char g_leap_scream[][] = {
	"npc/fast_zombie/fz_scream1.wav",
};

static char g_IdleSounds[][] = {
	"npc/fast_zombie/idle1.wav",
	"npc/fast_zombie/idle2.wav",
	"npc/fast_zombie/idle3.wav",
};

static char g_IdleAlertedSounds[][] = {
	"npc/fast_zombie/fz_alert_close1.wav",
	"npc/fast_zombie/fz_alert_far1.wav",
};

static char g_MeleeHitSounds[][] = {
	"npc/fast_zombie/claw_strike1.wav",
	"npc/fast_zombie/claw_strike2.wav",
	"npc/fast_zombie/claw_strike3.wav",
};
static char g_MeleeAttackSounds[][] = {
	"npc/fast_zombie/fz_frenzy1.wav",
};

static char g_MeleeMissSounds[][] = {
	"npc/fast_zombie/claw_miss1.wav",
	"npc/fast_zombie/claw_miss2.wav",
};
static char g_PlayMeleeJumpPrepare[][] = {
	"npc/fast_zombie/claw_miss1.wav",
	"npc/fast_zombie/claw_miss2.wav",
};
static char g_PlayMeleeJumpSound[][] = {
	"npc/fast_zombie/claw_miss1.wav",
	"npc/fast_zombie/claw_miss2.wav",
};

public void XenoFortifiedFastZombie_OnMapStart_NPC()
{
	for (int i = 0; i < (sizeof(g_DeathSounds));	   i++) { PrecacheSound(g_DeathSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_HurtSounds));		i++) { PrecacheSound(g_HurtSounds[i]);		}
	for (int i = 0; i < (sizeof(g_IdleSounds));		i++) { PrecacheSound(g_IdleSounds[i]);		}
	for (int i = 0; i < (sizeof(g_IdleAlertedSounds)); i++) { PrecacheSound(g_IdleAlertedSounds[i]); }
	for (int i = 0; i < (sizeof(g_MeleeHitSounds));	i++) { PrecacheSound(g_MeleeHitSounds[i]);	}
	for (int i = 0; i < (sizeof(g_MeleeAttackSounds));	i++) { PrecacheSound(g_MeleeAttackSounds[i]);	}
	for (int i = 0; i < (sizeof(g_MeleeMissSounds));   i++) { PrecacheSound(g_MeleeMissSounds[i]);   }
	for (int i = 0; i < (sizeof(g_MeleeMissSounds));   i++) { PrecacheSound(g_MeleeMissSounds[i]);   }
	for (int i = 0; i < (sizeof(g_PlayMeleeJumpPrepare));   i++) { PrecacheSound(g_PlayMeleeJumpPrepare[i]);   }
	for (int i = 0; i < (sizeof(g_PlayMeleeJumpSound));   i++) { PrecacheSound(g_PlayMeleeJumpSound[i]);   }
	for (int i = 0; i < (sizeof(g_leap_scream));   i++) { PrecacheSound(g_leap_scream[i]);   }
	for (int i = 0; i < (sizeof(g_leap_prepare));   i++) { PrecacheSound(g_leap_prepare[i]);   }
}

methodmap XenoFortifiedFastZombie < CClotBody
{
	public void PlayIdleSound() {
		if(this.m_flNextIdleSound > GetGameTime())
			return;
		
		EmitSoundToAll(g_IdleSounds[GetRandomInt(0, sizeof(g_IdleSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		this.m_flNextIdleSound = GetGameTime() + GetRandomFloat(3.0, 6.0);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayIdleSound()");
		#endif
	}
	
	public void PlayIdleAlertSound() {
		if(this.m_flNextIdleSound > GetGameTime())
			return;
		
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, _, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		this.m_flNextIdleSound = GetGameTime() + GetRandomFloat(3.0, 6.0);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayIdleAlertSound()");
		#endif
	}
	
	
	public void PlayLeapPrepare() {
		
		EmitSoundToAll(g_leap_prepare[GetRandomInt(0, sizeof(g_leap_prepare) - 1)], this.index, _, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeJumpPrepare()");
		#endif
	}
	
	public void PlayLeapDone() {
		
		EmitSoundToAll(g_leap_scream[GetRandomInt(0, sizeof(g_leap_scream) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeJumpPrepare()");
		#endif
	}
	public void PlayMeleeJumpPrepare() {
		if(this.m_flNextIdleSound > GetGameTime())
			return;
		
		EmitSoundToAll(g_PlayMeleeJumpPrepare[GetRandomInt(0, sizeof(g_PlayMeleeJumpPrepare) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeJumpPrepare()");
		#endif
	}
	
	public void PlayMeleeJumpSound() {
		if(this.m_flNextIdleSound > GetGameTime())
			return;
		
		EmitSoundToAll(g_PlayMeleeJumpSound[GetRandomInt(0, sizeof(g_PlayMeleeJumpSound) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeJumpSound()");
		#endif
	}
	public void PlayHurtSound() {
		if(this.m_flNextHurtSound > GetGameTime())
			return;
			
		this.m_flNextHurtSound = GetGameTime() + 0.4;
		
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayHurtSound()");
		#endif
	}
	
	public void PlayDeathSound() {
	
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayDeathSound()");
		#endif
	}
	
	public void PlayMeleeSound() {
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeHitSound()");
		#endif
	}
	public void PlayMeleeHitSound() {
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayMeleeHitSound()");
		#endif
	}

	public void PlayMeleeMissSound() {
		EmitSoundToAll(g_MeleeMissSounds[GetRandomInt(0, sizeof(g_MeleeMissSounds) - 1)], this.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, 80);
		
		#if defined DEBUG_SOUND
		PrintToServer("CGoreFast::PlayMeleeMissSound()");
		#endif
	}
	
	
	
	public XenoFortifiedFastZombie(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		XenoFortifiedFastZombie npc = view_as<XenoFortifiedFastZombie>(CClotBody(vecPos, vecAng, "models/zombie/fast.mdl", "1.15", "400", ally));
		
		i_NpcInternalId[npc.index] = XENO_FORTIFIED_FASTZOMBIE;
		
		int iActivity = npc.LookupActivity("ACT_RUN");
		if(iActivity > 0) npc.StartActivity(iActivity);
		
		
		
		npc.m_iBleedType = BLEEDTYPE_XENO;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;		
		
		npc.m_flNextMeleeAttack = 0.0;
		
		
		SDKHook(npc.index, SDKHook_OnTakeDamage, XenoFortifiedFastZombie_ClotDamaged);
		SDKHook(npc.index, SDKHook_Think, XenoFortifiedFastZombie_ClotThink);
		
		
		
		SetEntityRenderMode(npc.index, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.index, 150, 255, 150, 180);
		
		//IDLE
		npc.m_flSpeed = 400.0;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_flJumpCooldown = GetGameTime() + 5.0;
		npc.m_flInJump = 0.0;
		
		npc.StartPathing();
		
		return npc;
	}
	
	
}

//TODO 
//Rewrite
public void XenoFortifiedFastZombie_ClotThink(int iNPC)
{
	XenoFortifiedFastZombie npc = view_as<XenoFortifiedFastZombie>(iNPC);
	
	SetVariantInt(1);
	AcceptEntityInput(iNPC, "SetBodyGroup");
	
	if(npc.m_flNextDelayTime > GetGameTime())
	{
		return;
	}
	
	npc.m_flNextDelayTime = GetGameTime() + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();	
	
	if(npc.m_flNextThinkTime > GetGameTime())
	{
		return;
	}
	
	npc.m_flNextThinkTime = GetGameTime() + 0.1;

	if(npc.m_flGetClosestTargetTime < GetGameTime())
	{
		npc.m_iTarget = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = GetGameTime() + 1.0;
	}
	
	int PrimaryThreatIndex = npc.m_iTarget;
	
	if(IsValidEnemy(npc.index, PrimaryThreatIndex))
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(PrimaryThreatIndex);
		
		float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);		
		
		if(npc.m_flJumpCooldown < GetGameTime() && npc.m_flInJump < GetGameTime() && flDistanceToTarget > 10000 && flDistanceToTarget < 1000000)
		{
			int Enemy_I_See;
			Enemy_I_See = Can_I_See_Enemy(npc.index, PrimaryThreatIndex);
			//Target close enough to hit
			if(IsValidEnemy(npc.index, Enemy_I_See) && Enemy_I_See == PrimaryThreatIndex)
			{
				npc.m_flInJump = GetGameTime() + 0.65;
				
				npc.m_flJumpCooldown = GetGameTime() + 0.5;
				npc.PlayLeapPrepare();
			}
			
		}
		if(npc.m_flJumpCooldown < GetGameTime() && npc.m_flInJump > GetGameTime())
		{
			PluginBot_Jump(npc.index, vecTarget);
			npc.PlayLeapDone();
			npc.m_flJumpCooldown = GetGameTime() + 5.0;
			
		}
		if(npc.m_flInJump > GetGameTime())
		{
			PF_StopPathing(npc.index);
			npc.m_bPathing = false;
			npc.FaceTowards(vecTarget, 1000.0);
			
			return;
			
		}
			//Predict their pos.
		if(flDistanceToTarget < npc.GetLeadRadius()) 
		{
			
			float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, PrimaryThreatIndex);
			
			PF_SetGoalVector(npc.index, vPredictedPos);
		}
		else 
		{
			PF_SetGoalEntity(npc.index, PrimaryThreatIndex);
		}
		//Target close enough to hit
		if(flDistanceToTarget < 10000)
		{
			//Look at target so we hit.
	//		npc.FaceTowards(vecTarget, 1000.0);
			
				//Can we attack right now?
			if(npc.m_flNextMeleeAttack < GetGameTime())
			{
				//Play attack anim
				npc.AddGesture("ACT_MELEE_ATTACK1");
				
				Handle swingTrace;
				npc.FaceTowards(vecTarget, 20000.0);
				if(npc.DoSwingTrace(swingTrace, PrimaryThreatIndex))
				{
					
					int target = TR_GetEntityIndex(swingTrace);	
					
					float vecHit[3];
					TR_GetEndPosition(vecHit, swingTrace);
					
					if(target > 0) 
					{
						
						if(EscapeModeForNpc)
						{
							if(target <= MaxClients)
								SDKHooks_TakeDamage(target, npc.index, npc.index, 12.0, DMG_CLUB, -1, _, vecHit);
							else
								SDKHooks_TakeDamage(target, npc.index, npc.index, 20.0, DMG_CLUB, -1, _, vecHit);
						}
						else
						{
							if(target <= MaxClients)
								SDKHooks_TakeDamage(target, npc.index, npc.index, 4.0, DMG_CLUB, -1, _, vecHit);
							else
								SDKHooks_TakeDamage(target, npc.index, npc.index, 15.0, DMG_CLUB, -1, _, vecHit);
						}
							
							
						// Hit particle
						
								
						// Hit sound
						npc.PlayMeleeSound();
						npc.PlayMeleeHitSound();
					} 
				}
				delete swingTrace;
				npc.m_flNextMeleeAttack = GetGameTime() + 0.6;
			}
			PF_StopPathing(npc.index);
			npc.m_bPathing = false;
		}
		else
		{
			npc.StartPathing();
			
		}
	}
	else
	{
		PF_StopPathing(npc.index);
		npc.m_bPathing = false;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
	npc.PlayIdleAlertSound();
}

public Action XenoFortifiedFastZombie_ClotDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker <= 0)
		return Plugin_Continue;
		
	XenoFortifiedFastZombie npc = view_as<XenoFortifiedFastZombie>(victim);
	
	
	if(!npc.bXenoInfectedSpecialHurt && !Building_DoesPierce(attacker))
	{
		npc.bXenoInfectedSpecialHurt = true;
		SetEntityRenderMode(npc.index, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.index, 150, 255, 150, 255);
		damage = 0.0;
		EmitSoundToAll("physics/metal/metal_box_impact_bullet1.wav", attacker, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, 0.5);
		return Plugin_Changed;
	}
	
	/*
	if(attacker > MaxClients && !IsValidEnemy(npc.index, attacker))
		return Plugin_Continue;
	*/
	
	if (npc.m_flHeadshotCooldown < GetGameTime())
	{
		npc.m_flHeadshotCooldown = GetGameTime() + DEFAULT_HURTDELAY;
		npc.PlayHurtSound();
		
	}
	
	return Plugin_Changed;
}

public void XenoFortifiedFastZombie_NPCDeath(int entity)
{
	XenoFortifiedFastZombie npc = view_as<XenoFortifiedFastZombie>(entity);
	if(!npc.m_bGib)
	{
		npc.PlayDeathSound();	
	}
	
	SDKUnhook(npc.index, SDKHook_OnTakeDamage, XenoFortifiedFastZombie_ClotDamaged);
	SDKUnhook(npc.index, SDKHook_Think, XenoFortifiedFastZombie_ClotThink);
		
//	AcceptEntityInput(npc.index, "KillHierarchy");
}