-- Aggressive engage mode: selector tiers, PartyTarget wiring, Act gate, and the
-- Aggro -> Defensive rename (real Modes library for legacy values).
local count = 0
local function check(v, label) count = count + 1; assert(v, label) end
local function list(t) return setmetatable(t, {__index={it=function(self) local i=0; return function() i=i+1; return self[i] end end}}) end
local function source(path) local f = assert(io.open(path)); local s = f:read('*a'); f:close(); return s end

-- Selector tiers.
local mobs, tracked = {}, {}
windower = {ffxi={get_mob_by_id=function(id) return mobs[id] end, get_mob_by_index=function(index)
    for _, m in pairs(mobs) do if m.index == index then return m end end
end, get_player=function() return mobs[1] end}}
local party_members = list({{get_mob=function() return mobs[1] end}, {get_mob=function() return mobs[2] end}, {get_mob=function() return mobs[3] end}})
local party = {get_party_members=function() return party_members end}
local tracker = {add_mob=function(_, id) tracked[id] = true end, get_targets=function()
    local result = {}; for id in pairs(tracked) do result[#result+1] = {get_mob=function() return mobs[id] end} end; return list(result)
end}
local function enemy(id, index, status)
    local m = {id=id, index=index, spawn_type=16, valid_target=true, hpp=100, status=status or 0, distance=100, claim_id=0}
    mobs[id] = m; return m
end
mobs[1] = {id=1, index=1, hpp=100, status=0}      -- me
mobs[2] = {id=2, index=2, hpp=100, status=0}      -- assist target (leader)
mobs[3] = {id=3, index=3, hpp=100, status=0}      -- another member
local Selector = require('cylibs/entity/party/aggro_target')
local s = Selector.new(party, tracker)
local a, b, c = enemy(10, 10), enemy(20, 20), enemy(30, 30, 1)
local A = {aggressive=true}
local idx, why = s:select(10, 0, {aggressive=true, assist_engaged=false})
check(idx == nil and why == 'no-threat', 'assist only targeting: nothing to join')
check(s:select(10, 0) == 10, 'Defensive still follows a targeted assist enemy')
idx, why = s:select(10, 0, {aggressive=true, assist_engaged=true})
check(idx == 10 and why == 'assist', 'assist engaged: join its enemy')
mobs[3].status, mobs[3].target_index = 1, 20
idx, why = s:select(10, 0, A)
check(idx == 20 and why == 'party', 'assist idle: join the enemy a party member fights')
mobs[2].status, mobs[2].target_index = 1, 30
idx = s:select(nil, 0, A)
check(idx == 20, 'stays on the chosen party fight')
mobs[3].status = 0
check(s:select(nil, 0, A) == 30, 'that fight over: another member\'s fight')
mobs[2].status = 0
c.target_index = 3; tracked[30] = true
idx, why = s:select(nil, 0, A)
check(idx == 30 and why == 'defense', 'no fights: an enemy attacking the party')
c.target_index = nil; tracked[30] = nil
check(s:select(nil, 0, A) == nil, 'nothing: no target')
mobs[3].status, mobs[3].target_index = 1, 20; b.claim_id = 99
check(s:select(nil, 0, A) == nil, 'foreign-claimed party fight rejected')
b.claim_id = 0; b.hpp = 0
check(s:select(nil, 0, A) == nil, 'dead enemy rejected')
b.hpp = 100

-- PartyTarget passes the mode and whether the assist target is engaged.
local pt = source('cylibs/entity/party/party_target.lua')
check(pt:find("local aggressive = state.AutoEngageMode and state.AutoEngageMode.value == 'Aggressive'", 1, true), 'Aggressive recognised')
check(pt:find("{ aggressive = aggressive, assist_engaged = assist_mob_self and assist_mob_self.status == 1 or false }", 1, true), 'assist engaged passed')
check(pt:find("(state.AutoEngageMode.value == 'Defensive' or state.AutoEngageMode.value == 'Aggressive')", 1, true), 'threat watching in both modes')

-- Act gate: party fights and threats open in both modes.
state = {AutoEngageMode={value='Aggressive'}}
windower.ffxi.get_player = function() return {status=0} end
local Gate = require('cylibs/trust/act_gate')
local gp = {get_assist_target=function() return {get_mob=function() return {status=0} end} end,
    get_party_members=function() return list({{get_mob=function() return {status=1} end}}) end, party_target={}}
check(Gate.trigger(gp) == 'party', 'Aggressive: party fight opens Act')
state.AutoEngageMode.value = 'Defensive'
check(Gate.trigger(gp) == 'party', 'Defensive: party fight opens Act')
state.AutoEngageMode.value = 'Mirror'
check(Gate.trigger(gp) == nil, 'Mirror: party fight alone does not')

-- Rename with legacy values (real Modes).
local methods = {}
function methods:flatten() local r = L(); for _, v in ipairs(self) do r[#r+1] = v end; return r end
function methods:map(f) local r = L(); for _, v in ipairs(self) do r:append(f(v)) end; return r end
function methods:append(v) self[#self+1] = v end
function methods:contains(v) for _, x in ipairs(self) do if x == v then return true end end return false end
L = function(t) return setmetatable(t or {}, {__index=methods}) end
T, S = L, L
package.preload.sets = function() return {} end
require('cylibs/util/Modes')
local m = M{['description']='Auto Engage Mode', 'Always', 'Off', 'Mirror', 'Defensive', 'Aggressive'}
m.legacy_values = {aggro='Defensive'}
m:set('Aggro'); check(m.value == 'Defensive', 'saved Aggro becomes Defensive')
m:set('aggressive'); check(m.value == 'Aggressive', 'Aggressive settable')
local opts = {}; for _, v in ipairs(m:options()) do opts[#opts+1] = v end
check(table.concat(opts, ',') == 'Always,Off,Mirror,Defensive,Aggressive', 'legacy map not listed as an option')
local at = source('cylibs/trust/roles/attacker.lua')
check(at:find("state.AutoEngageMode.legacy_values = { aggro = 'Defensive' }", 1, true), 'attacker declares the rename')
check(not at:find("'Aggro'", 1, true), 'no Aggro value left in attacker')
check(source('Trust.lua'):find("local legacy = rawget(state_var, 'legacy_values')", 1, true), 'profile load maps legacy values')
print('Aggressive: ' .. count .. ' checks passed')
