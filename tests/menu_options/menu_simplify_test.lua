-- Exercise actual settings construction and job routing without renderer/game.
local f=assert(io.open('ui/TrustHud.lua'));local source=f:read('*a');f:close()
local methods={}
local list={}
function list:append(v)self[#self+1]=v;return self end
function list:sort()return self end
function list:filter(fn)local result=setmetatable({},{__index=list});for _,v in ipairs(self)do if fn(v)then result:append(v)end end;return result end
local function L(t)return setmetatable(t or {},{__index=list})end
local function node(buttons,children)
    return {buttons=buttons,children=children or {},
        setConfigKey=function()end,destroy=function(self)self.dead=true end,
        getChildMenuItem=function(self,k)return self.children[k]end,
        setChildMenuItem=function(self,k,v)self.children[k]=v end}
end
local generic={new=function()return node()end}
generic.disabled=generic.new
local layout='Condensed'
local env=setmetatable({TrustHud=methods,L=L,
    Frame=generic,ModesMenuItem=generic,ConfigSettingsMenuItem=generic,
    MenuPreferences={layout=function()return layout end},
    GambitSettingsMenuItem=generic,JobGambitSettingsMenuItem=generic,ReactionSettingsMenuItem=generic,
    ButtonItem={default=function(k)return k end,localized=function(k)return k end},
    MenuItem={new=node},T=function()return{keyset=function()return{}end}end,
    state={MainTrustSettingsMode={},SubTrustSettingsMode={},WeaponSkillSettingsMode={}},
    i18n={translate=function(k)return k end,resource=function(_,_,k)return k end},
    res={jobs={with=function(_,_,job)return {en=job}end}},require=function()return generic end,
    player={main_job_name='Bard',sub_job_name='White Mage',main_job_name_short='BRD',sub_job_name_short='WHM',trust={main_job={role_with_type=function()return{}end},sub_job={role_with_type=function()return nil end}}},
    main_trust_settings={},sub_trust_settings={},weapon_skill_settings={},trust_mode_settings={}}, {__index=_G})
for _,name in ipairs({'getSettingsMenuItem','reloadJobMenuItems','getMainMenuItem'}) do
    local body=assert(source:match('(function TrustHud:'..name..'%(.-)\nfunction TrustHud:'))
    assert(load(body,'actual '..name,'t',env))()
end
local job={role_with_type=function()return nil end}
local hud=setmetatable({getStatusMenuItem=function()return node()end},{__index=methods})
hud.getFollowerMenuItem=function()return node()end
hud.getTrusterMenuItem=hud.getFollowerMenuItem
hud.getPatherMenuItem=hud.getFollowerMenuItem
local settings=hud:getSettingsMenuItem(job,{}, {},nil,nil,{},'BRD')
assert(settings.buttons[#settings.buttons]=='Modes','all modes must be last')
assert(not settings.children.Status and settings.children.Gambits)
assert(not settings.children.Following and not settings.children.Paths and not settings.children['Alter Egos'])
assert(settings.children.Food and settings.children.Pulling and settings.children.Modes)
assert(settings.children.Gambits.buttons[1]=='BRD' and settings.children.Gambits.buttons[2]=='Custom')
local subSettings=hud:getSettingsMenuItem(job,{},env.state.SubTrustSettingsMode,nil,nil,{},'WHM')
assert(not subSettings.children.Food and not subSettings.children.Pulling and not subSettings.children.Modes)
local pullingOwner
env.player.trust.sub_job.role_with_type=function(_,name)if name=='puller' then return {}end end
hud.getMenuItemForRole=function(_,role,ws,wsm,trust,jobName,view,owner,mode)
    pullingOwner={owner,mode,jobName};return node()
end
hud:getSettingsMenuItem(job,{},env.state.MainTrustSettingsMode,nil,nil,{},'BRD')
assert(pullingOwner[1]==env.sub_trust_settings and pullingOwner[2]==env.state.SubTrustSettingsMode and pullingOwner[3]=='WHM')
env.player.trust.sub_job.role_with_type=function()return nil end
local calls={}
hud.mainMenuItem=node()
hud.getSettingsMenuItem=function(_,trust,owner,mode,ws)
    calls[#calls+1]={trust,owner,mode,ws};return node()
end
hud:reloadJobMenuItems()
assert(calls[1][2]==env.main_trust_settings and calls[1][4]==env.weapon_skill_settings)
assert(calls[2][2]==env.sub_trust_settings and calls[2][4]==nil)
assert(hud.mainMenuItem.children.Bard and hud.mainMenuItem.children['White Mage'])
assert(hud.mainMenuItem.children.Following and hud.mainMenuItem.children.Paths and hud.mainMenuItem.children['Alter Egos'])
layout='Full'
local fullSettings=methods.getSettingsMenuItem(hud,job,{}, {},nil,nil,{},'BRD')
assert(fullSettings.buttons[1]=='Modes' and not fullSettings.children.Status)
local fullSub=methods.getSettingsMenuItem(hud,job,{},env.state.SubTrustSettingsMode,nil,nil,{},'WHM')
assert(not fullSub.children.Modes and not fullSub.children.Food and not fullSub.children.Pulling)
local fullCalls=0
hud.getMenuItems=function()fullCalls=fullCalls+1;return node({'Status','Settings','Help','Donate','Discord'})end
hud.mainMenuItem=node()
hud:reloadJobMenuItems()
assert(fullCalls==2 and hud.mainMenuItem.children.Bard.children.Status)
assert(not hud.mainMenuItem.children.Following,'Full duplicated character tools at root')
hud.trustMenu={isVisible=function()return false end}
hud.mainMenuItem=nil
local fullRoot=hud:getMainMenuItem()
assert(fullRoot.children.Commands and fullRoot.buttonItems[4]=='Commands')
layout='Condensed'
local condensedRoot=hud:getMainMenuItem()
assert(condensedRoot~=fullRoot and fullRoot.dead and not condensedRoot.children.Commands)
assert(condensedRoot.children.Following and hud.menuLayout=='Condensed')
print('PASS direct job settings routing, correct owners and Modes-last ordering')
