program ogedit;
uses crt,vaf_unit;

const MAXOGGETTI=500;
      COLORMASK=15*16;
      SFONDOMASK=15;

type oggetto=record
               stanza:integer; {dove si trova inizialmente}
               livello:byte;   {su che livello}
               posx,posy:byte; {in che punto (alto a sx.)}
               dimx,dimy:integer; {quanto e' grosso}
               disegno:array[0..50] of byte; {il suo disegno}
               nome:string[20]; {il suo nome}
             end;
     oggetti_tipo=array[0..MAXOGGETTI] of oggetto;
     screen=array[1..8000] of byte;

var video,frame:^screen;
    cmd:char; {comando}
    x,y:byte; {posizione cursore}
    colore,sfondo:byte;
    moved:boolean;
    obj:^oggetti_tipo;
    objfile:file of oggetti_tipo;
    filename:string;
    object_number:integer;
    file_opened:boolean;


function itos(val:integer):string;
var s:string;
begin
 str(val,s);
 itos:=s;
end;

procedure splat(c:boolean);
begin
  move(frame^,video^,8000);
  if c then swritexy(x,y,7,16,'+',video^);{gotoxy(x,y);}
  swritexy(68,49,7,0,itos(x),video^);
  swritexy(71,49,7,0,itos(y),video^);
  swritexy(57,49,7,0,itos(object_number),video^);
  swritexy(9,49,7,0,obj^[object_number].nome,video^);
  swritexy(11,47,7,0,itos(obj^[object_number].stanza),video^);
  swritexy(27,47,7,0,itos(obj^[object_number].livello),video^);
  swritexy(45,47,7,0,itos(obj^[object_number].posx),video^);
  swritexy(48,47,7,0,itos(obj^[object_number].posy),video^);
  swritexy(66,47,7,0,itos(obj^[object_number].dimx),video^);
  swritexy(68,47,7,0,itos(obj^[object_number].dimy),video^);
end;

procedure disegna_oggetto(number:integer);
var h1,h2,rx,ry,ind2,ind3:integer;
begin
 with obj^[number] do
  begin
   h1:=1-dimx mod 2;h2:=1-dimy mod 2;
   rx:=posx-dimx div 2+h1;
   ry:=posy-dimy div 2+h2;
   for ind2:=0 to dimy-1 do
     for ind3:=0 to 2*dimx-1 do
       if disegno[dimx*2*ind2+ind3]<>255 then
        begin
         frame^[160*(ry+ind2-1)+2*(rx-1)+ind3+1]:=
           disegno[dimx*2*ind2+ind3];
         {mouse_map^[80*(y+ind2-1)+x+ind3 div 2]:=
         stanzoggetto^[indice_stanza,ind1];}
        end;
  end;
end;




procedure maschera;
 begin
  swritexy(1,42,7,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,43,7,0,'| Apri file | Salva file | Carica oggetto | saLva oggetto | tRasparenza     |',frame^);
  swritexy(1,44,7,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,45,7,0,'| CR: disegna [NO] | ''+'',''-'': colore | ''*'',''/'': sfondo | cattUra | sPeciale |',frame^);
  swritexy(1,46,7,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,47,7,0,'| sTanza [   ] | lIvello [   ] | posiZione [  ,  ] | Dimensioni [ , ] | Help|',frame^);
  swritexy(1,48,7,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,49,7,0,'| Nome [                    ] |''.'',''0'': numero Oggetto [   ] |    [  ,  ]   |',frame^);
  swritexy(1,50,7,0,'+                                                                           |',frame^);
 end;

procedure clear;
var i:integer;
 begin
  for i:=1 to 8000 do frame^[i]:=0;
 end;

procedure vuota_obj;
var i:integer;
 begin
  for i:=1 to MAXOGGETTI do
  with obj^[i] do
    begin
      stanza:=0;
      livello:=0;
      posx:=0;
      posy:=0;
      dimx:=0;
      dimy:=0;
      nome:='';
    end;
 end;

procedure raccogli_input;
 begin
  cmd:=readkey;
 end;

procedure esegui;
var j,h,k,x1,x2,y1,y2:integer;
    ch:char;

 begin
  moved:=cmd in ['8','2','4','6'];
  case cmd of
   'h': begin swritexy(3,50,7,0,'niente help...',video^); ch:=readkey; end;
   '8': if y>1 then dec(y);
   '2': if y<41 then inc(y);
   '4': if x>1 then dec(x);
   '6': if x<80 then inc(x);
   chr(13): begin
        swritexy(16,45,7,0,'SI',frame^);
        repeat
         splat(moved);
         ch:=readkey;
         if ch=chr(13) then swritexy(16,45,7,0,'NO',frame^)
          else begin
                 swritexy(x,y,colore,sfondo,ch,frame^);
                 if x<80 then inc(x)
                         else if y<41 then begin x:=1; inc(y); end;
               end;
        until ch=chr(13);
       end;
   '+': begin colore:=(colore+17) mod 16; forecolor(x,y,x,y,colore,frame^); splat(moved); end;
   '-': begin colore:=(colore+15) mod 16; forecolor(x,y,x,y,colore,frame^); splat(moved); end;
   '*': begin sfondo:=(sfondo+17) mod 16; backcolor(x,y,x,y,sfondo,frame^); splat(moved); end;
   '/': begin sfondo:=(sfondo+15) mod 16; backcolor(x,y,x,y,sfondo,frame^); splat(moved); end;
   'a': begin
          swritexy(3,50,1,7,'nome del file?:',video^);
          textcolor(7);
          gotoxy(19,50);repeat readln(filename); until filename<>'';
          splat(moved);
          assign(objfile,filename);
          {$i-}
          reset(objfile);
          {$i+}
          if ioresult<>0 then
            begin
             swritexy(3,50,0,7,'File non trovato.',video^);
             ch:=readkey
            end
            else begin
                   read(objfile,obj^);
                   close(objfile);
                   swritexy(3,50,0,7,'File caricato.',video^);
                   file_opened:=true;
                   ch:=readkey;
                   clear;maschera;
                   object_number:=1;
                   disegna_oggetto(object_number);
                 end;
        end;
   's': begin
          swritexy(3,50,1,7,'nome del file?:',video^);
          textcolor(7);
          gotoxy(19,50);readln(filename);
          splat(moved);
          assign(objfile,filename);
          {$i-}
          rewrite(objfile);
          {$i+}
          if ioresult<>0 then
            begin
             swritexy(3,50,0,7,'File non salvato.',video^);
             ch:=readkey
            end
            else begin
                   write(objfile,obj^);
                   close(objfile);
                   swritexy(3,50,0,7,'File salvato.',video^);
                   ch:=readkey;
                 end;
        end;
   '.': begin
         if object_number<MAXOGGETTI then inc(object_number);
         clear;maschera;
         disegna_oggetto(object_number);
        end;
   '0': begin
         if object_number>1 then dec(object_number);
         clear;maschera;
         disegna_oggetto(object_number);
        end;
   't': begin
         swritexy(3,50,0,7,'nuova stanza?:',video^);
         textcolor(7);gotoxy(18,50);
         readln(obj^[object_number].stanza);
        end;
   'i': begin
         swritexy(3,50,0,7,'nuovo livello?:',video^);
         textcolor(7);gotoxy(19,50);
         readln(obj^[object_number].livello);
        end;
   'z': begin
         swritexy(3,50,0,7,'nuova pos.x:',video^);
         textcolor(7);gotoxy(16,50);
         readln(obj^[object_number].posx);
         maschera;splat(moved);
         swritexy(3,50,0,7,'nuova pos.y:',video^);
         textcolor(7);gotoxy(16,50);
         readln(obj^[object_number].posy);
         clear;maschera;disegna_oggetto(object_number);
        end;
   'u': begin
         swritexy(3,50,0,7,'vai al punto in alto a sn. e premi ENTER',video^);
         repeat
           ch:=readkey;
           moved:=true;
           case ch of
             '8': if y>1 then dec(y);
             '2': if y<41 then inc(y);
             '4': if x>1 then dec(x);
             '6': if x<80 then inc(x);
            end;
           splat(moved);
         until ch=chr(13);
         x1:=x;y1:=y;
         swritexy(3,50,0,7,'vai al punto in basso a dx. e premi ENTER',video^);
         repeat
           ch:=readkey;
           moved:=true;
           case ch of
             '8': if y>1 then dec(y);
             '2': if y<41 then inc(y);
             '4': if x>1 then dec(x);
             '6': if x<80 then inc(x);
            end;
           splat(moved);
         until ch=chr(13);
         x2:=x;y2:=y;
         obj^[object_number].dimx:=x2-x1+1;
         obj^[object_number].dimy:=y2-y1+1;
         for j:=0 to obj^[object_number].dimy-1 do
           for k:=0 to 2*obj^[object_number].dimx-1 do
             obj^[object_number].disegno[2*obj^[object_number].dimx*j+k]:=
               frame^[160*(y1+j-1)+2*(x1)+k-1];
        end;
   'n': begin
         swritexy(3,50,0,7,'nuovo nome?:',video^);
         textcolor(7);gotoxy(16,50);
         readln(obj^[object_number].nome);
        end;
   'o': begin
         swritexy(3,50,0,7,'nuovo indice di oggetto?:',video^);
         textcolor(7);gotoxy(29,50);
         readln(j);
         if (j>=1)and(j<=MAXOGGETTI) then object_number:=j;
         clear;maschera;disegna_oggetto(object_number);
        end;
   'p': begin
         swritexy(3,50,0,7,'inserisci il codice ascii:',video^);
         textcolor(7);gotoxy(30,50);
         readln(j);
         if (j>=1)and(j<=255) then swritexy(x,y,7,16,chr(j),frame^{[160*(y-1)+2*x-1]:=j});
        end;
   'r': begin
         for j:=0 to 1 do frame^[160*(y-1)+2*x-1+j]:=255;
        end;
  end;
 end;

begin
 textmode(CO80+FONT8x8);
 file_opened:=false;
 video:=ptr($B800,0);
 new(obj);new(frame);
 object_number:=1;
 vuota_obj;
 x:=1;y:=1;
 colore:=7;sfondo:=0;
 moved:=true;
 clear;
 maschera;
 repeat
   splat(moved);
   raccogli_input;
   esegui;
 until (cmd='Q')or(cmd='q');
end.