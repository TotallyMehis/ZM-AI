public Action Cmd_ReplaceAI( int client, int args )
{
    if ( !client ) return Plugin_Handled;
    
    
    if ( GetClientTeam( client ) == TEAM_ZM )
    {
        SwitchBotToZM( client );
        return Plugin_Handled;
    }
    
    
    SwitchClientToZM( client, false );
    
    return Plugin_Handled;
}

public Action Cmd_ReplaceAI_Silent( int client, int args )
{
    if ( !client ) return Plugin_Handled;
    
    
    if ( GetClientTeam( client ) == TEAM_ZM )
    {
        SwitchBotToZM( client );
        return Plugin_Handled;
    }
    
    
    SwitchClientToZM( client, true );
    
    return Plugin_Handled;
}

public Action Cmd_Debug_AI( int client, int args )
{
    if ( client ) return Plugin_Handled;
    
    
    char buffer[512];
    
    FormatEx( buffer, sizeof( buffer ), "Debug Data:\nPop count: %i/%i (%i)\nResources: %i\nLast spawn: %.1f\n",
        g_nPopCount, GetMaxPopCount( true ), GetMaxPopCount( false ),
        g_nResources,
        (g_flCurTime - g_flLastSpawn) );
    
    ReplyToCommand( client, "%s", buffer );
    
    return Plugin_Handled;
}

public Action Lstnr_RoundRestart( int client, const char[] command, int argc )
{
    if ( !client ) return Plugin_Continue;
    
    if ( !g_ConVar_RoundRestart.BoolValue ) return Plugin_Continue;
    
    if ( client == g_iBot ) return Plugin_Continue;
    
    
    if ( SwitchBotToZM( client ) )
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}
