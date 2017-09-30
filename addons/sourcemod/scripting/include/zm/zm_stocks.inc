#if defined _zm_stocks_included
    #endinput
#endif
#define _zm_stocks_included


// To include whistler.
//#define ZM2

// For Reborn support.
#define ZMR


enum
{
    SLOT_FISTS = 0, // + Carry
    SLOT_PISTOL,
    SLOT_MELEE,
    SLOT_PRIMARY,
    SLOT_MOLOTOV,
    
    NUM_SLOTS
};

enum
{
    TEAM_UNASSIGNED = 0,
    TEAM_SPEC,
    TEAM_HUMAN,
    TEAM_ZM
};

enum
{
    ZTYPE_INVALID = -1,
    
    ZTYPE_SHAMBLER,
    ZTYPE_BANSHEE,
    ZTYPE_HULK,
    ZTYPE_DRIFTER,
    ZTYPE_IMMOLATOR,
#if defined ZM2
    ZTYPE_WHISTLER,
#endif
    
    NUM_ZTYPES
};

#define ZFLAG_SHAMBLER      ( 1 << ZTYPE_SHAMBLER )
#define ZFLAG_BANSHEE       ( 1 << ZTYPE_BANSHEE )
#define ZFLAG_HULK          ( 1 << ZTYPE_HULK )
#define ZFLAG_DRIFTER       ( 1 << ZTYPE_DRIFTER )
#define ZFLAG_IMMOLATOR     ( 1 << ZTYPE_IMMOLATOR )
#if defined ZM2
#define ZFLAG_WHISTLER      ( 1 << ZTYPE_WHISTLER )
#endif


#if defined ZMR
#define AMMOTYPE_PISTOL     0
#define AMMOTYPE_RIFLE      1
#define AMMOTYPE_SHOTGUN    2
#define AMMOTYPE_SMG        3
#define AMMOTYPE_MOLOTOV    4
#define AMMOTYPE_REVOLVER   5
#else
#define AMMOTYPE_PISTOL     2
#define AMMOTYPE_SMG        3
#define AMMOTYPE_RIFLE      4
#define AMMOTYPE_SHOTGUN    6
#define AMMOTYPE_MOLOTOV    11
#define AMMOTYPE_REVOLVER   12
#endif

stock bool Zm_GetWeaponAmmoType( int ent, int &ammotype )
{
    decl String:szClass[21];
    GetEntityClassname( ent, szClass, sizeof( szClass ) );
    
    // weapon_zm_fists
    // weapon_zm_improvised
    // weapon_zm_sledge
    // weapon_zm_pistol
    // weapon_zm_mac10
    // weapon_zm_rifle
    // weapon_zm_shotgun
    // weapon_zm_molotov
    // weapon_zm_revolver
    if ( StrEqual( szClass, "weapon_zm_pistol" ) )
    {
        ammotype = AMMOTYPE_PISTOL;
        return true;
    }
    
    if ( StrEqual( szClass, "weapon_zm_mac10" ) )
    {
        ammotype = AMMOTYPE_SMG;
        return true;
    }
    
    if ( StrEqual( szClass, "weapon_zm_rifle" ) )
    {
        ammotype = AMMOTYPE_RIFLE;
        return true;
    }
    
    if ( StrEqual( szClass, "weapon_zm_shotgun" ) )
    {
        ammotype = AMMOTYPE_SHOTGUN;
        return true;
    }
    
    if ( StrEqual( szClass, "weapon_zm_molotov" ) )
    {
        ammotype = AMMOTYPE_MOLOTOV;
        return true;
    }
    
    if ( StrEqual( szClass, "weapon_zm_revolver" ) )
    {
        ammotype = AMMOTYPE_REVOLVER;
        return true;
    }
    
    return false;
}

stock bool Zm_IsHumanAlive( int client )
{
    return ( GetClientTeam( client ) == TEAM_HUMAN && IsPlayerAlive( client ) );
}

stock int Zm_GetClientResources( int client )
{
#if defined ZMR
    return GetEntProp( client, Prop_Send, "m_nResources" );
#else
    return GetEntProp( client, Prop_Send, "m_iZombiePool" );
#endif
}

stock void Zm_SetClientResources( int client, int value )
{
#if defined ZMR
    SetEntProp( client, Prop_Send, "m_nResources", value );
#else
    SetEntProp( client, Prop_Send, "m_iZombiePool", value );
#endif
}

stock int Zm_GetClientPopCount( int client )
{
#if defined ZMR
    return GameRules_GetProp( "m_nZombiePop" ); // Popcount is shared between players.
#else
    return GetEntProp( client, Prop_Send, "m_iZombiePopCount" );
#endif
}

stock void Zm_SetClientPopCount( int client, int value )
{
    SetEntProp( client, Prop_Send, "m_iZombiePopCount", value );
}

stock int Zm_GetEntityCost( int ent )
{
#if defined ZMR
    return GetEntProp( ent, Prop_Data, "m_nCost" );
#else
    return GetEntProp( ent, Prop_Data, "m_iCost" );
#endif
}

stock int Zm_GetEntityTrapCost( int ent )
{
#if defined ZMR
    return GetEntProp( ent, Prop_Data, "m_nTrapCost" );
#else
    return GetEntProp( ent, Prop_Data, "m_iTrapCost" );
#endif
}

stock int Zm_GetEntityRemoveOnTrigger( int ent )
{
    return GetEntProp( ent, Prop_Data, "m_bRemoveOnTrigger" );
}

// Used for zombie spawn orbs, trap orbs and other zm specific ents.
stock bool Zm_IsEntityActive( int ent )
{
    return view_as<bool>( GetEntProp( ent, Prop_Data, "m_bActive" ) );
}

stock void Zm_GetEntityTrapDescription( int ent, char[] sz, int len )
{
#if defined ZMR
    GetEntPropString( ent, Prop_Data, "m_sDescription", sz, len );
#else
    GetEntPropString( ent, Prop_Data, "m_szDescription", sz, len );
#endif
}

stock int Zm_GetEntityZombieFlags( int ent )
{
#if defined ZMR
    return GetEntProp( ent, Prop_Data, "m_fZombieFlags" );
#else
    return GetEntProp( ent, Prop_Data, "m_iZombieFlags" );
#endif
}
