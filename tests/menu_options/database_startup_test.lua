-- Real ORM with mocked SQLite/Windower; exercise absent-data startup.
package.loaded['cylibs/events/Luvent']={}
package.loaded['files']={create_path=function()end}
package.loaded['cylibs/util/localization_util']={}
local exists,opens,closes,fail=false,0,0,false
windower={dir_exists=function()return exists end,create_dir=function(path)
    assert(path=='addon/data');exists=true
end,ffxi={get_player=function()return {name='Killala'}end},
trust={get_temp_dir=function()return 'missing-temp' end}}
package.loaded['sqlite3']={open=function(path)
    opens=opens+1;assert(exists and path=='addon/data/settings.db')
    if fail then return nil,14,'unable to open database file' end
    return {close=function()closes=closes+1 end}
end}
local ORM=require('cylibs/database/orm/orm').ORM
local db=ORM.new('addon/data','settings.db')
assert(exists and opens==1 and db.db)
db:close();db:destroy();assert(closes==1,'cleanup must be idempotent')
fail=true
local ok,err=pcall(ORM.new,'addon/data','settings.db')
assert(not ok and err:find('addon/data/settings.db',1,true) and err:find('14',1,true))
local old=io.open
io.open=function()return nil end
ok,err=pcall(ORM.new,'resources','resources.db',true)
io.open=old
assert(not ok and err:find('resources/resources.db',1,true) and opens==2,
    'missing seed must fail before SQLite can create an empty resource database')
local f=assert(io.open('Trust.lua'));local root=f:read('*a');f:close()
assert(root:find("local temp_dirs = L{\n\t\twindower.addon_path..'data',",1,true))
print('PASS database startup: missing parent, explicit open failure, seed failure and repeated cleanup')
