-- Compile without executing, normalizing only Windower quoted-string methods.
local count=0
for i=1,#arg do
    local path=arg[i]
    local f=assert(io.open(path)); local s=f:read('*a'); f:close()
    s=s:gsub('("[^"\n]*"):(%a+)%(',function(q,m) return '('..q..'):'..m..'(' end)
    s=s:gsub("('[^'\n]*'):(%a+)%(",function(q,m) return '('..q..'):'..m..'(' end)
    assert((loadstring or load)(s,'@'..path))
    count=count+1
end
print('PASS: '..count..' files compile on '.._VERSION..' (dialect normalization only)')

