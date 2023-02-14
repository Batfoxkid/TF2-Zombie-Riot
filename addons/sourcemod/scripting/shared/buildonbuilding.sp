#pragma semicolon 1
#pragma newdecls required

static int iBuildingDependency[2049] = {0, ...};
/*
static const float ViewHeights[] =
{
	75.0,
	65.0,
	75.0,
	68.0,
	68.0,
	75.0,
	75.0,
	68.0,
	75.0,
	68.0
};
*/
static DynamicHook dtIsPlacementPosValid;

void OnPluginStart_Build_on_Building()
{

	GameData hGameConf = new GameData("buildonbuildings_defs.games");

	if(!hGameConf)
		SetFailState("Cannot find file buildonbuildings_defs.games!");

	dtIsPlacementPosValid = DynamicHook.FromConf(hGameConf, "CBaseObject::IsPlacementPosValid()");
	// new DynamicHook(334, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);

	if(!dtIsPlacementPosValid)
		SetFailState("Failed to setup detour for CBaseObject::IsPlacementPosValid");

	// Dummy hook, we need pThis in the post hook
	//dtIsPlacementPosValid.Enable(Hook_Pre, OnIsPlacementPosValidPre);
	// Add a post hook on the function.
	//dtIsPlacementPosValid.Enable(Hook_Post, OnIsPlacementPosValidPost);
	
	HookEvent("player_carryobject", Event_ObjectMoved);

	delete hGameConf;

	return;
}

public void Event_ObjectMoved(Handle event, const char[] name, bool dontBroadCast)
{
	int building=GetEventInt(event, "index");
	if(!IsValidEntity(building))
	{
		return;
	}
	char str[32];
	GetEntityClassname(building, str, sizeof(str));
	if(StrEqual(str, "obj_attachment_sapper", false))
	{
		return;
	}
	if(iBuildingDependency[building])
	{
		SDKHooks_TakeDamage(iBuildingDependency[building], 0, 0, 100000.0, DMG_ACID);
		iBuildingDependency[building]=0;
		for(int i=0; i<2048; i++)
		{
			if(iBuildingDependency[i]==building)
			{
				iBuildingDependency[i]=0;
			}
		}
	}
}

public void Event_ObjectMoved_Custom(int building)
{
	if(!IsValidEntity(building))
	{
		return;
	}
	char str[32];
	GetEntityClassname(building, str, sizeof(str));
	if(StrEqual(str, "obj_attachment_sapper", false))
	{
		return;
	}
	if(iBuildingDependency[building])
	{
		SDKHooks_TakeDamage(iBuildingDependency[building], 0, 0, 100000.0, DMG_ACID);
		iBuildingDependency[building]=0;
		for(int i=0; i<2048; i++)
		{
			if(iBuildingDependency[i]==building)
			{
				iBuildingDependency[i]=0;
			}
		}
	}
}

void OnMapStart_Build_on_Build()
{
	for(int i=0; i<2048; i++)
	{
		iBuildingDependency[i]=0;
	}
}

static int i_DoNotTeleportThisPlayer;

public MRESReturn OnIsPlacementPosValidPre(int pThis, Handle hReturn, Handle hParams)
{
	if(pThis==-1)
	{
		return MRES_Ignored;
	}
	if(GetEntPropEnt(pThis, Prop_Send, "m_hBuilder")==-1)
	{
		return MRES_Ignored;
	}
	i_DoNotTeleportThisPlayer = GetEntPropEnt(pThis, Prop_Send, "m_hBuilder");
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && client != i_DoNotTeleportThisPlayer)
		{
			b_ThisEntityIgnoredEntirelyFromAllCollisions[client] = true;
		}
	}

	for(int entitycount_again; entitycount_again<i_MaxcountNpc_Allied; entitycount_again++)
	{
		int baseboss_index_allied = EntRefToEntIndex(i_ObjectsNpcs_Allied[entitycount_again]);
		if (IsValidEntity(baseboss_index_allied))
		{
			b_ThisEntityIgnoredEntirelyFromAllCollisions[baseboss_index_allied] = true;
		}
	}
	for(int entity=1; entity<=MAXENTITIES; entity++)
	{
#if defined ZR
		if (IsValidEntity(entity) && (IsEntitySpike(entity) || b_Is_Player_Projectile[entity]))
		{
			b_ThisEntityIgnoredEntirelyFromAllCollisions[entity] = true;
		}
#endif
#if defined RPG
		if (IsValidEntity(entity) && (b_Is_Player_Projectile[entity]))
		{
			b_ThisEntityIgnoredEntirelyFromAllCollisions[entity] = true;
		}
#endif
	}
#if defined ZR
	for(int entitycount_again; entitycount_again<ZR_MAX_TRAPS; entitycount_again++)
	{
		int entity = EntRefToEntIndex(i_ObjectsTraps[entitycount_again]);
		if (IsValidEntity(entity))
		{
			b_ThisEntityIgnoredEntirelyFromAllCollisions[entity] = true;
		}
	}
#endif
	return MRES_Ignored;
}

public MRESReturn OnIsPlacementPosValidPost(int pThis, Handle hReturn, Handle hParams)
{
	for(int entity=1; entity<=MAXENTITIES; entity++)
	{
		if (IsValidEntity(entity))
		{
			b_ThisEntityIgnoredEntirelyFromAllCollisions[entity] = false;
		}
	}
	i_DoNotTeleportThisPlayer = 0;

	if(pThis==-1)
	{
		return MRES_Ignored;
	}
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hBuilder");
	if(client==-1)
	{
		DHookSetReturn(hReturn, false);
		return MRES_ChangedOverride;
	}

	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
//	GetClientEyePosition(client, fPos);
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 70.0; //Default is on average 70. so lets keep it like that.
	fAng[0] = 0.0; //We dont care about them looking down or up
	fAng[2] = 0.0; //This shoulddnt be accounted for!

	float tmp[3];
	float actualBeamOffset[3];
	float BEAM_BeamOffset[3];
	BEAM_BeamOffset[0] = 70.0;
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

	/*
	int g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	TE_SetupBeamPoints(fPos, vectest, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 1.0, 1.0, 0.1, 5, 0.0, view_as<int>({255, 0, 255, 255}), 30);
	TE_SendToAll();
	*/
	//Visualise the box for the player!
	static float m_vecMaxs[3];
	static float m_vecMins[3];
	m_vecMaxs = view_as<float>( { 20.0, 20.0, 50.0 } );
	m_vecMins = view_as<float>( { -20.0, -20.0, 0.0 } );	

	CClotBody npc = view_as<CClotBody>(pThis);
	
	npc.bBuildingIsStacked = false;
	//Filter the permissible returns - the game is right about building there
	if(DHookGetReturn(hReturn))
	{
		//We are built on "legal" ground, clear the dependency tree
		iBuildingDependency[pThis]=0;
		for(int i=0; i<2048; i++)
		{
			if(iBuildingDependency[i]==pThis)
			{
				iBuildingDependency[i]=0;
			}
		}
		if(IsValidClient(client))
		{
		//	fPos[2] -= 69.0; //This just goes to the ground entirely. and three higher so you can see the bottom of the box.
			Handle hTrace;
			static float m_vecLookdown[3];
			m_vecLookdown = view_as<float>( { 90.0, 0.0, 0.0 } );
			hTrace = TR_TraceRayFilterEx(fPos, m_vecLookdown, ( MASK_SHOT ), RayType_Infinite, HitOnlyWorld, client);	
			TR_GetEndPosition(fPos, hTrace);
			delete hTrace;
			fPos[2] += 4.0;
			TE_DrawBox(client, fPos, m_vecMins, m_vecMaxs, 0.2, view_as<int>({0, 255, 0, 255}));
				
			if(f_DelayBuildNotif[client] < GetGameTime())
			{
				f_DelayBuildNotif[client] = GetGameTime() + 0.25;
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Can Build Here");	
			}
		}
		return MRES_Ignored;
	}
	
	float endPos[3];
	int buildingHit=0;

	if(IsValidGroundBuilding(fPos , 130.0, endPos, buildingHit, pThis)) //130.0
	{
		if(iBuildingDependency[buildingHit])
		{
			if(IsValidClient(client))
			{
				TE_DrawBox(client, fPos, m_vecMins, m_vecMaxs, 0.2, view_as<int>({255, 0, 0, 255}));
				if(f_DelayBuildNotif[client] < GetGameTime())
				{
					f_DelayBuildNotif[client] = GetGameTime() + 0.25;
					ClientCommand(client, "playgamesound items/medshotno1.wav");
					SetDefaultHudPosition(client, 255, 0, 0);
					SetGlobalTransTarget(client);
					ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Cannot Build Here");	
				}
			}
			DHookSetReturn(hReturn, false);
			return MRES_ChangedOverride;
		}
		//Bug: The traceray may hit the ground and report obj_X classname
		//Also coords are reported as (0.0, 0.0, 0.0) for both entities?!?
		//And here is my hack
		float endPos2[3];
		GetEntPropVector(buildingHit, Prop_Send, "m_vecOrigin", endPos2);
		//We use custom offets for buildings, so we do our own magic here
		float Delta = 50.0; //default is 50

#if defined ZR
		switch(i_WhatBuilding[buildingHit])
		{
			case BuildingAmmobox:
			{
				Delta = (32.0 * 0.5); //half it, the buidling is half in the sky!
			}
			case BuildingArmorTable:
			{
				Delta = 35.0;
			}
			case BuildingPerkMachine:
			{
				Delta = 65.0;
			}
			case BuildingPackAPunch:
			{
				Delta = 65.0;
			}
			case BuildingHealingStation:
			{
				Delta = 45.0;
			}
			case BuildingMortar:
			{
				Delta = 80.0;
			}
			case BuildingRailgun:
			{
				Delta = 40.0;
			}

		}
#endif
		
		if(FloatAbs(endPos2[2]-endPos[2])<Delta)
		{
			if(IsValidClient(client))
			{
				TE_DrawBox(client, fPos, m_vecMins, m_vecMaxs, 0.2, view_as<int>({255, 0, 0, 255}));
				if(f_DelayBuildNotif[client] < GetGameTime())
				{
					f_DelayBuildNotif[client] = GetGameTime() + 0.25;
					ClientCommand(client, "playgamesound items/medshotno1.wav");
					SetDefaultHudPosition(client, 255, 0, 0);
					SetGlobalTransTarget(client);
					ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Cannot Build Here");	
				}
			}
			DHookSetReturn(hReturn, false);
			return MRES_ChangedOverride;
		}
		DataPack datapack=new DataPack();
		datapack.WriteCell(EntIndexToEntRef(pThis));
		datapack.WriteCell(EntIndexToEntRef(buildingHit));
		datapack.WriteFloat(endPos[0]);
		datapack.WriteFloat(endPos[1]);
		datapack.WriteFloat(endPos[2]);
		datapack.Reset();
		DHookSetReturn(hReturn, true);
		RequestFrame(Frame_TeleportBuilding, datapack);
		if(IsValidClient(client))
		{
			TE_DrawBox(client, endPos, m_vecMins, m_vecMaxs, 0.2, view_as<int>({0, 255, 0, 255}));
			if(f_DelayBuildNotif[client] < GetGameTime())
			{
				f_DelayBuildNotif[client] = GetGameTime() + 0.25;
				SetDefaultHudPosition(client);
				SetGlobalTransTarget(client);
				ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Can Build Here");	
			}
		}
		npc.bBuildingIsStacked = true;
		return MRES_ChangedOverride;
	}
	if(IsValidClient(client))
	{
		TE_DrawBox(client, fPos, m_vecMins, m_vecMaxs, 0.2, view_as<int>({255, 0, 0, 255}));
		if(f_DelayBuildNotif[client] < GetGameTime())
		{
			f_DelayBuildNotif[client] = GetGameTime() + 0.25;
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetDefaultHudPosition(client, 255, 0, 0);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Cannot Build Here");	
		}
	}
	DHookSetReturn(hReturn, false);
	return MRES_ChangedOverride;
}

void OnEntityDestroyed_Build_On_Build(int entity)
{
	if(entity>-1 && entity<=2048 && iBuildingDependency[entity])
	{
		if(IsValidEntity(iBuildingDependency[entity]))
		{
			SDKHooks_TakeDamage(iBuildingDependency[entity], 0, 0, 100000.0, DMG_ACID);
		}
		iBuildingDependency[entity]=0;
	}
	for(int i=0; i<2048; i++)
	{
		if(iBuildingDependency[i]==entity)
		{
			iBuildingDependency[i]=0;
		}
	}
}

void OnEntityCreated_Build_On_Build(int entity, const char[] classname)
{
	if(StrEqual(classname, "obj_dispenser") || StrEqual(classname, "obj_sentrygun"))
	{
		// Dummy hook, we need pThis in the post hook
		dtIsPlacementPosValid.HookEntity(Hook_Pre, entity, OnIsPlacementPosValidPre);
		// Add a post hook on the function.
		dtIsPlacementPosValid.HookEntity(Hook_Post, entity, OnIsPlacementPosValidPost);
	}

	iBuildingDependency[entity]=0;
	for(int i=0; i<2048; i++)
	{
		if(iBuildingDependency[i]==entity)
		{
			iBuildingDependency[i]=0;
		}
	}
}

public void Frame_TeleportBuilding(DataPack datapack)
{
	int building=EntRefToEntIndex(datapack.ReadCell());
	int dependenton=EntRefToEntIndex(datapack.ReadCell());
	bool NoBuildOnBuild = false;
	if(dependenton == 0)
	{
		NoBuildOnBuild = true;
	}

	if(!IsValidEntity(building))
	{   
		delete datapack;
		return;
	}
	if(!GetEntProp(building, Prop_Send, "m_bBuilding"))
	{
		delete datapack;
		return;
	}
	float vecPos[3];
	vecPos[0]=datapack.ReadFloat();
	vecPos[1]=datapack.ReadFloat();
	vecPos[2]=datapack.ReadFloat();
	if(!NoBuildOnBuild)
	{
		if(IsValidEntity(dependenton))
		{
			iBuildingDependency[dependenton]=building;
		}
	}
	iBuildingDependency[building]=0; //Nothing depends on us
	delete datapack;
	TeleportEntity(building, vecPos, NULL_VECTOR, NULL_VECTOR);
	
	for(int i=1; i<MaxClients; i++) //Prevent stuck
	{
		if(IsValidClient(i) && IsPlayerAlive(i)) //To-do: Do it the correct way using UTIL_TraceEntity (unfortunately, it requires signature and memory allocations...)
		{
			if(IsPlayerStuckInEnt(i, building)) //Prevent  stuck but dont kill it.
			{
				SDKUnhook(i, SDKHook_PostThink, PhaseThroughOwnBuildings);
				SDKHook(i, SDKHook_PostThink, PhaseThroughOwnBuildings);
			}
		}
	}
	
	//We're done here
}

stock bool IsPlayerStuckInEnt(int client, int ent)
{
	float vecMin[3], vecMax[3], vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
	
	GetClientAbsOrigin(client, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayHitOnlyEnt, ent);
	return TR_DidHit();
}

public bool TraceRayHitOnlyEnt(int entity, int contentsMask, int ent2)
{
	return entity == ent2;  
}


//Derived from function in SMLIB
stock bool IsValidGroundBuilding(const float pos[3], float distance, float posEnd[3], int& buildingHit, int self)
{
	bool foundbuilding = false;
	Handle trace = TR_TraceRayFilterEx(pos, view_as<float>({90.0, 0.0, 0.0}), CONTENTS_SOLID, RayType_Infinite, TraceRayFilterBuildOnBuildings);

	if (TR_DidHit(trace))
	{
		if (TR_GetEntityIndex(trace) <= 0 || TR_GetEntityIndex(trace)==self)
		{
			CloseHandle(trace);
			return false;
		}


		TR_GetEndPosition(posEnd, trace);

		if (GetVectorDistance(pos, posEnd, true) <= (distance * distance)) {
			foundbuilding = true;
			buildingHit=TR_GetEntityIndex(trace);
		}
	}

	CloseHandle(trace);

	return foundbuilding;
}

public bool TraceRayFilterBuildOnBuildings(int entity, int contentsMask)
{
	if(entity==0 || entity==-1) //Never the world or something unknown
	{
		return false;
	}
	if(entity>0 && entity<=MaxClients) //ingore players?
	{
		return false;
	}
	if(b_BuildingIsStacked[entity])
	{
		return false;
	}
	
#if defined ZR
	if(!Building_Constructed[entity]) //Make sure they are actually build.
	{
		return false;
	}
#endif
	
	char str[32];
	GetEntityClassname(entity, str, sizeof(str));
	if(StrContains(str, "obj_", false)>-1 && !StrEqual(str, "obj_teleporter", false)) // We don't want to build on teleporters(exploits, stuck, ...) You know what i mean.
	{
		return true;
	}
	return false;
}