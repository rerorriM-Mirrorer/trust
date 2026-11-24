---------------------------
-- Fork addition (Manual1): an action A pressed while Trust was busy. cylibs/trust/manual_input.lua
-- holds the game's packet back and queues one of these at the very front of Trust's queue; when
-- its turn comes it sends the same command again as chat input (so GearSwap still swaps gear).
-- It finishes when the game reports the action, or gives up when the game never starts it.
-- @class module
-- @name ManualAction

local DisposeBag = require('cylibs/events/dispose_bag')

local Action = require('cylibs/actions/action')
local ManualAction = setmetatable({}, { __index = Action })
ManualAction.__index = ManualAction
ManualAction.__type = "ManualAction"
ManualAction.__class = "ManualAction"

-- Tunables
ManualAction.StartTimeout = 2.5   -- seconds; no start or finish seen by then = the game refused it (default 2.5)
ManualAction.FinishTimeout = 15   -- seconds; longest wait from start to finish (default 15)

-- Player action packet categories (Windower action event).
local FINISH = { [2] = true, [3] = true, [4] = true, [5] = true, [6] = true }   -- ranged, WS, spell, item, JA
local START = { [7] = true, [8] = true, [9] = true, [12] = true }               -- WS, spell, item, ranged starts
local INTERRUPTED = 28787

-------
-- @tparam table spec { kind, name, command, target_id, target_index } from manual_input.describe
function ManualAction.new(spec)
    local self = setmetatable(Action.new(0, 0, 0, spec.target_index, L{}), ManualAction)
    self.spec = spec
    self.manual = true
    self.act_exempt = true
    self.priority = ActionPriority.manual
    self.identifier = 'manual'
    self.dispose_bag = DisposeBag.new()
    return self
end

function ManualAction:destroy()
    if self.dispose_bag then self.dispose_bag:destroy(); self.dispose_bag = nil end
    Action.destroy(self)
end

function ManualAction:get_max_duration()
    return ManualAction.StartTimeout + ManualAction.FinishTimeout + 1
end

function ManualAction:perform()
    local me = windower.ffxi.get_player()
    local my_id = me and me.id
    self.started = false
    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        if self:is_completed() or act.actor_id ~= my_id then return end
        if START[act.category] then
            if act.param == INTERRUPTED then
                self:complete(false)
            else
                self.started = true
            end
        elseif FINISH[act.category] then
            self:complete(true)
        end
    end), WindowerEvents.Action)

    -- No start or finish in time: the game refused it (too far, recast, cannot act).
    coroutine.schedule(function()
        if not self:is_completed() and not self.started then
            if addon_system_message then
                addon_system_message('Trust: '..self.spec.name..' did not start.')
            end
            self:complete(false)
        end
    end, ManualAction.StartTimeout)
    coroutine.schedule(function()
        if not self:is_completed() then self:complete(false) end
    end, ManualAction.StartTimeout + ManualAction.FinishTimeout)

    windower.chat.input(self.spec.command)
end

function ManualAction:gettype()
    return "manualaction"
end

function ManualAction:getidentifier()
    return self.identifier
end

function ManualAction:is_equal(action)
    return action ~= nil and action.manual == true
end

function ManualAction:tostring()
    return self.spec.name..(self.spec.target_name and (' -> '..self.spec.target_name) or '')
end

return ManualAction
