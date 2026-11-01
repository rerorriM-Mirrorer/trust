local f=assert(io.open('cylibs/trust/roles/puller.lua'));local source=f:read('*a');f:close()
local shared=true;local store={revision=2}
local methods={}
local env=setmetatable({Puller=methods,state={AutoPullMode={value='Off'}},require=function(path)
    assert(path=='settings/shared_preferences');return{shared=function()return store end,enabled=function()return shared end}
end},{__index=_G})
local method=assert(source:match('(function Puller:tic.-)\nfunction Puller:'))
assert(load(method,'actual pull refresh','t',env))()
local raw={Targets={'legacy'},Distance=12}
local calls=0
local role={job_pull_settings=raw,shared_revision=1,shared_enabled=true,set_pull_settings=function(self,value)
    assert(value==raw);calls=calls+1;self.shared_revision=store.revision;self.shared_enabled=shared
end}
methods.tic(role);assert(calls==1)
methods.tic(role);assert(calls==1)
shared=false;methods.tic(role);assert(calls==2)
shared=true;methods.tic(role);assert(calls==3)
assert(source:find('self:set_pull_settings(self.job_pull_settings or self.pull_settings)',1,true),'mode change discarded the original legacy settings')
-- Actual root callback must reach the HUD player (the construction-local
-- mediaPlayer is not a global available to prerender).
local f=assert(io.open('Trust.lua'));local root=f:read('*a');f:close()
local callback
local enabled
local runtime=setmetatable({windower={register_event=function(_,fn)callback=fn end},hud={mediaPlayer={setEnabled=function(_,value)enabled=value end}},
    require=function(path)assert(path=='settings/shared_preferences');return{poll=function()return{Sounds={disabled=true}}end}end},{__index=_G})
local block=assert(root:match("(windower.register_event%('prerender', function%(%)%s*.-\nend%))"))
assert(load(block,'actual shared sound poll','t',runtime))();callback();assert(enabled==false)
print('PASS actual puller refresh: revisions/source changes refresh even while pulling Off, no redundant refresh, original legacy source retained')
