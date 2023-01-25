#pragma semicolon 1
#pragma newdecls required

methodmap BarrackArcher < BarrackBody
{
	public BarrackArcher(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		BarrackArcher npc = view_as<BarrackArcher>(BarrackBody(client, vecPos, vecAng, "100"));
		
		i_NpcInternalId[npc.index] = BARRACK_ARCHER;
		
		SDKHook(npc.index, SDKHook_Think, BarrackArcher_ClotThink);

		npc.m_flSpeed = 150.0;
		
		npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/weapons/c_models/c_bow/c_bow.mdl");
		SetVariantString("0.4");
		AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
		
		return npc;
	}
}

public void BarrackArcher_ClotThink(int iNPC)
{
	BarrackArcher npc = view_as<BarrackArcher>(iNPC);
	if(BarrackBody_ThinkStart(npc.index))
	{
		BarrackBody_ThinkTarget(npc.index, false);

		bool path = true;
		if(npc.m_iTarget > 0)
		{
			float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
			float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);

			if(flDistanceToTarget < 160000.0)
			{
				int Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
				//Target close enough to hit
				if(IsValidEnemy(npc.index, Enemy_I_See))
				{
					//Can we attack right now?
					if(npc.m_flNextMeleeAttack < GetGameTime(npc.index))
					{
						npc.m_flSpeed = 0.0;
			//			npc.FaceTowards(vecTarget, 30000.0);
						//Play attack anim
						npc.AddGesture("ACT_CUSTOM_ATTACK_BOW");
						
			//			npc.PlayMeleeSound();
			//			npc.FireArrow(vecTarget, 25.0, 1200.0);
						npc.m_flNextMeleeAttack = GetGameTime(npc.index) + 2.0;
						npc.m_flReloadDelay = GetGameTime(npc.index) + 1.0;
					}

					path = false;
				}
			}
		}

		BarrackBody_ThinkMove(npc.index, "ACT_CUSTOM_WALK_BOW", "ACT_CUSTOM_WALK_BOW", 160000.0, path);
	}
}

void BarrackArcher_HandleAnimEvent(int entity, int event)
{
	if(event == 1001)
	{
		BarrackArcher npc = view_as<BarrackArcher>(entity);
		
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
			npc.FaceTowards(vecTarget, 30000.0);
			
			npc.PlayRangedSound();
			npc.FireArrow(vecTarget, 100.0, 1200.0);
		}
	}
	
}

void BarrackArcher_NPCDeath(int entity)
{
	BarrackArcher npc = view_as<BarrackArcher>(entity);
	BarrackBody_NPCDeath(npc.index);
	SDKUnhook(npc.index, SDKHook_Think, BarrackArcher_ClotThink);
}