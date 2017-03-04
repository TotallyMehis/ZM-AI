public void E_RoundRestart( Event event, const char[] szEvent, bool bDontBroadcast )
{
    g_bRoundEnded = false;
    //g_flRoundStartTime = GetEngineTime();
    
    RequestFrame( E_RoundRestart_Post );
}

public void E_RoundRestart_Post( any data )
{
#if defined DEBUG
    PrintToServer( PREFIX..."RoundRestart_Post" );
#endif
    
    g_iHurt = INVALID_ENT_REFERENCE; // point_hurt is not kept through rounds.
    
    
    g_flCurTime = GetEngineTime();
    
    g_flNextForceAct = g_flCurTime + g_ConVar_InactDifChange.FloatValue;
    
    
    // Give the players some time at the start.

    float delay = 6.0;
    switch ( g_iDifficulty )
    {
        case DIFFICULTY_MED : delay += 8.0;
        case DIFFICULTY_EASY : delay += 10.0;
        case DIFFICULTY_SUPEREASY : delay += 14.0;
    }
    
    g_flNextSpawn = g_flCurTime + delay;
    g_flNextTrap = g_flCurTime + delay;
    
    FindEnts();
}

public void E_RoundVictory( Event event, const char[] szEvent, bool bDontBroadcast )
{
    if ( g_bRoundEnded ) return;
    
    
    g_bRoundEnded = true;
    
    
    /*if ( !g_iBot )
    {
        AddBot();
    }*/
}