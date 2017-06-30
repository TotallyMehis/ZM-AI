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