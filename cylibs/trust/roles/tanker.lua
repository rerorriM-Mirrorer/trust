---------------------------
-- Fork addition: Tanker role. While Auto Tank Mode is Auto and this character is engaged,
-- it pulls loose enemies (ones attacking another party member) back onto itself:
--   two or more loose enemies close together, nothing else nearby -> Banishga
--   otherwise, the enemy hitting the lowest-HP party member -> Flash, else Provoke
--   (WAR subjob), else Banish II, else Banish
-- "Party" includes alter egos (trusts) and every party member's pet.
-- It never moves and never changes the engaged target: spells and abilities are aimed at
-- the loose enemy by index, so the tank stays on the party leader's target. Each enemy is
-- left alone for a few seconds after an attempt. Decisions live in cylibs/util/tank_util.lua.
-- First version: added to PLD only (cylibs/trust/data/PLD.lua). Provoke needs a WAR subjob.
-- @class module
-- @name Tanker

local tank_util = require('cylibs/util/tank_util')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Tanker = setmetatable({}, { __index = Gambiter })
Tanker.__index = Tanker
Tanker.__class = "Tanker"

function Tanker.new(action_queue)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoTankMode }), Tanker)
    self.action_queue = action_queue
    self.recent = {}
    self.abilities = {
        Banishga = Spell.new('Banishga', L{}, L{}),
        Flash = Spell.new('Flash', L{}, L{}),
        Provoke = JobAbility.new('Provoke', L{}, L{}),
        ['Banish II'] = Spell.new('Banish II', L{}, L{}),
        Banish = Spell.new('Banish', L{}, L{}),
    }
    return self
end

function Tanker:get_type()
    return "tanker"
end

function Tanker:allows_duplicates()
    return false
end

function Tanker:allows_multiple_actions()
    return false
end

function Tanker:get_cooldown()
    return 1
end

function Tanker:get_priority()
    return ActionPriority.medium
end

-- Known, off cooldown, and (for spells) enough MP.
function Tanker:is_ready(name, player)
    local ability = self.abilities[name]
    if ability == nil or not ability:is_valid() then
        return false
    end
    if not Condition.check_conditions(ability:get_conditions(), player.index) then
        return false
    end
    if ability.get_spell then
        local spell = ability:get_spell()
        if spell and spell.mp_cost and player.vitals and player.vitals.mp < spell.mp_cost then
            return false
        end
    end
    return true
end

-- Snapshot of what tank_util needs from the game.
function Tanker:get_context(player)
    local me = windower.ffxi.get_mob_by_index(player.index)
    if me == nil then
        return nil
    end
    local party = {}
    for key, member in pairs(windower.ffxi.get_party()) do
        if type(member) == 'table' and type(key) == 'string' and key:match('^p%d$') and member.mob then
            party[member.mob.index] = { id = member.mob.id, hpp = member.hpp }
            -- Pets count too: an enemy hitting Myrr's avatar or a puppet is loose.
            local pet = member.mob.pet_index and windower.ffxi.get_mob_by_index(member.mob.pet_index)
            if pet and pet.hpp and pet.hpp > 0 then
                party[pet.index] = { id = pet.id, hpp = pet.hpp }
            end
        end
    end
    local mobs = {}
    for _, mob in pairs(windower.ffxi.get_mob_array()) do
        if mob.spawn_type == 16 then
            mobs[#mobs + 1] = mob
        end
    end
    return { me = me, party = party, mobs = mobs, max_range = tank_util.FlashRange + 1 }
end

function Tanker:check_gambits()
    if not self:is_enabled() or (os.clock() - self.last_gambit_time) < self:get_cooldown() then
        return
    end
    if self.action_queue.pull_action or self.action_queue:has_action(self:get_action_identifier()) then
        return
    end
    local player = windower.ffxi.get_player()
    if player == nil or player.status ~= 1 then
        return -- only while engaged
    end
    local ctx = self:get_context(player)
    if ctx == nil then
        return
    end
    local ready = {}
    for name, _ in pairs(self.abilities) do
        ready[name] = self:is_ready(name, player)
    end
    local now = os.clock()
    local choice = tank_util.choose(ctx, ready, self.recent, now)
    if choice == nil then
        return
    end
    self:perform_choice(choice, now)
end

function Tanker:perform_choice(choice, now)
    local target_index, target_id = choice.target.index, choice.target.id
    local action = self.abilities[choice.name]:to_action(target_index, self:get_player())
    if action == nil then
        return
    end
    for _, mob in ipairs(choice.marks) do
        self.recent[mob.id] = now
    end
    self.last_gambit_time = now
    action.priority = self:get_priority()
    action.identifier = self:get_action_identifier()
    -- Re-check just before it fires: the enemy must still exist and not be attacking us
    -- already (another party member may have pulled it, or it died).
    action.validate = function()
        if not self:is_enabled() then return false end
        local mob = windower.ffxi.get_mob_by_index(target_index)
        local p = windower.ffxi.get_player()
        return mob ~= nil and mob.id == target_id and (mob.hpp or 0) > 0
            and p ~= nil and mob.target_index ~= p.index
    end
    if logger.isEnabled then
        logger.notice(self.__class, 'perform_choice', choice.name, choice.target.name or target_index)
    end
    self.action_queue:push_action(action, true)
end

return Tanker
