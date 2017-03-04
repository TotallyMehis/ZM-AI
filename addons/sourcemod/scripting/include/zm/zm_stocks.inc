#if defined _zm_stocks_included
    #endinput
#endif
#define _zm_stocks_included



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


#define AMMOTYPE_PISTOL     2
#define AMMOTYPE_SMG        3
#define AMMOTYPE_RIFLE      4
#define AMMOTYPE_SHOTGUN    6
#define AMMOTYPE_MOLOTOV    11
#define AMMOTYPE_REVOLVER   12


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

stock int Zm_GetResources( int client )
{
    return GetEntProp( client, Prop_Send, "m_iZombiePool" );
}

stock void Zm_SetResources( int client, int value )
{
    SetEntProp( client, Prop_Send, "m_iZombiePool", value );
}

stock int Zm_GetPopCount( int client )
{
    return GetEntProp( client, Prop_Send, "m_iZombiePopCount" );
}

stock void Zm_SetPopCount( int client, int value )
{
    SetEntProp( client, Prop_Send, "m_iZombiePopCount", value );
}

// Used for zombie spawn orbs, trap orbs and other zm specific ents.
stock bool Zm_IsEntActive( int ent )
{
    return view_as<bool>( GetEntProp( ent, Prop_Data, "m_bActive" ) );
}

stock bool Zm_IsHumanAlive( int client )
{
    return ( GetClientTeam( client ) == TEAM_HUMAN && IsPlayerAlive( client ) );
}