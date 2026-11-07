local BuffConflictsCondition = require('cylibs/conditions/buff_conflicts')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasStatusEffectCondition = require('cylibs/conditions/has_status_effect')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Buffer = setmetatable({}, {__index = Gambiter })
Buffer.__index = Buffer
Buffer.__class = "Buffer"

function Buffer.new(action_queue, buff_settings, state_var, job)
    local self = setmetatable(Gambiter.new(action_queue, {}, state_var or state.AutoBuffMode), Buffer)

    self.job = job

    self:set_buff_settings(buff_settings)

    return self
end

function Buffer:destroy()
    Gambiter.destroy(self)
end

-- Ally priority follows the party slots exposed by Windower.
local function party_order(left, right)
    local party = windower.ffxi.get_party() or {}
    local function slot(member)
        for index = 1, 5 do
            local entry = party['p'..index]
            if entry and entry.mob and entry.mob.id == member:get_id() then
                return index
            end
        end
        return 6
    end
    local left_slot, right_slot = slot(left), slot(right)
    if left_slot == right_slot then
        return left:get_id() < right:get_id()
    end
    return left_slot < right_slot
end

function Buffer:set_buff_settings(buff_settings)
    local runtime_gambits = L{}
    local apply_default_conditions = function(gambit)
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        for condition in self:get_default_conditions(gambit):it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    for gambit in buff_settings.Gambits:it() do
        if gambit:getAbility().__type == Buff.__type then
            gambit:getAbility():reload()
        end
        if gambit:getAbilityTarget() == 'Both' then
            -- Keep one settings row and give each runtime target its own default
            -- conditions. The ordinary gambit queue still evaluates in order.
            gambit.conditions = gambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            local self_gambit, ally_gambit = gambit:copy(), gambit:copy()
            self_gambit.target = GambitTarget.TargetType.Self
            self_gambit.conditions_target = self_gambit.target
            ally_gambit.target = GambitTarget.TargetType.Ally
            ally_gambit.conditions_target = ally_gambit.target
            ally_gambit:setPriorityComparator(party_order)
            apply_default_conditions(self_gambit)
            apply_default_conditions(ally_gambit)
            runtime_gambits:append(self_gambit)
            runtime_gambits:append(ally_gambit)
        else
            apply_default_conditions(gambit)
            runtime_gambits:append(gambit)
        end
    end
    self:set_gambit_settings({ Gambits = runtime_gambits, Default = buff_settings.Default })
end

function Buffer:get_default_conditions(gambit)
    local conditions = L{
        NotCondition.new(L{ HasStatusEffectCondition.new(gambit:getAbility():get_status().id) }),
        NotCondition.new(L{ BuffConflictsCondition.new(gambit:getAbility():get_status().en)}),
        MinHitPointsPercentCondition.new(1),
    }
    if gambit:getAbilityTarget() ~= GambitTarget.TargetType.Self then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
        conditions:append(ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()))
    end
    return conditions + self.job:get_conditions_for_ability(gambit:getAbility()):map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Buffer:allows_duplicates()
    return true
end

function Buffer:allows_multiple_actions()
    return false
end

function Buffer:get_type()
    return "buffer"
end

function Buffer:get_cooldown()
    return 5
end

function Buffer:get_localized_name()
    return "Buffing"
end

function Buffer:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Buffer