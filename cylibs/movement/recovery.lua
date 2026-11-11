-- A: action hooks arbitrate movement before the original follow/run code runs.
-- Only tagged pulling/following/path actions participate. Cooldowns are local,
-- keyed by zone and mob ID; never modify shared target-name exclusions.
local Detector=require('cylibs/movement/stuck_detector')
local clock=require('socket').gettime
local M={skips={},last='idle'}
local detector=Detector.new(clock)
local defaults={mode='Detour',pulling=true,following=true,paths=true,interval=2,
    min_movement=.5,detour_distance=2,attempts=2,pull_cooldown=30,diagnostics=true,verbose=true}
local function settings()
    local saved=addon_settings and addon_settings:getSettings().movement
    saved=saved and saved.recovery or {}
    local result={}
    for k,v in pairs(defaults) do if saved[k]==nil then result[k]=v else result[k]=saved[k] end end
    if result.mode~='Detour' and result.mode~='Pause' then result.mode='Off' end
    local limits={interval={.5,15},min_movement={.1,3},detour_distance={.5,5},attempts={1,4},pull_cooldown={5,180}}
    for k,range in pairs(limits) do
        local n=tonumber(result[k]);if not n or n~=n then n=defaults[k] end
        result[k]=math.max(range[1],math.min(range[2],n))
    end
    return result
end
M.settings=settings
local function mobkey(id)
    local info=windower.ffxi.get_info()
    return tostring(info and info.zone)..':'..tostring(id)
end
function M.is_skipped(id)
    local config=settings()
    if config.mode=='Off' or config.pulling==false then return false end
    local key=mobkey(id);local until_time=M.skips[key]
    if until_time and clock()<until_time then return true end
    if until_time then M.skips[key]=nil;detector:reset() end
    return false
end
function M.reset(clear_skips)
    detector:reset();M.last='idle'
    if clear_skips then M.skips={} end
end
function M.status()return settings().mode..' | '..M.last end
local function report(text,config,important,display)
    M.last=text
    if important or config.verbose then
        require('cylibs/ui/chat/status_message').show('Recovery',display or text)
    end
    if not config.diagnostics then return end
    windower.create_dir(windower.addon_path..'data/movement')
    local character=windower.ffxi.get_player()
    local name=character and character.name or 'unknown'
    local f=io.open(windower.addon_path..'data/movement/recovery-'..name..'.log','a')
    if f then f:write(os.date('%Y-%m-%d %H:%M:%S')..' '..text..'\n');f:close() end
end
function M.tag(action,kind,id,key,root)
    if not action then return end
    root=root or action
    action.recovery={kind=kind,id=id,key=key or (kind..':'..tostring(id)),root=root}
    local config=settings()
    local type_name=action.gettype and action:gettype() or ''
    if config.mode~='Off' and config[kind]~=false and
        (type_name=='sequenceaction' or type_name=='followaction' or type_name=='runtoaction' or type_name=='runtolocationaction') then
        local budget=(config.interval+2)*(config.attempts+1)+5
        action.recovery_timeout=budget
        if action.max_duration then action.max_duration=math.max(action.max_duration,budget) end
    end
    if action.queue then for child in action.queue:it() do M.tag(child,kind,id,key,root) end end
end
-- Bind through the existing player events so manual casts suspend observation
-- too. Rebinding on job reload disposes subscriptions and all transient state.
function M.bind(character)
    if M.dispose_bag then M.dispose_bag:destroy() end
    M.dispose_bag=require('cylibs/events/dispose_bag').new()
    M.casting_until=0;M.reset(true)
    if not character then return end
    local function add(name,fn)
        if character[name] then
            local event=character[name](character)
            M.dispose_bag:add(event:addAction(fn),event)
        end
    end
    add('on_spell_begin',function()M.casting_until=clock()+30 end)
    for _,name in ipairs({'on_spell_finish','on_spell_finish_no_effect','on_spell_interrupted','on_unable_to_cast'}) do
        add(name,function()M.casting_until=0 end)
    end
end
function M.close()
    if M.dispose_bag then M.dispose_bag:destroy();M.dispose_bag=nil end
    M.reset(true)
end
local function suspended(ordinary_follow, following)
    local info=windower.ffxi.get_info();local character=windower.ffxi.get_player()
    if not info or not info.logged_in or not character then return true, 'character unavailable' end
    -- Windower statuses: 5 = Chocobo, 85 = Mount. Permit these only
    -- for following; pulling and recorded-path status guards stay unchanged.
    local mounted_follow = following and (character.status == 5 or character.status == 85)
    local travel_follow = following and (character.status == 0 or mounted_follow)
    if info.chat_open and not travel_follow then return true, 'chat input open' end
    -- An idle or mounted follower can travel with an ordinary inventory window open.
    if info.menu_open and not travel_follow then
        -- Windower exposes a flag rather than a menu ID. Recognize the
        -- engaged enemy cursor as the battle menu unless subtargeting.
        local target = character.status == 1 and windower.ffxi.get_mob_by_target('t')
        local battle_menu = target and target.spawn_type == 16 and target.hpp > 0
            and not windower.ffxi.get_mob_by_target('st')
        if not battle_menu then return true, 'Windower menu_open=true' end
    end
    if character.status~=0 and character.status~=1 and not mounted_follow then return true, 'character status '..tostring(character.status) end
    if not ordinary_follow and addon_enabled and not addon_enabled:getValue() then return true, 'Trust paused' end
    local follow_settings = addon_settings and addon_settings:getSettings().follow or {}
    local pause_for_cast = not travel_follow or follow_settings.auto_pause == true
    if pause_for_cast and clock()<(M.casting_until or 0) then return true, 'cast completion pending' end
    if not travel_follow and hud and hud.trustMenu and hud.trustMenu:isVisible() then return true, 'Trust menu open' end
    for _,id in ipairs(character.buffs or {}) do
        local buff=res and res.buffs[id]
        if buff and ({Sleep=true,Stun=true,Petrification=true,Terror=true,Bind=true,Lullaby=true})[buff.en] then
            return true, 'status effect '..buff.en
        end
    end
    return false
end
M.suspended=suspended
function M.step(action,pos,goal,radius)
    local meta=action.recovery
    if not meta then return false end
    local config=settings()
    if config.mode=='Off' or config[meta.kind]==false then detector:reset();return false end
    -- Following must not overwrite a puller's steering in the other queue.
    local current=action_queue and action_queue.current_action
    if meta.kind~='pulling' and current and current.recovery and current.recovery.kind=='pulling' then return true end
    if meta.kind=='pulling' and M.is_skipped(meta.id) then
        windower.ffxi.follow();windower.ffxi.run(false)
        if not meta.root:is_cancelled() and not meta.root.completed then meta.root:cancel() end
        return true
    end
    local key=mobkey(meta.key)
    local previous=detector.context and detector.context.key==key and detector.last or ''
    local following = meta.kind == 'following'
    local blocked, reason = suspended(following and action.follow_while_stopped == true, following)
    if following then
        -- Log transitions, not every frame. Input/status holds remain authoritative.
        if reason ~= meta.follow_block_reason then
            if reason then
                report('following held: '..reason, {diagnostics=config.diagnostics,verbose=false}, false)
            elseif meta.follow_block_reason then
                report('following resumed after '..meta.follow_block_reason, {diagnostics=config.diagnostics,verbose=false}, false)
            end
            meta.follow_block_reason = reason
        end
        if not blocked then
            local dx,dy=goal[1]-pos[1],goal[2]-pos[2]
            local near=math.sqrt(dx*dx+dy*dy)<=math.max(radius,config.detour_distance)
            if near then
                -- A cosmetic slot correction must never send the follower farther
                -- sideways than its actual destination. Keep steering directly.
                if not meta.follow_near then
                    report(string.format('following near goal; direct steering without detours; formation=%s distance=%.2f radius=%.2f goal=%.2f,%.2f', tostring(action.formation==true),math.sqrt(dx*dx+dy*dy),radius,goal[1],goal[2]), {diagnostics=config.diagnostics,verbose=false}, false)
                end
                meta.follow_near=true;meta.follow_retry=nil;detector:reset()
                return false
            end
            meta.follow_near=false
            if meta.follow_retry then
                local retry=meta.follow_retry
                local gx,gy=goal[1]-retry.goal[1],goal[2]-retry.goal[2]
                local moved=math.sqrt(gx*gx+gy*gy)>=math.max(config.min_movement,radius)
                if clock()<retry.until_time and not moved then
                    M.last='following waiting to retry'
                    windower.ffxi.run(false)
                    return true
                end
                meta.follow_retry=nil;detector:reset()
                report('following retrying current leader destination',config,false)
            end
        elseif meta.follow_retry then
            -- Cast/menu/status time is not time spent trying to move.
            meta.follow_retry.until_time=clock()+config.interval
        end
    end
    local decision,offset,started=detector:sample(key,pos,goal,radius,config,blocked)
    if decision=='normal' then
        M.last=detector.last
        if previous:find('detour',1,true) then
            report(meta.kind..': retrying original destination',config,false)
        end
        return false
    end
    windower.ffxi.follow()
    windower.ffxi.run(false)
    if decision=='detour' then
        if started then
            if windower.ffxi.get_player().target_locked then windower.send_command('input /lockon') end
            report(string.format('%s %s: detour %d from %.2f,%.2f toward %.2f,%.2f; goal %.2f,%.2f',
                meta.kind,tostring(meta.id or meta.key),detector.context.attempts,pos[1],pos[2],offset[1],offset[2],goal[1],goal[2]),config,false,
                meta.kind..': detour '..detector.context.attempts..' '..(detector.context.attempts%2==1 and 'left' or 'right')..' ('..config.detour_distance..' yalms)')
        end
        windower.ffxi.run(offset[1]-pos[1],offset[2]-pos[2],pos[3])
    elseif decision=='failed' and following then
        -- Ordinary following remains live. Wait briefly, then retry the current
        -- goal; a changed leader destination can release the wait immediately.
        meta.follow_retry={until_time=clock()+config.interval,goal={goal[1],goal[2],goal[3]}}
        detector:reset()
        -- Start a fresh bounded attempt budget so the queue timeout cannot
        -- silently retire the live action during repeated recovery cycles.
        if meta.root.set_start_time then meta.root:set_start_time(os.time()) end
        report('following waiting to retry; target retained',config,false)
    elseif decision=='failed' and not meta.handled then
        meta.handled=true
        if meta.kind=='pulling' then
            M.skips[mobkey(meta.id)]=clock()+config.pull_cooldown
            local character=windower.ffxi.get_player()
            local target=character and windower.ffxi.get_mob_by_index(character.target_index or 0)
            if character and character.status==1 and target and target.id==meta.id then
                local disengage=require('cylibs/actions/disengage').new()
                disengage:perform();disengage:destroy()
            end
            -- Publish exclusion before cancellation can complete the sequence
            -- and let the attacker choose another engagement action.
            report('blocked pull '..tostring(meta.id)..'; skipping for '..config.pull_cooldown..'s',config,true)
        else
            local trust=player and player.trust and player.trust.main_job
            local follower=trust and trust:role_with_type('follower')
            if follower then follower.recovery_paused=true;follower:stop_following() end
            report(meta.kind..' paused; use follow start or path start to retry',config,true)
        end
        if not meta.root:is_cancelled() and not meta.root.completed then meta.root:cancel() end
    else M.last=detector.last end
    return true
end
return M
