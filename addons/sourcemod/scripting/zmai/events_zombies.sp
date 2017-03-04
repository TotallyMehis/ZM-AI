public void E_ZombieSpawn( Event event, const char[] szEvent, bool bDontBroadcast )
{
    int zombie = event.GetInt( "z_id" );
    if ( !IsValidEntity( zombie ) ) return;
    
    
    g_flLastSpawn = g_flCurTime;
}