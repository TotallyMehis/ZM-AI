public Action Cmd_ReplaceAI( int client, int args )
{
    if ( !client ) return Plugin_Handled;
    
    
    if ( !g_iBot || !IsClientInGame( g_iBot ) )
    {
        ReplyToCommand( client, PREFIX..."The AI isn't in the game!" );
        return Plugin_Handled;
    }
    
    if ( GetClientTeam( client ) == TEAM_ZM )
    {
        ReplyToCommand( client, PREFIX..."You are already the ZM!" );
        return Plugin_Handled;
    }
    
    if ( GetClientTeam( g_iBot ) != TEAM_ZM )
    {
        ReplyToCommand( client, PREFIX..."The AI isn't the ZM right now!" );
        return Plugin_Handled;
    }
    
    if ( GetClientTeam( client ) == TEAM_HUMAN && GetTeamClientCount( TEAM_HUMAN ) <= 1 )
    {
        ReplyToCommand( client, PREFIX..."You are the only survivor!" );
        return Plugin_Handled;
    }
    
    
    ChangeClientTeam( client, TEAM_ZM );
    ChangeClientTeam_Bot( g_iBot, TEAM_SPEC );
    
    return Plugin_Handled;
}

public Action Cmd_ReplaceAI_Silent( int client, int args )
{
    if ( !client ) return Plugin_Handled;
    
    
    if ( !g_iBot || !IsClientInGame( g_iBot ) )
    {
        return Plugin_Handled;
    }
    
    if ( GetClientTeam( client ) == TEAM_ZM )
    {
        return Plugin_Handled;
    }
    
    if ( GetClientTeam( g_iBot ) != TEAM_ZM )
    {
        return Plugin_Handled;
    }
    
    if ( GetClientTeam( client ) == TEAM_HUMAN && GetTeamClientCount( TEAM_HUMAN ) <= 1 )
    {
        return Plugin_Handled;
    }
    
    
    ChangeClientTeam( client, TEAM_ZM );
    ChangeClientTeam_Bot( g_iBot, TEAM_SPEC );
    
    return Plugin_Handled;
}