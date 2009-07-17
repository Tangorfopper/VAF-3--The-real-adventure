program slowappear;
uses crt,dos;

const COLOR_MASK=15;BACK_MASK=15*16;

type Tfotogramma=array[1..6560] of byte;

var immagine,passo,old:Tfotogramma;
    schermo,step:file of Tfotogramma;
    i,j:integer;
    c,s:byte;
    fatto:boolean;
    stringa:string[3];
    video:^Tfotogramma;

function predec(iesimo:byte;colore:byte;foreground:boolean):byte;
begin
  if foreground then
   case colore of
    0:predec:=0;
    1,2,4,5:if iesimo>=1 then predec:=0 else predec:=colore;
    3:if iesimo=1 then predec:=1 else predec:=predec(iesimo-1,1,true);
    6:if iesimo=1 then predec:=4 else predec:=predec(iesimo-1,4,true);
    7:if iesimo=1 then predec:=8 else predec:=predec(iesimo-1,8,true);
    8:if iesimo=1 then predec:=0 else predec:=predec(iesimo-1,0,true);
    9:if iesimo=1 then predec:=3 else predec:=predec(iesimo-1,3,true);
    10:if iesimo=1 then predec:=2 else predec:=predec(iesimo-1,2,true);
    11:if iesimo=1 then predec:=9 else predec:=predec(iesimo-1,9,true);
    12:if iesimo=1 then predec:=6 else predec:=predec(iesimo-1,6,true);
    13:if iesimo=1 then predec:=5 else predec:=predec(iesimo-1,5,true);
    14:if iesimo=1 then predec:=10 else predec:=predec(iesimo-1,10,true);
    15:if iesimo=1 then predec:=7 else predec:=predec(iesimo-1,7,true);
   end
   else case colore of
         0:predec:=0;
         1,2,4:if iesimo>=1 then predec:=0 else predec:=colore;
         3:if iesimo=1 then predec:=2 else predec:=predec(iesimo-1,2,false);
         5:if iesimo=1 then predec:=1 else predec:=predec(iesimo-1,1,false);
         6:if iesimo=1 then predec:=4 else predec:=predec(iesimo-1,4,false);
         7:if iesimo=1 then predec:=0 else predec:=predec(iesimo-1,0,false);
        end;
 end;


begin
  if paramcount=0 then writeln('usage: slowapp filename')
  else begin
        video:=ptr($B800,0);
        textmode(CO80+FONT8X8);
        assign(schermo,paramstr(1));
        reset(schermo);
        read(schermo,immagine);
        close(schermo);
        for i:=1 to 6560 do passo[i]:=0;
        for i:=1 to 6560 do old[i]:=immagine[i];
        j:=1;
        repeat
         fatto:=true;
         for i:=1 to 6560 do
          if (i mod 2)=0 then
           begin
            c:=predec(j,immagine[i] and COLOR_MASK,true);
            s:=predec(j,(immagine[i] and BACK_MASK) div 16,false);
            passo[i]:=c or (s*16);
            fatto:=(fatto)and(passo[i]=old[i]);
           end
           else passo[i]:=immagine[i];
         if not fatto then
          begin
           str(j,stringa);
           assign(step,paramstr(1)+'.'+stringa);
           rewrite(step);
           write(step,passo);
           close(step);
           for i:=1 to 6560 do old[i]:=passo[i];
           for i:=1 to 6560 do video^[i]:=old[i];
           readkey;
          end;
         inc(j);
        until fatto;
        textmode(CO80);
       end;
end.
