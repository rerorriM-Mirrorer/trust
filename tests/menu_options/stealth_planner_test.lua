local P=require('cylibs/trust/stealth/planner')
local checks=0
local function check(v,m) checks=checks+1;assert(v,m) end
local function member(name,caps,x)
 return {name=name,ready=true,caps=caps or {},x=x or 0,y=0,z=0,zone=1}
end
local a,b,c=member('Alice',{s=true,i=true}),member('Bob'),member('Cleo',{o=true,p=true})
local members={a,b,c}
local attempt={}
local choice=P.next(members,'sneak',attempt)
check(choice.code=='s','magic before oil')
for _,v in ipairs(members)do v.sneak=true end
check(P.next(members,'sneak',{})==nil,'skip existing Sneak')
choice=P.next(members,'invisible',{})
check(choice.provider=='Alice' and choice.target=='Bob','caster covers another first')
b.invisible=true;c.invisible=true
choice=P.next(members,'invisible',{})
check(choice.target=='Alice','caster self last')
a.invisible=true
check(P.next(members,'invisible',{})==nil,'already covered produces no work')
a.invisible=false;b.invisible=false;c.invisible=false
b.x=30;c.x=30
choice=P.next(members,'invisible',{})
check(choice.target=='Alice','out of range targets never approached')
a.caps={};a.ready=false
choice=P.next(members,'invisible',{})
check(choice.provider=='Cleo' and choice.code=='p','self item fallback')
attempt[choice.key]=true
check(P.next(members,'invisible',attempt)==nil,'bounded attempts, no retry loop')
c.caps={j=true,o=true,p=true};c.sneak=false
choice=P.next(members,'sneak',{})
check(choice.code=='j','Jig before consuming oil')
c.sneak=true
choice=P.next(members,'invisible',{})
check(choice.code=='p','Jig never used with Sneak already active')
c.invisible=true;c.sneak=false
check(P.next(members,'sneak',{})==nil,'preserve existing Invisible instead of stripping it with oil')
a.ready=true;a.caps={as=true,ai=true,s=true,i=true};a.x=0;b.x=2;c.x=3
c.invisible=false;b.sneak=false
choice=P.next(members,'sneak',{})
check(choice.code=='as' and choice.target=='Alice','Accession when multiple missing are nearby')
c.x=12
choice=P.next(members,'sneak',{})
check(choice.code=='s','single casts when area cannot cover remaining targets')
c.x=3;c.zone=2
choice=P.next(members,'sneak',{})
check(choice.code=='s','different zone prevents area planning')
c.zone=1;b.aborted=true;c.aborted=true
choice=P.next(members,'invisible',{})
check(choice and choice.target=='Alice' and choice.code=='i','manual cancellation excludes recipients and area')
a.invisible=true
check(P.next(members,'invisible',{})==nil,'cancelled targets not reassigned')
check(#P.missing(members,'invisible')==2,'partial coverage retains names')
a=member('Alice',{s='wait'});b=member('Bob',{o=true});c=member('Cleo',{s=true})
choice=P.next({a,b},'sneak',{})
check(choice.wait and choice.code=='s','normal magic recast takes priority over items')
choice=P.next({a,b,c},'sneak',{})
check(choice.provider=='Cleo' and not choice.wait,'another ready caster avoids unnecessary wait')
print('stealth planner: '..checks..' checks')
