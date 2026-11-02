import ctypes,ctypes.util,sqlite3,tempfile,os,re
from pathlib import Path
root=Path(__file__).resolve().parents[2]
lib=ctypes.CDLL(ctypes.util.find_library('lua5.4'));L=ctypes.c_void_p
lib.luaL_newstate.restype=L
for n,args in {'luaL_openlibs':[L],'luaL_loadbufferx':[L,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p], 'lua_pcallk':[L,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,L], 'lua_tolstring':[L,ctypes.c_int,L],'lua_tointegerx':[L,ctypes.c_int,L],'lua_pushinteger':[L,ctypes.c_longlong], 'lua_pushstring':[L,ctypes.c_char_p], 'lua_pushnil':[L], 'lua_setglobal':[L,ctypes.c_char_p], 'lua_close':[L]}.items():getattr(lib,n).argtypes=args
lib.lua_tolstring.restype=ctypes.c_char_p;lib.lua_tointegerx.restype=ctypes.c_longlong
C=ctypes.CFUNCTYPE(ctypes.c_int,L);lib.lua_pushcclosure.argtypes=[L,C,ctypes.c_int]
connections={};errors={};serial=0
callbacks=[]
def text(s,i):return lib.lua_tolstring(s,i,None).decode()
def number(s,i):return lib.lua_tointegerx(s,i,None)
def bind(state,name,fn):
 cb=C(fn);callbacks.append(cb);lib.lua_pushcclosure(state,cb,0);lib.lua_setglobal(state,name.encode())
def op_open(s):
 global serial
 try:
  db=sqlite3.connect(text(s,1),timeout=0,isolation_level=None);serial+=1;connections[serial]=db;lib.lua_pushinteger(s,serial)
 except Exception as e:lib.lua_pushnil(s)
 return 1
def op_exec(s):
 i=number(s,1)
 try:connections[i].execute(text(s,2));result=0
 except Exception as e:errors[i]=str(e);result=getattr(e,'sqlite_errorcode',1)
 lib.lua_pushinteger(s,result);return 1
def op_close(s):
 db=connections.pop(number(s,1),None)
 if db:db.close()
 return 0
def op_error(s):lib.lua_pushstring(s,errors.get(number(s,1),'unknown SQLite error').encode());return 1
def op_abandon(s):
 for db in connections.values():db.close()
 connections.clear();return 0
prelude='''package.preload.sqlite3=function()
 return {OK=0,open=function(path)
 local id=_sql_open(path);if not id then return nil end
 return {exec=function(_,sql)return _sql_exec(id,sql)end,close=function()_sql_close(id)end,
 errmsg=function()return _sql_error(id)end,busy_timeout=function(_,v)assert(v==0)end}
 end,test_abandon=function()_sql_abandon()end}
end
'''
def execute(state,code,name):
 data=code.encode();rc=lib.luaL_loadbufferx(state,data,len(data),name.encode(),None)
 if not rc:rc=lib.lua_pcallk(state,0,-1,0,0,None)
 if rc:raise RuntimeError(lib.lua_tolstring(state,-1,None).decode())
with tempfile.TemporaryDirectory() as tmp:
 for p in root.rglob('*.lua'):
  if '.git' in p.parts:continue
  target=Path(tmp)/p.relative_to(root);target.parent.mkdir(parents=True,exist_ok=True)
  target.write_text(re.sub(r'''('(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")(?=:\w+\s*\()''',r'(\1)',p.read_text()))
 os.chdir(tmp);state=lib.luaL_newstate();lib.luaL_openlibs(state)
 try:
  for name,fn in [('_sql_open',op_open),('_sql_exec',op_exec),('_sql_close',op_close),('_sql_error',op_error),('_sql_abandon',op_abandon)]:bind(state,name,fn)
  execute(state,prelude,'real SQLite bridge')
  execute(state,Path('tests/menu_options/shared_file_backend_test.lua').read_text(),'shared_file_backend_test.lua')
 finally:
  lib.lua_close(state)
  for db in connections.values():db.close()
print('PASS Lua production writer against actual host SQLite connections (LuaSQLite3 API bridge), FFI absent.')
