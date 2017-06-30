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

public Action Lstnr_RoundRestart( int client, const char[] command, int argc )
{
    if ( !client ) return Plugin_Continue;
    
    if ( !g_ConVar_RoundRestart.BoolValue ) return Plugin_Continue;
    
    if ( client == g_iBot ) return Plugin_Continue;
    
    
    SwitchBotToZM( client );
    
    return Plugin_Continue;
}