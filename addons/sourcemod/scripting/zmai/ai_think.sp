public Action T_BotThink( Handle hTimer )
{
#if defined DEBUG_AITHINK
    PrintToServer( PREFIX..."BotThink()" );
#endif

    if ( !g_bEnabled )
    {
        return Plugin_Stop;
    }

    // First check if the bot even exists.
    if ( !g_iBot )
    {
        FindBot();
        return Plugin_Continue;
    }
    
    if ( !IsClientInGame( g_iBot ) || !IsFakeClient( g_iBot ) )
    {
        g_iBot = 0;
        return Plugin_Continue;
    }
    
    if ( GetClientTeam( g_iBot ) != TEAM_ZM )
    {
        return Plugin_Continue;
    }
    
    
    // Make sure our traps are in order.
    if ( !g_iNumSpawns && !g_iNumTraps )
    {
        return Plugin_Continue;
    }
    
    
    // We're fine, now cache some useful stuff.
    g_flCurTime = GetEngineTime();
    g_nPopCount = Zm_GetClientPopCount( g_iBot );
    g_nResources = Zm_GetClientResources( g_iBot );
    g_nHumans = GetHumanCount();
    
    
    /*if ( g_flNextPopCheck < g_flCurTime )
    {
        CheckValidPopCount();
        
        g_flNextPopCheck = g_flCurTime + 10.0;
    }*/
    
    HandleZombies();
    
    
    HandleDifficulty();
    
    
    if ( ShouldSpawnZombies() )
    {
        if ( g_flNextDistChange < g_flCurTime )
        {
            if ( (g_flCurTime - g_flLastSpawn) > 30.0 )
            {
#if defined DEBUG_AITHINK
                PrintToServer( PREFIX..."Increasing zombie spawn/deletion distance for the lack of zombies!" );
#endif
                g_flZombieDeleteDistSq = g_flBaseZombieDeleteDistSq * 1.5;
                g_flZombieSpawnDistSq = g_flBaseZombieSpawnDistSq * 1.5;
                
                g_flNextDistChange = g_flCurTime + 30.0;
            }
            else
            {
#if defined DEBUG_AITHINK
                PrintToServer( PREFIX..."Resetting zombie spawn/deletion distance." );
#endif
                g_flZombieDeleteDistSq = g_flBaseZombieDeleteDistSq;
                g_flZombieSpawnDistSq = g_flBaseZombieSpawnDistSq;
                
                g_flNextDistChange = g_flCurTime + 10.0;
            }
        }
        

        CheckZombieSpawns();
    }
    
    
    if ( ShouldUseTraps() )
    {
        CheckTraps();
    }
    
    return Plugin_Continue;
}