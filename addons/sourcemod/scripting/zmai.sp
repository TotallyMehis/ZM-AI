#include <sourcemod>
#include <sdktools>
#include <regex>


#include <zm/zm_stocks>

#include <msharedutil/ents>
#include <msharedutil/arrayvec>




//#define DEBUG
//#define DEBUG_SPAWNROOMSIZE
//#define DEBUG_AISPAWNING
//#define DEBUG_TRAPS
//#define DEBUG_ZOMBIESPAWNS
//#define DEBUG_TRAPTYPE
//#define DEBUG_AITHINK
//#define DEBUG_HANDLEZOMBIES
//#define DEBUG_ZOMBIESPAWNING
//#define DEBUG_HURT
//#define DEBUG_REGEX



#define PREFIX                      "[ZM AI] "

#define DEF_AINAME                  "ZM AI"

#define PLUGIN_VERSION              "0.9"



#define THINK_FREQ                  0.25



#define HULL_Z_MAX                  72.0
#define HULL_Z_MAX_DUCKED           60.0


#define ROOMSIZE_MAX                2048.0

#define ROOM_MASK                   MASK_NPCSOLID

#define ROOM_CHECKDIST              128.0

#define SPOTS_MEDIUM                12
#define SPOTS_BIG                   24
#define SPOTS_HUGE                  50

enum
{
    ROOMSIZE_SMALL = 0,
    ROOMSIZE_MEDIUM,
    ROOMSIZE_BIG,
    ROOMSIZE_HUGE
};

enum
{
    SPAWN_ENTREF = 0,
    
    SPAWN_ROOMSIZE,
    
    SPAWN_POS[3],
    
    SPAWN_SIZE
};


#define TRAPFLAG_CANUSETRIGGER      ( 1 << 0 )
#define TRAPFLAG_ISWAITINGTRIGGER   ( 1 << 1 )
#define TRAPFLAG_ALWAYS             ( 1 << 2 )
#define TRAPFLAG_TRACE_ACTIVATE     ( 1 << 3 )


#define DEF_GROUPID                 -1
#define DEF_VECTOR                  view_as<float>( { 0.0, 0.0, 0.0 } )

#define DEF_DELAY                   1.0
#define DEF_DELAY_MIN               0.0
#define DEF_DELAY_MAX               0.0
#define DEF_DELAY_MULTPERHUMAN      1.0
#define DEF_AOESIZE                 0.0
#define DEF_VISSIZE                 0.0
#define DEF_CHANCE                  1.0
#define DEF_CHANCE_MULTPERHUMAN     1.0
#define DEF_MIN_RES                 0
#define DEF_MAX_RES                 0

#define DEF_NONE_AOESIZE            ( 128.0 * 128.0 )
#define DEF_NONE_VISSIZE            ( 512.0 * 512.0 )

#define DEF_WAIT                    0.0

enum
{
    TRAP_ENTREF = 0,
    
    TRAP_FLAGS,
    
    TRAP_AOESIZE_SQ,
    TRAP_VISSIZE_SQ,
    
    TRAP_DELAY,
    TRAP_DELAY_MIN,
    TRAP_DELAY_MAX,
    TRAP_DELAY_MULTPERHUMAN,
    
    TRAP_NEXTUSE,
    
    TRAP_GROUPID,
    
    TRAP_CHECKPOS[3],
    
    TRAP_TRACE_DIR[3],
    TRAP_TRACE_LEN,
    TRAP_TRACE_W_H,
    
    TRAP_CHANCE,
    TRAP_CHANCE_MULTPERHUMAN,
    
    TRAP_MIN_RES,
    TRAP_MAX_RES,
    
    TRAP_SIZE
};

#define MAX_TRAP_DESC           128
#define MAX_TRAP_DESC_CELL      MAX_TRAP_DESC / 4

#define MAX_TARGETNAME          64
#define MAX_TARGETNAME_CELL     MAX_TARGETNAME / 4

enum
{
    TRAPTYPE_FIND_TARGETNAME[MAX_TARGETNAME_CELL] = 0,
    
    TRAPTYPE_FIND_REGEXHANDLE,
    
    
    TRAPTYPE_FLAGS,
    
    TRAPTYPE_AOESIZE_SQ,
    TRAPTYPE_VISSIZE_SQ,
    
    
    TRAPTYPE_WAIT_FROMSTART,
    
    TRAPTYPE_DELAY,
    TRAPTYPE_DELAY_MIN,
    TRAPTYPE_DELAY_MAX,
    TRAPTYPE_DELAY_MULTPERHUMAN,
    
    TRAPTYPE_GROUPID,
    
    TRAPTYPE_TRACE_DIR[3],
    TRAPTYPE_TRACE_LEN,
    TRAPTYPE_TRACE_W_H,
    
    TRAPTYPE_TRACE_CHECKPOSOFFSET,
    TRAPTYPE_CHECKPOSOFFSET[3],
    
    TRAPTYPE_CHANCE,
    TRAPTYPE_CHANCE_MULTPERHUMAN,
    
    TRAPTYPE_MIN_RES,
    TRAPTYPE_MAX_RES,
    
    TRAPTYPE_SIZE
};


#define CONFIG_GENERALTRAPS         "zmai_generaltraps.cfg"


#define DEF_BASE_SPAWN_DIST         1024.0
#define DEF_BASE_SPAWN_DIST_SQ      DEF_BASE_SPAWN_DIST * DEF_BASE_SPAWN_DIST

#define DEF_BASE_DELETE_DIST        2200.0
#define DEF_BASE_DELETE_DIST_SQ     DEF_BASE_DELETE_DIST * DEF_BASE_DELETE_DIST


// If further than this from the closest player and is also idle, we will move the zombie.
#define MIN_ZOMBIEMOVE_DIST         256.0
#define MIN_ZOMBIEMOVE_DIST_SQ      MIN_ZOMBIEMOVE_DIST * MIN_ZOMBIEMOVE_DIST

// Max distance modifier.
#define SPAWN_DIST_MODF             512.0
#define SPAWN_DIST_MODF_SQ          SPAWN_DIST_MODF * SPAWN_DIST_MODF

// Minimum distance the trap has to be to the ground in order to be a triggerable.
#define TRAP_MIN_TRIGGER_DIST       256.0
//#define TRAP_MIN_TRIGGER_DIST_SQ    TRAP_MIN_TRIGGER_DIST * TRAP_MIN_TRIGGER_DIST


#define DIFFICULTY_HARD             3
#define DIFFICULTY_MED              2
#define DIFFICULTY_EASY             1
#define DIFFICULTY_SUPEREASY        0

#define DIF_HARD                    500.0 // Approx. 10 humans with primary weapons (with ammo).
#define DIF_MED                     250.0 // Approx. 5 humans with primary weapons (with ammo).
#define DIF_EASY                    100.0 // Approx. 2 humans with primary weapons (with ammo).


#define NPC_STATE_IDLE              1
#define NPC_STATE_COMBAT            3

#define DMG_GENERIC                 0
#define DMG_ALWAYSGIB               ( 1 << 13 )

char g_szZTypes[NUM_ZTYPES][17] =
{
    "npc_zombie",
    "npc_fastzombie",
    "npc_poisonzombie",
    "npc_dragzombie",
    "npc_burnzombie",
#if defined ZM2
    "npc_whistler"
#endif
};

float g_flSpawnTimeMultiplier[NUM_ZTYPES] =
{
    1.0,
    2.0, // Fuck banshees
    1.7,
    1.4,
    2.0,
#if defined ZM2
    2.0
#endif
};


int g_iBot;

ArrayList g_hTrapTypes;
ArrayList g_hSpawns;
ArrayList g_hTraps;

int g_iNumSpawns;
int g_iNumTraps;
int g_nPopCount;
int g_nResources;
int g_nHumans;

float g_flCurTime; // Engine time cached.

int g_iDifficulty;

float g_flNextSpawn;
float g_flNextTrap;
float g_flNextForceAct; // Used to track whether we should ignore difficulty max zombie pop.
//float g_flNextPopCheck; // When do we check if our zombie pop is true?

float g_flNextDifficultyHandle;
float g_flNextZombieHandle;





int g_iHurt;

// Can be changed during game for balancing.
float g_flZombieDeleteDistSq;
float g_flZombieSpawnDistSq;

// Same as above but will keep the base value.
float g_flBaseZombieDeleteDistSq;
float g_flBaseZombieSpawnDistSq;

float g_flLastSpawn; // To track whether we should increase distances above.
float g_flNextDistChange; // When to reset the distance increase above.


// Cache variables for convars.
ConVar g_ConVar_ZombieMax;

ConVar g_ConVar_ZombiePopCost_Shambler;
ConVar g_ConVar_ZombiePopCost_Banshee;
ConVar g_ConVar_ZombiePopCost_Hulk;
ConVar g_ConVar_ZombiePopCost_Drifter;
ConVar g_ConVar_ZombiePopCost_Immolator;

ConVar g_ConVar_Cost_Shambler;
ConVar g_ConVar_Cost_Banshee;
ConVar g_ConVar_Cost_Hulk;
ConVar g_ConVar_Cost_Drifter;
ConVar g_ConVar_Cost_Immolator;

// OUR CONVARS
ConVar g_ConVar_InactDifChange;
ConVar g_ConVar_BotName;
ConVar g_ConVar_RoundRestart;



bool g_bRoundEnded;

bool g_bEnabled;


int g_Offset_iAmmo;


#include "zmai/ai_think.sp"
#include "zmai/cmds.sp"
#include "zmai/events.sp"
#include "zmai/events_players.sp"
#include "zmai/events_round.sp"
#include "zmai/events_zombies.sp"
#include "zmai/file.sp"


public Plugin myinfo =
{
    author = "Mehis",
    name = "ZM AI",
    description = "An AI that can fill the role of ZM.",
    url = "",
    version = PLUGIN_VERSION
};

public void OnPluginStart()
{
    g_Offset_iAmmo = FindSendPropInfo( "CBasePlayer", "m_iAmmo" );
    
    if ( g_Offset_iAmmo == -1 )
    {
        SetFailState( PREFIX..."Couldn't find iAmmo offset!" );
    }
    
    
    // CONVARS
    g_ConVar_ZombieMax = FindConVar( "zm_zombiemax" );
    if ( g_ConVar_ZombieMax == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_zombiemax!" );
    
    
    // Cache popcost...
    g_ConVar_ZombiePopCost_Shambler = FindConVar( "zm_popcost_shambler" );
    if ( g_ConVar_ZombiePopCost_Shambler == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_shambler!" );
    
    g_ConVar_ZombiePopCost_Banshee = FindConVar( "zm_popcost_banshee" );
    if ( g_ConVar_ZombiePopCost_Banshee == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_banshee!" );
    
    g_ConVar_ZombiePopCost_Hulk = FindConVar( "zm_popcost_hulk" );
    if ( g_ConVar_ZombiePopCost_Hulk == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_hulk!" );
    
    g_ConVar_ZombiePopCost_Drifter = FindConVar( "zm_popcost_drifter" );
    if ( g_ConVar_ZombiePopCost_Drifter == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_drifter!" );
    
    g_ConVar_ZombiePopCost_Immolator = FindConVar( "zm_popcost_immolator" );
    if ( g_ConVar_ZombiePopCost_Immolator == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_immolator!" );
    
    
    // Cache cost...
    g_ConVar_Cost_Shambler = FindConVar( "zm_cost_shambler" );
    if ( g_ConVar_Cost_Shambler == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_shambler!" );
    
    g_ConVar_Cost_Banshee = FindConVar( "zm_cost_banshee" );
    if ( g_ConVar_Cost_Banshee == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_banshee!" );
    
    g_ConVar_Cost_Hulk = FindConVar( "zm_cost_hulk" );
    if ( g_ConVar_Cost_Hulk == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_hulk!" );
    
    g_ConVar_Cost_Drifter = FindConVar( "zm_cost_drifter" );
    if ( g_ConVar_Cost_Drifter == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_drifter!" );
    
    g_ConVar_Cost_Immolator = FindConVar( "zm_cost_immolator" );
    if ( g_ConVar_Cost_Immolator == null ) SetFailState( PREFIX..."Couldn't find cvar handle for zm_popcost_immolator!" );
    
    
    
    g_ConVar_InactDifChange = CreateConVar( "zmai_inactivitydifchangetime", "60", "How many seconds of inactivitity till the AI will ignore difficulty caps.", FCVAR_NOTIFY, true, 0.0 );
    
    g_ConVar_BotName = CreateConVar( "zmai_botname", DEF_AINAME, "Name of the AI.", FCVAR_NOTIFY );
    g_ConVar_RoundRestart = CreateConVar( "zmai_overrideroundrestart", "1", "Do we switch if a real player attemps to restart the round as ZM.", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
    g_ConVar_BotName.AddChangeHook( E_ConVarChange_BotName );
    
    
    AutoExecConfig( true, "zmai" );
    
    
    
    // CMDS
    RegConsoleCmd( "sm_replaceai", Cmd_ReplaceAI );
    RegConsoleCmd( "sm_takecontrol", Cmd_ReplaceAI );
    RegConsoleCmd( "sm_becomezm", Cmd_ReplaceAI );
    RegConsoleCmd( "sm_ai", Cmd_ReplaceAI );
    RegConsoleCmd( "sm_zm", Cmd_ReplaceAI_Silent );
    RegConsoleCmd( "sm_zombiemaster", Cmd_ReplaceAI_Silent );
    
    AddCommandListener( Lstnr_RoundRestart, "roundrestart" );
    
    
    // TIMERS
    CreateTimer( 90.0, T_DisplayStatus, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
    
    
    // EVENTS
    HookEvent( "player_spawn", E_PlayerSpawn );
    HookEvent( "player_hurt", E_PlayerHurt );
    
    HookEvent( "round_restart", E_RoundRestart, EventHookMode_PostNoCopy );
    HookEvent( "round_victory", E_RoundVictory );
    
    HookEvent( "zombie_spawn", E_ZombieSpawn );
    
    
    
    
    
    g_hSpawns = new ArrayList( SPAWN_SIZE );
    g_hTraps = new ArrayList( TRAP_SIZE );
    g_hTrapTypes = new ArrayList( TRAPTYPE_SIZE );
    
    g_iNumSpawns = 0;
    g_iNumTraps = 0;
}

public Action T_DisplayStatus( Handle hTimer )
{
    if ( !g_bEnabled )
    {
        PrintToChatAll( PREFIX..."ZM AI is disabled for this map." );
    }
    else if ( g_iBot && GetClientTeam( g_iBot ) == TEAM_ZM )
    {
        PrintToChatAll( PREFIX..."The AI is not working properly? You can replace it by typing !ai in chat." );
    }
    
    
    return Plugin_Continue;
}

public Action T_CreateBot( Handle hTimer )
{
    FindBot();
}

public void OnMapStart()
{
    // Round stuff.
    g_bRoundEnded = true;
    //g_flRoundStartTime = 0.0;

    
    
    // Enable by default.
    g_bEnabled = true;
    
    
    g_flBaseZombieDeleteDistSq = DEF_BASE_DELETE_DIST_SQ;

    g_flBaseZombieSpawnDistSq = DEF_BASE_SPAWN_DIST_SQ;
    
    
    g_flNextZombieHandle = 0.0;
    g_flNextDifficultyHandle = 0.0;
    
    g_flNextForceAct = 0.0;
    g_flNextDistChange = 0.0;
    g_flNextSpawn = 0.0;
    g_flNextTrap = 0.0;
    
    g_iBot = 0;
    
    
    
    
    ReadFiles();
    
    
    g_flZombieDeleteDistSq = g_flBaseZombieDeleteDistSq;
    g_flZombieSpawnDistSq = g_flBaseZombieSpawnDistSq;
    
    
    if ( g_bEnabled )
    {
        CreateTimer( 1.0, T_CreateBot, TIMER_FLAG_NO_MAPCHANGE );
        
        CreateTimer( THINK_FREQ, T_BotThink, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
    }
}

public void OnClientPutInServer( int client )
{
    if ( !g_iBot && IsFakeClient( client ) )
    {
        g_iBot = client;
        
        SetBotName();
        
        // Netprops need to be set after put in server.
        RequestFrame( Event_BotPutInServer_Post, GetClientUserId( client ) );
    }
}

stock void SetBotName()
{
    if ( !g_iBot ) return;
    
    
    char szName[32];
    g_ConVar_BotName.GetString( szName, sizeof( szName ) );
    
    SetClientInfo( g_iBot, "name", ( szName[0] == '\0' ) ? DEF_AINAME : szName );
}

public void Event_BotPutInServer_Post( int bot )
{
    if ( (bot = GetClientOfUserId( bot )) && bot == g_iBot )
    {
        // Set necessary props here.
        SetEntProp( bot, Prop_Send, "m_zmParticipation", 0 );
        
        
        SetBotPhysicsFlags( bot );
    }
}

public void OnClientDisconnect( int client )
{
    if ( g_iBot == client )
    {
        g_iBot = 0;
    }
    // Save the round with the bot if an actual master quits.
    else if (   !g_bRoundEnded
            &&  IsClientInGame( client )
            &&  GetClientTeam( client ) == TEAM_ZM
            &&  IsValidAI()
            &&  GetClientTeam( g_iBot ) != TEAM_ZM )
    {
        ChangeClientTeam_Bot( g_iBot, TEAM_ZM );
    }
}

stock void ChangeClientTeam_Bot( int bot, int team )
{
    ChangeClientTeam( bot, team );
    
    SetBotPhysicsFlags( bot );
}

stock void SetBotPhysicsFlags( int bot )
{
    // If this isn't set, the bot will be able to be spectated while in the spectator team.
#define PFLAG_OBSERVER      8

    int flags = GetEntProp( bot, Prop_Data, "m_afPhysicsFlags" );
    
    if ( GetClientTeam( bot ) == TEAM_SPEC )
    {
        SetEntProp( bot, Prop_Data, "m_afPhysicsFlags", flags | PFLAG_OBSERVER );
    }
    else
    {
        SetEntProp( bot, Prop_Data, "m_afPhysicsFlags", flags & ~PFLAG_OBSERVER );
    }
}

stock void CheckBotProps( int bot )
{
    if ( GetClientTeam( bot ) == TEAM_HUMAN )
    {
        ChangeClientTeam_Bot( bot, TEAM_SPEC );
        
        /*if ( !g_bRoundEnded )
        {
            KickClient( bot );
        }
        
        return;*/
    }
    
#define FSOLID_NOT_SOLID    4
    // For some reason the bot will float in the air.
    // Gets called before the spawn function is complete?
    SetEntProp( bot, Prop_Data, "m_takedamage", 0 );
    
    
    
    SetEntityRenderMode( bot, RENDER_NONE );
    SetEntityMoveType( bot, MOVETYPE_NOCLIP ); // Stops the fool from falling constantly.
    SetEntProp( bot, Prop_Send, "m_CollisionGroup", 1 ); // No collision with everything.
    SetEntProp( bot, Prop_Send, "m_usSolidFlags", GetEntProp( bot, Prop_Send, "m_usSolidFlags" ) | FSOLID_NOT_SOLID ); // No collision with everything.
    
    
    SetBotPhysicsFlags( bot );
}

stock bool FindTrapType( int ent, any target[TRAP_SIZE] )
{
    int len = g_hTrapTypes.Length;
    if ( !len ) return false;
    
    
    decl String:desc[MAX_TRAP_DESC];
    Zm_GetEntityTrapDescription( ent, desc, sizeof( desc ) );
    
    decl String:targetname[MAX_TARGETNAME];
    GetEntityName( ent, targetname, sizeof( targetname ) );
    
    
    decl data[TRAPTYPE_SIZE];
    decl String:findtargetname[MAX_TARGETNAME];
    decl Float:pos[3];
    
    bool match;
    
    Regex reg;
    
    
    for ( int i = 0; i < len; i++ )
    {
        g_hTrapTypes.GetArray( i, data );
        
        
        
        strcopy( findtargetname, sizeof( findtargetname ), view_as<char>( data[TRAPTYPE_FIND_TARGETNAME] ) );
        
        reg = view_as<Regex>( data[TRAPTYPE_FIND_REGEXHANDLE] );
        
        
        if ( findtargetname[0] != 0 && targetname[0] != 0 )
        {
            match = StrEqual( targetname, findtargetname, false );
        }
        else if ( reg != null )
        {
            int matches = reg.Match( desc );
            
//#if defined DEBUG_REGEX
//            PrintToServer( PREFIX..."Compared regex %x to \"%s\" with %i matches.", reg, desc, matches );
//#endif
            match = ( matches > 0 );
        }
        else
        {
            match = false;
        }
        
        if ( match )
        {
            target[TRAP_AOESIZE_SQ] = view_as<float>( data[TRAPTYPE_AOESIZE_SQ] );
            
            target[TRAP_VISSIZE_SQ] = view_as<float>( data[TRAPTYPE_VISSIZE_SQ] );
            
            target[TRAP_FLAGS] = data[TRAPTYPE_FLAGS];
            
            target[TRAP_GROUPID] = data[TRAPTYPE_GROUPID];
            
            
            target[TRAP_NEXTUSE] = view_as<int>( GetEngineTime() + view_as<float>( data[TRAPTYPE_WAIT_FROMSTART] ) );
            
            target[TRAP_DELAY] = data[TRAPTYPE_DELAY];
            target[TRAP_DELAY_MIN] = data[TRAPTYPE_DELAY_MIN];
            target[TRAP_DELAY_MAX] = data[TRAPTYPE_DELAY_MAX];
            target[TRAP_DELAY_MULTPERHUMAN] = data[TRAPTYPE_DELAY_MULTPERHUMAN];
            
            target[TRAP_TRACE_W_H] = data[TRAPTYPE_TRACE_W_H];
            target[TRAP_TRACE_LEN] = data[TRAPTYPE_TRACE_LEN];
            CopyArray( data[TRAPTYPE_TRACE_DIR], target[TRAP_TRACE_DIR], 3 );
            
            target[TRAP_CHANCE] = data[TRAPTYPE_CHANCE];
            target[TRAP_CHANCE_MULTPERHUMAN] = data[TRAPTYPE_CHANCE_MULTPERHUMAN];
            
            target[TRAP_MIN_RES] = data[TRAPTYPE_MIN_RES];
            target[TRAP_MAX_RES] = data[TRAPTYPE_MAX_RES];
            
            
            float dist = view_as<float>( data[TRAPTYPE_TRACE_CHECKPOSOFFSET] );
            float vec[3];
            
            
            GetEntityAbsOrigin( ent, pos );
            
            for ( int j = 0; j < 3; j++ )
            {
                pos[j] += view_as<float>( data[TRAPTYPE_CHECKPOSOFFSET + j] );
            }
            
            
            
            if ( dist != 0.0 )
            {
                vec = pos;
                
                for ( int j = 0; j < 3; j++ )
                {
                    vec[j] += view_as<float>( data[TRAPTYPE_TRACE_DIR + j] ) * dist;
                }
                
                TR_TraceRayFilter( pos, vec, CONTENTS_SOLID, RayType_EndPoint, TraceFilter_WorldOnly );
                
                TR_GetEndPosition( pos, null );
            }
            
            
            CopyArray( pos, target[TRAP_CHECKPOS], 3 );
            
#if defined DEBUG_TRAPTYPE
            PrintToServer( PREFIX..."Found type for (%i|%s) \"%s\" Check pos: [%.0f %.0f %.0f]", ent, targetname, desc, pos[0], pos[1], pos[2] );
#endif
            
            return true;
        }
    }
    
#if defined DEBUG_TRAPTYPE
    PrintToServer( PREFIX..."Couldn't find type! (%i|%s) | \"%s\"", ent, targetname, desc );
#endif
    
    return false;
}

stock bool TypeHasActivationMethod( any data[TRAPTYPE_SIZE] )
{
    if ( data[TRAPTYPE_FLAGS] & TRAPFLAG_TRACE_ACTIVATE ) return true;
    
    if ( view_as<float>( data[TRAPTYPE_AOESIZE_SQ] ) > 0.0 ) return true;
    if ( view_as<float>( data[TRAPTYPE_VISSIZE_SQ] ) > 0.0 ) return true;
    
    return false;
}



stock void ClearTrapTypes()
{
    // We must free our regex handles before purging the array.
    int len = g_hTrapTypes.Length;
    
    Regex reg;
    
    for ( int i = 0; i < len; i++ )
    {
        reg = view_as<Regex>( g_hTrapTypes.Get( i, TRAPTYPE_FIND_REGEXHANDLE ) );
        
        delete reg;
    }
    
    g_hTrapTypes.Clear();
}

stock void AddSpawns()
{
    decl data[SPAWN_SIZE];
    
    float pos[3];
    float temp[3];
    float curpos[3];
    
    float search_mins[3];
    float search_maxs[3];
    
    
    g_hSpawns.Clear();
    
    int ent = -1;
    while ( (ent = FindEntityByClassname( ent, "info_zombiespawn" )) != -1 )
    {
        data[SPAWN_ENTREF] = EntIndexToEntRef( ent );
        
        GetEntityAbsOrigin( ent, pos );
        CopyArray( pos, data[SPAWN_POS], 3 );
        
        
        
        // Figure out our room size.
        temp = pos; temp[0] += ROOMSIZE_MAX;
        TR_TraceRayFilter( pos, temp, ROOM_MASK, RayType_EndPoint, TraceFilter_WorldOnly );
        TR_GetEndPosition( temp );
        search_maxs[0] = temp[0];
        
        temp = pos; temp[0] -= ROOMSIZE_MAX;
        TR_TraceRayFilter( pos, temp, ROOM_MASK, RayType_EndPoint, TraceFilter_WorldOnly );
        TR_GetEndPosition( temp );
        search_mins[0] = temp[0];
        
        temp = pos; temp[1] += ROOMSIZE_MAX;
        TR_TraceRayFilter( pos, temp, ROOM_MASK, RayType_EndPoint, TraceFilter_WorldOnly );
        TR_GetEndPosition( temp );
        search_maxs[1] = temp[1];
        
        temp = pos; temp[1] -= ROOMSIZE_MAX;
        TR_TraceRayFilter( pos, temp, ROOM_MASK, RayType_EndPoint, TraceFilter_WorldOnly );
        TR_GetEndPosition( temp );
        search_mins[1] = temp[1];
        
        // We now have our room mins and maxs.
        
        // Get our max depth.
        temp = pos; temp[2] -= ROOMSIZE_MAX;
        TR_TraceRayFilter( pos, temp, ROOM_MASK, RayType_EndPoint, TraceFilter_WorldOnly );
        TR_GetEndPosition( temp );
        
        float max_z = temp[2] - 72.0;
        
        
        search_mins[2] = pos[2];
        search_maxs[2] = pos[2];
        
        
        CorrectMinsMaxs( search_mins, search_maxs );
        
        
        // Now check how many valid spots the room has.
        int nValidSpots = 0;
        
        
        curpos = search_mins;
        while ( curpos[1] < search_maxs[1] )
        {
            // Must see spawn.
            if ( !TR_PointOutsideWorld( curpos ) && CanSee( pos, curpos ) )
            {
                
#define ANG_DOWN            view_as<float>( { 90.0, 0.0, 0.0 } )

                TR_TraceRay( curpos, ANG_DOWN, ROOM_MASK, RayType_Infinite );
                TR_GetEndPosition( temp );
                
                if ( temp[2] >= max_z )
                {
                    ++nValidSpots;
                }
            }
            
            
            curpos[0] += ROOM_CHECKDIST;
            
            if ( curpos[0] > search_maxs[0] )
            {
                curpos[0] = search_mins[0];
                curpos[1] += ROOM_CHECKDIST;
            }
        }
        
        
        if ( nValidSpots >= SPOTS_HUGE )
        {
            data[SPAWN_ROOMSIZE] = ROOMSIZE_HUGE;
        }
        else if ( nValidSpots >= SPOTS_BIG )
        {
            data[SPAWN_ROOMSIZE] = ROOMSIZE_BIG;
        }
        else if ( nValidSpots >= SPOTS_MEDIUM )
        {
            data[SPAWN_ROOMSIZE] = ROOMSIZE_MEDIUM;
        }
        else
        {
            data[SPAWN_ROOMSIZE] = ROOMSIZE_SMALL;
        }
        
#if defined DEBUG_SPAWNROOMSIZE
        PrintToServer( PREFIX..."Found zombie spawn %i with %i valid spots! (room size: %i)", ent, nValidSpots, data[SPAWN_ROOMSIZE] );
#endif
        
        
        g_hSpawns.PushArray( data );
    }
    
    g_iNumSpawns = g_hSpawns.Length;
}

stock void AddTraps()
{
    decl data[TRAP_SIZE];
    decl Float:pos[3];
    
    
    g_hTraps.Clear();
    
    
    int ent = -1;
    while ( (ent = FindEntityByClassname( ent, "info_manipulate" )) != -1 )
    {
        data[TRAP_ENTREF] = EntIndexToEntRef( ent );
        
        
        if ( !FindTrapType( ent, data ) )
        {
            data[TRAP_CHANCE] = view_as<int>( DEF_CHANCE );
            data[TRAP_CHANCE_MULTPERHUMAN] = view_as<int>( DEF_CHANCE_MULTPERHUMAN );
            
            data[TRAP_AOESIZE_SQ] = view_as<int>( DEF_NONE_AOESIZE );
            data[TRAP_VISSIZE_SQ] = view_as<int>( DEF_NONE_VISSIZE );
            
            
            GetEntityAbsOrigin( ent, pos );
            CopyArray( pos, data[TRAP_CHECKPOS], 3 );
            
            
            data[TRAP_NEXTUSE] = 0;
            
            data[TRAP_DELAY] = view_as<int>( DEF_DELAY );
            data[TRAP_DELAY_MIN] = view_as<int>( DEF_DELAY_MIN );
            data[TRAP_DELAY_MAX] = view_as<int>( DEF_DELAY_MAX );
            data[TRAP_DELAY_MULTPERHUMAN] = view_as<int>( DEF_DELAY_MULTPERHUMAN );
            
            data[TRAP_FLAGS] = 0;
            data[TRAP_GROUPID] = DEF_GROUPID;
            
            data[TRAP_MIN_RES] = DEF_MIN_RES;
            data[TRAP_MAX_RES] = DEF_MAX_RES;
            data[TRAP_TRACE_LEN] = 0;
        }
        
        g_hTraps.PushArray( data );
    }
    
    g_iNumTraps = g_hTraps.Length;
}

stock void FindEnts()
{
    AddSpawns();
    AddTraps();
    
    
#if defined DEBUG
    PrintToServer( PREFIX..."Found %i spawns and %i traps", g_iNumSpawns, g_iNumTraps );
#endif

    if ( !g_iNumSpawns && !g_iNumTraps )
        PrintToServer( PREFIX..."No spawns or traps were found for AI!!" );
}

stock int GetFakePlayer( int startindex = 1, int ignore = -1 )
{
    for ( int i = startindex; i <= MaxClients; i++ )
    {
        if ( IsClientInGame( i ) && IsFakeClient( i ) && i != ignore )
            return i;
    }
    
    return -1;
}

stock void FindBot()
{
    int bot = GetFakePlayer();
    
    if ( bot != -1 )
    {
        g_iBot = bot;
        
        CheckBotProps( bot );
    }
    else
    {
        AddBot();
    }
}

stock bool TypeFitsFlags( int type, int flags )
{
    return ( type != ZTYPE_INVALID && ( flags == 0 || (flags & (1 << type)) ) );
}

stock bool SpawnZombies( int ent, const any data[SPAWN_SIZE], float flDistMult )
{
    int flags = GetEntProp( ent, Prop_Data, "m_iZombieFlags" );
    
    // Check all zombie types.
    int ztypes[NUM_ZTYPES];
    ztypes[ZTYPE_SHAMBLER] = ZFLAG_SHAMBLER;
    ztypes[ZTYPE_BANSHEE] = ZFLAG_BANSHEE;
    ztypes[ZTYPE_HULK] = ZFLAG_HULK;
    ztypes[ZTYPE_DRIFTER] = ZFLAG_DRIFTER;
    ztypes[ZTYPE_IMMOLATOR] = ZFLAG_IMMOLATOR;
    
    for ( int type = 0; type < NUM_ZTYPES; type++ )
    {
        if (!TypeFitsFlags( type, ztypes[type] )
        ||  !HasEnoughPoolToSpawnType( type )
        ||  !HasEnoughResToSpawnType( type )
        ||  GetZombieTypeNum( type ) >= GetMaxZombiesOfType( type ))
        {
            ztypes[type] = 0;
        }
    }
    
    
    int nTypes = 0;
    
    for ( int type = 0; type < NUM_ZTYPES; type++ )
    {
        if ( ztypes[type] != 0 ) ++nTypes;
    }
    
    // We cannot spawn any zombies! :(
    if ( !nTypes ) return false;
    
    
    int[] randomtypes = new int[nTypes];
    
    int i = 0;
    for ( int type = 0; type < NUM_ZTYPES; type++ )
    {
        if ( ztypes[type] )
        {
            randomtypes[i++] = type;
            
            ztypes[type] = 0;
            
            
            if ( i >= nTypes ) break;
        }
    }
    
    int type = randomtypes[ GetRandomInt( 0, nTypes - 1 ) ];
    
    
    
    // What is our next zombie spawn time?
    decl Float:flAdd;
    
    // Difficulty
    switch ( g_iDifficulty )
    {
        case DIFFICULTY_MED :       flAdd = 1.2;
        case DIFFICULTY_EASY :      flAdd = 2.4;
        case DIFFICULTY_SUPEREASY : flAdd = 4.0;
        default :                   flAdd = 0.5;
    }
    
    // Multiply by type.
    flAdd *= g_flSpawnTimeMultiplier[type];
    
    // Multiply by room size.
    switch ( data[SPAWN_ROOMSIZE] )
    {
        case ROOMSIZE_SMALL :   flAdd *= 2.0;
        case ROOMSIZE_MEDIUM :  flAdd *= 1.4;
        case ROOMSIZE_BIG :     flAdd *= 1.2;
    }
    
    
    g_flNextSpawn = g_flCurTime + flAdd * flDistMult;
    
    
#if defined DEBUG_AISPAWNING
    PrintToServer( PREFIX..."Spawning zombie %s, next spawn in %.1fs (DistMult: %.1f | Dif: %i | RoomSize: %i | Flags: %i)!",
        g_szZTypes[type],
        g_flNextSpawn - g_flCurTime,
        flDistMult,
        g_iDifficulty,
        data[SPAWN_ROOMSIZE],
        flags );
#endif
    
    SetSelectedZombieSpawn( g_iBot, ent, flags );
    FakeClientCommand( g_iBot, "summon %s %i", g_szZTypes[type], ent );
    
    return true;
}

stock void HandleDifficulty()
{
    // Figure out our difficulty.
    
    if ( g_flCurTime < g_flNextDifficultyHandle ) return;
    
    
    
    float total;
    
    float wep_add;
    float hp_modf;
    
    int ent;
    
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( !IsClientInGame( i ) ) continue;
        
        if ( !Zm_IsHumanAlive( i ) ) continue;
        
        
        hp_modf = GetClientHealth( i ) / 60.0;
        
        wep_add = 0.0;
        
        
        
        ent = GetPlayerWeaponSlot( i, SLOT_PISTOL );
        if ( ent != -1 )
        {
            decl ammotype;
            decl Float:ammo_modf;
            
            if ( Zm_GetWeaponAmmoType( ent, ammotype ) )
            {
                int totalammo = GetEntProp( ent, Prop_Data, "m_iClip1" ) + GetClientAmmo( i, ammotype );
                
                ammo_modf = totalammo / float(GetAmmoTypeMaxCountTotal( ammotype ));
                
                if ( ammo_modf > 1.0 ) ammo_modf = 1.0;
                else if ( ammo_modf < 0.0 ) ammo_modf = 0.0;
            }
            
            
            wep_add += ammo_modf * 10.0 + ammo_modf * 10.0;
        }
        
        ent = GetPlayerWeaponSlot( i, SLOT_PRIMARY );
        if ( ent != -1 )
        {
            decl ammotype;
            decl Float:ammo_modf;
            
            if ( Zm_GetWeaponAmmoType( ent, ammotype ) )
            {
                int totalammo = GetEntProp( ent, Prop_Data, "m_iClip1" ) + GetClientAmmo( i, ammotype );
                
                ammo_modf = totalammo / float(GetAmmoTypeMaxCountTotal( ammotype ));
                
                if ( ammo_modf > 1.0 ) ammo_modf = 1.0;
                else if ( ammo_modf < 0.0 ) ammo_modf = 0.0;
            }
            
            
            wep_add += ammo_modf * 30.0 + ammo_modf * 10.0;
        }
        
        
        if ( GetPlayerWeaponSlot( i, SLOT_MELEE ) != -1 )
        {
            wep_add += 10.0;
        }
        
        if ( GetPlayerWeaponSlot( i, SLOT_MOLOTOV ) != -1 )
        {
            wep_add += 5.0;
        }
        
        
        total += hp_modf * 10.0 + wep_add;
    }
    
    if ( total >= DIF_HARD )
    {
        g_iDifficulty = DIFFICULTY_HARD;
    }
    else if ( total >= DIF_MED )
    {
        g_iDifficulty = DIFFICULTY_MED;
    }
    else if ( total >= DIF_EASY )
    {
        g_iDifficulty = DIFFICULTY_EASY;
    }
    else
    {
        g_iDifficulty = DIFFICULTY_SUPEREASY;
    }
    
    
    g_flNextDifficultyHandle = g_flCurTime + 5.0;
}

stock void HandleZombies()
{
    // Move/delete zombies.
    
    if ( g_flCurTime < g_flNextZombieHandle ) return;
    
    
    int ent = -1;
    
    
    decl Float:vecPos[3];
    decl Float:vecTargetPos[3];
    decl Float:flDist;
    decl client;
    
    decl String:szName[3];
    
    
    while ( (ent = FindEntityByClassname( ent, "npc_*" )) != -1 )
    {
        if ( !(GetEntityFlags( ent ) & FL_NPC) ) continue;
        
        if ( !IsValidEntity( ent ) ) continue;
        
        if ( GetEntProp( ent, Prop_Data, "m_iHealth" ) <= 0 ) continue;
        
        
#if defined DEBUG_HANDLEZOMBIES
        PrintToServer( PREFIX..."Found valid zombie %i!", ent );
#endif
        
        GetEntityAbsOrigin( ent, vecPos );
        
        // Lift it off the ground a bit for traces.
        vecPos[2] += 2.0;
        
        
        client = ClosestPlayer( vecPos, flDist );
        
        if ( !client )
        {
            continue;
        }
        
#if defined DEBUG_HANDLEZOMBIES
            PrintToServer( PREFIX..."Nearest player: %i", client );
#endif
        
        // Too far away from any players, just delete him!
        if ( flDist > g_flZombieDeleteDistSq && !CanSeeAnyPlayerInDistSq( vecPos, flDist * flDist ) )
        {
            // Ignore "special" zombies with a name, made by the map.
            GetEntityName( ent, szName, sizeof( szName ) );
            
            if ( szName[0] != '\0' && szName[0] != '_' && szName[1] != '_' )
            {
#if defined DEBUG_HANDLEZOMBIES
                char szFull[64];
                GetEntityName( ent, szFull, sizeof( szFull ) );
                
                PrintToServer( PREFIX..."Special zombie detected! Can't delete. (Name: %s)", szFull );
#endif
                continue; 
            }
            
            
#if defined DEBUG_HANDLEZOMBIES
            PrintToServer( PREFIX..."Deleting %i for being %.1f units far (%.1 max)!", ent, SquareRoot( flDist ), SquareRoot( g_flZombieDeleteDistSq ) );
#endif
            
            KillZombie( ent, GetEntProp( ent, Prop_Data, "m_iHealth" ) * 2 );
            
            continue;
        }
        
#if defined DEBUG_HANDLEZOMBIES
        PrintToServer( PREFIX..."Zombie state: %i | Moving: %i",
            GetZombieState( ent ),
            IsZombieMoving( ent ) );
#endif
        
        
        // We're not close to anybody, not moving anywhere... Move to the closest player!
        
        // There are STILL some mistakes in this.
        // Sometimes the NPC can be idling and not moving while the player is right in front of it, etc.
        if ( flDist > MIN_ZOMBIEMOVE_DIST_SQ && GetZombieState( ent ) == NPC_STATE_IDLE && !IsZombieMoving( ent ) )
        {
#if defined DEBUG_HANDLEZOMBIES
            PrintToServer( PREFIX..."Moving %i towards player %i!", ent, client );
#endif
            
            GetClientAbsOrigin( client, vecTargetPos );
            
            //decl String:szClass[32];
            //GetEntityClassname( ent, szClass, sizeof( szClass ) );
            //PrintToServer( PREFIX..."Class: %s (on fire: %i)", szClass, GetEntityFlags( ent ) & FL_ONFIRE ? 1 : 0 );
            
            UnselectAllZombies( g_iBot );
            SelectZombiesInSphere( g_iBot, vecPos ); // 256 unit sphere.
            MoveZombies( g_iBot, vecTargetPos );
            
            break;
        }
    }
    
    
    g_flNextZombieHandle = g_flCurTime + 2.0;
}

stock bool ShouldSpawnZombies()
{
    if ( g_nPopCount >= g_ConVar_ZombieMax.IntValue ) return false;
    
    if ( g_flNextSpawn >= g_flCurTime ) return false;
    
    if ( g_nResources < 10 ) return false;
    
    if ( g_nHumans <= 0 ) return false;
    
    // Force spawning if nothing has happened (zombie/player hurt)
    if ( g_flCurTime >= g_flNextForceAct )
    {
#if defined DEBUG_ZOMBIESPAWNING
        PrintToServer( PREFIX..."Nobody has gotten damaged for %.1f seconds, ignoring difficulty max popcount.", g_ConVar_InactDifChange.FloatValue );
#endif
        
        return true;
    }
    
    switch ( g_iDifficulty )
    {
        case DIFFICULTY_MED : if ( g_nPopCount > 40 ) return false;
        case DIFFICULTY_EASY : if ( g_nPopCount > 28 ) return false;
        case DIFFICULTY_SUPEREASY : if ( g_nPopCount > 20 ) return false;
    }
    
    return true;
}

stock bool HasEnoughResToSpawnType( int type )
{
    switch ( type )
    {
        case ZTYPE_SHAMBLER :   return ( g_nResources >= g_ConVar_Cost_Shambler.IntValue );
        case ZTYPE_BANSHEE :    return ( g_nResources >= g_ConVar_Cost_Banshee.IntValue );
        case ZTYPE_HULK :       return ( g_nResources >= g_ConVar_Cost_Hulk.IntValue );
        case ZTYPE_DRIFTER :    return ( g_nResources >= g_ConVar_Cost_Drifter.IntValue );
        case ZTYPE_IMMOLATOR :  return ( g_nResources >= g_ConVar_Cost_Immolator.IntValue );
    }
    
    return true;
}

stock bool HasEnoughPoolToSpawnType( int type )
{
    return ( (g_nPopCount + GetTypePopCost( type )) <= g_ConVar_ZombieMax.IntValue );
}

stock int GetTypePopCost( int type )
{
    switch ( type )
    {
        case ZTYPE_SHAMBLER :   return g_ConVar_ZombiePopCost_Shambler.IntValue ;
        case ZTYPE_BANSHEE :    return g_ConVar_ZombiePopCost_Banshee.IntValue;
        case ZTYPE_HULK :       return g_ConVar_ZombiePopCost_Hulk.IntValue;
        case ZTYPE_DRIFTER :    return g_ConVar_ZombiePopCost_Drifter.IntValue;
        case ZTYPE_IMMOLATOR :  return g_ConVar_ZombiePopCost_Immolator.IntValue;
    }
    
    return 1337;
}

/*stock void CheckValidPopCount()
{
    if ( g_nHumans <= 0 ) return;
    
    
    // Check if our popcount is bugged.
    // Could be something to do with our point_hurt?
    int realpop = GetRealPopCount();
    
    if ( g_nPopCount != realpop )
    {
#if defined DEBUG
        PrintToServer( PREFIX..."AI had bugged popcount! Resetting back to %i!", realpop );
#endif

        Zm_SetClientPopCount( g_iBot, realpop );
    }
}

stock int GetRealPopCount()
{
    // This still doesn't return the correct popcount. Needs more testing...
    decl String:szClass[6];
    int pop = 0;
    
    int ent = -1;
    while ( (ent = FindEntityByClassname( ent, "npc_*" )) != -1 )
    {
        if ( !(GetEntityFlags( ent ) & FL_NPC) ) continue;
        
        
        GetEntityClassname( ent, szClass, sizeof( szClass ) );
        
#if defined DEBUG
        PrintToServer( PREFIX..."Found valid zombie (%c) with %i hp", szClass[4], GetEntProp( ent, Prop_Data, "m_iHealth" ) );
#endif
        
        switch ( GetZombieType( szClass ) )
        {
            case ZTYPE_SHAMBLER :   pop += g_ConVar_ZombiePopCost_Shambler.IntValue;
            case ZTYPE_BANSHEE :    pop += g_ConVar_ZombiePopCost_Banshee.IntValue;
            case ZTYPE_HULK :       pop += g_ConVar_ZombiePopCost_Hulk.IntValue;
            case ZTYPE_DRIFTER :    pop += g_ConVar_ZombiePopCost_Drifter.IntValue;
            case ZTYPE_IMMOLATOR :  pop += g_ConVar_ZombiePopCost_Immolator.IntValue;
        }
    }
    
    return pop;
}*/

stock bool ShouldUseTraps()
{
    if ( g_flNextTrap >= g_flCurTime ) return false;
    
    if ( g_nHumans <= 0 ) return false;
    
    return true;
}

stock void CheckZombieSpawns( int ignore = -1 )
{
#if defined DEBUG_ZOMBIESPAWNING
    PrintToServer( PREFIX..."CheckZombieSpawns(%i)", ignore );
#endif
    // Loop through all spawns and check which one has the most players near it.
    // Will always favor spawns that the player can actually see instead of just distance from spawn.
    static int data[SPAWN_SIZE];
    
    
    decl Float:vecEntPos[3];
    decl Float:vecPlyPos[3];
    
    
    int best_index = -1;
    int best_ent = -1;
    int best_num_cansee = 0;
    int best_num_inrange = 0;
    int best_closest_player = 0;
    
    
    decl Float:best_dist;
    
    decl client;
    
    decl num_cansee;
    decl num_inrange;
    decl Float:cur_dist;
    decl Float:cur_dist_smallest;
    
    decl ent;
    
    
    for ( int i = 0; i < g_iNumSpawns; i++ )
    {
        if ( i <= ignore )
        {
            continue;
        }
        
        g_hSpawns.GetArray( i, data );
        
        
        // Activeable died, just flag it as killed and ignore it for the rest of the round.
        if ( (ent = EntRefToEntIndex( data[SPAWN_ENTREF] )) < 1 )
        {
//#if defined DEBUG_ZOMBIESPAWNS
//          PrintToServer( PREFIX..."Invalid ent ref with spawn!" );
//#endif
            continue;
        }
        
        
        // We're still not active. Don't spawn anything.
        if ( !Zm_IsEntityActive( ent ) ) continue;
        
        
        CopyArray( data[SPAWN_POS], vecEntPos, 3 );
        
        
#if defined DEBUG_ZOMBIESPAWNING
        PrintToServer( PREFIX..."Valid spawn %i [%.0f %.0f %.0f]", i, vecEntPos[0], vecEntPos[1], vecEntPos[2] );
#endif

        
        num_cansee = 0;
        num_inrange = 0;
        cur_dist_smallest = 0.0;
        
        for ( client = 1; client <= MaxClients; client++ )
        {
            if ( !IsClientInGame( client ) ) continue;
            
            if ( !Zm_IsHumanAlive( client ) ) continue;
            
            
            GetClientAbsOrigin( client, vecPlyPos );
            vecPlyPos[2] += (GetEntityFlags( client ) & FL_DUCKING) ? HULL_Z_MAX_DUCKED : HULL_Z_MAX;
            
            cur_dist = GetVectorDistance( vecEntPos, vecPlyPos, true );
            
            // Can see and under the deletion distance.
            if ( CanSee( vecEntPos, vecPlyPos ) && cur_dist < (g_flZombieDeleteDistSq * 0.75) )
            {
                num_cansee++;
            }
            // Otherwise, check if generally close enough.
            else if ( cur_dist < g_flZombieSpawnDistSq )
            {
                if ( cur_dist < cur_dist_smallest )
                {
                    cur_dist_smallest = cur_dist;
                    best_closest_player = client;
                }
                
                num_inrange++;
            }
        }
        
        // Alright, we counted how many can see or are in range. Let's compare that to the other ones.
        if ( num_cansee > best_num_cansee || ( num_inrange > best_num_inrange && cur_dist_smallest < best_dist ) )
        {
            // This spawn is better!
            best_index = i;
            best_ent = ent;
            best_num_cansee = num_cansee;
            best_num_inrange = num_inrange;
            best_dist = cur_dist_smallest;
        }
    }
    
    // We picked a spawn!
    if ( best_index != -1 )
    {
#if defined DEBUG_ZOMBIESPAWNING
        PrintToServer( PREFIX..."Chose best index %i", best_index );
        
        if ( best_closest_player )
        {
            GetClientAbsOrigin( best_closest_player, vecPlyPos );
            PrintToServer( PREFIX..."%i player pos: {%.0f, %.0f, %.0f}", best_closest_player, vecPlyPos[0], vecPlyPos[1], vecPlyPos[2] );
        }
#endif

        g_hSpawns.GetArray( best_index, data );
        
        // Make distance multiplier from closest player.
        // If no player found, just use best modifier.
        if ( !best_closest_player )
        {
            cur_dist = SPAWN_DIST_MODF_SQ;
        }
        else
        {
            CopyArray( data[SPAWN_POS], vecEntPos, 3 );
            
            GetClientAbsOrigin( best_closest_player, vecPlyPos );
            cur_dist = GetVectorDistance( vecEntPos, vecPlyPos, true );
        }
        
        cur_dist /= SPAWN_DIST_MODF_SQ;
        
        if ( cur_dist < 0.0 ) cur_dist = 0.0;
        else if ( cur_dist > 0.75 ) cur_dist = 0.75;
        
        cur_dist = 1.0 - cur_dist;
        
        
        if ( !SpawnZombies( best_ent, data, cur_dist ) )
        {
            // Try once more, this time ignore the one we tried.
            CheckZombieSpawns( best_index );
        }
    }
}

stock bool CanUseTrap( const any data[TRAP_SIZE] )
{
    decl ent;
    if ( (ent = EntRefToEntIndex( data[TRAP_ENTREF] )) < 1 ) return false;
    
    if ( !Zm_IsEntityActive( ent ) ) return false;
    
    if ( view_as<float>( data[TRAP_NEXTUSE] ) > g_flCurTime ) return false;
    
    if ( data[TRAP_FLAGS] & TRAPFLAG_ISWAITINGTRIGGER ) return false;
    
    if ( Zm_GetEntityCost( ent ) > g_nResources ) return false;
    
    if ( data[TRAP_MIN_RES] > 0 && g_nResources < data[TRAP_MIN_RES] ) return false;
    if ( data[TRAP_MAX_RES] > 0 && g_nResources > data[TRAP_MAX_RES] ) return false;
    
    return true;
}

stock void CheckTraps()
{
    // Loop through all traps.
    // Type checks are done in ShouldUseTrap. (aoe, traces)
    static int data[TRAP_SIZE];
    
    decl Float:pos[3];
    decl ent;
    
    
    for ( int i = 0; i < g_iNumTraps; i++ )
    {
        g_hTraps.GetArray( i, data );
        
        if ( !CanUseTrap( data ) ) continue;
        
        
        ent = EntRefToEntIndex( data[TRAP_ENTREF] );
        
        
        CopyArray( data[TRAP_CHECKPOS], pos, 3 );
        
        if ( ShouldUseTrap( i, ent, data, pos ) )
        {
            if ( data[TRAP_GROUPID] >= 0 )
            {
                // These traps are already checked.
                int index = ChooseFromGroup( data[TRAP_GROUPID], i );
                
                if ( index != -1 )
                {
                    g_hTraps.GetArray( index, data );
                    
                    ent = EntRefToEntIndex( data[TRAP_ENTREF] );
                    
                    CopyArray( data[TRAP_CHECKPOS], pos, 3 );
                    
                    if ( ShouldUseTrap( index, ent, data, pos ) )
                    {
                        UseTrap( index, data, ent );
                        break;
                    }
                }
                else
                {
                    UseTrap( index, data, ent );
                    break;
                }
            }
            else
            {
                UseTrap( i, data, ent );
                break;
            }
        }
        
        if ( data[TRAP_FLAGS] & TRAPFLAG_CANUSETRIGGER && Zm_GetEntityTrapCost( ent ) <= g_nResources )
        {
#if defined DEBUG_TRAPS
            PrintToServer( PREFIX..."Creating a trigger! (%i)", ent );
#endif

            decl Float:end[3];
            end = pos;
            end[2] -= TRAP_MIN_TRIGGER_DIST;
            
            TR_TraceRayFilter( pos, end, CONTENTS_SOLID, RayType_EndPoint, TraceFilter_WorldOnly );
            
            TR_GetEndPosition( end, null );
            
            CreateTrapTrigger( g_iBot, ent, Zm_GetEntityCost( ent ), Zm_GetEntityTrapCost( ent ), end );
            
            
            // Set it as killed.
            if ( Zm_GetEntityRemoveOnTrigger( ent ) )
                g_hTraps.Set( i, INVALID_ENT_REFERENCE, TRAP_ENTREF );
            
            g_hTraps.Set( i, data[TRAP_FLAGS] | TRAPFLAG_ISWAITINGTRIGGER, TRAP_FLAGS );
            
            break;
        }
    }
}

stock void UseTrap( int index, const any data[TRAP_SIZE], int ent )
{
#if defined DEBUG_TRAPS
    PrintToServer( PREFIX..."Activating trap! (%i)", ent );
#endif
    
    ActivateTrap( g_iBot, ent, Zm_GetEntityCost( ent ) );

    // Some wait time between using the same trap.
    
    float delay = view_as<float>( data[TRAP_DELAY] );
    float mindelay = view_as<float>( data[TRAP_DELAY_MIN] );
    float maxdelay = view_as<float>( data[TRAP_DELAY_MAX] );
    
    switch ( g_iDifficulty )
    {
        case DIFFICULTY_MED : delay *= 1.25;
        case DIFFICULTY_EASY : delay *= 1.75;
        case DIFFICULTY_SUPEREASY : delay *= 3.0;
    }
    
    
    delay = MultPerHuman( delay, view_as<float>( data[TRAP_DELAY_MULTPERHUMAN] ) );
    
    
#define MIN_DELAY       0.001
    
    if ( maxdelay > 0.0 && delay > maxdelay ) delay = maxdelay;
    else if ( mindelay > 0.0 && delay < mindelay ) delay = mindelay;
    
    
    if ( delay < MIN_DELAY ) delay = MIN_DELAY;
    
    
    
    g_hTraps.Set( index, g_flCurTime + delay, TRAP_NEXTUSE );
    
    
    
    // Always delay the next trap. If the map logic disables other traps when using this trap, we will accidentally use them all... (aka zm_bastard elevator traps)
    float nextdelay = 2.0;
    
    switch ( g_iDifficulty )
    {
        case DIFFICULTY_EASY :
        {
            nextdelay += 3.0;
        }
        case DIFFICULTY_SUPEREASY :
        {
            nextdelay += 6.0;
        }
    }
    
    g_flNextTrap = g_flCurTime + nextdelay;
}

stock bool CountChances( const any data[TRAP_SIZE] )
{
    float chance = view_as<float>( data[TRAP_CHANCE] );
    
    if ( chance >= 1.0 ) return true;
    if ( chance <= 0.0 ) return false;
    
    
    chance = MultPerHuman( chance, view_as<float>( data[TRAP_CHANCE_MULTPERHUMAN] ) );
    
    
    int c = RoundFloat( chance * 100.0 );
    
    return ( GetRandomInt( 1, 100 ) >= c );
}

stock float MultPerHuman( float value, float mult )
{
    if ( mult == 1.0 ) return value;
    
    if ( mult == 0.0 ) return 0.0;
    
    
    for ( int i = 0; i < g_nHumans - 1; i++ )
    {
        value *= mult;
    }

    return value;
}

stock bool ShouldUseTrap( int index, int ent, const any data[TRAP_SIZE], const float entpos[3] )
{
    if ( !CountChances( data ) )
    {
        g_hTraps.Set( index, INVALID_ENT_REFERENCE, TRAP_ENTREF );
        return false;
    }
    
    if ( data[TRAP_FLAGS] & TRAPFLAG_ALWAYS ) return true;
    
    if ( data[TRAP_FLAGS] & TRAPFLAG_TRACE_ACTIVATE )
    {
        decl Float:temp[3];
        CopyArray( data[TRAP_TRACE_DIR], temp, 3 );
        
        return DoSeePlayer(
            entpos,
            temp,
            view_as<float>( data[TRAP_TRACE_LEN] ),
            view_as<float>( data[TRAP_TRACE_W_H] ) );
    }
    
    /*if ( data[TRAP_FLAGS] & TRAPFLAG_TRACE_SIDES )
    {
        return DoSeePlayer_Sides( entpos, data[TRAP_TRACE_LEN] );
    }*/
    
    
    if (view_as<float>( data[TRAP_AOESIZE_SQ] ) > 0.0
    &&  DistanceToClosestPlayerSq( entpos ) <= view_as<float>( data[TRAP_AOESIZE_SQ] ) ) return true;
    
    
    if (view_as<float>( data[TRAP_VISSIZE_SQ] ) > 0.0
    &&  CanSeeAnyPlayerInDistSq( entpos, view_as<float>( data[TRAP_VISSIZE_SQ] ) ) )
    {
        return true;
    }
    
    return false;
}

stock int ChooseFromGroup( int groupid, int original )
{
    int len = g_hTraps.Length;
    if ( !len ) return -1;
    
    
    decl i;
    int num_elem = 1;
    
    
    for ( i = 0; i < len; i++ )
    {
        if ( g_hTraps.Get( i, TRAP_GROUPID ) == groupid && i != original )
        {
            ++num_elem;
        }
    }
    
    if ( num_elem <= 1 ) return -1;
    
    
    int cur = 1;
    int[] elem = new int[num_elem];
    elem[0] = original;
    
    decl data[TRAP_SIZE];
    
    for ( i = 0; i < len; i++ )
    {
        if ( g_hTraps.Get( i, TRAP_GROUPID ) == groupid && i != original )
        {
            g_hTraps.GetArray( i, data );
            
            if ( !CanUseTrap( data ) ) continue;
            
            
            elem[cur++] = i;
        }
    }
    
    int c = GetRandomInt( 0, cur - 1 );
    
#if defined DEBUG_TRAPS
    PrintToServer( PREFIX..."Choosing randomly from %i traps! (%i | %i)", cur, c, elem[c] );
#endif
    
    return elem[c];
}

stock void KillZombie( int target, int damage )
{
    int ent = EntRefToEntIndex( g_iHurt );
    
    if ( ent < 1 )
    {
        ent = CreateEntityByName( "point_hurt" );
        
        if ( ent < 1 )
        {
            LogError( PREFIX..."Failed creating a new point_hurt to delete zombies!" );
            return;
        }
        
        DispatchSpawn( ent );
        
        SetEntProp( ent, Prop_Data, "m_bitsDamageType", DMG_ALWAYSGIB );
        
        g_iHurt = EntIndexToEntRef( ent );
    }
    
    if ( !AcceptEntityInput( ent, "TurnOn" ) )
    {
#if defined DEBUG_HURT
        PrintToServer( PREFIX..."Couldn't turn on ent %i!", ent );
#endif
    }
    
    SetEntProp( ent, Prop_Data, "m_nDamage", damage );
    
    static char szName[24];
    GetEntityName( target, szName, sizeof( szName ) );
    
    if ( szName[0] == '\0' )
    {
        FormatEx( szName, sizeof( szName ), "___%i", target );
        DispatchKeyValue( target, "targetname", szName );
    }
    
    DispatchKeyValue( ent, "DamageTarget", szName );
    //DispatchKeyValue( ent, "DamageTarget", "!activator" );
    
    if ( !AcceptEntityInput( ent, "Hurt", target ) )
    {
#if defined DEBUG_HURT
        PrintToServer( PREFIX..."Couldn't hurt zombie %i!", target );
#endif
    }
    
    if ( !AcceptEntityInput( ent, "TurnOff" ) )
    {
#if defined DEBUG_HURT
        PrintToServer( PREFIX..."Couldn't turn off ent %i!", ent );
#endif
    }
}

stock int GetZombieTypeNum( int type )
{
    int num;
    int ent = -1;
    
    while ( (ent = FindEntityByClassname( ent, g_szZTypes[type] )) != -1 )
    {
        if ( !(GetEntityFlags( ent ) & FL_NPC) ) continue;
        
        num++;
    }
    
    return num;
}

stock int GetMaxZombiesOfType( int type )
{
    switch ( g_iDifficulty )
    {
        case DIFFICULTY_HARD :
        {
            switch ( type )
            {
                case ZTYPE_BANSHEE : return 7;
                case ZTYPE_HULK : return 8;
                case ZTYPE_DRIFTER : return 16;
                case ZTYPE_IMMOLATOR : return 6;
            }
        }
        case DIFFICULTY_MED :
        {
            switch ( type )
            {
                case ZTYPE_BANSHEE : return 5;
                case ZTYPE_HULK : return 4;
                case ZTYPE_DRIFTER : return 10;
                case ZTYPE_IMMOLATOR : return 3;
            }
        }
        case DIFFICULTY_EASY :
        {
            switch ( type )
            {
                case ZTYPE_BANSHEE : return 3;
                case ZTYPE_HULK : return 2;
                case ZTYPE_DRIFTER : return 7;
                case ZTYPE_IMMOLATOR : return 2;
            }
        }
        case DIFFICULTY_SUPEREASY :
        {
            switch ( type )
            {
                case ZTYPE_BANSHEE : return 2;
                case ZTYPE_HULK : return 2;
                case ZTYPE_DRIFTER : return 5;
                case ZTYPE_IMMOLATOR : return 1;
            }
        }
    }
    
    return g_ConVar_ZombieMax.IntValue;
}

stock void AddBot()
{
    if ( !g_bEnabled )
    {
        return;
    }
    
    // Spawn the bot.
    // Has to have sv_cheats set to 1!
    int flags;
    
    if ( (flags = GetCommandFlags( "bot_add" )) == INVALID_FCVAR_FLAGS )
    {
        SetFailState( "Couldn't find command flags for command bot_add!" );
    }
    
    
    if ( flags & FCVAR_CHEAT ) SetCommandFlags( "bot_add", flags & ~FCVAR_CHEAT );
    
    
    ServerCommand( "bot_add" );
}

stock void SelectZombie( int client, int index )
{
    // Doesn't work.
    FakeClientCommand( client, "conq_npc_select_index %i", index );
}

stock void SelectZombiesInSphere( int client, const float vecPos[3] )
{
    // This is the only thing that lets us select zombies. The bad thing is, it selects zombies in a 256-unit radius.
    // NOTE: Will use sticky. Have to unselect everything first.
    FakeClientCommand( client, "conq_npc_select_sphere %.0f %.0f %.0f", vecPos[0], vecPos[1], vecPos[2] );
}

stock void UnselectAllZombies( int client )
{
    // This command will first deselect all zombies and then attempt to select the zombies in the squad. If no squad exists, nothing else is done.
    
    // Can be added back in, since we're running the update.
    // Will no longer crash the server.
    //FakeClientCommand( client, "zm_gotosquad" );
    
    FakeClientCommand( client, "zm_altselect_cc" );
}

stock void MoveZombies( int client, const float vecTarget[3] )
{
    FakeClientCommand( client, "conq_npc_move_coords %.1f %.1f %.1f", vecTarget[0], vecTarget[1], vecTarget[2] );
}

stock void DeleteZombies( int client )
{
    FakeClientCommand( client, "zm_deletezombies" );
}

stock int GetZombieState( int ent )
{
    return GetEntProp( ent, Prop_Data, "m_NPCState" );
}

stock bool IsZombieMoving( int ent )
{
    return view_as<bool>( GetEntProp( ent, Prop_Data, "m_bIsMoving" ) );
}

stock void CreateTrapTrigger( int client, int ent, int cost, int trapcost, float vecPos[3] )
{
#if defined DEBUG_TRAPS
    PrintToServer( "Created trap! (%i)", ent );
#endif
    
    SetSelectedTrap( client, ent, cost, trapcost );
    
    FakeClientCommand( client, "create_trap %.1f %.1f %.1f", vecPos[0], vecPos[1], vecPos[2] );
}

stock void ActivateTrap( int client, int ent, int cost )
{
#if defined DEBUG_TRAPS
    PrintToServer( "Activate trap! (%i)", ent );
#endif
    
    SetSelectedTrap( client, ent, cost );
    
    FakeClientCommand( client, "manipulate" );
}

stock void SetSelectedZombieSpawn( int client, int ent, int flags )
{
    SetEntProp( client, Prop_Send, "m_iLastSelected", ent );
    
    SetEntProp( client, Prop_Send, "m_iLastZombieFlags", flags );
}

stock void SetSelectedTrap( int client, int ent, int cost, int trapcost = 0 )
{
    SetEntProp( client, Prop_Send, "m_iLastSelected", ent );
    
    SetEntProp( client, Prop_Send, "m_iLastCost", cost );
    SetEntProp( client, Prop_Send, "m_iLastTrapCost", trapcost );
}

stock bool CanSee_WorldOnly( const float start[3], const float end[3] )
{
    TR_TraceRayFilter( start, end, CONTENTS_SOLID, RayType_EndPoint, TraceFilter_WorldOnly );
    
    return ( !TR_DidHit( null ) );
}

public bool TraceFilter_WorldOnly( int ent, int mask )
{
    return ( ent == 0 );
}

stock bool CanSee( const float start[3], const float end[3] )
{
    TR_TraceRayFilter( start, end, MASK_SOLID, RayType_EndPoint, TraceFilter_Blockable );
    
    return ( !TR_DidHit( null ) );
}

public bool TraceFilter_Blockable( int ent, int mask )
{
    return ( ent == 0 || ent > MaxClients );
}

stock bool DoSeePlayer( const float vecStart[3], const float vecDir[3], float dist, float widthheight )
{
    decl Float:dest[3], Float:mins[3], Float:maxs[3];
    
    dest[0] = vecStart[0] + vecDir[0] * dist;
    dest[1] = vecStart[1] + vecDir[1] * dist;
    dest[2] = vecStart[2] + vecDir[2] * dist;
    
    mins[0] = -widthheight;
    mins[1] = -widthheight;
    mins[2] = -widthheight;
    
    maxs[0] = widthheight;
    maxs[1] = widthheight;
    maxs[2] = widthheight;
    
    
    TR_TraceHullFilter( vecStart, dest, mins, maxs, MASK_ALL, TraceFilter_PlayersOnly );
    
    return ( TR_DidHit() && TraceFilter_PlayersOnly( TR_GetEntityIndex(), 0 ) );
}

public bool TraceFilter_PlayersOnly( int ent, int mask )
{
    return ( ent > 0 && ent <= MaxClients );
}

stock int ClosestPlayer( const float mypos[3], float &flDist )
{
    int client = 0;
    
    decl Float:pos[3], Float:dist;
    
    flDist = 0.0;
    
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( !IsClientInGame( i ) ) continue;
        
        if ( GetClientTeam( i ) != TEAM_HUMAN ) continue;
        
        if ( !IsPlayerAlive( i ) ) continue;
        
        
        GetClientAbsOrigin( i, pos );
        
        dist = GetVectorDistance( mypos, pos, true );
        
        if ( flDist <= 0.0 || flDist > dist )
        {
            flDist = dist;
            client = i;
        }
    }
    
    return client;
}

stock bool CanSeeAnyPlayerInDistSq( const float mypos[3], float dist )
{
    decl Float:pos[3];
    
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( !IsClientInGame( i ) || !Zm_IsHumanAlive( i ) ) continue;
        
        
        GetClientAbsOrigin( i, pos );
        
        if ( GetVectorDistance( mypos, pos, true ) <= dist && CanSee_WorldOnly( mypos, pos ) )
        {
            return true;
        }
    }
    
    return false;
}

stock float DistanceToClosestPlayerSq( const float mypos[3] )
{
    decl Float:vecPos[3], Float:dist;
    float smallest_dist = 0.0;
    
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( !IsClientInGame( i ) ) continue;
        
        if ( GetClientTeam( i ) != TEAM_HUMAN ) continue;
        
        
        GetClientAbsOrigin( i, vecPos );
        
        dist = GetVectorDistance( mypos, vecPos, true );
        
        if ( smallest_dist <= 0.0 || smallest_dist > dist )
            smallest_dist = dist;
    }
    
    return smallest_dist;
}

stock int GetHumanCount()
{
    int num = 0;
    
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame( i ) && Zm_IsHumanAlive( i ) )
            ++num;
    }
    
    return num;
}

stock int GetAmmoTypeMaxCount( int ammotype )
{
    switch ( ammotype )
    {
        case AMMOTYPE_PISTOL : return 80;
        case AMMOTYPE_SMG : return 60;
        case AMMOTYPE_RIFLE : return 20;
        case AMMOTYPE_SHOTGUN : return 24;
        case AMMOTYPE_REVOLVER : return 36;
    }
    
    return 0;
}

stock int GetAmmoTypeMaxCountTotal( int ammotype )
{
    switch ( ammotype )
    {
        case AMMOTYPE_PISTOL : return 100;
        case AMMOTYPE_SMG : return 80;
        case AMMOTYPE_RIFLE : return 31;
        case AMMOTYPE_SHOTGUN : return 32;
        case AMMOTYPE_REVOLVER : return 42;
    }
    
    return 0;
}

stock int GetClientAmmo( int client, int ammotype )
{
    return GetEntData( client, g_Offset_iAmmo + ( (ammotype + 1) * 4 ) );
}

stock bool SwitchBotToZM( int client )
{
    if ( g_bRoundEnded ) return false;
    
    
    if ( GetClientTeam( client ) != TEAM_ZM ) return false;
    
    if ( !IsValidAI() )
    {
        return false;
    }
    
    
    ChangeClientTeam( client, TEAM_SPEC );
    ChangeClientTeam_Bot( g_iBot, TEAM_ZM );
    
    return true;
}

stock bool SwitchClientToZM( int client, bool bSilent = false )
{
    if ( g_bRoundEnded ) return false;
    
    
    if ( !IsValidAI() )
    {
        if ( !bSilent )
            ReplyToCommand( client, PREFIX..."The AI isn't in the game!" );
        
        return false;
    }
    
    if ( GetClientTeam( g_iBot ) != TEAM_ZM )
    {
        if ( !bSilent )
            ReplyToCommand( client, PREFIX..."The AI isn't the ZM right now!" );
        
        return false;
    }
    
    if ( GetClientTeam( client ) == TEAM_HUMAN && _GetTeamClientCount( TEAM_HUMAN ) <= 1 )
    {
        if ( !bSilent )
            ReplyToCommand( client, PREFIX..."You are the only survivor!" );
        
        return false;
    }
    
    
    ChangeClientTeam( client, TEAM_ZM );
    ChangeClientTeam_Bot( g_iBot, TEAM_SPEC );
    
    return true;
}

stock bool IsValidAI()
{
    return ( g_iBot && IsClientInGame( g_iBot ) );
}

// Sourcemod's GetTeamClientCount doesn't seem to work.
stock int _GetTeamClientCount( int team )
{
    int num = 0;
    
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( GetClientTeam( i ) == team ) ++num;
    }
    
    return num;
}