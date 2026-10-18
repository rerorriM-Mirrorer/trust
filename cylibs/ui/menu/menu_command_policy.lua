-- Awake: allow known command effects while a menu is visible. A spelling in
-- a runtime group is not permission for every structural editor subcommand.
local Policy = {}
local immediate={help=true,version=true,status=true,debug=true,menuperf=true,
    menu=true,widget=true,commands=true,start=true,startall=true,stop=true,stopall=true,toggle=true}
local profiles={trustmode=true,maintrustsettingsmode=true,subtrustsettingsmode=true,weaponskillsettingsmode=true}
local runtime={
    attack={['']=true,off=true,mirror=true,engage=true,distance=true},
    follow={['*']=true}, assist={['*']=true},
    heal={['']=true,auto=true,off=true,emergency=true},
    pull={['']=true,auto=true,aggroed=true,all=true,off=true},
    mb={['']=true,auto=true,off=true,earth=true,lightning=true,water=true,fire=true,ice=true,wind=true,light=true,dark=true},
    nuke={off=true,earth=true,lightning=true,water=true,fire=true,ice=true,wind=true,light=true,dark=true,cleave=true},
    target={auto=true,off=true,cycle=true,clear=true},
}

function Policy.effect(command, args)
    command=type(command)=='string' and command:lower() or 'help'
    args=args or {}
    if immediate[command] then return 'immediate' end
    local verb=type(args[1])=='string' and args[1]:lower() or ''
    if command=='combat' then return verb=='' and 'immediate' or 'commit' end
    if command=='set' or command=='cycle' then
        return profiles[verb] and 'blocked' or 'commit'
    end
    -- Retain remote command access; each receiving Trust runs its own policy.
    if command=='send' or command=='sendall' then return 'commit' end
    local verbs=runtime[command]
    if verbs and (verbs[verb] or verbs['*']) then return 'commit' end
    return 'blocked'
end

return Policy
