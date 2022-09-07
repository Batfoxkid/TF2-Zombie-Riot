static const float OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

enum ParticleAttachment_t {
	PATTACH_ABSORIGIN = 0,
	PATTACH_ABSORIGIN_FOLLOW,
	PATTACH_CUSTOMORIGIN,
	PATTACH_POINT,
	PATTACH_POINT_FOLLOW,
	PATTACH_WORLDORIGIN,
	PATTACH_ROOTBONE_FOLLOW
};

stock int abs(int x)
{
	return x < 0 ? -x : x;
}

stock float fabs(float value)
{
	return value < 0 ? -value : value;
}

stock int min(int n1, int n2)
{
	return n1 < n2 ? n1 : n2;
}

stock float fmin(float n1, float n2)
{
	return n1 < n2 ? n1 : n2;
}

stock int max(int n1, int n2)
{
	return n1 > n2 ? n1 : n2;
}

stock float fmax(float n1, float n2)
{
	return n1 > n2 ? n1 : n2;
}

stock Function ValToFunc(any val)
{
	return val;
}

stock void SetActiveWeapon(int client, int entity)
{
	int holding = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(holding > MaxClients && HasEntProp(holding, Prop_Send, "m_flChargeLevel"))
		SetEntPropFloat(holding, Prop_Send, "m_flChargeLevel", 0.0);

	TF2Attrib_SetByDefIndex(client, 698, 0.0);
	SetEntProp(client, Prop_Send, "m_bWearingSuit", true);

	//static char buffer[36];
	//GetEntityClassname(entity, buffer, sizeof(buffer));
	//FakeClientCommand(client, "use %s", buffer);	//TODO: Rare bug where client is just deleted
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);

	TF2Attrib_SetByDefIndex(client, 698, 1.0);
	SetEntProp(client, Prop_Send, "m_bWearingSuit", false);

//	ViewChange_Switch(client, entity);
}

stock int GetSpellbook(int client)
{
	int i, entity;
	while(TF2_GetItem(client, entity, i))
	{
		static char buffer[36];
		if(GetEntityClassname(entity, buffer, sizeof(buffer)) && StrEqual(buffer, "tf_weapon_spellbook"))
			return entity;
	}
	return -1;
}

stock int GivePropAttachment(int entity, const char[] model)
{
	int prop = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(prop))
	{
		DispatchKeyValue(prop, "model", model);
		DispatchSpawn(prop);
		SetEntProp(prop, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_PARENT_ANIMATES);
		SetEntityCollisionGroup(prop, 2);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", entity, prop);

		SetVariantString("head");
		AcceptEntityInput(prop, "SetParentAttachmentMaintainOffset"); 
	}
	return prop;
}

stock int ParticleEffectAt(float position[3], char[] effectName, float duration = 0.1)
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if (duration > 0.0)
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}

stock int ParticleEffectAt_Parent(float position[3], char[] effectName, int iParent, const char[] szAttachment = "", float vOffsets[3] = {0.0,0.0,0.0})
{
	int particle = CreateEntityByName("info_particle_system");

	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);

		SetParent(iParent, particle);

		ActivateEntity(particle);

		AcceptEntityInput(particle, "start");
		
		//CreateTimer(0.1, Activate_particle_late, particle, TIMER_FLAG_NO_MAPCHANGE);
	}

	return particle;
}

stock int ParticleEffectAtWithRotation(float position[3], float rotation[3], char[] effectName, float duration = 0.1)
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		SetEntPropVector(particle, Prop_Data, "m_angRotation", rotation);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if (duration > 0.0)
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}


stock bool FindInfoTarget(const char[] name)
{
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "info_target")) != -1)
	{
		static char buffer[32];
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrEqual(buffer, name, false))
			return true;
	}
	return false;
}

stock bool ExcuteRelay(const char[] name, const char[] input="Trigger")
{
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "logic_relay")) != -1)
	{
		static char buffer[32];
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrEqual(buffer, name, false))
		{
			AcceptEntityInput(entity, input);
			return true;
		}
	}
	return false;
}

stock void CreateAttachedAnnotation(int client, int entity, float time, const char[] buffer)
{
	Event event = CreateEvent("show_annotation");
	if(event)
	{
		static float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		event.SetFloat("worldNormalX", pos[0]);
		event.SetFloat("worldNormalY", pos[1]);
		event.SetFloat("worldNormalZ", pos[2]);
		event.SetInt("follow_entindex", entity);
		event.SetFloat("lifetime", time);
		event.SetInt("visibilityBitfield", (1<<client));
		//event.SetBool("show_effect", effect);
		event.SetString("text", buffer);
		event.SetString("play_sound", "vo/null.mp3");
		event.SetInt("id", 6000+entity); //What to enter inside? Need a way to identify annotations by entindex!
		event.Fire();
	}
}

stock bool StartFuncByPluginName(const char[] pluginname, const char[] funcname)
{
	Handle iter = GetPluginIterator();
	while(MorePlugins(iter))
	{
		Handle plugin = ReadPlugin(iter);
		static char buffer[256];
		GetPluginFilename(plugin, buffer, sizeof(buffer));
		if(StrContains(buffer, pluginname, false) != -1)
		{
			Function func = GetFunctionByName(plugin, funcname);
			if(func != INVALID_FUNCTION)
			{
				Call_StartFunction(plugin, func);
				delete iter;
				return true;
			}
			break;
		}
	}
	delete iter;
	return false;
}

stock int ExplodeStringInt(const char[] text, const char[] split, int[] buffers, int maxInts)
{
	int reloc_idx, idx, total;

	if (maxInts < 1 || !split[0])
	{
		return 0;
	}

	char buffer[16];
	while ((idx = SplitString(text[reloc_idx], split, buffer, sizeof(buffer))) != -1)
	{
		reloc_idx += idx;
		buffers[total] = StringToInt(buffer);
		if (++total == maxInts)
			return total;
	}

	buffers[total++] = StringToInt(text[reloc_idx]);
	return total;
}

stock void MergeStringInt(int[] buffers, int maxInts, const char[] split, char[] buffer, int length)
{
	IntToString(buffers[0], buffer, length);
	for(int i=1; i<maxInts; i++)
	{
		Format(buffer, length, "%s%s%d", buffer, split, buffers[i]);
	}
}

stock int ExplodeStringFloat(const char[] text, const char[] split, float[] buffers, int maxFloats)
{
	int reloc_idx, idx, total;

	if (maxFloats < 1 || !split[0])
	{
		return 0;
	}

	char buffer[16];
	while ((idx = SplitString(text[reloc_idx], split, buffer, sizeof(buffer))) != -1)
	{
		reloc_idx += idx;
		buffers[total] = StringToFloat(buffer);
		if (++total == maxFloats)
			return total;
	}

	buffers[total++] = StringToFloat(text[reloc_idx]);
	return total;
}

stock bool KvJumpToKeySymbol2(KeyValues kv, int id)
{
	if(kv.GotoFirstSubKey())
	{
		do
		{
			if(kv.JumpToKeySymbol(id))
				return true;
		} while(kv.GotoNextKey());
	}
	return false;
}
stock int GetClientPointVisible(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, ( MASK_SOLID | CONTENTS_SOLID ), RayType_Infinite, Trace_DontHitEntityOrPlayer, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin) < flDistance)
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock int GetClientPointVisibleRevive(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, ( MASK_SOLID | CONTENTS_SOLID ), RayType_Infinite, Trace_DontHitAlivePlayer, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin) < flDistance)
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock int GetClientPointVisibleOnlyClient(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, ( MASK_SOLID | CONTENTS_SOLID ), RayType_Infinite, Trace_OnlyPlayer, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin) < flDistance)
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock void ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	char message[512];
	VFormat(message, sizeof(message), buffer, 5);

	BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	if(bf)
	{
		bf.WriteString(message);
		bf.WriteString(icon);
		bf.WriteByte(color);
		EndMessage();
	}
}

stock void CreateExplosion(int owner, const float origin[3], float damage, int magnitude, int radius)
{
	int explosion = CreateEntityByName("env_explosion");
	if(IsValidEntity(explosion))
	{
		DispatchKeyValueFloat(explosion, "DamageForce", damage);
		
		SetEntProp(explosion, Prop_Data, "m_iMagnitude", magnitude);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", radius);
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
		
		if(DispatchSpawn(explosion))
		{
			TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode");
			RemoveEntity(explosion);
		}
	}
}

stock TFClassType TF2_GetWeaponClass(int index, TFClassType defaul=TFClass_Unknown, int checkSlot=-1)
{
	switch(index)
	{
		case 735, 736, 810, 831, 933, 1080, 1102:
			return TFClass_Spy;
	}
	
	if(defaul != TFClass_Unknown)
	{
		int slot = TF2Econ_GetItemLoadoutSlot(index, defaul);
		if(checkSlot != -1)
		{
			if(slot == checkSlot)
				return defaul;
		}
		else if(slot>=0 && slot<6)
		{
			return defaul;
		}
	}

	for(TFClassType class=TFClass_Engineer; class>TFClass_Unknown; class--)
	{
		if(defaul == class)
			continue;

		int slot = TF2Econ_GetItemLoadoutSlot(index, class);
		if(checkSlot != -1)
		{
			if(slot == checkSlot)
				return class;
		}
		else if(slot>=0 && slot<6)
		{
			return class;
		}
	}
	return defaul;
}

stock bool TF2_GetItem(int client, int &weapon, int &pos)
{
	//Could be looped through client slots, but would cause issues with >1 weapons in same slot
	int maxWeapons = GetMaxWeapons(client);

	//Loop though all weapons (non-wearables)
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;

		if(weapon > MaxClients)
			return true;
	}
	return false;
}

stock bool TF2_GetWearable(int client, int &entity)
{
	while((entity=FindEntityByClassname(entity, "tf_wear*")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			return true;
	}
	return false;
}

stock int TF2_GetClassnameSlot(const char[] classname, bool econ=false)
{
	if(StrEqual(classname, "player"))
	{
		return -1;
	}
	else if(StrEqual(classname, "tf_weapon_scattergun") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_primary") ||
	   StrEqual(classname, "tf_weapon_soda_popper") ||
	   StrEqual(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	   StrEqual(classname, "tf_weapon_particle_cannon") ||
	   StrEqual(classname, "tf_weapon_flamethrower") ||
	   StrEqual(classname, "tf_weapon_grenadelauncher") ||
	   StrEqual(classname, "tf_weapon_cannon") ||
	   StrEqual(classname, "tf_weapon_minigun") ||
	   StrEqual(classname, "tf_weapon_shotgun_primary") ||
	   StrEqual(classname, "tf_weapon_sentry_revenge") ||
	   StrEqual(classname, "tf_weapon_drg_pomson") ||
	   StrEqual(classname, "tf_weapon_shotgun_building_rescue") ||
	   StrEqual(classname, "tf_weapon_syringegun_medic") ||
	   StrEqual(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	   StrEqual(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_secondary") ||
	   StrEqual(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	   StrEqual(classname, "tf_weapon_buff_item") ||
	   StrEqual(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	   StrEqual(classname, "tf_weapon_laser_pointer") ||
	   StrEqual(classname, "tf_weapon_mechanical_arm") ||
	   StrEqual(classname, "tf_weapon_medigun") ||
	   StrEqual(classname, "tf_weapon_smg") ||
	   StrEqual(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_r"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(StrEqual(classname, "tf_weapon_sa"))	// Sapper
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_i") || !StrContains(classname, "tf_weapon_pda_engineer_d"))	// Invis & Destory PDA
	{
		return econ ? TFWeaponSlot_Item1 : TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_p"))	// Disguise Kit & Build PDA
	{
		return econ ? TFWeaponSlot_PDA : TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_bu"))	// Builder Box
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_PDA;
	}
	else if(!StrContains(classname, "tf_weapon_sp"))	 // Spellbook
	{
		return TFWeaponSlot_Item1;
	}
	return TFWeaponSlot_Melee;
}

stock int GetAmmo(int client, int type)
{
	int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, type);
	if(ammo < 0)
		ammo = 0;

	return ammo;
}

stock void SetAmmo(int client, int type, int ammo)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, const int[] attrib, const float[] value, int count)
{
	int weapon = SpawnWeaponBase(client, name, index, level, qual, attrib, value, count);
	if(IsValidEntity(weapon))
	{
		HandleAttributes(weapon, attrib, value, count, index, client); //Thanks suza! i love my min models
	}
	return weapon;
}

stock int SpawnWeaponBase(int client, char[] name, int index, int level, int qual, const int[] attrib, const float[] value, int count)
{
	Handle weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	if(weapon == INVALID_HANDLE)
		return -1;
	
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, qual);
	
	TF2Items_SetNumAttributes(weapon, count);

	for(int i; i<count; i++)
	{
		TF2Items_SetAttribute(weapon, i, attrib[i], value[i]);
	}
	
	TF2_SetPlayerClass(client, TF2_GetWeaponClass(index, CurrentClass[client], TF2_GetClassnameSlot(name, true)), _, false);
	
	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	if(entity > MaxClients)
	{
		if(StrEqual(name, "tf_weapon_sapper"))
		{
			SetEntProp(entity, Prop_Send, "m_iObjectType", 3);
			SetEntProp(entity, Prop_Data, "m_iSubType", 3);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 3);
		}
		else if(StrEqual(name, "tf_weapon_builder"))
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 0);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 1);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 2);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}

		EquipPlayerWeapon(client, entity);
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
	}

	TF2_SetPlayerClass(client, CurrentClass[client], _, false);
	return entity;
}
//										 info.Attribs, info.Value, info.Attribs);
public void HandleAttributes(int weapon, const int[] attributes, const float[] values, int count, int index, int client)
{
	RemoveAllDefaultAttribsExceptStrings(weapon, index, client);
	
	for(int i = 0; i < count; i++) 
	{
		TF2Attrib_SetByDefIndex(weapon, attributes[i], values[i]);
	}
}

void RemoveAllDefaultAttribsExceptStrings(int entity, int index, int client)
{
	TF2Attrib_RemoveAll(entity);
	
	char valueType[2];
	char valueFormat[64];
	
	int currentAttrib;
	
	ArrayList staticAttribs = TF2Econ_GetItemStaticAttributes(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
	char Weaponname[64];
	GetEntityClassname(entity, Weaponname, sizeof(Weaponname));
	TF2Items_OnGiveNamedItem_Post_SDK(client, Weaponname, index, 5, 6, entity);
	
	for(int i = 0; i < staticAttribs.Length; i++)
	{
		currentAttrib = staticAttribs.Get(i, .block = 0);
	
		// Probably overkill
		if(currentAttrib == 796 || currentAttrib == 724 || currentAttrib == 817 || currentAttrib == 834 
			|| currentAttrib == 745 || currentAttrib == 731 || currentAttrib == 746)
			continue;
	
		// "stored_as_integer" is absent from the attribute schema if its type is "string".
		// TF2ED_GetAttributeDefinitionString returns false if it can't find the given string.
		if(!TF2Econ_GetAttributeDefinitionString(currentAttrib, "stored_as_integer", valueType, sizeof(valueType)))
			continue;
	
		TF2Econ_GetAttributeDefinitionString(currentAttrib, "description_format", valueFormat, sizeof(valueFormat));
	
		// Since we already know what we're working with and what we're looking for, we can manually handpick
		// the most significative chars to check if they match. Eons faster than doing StrEqual or StrContains.
	
		
		if(valueFormat[9] == 'a' && valueFormat[10] == 'd') // value_is_additive & value_is_additive_percentage
		{
			TF2Attrib_SetByDefIndex(entity, currentAttrib, 0.0);
		}
		else if((valueFormat[9] == 'i' && valueFormat[18] == 'p')
			|| (valueFormat[9] == 'p' && valueFormat[10] == 'e')) // value_is_percentage & value_is_inverted_percentage
		{
			TF2Attrib_SetByDefIndex(entity, currentAttrib, 1.0);
		}
		else if(valueFormat[9] == 'o' && valueFormat[10] == 'r') // value_is_or
		{
			TF2Attrib_SetByDefIndex(entity, currentAttrib, 0.0);
		}
		
		NullifySpecificAttributes(entity,currentAttrib);
	}
	
	delete staticAttribs;	
}

stock void NullifySpecificAttributes(int entity, int attribute)
{
	switch(attribute)
	{
		case 781: //Is sword
		{
			TF2Attrib_SetByDefIndex(entity, attribute, 0.0);	
		}
		case 128: //Provide on active
		{
			TF2Attrib_SetByDefIndex(entity, attribute, 0.0);	
		}
	}
	
}

stock void SwapWeapons(int client, int wep1, int wep2)
{
	int slot1 = -1;
	int slot2 = -1;
	int length = GetMaxWeapons(client);
	for(int i; i<length; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity == wep1)
		{
			slot1 = i;
			if(slot2 == -1)
				continue;
		}
		else if(entity == wep2)
		{
			slot2 = i;
			if(slot1 == -1)
				continue;
		}
		else
		{
			continue;
		}

		SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", wep1, slot2);
		SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", wep2, slot1);
		break;
	}
}

stock void TF2_RemoveItem(int client, int weapon)
{
	/*if(TF2_IsWearable(weapon))
	{
		TF2_RemoveWearable(client, weapon);
		return;
	}*/

	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

stock int GetMaxWeapons(int client)
{
	static int maxweps;
	if(!maxweps)
		maxweps = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	return maxweps;
}

stock float RemoveExtraHealth(TFClassType class)
{
	switch(class)
	{
		case TFClass_Soldier:
			return 0.0;

		case TFClass_Pyro, TFClass_DemoMan:
			return -25.0;

		case TFClass_Heavy:
			return 100.0;

		case TFClass_Medic:
			return -50.0;
	}
	return -75.0;
}

stock float RemoveExtraSpeed(TFClassType class)
{
	switch(class)
	{
		case TFClass_Scout:
			return 300.0/400.0;

		case TFClass_Soldier:
			return 300.0/240.0;

		case TFClass_DemoMan:
			return 300.0/280.0;

		case TFClass_Heavy:
			return 300.0/230.0;

		case TFClass_Medic, TFClass_Spy:
			return 300.0/320.0;

		default:
			return 300.0/300.0;
	}
}
/*
void RequestFrames(RequestFrameCallback func, int frames, any data=0)
{
	DataPack pack = new DataPack();
	pack.WriteFunction(func);
	pack.WriteCell(data);
	pack.WriteCell(frames);
	RequestFrame(RequestFramesCallback, pack);
}

public void RequestFramesCallback(DataPack pack)
{
	pack.Reset();
	RequestFrameCallback func = view_as<RequestFrameCallback>(pack.ReadFunction());
	any data = pack.ReadCell();

	int frames = pack.ReadCell();
	if(frames < 2)
	{
		RequestFrame(func, data);
		delete pack;
	}
	else
	{
		pack.Position--;
		pack.WriteCell(frames-1, false);
		RequestFrame(RequestFramesCallback, pack);
	}
}
*/
/*
int TF2_CreateGlow(int entity, const char[] model, int owner, int color[4])
{
	int prop = CreateEntityByName("tf_taunt_prop");
	if(IsValidEntity(prop))
	{
		DispatchSpawn(prop);

		SetEntityModel(prop, model);
		SetEntPropEnt(prop, Prop_Data, "m_hEffectEntity", owner);
		SetEntProp(prop, Prop_Send, "m_bGlowEnabled", true);
		SetEntProp(prop, Prop_Send, "m_fEffects", GetEntProp(prop, Prop_Send, "m_fEffects")|EF_BONEMERGE|EF_NOSHADOW|EF_NOINTERP);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", entity);

		SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
		SetEntityRenderColor(prop, color[0], color[1], color[2], color[3]);
		SDKHook(prop, SDKHook_SetTransmit, GlowTransmit);
	}
	return prop;
}

public Action GlowTransmit(int entity, int target)
{
	if(GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity") == target)
		return Plugin_Continue;

	return Plugin_Handled;
}
*/

stock int TF2_CreateGlow(int iEnt)
{
	char oldEntName[64];
	GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);
	
	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "RainbowGlow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "2");
	DispatchSpawn(ent);
	
	AcceptEntityInput(ent, "Enable");
	
	//Change name back to old name because we don't need it anymore.
	SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

	return ent;
}
stock void SetParent(int iParent, int iChild, const char[] szAttachment = "", float vOffsets[3] = {0.0,0.0,0.0})
{
	SetVariantString("!activator");
	AcceptEntityInput(iChild, "SetParent", iParent, iChild);
	
	if (szAttachment[0] != '\0') // Use at least a 0.01 second delay between SetParent and SetParentAttachment inputs.
	{
		SetVariantString(szAttachment); // "head"

		if (!AreVectorsEqual(vOffsets, view_as<float>({0.0,0.0,0.0}))) // NULL_VECTOR
		{
			float vPos[3];
			GetEntPropVector(iParent, Prop_Send, "m_vecOrigin", vPos);
			AddVectors(vPos, vOffsets, vPos);
			TeleportEntity(iChild, vPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(iChild, "SetParentAttachmentMaintainOffset", iParent, iChild);
		}
		else
		{
			AcceptEntityInput(iChild, "SetParentAttachment", iParent, iChild);
		}
	}
}

stock int GiveWearable(int client, int index)
{
	int entity = CreateEntityByName("tf_wearable");
	if(entity > MaxClients)	// Weapon viewmodel
	{
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
		SetEntProp(entity, Prop_Send, "m_bInitialized", true);
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", 1);
		SetEntProp(entity, Prop_Send, "m_iEntityLevel", 1);
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		
		DispatchSpawn(entity);
		SDKCall_EquipWearable(client, entity);
		
		return entity;
	}
	return -1;
}

stock bool AreVectorsEqual(float vVec1[3], float vVec2[3])
{
	return (vVec1[0] == vVec2[0] && vVec1[1] == vVec2[1] && vVec1[2] == vVec2[2]);
} 

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		RemoveEntity(entity);
	}
	return Plugin_Handled;
}

public Action Timer_RemoveEntity_CustomProjectile(Handle timer, DataPack pack)
{
	pack.Reset();
	int iCarrier = EntRefToEntIndex(pack.ReadCell());
	int particle = EntRefToEntIndex(pack.ReadCell());
	int iRot = EntRefToEntIndex(pack.ReadCell());
	if(IsValidEntity(particle) && particle>MaxClients)
	{
		RemoveEntity(particle);
	}
	if(IsValidEntity(iCarrier) && iCarrier>MaxClients)
	{
		RemoveEntity(iCarrier);
	}
	if(IsValidEntity(iRot) && iRot>MaxClients)
	{
		RemoveEntity(iRot);
	}
	return Plugin_Handled; 
}

public Action Timer_DisableMotion(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
		AcceptEntityInput(entity, "DisableMotion");
	return Plugin_Handled;
}

void StartBleedingTimer(int entity, int client, float damage, int amount, int weapon)
{
	DataPack pack;
	CreateDataTimer(0.5, Timer_Bleeding, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(entity));
	pack.WriteCell(EntIndexToEntRef(weapon));
	pack.WriteCell(GetClientUserId(client));
	pack.WriteFloat(damage);
	pack.WriteCell(amount);
}

public Action Timer_Bleeding(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity<=MaxClients || !IsValidEntity(entity) || b_NpcHasDied[entity])
		return Plugin_Stop;
		
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(weapon<=MaxClients || !IsValidEntity(weapon))
		return Plugin_Stop;

	int client = GetClientOfUserId(pack.ReadCell());
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	float pos[3], ang[3];
	
	pos = WorldSpaceCenter(entity);
	
	GetClientEyeAngles(client, ang);
	SDKHooks_TakeDamage(entity, client, client, pack.ReadFloat(), DMG_SLASH, weapon, _, pos, false);

	entity = pack.ReadCell();
	if(entity < 1)
		return Plugin_Stop;

	pack.Position--;
	pack.WriteCell(entity-1, false);
	return Plugin_Continue;
}

void StartHealingTimer(int client, float delay, int health, int amount=0, bool maxhealth=true)
{
	DataPack pack;
	CreateDataTimer(delay, Timer_Healing, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(client));
	pack.WriteCell(health);
	pack.WriteCell(maxhealth);
	pack.WriteCell(amount);
}

public Action Timer_Healing(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	
	bool IsAnEntity = false;
	
	if(IsValidEntity(client))
	{
		if(client <= MAXENTITIES && client > MaxClients)
		{
			IsAnEntity = true;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	
	if(!IsAnEntity)
	{
		if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || dieingstate[client] > 0)
			return Plugin_Stop;
	}
	int current;
	if(!IsAnEntity)
	{
		current = GetClientHealth(client);
	}
	else
	{
		current = GetEntProp(client, Prop_Data, "m_iHealth");
	}
	
	int health = pack.ReadCell();
	if(pack.ReadCell())
	{
		int maxhealth
		if(!IsAnEntity)
		{
			maxhealth = SDKCall_GetMaxHealth(client);
		}
		else
		{
			maxhealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		}
		
		if(current > maxhealth)
		{
			health = 0;
		}
		else if(current+health > maxhealth)
		{
			health = maxhealth-current;
		}
	}

	current += health;
	if(current < 1)
	{
		if(!IsAnEntity)
		{
			ForcePlayerSuicide(client);
		}
	}
	else if(current)
	{
		SetEntProp(client, Prop_Data, "m_iHealth", current);
		if(!IsAnEntity)
		{
			if(health>1 || health<-1)
				ApplyHealEvent(client, client, health);
		}
	}

	current = pack.ReadCell();
	if(current < 2)
		return Plugin_Stop;

	pack.Position--;
	pack.WriteCell(current-1, false);
	return Plugin_Continue;
}

stock void ApplyHealEvent(int patient, int healer, int amount)
{
	Event event = CreateEvent("player_healed", true);

	event.SetInt("patient", patient);
	event.SetInt("healer", healer);
	event.SetInt("heals", amount);

	event.Fire();
}

public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity!=data;
}

public bool Trace_OnlyPlayer(int entity, int mask, any data)
{
	if(entity > MaxClients || entity == 0)
	{
		return false;
	}
	else
	{
		if(TeutonType[entity] != TEUTON_NONE)
			return false;
	}
	return entity!=data;
}

public bool Trace_DontHitEntityOrPlayer(int entity, int mask, any data)
{
	if(entity <= MaxClients)
	{
		if(entity != data) //make sure that they are not dead, if they are then just ignore them/give special shit
		{
			int Building_Index = EntRefToEntIndex(Building_Mounted[entity]);
			if(dieingstate[entity] > 0)
			{
				return entity!=data;
			}
			else if(Building_Index == 0 || !IsValidEntity(Building_Index))
			{
				return false;
			}
			return Building_Index!=data;
		}
	}
	
	return entity!=data;
}


public bool Trace_DontHitAlivePlayer(int entity, int mask, any data)
{
	if(entity <= MaxClients)
	{
		if(entity != data)
		{
			if(dieingstate[entity] <= 0)
			{
				return false;
			}
		}
	}
	else if(!Citizen_ThatIsDowned(entity))
	{
		return false;
	}
	
	return entity!=data;
}

stock float[] GetAbsOrigin(int client)
{
	float v[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", v);
	return v;
}

public void DeleteHandle(Handle handle)
{
	delete handle;
}

stock bool IsValidClient( int client)
{	
	if ( client <= 0 || client > MaxClients )
		return false; 
	if ( !IsClientInGame( client ) ) 
		return false; 
		
	return true; 
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon)) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
}

stock float[] GetWorldSpaceCenter(int client)
{
	float v[3]; v = GetAbsOrigin(client);
	
	float max_space[3];
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", max_space);
	v[2] += max_space[2] / 2;
	
	return v;
}

bool IsBehindAndFacingTarget(int owner, int target)
{
	float vecToTarget[3];
	SubtractVectors(GetWorldSpaceCenter(target), GetWorldSpaceCenter(owner), vecToTarget);

	vecToTarget[2] = 0.0;
	NormalizeVector(vecToTarget, vecToTarget);
	
	float vecEyeAngles[3];
	
	GetClientEyeAngles(owner, vecEyeAngles);
	float vecOwnerForward[3];
	GetAngleVectors(vecEyeAngles, vecOwnerForward, NULL_VECTOR, NULL_VECTOR);
	vecOwnerForward[2] = 0.0;
	NormalizeVector(vecOwnerForward, vecOwnerForward);
	GetEntPropVector(target, Prop_Data, "m_angRotation", vecEyeAngles);
//	GetClientEyeAngles(target, vecEyeAngles);
	float vecTargetForward[3];
	GetAngleVectors(vecEyeAngles, vecTargetForward, NULL_VECTOR, NULL_VECTOR);
	vecTargetForward[2] = 0.0;
	NormalizeVector(vecTargetForward, vecTargetForward);
	
	float flPosVsTargetViewDot = GetVectorDotProduct(vecToTarget, vecTargetForward);
	float flPosVsOwnerViewDot = GetVectorDotProduct(vecToTarget, vecOwnerForward);
	float flViewAnglesDot = GetVectorDotProduct(vecTargetForward, vecOwnerForward);
	
	return ( flPosVsTargetViewDot > 0.0 && flPosVsOwnerViewDot > 0.5 && flViewAnglesDot > -0.3 );
}

stock float AngleDiff(float firstAngle, float secondAngle)
{
	float diff = secondAngle - firstAngle;
	return AngleNormalize(diff);
}

stock float AngleNormalize(float angle)
{
	while (angle > 180.0) angle -= 360.0;
	while (angle < -180.0) angle += 360.0;
	return angle;
}

void DoOverlay(int client, const char[] overlay)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if(overlay[0])
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	else
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", flags);
}

public bool PlayersOnly(int entity, int contentsMask, any iExclude)
{
	if(entity > MAXPLAYERS)
	{
		return false;
	}
	
	else if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") != GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		return false;
		
	
	return !(entity == iExclude);
}

#define	SHAKE_START					0			// Starts the screen shake for all players within the radius.
#define	SHAKE_STOP					1			// Stops the screen shake for all players within the radius.
#define	SHAKE_AMPLITUDE				2			// Modifies the amplitude of an active screen shake for all players within the radius.
#define	SHAKE_FREQUENCY				3			// Modifies the frequency of an active screen shake for all players within the radius.
#define	SHAKE_START_RUMBLEONLY		4			// Starts a shake effect that only rumbles the controller, no screen effect.
#define	SHAKE_START_NORUMBLE		5			// Starts a shake that does NOT rumble the controller.



stock bool Client_Shake(int client, int command=SHAKE_START, float amplitude=50.0, float frequency=150.0, float duration=3.0)
{
	if (command == SHAKE_STOP) {
		amplitude = 0.0;
	}
	else if (amplitude <= 0.0) {
		return false;
	}

	Handle userMessage = StartMessageOne("Shake", client);

	if (userMessage == INVALID_HANDLE) {
		return false;
	}

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available
		&& GetUserMessageType() == UM_Protobuf) {

		PbSetInt(userMessage,   "command",		 command);
		PbSetFloat(userMessage, "local_amplitude", amplitude);
		PbSetFloat(userMessage, "frequency",	   frequency);
		PbSetFloat(userMessage, "duration",		duration);
	}
	else {
		BfWriteByte(userMessage,	command);	// Shake Command
		BfWriteFloat(userMessage,	amplitude);	// shake magnitude/amplitude
		BfWriteFloat(userMessage,	frequency);	// shake noise frequency
		BfWriteFloat(userMessage,	duration);	// shake lasts this long
	}

	EndMessage();

	return true;
}


stock void PrintKeyHintText(int client, const char[] format, any ...)
{
	char buffer[254]; //maybe 255 is the limit.
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);

	Handle userMessage = StartMessageOne("KeyHintText", client);
	if(userMessage == INVALID_HANDLE)
		return;

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType")==FeatureStatus_Available && GetUserMessageType()==UM_Protobuf)
	{
		PbSetString(userMessage, "hints", buffer);
	}
	else
	{
		BfWriteByte(userMessage, 1); 
		BfWriteString(userMessage, buffer); 
	}
	
	EndMessage();
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock bool IsEven( int iNum )
{
	return iNum % 2 == 0;
} 

stock bool IsInvuln(int client) //Borrowed from Batfoxkid
{
	if(!IsValidClient(client))
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		//TF2_IsPlayerInCondition(client, TFCond_MegaHeal) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

stock int ParseColor(char[] colorStr)
{
	int ret = 0;
	ret |= charToHex(colorStr[0])<<20;
	ret |= charToHex(colorStr[1])<<16;
	ret |= charToHex(colorStr[2])<<12;
	ret |= charToHex(colorStr[3])<<8;
	ret |= charToHex(colorStr[4])<<4;
	ret |= charToHex(colorStr[5]);
	return ret;
}

stock void VectorRotate(float inPoint[3], float angles[3], float outPoint[3])
{
	float matRotate[3][4];
	AngleMatrix(angles, matRotate);
	VectorRotate2(inPoint, matRotate, outPoint);
}


stock void VectorRotate2(float in1[3], float in2[3][4], float out[3])
{
	out[0] = DotProduct(in1, in2[0]);
	out[1] = DotProduct(in1, in2[1]);
	out[2] = DotProduct(in1, in2[2]);
}

stock float ClampBeamWidth(float w) { return w > 128.0 ? 128.0 : w; }
stock int GetR(int c) { return abs((c>>16)&0xff); }
stock int GetG(int c) { return abs((c>>8 )&0xff); }
stock int GetB(int c) { return abs((c	)&0xff); }



stock void ConformLineDistance(float result[3], const float src[3], const float dst[3], float maxDistance, bool canExtend = false)
{
	float distance = GetVectorDistance(src, dst);
	if (distance <= maxDistance && !canExtend)
	{
		// everything's okay.
		result[0] = dst[0];
		result[1] = dst[1];
		result[2] = dst[2];
	}
	else
	{
		// need to find a point at roughly maxdistance. (FP irregularities aside)
		float distCorrectionFactor = maxDistance / distance;
		result[0] = ConformAxisValue(src[0], dst[0], distCorrectionFactor);
		result[1] = ConformAxisValue(src[1], dst[1], distCorrectionFactor);
		result[2] = ConformAxisValue(src[2], dst[2], distCorrectionFactor);
	}
}


stock void SetColorRGBA(int color[4], int r, int g, int b, int a)
{
	color[0] = abs(r)%256;
	color[1] = abs(g)%256;
	color[2] = abs(b)%256;
	color[3] = abs(a)%256;
}


stock float DEG2RAD(float n)
{
	return n * 0.017453;
}

stock float DotProduct(float v1[3], float v2[4])
{
	return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
}

stock int charToHex(int c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	else if (c >= 'a' && c <= 'f')
		return c - 'a' + 10;
	else if (c >= 'A' && c <= 'F')
		return c - 'A' + 10;
	
	// this is a user error, so print this out (it won't spam)
	PrintToConsoleAll("Invalid hex character, probably while parsing something's color. Please only use 0-9 and A-F in your color. c=%d", c);
	return 0;
}
stock float ConformAxisValue(float src, float dst, float distCorrectionFactor)
{
	return src - ((src - dst) * distCorrectionFactor);
}

stock void AngleMatrix(float angles[3], float matrix[3][4])
{
	float sr = 0.0;
	float sp = 0.0;
	float sy = 0.0;
	float cr = 0.0;
	float cp = 0.0;
	float cy = 0.0;
	sy = Sine(DEG2RAD(angles[1]));
	cy = Cosine(DEG2RAD(angles[1]));
	sp = Sine(DEG2RAD(angles[0]));
	cp = Cosine(DEG2RAD(angles[0]));
	sr = Sine(DEG2RAD(angles[2]));
	cr = Cosine(DEG2RAD(angles[2]));
	matrix[0][0] = cp * cy;
	matrix[1][0] = cp * sy;
	matrix[2][0] = -sp;
	float crcy = cr * cy;
	float crsy = cr * sy;
	float srcy = sr * cy;
	float srsy = sr * sy;
	matrix[0][1] = sp * srcy - crsy;
	matrix[1][1] = sp * srsy + crcy;
	matrix[2][1] = sr * cp;
	matrix[0][2] = sp * crcy + srsy;
	matrix[1][2] = sp * crsy - srcy;
	matrix[2][2] = cr * cp;
	matrix[0][3] = 0.0;
	matrix[1][3] = 0.0;
	matrix[2][3] = 0.0;
}

public bool Base_Boss_Hit(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	
	if(entity != iExclude && (StrEqual(class, "obj_dispenser") || StrEqual(class, "obj_teleporter") || StrEqual(class, "obj_sentrygun")))
	{
		if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		{
			return true;
		}
		
		else if(GetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed") >= 0.1)
		{
			return false;
		}
		else
		{
			return true;
		}
	}
		
	
	return !(entity == iExclude);
}

public bool IngorePlayersAndBuildings(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	if(entity <= MaxClients) //just ignore players entirely, there will be no pvp.
	{
		return false;
	}
	if(StrEqual(class, "prop_physics") || StrEqual(class, "prop_physics_multiplayer"))
	{
		return false;
	}
	if(entity != iExclude && (StrEqual(class, "obj_dispenser") || StrEqual(class, "obj_teleporter") || StrEqual(class, "obj_sentrygun") || StrEqual(class, "base_boss"))) //include baseboss so it goesthru
	{
		if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
		
	
	return !(entity == iExclude);
}

public bool Detect_BaseBoss(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	
	if(!StrEqual(class, "base_boss"))
	{
		return false;
	}
	
	if(entity != iExclude && StrEqual(class, "base_boss"))
	{
		if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
		
	
	return !(entity == iExclude);
}

stock int GetClosestTarget_BaseBoss(int entity)
{
	float TargetDistance = 0.0; 
	int ClosestTarget = -1; 
	int i = MaxClients + 1;
	while ((i = FindEntityByClassname(i, "base_boss")) != -1)
	{
		if (GetEntProp(entity, Prop_Send, "m_iTeamNum")!=GetEntProp(i, Prop_Send, "m_iTeamNum") && !b_NpcHasDied[i]) 
		{
			float EntityLocation[3], TargetLocation[3]; 
			GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityLocation ); 
			GetEntPropVector( i, Prop_Data, "m_vecAbsOrigin", TargetLocation ); 
				
				
			float distance = GetVectorDistance( EntityLocation, TargetLocation ); 
			if( TargetDistance ) 
			{
				if( distance < TargetDistance ) 
				{
					ClosestTarget = i; 
					TargetDistance = distance;		  
				}
			} 
			else 
			{
				ClosestTarget = i; 
				TargetDistance = distance;
			}				
		}
	}
	return ClosestTarget; 
}

bool b_WasAlreadyCalculatedToBeClosest[MAXENTITIES]; //should be false by default...

stock int GetClosestTarget_BaseBoss_Pos(float pos[3],int entity)
{
	float TargetDistance = 0.0; 
	int ClosestTarget = -1; 
	for(int entitycount; entitycount<i_MaxcountNpc; entitycount++)
	{
		int baseboss_index = EntRefToEntIndex(i_ObjectsNpcs[entitycount]);
		if (IsValidEntity(baseboss_index) && !b_WasAlreadyCalculatedToBeClosest[baseboss_index])
		{
			if(!b_NpcHasDied[baseboss_index])
			{
				if (GetEntProp(entity, Prop_Send, "m_iTeamNum")!=GetEntProp(baseboss_index, Prop_Send, "m_iTeamNum")) 
				{
					float TargetLocation[3]; 
					GetEntPropVector( baseboss_index, Prop_Data, "m_vecAbsOrigin", TargetLocation ); 
					
					float distance = GetVectorDistance( pos, TargetLocation ); 
					if( TargetDistance ) 
					{
						if( distance < TargetDistance ) 
						{
							ClosestTarget = baseboss_index; 
							TargetDistance = distance;		  
						}
					} 
					else 
					{
						ClosestTarget = baseboss_index; 
						TargetDistance = distance;
					}				
				}
			}
		}
	}
	for(int entitycount; entitycount<i_MaxcountBreakable; entitycount++)
	{
		int breakable_entity = EntRefToEntIndex(i_ObjectsBreakable[entitycount]);
		if(IsValidEntity(breakable_entity))
		{
			if (GetEntProp(breakable_entity, Prop_Send, "m_iTeamNum")!=GetEntProp(breakable_entity, Prop_Send, "m_iTeamNum")) 
			{
				float TargetLocation[3]; 
				GetEntPropVector( breakable_entity, Prop_Data, "m_vecAbsOrigin", TargetLocation ); 
				
				float distance = GetVectorDistance( pos, TargetLocation ); 
				if( TargetDistance ) 
				{
					if( distance < TargetDistance ) 
					{
						ClosestTarget = breakable_entity; 
						TargetDistance = distance;		  
					}
				} 
				else 
				{
					ClosestTarget = breakable_entity; 
					TargetDistance = distance;
				}				
			}
		}
	}
	if(IsValidEntity(ClosestTarget))
	{
		b_WasAlreadyCalculatedToBeClosest[ClosestTarget] = true;
	}
	return ClosestTarget; 
}

stock void AnglesToVelocity(const float ang[3], float vel[3], float speed=1.0)
{
	vel[0] = Cosine(DegToRad(ang[1]));
	vel[1] = Sine(DegToRad(ang[1]));
	vel[2] = Sine(DegToRad(ang[0])) * -1.0;
	
	NormalizeVector(vel, vel);
	
	ScaleVector(vel, speed);
}

bool ObstactleBetweenEntities(int entity1, int entity2)
{
	static float pos1[3], pos2[3];
	if(IsValidClient(entity1))
	{
		GetClientEyePosition(entity1, pos1);
	}
	else
	{
		GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", pos1);
	}

	GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", pos2);

	Handle trace = TR_TraceRayFilterEx(pos1, pos2, MASK_ALL, RayType_EndPoint, Trace_DontHitEntity, entity1);

	bool hit = TR_DidHit(trace);
	int index = TR_GetEntityIndex(trace);
	delete trace;

	if(!hit || index!=entity2)
		return true;

	return false;
}

bool IsEntityStuck(int entity)
{
	static float minn[3], maxx[3], pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", minn);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxx);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	
	TR_TraceHullFilter(pos, pos, minn, maxx, MASK_SOLID, Trace_DontHitEntity, entity);
	return (TR_DidHit());
}

stock bool IsWandWeapon(int entity)
{
	int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	return (index == 450 || index == 423 || index == 880 || index == 939 || index == 264 || index == 474 || index == 954 || index == 1123 || index == 1127 || index == 30758 || index == 1013 || index == 173 || index == 648);
}

stock bool IsWandWeaponStore(int index)
{
	return (index == 450 || index == 423 || index == 880 || index == 939 || index == 264 || index == 474 || index == 954 || index == 1123 || index == 1127 || index == 30758 || index == 1013 || index == 173 || index == 648);
}

stock int SpawnWeapon_Special(int client, char[] name, int index, int level, int qual, const char[] att, bool visible=true)
{
	if(StrEqual(name, "saxxy", false))	// if "saxxy" is specified as the name, replace with appropiate name
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:	ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan:	ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic:	ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper:	ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy:	ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
			default:		ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun", false))	// If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
			default:		ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
		}
	}

	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				delete hWeapon;
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	if(entity == -1)
		return -1;

	EquipPlayerWeapon(client, entity);

	if(visible)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	return entity;
}


public float Custom_Explosive_Logic(int clientIdx, float distance_calc, float SS_DamageDecayExponent, float SS_MaxDamage, float SS_Radius)
{
	float damage;
	if (SS_DamageDecayExponent <= 0.0)
		damage = SS_MaxDamage;
	else if (SS_DamageDecayExponent == 1.0)
		damage = SS_MaxDamage * (1.0 - (distance_calc / SS_Radius));
	
	else
	{
		damage = SS_MaxDamage - (SS_MaxDamage * (Pow(Pow(SS_Radius, SS_DamageDecayExponent) -
			Pow(SS_Radius - distance_calc, SS_DamageDecayExponent), 1.0 / SS_DamageDecayExponent) / SS_Radius));
	}
	return fmax(1.0, damage);
}

stock void GetRayAngles(float startPoint[3], float endPoint[3], float angle[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPoint[0] - startPoint[0];
	tmpVec[1] = endPoint[1] - startPoint[1];
	tmpVec[2] = endPoint[2] - startPoint[2];
	GetVectorAngles(tmpVec, angle);
}

public bool RW_IsValidHomingTarget(int target, int owner)
{
	if(!IsValidEntity(target))
		return false;
	
	if(b_NpcHasDied[target])
		return false;
	
	if(b_IsCamoNPC[target])
		return false;
		
	return true;
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

stock bool AngleWithinTolerance(float entityAngles[3], float targetAngles[3], float tolerance)
{
	static bool tests[2];
	
	for (int i = 0; i < 2; i++)
		tests[i] = fabs(entityAngles[i] - targetAngles[i]) <= tolerance || fabs(entityAngles[i] - targetAngles[i]) >= 360.0 - tolerance;
	
	return tests[0] && tests[1];
}

stock float fixAngle(float angle)
{
	int sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

stock int Spawn_Buildable(int client, int AllowBuilding = -1)
{
	int entity = SpawnWeapon(client, "tf_weapon_builder", 28, 1, 0, view_as<int>({148}), view_as<float>({1.0}), 1); 
	if(entity > MaxClients)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		TF2Attrib_SetByDefIndex(entity, 148, 0.0);
		
		if(AllowBuilding == -1)
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		else if(AllowBuilding == 0)
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		else if(AllowBuilding == 2)
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		
	//	PrintToChatAll("%i",GetEntPropEnt(entity, Prop_Send, "m_hOwner"));
		
		TF2Attrib_SetByDefIndex(client, 353, 1.0);
		
		TF2Attrib_SetByDefIndex(entity, 292, 3.0);
		TF2Attrib_SetByDefIndex(entity, 293, 59.0);
		TF2Attrib_SetByDefIndex(entity, 495, 60.0); //Kill eater score shit, i dont know.
	//	TF2_SetPlayerClass(client, TFClass_Engineer);
		return entity;
	}	
	return -1;
}

public void CreateEarthquake(float position[3], float duration, float radius, float amplitude, float frequency)
{
	int earthquake = CreateEntityByName("env_shake");
	if (IsValidEntity(earthquake))
	{
	
		DispatchKeyValueFloat(earthquake, "amplitude", amplitude);
		DispatchKeyValueFloat(earthquake, "radius", radius * 2);
		DispatchKeyValueFloat(earthquake, "duration", duration + 1.0);
		DispatchKeyValueFloat(earthquake, "frequency", frequency);

		SetVariantString("spawnflags 4"); // no physics (physics is 8), affects people in air (4)
		AcceptEntityInput(earthquake, "AddOutput");

		// create
		DispatchSpawn(earthquake);
		TeleportEntity(earthquake, position, NULL_VECTOR, NULL_VECTOR);

		AcceptEntityInput(earthquake, "StartShake", 0);
		CreateTimer(duration + 0.1, Timer_RemoveEntity, EntIndexToEntRef(earthquake), TIMER_FLAG_NO_MAPCHANGE);
	}
}


public bool TF2U_GetWearable(int client, int &entity, int &index)
{
	/*#if defined __nosoop_tf2_utils_included
	if(Loaded)
	{
		int length = TF2Util_GetPlayerWearableCount(client);
		while(index < length)
		{
			entity = TF2Util_GetPlayerWearable(client, index++);
			if(entity > MaxClients)
				return true;
		}
	}
	else
	#endif*/
	{
		if(index >= -1 && index <= MaxClients)
			index = MaxClients + 1;
		
		if(index > -2)
		{
			while((index=FindEntityByClassname(index, "tf_wear*")) != -1)
			{
				if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == client)
				{
					entity = index;
					return true;
				}
			}
			
			index = -(MaxClients + 1);
		}
		
		entity = -index;
		while((entity=FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			{
				index = -entity;
				return true;
			}
		}
	}
	return false;
}

void spawnRing(int client, float range, float modif_X, float modif_Y, float modif_Z, char sprite[255], int r, int g, int b, int alpha, int fps, float life, float width, float amp, int speed, float endRange = -69.0) //Spawns a TE beam ring at a client's/entity's location
{
	if (IsValidEntity(client))
	{
		float center[3];
		
		if (IsValidMulti(client, true, true, false)) //If our entity is a living player, grab their abs origin
		{
			GetClientAbsOrigin(client, center);
		}
		else if (client > MaxClients) //If our entity is just an entity, grab its m_vecOrigin
		{
			if (HasEntProp(client, Prop_Send, "m_vecOrigin"))
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", center);
			}
		}
		
		if (IsValidMulti(client, true, false, false)) //If the entity is a dead player, abort
		{
			return;
		}
		
		center[0] += modif_X;
		center[1] += modif_Y;
		center[2] += modif_Z;
		
		
		int ICE_INT = PrecacheModel(sprite);
		
		int color[4];
		color[0] = r;
		color[1] = g;
		color[2] = b;
		color[3] = alpha;
		
		if (endRange == -69.0)
		{
			endRange = range + 0.5;
		}
		
		//TE_SetupBeamRingPoint(center, range, range+0.5, ICE_INT, ICE_INT, 0, fps, life, width, amp, {r, g, b, alpha}, speed, 0);
		TE_SetupBeamRingPoint(center, range, endRange, ICE_INT, ICE_INT, 0, fps, life, width, amp, color, speed, 0);
		//TE_SetupBeamRingPoint(center, range, range+0.5, ICE_INT, ICE_INT, 0, 10, 0.1, 50.0, 5.0, {255, 255, 255, 100}, 1, 0);
		TE_SendToAll();
	}
}

stock bool IsSpaceOccupiedIgnorePlayersOnlyNpc(const float pos[3], const float mins[3], const float maxs[3],int entity=-1,int &ref=-1)
{
	Handle hTrace = TR_TraceHullFilterEx(pos, pos, mins, maxs, MASK_NPCSOLID, TraceRayOnlyNpc, entity);
	bool bHit = TR_DidHit(hTrace);
	ref = TR_GetEntityIndex(hTrace);
	delete hTrace;
	return bHit;
}

public bool TraceEntityFilterPlayer(int entity, any contentsMask) //Borrowed from Apocalips
{
	return entity > MaxClients;
}

public bool TraceRayOnlyNpc(int entity, any contentsMask, any data)
{
	static char class[12];
	GetEntityClassname(entity, class, sizeof(class));
	
	if(StrEqual(class, "base_boss")) return true;
	
	return !(entity == data);
}

stock bool IsValidMulti(int client, bool checkAlive=true, bool isAlive=true, bool checkTeam=false, TFTeam team=TFTeam_Red, bool send=false) //An extension of IsValidClient that also checks for boss status, alive-ness, and optionally a team. Send is used for debug purposes to inform the programmer when and why this stock returns false.
{
	if (!IsValidClient(client)) //Self-explanatory
	{
		return false;
	}
	
	if (checkAlive) //Do we want to check if the player is alive?
	{
		if (isAlive && !IsPlayerAlive(client)) //If we need the player to be alive, but they're dead, return false.
		{
			return false;
		}
		if (!isAlive && IsPlayerAlive(client)) //If we need the player to be dead, but they're alive, return false.
		{
			return false;
		}
	}
	
	if (checkTeam) //Do we want to check the client's team?
	{
		if (TF2_GetClientTeam(client) != team) //If they aren't on the desired team, return false.
		{
			return false;
		}
	}
	return true; //If all desired conditions are met, return true.
}

public bool AntiTraceEntityFilterPlayer(int entity, any contentsMask) //Borrowed from Apocalips
{
	return entity <= MaxClients;
}

#define EXPLOSION_PARTICLE_SMALL_1 "ExplosionCore_MidAir"
#define EXPLOSION_PARTICLE_SMALL_2 "ExplosionCore_buildings"
#define EXPLOSION_PARTICLE_SMALL_3 "ExplosionCore_Wall"
#define EXPLOSION_PARTICLE_SMALL_4 "rd_robot_explosion"

public void SpawnSmallExplosion(float DetLoc[3])
{
	float pos[3];
	pos[0] += DetLoc[0] + GetRandomFloat(-80.0, 80.0);
	pos[1] += DetLoc[1] + GetRandomFloat(-80.0, 80.0);
	pos[2] += DetLoc[2] + GetRandomFloat(0.0, 80.0);
	
	TE_Particle(EXPLOSION_PARTICLE_SMALL_1, pos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
}

public void SpawnSmallExplosionNotRandom(float DetLoc[3])
{
	TE_Particle(EXPLOSION_PARTICLE_SMALL_1, DetLoc, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
}

void GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}


stock int TracePlayerHulls(const float pos[3], const float mins[3], const float maxs[3],int entity=-1,int &ref=-1)
{
	Handle hTrace = TR_TraceHullFilterEx(pos, pos, mins, maxs, MASK_ALL, IngorePlayersAndBuildings, entity);
	bool bHit = TR_DidHit(hTrace);
	ref = TR_GetEntityIndex(hTrace);
	delete hTrace;
	return bHit;
}
/*
bool TE_DrawBox(int client, float m_vecOrigin[3], float m_vecMins[3], float m_vecMaxs[3], float flDur = 0.1, int color[4])
{
	//Trace top down
	float tStart[3]; tStart = m_vecOrigin;
	float tEnd[3];   tEnd = m_vecOrigin;
	
	tStart[2] = (tStart[2] + m_vecMaxs[2]);
	
//	TE_ShowPole(tStart, view_as<int>( { 255, 0, 255, 255 } ));
//	TE_ShowPole(tEnd, view_as<int>( { 0, 255, 255, 255 } ));
	
	Handle trace = TR_TraceHullFilterEx(tStart, tEnd, m_vecMins, m_vecMaxs, MASK_SHOT|CONTENTS_GRATE, IngorePlayersAndBuildingsHull, client);
	bool bDidHit = TR_DidHit(trace);
	
	if( m_vecMins[0] == m_vecMaxs[0] && m_vecMins[1] == m_vecMaxs[1] && m_vecMins[2] == m_vecMaxs[2] )
	{
		m_vecMins = view_as<float>({-15.0, -15.0, -15.0});
		m_vecMaxs = view_as<float>({15.0, 15.0, 15.0});
	}
	else
	{
		AddVectors(m_vecOrigin, m_vecMaxs, m_vecMaxs);
		AddVectors(m_vecOrigin, m_vecMins, m_vecMins);
	}
	
	float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
	vPos1 = m_vecMaxs;
	vPos1[0] = m_vecMins[0];
	vPos2 = m_vecMaxs;
	vPos2[1] = m_vecMins[1];
	vPos3 = m_vecMaxs;
	vPos3[2] = m_vecMins[2];
	vPos4 = m_vecMins;
	vPos4[0] = m_vecMaxs[0];
	vPos5 = m_vecMins;
	vPos5[1] = m_vecMaxs[1];
	vPos6 = m_vecMins;
	vPos6[2] = m_vecMaxs[2];

	TE_SendBeam(client, m_vecMaxs, vPos1, flDur, color);
	TE_SendBeam(client, m_vecMaxs, vPos2, flDur, color);
	TE_SendBeam(client, m_vecMaxs, vPos3, flDur, color);
	TE_SendBeam(client, vPos6, vPos1, flDur, color);
	TE_SendBeam(client, vPos6, vPos2, flDur, color);
	TE_SendBeam(client, vPos6, m_vecMins, flDur, color);
	TE_SendBeam(client, vPos4, m_vecMins, flDur, color);
	TE_SendBeam(client, vPos5, m_vecMins, flDur, color);
	TE_SendBeam(client, vPos5, vPos1, flDur, color);
	TE_SendBeam(client, vPos5, vPos3, flDur, color);
	TE_SendBeam(client, vPos4, vPos3, flDur, color);
	TE_SendBeam(client, vPos4, vPos2, flDur, color);
	
	delete trace;
	
	return bDidHit;
}

void TE_SendBeam(int client, float m_vecMins[3], float m_vecMaxs[3], float flDur = 0.1, int color[4])
{
	TE_SetupBeamPoints(m_vecMins, m_vecMaxs, g_iLaserMaterial, g_iHaloMaterial, 0, 0, flDur, 1.0, 1.0, 1, 0.0, color, 0);
	TE_SendToClient(client);
}
*/
/*
float[] CalculateBulletDamageForce( const float vecBulletDir[3], float flScale )
{
	float vecForce[3]; vecForce = vecBulletDir;
	NormalizeVector( vecForce, vecForce );
	ScaleVector(vecForce, FindConVar("phys_pushscale").FloatValue);
	ScaleVector(vecForce, flScale);
	return vecForce;
}
*/

int Target_Hit_Wand_Detection(int owner_projectile, int other_entity)
{
	if(other_entity == 0)
	{
		return 0;
	}
	else if(GetEntProp(owner_projectile, Prop_Send, "m_iTeamNum") != GetEntProp(other_entity, Prop_Send, "m_iTeamNum"))
	{
		char other_classname[32];
		GetEntityClassname(other_entity, other_classname, sizeof(other_classname));
		if (StrContains(other_classname, "base_boss") != -1 || StrContains(other_classname, "func_breakable") != -1 || StrContains(other_classname, "prop_dynamic") != -1)
		{
			return other_entity;
		}
	}
	return -1;
}

float[] CalculateDamageForce( const float vecBulletDir[3], float flScale )
{
	float vecForce[3]; vecForce = vecBulletDir;
	NormalizeVector( vecForce, vecForce );
	ScaleVector(vecForce, FindConVar("phys_pushscale").FloatValue);
	ScaleVector(vecForce, flScale);
	return vecForce;
}

float[] CalculateDamageForceSelfCalculated(int client, float flScale )
{
	float vecSwingForward[3];
	float ang[3];
	GetClientEyeAngles(client, ang);
	
	GetAngleVectors(ang, vecSwingForward, NULL_VECTOR, NULL_VECTOR);
	
	return CalculateDamageForce(vecSwingForward, flScale);
}

float ImpulseScale( float flTargetMass, float flDesiredSpeed )
{
	return (flTargetMass * flDesiredSpeed);
}
/*
float[] CalculateExplosiveDamageForce( const float vecForceOrigin[3],const float vecDir[3], float flScale )
{
	info->SetDamagePosition( vecForceOrigin );

	float flClampForce = ImpulseScale( 75, 400 );

	// Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	float flForceScale = info->GetBaseDamage() * ImpulseScale( 75, 4 );

	if( flForceScale > flClampForce )
		flForceScale = flClampForce;

	// Fudge blast forces a little bit, so that each
	// victim gets a slightly different trajectory. 
	// This simulates features that usually vary from
	// person-to-person variables such as bodyweight,
	// which are all indentical for characters using the same model.
	flForceScale *= random->RandomFloat( 0.85, 1.15 );

	// Calculate the vector and stuff it into the takedamageinfo
	Vector vecForce = vecDir;
	VectorNormalize( vecForce );
	vecForce *= flForceScale;
	vecForce *= phys_pushscale.GetFloat();
	vecForce *= flScale;
	info->SetDamageForce( vecForce );
}*/
#define INNER_RADIUS_FRACTION 0.25

float[] CalculateExplosiveDamageForce(const float vec_Explosive[3], const float vecEndPosition[3], float damage_Radius)
{
	float flClampForce = ImpulseScale( 75.0, 400.0 );

	// Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	float flForceScale = 100.0 * ImpulseScale( 75.0, 4.0 );

	if( flForceScale > flClampForce )
		flForceScale = flClampForce;

	// Fudge blast forces a little bit, so that each
	// victim gets a slightly different trajectory. 
	// This simulates features that usually vary from
	// person-to-person variables such as bodyweight,
	// which are all indentical for characters using the same model.
	flForceScale *= GetRandomFloat( 0.85, 1.15 );
	
	float vecSegment[3];
	float Ignore[3];
	SubtractVectors( vec_Explosive, vecEndPosition, vecSegment ); 
	float flDistance;
	
	flDistance = NormalizeVector( vecSegment, Ignore );
		
	float flFactor = 1.0 / ( damage_Radius * (INNER_RADIUS_FRACTION - 1.0) );
	float flFactor_Post = flFactor * flFactor;
	float flScale = flDistance - damage_Radius;
	float flScale_Post = flScale * flScale * flFactor_Post;
	
	if ( flScale_Post > 1.0 ) 
	{ 
		flScale_Post = 1.0; 
	}
	else if ( flScale_Post < 0.35 ) 
	{ 
		flScale_Post = 0.35; 
	}
		
	// Calculate the vector and stuff it into the takedamageinfo
	float vecForce[3]; vecForce = vecSegment;
	NormalizeVector( vecForce, vecForce );
	ScaleVector(vecForce, flForceScale);
	ScaleVector(vecForce, FindConVar("phys_pushscale").FloatValue);
	ScaleVector(vecForce, flScale_Post);
	
	vecForce[0] *= -1.0;
	vecForce[1] *= -1.0;
	vecForce[2] *= -1.0;
	return vecForce;
}

public void Give_Assist_Points(int target, int assister)
{
	i_assist_heal_player[target] = assister;
	f_assist_heal_player_time[target] = GetGameTime() + 10.0;	
}

public int CountPlayersOnRed()
{
	int amount;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client)==2 && TeutonType[client] != TEUTON_WAITING)
			amount++;
	}
	
	return amount;
	
}

stock int HasNamedItem(int client, const char[] name)
{
	int amount;
	if(name[0] && GetFeatureStatus(FeatureType_Native, "TextStore_GetItems") == FeatureStatus_Available)
	{
		int length = TextStore_GetItems();
		for(int i; i<length; i++)
		{
			static char buffer[64];
			TextStore_GetItemName(i, buffer, sizeof(buffer));
			if(StrEqual(buffer, name, false))
			{
				TextStore_GetInv(client, i, amount);
				break;
			}
		}
	}
	
	return amount;
}


//TODO: Better detection that doesnt make large enemies have better suriveability
//idea: Fire a trace to all nearby enemies, and use that distance different to dertermine falloff.

stock void Explode_Logic_Custom(float damage, int client, int entity, int weapon, float spawnLoc[3] = {0.0,0.0,0.0}, float explosionRadius = EXPLOSION_RADIUS, float ExplosionDmgMultihitFalloff = EXPLOSION_AOE_DAMAGE_FALLOFF, float explosion_range_dmg_falloff = EXPLOSION_RANGE_FALLOFF, bool FromBlueNpc = false, int maxtargetshit = 10)
{
	float damage_reduction = 1.0;
	int Closest_npc = 0;
	int TargetsHit = 0; //This will not exeed 10 ever, beacuse at that point your damage is nothing.
	//maxtargetshit
	if(IsValidEntity(weapon))
	{
		float value = Attributes_FindOnWeapon(client, weapon, 99, true, 1.0);//increaced blast radius attribute (Check weapon only)
		explosionRadius *= value;
	}
	for( int i = 1; i < MAXENTITIES; i++ ) 
	{
		b_WasAlreadyCalculatedToBeClosest[i] = false;
	}
		
	if(!FromBlueNpc) //make sure that there even is any valid npc before we do these huge calcs.
	{ 
		if(spawnLoc[0] == 0.0)
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", spawnLoc);
			Closest_npc = GetClosestTarget_BaseBoss_Pos(spawnLoc, entity);
		}
		else
		{
			Closest_npc = GetClosestTarget_BaseBoss_Pos(spawnLoc, entity);
		}
	}
	else //only nerf blue npc radius!
	{
		explosionRadius *= 0.65;
		if(spawnLoc[0] == 0.0) //only get position if thhey got notin
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", spawnLoc);
		} 

		Closest_npc = GetClosestTarget(entity, _, _, true, _, _, spawnLoc);
	}
	
	float VicLoc[3];
	
	int damage_flags = 0;
	if((i_ExplosiveProjectileHexArray[entity] & EP_DEALS_SLASH_DAMAGE))
	{
		damage_flags |= DMG_SLASH;
	}
	else
	{
		damage_flags |= DMG_BLAST;
	}
	
	if((i_ExplosiveProjectileHexArray[entity] & EP_NO_KNOCKBACK))
	{
		damage_flags |= DMG_PREVENT_PHYSICS_FORCE;
	}
			
	if(IsValidEntity(Closest_npc))
	{
		VicLoc = WorldSpaceCenter(Closest_npc);
		if (GetVectorDistance(spawnLoc, VicLoc, true) <= Pow(explosionRadius, 2.0))
		{			
			float distance_1 = GetVectorDistance(VicLoc, spawnLoc);
			float damage_1 = Custom_Explosive_Logic(client, distance_1, explosion_range_dmg_falloff, damage, explosionRadius + 1.0);
			

			if(damage_1 > damage)
			{
				damage_1 = damage;
			}	
			
			SDKHooks_TakeDamage(Closest_npc, client, client, damage_1, damage_flags, weapon, CalculateExplosiveDamageForce(spawnLoc, VicLoc, explosionRadius), VicLoc);
			
			if(!FromBlueNpc) //Npcs do not have damage falloff, dodge.
			{
				damage_reduction *= ExplosionDmgMultihitFalloff;
			}
		//	b_WasAlreadyCalculatedToBeClosest[Closest_npc] = true; //First target hit/closest might want special stuff idk
		}
		
		if(!FromBlueNpc)
		{
			for(int entitycount; entitycount<i_MaxcountNpc; entitycount++)  //Loop as often as there can be even be max NPC's.
			{
				if(TargetsHit > maxtargetshit)
				{
					break;
				}
				int new_closest_npc = GetClosestTarget_BaseBoss_Pos(spawnLoc, entity); //alotta loops :)
				if (IsValidEntity(new_closest_npc)) //Make sure its valid bla bla bla
				{
					if(Closest_npc != new_closest_npc) //Double check JUST to be sure.
					{
						//Damage Calculations
						VicLoc = WorldSpaceCenter(new_closest_npc);						
						if (GetVectorDistance(spawnLoc, VicLoc, true) <= Pow(explosionRadius, 2.0))
						{
							float distance_1 = GetVectorDistance(VicLoc, spawnLoc);
							float damage_1 = Custom_Explosive_Logic(client, distance_1, explosion_range_dmg_falloff, damage, explosionRadius + 1.0);
											
							if(damage_1 > damage)
							{
								damage_1 = damage;
							}											
							SDKHooks_TakeDamage(new_closest_npc, client, client, damage_1 / damage_reduction, damage_flags, weapon, CalculateExplosiveDamageForce(spawnLoc, VicLoc, explosionRadius), VicLoc);
							
							damage_reduction *= ExplosionDmgMultihitFalloff;
							TargetsHit += 1;
						}
						//Damage Calculations
					}
				}
			}
		}
		else //Gotta loop through all here, oopsie!
		{
			for( int i = 1; i <= MaxClients; i++ ) 
			{
				if(TargetsHit > maxtargetshit)
				{
					break;
				}
				if (IsValidClient(i))
				{
					CClotBody npc = view_as<CClotBody>(i);
					if (GetEntProp(i, Prop_Send, "m_iTeamNum")!=GetEntProp(entity, Prop_Send, "m_iTeamNum") && !npc.m_bThisEntityIgnored && IsEntityAlive(i)) //&& CheckForSee(i)) we dont even use this rn and probably never will.
					{
						VicLoc = WorldSpaceCenter(i);						
						if (GetVectorDistance(spawnLoc, VicLoc, true) <= Pow(explosionRadius, 2.0))
						{
							Handle trace; 
							trace = TR_TraceRayFilterEx(spawnLoc, VicLoc, ( MASK_SHOT | CONTENTS_SOLID ), RayType_EndPoint, HitOnlyTargetOrWorld, i);
							int Traced_Target;
								
							Traced_Target = TR_GetEntityIndex(trace);
							delete trace;
								
							if(Traced_Target == i)
							{
								float distance_1 = GetVectorDistance(VicLoc, spawnLoc);
								float damage_1 = Custom_Explosive_Logic(client, distance_1, explosion_range_dmg_falloff, damage, explosionRadius + 1.0);
								
								if(damage_1 > damage)
								{
									damage_1 = damage;
								}
								SDKHooks_TakeDamage(i, client, client, damage_1, damage_flags, weapon, CalculateExplosiveDamageForce(spawnLoc, VicLoc, explosionRadius), VicLoc);
								TargetsHit += 1;
							}
						}
					}
				}
			}
			for (int pass = 0; pass <= 2; pass++)
			{
				static char classname[1024];
				if (pass == 0) classname = "obj_sentrygun";
				else if (pass == 1) classname = "obj_dispenser";
			//	else if (pass == 2) classname = "obj_teleporter";
				else if (pass == 2) classname = "base_boss";
				
				int i = MaxClients + 1;
				while ((i = FindEntityByClassname(i, classname)) != -1)
				{
					if(TargetsHit > maxtargetshit)
					{
						break;
					}
					if (GetEntProp(entity, Prop_Send, "m_iTeamNum")!=GetEntProp(i, Prop_Send, "m_iTeamNum")) 
					{
						CClotBody npc = view_as<CClotBody>(i);
						if(pass != 2)
						{
							VicLoc = WorldSpaceCenter(i);						
							if (GetVectorDistance(spawnLoc, VicLoc, true) <= Pow(explosionRadius, 2.0))
							{
								Handle trace; 
								trace = TR_TraceRayFilterEx(spawnLoc, VicLoc, ( MASK_SHOT | CONTENTS_SOLID ), RayType_EndPoint, HitOnlyTargetOrWorld, i);
								int Traced_Target;
								
								Traced_Target = TR_GetEntityIndex(trace);
								delete trace;
								
								if(Traced_Target == i)
								{
									float distance_1 = GetVectorDistance(VicLoc, spawnLoc);
									float damage_1 = Custom_Explosive_Logic(client, distance_1, explosion_range_dmg_falloff, damage, explosionRadius + 1.0);
																				
									if(damage_1 > damage)
									{
										damage_1 = damage;
									}
							
									SDKHooks_TakeDamage(i, client, client, damage_1, damage_flags, weapon, CalculateExplosiveDamageForce(spawnLoc, VicLoc, explosionRadius), VicLoc);
									TargetsHit += 1;
								}
							}
						}		
						else
						{
							if(!npc.m_bThisEntityIgnored && GetEntProp(i, Prop_Data, "m_iHealth") > 0) //Check if dead or even targetable
							{
								VicLoc = WorldSpaceCenter(i);						
								if (GetVectorDistance(spawnLoc, VicLoc, true) <= Pow(explosionRadius, 2.0))
								{
									Handle trace; 
									trace = TR_TraceRayFilterEx(spawnLoc, VicLoc, ( MASK_SHOT | CONTENTS_SOLID ), RayType_EndPoint, HitOnlyTargetOrWorld, i);
									int Traced_Target;
									
									Traced_Target = TR_GetEntityIndex(trace);
									delete trace;
									
									if(Traced_Target == i)
									{
										float distance_1 = GetVectorDistance(VicLoc, spawnLoc);
										float damage_1 = Custom_Explosive_Logic(client, distance_1, explosion_range_dmg_falloff, damage, explosionRadius + 1.0);
																	
										if(damage_1 > damage)
										{
											damage_1 = damage;
										}
							
										SDKHooks_TakeDamage(i, client, client, damage_1, damage_flags, weapon, CalculateExplosiveDamageForce(spawnLoc, VicLoc, explosionRadius), VicLoc);
										TargetsHit += 1;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
}

stock void UpdatePlayerPoints(int client)
{
	int Points;
	
	Points += Healing_done_in_total[client] / 5;
	
	Points += RoundToCeil(Damage_dealt_in_total[client]) / 200;
	
	Points += Resupplies_Supplied[client] * 2;
	
	Points += i_BarricadeHasBeenDamaged[client] / 65;
	
	Points += i_ExtraPlayerPoints[client] / 50;
	
	Points /= 10;
	
	PlayerPoints[client] = Points;	// Do stuff here :)
}

stock int MaxArmorCalculation(int value, int client, float multiplyier)
{
	int Armor_Max;
	
	if(value == 50)
		Armor_Max = 300;
											
	else if(value == 100)
		Armor_Max = 450;
											
	else if(value == 150)
		Armor_Max = 1000;
										
	else if(value == 200)
		Armor_Max = 2000;	
		
	else
		Armor_Max = 200;
		
	return (RoundToCeil(float(Armor_Max) * multiplyier));
	
}

//	f_TimerTickCooldownRaid = 0.0;
//	f_TimerTickCooldownShop = 0.0;
stock void PlayTickSound(bool RaidTimer, bool NormalTimer)
{
	if(NormalTimer)
	{
		if(f_TimerTickCooldownShop < GetGameTime())
		{
			f_TimerTickCooldownShop = GetGameTime() + 0.9;
			EmitSoundToAll("misc/halloween/clock_tick.wav", _, SNDCHAN_AUTO, _, _, 1.0);
		}
	}
	if(RaidTimer)
	{
		if(f_TimerTickCooldownRaid < GetGameTime())
		{
			float Timer_Show = RaidModeTime - GetGameTime();
		
			if(Timer_Show < 0.0)
				Timer_Show = 0.0;
				
			
			if(Timer_Show < 10.0)
			{
				if(Timer_Show < 5.0)
				{
					f_TimerTickCooldownRaid = GetGameTime() + 0.9;
				}
				else
				{
					f_TimerTickCooldownRaid = GetGameTime() + 1.9;
				}
			}
			else
				f_TimerTickCooldownRaid = GetGameTime() + 10.0;
				
			EmitSoundToAll("mvm/mvm_bomb_warning.wav", _, SNDCHAN_AUTO, _, _, 1.0);
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsClientInGame(client))
				{
					SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
					SetGlobalTransTarget(client);
					ShowSyncHudText(client,  SyncHud_Notifaction, "You have %.1f Seconds left to kill the Raid!", Timer_Show);	
				}
			}
		}
	}
}

public bool HitOnlyTargetOrWorld(int entity, int contentsMask, any iExclude)
{
	if(entity == 0)
	{
		return true;
	}
	if(entity == iExclude)
	{
		return true;
	}
		
	
	return false;
}


public bool HitOnlyWorld(int entity, int contentsMask, any iExclude)
{
	if(entity == 0)
	{
		return true;
	}	
	
	return false;
}

public void CauseDamageLaterSDKHooks_Takedamage(DataPack pack)
{
	pack.Reset();
	int Victim = EntRefToEntIndex(pack.ReadCell());
	int client = EntRefToEntIndex(pack.ReadCell());
	int inflictor = EntRefToEntIndex(pack.ReadCell());
	float damage = pack.ReadFloat();
	int damage_type = pack.ReadCell();
	int weapon = EntRefToEntIndex(pack.ReadCell());
	float damage_force[3];
	damage_force[0] = pack.ReadFloat();
	damage_force[1] = pack.ReadFloat();
	damage_force[2] = pack.ReadFloat();
	float playerPos[3];
	playerPos[0] = pack.ReadFloat();
	playerPos[1] = pack.ReadFloat();
	playerPos[2] = pack.ReadFloat();
	
	if(IsValidEntity(Victim) && IsValidEntity(client) && IsValidEntity(weapon) && IsValidEntity(inflictor))
	{
		SDKHooks_TakeDamage(Victim, client, inflictor, damage, damage_type, weapon, damage_force, playerPos);
	}
	
	delete pack;
}


public void ReviveAll()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			DoOverlay(client, "");
			if(GetClientTeam(client)==2)
			{
				if((!IsPlayerAlive(client) || TeutonType[client] == TEUTON_DEAD)/* && !IsValidEntity(EntRefToEntIndex(RaidBossActive))*/)
				{
					applied_lastmann_buffs_once = false;
					DHook_RespawnPlayer(client);
					TF2_AddCondition(client, TFCond_UberchargedCanteen, 2.0);
					TF2_AddCondition(client, TFCond_MegaHeal, 2.0);
				}
				else if(dieingstate[client] > 0)
				{
					dieingstate[client] = 0;
					Store_ApplyAttribs(client);
					TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.00001);
					int entity, i;
					while(TF2U_GetWearable(client, entity, i))
					{
						SetEntityRenderMode(entity, RENDER_NORMAL);
						SetEntityRenderColor(entity, 255, 255, 255, 255);
					}
					SetEntityRenderMode(client, RENDER_NORMAL);
					SetEntityRenderColor(client, 255, 255, 255, 255);
					SetEntityCollisionGroup(client, 5);
					if(!EscapeMode)
					{
						SetEntityHealth(client, 50);
						RequestFrame(SetHealthAfterRevive, client);
					}	
					else
					{
						SetEntityHealth(client, 150);
						RequestFrame(SetHealthAfterRevive, client);						
					}
				}
			}
		}
	}	
	Music_EndLastmann();
	CheckAlivePlayers();
}



stock void LookAtTarget(int client, int target)
{
    float angles[3];
    float clientEyes[3];
    float targetEyes[3];
    float resultant[3]; 
    
    GetClientEyePosition(client, clientEyes);
    if(target > 0 && target <= MaxClients && IsClientInGame(target))
    {
		GetClientEyePosition(target, targetEyes);
    }
    else
    {
    	targetEyes = WorldSpaceCenter(target);
    }
    MakeVectorFromPoints(targetEyes, clientEyes, resultant); 
    GetVectorAngles(resultant, angles); 
    if(angles[0] >= 270){ 
        angles[0] -= 270; 
        angles[0] = (90-angles[0]); 
    }else{ 
        if(angles[0] <= 90){ 
            angles[0] *= -1; 
        } 
    } 
    angles[1] -= 180; 
    TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR); 
} 


int Trail_Attach(int entity, char[] trail, int alpha, float lifetime=1.0, float startwidth=22.0, float endwidth=0.0, int rendermode)
{
	int entIndex = CreateEntityByName("env_spritetrail");
	if (entIndex > 0 && IsValidEntity(entIndex))
	{
		char strTargetName[MAX_NAME_LENGTH];

		DispatchKeyValue(entity, "targetname", strTargetName);
		Format(strTargetName,sizeof(strTargetName),"trail%d",EntIndexToEntRef(entity));
		DispatchKeyValue(entity, "targetname", strTargetName);
		DispatchKeyValue(entIndex, "parentname", strTargetName);
		

		DispatchKeyValue(entIndex, "spritename", trail);
		SetEntPropFloat(entIndex, Prop_Send, "m_flTextureRes", 1.0);
			
		char sTemp[5];
		IntToString(alpha, sTemp, sizeof(sTemp));
		DispatchKeyValue(entIndex, "renderamt", sTemp);
			
		DispatchKeyValueFloat(entIndex, "lifetime", lifetime);
		DispatchKeyValueFloat(entIndex, "startwidth", startwidth);
		DispatchKeyValueFloat(entIndex, "endwidth", endwidth);
		
		IntToString(rendermode, sTemp, sizeof(sTemp));
		DispatchKeyValue(entIndex, "rendermode", sTemp);
			
		DispatchSpawn(entIndex);
		float f_origin[3];
		f_origin = GetAbsOrigin(entity);
		TeleportEntity(entIndex, f_origin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(strTargetName);
		AcceptEntityInput(entIndex, "SetParent");
		return entIndex;
	}	
	return -1;
}

stock void ConstrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance, bool do2)
{
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	if(do2)
		endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

public float Ability_Check_Cooldown(int client, int what_slot)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	char classname[32];
	GetEntityClassname(weapon, classname, 32);
	
	int weapon_slot = TF2_GetClassnameSlot(classname);
	
	switch(what_slot)
	{
		case 1:	
		{
			return (f_Ability_Cooldown_m1[client][weapon_slot] - GetGameTime());
		}
		case 2:	
		{
			return (f_Ability_Cooldown_m2[client][weapon_slot] - GetGameTime());
		}
		case 3:	
		{
			return (f_Ability_Cooldown_r[client][weapon_slot] - GetGameTime());
		}
	}
	PrintToChatAll("Somehow something has no cooldown :( Please report!!!");
	return 0.0;
}

public void Ability_Apply_Cooldown(int client, int what_slot, float cooldown)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	char classname[32];
	GetEntityClassname(weapon, classname, 32);
	
	int weapon_slot = TF2_GetClassnameSlot(classname);
	
	cooldown += GetGameTime(); //lol
	switch(what_slot)
	{
		case 1:	
		{
			f_Ability_Cooldown_m1[client][weapon_slot] = cooldown;
		}
		case 2:	
		{
			f_Ability_Cooldown_m2[client][weapon_slot] = cooldown;
		}
		case 3:	
		{
			f_Ability_Cooldown_r[client][weapon_slot] = cooldown;
		}
	}
}

#define spirite "spirites/zerogxplode.spr"


public void MakeExplosionFrameLater(DataPack pack)
{
	pack.Reset();
	float vec_pos[3];
	vec_pos[0] = pack.ReadFloat();
	vec_pos[1] = pack.ReadFloat();
	vec_pos[2] = pack.ReadFloat();
	int Do_Sound = pack.ReadCell();
	
	int ent = CreateEntityByName("env_explosion");
	if(ent != -1)
	{
	//	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		
		if(Do_Sound == 1)
		{		
			EmitAmbientSound("ambient/explosions/explode_3.wav", vec_pos);
		}
		
		DispatchKeyValueVector(ent, "origin", vec_pos);
		DispatchKeyValue(ent, "spawnflags", "581");
						
		DispatchKeyValue(ent, "rendermode", "0");
		DispatchKeyValue(ent, "fireballsprite", spirite);
										
		DispatchKeyValueFloat(ent, "DamageForce", 0.0);								
		SetEntProp(ent, Prop_Data, "m_iMagnitude", 0); 
		SetEntProp(ent, Prop_Data, "m_iRadiusOverride", 0); 
									
		DispatchSpawn(ent);
		ActivateEntity(ent);
									
		AcceptEntityInput(ent, "explode");
		AcceptEntityInput(ent, "kill");
	}		
	SpawnSmallExplosionNotRandom(vec_pos);
	delete pack;
}


stock void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback!=INVALID_FUNCTION && !DHookEnableDetour(detour, false, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);

		if(postCallback!=INVALID_FUNCTION && !DHookEnableDetour(detour, true, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);

		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}