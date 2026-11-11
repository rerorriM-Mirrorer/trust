local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local methods={}
function L(t)return setmetatable(t or {},{__index={length=function(s)return #s end,filter=function(s,f)local r=L{};for _,v in ipairs(s)do if f(v)then r[#r+1]=v end end;return r end}})end
local src=source('cylibs/entity/party_member.lua')
local env=setmetatable({PartyMember=methods},{__index=_G})
for _,name in ipairs({'get_num_songs','get_songs','get_max_num_songs','has_song'})do
 local body=assert(src:match('(function PartyMember:'..name..'%(.-)\nfunction PartyMember:'))
 assert(load(body,nil,'t',env))()
end
local Bard={}
local isMain=false
local brd=source('cylibs/entity/jobs/BRD.lua')
assert(load(assert(brd:match('(function Bard:get_max_num_songs.-)\nfunction Bard:get_song_buff_ids')),nil,'t',setmetatable({Bard=Bard},{__index=_G})))()
local job=setmetatable({max_num_songs=2,gear_swap_enabled=false,isMainJob=function()return isMain end,getLevel=function()return 30 end,is_clarion_call_active=function()return false end,get_song_buff_ids=function()return L{1}end},{__index=Bard})
local songs=L{{get_expire_time=function()return os.time()+10 end}}
local singer={job=job,song_tracker={expiring_duration=60,
 get_num_songs=function()return 1 end,get_songs=function()return songs end,get_max_num_songs=function()return job:get_max_num_songs(false,1) end,has_song=function(_,_,id)return id==123 end}}
local main,sub=nil,singer
player={trust={main_job={role_with_type=function()return main end},sub_job={role_with_type=function()return sub end}}}
local member=setmetatable({get_id=function()return 1 end,get_buff_ids=function()return L{1}end},{__index=methods})
assert(member:get_max_num_songs()==1,'BRD sub capacity incorrectly zero')
assert(member:get_num_songs()==1 and member:get_num_songs(true)==1 and member:get_songs()==songs and member:has_song(123))
-- Exercise the production capacity gate for the first/second/third songs.
local Gate={};local s=source('cylibs/conditions/max_num_songs.lua')
windower={ffxi={get_mob_by_index=function()return{id=1}end}}
player.party={get_party_member=function()return member end}
assert(load(assert(s:match('(function MaxNumSongsCondition:is_satisfied.-)\nfunction MaxNumSongsCondition:get_config_items')),nil,'t',setmetatable({MaxNumSongsCondition=Gate},{__index=_G})))()
for n=1,3 do
 local gate=setmetatable({num_songs=n,operator='>=',eval=function(_,a,b)return a>=b end},{__index=Gate})
 assert(gate:is_satisfied(1)==(n==1))
end
local Expiring={};s=source('cylibs/conditions/num_expiring_songs.lua')
assert(load(assert(s:match('(function NumExpiringSongsCondition:is_satisfied.-)\nfunction NumExpiringSongsCondition:get_config_items')),nil,'t',setmetatable({NumExpiringSongsCondition=Expiring},{__index=_G})))()
local expiry=setmetatable({num_required=1,operator='>=',eval=function(_,a,b)return a>=b end},{__index=Expiring})
assert(expiry:is_satisfied(1),'BRD sub refresh cannot see expiring songs')
isMain=true;main=singer;sub=nil;assert(member:get_max_num_songs()==2 and expiry:is_satisfied(1))
main=nil;assert(member:get_max_num_songs()==0 and not member:has_song(123) and not expiry:is_satisfied(1))
player=nil;assert(require('cylibs/util/singer_util').get_singer()==nil)
print('PASS main/sub Singer resolution, one-song sub capacity, later-slot exclusion, tracking/refresh and lifecycle absence')
