#pragma semicolon 1
#pragma newdecls required


static Handle h_TimerManagement[MAXPLAYERS] = {null, ...};
static float fl_hud_timer[MAXPLAYERS];
static bool b_cannon_animation_active[MAXTF2PLAYERS];
static float fl_animation_cooldown[MAXTF2PLAYERS];

static bool b_Thirdperson_Before[MAXTF2PLAYERS];
static int i_NPC_ID[MAXTF2PLAYERS];
static float fl_magia_angle[MAXTF2PLAYERS];
static float fl_fractal_laser_dist[MAXTF2PLAYERS];
static float fl_fractal_last_known_loc[MAXTF2PLAYERS][3];
static float fl_fractal_laser_trace_throttle[MAXTF2PLAYERS];
static float fl_fractal_turn_throttle[MAXTF2PLAYERS];
static float fl_fractal_dmg_throttle[MAXTF2PLAYERS];

#define FRACTAL_KIT_CRYSTAL_THROW_COST 25
#define FRACTAL_KIT_CRYSTAL_REFLECTION 4	//how many targets the crysal can attack at the same time
#define FRACTAL_KIT_FANTASIA_COST 5
#define FRACTAL_KIT_FANTASIA_GAIN 1
#define FRACTAL_KIT_STARFALL_COST 75
#define KRACTAL_KIT_STARFALL_JUMP_AMT	10	//how many times the ion can multi strike.
static int i_max_crystal_amt[MAXTF2PLAYERS];
static int i_current_crystal_amt[MAXTF2PLAYERS];
static bool b_is_crystal[MAXENTITIES];
static int i_crystal_index[MAXTF2PLAYERS];
static bool b_on_crystal[MAXTF2PLAYERS];

/*
	IDEA: Get the npc' angle vectors, and compare those to incoming damage, basically a directional shield that respects the anim!

	Laser needs a sound start and end
	Add the shield mentioned above.

	Lower how bright effects are.


	//the anim npc has the medic backpack, this annoys me greatly
*/

static void Adjust_Crystal_Stats(int client, int weapon)
{
	switch(Pap(weapon))
	{
		case 0:
		{
			i_max_crystal_amt[client] = 75;
		}
		case 1:
		{
			i_max_crystal_amt[client] = 85;
		}
		case 2:
		{
			i_max_crystal_amt[client] = 100;
		}
		case 3:
		{
			i_max_crystal_amt[client] = 100;
		}
		case 4:
		{
			i_max_crystal_amt[client] = 100;
		}
		case 5:
		{
			i_max_crystal_amt[client] = 100;
		}
		case 6:
		{
			i_max_crystal_amt[client] = 100;
		}	
	}
	if(b_TwirlHairpins[client])
		i_max_crystal_amt[client] += 25;
		
}

void Kit_Fractal_MapStart()
{
	Zero(i_max_crystal_amt);
	Zero(fl_fractal_laser_trace_throttle);
	Zero(fl_hud_timer);
	Zero(b_cannon_animation_active);
	Zero(fl_animation_cooldown);
	Zero(b_on_crystal);
	PrecacheModel("models/props_moonbase/moon_gravel_crystal_blue.mdl", true);
}

static void Initiate_Animation(int client, int weapon)
{
	Attributes_Set(weapon, 698, 1.0);
	//TF2_AddCondition(client, TFCond_FreezeInput, -1.0);

	int WeaponModel;
	WeaponModel = EntRefToEntIndex(i_Worldmodel_WeaponModel[client]);
	if(IsValidEntity(WeaponModel))
	{
		SetEntityRenderMode(WeaponModel, RENDER_TRANSCOLOR); //Make it entirely invis.
		SetEntityRenderColor(WeaponModel, 255, 255, 255, 1);
	}

	fl_magia_angle[client] = GetRandomFloat(0.0, 360.0);

	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntProp(client, Prop_Send, "m_bIsPlayerSimulated", 0);
	SetEntProp(client, Prop_Send, "m_bSimulatedEveryTick", 0);
//	SetEntProp(client, Prop_Send, "m_bAnimatedEveryTick", 0);
	SetEntProp(client, Prop_Send, "m_bClientSideAnimation", 0);
	SetEntProp(client, Prop_Send, "m_bClientSideFrameReset", 1);
	SetEntProp(client, Prop_Send, "m_bForceLocalPlayerDraw", 1);
	int entity, i;
	while(TF2U_GetWearable(client, entity, i))
	{
		SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") | EF_NODRAW);
	}	

	b_Thirdperson_Before[client] = thirdperson[client];
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

	float vabsOrigin[3], vabsAngles[3];
	WorldSpaceCenter(client, vabsOrigin);
	GetClientEyeAngles(client, vabsAngles);
	vabsAngles[0] = 0.0;
	vabsAngles[2] = 0.0;
	int Spawn_Index = NPC_CreateByName("npc_fractal_cannon_animation", client, vabsOrigin, vabsAngles, GetTeam(client));
	if(Spawn_Index > 0)
	{
		i_NPC_ID[client] = EntIndexToEntRef(Spawn_Index);
	}
}
static void Turn_Animation(int client, int weapon)
{
	int animation = EntRefToEntIndex(i_NPC_ID[client]);
	if(animation == -1)
	{
		Kill_Animation(client);
		return;
	}
	Fracatal_Kit_Animation npc = view_as<Fracatal_Kit_Animation>(animation);

	float Start_Loc[3];
	WorldSpaceCenter(client, Start_Loc);
	if(fl_fractal_laser_trace_throttle[client] < GetGameTime())
	{
		fl_fractal_laser_trace_throttle[client] = GetGameTime() + 0.1;
		Player_Laser_Logic Laser;
		Laser.client = client;
		Laser.DoForwardTrace_Basic(1000.0);
		fl_fractal_last_known_loc[client] = Laser.End_Point;
	}	
	

	float turn_speed = 65.0;
	float firerate1 = Attributes_Get(weapon, 6, 1.0);
	float firerate2 = Attributes_Get(weapon, 5, 1.0);
	turn_speed /= firerate1;
	turn_speed /= firerate2;

	
	npc.FaceTowards(fl_fractal_last_known_loc[client], (turn_speed));
	float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
	float Tele_Loc[3]; Tele_Loc = Start_Loc; Tele_Loc[2]-=37.0;
	TeleportEntity(npc.index, Tele_Loc, NULL_VECTOR, {0.0, 0.0, 0.0});	//make 200% sure it follows the player.

	int iPitch = npc.LookupPoseParameter("body_pitch");
	if(iPitch < 0)
		return;		

	//Body pitch
	float v[3], ang[3];
	SubtractVectors(VecSelfNpc, fl_fractal_last_known_loc[client], v); 
	NormalizeVector(v, v);
	GetVectorAngles(v, ang); 
							
	float flPitch = npc.GetPoseParameter(iPitch);
							
	npc.SetPoseParameter(iPitch, ApproachAngle(ang[0], flPitch, 10.0));
	
}
static void Fire_Beam(int client, int weapon, bool update)
{
	int animation = EntRefToEntIndex(i_NPC_ID[client]);
	if(animation == -1)
	{
		Kill_Animation(client);
		return;
	}
	Fracatal_Kit_Animation npc = view_as<Fracatal_Kit_Animation>(animation);

	if(npc.m_flNextRangedBarrage_Spam > GetGameTime() && npc.m_flNextRangedBarrage_Spam != FAR_FUTURE)
		return;

	float Radius = 30.0;
	float diameter = Radius*2.0;
	if(update)
	{
		int WeaponModel;
		WeaponModel = EntRefToEntIndex(i_Worldmodel_WeaponModel[client]);
		if(IsValidEntity(WeaponModel))
		{
			SetEntityRenderMode(WeaponModel, RENDER_TRANSCOLOR); //Make it entirely invsible.
			SetEntityRenderColor(WeaponModel, 255, 255, 255, 1);
		}

		int mana_cost;
		mana_cost = RoundToCeil(Attributes_Get(weapon, 733, 1.0));

		if(mana_cost > Current_Mana[client])
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);

			Kill_Cannon(client);
			return;
		}

		Mana_Regen_Delay[client] = GetGameTime() + 1.0;
		Mana_Hud_Delay[client] = 0.0;
		
		Current_Mana[client] -= mana_cost;
		
		delay_hud[client] = 0.0;
	}
	float 	flPos[3], // original
			flAng[3]; // original
	float Angles[3];

	GetEntPropVector(npc.index, Prop_Data, "m_angRotation", Angles);

	int iPitch = npc.LookupPoseParameter("body_pitch");
	if(iPitch < 0)
		return;

	float flPitch = npc.GetPoseParameter(iPitch);
	flPitch *=-1.0;
	if(flPitch>25.0)	//limit the pitch. by a lot
		flPitch=25.0;
	if(flPitch <-50.0)
		flPitch = -50.0;
	Angles[0] = flPitch;
	GetAttachment(npc.index, "effect_hand_r", flPos, flAng);
	//flPos[2]+=37.0;
	//Get_Fake_Forward_Vec(-10.0, Angles, flPos, flPos);

	Offset_Vector({-10.0, 2.5, 2.5}, Angles, flPos);	//{-10.0, 2.5, 2.5}

	float EndLoc[3]; 

	int color[4];
	color[0] = 0;
	color[1] = 250;
	color[2] = 237;	
	color[3] = 255;
	
	if(update)
	{
		Player_Laser_Logic Laser;
		Laser.client = client;
		float dps = 100.0;
		float range = 2500.0;
		Laser.DoForwardTrace_Custom(Angles, flPos, range);
		dps *=Attributes_Get(weapon, 410, 1.0);
		range *= Attributes_Get(weapon, 103, 1.0);
		range *= Attributes_Get(weapon, 104, 1.0);
		range *= Attributes_Get(weapon, 475, 1.0);
		range *= Attributes_Get(weapon, 101, 1.0);
		range *= Attributes_Get(weapon, 102, 1.0);
		Laser.Damage = dps;
		Laser.Radius = Radius;
		Laser.damagetype = DMG_PLASMA;
		int crystal = EntRefToEntIndex(i_crystal_index[client]);
		if(IsValidEntity(crystal))
		{
			if(Crystal_Logic(client, weapon, Radius, Laser.Start_Point, Laser.End_Point, range))
			{
				WorldSpaceCenter(crystal, Laser.End_Point);
			}
		}
		Laser.Deal_Damage();
		fl_fractal_laser_dist[client] = GetVectorDistance(Laser.End_Point, flPos);
		EndLoc = Laser.End_Point;
	}
	else
	{
		int crystal = EntRefToEntIndex(i_crystal_index[client]);
		if(IsValidEntity(crystal))
		{
			if(b_on_crystal[client])
				WorldSpaceCenter(crystal, EndLoc);
			else
				Get_Fake_Forward_Vec(fl_fractal_laser_dist[client], Angles, EndLoc, flPos);
		}
		else
			Get_Fake_Forward_Vec(fl_fractal_laser_dist[client], Angles, EndLoc, flPos);

	}
	
	float TE_Duration = 0.1;
	

	float Offset_Loc[3];
	Get_Fake_Forward_Vec(50.0, Angles, Offset_Loc, flPos);

	int colorLayer4[4];
	SetColorRGBA(colorLayer4, color[0], color[1], color[2], color[1]);
	int colorLayer3[4];
	SetColorRGBA(colorLayer3, colorLayer4[0] * 7 + 255 / 8, colorLayer4[1] * 7 + 255 / 8, colorLayer4[2] * 7 + 255 / 8, color[3]);
	int colorLayer2[4];
	SetColorRGBA(colorLayer2, colorLayer4[0] * 6 + 510 / 8, colorLayer4[1] * 6 + 510 / 8, colorLayer4[2] * 6 + 510 / 8, color[3]);
	int colorLayer1[4];
	SetColorRGBA(colorLayer1, colorLayer4[0] * 5 + 7255 / 8, colorLayer4[1] * 5 + 7255 / 8, colorLayer4[2] * 5 + 7255 / 8, color[3]);

	float 	Rng_Start = GetRandomFloat(diameter*0.3, diameter*0.5);

	float 	Start_Diameter1 = ClampBeamWidth(Rng_Start*0.7),
			Start_Diameter2 = ClampBeamWidth(Rng_Start*0.9),
			Start_Diameter3 = ClampBeamWidth(Rng_Start);
		
	float 	End_Diameter1 = ClampBeamWidth(diameter*0.7),
			End_Diameter2 = ClampBeamWidth(diameter*0.9),
			End_Diameter3 = ClampBeamWidth(diameter);

	int Beam_Index = g_Ruina_BEAM_Combine_Blue;

	TE_SetupBeamPoints(flPos, Offset_Loc, Beam_Index, 	0, 0, 66, TE_Duration, 0.0, Start_Diameter1, 0, 7.0, colorLayer2, 3);
	TE_SendToAll(0.0);
	TE_SetupBeamPoints(flPos, Offset_Loc, Beam_Index, 	0, 0, 66, TE_Duration, 0.0, Start_Diameter2, 0, 7.0, colorLayer3, 3);
	TE_SendToClient(client);
	TE_SetupBeamPoints(flPos, Offset_Loc, Beam_Index,	0, 0, 66, TE_Duration, 0.0, Start_Diameter3, 0, 7.0, colorLayer4, 3);
	TE_SendToClient(client);

	TE_SetupBeamPoints(Offset_Loc, EndLoc, Beam_Index, 	0, 0, 66, TE_Duration, Start_Diameter1*0.9, End_Diameter1, 0, 0.1, colorLayer2, 3);
	TE_SendToAll(0.0);
	TE_SetupBeamPoints(Offset_Loc, EndLoc, Beam_Index, 	0, 0, 66, TE_Duration, Start_Diameter2*0.9, End_Diameter2, 0, 0.1, colorLayer3, 3);
	TE_SendToClient(client);
	TE_SetupBeamPoints(Offset_Loc, EndLoc, Beam_Index, 	0, 0, 66, TE_Duration, Start_Diameter3*0.9, End_Diameter3, 0, 0.1, colorLayer4, 3);
	TE_SendToClient(client);

	if(fl_magia_angle[client]>360.0)
		fl_magia_angle[client] -=360.0;
	
	fl_magia_angle[client]+=2.5/TickrateModify;

	Fractal_Magia_Rings(client, Offset_Loc, Angles, 3, true, 40.0, 1.0, TE_Duration, color, EndLoc);

	npc.PlayLaserLoopSound();
}
void Format_Fancy_Hud(char Text[255])
{
	ReplaceString(Text, 128, "Ą", "「");
	ReplaceString(Text, 128, "Č", "」");
	ReplaceString(Text, 128, "Ę", "【");
	ReplaceString(Text, 128, "Ė", "】");
}
static void Get_Fake_Forward_Vec(float Range, float vecAngles[3], float Vec_Target[3], float Pos[3])
{
	float Direction[3];
	
	GetAngleVectors(vecAngles, Direction, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(Direction, Range);
	AddVectors(Pos, Direction, Vec_Target);
}
static void Fractal_Magia_Rings(int client, float Origin[3], float Angles[3], int loop_for, bool Type=true, float distance_stuff, float ang_multi, float TE_Duration, int color[4], float drill_loc[3])
{
	float buffer_vec[3][3];
		
	for(int i=0 ; i<loop_for ; i++)
	{	
		float tempAngles[3], Direction[3], endLoc[3];
		tempAngles[0] = Angles[0];
		tempAngles[1] = Angles[1];	//has to the same as the beam
		tempAngles[2] = (fl_magia_angle[client]+((360.0/loop_for)*float(i)))*ang_multi;	//we use the roll angle vector to make it speeen
		/*
			Using this method we can actuall keep proper pitch/yaw angles on the turning, unlike say fantasy blade or mlynar newspaper's special swing thingy.
		*/
		
		if(tempAngles[2]>360.0)
			tempAngles[2] -= 360.0;
	
					
		GetAngleVectors(tempAngles, Direction, NULL_VECTOR, Direction);
		ScaleVector(Direction, distance_stuff);
		AddVectors(Origin, Direction, endLoc);
		
		buffer_vec[i] = endLoc;
		
		if(Type)
		{
			int r=175, g=175, b=175, a=175;
			float diameter = 15.0;
			int colorLayer4[4];
			SetColorRGBA(colorLayer4, r, g, b, a);
			int colorLayer1[4];
			SetColorRGBA(colorLayer1, colorLayer4[0] * 5 + 765 / 8, colorLayer4[1] * 5 + 765 / 8, colorLayer4[2] * 5 + 765 / 8, a);
										
			TE_SetupBeamPoints(endLoc, drill_loc, g_Ruina_BEAM_Combine_Blue, 0, 0, 0, TE_Duration, ClampBeamWidth(diameter * 0.3 * 1.28), ClampBeamWidth(diameter * 0.3 * 1.28), 0, 0.25, colorLayer1, 3);
										
			Send_Te_Client_ZR(client);
		}
		
	}
	
	TE_SetupBeamPoints(buffer_vec[0], buffer_vec[loop_for-1], g_Ruina_BEAM_Combine_Blue, 0, 0, 0, TE_Duration, 5.0, 5.0, 0, 0.01, color, 3);	
	Send_Te_Client_ZR(client);
	for(int i=0 ; i<(loop_for-1) ; i++)
	{
		TE_SetupBeamPoints(buffer_vec[i], buffer_vec[i+1], g_Ruina_BEAM_Combine_Blue, 0, 0, 0, TE_Duration, 5.0, 5.0, 0, 0.01, color, 3);	
		Send_Te_Client_ZR(client);
	}
	
}
static void Kill_Animation(int client)
{
	
	int animation = EntRefToEntIndex(i_NPC_ID[client]);
	if(animation != -1)
	{
		Fracatal_Kit_Animation npc = view_as<Fracatal_Kit_Animation>(animation);
		npc.m_iState = 1;

		SmiteNpcToDeath(animation);
	}
	if(!IsClientInGame(client))
		return;

	if(b_Thirdperson_Before[client] && thirdperson[client])
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}

	int WeaponModel;
	WeaponModel = EntRefToEntIndex(i_Worldmodel_WeaponModel[client]);
	if(IsValidEntity(WeaponModel))
	{
		SetEntityRenderMode(WeaponModel, RENDER_TRANSCOLOR); //Make it entirely visible.
		SetEntityRenderColor(WeaponModel, 255, 255, 255, 255);
	}

	//TF2_RemoveCondition(client, TFCond_FreezeInput);
	SetEntProp(client, Prop_Send, "m_bIsPlayerSimulated", 1);
//	SetEntProp(client, Prop_Send, "m_bAnimatedEveryTick", 1);
	SetEntProp(client, Prop_Send, "m_bSimulatedEveryTick", 1);
	SetEntProp(client, Prop_Send, "m_bClientSideAnimation", 1);
	SetEntProp(client, Prop_Send, "m_bClientSideFrameReset", 0);	
	SetEntProp(client, Prop_Send, "m_bForceLocalPlayerDraw", 0);
//its too offset, clientside prediction makes this impossible
	if(!b_HideCosmeticsPlayer[client])
	{
		int entity, i;
		while(TF2U_GetWearable(client, entity, i))
		{
			SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") &~ EF_NODRAW);
		}
	}
	else
	{
		int entity, i;
		while(TF2U_GetWearable(client, entity, i))
		{
			if(Viewchanges_NotAWearable(client, entity))
				SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") &~ EF_NODRAW);
		}
	}
	SetEntityMoveType(client, MOVETYPE_WALK);
}


void Activate_Fractal_Kit(int client, int weapon)
{
	if(h_TimerManagement[client] != null)
	{
		//This timer already exists.
		if(i_CustomWeaponEquipLogic[weapon]==WEAPON_KIT_FRACTAL)
		{
			//Is the weapon it again?
			//Yes?
			if(b_cannon_animation_active[client])
				Kill_Cannon(client);
			delete h_TimerManagement[client];
			h_TimerManagement[client] = null;
			DataPack pack;
			h_TimerManagement[client] = CreateDataTimer(0.1, Timer_Weapon_Managment, pack, TIMER_REPEAT);
			pack.WriteCell(client);
			pack.WriteCell(EntIndexToEntRef(weapon));

			Adjust_Crystal_Stats(client, weapon);
			
		}
		return;
	}
		
	if(i_CustomWeaponEquipLogic[weapon]==WEAPON_KIT_FRACTAL)
	{
		if(b_cannon_animation_active[client])
			Kill_Cannon(client);

		DataPack pack;
		h_TimerManagement[client] = CreateDataTimer(0.1, Timer_Weapon_Managment, pack, TIMER_REPEAT);
		pack.WriteCell(client);
		pack.WriteCell(EntIndexToEntRef(weapon));
		Adjust_Crystal_Stats(client, weapon);
	}
}
static int Pap(int weapon)
{
	return RoundFloat(Attributes_Get(weapon, 122, 0.0));
}
static int Slot(int weapon)
{
	return RoundFloat(Attributes_Get(weapon, 868, 0.0));
}

public void Kit_Fractal_Throw_Crystal(int client, int weapon, bool &result, int slot)
{
	if(fl_animation_cooldown[client] > GetGameTime())
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "The Laser Cannon is Recharging [%.1fs]", fl_animation_cooldown[client]-GetGameTime());
		return;
	}
	if(i_current_crystal_amt[client] < FRACTAL_KIT_CRYSTAL_THROW_COST)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "Your Weapon is not charged enough.");
		return;
	}
	int old_crystal = EntRefToEntIndex(i_crystal_index[client]);
	if(IsValidEntity(old_crystal))
	{
		RemoveEntity(old_crystal);
		b_is_crystal[old_crystal] = false;
	}
	b_on_crystal[client] = false;
		
	i_current_crystal_amt[client] -=FRACTAL_KIT_CRYSTAL_THROW_COST;
	
	float speed = 1250.0;
	float time = 5.0;
	float damage = 100.0;
	int projectile = Wand_Projectile_Spawn(client, speed, time, damage, 0, weapon, "");
	if(!IsValidEntity(projectile))
		return;

	ApplyCustomModelToWandProjectile(projectile, "models/props_moonbase/moon_gravel_crystal_blue.mdl", 2.0, "");
	WandProjectile_ApplyFunctionToEntity(projectile, Projectile_Touch);
	SetEntityMoveType(projectile, MOVETYPE_FLYGRAVITY);
	i_crystal_index[client] = EntIndexToEntRef(projectile);
	b_is_crystal[projectile] = true;

}
static bool Crystal_Logic(int client, int weapon, float Radius, float Start[3], float End[3], float Range)
{
	//CPrintToChatAll("Crystal Logic Active");
	float hullMin[3], hullMax[3];
	Set_HullTrace(Radius*1.2, hullMin, hullMax);

	Range *= 0.75;

	b_on_crystal[client] = false;
	b_LagCompNPC_No_Layers = true;
	StartLagCompensation_Base_Boss(client);
	Handle trace = TR_TraceHullFilterEx(Start, End, hullMin, hullMax, 1073741824, Crystal_Find_Trace, client);	// 1073741824 is CONTENTS_LADDER?
	delete trace;
	FinishLagCompensation_Base_boss();

	if(!b_on_crystal[client])
		return false;

	int crystal = EntRefToEntIndex(i_crystal_index[client]);

	float pos2[3];
	GetEntPropVector(crystal, Prop_Data, "m_vecAbsOrigin", pos2);

	b_LagCompNPC_No_Layers = true;
	StartLagCompensation_Base_Boss(client);
		
	for(int i=0; i < MAXENTITIES; i++)
	{
		HitEntitiesSphereMlynar[i] = false;
	}
	TR_EnumerateEntitiesSphere(pos2, Range, PARTITION_NON_STATIC_EDICTS, TraceEntityEnumerator_Mlynar, client);
	FinishLagCompensation_Base_boss();

	float dps = 25.0;
	dps *=Attributes_Get(weapon, 410, 1.0);

//	bool Hit = false;
	for (int entity_traced = 0; entity_traced < FRACTAL_KIT_CRYSTAL_REFLECTION; entity_traced++)
	{
		if (HitEntitiesSphereMlynar[entity_traced] > 0)
		{
			float pos1[3];
			WorldSpaceCenter(HitEntitiesSphereMlynar[entity_traced], pos1);

			// ensure no wall is obstructing
			if(Can_I_See_Enemy_Only(crystal, HitEntitiesSphereMlynar[entity_traced]))
			{
				Player_Laser_Logic Laser;
				Laser.client = client;
				Laser.Damage = dps;
				Laser.Radius = Radius;
				Laser.damagetype = DMG_PLASMA;
				Laser.Start_Point = pos2;
				Laser.End_Point = pos1;
				Laser.Deal_Damage();

				int laser;
				laser = ConnectWithBeam(crystal, HitEntitiesSphereMlynar[entity_traced], 175, 175, 175, 3.0, 1.0, 2.5, BEAM_COMBINE_BLACK);

				CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(laser), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			break;
		}
	}
	return true;
}
static bool Crystal_Find_Trace(int entity, int contentsMask, int client)
{
	if (IsValidEntity(entity))
	{
		if(b_is_crystal[entity])
		{
			b_on_crystal[client] = true;
		}
	}
	return false;
}
static void Projectile_Touch(int entity, int target)
{
	int particle = EntRefToEntIndex(i_WandParticle[entity]);
	if (target > 0)	
	{
		//Code to do damage position and ragdolls
		static float angles[3];
		GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
		float vecForward[3];
		GetAngleVectors(angles, vecForward, NULL_VECTOR, NULL_VECTOR);
		static float Entity_Position[3];
		WorldSpaceCenter(target, Entity_Position);

		int owner = EntRefToEntIndex(i_WandOwner[entity]);
		int weapon = EntRefToEntIndex(i_WandWeapon[entity]);

		float Dmg_Force[3]; CalculateDamageForce(vecForward, 10000.0, Dmg_Force);
		
		SDKHooks_TakeDamage(target, owner, owner, f_WandDamage[entity], DMG_PLASMA, weapon, Dmg_Force, Entity_Position, _ , ZR_DAMAGE_LASER_NO_BLAST);	// 2048 is DMG_NOGIB?

		if(IsValidEntity(particle))
		{
			RemoveEntity(particle);
		}
		b_is_crystal[entity] = false;
		b_on_crystal[owner] = false;
		i_crystal_index[owner] = INVALID_ENT_REFERENCE;
		RemoveEntity(entity);

	}
	else if(target == 0)
	{
		if(IsValidEntity(particle))
		{
			RemoveEntity(particle);
		}
		
		b_is_crystal[entity] = false;
		int owner = EntRefToEntIndex(i_WandOwner[entity]);
		i_crystal_index[owner] = INVALID_ENT_REFERENCE;
		b_on_crystal[owner] = false;
		RemoveEntity(entity);
	}
	
}
static int i_targeted_ID[MAXTF2PLAYERS][KRACTAL_KIT_STARFALL_JUMP_AMT];
public void Kit_Fractal_Starfall(int client, int weapon, bool &result, int slot)
{
	if(b_cannon_animation_active[client])
	{
		return;
	}
	if(i_current_crystal_amt[client] < FRACTAL_KIT_STARFALL_COST)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "Your Weapon is not charged enough.");
		return;
	}
	int mana_cost;
	mana_cost = RoundToCeil(Attributes_Get(weapon, 733, 1.0));

	if(mana_cost > Current_Mana[client] && !b_cannon_animation_active[client])
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
		return;
	}
	for(int i=0 ; i < KRACTAL_KIT_STARFALL_JUMP_AMT ; i++)
	{
		i_targeted_ID[client][i] = INVALID_ENT_REFERENCE;
	}
	i_current_crystal_amt[client] -=FRACTAL_KIT_STARFALL_COST;
	Player_Laser_Logic Laser;
	Laser.client = client;
	float Range = 1500.0;
	float Radius = 250.0;
	Laser.DoForwardTrace_Basic(Range);
	float dps = 100.0;
	dps *=Attributes_Get(weapon, 410, 1.0);
	Check_StarfallAOE(client, Laser.End_Point, Radius, KRACTAL_KIT_STARFALL_JUMP_AMT-1, dps, true);

}
static int i_entity_targeted[KRACTAL_KIT_STARFALL_JUMP_AMT];
static void AoeExplosionCheckCast(int entity, int victim, float damage, int weapon)
{
	if(IsValidEnemy(entity, victim))
	{
		for(int i=0 ; i < KRACTAL_KIT_STARFALL_JUMP_AMT ; i++)
		{
			if(!i_entity_targeted[i])
			{
				i_entity_targeted[i] = victim;
				break;
			}
		}
	}
}
static void Check_StarfallAOE(int client, float Loc[3], float Radius, int cycle, float damage, bool first = false)
{
	if(cycle < 0)
		return;

	Zero(i_entity_targeted);
	Explode_Logic_Custom(0.0, client, client, -1, Loc, Radius, _, _, _, _, _, _, AoeExplosionCheckCast);

//	bool Hit = false;
	for (int entitys = 0; entitys < KRACTAL_KIT_STARFALL_JUMP_AMT; entitys++)
	{
		if(i_entity_targeted[entitys] > 0)
		{
			bool the_same = false;
			for(int i= 0 ; i < KRACTAL_KIT_STARFALL_JUMP_AMT ; i++)
			{
				if(i_entity_targeted[entitys] == EntRefToEntIndex(i_targeted_ID[client][i]))
					the_same =true;
			}
			if(the_same)
				continue;
			
			//CPrintToChatAll("cycle %i", cycle);
			float speed = 0.75;
			i_targeted_ID[client][cycle] = EntIndexToEntRef(i_entity_targeted[entitys]);
			float pos1[3];
			WorldSpaceCenter(i_entity_targeted[entitys], pos1);
			DataPack pack;
			CreateDataTimer(speed, Timer_StarfallIon, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(EntIndexToEntRef(client));
			pack.WriteFloat(damage);
			pack.WriteFloat(Radius);
			pack.WriteCell(cycle);
			int color[4] = {255, 255, 255, 255};
			if(!first)
			{
				pack.WriteFloatArray(pos1, 3);
				pos1[2]+=10.0;
				TE_SetupBeamRingPoint(pos1, Radius*2.0, 0.0, g_Ruina_BEAM_Laser, g_Ruina_HALO_Laser, 0, 1, speed, 15.0, 0.75, color, 1, 0);
				TE_SendToAll();
				pos1[2]-=10.0;
			}
			else
			{	
				pack.WriteFloatArray(Loc, 3);
				Loc[2]+=10.0;
				TE_SetupBeamRingPoint(Loc, Radius*2.0, 0.0, g_Ruina_BEAM_Laser, g_Ruina_HALO_Laser, 0, 1, speed, 15.0, 0.75, color, 1, 0);
				TE_SendToAll();
				Loc[2]-=10.0;
			}
				
				
			break;

		}
		else
		{
			break;
		}
	}
}
static Action Timer_StarfallIon(Handle Timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidClient(client))
	{
		return Plugin_Stop;
	}
	float damage = pack.ReadFloat();
	float radius = pack.ReadFloat();
	int cycle = pack.ReadCell();
	float Loc[3]; pack.ReadFloatArray(Loc, 3);

	Explode_Logic_Custom(damage , client ,client , -1 , Loc , radius);
	float sky[3]; sky = Loc; sky[2] +=3000.0;
	int color[4] = {255, 255, 255, 255};
	float speed = 0.45;
	TE_SetupBeamPoints(Loc, sky, g_Ruina_BEAM_Combine_Blue, 0, 0, 0, speed, 15.0, 15.0, 0, 0.1, color, 3);
	TE_SendToAll();
	Loc[2]+=10.0;
	TE_SetupBeamRingPoint(Loc, 0.0, radius*2.0, g_Ruina_BEAM_Laser, g_Ruina_HALO_Laser, 0, 1, speed, 15.0, 0.75, color, 1, 0);
	TE_SendToAll();
	Loc[2]-=10.0;
	Check_StarfallAOE(client, Loc, radius, cycle-1, damage);

	return Plugin_Stop;
}

public void Kit_Fractal_Primary_Cannon(int client, int weapon, bool &result, int slot)
{
	if(fl_animation_cooldown[client] > GetGameTime())
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "The Laser Cannon is Recharging [%.1fs]", fl_animation_cooldown[client]-GetGameTime());
		return;
	}
	int mana_cost;
	mana_cost = RoundToCeil(Attributes_Get(weapon, 733, 1.0));

	mana_cost *= 10;

	if(mana_cost > Current_Mana[client] && !b_cannon_animation_active[client])
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Not Enough Mana", mana_cost);
		return;
	}

	if(b_cannon_animation_active[client])
	{
		Kill_Cannon(client);
	}
	else
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND != 0))
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Must be on the ground to use the Laser Cannon");
			return;
		}
		if(!IsPlayerAlive(client) || TeutonType[client] != TEUTON_NONE || dieingstate[client] != 0)	//are you dead?
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "Must be alive to use the Laser Cannon");
			return;
		}
		Mana_Regen_Delay[client] = GetGameTime() + 1.0;
		Mana_Hud_Delay[client] = 0.0;
		
		Current_Mana[client] -= mana_cost;
		
		delay_hud[client] = 0.0;
		b_cannon_animation_active[client] = true;
		Initiate_Cannon(client, weapon);
	}
}
static void Kill_Cannon(int client)
{
	SDKUnhook(client, SDKHook_PreThink, Fractal_Cannon_Tick);
	b_cannon_animation_active[client] = false;
	fl_animation_cooldown[client] = GetGameTime() + 5.0;	//no spaming it!
	Kill_Animation(client);

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(weapon))
	{
		Attributes_Set(weapon, 698, 0.0);
	}

}

static void Initiate_Cannon(int client, int weapon)
{
	Initiate_Animation(client, weapon);
	fl_fractal_dmg_throttle[client] = 0.0;
	fl_fractal_turn_throttle[client] = 0.0;
	fl_fractal_laser_trace_throttle[client] = 0.0;
	SDKUnhook(client, SDKHook_PreThink, Fractal_Cannon_Tick);
	SDKHook(client, SDKHook_PreThink, Fractal_Cannon_Tick);
}

static void Fractal_Cannon_Tick(int client)
{
	int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(weapon_holding))	//CLEARLY YOU DON'T OWN AN AIR FRYER
	{
		Kill_Cannon(client);
		return;
	}
	if(h_TimerManagement[client] == null)	//is the timer invalid? 
	{
		Kill_Cannon(client);
		return;
	}
	if(!b_cannon_animation_active[client])	//is the tick somehow active even though it shouldn't be possible?
	{
		Kill_Cannon(client);
		return;
	}
	if(i_CustomWeaponEquipLogic[weapon_holding] != WEAPON_KIT_FRACTAL)	//are you somehow holding a non fractal kit weapon?
	{
		Kill_Cannon(client);
		return;
	}
	if(!IsPlayerAlive(client) || TeutonType[client] != TEUTON_NONE || dieingstate[client] != 0)	//are you dead?
	{
		Kill_Cannon(client);
		return;
	}
	float GameTime = GetGameTime();

	bool update = false;

	if(fl_fractal_dmg_throttle[client] < GameTime)
	{
		fl_fractal_dmg_throttle[client] = GameTime + 0.1;
		update = true;
	}
	
	Fire_Beam(client, weapon_holding, update);

	if(fl_fractal_turn_throttle[client] > GameTime)
		return;
	
	
	fl_fractal_turn_throttle[client] = GameTime + 0.05;

	Turn_Animation(client, weapon_holding);
}

void Fractal_Kit_Modify_Mana(int client, int weapon_holding)
{
	switch(Pap(weapon_holding))
	{
		case 0:
		{
			mana_regen[client] *= 0.4;
			max_mana[client] *= 2.0;
		}
		case 1:
		{
			mana_regen[client] *= 0.5;
			max_mana[client] *= 4.0;
		}
		case 2:
		{
			mana_regen[client] *= 0.7;
			max_mana[client] *= 8.0;
		}
		case 3:
		{
			mana_regen[client] *= 0.9;
			max_mana[client] *= 9.0;
		}
		case 4:
		{
			mana_regen[client] *= 1.0;
			max_mana[client] *= 12.0;
		}
		case 5:
		{
			mana_regen[client] *= 1.25;
			max_mana[client] *= 14.0;
		}
		case 6:
		{
			//mana_regen[client] *= 2.0;
			max_mana[client] *= 17.0;

			mana_regen[client] *= 99.0;
		}
	}
	if(b_TwirlHairpins[client])
		max_mana[client] *= 1.1;
}

static Action Timer_Weapon_Managment(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(weapon))
	{
		h_TimerManagement[client] = null;
		return Plugin_Stop;
	}	

	int weapon_holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");   //get current active weapon. we don't actually use the original weapon, its there as a way to tell if something went wrong

	if(!IsValidEntity(weapon_holding))  //held weapon is somehow invalid, keep on looping...
		return Plugin_Continue;

	if(i_CustomWeaponEquipLogic[weapon_holding] != WEAPON_KIT_FRACTAL)
		return Plugin_Continue;

	Hud(client, weapon_holding);

	if(i_current_crystal_amt[client] < 100)	//10
	{
		i_current_crystal_amt[client] +=1;
	}

	return Plugin_Continue;
}

static void Hud(int client, int weapon)
{
	float GameTime = GetGameTime();

	if(fl_hud_timer[client] > GameTime)
		return;

	fl_hud_timer[client] = GameTime + 0.5;

	char HUDText[255] = "";

	switch(Slot(weapon))
	{
		case 1:
		{
			if(b_cannon_animation_active[client])
			{
				Format(HUDText, sizeof(HUDText), "ĄHyper CannonČ Active Ę[M1] to DissableĖ");

				Format(HUDText, sizeof(HUDText), "%s\nPress [M2] To Throw ĄCrystalČ [Cost:%i]",HUDText, FRACTAL_KIT_CRYSTAL_THROW_COST);
			}
			else
			{
				if(fl_animation_cooldown[client] > GameTime)
				{	
					Format(HUDText, sizeof(HUDText), "ĄHyper CannonČ Offline ĘCooling [%.1fs]Ė", fl_animation_cooldown[client] - GameTime);
				}
				else
				{
					Format(HUDText, sizeof(HUDText), "ĄHyper CannonČ Ready Ę[M1] to ActivateĖ");
					Format(HUDText, sizeof(HUDText), "%s\nPress [M2] To Throw ĄCrystalČ [Cost:%i]",HUDText, FRACTAL_KIT_CRYSTAL_THROW_COST);
				}
			}
		}
		case 2:
		{
			if(b_cannon_animation_active[client])
			{
				Format(HUDText, sizeof(HUDText), "How in thE FUCK CAN YOU SEE THIS TEXT????????  Error: Secondary slot while cannon is active");
			}
			else
			{
				//m1: mana harvester.
				//m2: Mana Ion.
			}
		}
		case 3:
		{
			if(b_cannon_animation_active[client])
			{
				Format(HUDText, sizeof(HUDText), "How in thE FUCK CAN YOU SEE THIS TEXT?? Error: Melee slot while cannon is active");
			}
			else
			{

				//fantasia
			}
		}
	}

	Format(HUDText, sizeof(HUDText), "%s\nĄCrystals:Ę%i/%iĖČ",HUDText, i_current_crystal_amt[client], i_max_crystal_amt[client]);
		

	Format_Fancy_Hud(HUDText);

	PrintHintText(client, HUDText);
	StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
}

//stuff that im probably gonna use a lot in other future weapons.

void Offset_Vector(float BEAM_BeamOffset[3], float Angles[3], float Result_Vec[3])
{
	float tmp[3];
	float actualBeamOffset[3];

	tmp[0] = BEAM_BeamOffset[0];
	tmp[1] = BEAM_BeamOffset[1];
	tmp[2] = 0.0;
	VectorRotate(BEAM_BeamOffset, Angles, actualBeamOffset);
	actualBeamOffset[2] = BEAM_BeamOffset[2];
	Result_Vec[0] += actualBeamOffset[0];
	Result_Vec[1] += actualBeamOffset[1];
	Result_Vec[2] += actualBeamOffset[2];
}
void Send_Te_Client_ZR(int client)
{
	if(LastMann)
		TE_SendToAll();
	else
		TE_SendToClient(client);
}

static int Player_Laser_BEAM_HitDetected[MAXENTITIES];
static int i_targets_hit;
static int i_maxtargets_hit;
enum struct Player_Laser_Logic
{
	int client;
	float Start_Point[3];
	float End_Point[3];
	float Angles[3];
	float Radius;
	float Damage;
	float Bonus_Damage;
	int damagetype;
	int max_targets;
	float target_hitfalloff;
	float range_hitfalloff;		//no work yet

	bool trace_hit;
	bool trace_hit_enemy;

	/*

	*/

	void DoForwardTrace_Basic(float Dist=-1.0)
	{
		float Angles[3], startPoint[3], Loc[3];
		GetClientEyePosition(this.client, startPoint);
		GetClientEyeAngles(this.client, Angles);

		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(this.client);
		Handle trace = TR_TraceRayFilterEx(startPoint, Angles, 11, RayType_Infinite, Player_Laser_BEAM_TraceWallsOnly);

		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(Loc, trace);
			delete trace;


			if(Dist !=-1.0)
			{
				ConformLineDistance(Loc, startPoint, Loc, Dist);
			}
			this.Start_Point = startPoint;
			this.End_Point = Loc;
			this.trace_hit=true;
			this.Angles = Angles;
		}
		else
		{
			delete trace;
		}
		FinishLagCompensation_Base_boss();
	}
	void DoForwardTrace_Custom(float Angles[3], float startPoint[3], float Dist=-1.0)
	{
		float Loc[3];
		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(this.client);
		Handle trace = TR_TraceRayFilterEx(startPoint, Angles, 11, RayType_Infinite, Player_Laser_BEAM_TraceWallsOnly);
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(Loc, trace);
			delete trace;


			if(Dist !=-1.0)
			{
				ConformLineDistance(Loc, startPoint, Loc, Dist);
			}
			this.Start_Point = startPoint;
			this.End_Point = Loc;
			this.Angles = Angles;
			this.trace_hit=true;
		}
		else
		{
			delete trace;
		}
		FinishLagCompensation_Base_boss();
	}

	void Deal_Damage(Function Attack_Function = INVALID_FUNCTION)
	{
		if(this.max_targets)
			i_maxtargets_hit = this.max_targets;
		else
			i_maxtargets_hit = MAX_TARGETS_HIT;

		float Falloff = LASER_AOE_DAMAGE_FALLOFF;

		if(this.target_hitfalloff)
			Falloff = this.target_hitfalloff;

		Zero(Player_Laser_BEAM_HitDetected);

		i_targets_hit = 0;

		float hullMin[3], hullMax[3];
		hullMin[0] = -this.Radius;
		hullMin[1] = hullMin[0];
		hullMin[2] = hullMin[0];
		hullMax[0] = -hullMin[0];
		hullMax[1] = -hullMin[1];
		hullMax[2] = -hullMin[2];

		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(this.client);
		Handle trace = TR_TraceHullFilterEx(this.Start_Point, this.End_Point, hullMin, hullMax, 1073741824, Player_Laser_BEAM_TraceUsers, this.client);	// 1073741824 is CONTENTS_LADDER?
		delete trace;
		FinishLagCompensation_Base_boss();

		float TargetHitFalloff = 1.0;
				
		for (int loop = 0; loop < i_targets_hit; loop++)
		{
			int victim = Player_Laser_BEAM_HitDetected[loop];
			if (victim && IsValidEnemy(this.client, victim))
			{
				this.trace_hit_enemy=true;

				float playerPos[3];
				WorldSpaceCenter(victim, playerPos);

				float Dmg = this.Damage;

				if(ShouldNpcDealBonusDamage(victim))
					Dmg = this.Bonus_Damage;

				Dmg *= TargetHitFalloff;

				TargetHitFalloff *= Falloff;
				
				SDKHooks_TakeDamage(victim, this.client, this.client, Dmg, this.damagetype, -1, _, playerPos);

				if(Attack_Function && Attack_Function != INVALID_FUNCTION)
				{	
					Call_StartFunction(null, Attack_Function);
					Call_PushCell(this.client);
					Call_PushCell(victim);
					Call_PushCell(this.damagetype);
					Call_PushFloatRef(this.Damage);
					Call_Finish();

					//static void On_LaserHit(int client, int target, int damagetype, float &damage)
				}
			}
		}
	}
}

static bool Player_Laser_BEAM_TraceWallsOnly(int entity, int contentsMask)
{
	return !entity;
}
static bool Player_Laser_BEAM_TraceUsers(int entity, int contentsMask, int client)
{
	if (IsValidEntity(entity))
	{
		entity = Target_Hit_Wand_Detection(client, entity);
		if(0 < entity)
		{
			for(int i=0 ; i < i_maxtargets_hit ; i++)
			{
				if(!Player_Laser_BEAM_HitDetected[i])
				{
					i_targets_hit++;
					Player_Laser_BEAM_HitDetected[i] = entity;
					break;
				}
			}
		}
	}
	return false;
}