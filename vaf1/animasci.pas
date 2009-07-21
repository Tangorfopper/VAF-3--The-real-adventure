unit animasci;

interface
uses dos,crt,smix;
procedure goascii(res: string);
function intdelay(val:longint):boolean;

const play='P';frame='F';sleep='S';typing='T';
      dropscreen='D';clearscreen='C';
      maxnumframe=20;
      maxnumsamples=16;
      larg=80;
      altezza=23;

type animation=array[1..altezza] of string[larg];
     mosse=array [1..maxnumframe] of animation;

implementation
var sounds:array[1..maxnumsamples] of psound;

procedure typer(s:string;x,y,soundindex,del:integer;var fast:boolean);
var i:integer;
    ok:byte;
    c:char;
begin
  if not fast then ok:=1
     else ok:=0;
  for i:=1 to length(s) do
    begin
      gotoxy(x-1+i,y);
      write(s[i]);
      if keypressed then ok:=0;
      if (soundindex<>0)and(ok=1) then
         begin
           stopsound(soundindex);
           startsound(sounds[soundindex],soundindex,false)
         end;
      delay(del*ok)
    end;
  if soundindex<>0 then stopsound(soundindex);
  if ok=0 then begin
                 if keypressed then c:=readkey;
                 fast:=true;
               end
          else fast:=false
end;

function intdelay(val:longint):boolean;
var {i:word;
    h1,m1,s1,s1001:word;
    h,m,s,s100:longint;
    totalwait:longint;
    actual,p:longint;
    wake:boolean;}
    counter:longint;
    c:char;

{begin
  gettime(h1,m1,s1,s1001);
  h:=h1;m:=m1;s:=s1;s100:=s1001;
  p:=s100 div 10;
  actual:=(p)+36000*h+600*m+10*s;
  wake:=val=0;
  totalwait:=0;
  while not wake do
    begin
      gettime(h1,m1,s1,s1001);
      h:=h1;m:=m1;s:=s1;s100:=s1001;
      p:=(s100 div 10);
      totalwait:=(p+36000*h+600*m+10*s)-actual;
      wake:=(totalwait>=val)or(keypressed)
    end;
  if keypressed then begin
                       c:=readkey;
                       intdelay:=true;
                     end
     else intdelay:=false;
end;}

begin
  counter:=1;
  if val>0 then
    begin
      repeat
        delay(10);
        inc(counter)
      until (keypressed)or(counter=10*val);
      if keypressed then begin
                           c:=readkey;
                           intdelay:=true
                         end
         else intdelay:=false;
    end
    else intdelay:=false;
end;

procedure goascii(res:string);

var anim:mosse;
    resource:text;
    delayval:word;
    command,ch:char;
    numframe,numsound:word;
    soundfile,animfile:string;
    fsanim:text;
    noanimation,nosnd,brk,loop:boolean;
    i,j,frameid,soundid,x,y,isound,d,overlay,shouldloop:integer;
    key,st:string;

begin
  noanimation:=false;
  nosnd:=false;
  assign(resource,res);
  reset(resource);
  readln(resource,numframe);
  if numframe>maxnumframe then numframe:=maxnumframe;
  readln(resource,animfile);
  if animfile='none' then noanimation:=true;
  if not noanimation then
    begin
      assign(fsanim,animfile);
      reset(fsanim);
      for i:=1 to numframe do
        for j:=1 to altezza do
          readln(fsanim,anim[i][j]);
      close(fsanim);
    end;
  readln(resource,numsound);
  if numsound>maxnumsamples then numsound:=maxnumsamples;
  readln(resource,soundfile);
  if soundfile='none' then nosnd:=true;
  if not nosnd then
    begin
      OpenSoundResourceFile(soundfile);
      for i:=1 to numsound do
         begin
           readln(resource,key);
           LoadSound(Sounds[i],key);
         end;
      CloseSoundResourceFile;
    end;
  {comincia l'animazione...}
  frameid:=1;
  repeat
    read(resource,command);
    case command of
      clearscreen:begin
                    clrscr;
                    readln(resource);
                  end;
      sleep:begin
              readln(resource,delayval);
              intdelay(delayval);
            end;
      play:begin
             read(resource,soundid);
             read(resource,overlay);
             read(resource,shouldloop);
             readln(resource,delayval);
             if overlay=0 then for i:=1 to maxnumsamples do stopsound(i);
             loop:=shouldloop<>0;
             startsound(sounds[soundid],soundid,loop);
             intdelay(delayval)
           end;
      frame:begin
              readln(resource,delayval);
              clrscr;
              for i:=1 to altezza do writeln(anim[frameid][i]);
              inc(frameid);
              intdelay(delayval);
            end;
      typing:begin
               read(resource,x);
               read(resource,y);
               read(resource,isound);
               readln(resource,d);
               readln(resource,st);
               brk:=false;
               typer(st,x,y,isound,d*10,brk)
             end;
      dropscreen:begin
                   read(resource,isound);
                   readln(resource,d);
                   if keypressed then ch:=readkey;
                   brk:=false;
                   for i:=1 to altezza do
                       typer(anim[frameid][i],1,i,isound,d*10,brk);
                   if brk then intdelay(10);
                   inc(frameid);
                 end
      else readln(resource);
    end;
  until (command='e')or(keypressed);
  for i:=1 to numsound do if sounds[i]<>nil then
      begin
        stopsound(i);
        freesound(sounds[i]);
      end;
  close(resource);
end;

end.