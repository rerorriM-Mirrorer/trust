"""Run the sender's actual decision branches after narrow AHK-to-JS translation.
This does not validate native AHK syntax or Windows input delivery.
"""
from pathlib import Path
import re,subprocess
root=Path(__file__).resolve().parents[2]
s=(root/'companions/xivcrossbar/movement_signal.ahk').read_text()
def decision(name,end):
 body=re.split(r'^'+name+r'\([^\n]*\) \{',s,maxsplit=1,flags=re.M)[1].split(end,1)[0]
 body=re.sub(r'^\s*;[^\n]*','',body,flags=re.M)
 body=re.sub(r'^\s*global[^\n]*','',body,flags=re.M)
 body=body.replace(' = ',' === ').replace(':=','=').replace(' and ',' && ').replace(' or ',' || ').replace(' . ',' + ')
 return body
poll=decision('MovementPoll','\n; Explicit leader').rsplit('}',1)[0]
send=decision('MovementSend','    title := ""')
leader=decision('MovementLeader','\nMovementSend(').rsplit('}',1)[0]
tick=decision('MovementTick','\nMovementPoll(').rsplit('}',1)[0]
js='''const assert=require('node:assert/strict');
let TM,PC={enabled:true},now=1000,activeWindow=1,ready=true,context='gameplay',supported=true,sends=[];
function DllCall(){return now} function WinActive(){return activeWindow}
function PersonalContext(){return context}
function MovementReceiverReady(){TM.takeoverSupported=supported;return ready}
function SendEvent(k){sends.push(k)} function MovementRelease(){TM.signalOwner=0}
function reset(){TM={client:0,fired:false,episode:false,neutralSince:0,signalOwner:0,threshold:.24,policy:'Send',sent:0};sends=[];activeWindow=1;ready=true;context='gameplay';supported=true;now=1000}
'''+f'function MovementPoll(states,active,observation=false){{let magnitude;{poll}}}\nfunction MovementTick(active){{{tick}}}\nfunction MovementSend(active,localOnly,leader=false){{{send}}}\nfunction MovementLeader(active){{{leader}}}\n'+'''
function poll(x,y=0){MovementPoll({moveX:x,moveY:y,HasOwnProp(k){return Object.hasOwn(this,k)}},activeWindow)}
function neutral(){poll(0);now+=100;poll(0)}
reset();MovementTick(1);poll(.5);assert.equal(sends.length,1);assert.match(sends[0],/sc07B/);
for(let i=0;i<100;i++){now+=10;MovementTick(1);poll(.5)}assert.equal(sends.length,1);
neutral();poll(.5);assert.equal(sends.length,2);assert.match(sends[1],/sc079/);
// Brief neutral or near-deadzone motion cannot rearm.
poll(0);now+=50;poll(0);poll(.5);assert.equal(sends.length,2);
poll(.18);now+=200;poll(.18);poll(.5);assert.equal(sends.length,2);
neutral();poll(.5);assert.equal(sends.length,3);
// Desktop does not reclassify same-client takeover as party handoff.
MovementTick(0);MovementTick(1);neutral();poll(.5);assert.match(sends[3],/sc079/);
// Different client keeps first-movement party handoff.
activeWindow=2;MovementTick(2);poll(.5);assert.match(sends[4],/sc07B/);
reset();MovementTick(1);TM.policy='Ready';ready=false;poll(.5);assert.equal(sends.length,0);
ready=true;context='menu';poll(.5);assert.equal(sends.length,0);
context='gameplay';poll(.5);assert.equal(sends.length,1);
neutral();supported=false;poll(.5);assert.equal(sends.length,1);
reset();MovementTick(1);ready=false;poll(.5);assert.equal(sends.length,1);poll(.5);assert.equal(sends.length,1);
neutral();MovementLeader(1);assert.match(sends.at(-1),/sc077/);assert.equal(TM.fired,true);
neutral();poll(.5);assert.match(sends.at(-1),/sc079/);
console.log('PASS actual sender decision branches: hold, neutral hysteresis, local-only repeat, focus change, Ready guards, Send once, older-receiver gate');
'''
subprocess.run(['node','-e',js],check=True)
# Lexical checks and current companion include/function closure.
files=list((root/'companions/xivcrossbar').glob('*.ahk'))
for p in files:
 text=p.read_text();stack=[];quoted=False;i=0
 while i<len(text):
  c=text[i]
  if c=='`':i+=2;continue
  if c=='"':quoted=not quoted
  elif not quoted:
   if c==';':
    end=text.find('\n',i);i=len(text) if end<0 else end;continue
   if c in '({[':stack.append(c)
   elif c in ')}]':assert stack and stack.pop()=={')':'(',']':'[','}':'{'}[c],(p,i)
  i+=1
 assert not quoted and not stack,p
controls=(root/'companions/xivcrossbar/personal_controls.ahk').read_text()
assert controls.index('if (!PC.ready)')<controls.index('MovementLeader(active)')<controls.index('return PersonalBanksPoll')
assert 'raw.mute and !PC.previous.mute and (mode = "gameplay" or mode = "crossbar")' in controls
combined='\n'.join(p.read_text() for p in files)
prefix=r'(?:Personal|ControllerMessage|Wrapper|Movement|InputTrace|InputTiming)\w+'
defs=re.findall(r'^('+prefix+r')\([^\n]*\) \{',combined,re.M)
assert len(defs)==len(set(defs))
assert set(re.findall(r'\b('+prefix+r')\(',combined))<=set(defs)
print('PASS six companion lexical checks and runtime helper closure; native AHK/Windows pending')
