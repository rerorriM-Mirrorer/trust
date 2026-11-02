local AggroedCondition = require('cylibs/conditions/aggroed')
local Approach = require('cylibs/battle/approach')
local ConditionalCondition = require('cylibs/conditions/conditional')
local CooldownCondition = require('cylibs/conditions/cooldown')
local DisposeBag = require('cylibs/events/dispose_bag')
local Engage = require('cylibs/battle/engage')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasMaxNumAlterEgosCondition = require('cylibs/conditions/has_max_num_alter_egos')
local MobFilter = require('cylibs/battle/monsters/mob_filter')
local PartyClaimedCondition = require('cylibs/conditions/party_claimed')
local PartyLeaderCondition = require('cylibs/conditions/party_leader')
local PartyTargetedCondition = require('cylibs/conditions/party_targeted')
local PullTargetUtil = require('cylibs/util/pull_target_util')
local RunToLocationAction = require('cylibs/actions/runtolocation')
local TargetIdsCondition = require('cylibs/conditions/target_ids')
local TargetNamesCondition = require('cylibs/conditions/target_names')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Puller = setmetatable({}, {__index = Gambiter })
Puller.__index = Puller
Puller.__class = "Puller"

state.AutoPullMode = M{['description'] = 'Pull Monsters to Fight', 'Off', 'Auto','Aggroed','All'}
state.AutoPullMode:set_description('Auto', "Pull monsters for the party from the target list.")
state.AutoPullMode:set_description('Aggroed', "Pull any monster aggressive to the party.")
state.AutoPullMode:set_description('All', "Pull any monster that's nearby.")

state.AutoCampMode = M{['description'] = 'Return to Camp after Battle', 'Off', 'Auto'}
state.AutoCampMode:set_description('Auto', "Return to camp after battle (set with // trust pull camp).")

state.PullActionMode = M{['description'] = 'Pull Actions', 'Auto', 'Target', 'Approach'}
state.PullActionMode:set_description('Auto', "Pull with pull actions in settings.")
state.PullActionMode:set_description('Target', "Pull by targeting and engaging.")
state.PullActionMode:set_description('Approach', "Pull by engaging and approaching.")


function Puller.new(action_queue, pull_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, state.AutoPullMode), Puller)

    self.job = job
    self.dispose_bag = DisposeBag.new()

    self:set_pull_settings(pull_settings)

    return self
end

function Puller:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Puller:on_add()
    Gambiter.on_add(self)

    local current_target = self:get_alliance():get_target_by_index(self:get_party():get_player():get_target_index())
    if state.AutoPullMode.value ~= 'Off' and current_target and self:is_valid_target(current_target:get_mob()) then
        self:set_pull_target(Monster.new(current_target.id))
    end

    local on_pull_mode_changed = function(new_value)
        self:get_party():set_should_ignore_assist_target(new_value ~= 'Off')
        if new_value ~= 'Off' then
            self:set_pull_settings(self.job_pull_settings or self.pull_settings)
            windower.send_command('input /autotarget off')
            self:get_party():set_assist_target(self:get_party():get_player())
        else
            self:get_party():set_party_target_index(self:get_party():get_assist_target():get_target_index())
        end
    end
    on_pull_mode_changed(state.AutoPullMode.value)

    self.dispose_bag:add(state.AutoPullMode:on_state_change():addAction(function(_, new_value)
        on_pull_mode_changed(new_value)
    end), state.AutoPullMode:on_state_change())

    self.dispose_bag:add(WindowerEvents.MobKO:addAction(function(mob_id, mob_name, status)
        if self:get_target() and self:get_target():get_id() == mob_id then
            logger.notice(self.__class, 'mob_ko', mob_name, self:get_target():get_mob().hpp, status)
            CooldownCondition.set_timestamp('last_mob_ko', os.time())
            self:set_pull_target(nil) -- this is necessary otherwise get_target() returns valid until next loop
            self:check_target(L{ mob_id })
        end
    end), WindowerEvents.MobKO)

    self.dispose_bag:add(self:get_party():get_player():on_status_change():addAction(function(_, new_status, old_status)
        if L{ 'Event' }:contains(new_status) then
            self:set_pull_target(nil)
        end
    end), self:get_party():get_player():on_status_change())
end

function Puller:tic(_, _)
    local shared=require('settings/shared_preferences')
    local revision=shared.shared().revision
    local enabled=shared.enabled()
    if self.shared_revision~=revision or self.shared_enabled~=enabled then
        self:set_pull_settings(self.job_pull_settings)
    end
    if state.AutoPullMode.value == 'Off' then
        return
    end

    logger.notice(self.__class, 'tic', 'target_index', self.target_index or 'none')

    self:return_to_camp()
    self:check_target()
end

function Puller:target_change(target_index)
    Gambiter.target_change(self, target_index)

    self:check_gambits(nil, nil, true)
end

function Puller:check_target(target_id_blacklist)
    if state.AutoPullMode.value == 'Off' then
        return
    end

    local next_target = self:get_pull_target()

    if not self:is_valid_target(next_target and next_target:get_mob(), target_id_blacklist) then
        if next_target and next_target:get_mob() then
            local previous_target = next_target:get_mob()
            logger.notice(self.__class, 'check_target', 'clear', previous_target.name, previous_target.hpp, previous_target.index, previous_target.status, previous_target.claim_id or 'unclaimed')
        end

        next_target = self:get_next_target(target_id_blacklist)
        if next_target then
            self:set_pull_target(next_target)
            logger.notice(self.__class, 'check_target', 'set_pull_target', next_target:get_name(), next_target:get_mob().index)
        else
            self:set_pull_target(nil)
            logger.notice(self.__class, 'check_target', 'no valid targets')
            if state.AutoPullMode.value == 'Auto' then
                self:get_party():add_to_chat(self:get_party():get_player(), "I can't find anything to pull. I'll check again soon.", self.__class..'_no_valid_targets', 15)
            end
            self:return_to_camp()
            return
        end
    end
end

function Puller:get_all_targets()
    local all_targets = L{}
    if not self:check_delay() then
        return all_targets
    end
    local target_names = self.target_names
    local function sort_bucket(mobs)
        table.sort(mobs, function(a, b)
            local index_a = require('cylibs/util/name_match').index_of(target_names,a.name)
            local index_b = require('cylibs/util/name_match').index_of(target_names,b.name)
            if index_a == -1 then index_a = math.huge end
            if index_b == -1 then index_b = math.huge end
            return index_a < index_b
        end)
        return mobs
    end
    if state.AutoPullMode.value == 'Aggroed' then
        -- 1. Aggroed mobs that are unclaimed and not targeted by party members
        -- 2. Aggroed mobs that are unclaimed
        -- 3. Aggroed mobs that are party claimed
        all_targets = sort_bucket(self.mob_filter:get_aggroed_mobs(L{ UnclaimedCondition.new(), NotCondition.new(L{ PartyTargetedCondition.new() }) }))
                + sort_bucket(self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.Unclaimed }))
                + sort_bucket(self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.PartyClaimed }))
    elseif state.AutoPullMode.value == 'Auto' then
        -- 1. Aggroed mobs that are party claimed
        -- 2. Aggroed mobs that are unclaimed
        -- 3. Unaggroed mobs in target name whitelist
        all_targets = sort_bucket(self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.PartyClaimed }))
                + sort_bucket(self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.Unclaimed }))
                + sort_bucket(self.mob_filter:get_nearby_mobs(L{ MobFilter.Type.Unclaimed }):filter(function(mob)
            return require('cylibs/util/name_match').contains(self.target_names,mob.name) or self.target_ids:contains(mob.id)
        end))
    elseif state.AutoPullMode.value == 'All' then
        -- 1. All mobs that are party claimed
        -- 2. All mobs that are unclaimed
        all_targets = sort_bucket(self.mob_filter:get_nearby_mobs(L{ MobFilter.Type.PartyClaimed }))
                + sort_bucket(self.mob_filter:get_nearby_mobs(L{ MobFilter.Type.Unclaimed }))
    end
    return all_targets
end

function Puller:check_delay()
    local last_mob_ko = CooldownCondition.get_timestamp('last_mob_ko')
    return last_mob_ko == nil or os.time() >= last_mob_ko + self.delay
end

function Puller:get_next_target(target_id_blacklist)
    target_id_blacklist = target_id_blacklist or L{}

    if self:get_party():get_player():get_status() == 'Event' or not self:check_delay() then
        return nil
    end

    local current_target = self:get_alliance():get_target_by_index(self:get_party():get_player():get_target_index())
    if current_target and not target_id_blacklist:contains(current_target:get_id()) and self:is_valid_target(current_target:get_mob())
            and Condition.check_conditions(L{ AggroedCondition.new() }, current_target:get_mob().index) then
        return Monster.new(current_target:get_id())
    end
    local all_targets = self:get_all_targets():filter(function(target)
        return not target_id_blacklist:contains(target.id) and self:is_valid_target(target)
    end)
    if all_targets:length() > 0 then
        if state.PullActionMode.value == 'Target' or self.max_num_targets > 1 then
            return Monster.new(all_targets:random().id)
        else
            return Monster.new(all_targets[1].id)
        end
    else
        return nil
    end
end

function Puller:is_valid_target(target, target_id_blacklist)
    if target and require('cylibs/movement/recovery').is_skipped(target.id) then return false end
    if not target or target_id_blacklist and target_id_blacklist:contains(target.id) then
        return false
    end

    local pull_abilities = self.pull_abilities[state.PullActionMode.value]

    local max_pull_ability_range = 0
    for gambit in pull_abilities:it() do
        max_pull_ability_range = math.max(max_pull_ability_range, gambit:getAbility():get_range())
    end
    if state.AutoPullMode.value=='Auto' or state.AutoPullMode.value=='All' then
        max_pull_ability_range=self.distance
    else
        max_pull_ability_range=math.min(max_pull_ability_range,self.distance)
    end

    local conditions = L{
        MinHitPointsPercentCondition.new(1),
        ConditionalCondition.new(L{
            PartyClaimedCondition.new(true),
            ConditionalCondition.new(L{ UnclaimedCondition.new(), MaxDistanceCondition.new(max_pull_ability_range) }, Condition.LogicalOperator.And),
        }, Condition.LogicalOperator.Or),
        NotCondition.new(L{ TargetNamesCondition.new(self.blacklist) }),
    }
    return not L{ 2, 3 }:contains(target.status) and Condition.check_conditions(conditions, target.index)
end

function Puller:get_pull_target()
    return self:get_target()
end

function Puller:set_pull_target(target)
    if state.AutoPullMode.value == 'Off' then
        self:get_party():set_party_target_index(self:get_party():get_assist_target():get_target_index())
    else
        self:get_party():set_party_target_index(target and target:get_mob().index)
    end
end

function Puller:get_pull_settings()
    return self.pull_settings
end

function Puller:set_pull_settings(pull_settings)
    self.job_pull_settings=pull_settings
    local shared=require('settings/shared_preferences')
    pull_settings=shared.effective(pull_settings)
    self.shared_revision=shared.shared().revision
    self.shared_enabled=shared.enabled()
    self.pull_settings = pull_settings
    self.distance = pull_settings.Distance
    self.blacklist = pull_settings.Blacklist
    self.delay = pull_settings.Delay or 0
    self.mob_filter = MobFilter.new(self:get_alliance(), self.distance or 25, nil, self.blacklist)
    if pull_settings.RandomizeTarget then
        self.max_num_targets = 6
    else
        self.max_num_targets = 1
    end
    self:set_target_names(pull_settings.Targets or L{})
    self:set_target_ids((pull_settings.TargetIds or L{}):map(PullTargetUtil.get_id))

    CooldownCondition.set_timestamp('last_mob_ko', os.time() - self.delay)

    for gambit in pull_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = L{
            GambitCondition.new(ModeCondition.new('PullActionMode', 'Auto'), GambitTarget.TargetType.Self)
        } + self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    local approach = Gambit.new(GambitTarget.TargetType.Enemy, L{}, Approach.new(), GambitTarget.TargetType.Enemy, L{"Pulling"})
    approach.conditions = L{
        GambitCondition.new(ModeCondition.new('PullActionMode', 'Approach'), GambitTarget.TargetType.Self)
    } + self:get_default_conditions(approach)

    local auto_target = Gambit.new(GambitTarget.TargetType.Enemy, L{}, Engage.new(L{MaxDistanceCondition.new(30)}), GambitTarget.TargetType.Enemy, L{"Pulling","Reaction"})
    auto_target.conditions = L{
        GambitCondition.new(ModeCondition.new('PullActionMode', 'Target'), GambitTarget.TargetType.Self),
    } + self:get_default_conditions(auto_target)

    self.pull_abilities = {
        Auto = pull_settings.Gambits,
        Approach = L{ approach },
        Target = L{ auto_target },
    }

    local gambit_settings = {
        Gambits = self.pull_abilities.Auto + self.pull_abilities.Approach + self.pull_abilities.Target
    }
    
    self:set_gambit_settings(gambit_settings)
end

function Puller:get_default_conditions(gambit)
    local conditions = L{
        GambitCondition.new(UnclaimedCondition.new(), GambitTarget.TargetType.Enemy),
        GambitCondition.new(MaxDistanceCondition.new((state.AutoPullMode.value=='Auto' or state.AutoPullMode.value=='All') and self.distance or gambit:getAbility():get_range()), GambitTarget.TargetType.Enemy),
        GambitCondition.new(MinHitPointsPercentCondition.new(1), GambitTarget.TargetType.Enemy),
        GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('weakness') }), GambitTarget.TargetType.Self),
    }
    if state.AutoPullMode.value == 'Aggroed' then
        conditions:append(GambitCondition.new(AggroedCondition.new(), GambitTarget.TargetType.Enemy))
    elseif state.AutoPullMode.value == 'Auto' then
        conditions:append(GambitCondition.new(ConditionalCondition.new(L{
            TargetNamesCondition.new(self:get_target_names()),
            TargetIdsCondition.new(self:get_target_ids()),
        }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Enemy))
    end
    local alter_ego_conditions = L{
        GambitCondition.new(ConditionalCondition.new(
            L{
                NotCondition.new(L{ PartyLeaderCondition.new() }),
                ModeCondition.new('AutoTrustsMode', 'Off'),
                ConditionalCondition.new(L{ ModeCondition.new('AutoTrustsMode', 'Auto'), NotCondition.new(L{ ModeCondition.new('AutoPullMode', 'Off') }), HasMaxNumAlterEgosCondition.new() }, Condition.LogicalOperator.And)
            },
            Condition.LogicalOperator.Or), GambitTarget.TargetType.Self
        )
    }
    return (alter_ego_conditions + conditions + self.job:get_conditions_for_ability(gambit:getAbility())):map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, GambitTarget.TargetType.Self)
        end
        return condition
    end)
end

-- Planning omits only automatically supplied standing requirements. User
-- conditions, MP/recast/job/target filters remain authoritative. Execution
-- checks the original gambit again after arriving and stopping.
function Puller:planning_gambit(gambit)
    local copy=setmetatable({},getmetatable(gambit))
    for k,v in pairs(gambit) do copy[k]=v end
    copy.conditions=gambit.conditions:filter(function(wrapped)
        local condition=wrapped:getCondition()
        return condition.__class~='IsStandingCondition' or wrapped:is_editable()
    end)
    return copy
end

function Puller:report_pull(text)
    if self.last_pull_report==text then return end
    self.last_pull_report=text
    local config=require('cylibs/movement/recovery').settings()
    if config.verbose then require('cylibs/ui/chat/status_message').show('Pulling',text) end
    if config.diagnostics then
        windower.create_dir(windower.addon_path..'data/movement')
        local name=windower.ffxi.get_player().name
        local file=io.open(windower.addon_path..'data/movement/pulling-'..name..'.log','a')
        if file then file:write(os.date('%Y-%m-%d %H:%M:%S')..' '..text..'\n');file:close() end
    end
end

function Puller:check_gambits(gambits,param,ignore_delay)
    if state.AutoPullMode.value~='Auto' and state.AutoPullMode.value~='All' then
        return Gambiter.check_gambits(self,gambits,param,ignore_delay)
    end
    if not self:is_enabled() or self.action_queue.is_enabled==false then return end
    if self.action_queue:has_action(self:get_action_identifier()) then return end
    local target=self:get_target()
    local mob=target and target:get_mob()
    if not mob or not self:is_valid_target(mob) then return end
    if not UnclaimedCondition.new():is_satisfied(mob.index) then return end
    self.pull_retry=self.pull_retry or {}
    if require('socket').gettime()<(self.pull_retry[mob.id] or 0) then return end
    for gambit in (gambits or self:get_all_gambits()):it() do
        local ability=gambit:getAbility()
        if gambit:isEnabled() and ability and ability:is_valid() then
            local plan=self:planning_gambit(gambit)
            local satisfied=self:is_gambit_satisfied(plan,param)
            if satisfied then self:queue_pull(gambit,plan,target,param);return end
        end
    end
    self:report_pull('no eligible pull action for '..mob.name)
end

function Puller:queue_pull(gambit,plan,target,param)
    local mob=target:get_mob();local id,index=mob.id,mob.index
    local ability=gambit:getAbility()
    local melee=ability.__class=='Approach' or ability.__class=='Engage'
    local range=melee and 2 or ability:get_range()
    if not melee then
        for condition in ability:get_conditions():it() do
            if condition.__class=='MaxDistanceCondition' then range=math.min(range,condition.distance) end
        end
        range=math.max(.5,range-.5)
    end
    local mode=state.PullActionMode.value
    local function active()
        return self:is_enabled() and self.action_queue.is_enabled~=false
            and (state.AutoPullMode.value=='Auto' or state.AutoPullMode.value=='All')
            and state.PullActionMode.value==mode and self:get_target()
            and self:get_target():get_mob() and self:get_target():get_mob().id==id
    end
    local function eligible()
        return active() and gambit:isEnabled() and ability:is_valid()
            and self:is_valid_target(windower.ffxi.get_mob_by_index(index))
            and self:is_gambit_satisfied(plan,param)
    end
    local action=require('cylibs/actions/pull_attempt').new({
        index=index,id=id,name=mob.name,ability=ability,player=self:get_player(),
        range=range,melee=melee,queue=self.action_queue,active=active,eligible=eligible,
        ready=function()return self:is_gambit_satisfied(gambit,param) end,
        claimed=function(m)return PartyClaimedCondition.new(true):is_satisfied(m.index) end,
        start=function()
            local follower=self.job and player.trust.main_job:role_with_type('follower')
            if follower then follower:stop_following() end
        end,
        report=function(reason)self:report_pull(mob.name..': '..reason) end,
        finished=function(success)
            if not success then self.pull_retry[id]=require('socket').gettime()+2 end
            local combat=player.trust.main_job:role_with_type('combatmode')
            if success and combat then combat:check_gambits(nil,nil,true) end
        end,
    })
    action.validate=function()return eligible() end
    require('cylibs/movement/recovery').tag(action,'pulling',id)
    -- A full five-slot queue must not repeatedly reject the pull behind
    -- routine work. Retire one queued lower-priority action, never a cast
    -- already running or higher-priority healing.
    if self.action_queue:length()>=self.action_queue.max_size then
        local lowest
        for queued in self.action_queue.queue:it() do
            if queued:getpriority()<action:getpriority() and
                    (not lowest or queued:getpriority()<lowest:getpriority()) then lowest=queued end
        end
        if lowest then
            local queue=Q{}
            for queued in self.action_queue.queue:it() do
                if queued==lowest then queued:destroy() else queue:push(queued) end
            end
            self.action_queue.queue=queue
        end
    end
    self:report_pull(mob.name..': pull queued; waiting for current action if busy')
    self.action_queue:push_action(action,true)
    -- Retire only competing combat movement, after the higher-priority pull
    -- is queued. Running casts/abilities are allowed to finish normally.
    local current=self.action_queue.current_action
    if not action.is_destroyed and current and current~=action
            and current:getidentifier()=='combatmode_action' then current:cancel() end
end

function Puller:get_type()
    return "puller"
end

function Puller:set_target_names(target_names)
    self.target_names = target_names
end

function Puller:get_target_names()
    return self.target_names
end

function Puller:set_target_ids(target_ids)
    self.target_ids = target_ids
end

function Puller:get_target_ids()
    return self.target_ids
end

function Puller:set_camp_position(position)
    self.mob_filter:set_center_position(position)
end

function Puller:get_camp_position()
    return self.mob_filter:get_center_position()
end

function Puller:get_cooldown()
    return 0
end

function Puller:allows_duplicates()
    return false
end

function Puller:allows_multiple_actions()
    return false
end

function Puller:return_to_camp()
    if state.AutoCampMode.value == 'Off' or self:get_pull_target() ~= nil
            or self:get_party():get_player():get_status() == 'Engaged' or self:get_camp_position() == nil then
        return false
    end

    local distance = self:get_party():get_player():distance(self:get_camp_position()[1], self:get_camp_position()[2])
    if distance > 40 then
        self:set_camp_position(nil)
        self:get_party():add_to_chat(self:get_party():get_player(), "I'm too far from camp to go back now.")
        windower.ffxi.run(false)
        return false
    end

    if distance > 2 then
        local return_to_camp_action = RunToLocationAction.new(self:get_camp_position()[1], self:get_camp_position()[2], self:get_camp_position()[3], 2.0)
        return_to_camp_action.identifier = "Return to camp"

        self.action_queue:push_action(return_to_camp_action, true)
    end

    return true
end

return Puller