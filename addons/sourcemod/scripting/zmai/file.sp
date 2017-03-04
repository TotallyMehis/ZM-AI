stock void ReadFiles()
{
    char szMap[64];
    char szFile[PLATFORM_MAX_PATH];
    
    GetCurrentMap( szMap, sizeof( szMap ) );
    
    
    ClearTrapTypes();
    
    BuildPath( Path_SM, szFile, sizeof( szFile ), "configs/zmai_maps/%s.cfg", szMap );
    ReadTypes( szFile );
    
    
    ReadMapOptions( szFile );
    
    
    BuildPath( Path_SM, szFile, sizeof( szFile ), "configs/"...CONFIG_GENERALTRAPS );
    ReadTypes( szFile, true );
}

stock bool ReadTypes( const char[] szFile, bool doerror = false )
{
    KeyValues kv = new KeyValues( "Traps" );
    
    //kv.SetEscapeSequences( false );
    
    
    if ( !kv.ImportFromFile( szFile ) || !kv.GotoFirstSubKey() )
    {
        if ( doerror )
        {
            LogError( PREFIX..."Couldn't find file '%s'", szFile );
        }
        
        delete kv;
        
        return false;
    }
    
    
    decl String:szError[256];
    
    float f;
    decl data[TRAPTYPE_SIZE];
    decl String:desc[512];
    decl Float:tracedir[3];
    decl Float:offset[3];
    float delay;
    float delay_min;
    float delay_max;
    
    float type_check;
    
    do
    {
        if ( !kv.GetSectionName( desc, sizeof( desc ) ) )
        {
            continue;
        }
        
        if ( desc[0] == 0 ) continue;
        
        
        data[TRAPTYPE_FIND_TARGETNAME] = 0;
        data[TRAPTYPE_FIND_REGEXHANDLE] = 0;
        
        
        if ( desc[0] == '*' ) // We want the name of the entity instead of a regex.
        {
            strcopy( view_as<char>( data[TRAPTYPE_FIND_TARGETNAME] ), MAX_TARGETNAME, desc[1] );
        }
        else
        {
            Regex reg = new Regex( desc, PCRE_CASELESS, szError, sizeof( szError ) );
            
#if defined DEBUG_REGEX
            PrintToServer( PREFIX..."Compiled regex \"%s\" %x", desc, reg );
#endif
            
            if ( reg == null )
            {
                LogError( PREFIX..."Couldn't compile regex! (Error: %s)", szError );
                continue;
            }
            
            
            data[TRAPTYPE_FIND_REGEXHANDLE] = view_as<int>( reg );
        }
        
        
        
        
        
        type_check = kv.GetFloat( "trace_type_check", 0.0 );
        
        data[TRAPTYPE_FLAGS] = kv.GetNum( "always", 0 ) ? TRAPFLAG_ALWAYS : 0;
        data[TRAPTYPE_FLAGS] |= ( type_check > 0.0 ) ? TRAPFLAG_TRACE_ACTIVATE : 0;
        
        
        f = kv.GetFloat( "aoe", DEF_AOESIZE );
        data[TRAPTYPE_AOESIZE_SQ] = view_as<int>( f * f );
        
        
        f = kv.GetFloat( "visibility", DEF_VISSIZE );
        data[TRAPTYPE_VISSIZE_SQ] = view_as<int>( f * f );
        
        data[TRAPTYPE_WAIT_FROMSTART] = view_as<int>( kv.GetFloat( "wait_fromstart", DEF_WAIT ) );
        
        delay = kv.GetFloat( "delay", DEF_DELAY );
        delay_min = kv.GetFloat( "delay_min", DEF_DELAY_MIN );
        delay_max = kv.GetFloat( "delay_max", DEF_DELAY_MAX );
        
        if ( delay_min < 0.0 ) delay_min = 0.0;
        if ( delay_max < 0.0 ) delay_max = 0.0;
        if ( delay_min > delay_max ) delay_min = delay_max;
        
        if ( delay_min > 0.0 && delay_min > delay ) delay = delay_min;
        if ( delay_max > 0.0 && delay_max < delay ) delay = delay_max;
        
        
        data[TRAPTYPE_DELAY] = view_as<int>( delay );
        data[TRAPTYPE_DELAY_MIN] = view_as<int>( delay_min );
        data[TRAPTYPE_DELAY_MAX] = view_as<int>( delay_max );
        data[TRAPTYPE_DELAY_MULTPERHUMAN] = view_as<int>( kv.GetFloat( "delay_multperhuman", DEF_DELAY_MULTPERHUMAN ) );
        
        
        
        data[TRAPTYPE_GROUPID] = kv.GetNum( "groupid", DEF_GROUPID );
        
        data[TRAPTYPE_TRACE_LEN] = view_as<int>( type_check );
        data[TRAPTYPE_TRACE_W_H] = view_as<int>( kv.GetFloat( "trace_width_height", 0.0 ) );
        data[TRAPTYPE_TRACE_CHECKPOSOFFSET] = view_as<int>( kv.GetFloat( "trace_checkposoffset", 0.0 ) );
        
        
        
        kv.GetVector( "trace_dir", tracedir, DEF_VECTOR );
        CopyArray( tracedir, data[TRAPTYPE_TRACE_DIR], 3 );
        
        
        kv.GetVector( "checkposoffset", offset, DEF_VECTOR );
        CopyArray( offset, data[TRAPTYPE_CHECKPOSOFFSET], 3 );
        
        
        
        data[TRAPTYPE_CHANCE] = view_as<int>( kv.GetFloat( "chance", DEF_CHANCE ) );
        data[TRAPTYPE_CHANCE_MULTPERHUMAN] = view_as<int>( kv.GetFloat( "chance_multperhuman", DEF_CHANCE_MULTPERHUMAN ) );
        
        
        data[TRAPTYPE_MIN_RES] = kv.GetNum( "minres", DEF_MIN_RES );
        data[TRAPTYPE_MAX_RES] = kv.GetNum( "maxres", DEF_MAX_RES );
        
        
        if ( !TypeHasActivationMethod( data ) )
        {
            data[TRAPTYPE_AOESIZE_SQ] = view_as<int>( DEF_NONE_AOESIZE );
            data[TRAPTYPE_VISSIZE_SQ] = view_as<int>( DEF_NONE_VISSIZE );
        }
        
        
        g_hTrapTypes.PushArray( data );
    }
    while( kv.GotoNextKey() );
    
    
    delete kv;
    
    
    return true;
}

stock bool ReadMapOptions( const char[] szFile )
{
    KeyValues kv = new KeyValues( "Options" );
    
    if ( !kv.ImportFromFile( szFile ) )
    {
        delete kv;
        return false;
    }
    
    
    float f;
    
    
    g_bEnabled = kv.GetNum( "enabled", 1 ) ? true : false;
    
    
    f = kv.GetFloat( "base_zombiespawn_dist", DEF_BASE_SPAWN_DIST );
    g_flBaseZombieSpawnDistSq = f * f;
    
    f = kv.GetFloat( "base_zombiedelete_dist", DEF_BASE_DELETE_DIST );
    g_flBaseZombieDeleteDistSq = f * f;
    
    
    delete kv;
    
    return true;
}