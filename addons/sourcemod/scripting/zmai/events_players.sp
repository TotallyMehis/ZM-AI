public Action E_PlayerSpawn( Event event, const char[] szEvent, bool bDontBroadcast )
{
    int client = GetClientOfUserId( event.GetInt( "userid" ) );
    if ( !client ) return;
    
    
    if ( g_iBot == client ) RequestFrame( BotSpawn_Post, GetClientUserId( client ) );
}

public void BotSpawn_Post( int bot )
{
    bot = GetClientOfUserId( bot );
    
    if ( !g_iBot || g_iBot != bot ) return;
    
    
    CheckBotProps( bot );
}

public void E_PlayerHurt( Event event, const char[] szEvent, bool bDontBroadcast )
{
    int client = GetClientOfUserId( event.GetInt( "userid" ) );
    if ( !client ) return;
    
#if !defined ZMR
    //event.GetInt( "attacker" );
    if ( event.GetBool( "zombie" ) )
    {
        g_flNextForceAct = g_flCurTime + g_ConVar_InactDifChange.FloatValue;
    }
#else
    g_flNextForceAct = g_flCurTime + g_ConVar_InactDifChange.FloatValue;
#endif
}