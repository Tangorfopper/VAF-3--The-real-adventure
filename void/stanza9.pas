program prova_stanza;
uses crt,dos,mouse,vaf_unit,types;
const MAXLIVELLI=5;
      MAXOGGETTI=500;

var salva:file of stanza;
    env:stanza;
    stanzano,posizione_livello,i,numlivelli,posinprov,posx,posy,ind1,ind2:integer;
    filedeglioggetti,filedellestanze,nomedelfiledellestanze,nomedelfiledeglioggetti,stanzanos,filo:string;
    video,schermo:^screen;
    h,tasto:char;
    uscita,saved,working:boolean;
    {allora: temporaneo contiene il lavoro in "prova",
             fatto contiene cosa e' ormai definitivo,
             schermo e' il puntatore alla memoria video,
             cio' che verra' salvato nel livello va in livello}
    obj:^oggetti_tipo;

procedure splat;
begin
  move(schermo^,video^,8000);
end;

procedure crea_maschera;
 begin
  swritexy(1,42,15,0,'+------------------------------------------------------------------------------+',schermo^);
  swritexy(1,43,15,0,'|   uovo  |  arica |       |        |       |     |     |       |    | Q quit  |',schermo^);
  swritexy(1,44,15,0,'+------------------------------------------------------------------------------+',schermo^);
  swritexy(1,45,15,0,'|                 |           |               |                |               |',schermo^);
  swritexy(1,46,15,0,'+------------------------------------------------------------------------------+',schermo^);
  swritexy(1,47,15,0,'|       |              |    |        |             |            |              |',schermo^);
  swritexy(1,48,15,0,'+------------------------------------------------------------------------------+',schermo^);
  swritexy(1,49,15,0,'|                                                                              |',schermo^);
  swritexy(1,50,15,0,'+------------------------------------------------------------------------------+',schermo^);
  swritexy(4,43,6,0,'N',schermo^);
  swritexy(13,43,6,0,'C',schermo^);
  swritexy(72,43,6,0,'Q',schermo^);
  swritexy(66,43,15,0,'Draw',schermo^);
  swritexy(66,43,6,0,'D',schermo^);
  if working then begin
                  swritexy(21,43,15,0,'Chiappa',schermo^);
                  swritexy(25,43,6,0,'p',schermo^);
                  swritexy(29,43,15,0,'Aggiungi',schermo^);
                  swritexy(29,43,6,0,'A',schermo^);
                  swritexy(38,43,15,0,'Elimina',schermo^);
                  swritexy(38,43,6,0,'E',schermo^);
                  swritexy(46,43,15,0,'Salva',schermo^);
                  swritexy(46,43,6,0,'S',schermo^);
                  swritexy(58,43,15,0,'Musica',schermo^);
                  swritexy(59,43,6,0,'u',schermo^);
                  str(env.backmusic,stanzanos);
                  swritexy(64,43,6,0,stanzanos,schermo^);
                  swritexy(3,45,15,0,'Visualizza move',schermo^);
                  swritexy(10,45,6,0,'z',schermo^);
                  swritexy(21,45,15,0,'Crea move',schermo^);
                  swritexy(28,45,6,0,'v',schermo^);
                  swritexy(52,43,15,0,'Reset',schermo^);
                  swritexy(52,43,6,0,'R',schermo^);
                  swritexy(33,45,15,0,'Setta livelli',schermo^);
                  swritexy(39,45,6,0,'l',schermo^);
                  swritexy(49,45,15,0,'Mostra livelli',schermo^);
                  swritexy(49,45,6,0,'M',schermo^);
                  swritexy(66,45,15,0,'Metti oggetto',schermo^);
                  swritexy(72,45,6,0,'o',schermo^);
                  swritexy(2,47,15,0,'Entrate',schermo^);
                  swritexy(4,47,6,0,'t',schermo^);
                  swritexy(10,47,15,0,'Mostra entrate',schermo^);
                  swritexy(14,47,6,0,'r',schermo^);
                  swritexy(25,47,15,0,'Gira',schermo^);
                  swritexy(25,47,6,0,'G',schermo^);
                  swritexy(30,47,15,0,'Adiacenz',schermo^);
                  swritexy(32,47,6,0,'i',schermo^);
                  swritexy(39,47,15,0,'Skala',schermo^);
                  swritexy(40,47,6,0,'k',schermo^);
                  str(stanzano,stanzanos);
                  swritexy(66,47,15,0,'STANZA NUM.: '+stanzanos,schermo^);
                  str(env.scala,stanzanos);
                  swritexy(44,47,15,0,'(ora:'+stanzanos+')',schermo^);
                  swritexy(54,47,15,0,'View gioco',schermo^);
                  swritexy(57,47,6,0,'w',schermo^);
                  end;
  splat;
 end;

procedure disegna_sfondo(da:array of byte;var dove:array of byte);
var ind1:integer;
{per ora... spiattella sul video il livello n_livello-esimo}
  begin
    for ind1:=0 to 6559 do
      begin
        if da[ind1]<>255
          then dove[ind1]:=da[ind1];
        {disegna gli oggetti del livello i}
      end;
  end;

procedure stampaschermo(inizio,fine:byte);
begin
for i:=inizio downto fine do
      disegna_sfondo(env.livs[i],schermo^);
end;

procedure qualestanzasiamo;
var caric:file of stanza;
begin
 assign(caric,filedellestanze);
 {$i-}
 reset(caric);
 {$i+}
 if ioresult<>0 then
                begin
                 swritexy(2,49,15,0,'NUOVO FILE DEGLI AMBIENTI (file room)',video^);
                 repeat until keypressed;
                 swritexy(2,49,15,0,'                             ',video^);
                 stanzano:=1;
                end
                else begin
                      stanzano:=filesize(caric)+1;
                      str(stanzano,stanzanos);
                      swritexy(2,49,15,0,'Questa sara'' la stanza numero:',video^);
                      swritexy(33,49,15,0,stanzanos,video^);
                      repeat until keypressed;
                      swritexy(2,49,15,0,'                                   ',video^);
                     end;
end;

procedure cambiascala(var scaladellastanza:byte);
var indicei:byte;
    scala:string;
begin
 repeat
  str(scaladellastanza,scala);
  swritexy(2,49,15,0,'Quale scala dell''omino? (0,1,2) attuale:'+scala+' ',video^);
  gotoxy(44,49);readln(indicei);if indicei<3 then scaladellastanza:=indicei;
  swritexy(2,49,6,0,'                                              ',video^);
 until indicei<3;
 str(scaladellastanza,stanzanos);
 swritexy(44,47,15,0,'(ora:'+stanzanos+')',schermo^);
end;

procedure settamusica(var musicadellastanza:byte);
var indicem:byte;
    musicas:string;
begin
 repeat
  swritexy(2,49,15,0,'Musica nella stanza? (0 non cambia musica, >0 tipo musica da suonare)',video^);
  gotoxy(75,49);readln(indicem);if indicem>=0 then musicadellastanza:=indicem;
  swritexy(2,49,6,0,'                                                            ',video^);
 until indicem>-1;
 str(indicem,musicas);
 swritexy(64,43,6,0,musicas,schermo^);
end;

procedure puliscivecchiocreanuovo;
var i,j,indicei:integer;
begin
 qualestanzasiamo;
 for i:=0 to 4 do
 for j:=1 to 8000 do
  env.livs[i][j]:=255;
 for i:=1 to 50 do
 for j:=1 to 80 do
  env.moveable[j][i]:=0;
 for i:=0 to 4 do
  env.levelpos[i]:=0;
  env.levelpos[0]:=42;
  env.levelpos[1]:=1;
 i:=1;
 while i<=8000 do begin schermo^[i]:=0; inc(i); end;
 crea_maschera;
 stampaschermo(env.n_livelli,0);
 repeat
  swritexy(2,49,15,0,'Numero dei livelli? (massimo 5)        ',video^);
  gotoxy(34,49);readln(indicei);env.n_livelli:=indicei;
  swritexy(2,49,6,0,'                                            ',video^);
 until indicei<6;
 for ind1:=1 to 4 do begin
                      swritexy(2,49,15,0,'Adiacenza',video^);
                      case ind1 of
                      1 : swritexy(12,49,15,0,'nord:',video^);
                      3 : swritexy(12,49,15,0,'est :',video^);
                      4 : swritexy(12,49,15,0,'sud :',video^);
                      2 : swritexy(12,49,15,0,'ovest:',video^);
                      end;
                      gotoxy(18,49);readln(indicei);env.adiacenza[ind1]:=indicei;
                      swritexy(2,49,6,0,'                            ',video^);
                     end;
 for ind1:=1 to 4 do begin
                      env.entrata[ind1].wx:=3;env.entrata[ind1].wy:=3;
                     end;
 swritexy(2,49,15,0,'Tutte le entrate inizializzate a 3,3',video^);
 repeat until keypressed;
 swritexy(2,49,15,0,'                                    ',video^);
 cambiascala(env.scala);
 settamusica(env.backmusic);
end;

procedure aggiungilivello;
var livindic:integer;
    filo:string;
    chief:file of byte;
begin
swritexy(2,49,6,0,'A quale livello devo inserire?',video^);
gotoxy(34,49);
readln(livindic);
swritexy(2,49,6,0,'                               ',video^);
if livindic>env.n_livelli then
                          begin
                          swritexy(2,49,6,0,'Livello non presente                     ',video^);
                          repeat until keypressed;
                            swritexy(2,49,6,0,'                                       ',video^);
                          end
else
swritexy(2,49,6,0,'Nome sfondo livello                ',video^);
gotoxy(30,49); readln(filo);
assign(chief,filo);
{$i-}
reset(chief);
{$i+}
if ioresult<>0 then
                begin
                 swritexy(2,49,6,0,'FILE NON TROVATO        ',video^);
                 repeat until keypressed;
                end
               else
                begin
                ind1:=1;
                while (ind1<=6560) and not eof(chief) do
                 begin
                       read(chief,env.livs[livindic][ind1]);
                       inc(ind1);
                 end;
                  close(chief);
                 end;
swritexy(2,49,6,0,'                              ',video^);
end;

procedure eliminalivello;
var j,livindic:integer;
    filo:string;
    chief:file of byte;
begin
swritexy(2,49,6,0,'Quale livello devo eliminare?',video^);
gotoxy(34,49);
readln(livindic);
swritexy(2,49,6,0,'                             ',video^);
if livindic>env.n_livelli then swritexy(2,49,6,0,'Livello non presente                          ',video^)
else
for j:=1 to 6560 do
  begin
   env.livs[livindic][j]:=255;
   schermo^[j]:=0;
  end;
end;

procedure salvaschermo;
begin
 assign(salva,filedellestanze);
 {$I-}
 reset(salva);
 {$I+}
 if ioresult<>0 then rewrite(salva);
 seek(salva,stanzano-1);
 write(salva,env);
 close(salva);
 saved:=true;
end;

procedure caricadadisco(numstanza:integer);
var caric:file of stanza;
begin
 assign(caric,filedellestanze);
 {$i-}
 reset(caric);
 {$i+}
 if ioresult<>0 then
 begin
  stanzano:=0;
  swritexy(2,49,6,0,'FILE NON TROVATO                            ',video^);
  repeat until keypressed;
  swritexy(2,49,6,0,'                                            ',video^);
 end
 else begin
       if numstanza<=filesize(caric) then
       begin
        seek(caric,numstanza-1);
        read(caric,env);
        close(caric);
       end
       else
       begin
        stanzano:=0;
        swritexy(2,49,6,0,'STANZA NON PRESENTE                                ',video^);
        repeat until keypressed;
        swritexy(2,49,6,0,'                             ',video^);
       end
 end;
end;

procedure caricaschermo;
var caricf:file of stanza;
    oggettif:file of oggetti_tipo;
    cambio:char;
    fileok:boolean;
begin
 swritexy(2,49,6,0,'Cambia file delle stanze (e degli oggetti)??(s/n)',video^);
 cambio:=readkey;
 if (cambio='s') or (cambio='S') then
 begin
  fileok:=true;
  repeat
  swritexy(2,49,6,0,'Nome del file delle stanze:                        ',video^);gotoxy(38,49);
  readln(nomedelfiledellestanze);
  assign(caricf,nomedelfiledellestanze);
  {$i-}
  reset(caricf);
  {$i+}
  if ioresult<>0 then begin
                       swritexy(2,49,6,0,'FILE NON TROVATO (continua?(s/n))        ',video^);
                       cambio:=readkey;
                       if (cambio<>'s') and (cambio<>'S')then
                       fileok:=false
                       else fileok:=true;
                      end
  else begin
       close(caricf);
       fileok:=true;
       end;
  until fileok;
  filedellestanze:=nomedelfiledellestanze;
  fileok:=true;
  repeat
  swritexy(2,49,6,0,'Nome del file deglioggetti:                        ',video^);gotoxy(38,49);
  readln(nomedelfiledeglioggetti);
  assign(oggettif,nomedelfiledeglioggetti);
  {$i-}
  reset(oggettif);
  {$i+}
  if ioresult<>0 then begin
                       swritexy(2,49,6,0,'FILE NON TROVATO (continua?(s/n))        ',video^);
                       cambio:=readkey;
                       if (cambio<>'s') and (cambio<>'S')then
                       fileok:=false
                       else fileok:=true;
                      end
  else begin
       close(oggettif);
       fileok:=true;
       end;
  until fileok;
  filedeglioggetti:=nomedelfiledeglioggetti;
 end;
 swritexy(2,49,6,0,'Numero della stanza?                        ',video^);
 gotoxy(34,49);
 readln(stanzano);
 swritexy(2,49,6,0,'                                   ',video^);
 caricadadisco(stanzano);
 i:=1;
 while i<=8000 do begin schermo^[i]:=0; inc(i); end;
 crea_maschera;
 stampaschermo(env.n_livelli,0);
 str(stanzano,stanzanos);
 swritexy(79,47,15,0,stanzanos,schermo^);
 str(env.scala,stanzanos);
 swritexy(44,47,15,0,'(ora:'+stanzanos+')',schermo^);
 splat;
end;

procedure settalivello;
var livindic:integer;
    segno,conta:string;
    contatore,j,linea:integer;
begin
 segno:='';
 for contatore:=0 to 4 do
 begin
  str(contatore,conta);
  segno:=segno+conta+'[';
  str(env.levelpos[contatore],conta);
  segno:=segno+conta+']';
 end;
 swritexy(2,49,6,0,segno+' Livello da settare?',video^);
 gotoxy(54,49);
 readln(livindic);
 swritexy(2,49,6,0,'                                                       ',video^);
 if (livindic>env.n_livelli) then
                              begin
                               swritexy(2,49,6,0,'Livello non presente                       ',video^);
                               repeat until keypressed;
                               swritexy(2,49,6,0,'                                           ',video^);
                              end
 else
 if livindic=0 then begin
                     env.levelpos[livindic]:=42;
                     swritexy(2,49,6,0,'Settato livello 0                ',video^);
                     delay(1000);
                    end
 else
 begin
  str(livindic,segno);
  linea:=1;
  for j:=1 to 80 do
  swritexy(j,linea,13,0,segno,video^);
  repeat
   swritexy(2,49,6,0,'+ aumenta | - diminuisce | o esce',video^);
   tasto:=readkey;
   case tasto of
       '+' : if linea<41 then inc(linea);
       '-' : if linea>1 then dec(linea);
   end;
   splat;
   for j:=1 to 80 do
   swritexy(j,linea,13,0,segno,video^);
  until tasto='o';
  env.levelpos[livindic]:=linea;
  swritexy(2,49,6,0,'                             ',video^);
  splat;
 end
end;

procedure mostralivelli;
var segno:string;
begin
 for i:=0 to env.n_livelli do
  if env.levelpos[i]>0 then begin str(i,segno);
                                  swritexy(1,env.levelpos[i],13,0,segno,video^);
                            end;
repeat until keypressed;
splat;
end;

procedure mostramoveable(param:byte);
var i,j:integer;
begin
 for i:=1 to 80 do
  for j:=1 to 50 do
   begin
   if param=0 then
   begin
    if env.moveable[i,j]>MAXOGGETTI then swritexy(i,j,13,0,'V',video^);
    if (env.moveable[i,j]>0) and (env.moveable[i,j]<=MAXOGGETTI) then swritexy(i,j,13,0,'o',video^);
   end;
   case env.moveable[i,j] of
   -1001 :swritexy(i,j,13,0,'N',video^);
   -1002 :swritexy(i,j,13,0,'O',video^);
   -1003 :swritexy(i,j,13,0,'E',video^);
   -1004 :swritexy(i,j,13,0,'S',video^);
   end;
   end;
end;

procedure creamoveable;
var k:char;
    ode,xit,i,j,curs1,curs2:integer;
begin
 i:=40;j:=20;
 repeat
 mostramoveable(0);
 swritexy(2,49,15,0,'A su | Z giu'' | X sx | C dx | V insert | E uscita | R reset | d restot | Q esce ',video^);
 k:=readkey;
   case k of
   'd','D' : begin
              for curs1:=1 to 50 do
               for curs2:=1 to 80 do
                env.moveable[curs2,curs1]:=0;
             end;
   'X','x' : if i>1 then dec(i);
   'C','c' : if i<80 then inc(i);
   'A','a' : if j>1 then dec(j);
   'Z','z' : if j<41 then inc(j);
   'R','r' : env.moveable[i,j]:=0;
   'V','v' : env.moveable[i,j]:=501;
   'E','e' : begin
              swritexy(2,49,15,0,'Uscita verso? (nord=1,ovest=2,est=3,sud=4,cancella=5)                             ',video^);
              k:=readkey;
              val(k,xit,ode);
              if k='5' then env.moveable[i,j]:=0 else
              env.moveable[i,j]:=-1000-xit;
              swritexy(2,49,15,0,'                                           ',video^);
             end
   end;
   splat;
   swritexy(i,j,13,0,'V',video^);
 until (k='q') or (k='Q')
end;

procedure mostraentrate;
var i,j:integer;
begin
 for i:=1 to 80 do
  for j:=1 to 50 do
   begin
   if (env.entrata[1].wx=i) and (env.entrata[1].wy=j)
      then swritexy(i,j,13,0,'N',video^);
   if (env.entrata[2].wx=i) and (env.entrata[2].wy=j)
      then swritexy(i,j,13,0,'O',video^);
   if (env.entrata[3].wx=i) and (env.entrata[3].wy=j)
      then swritexy(i,j,13,0,'E',video^);
   if (env.entrata[4].wx=i) and (env.entrata[4].wy=j)
      then swritexy(i,j,13,0,'S',video^);
   end;
end;

procedure creaentrate;
var k:char;
    i,j:integer;
begin
 mostraentrate;
 i:=40;j:=20;
 repeat
 swritexy(2,49,15,0,'A su | Z giu'' | X sx | C dx |1 da nord|2 da ovest|3 da est|4 da sud|  Q esce',video^);
 k:=readkey;
 case k of
   'X','x' : if i>1 then dec(i);
   'C','c' : if i<80 then inc(i);
   'A','a' : if j>1 then dec(j);
   'Z','z' : if j<41 then inc(j);
   '1': begin env.entrata[1].wx:=i;env.entrata[1].wy:=j;end;
   '2': begin env.entrata[2].wx:=i;env.entrata[2].wy:=j;end;
   '3': begin env.entrata[3].wx:=i;env.entrata[3].wy:=j;end;
   '4': begin env.entrata[4].wx:=i;env.entrata[4].wy:=j;end;
   end;
 splat;
 swritexy(i,j,13,0,'U',video^);
 mostraentrate;
 until (k='q') or (k='K')
end;

procedure giringirello;
var k:char;
    stinga:string;
begin
 repeat
 mostramoveable(1);
 swritexy(2,49,15,0,'        |       |       |         | Q esce |',video^);
 if env.adiacenza[1]<>0 then
                        begin
                         str(env.adiacenza[1],stinga);
                         swritexy(2,49,15,0,'Nord('+stinga+')',video^);
                        end;
 if env.adiacenza[4]<>0 then
                        begin
                         str(env.adiacenza[4],stinga);
                         swritexy(11,49,15,0,'Sud('+stinga+')',video^);
                        end;
 if env.adiacenza[2]<>0 then
                        begin
                         str(env.adiacenza[2],stinga);
                         swritexy(19,49,15,0,'Ovest('+stinga+')',video^);
                        end;
 if env.adiacenza[3]<>0 then
                        begin
                         str(env.adiacenza[3],stinga);
                         swritexy(27,49,15,0,'Est('+stinga+')',video^);
                        end;
 k:=readkey;
      case k of
      'N','n': if env.adiacenza[1]<>0 then begin
                                            stanzano:=env.adiacenza[1];
                                            caricadadisco(env.adiacenza[1]);
                                           end;
      'S','s': if env.adiacenza[4]<>0 then begin
                                            stanzano:=env.adiacenza[4];
                                            caricadadisco(env.adiacenza[4]);
                                           end;
      'E','e': if env.adiacenza[3]<>0 then begin
                                            stanzano:=env.adiacenza[3];
                                            caricadadisco(env.adiacenza[3]);
                                           end;
      'O','o': if env.adiacenza[2]<>0 then begin
                                            stanzano:=env.adiacenza[2];
                                            caricadadisco(env.adiacenza[2]);
                                           end;
      end;
      i:=1;
      while i<=8000 do begin schermo^[i]:=0; inc(i); end;
      crea_maschera;
      stampaschermo(env.n_livelli,0);
      str(stanzano,stanzanos);
      swritexy(79,47,15,0,stanzanos,schermo^);
      str(env.scala,stanzanos);
      swritexy(44,47,15,0,'(ora:'+stanzanos+')',schermo^);
      splat;
 until (k='q') or (k='Q')
end;

procedure disegna_oggetto(oggdadis:oggetto);
var h1,h2,rx,ry,ind2,ind3:integer;
begin
 with oggdadis do
  begin
   h1:=1-dimx mod 2;h2:=1-dimy mod 2;
   rx:=posx-dimx div 2+h1;
   ry:=posy-dimy div 2+h2;
   for ind2:=0 to dimy-1 do
     for ind3:=0 to 2*dimx-1 do
       if disegno[dimx*2*ind2+ind3]<>255 then
        video^[160*(ry+ind2-1)+2*(rx-1)+ind3+1]:=disegno[dimx*2*ind2+ind3];
  end;
end;

procedure caricaoggetti;
var objfile:file of oggetti_tipo;
begin
 new(obj);
 assign(objfile,filedeglioggetti);
 reset(objfile);
 read(objfile,obj^);
 close(objfile);
end;

procedure salvaoggetti;
var objfile:file of oggetti_tipo;
begin
 assign(objfile,filedeglioggetti);
 rewrite(objfile);
 write(objfile,obj^);
 close(objfile);
 dispose(obj);
end;

procedure editaoggetti(numero:integer;var obj:oggetto);

var video,frame:^screen;
    cmd:char; {comando}
    x,y:byte; {posizione cursore}
    colore,sfondo:byte;
    moved:boolean;

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
  swritexy(57,49,7,0,itos(numero),video^);
  swritexy(9,49,7,0,obj.nome,video^);
  swritexy(11,47,7,0,itos(obj.stanza),video^);
  swritexy(27,47,7,0,itos(obj.livello),video^);
  swritexy(45,47,7,0,itos(obj.posx),video^);
  swritexy(48,47,7,0,itos(obj.posy),video^);
  swritexy(66,47,7,0,itos(obj.dimx),video^);
  swritexy(68,47,7,0,itos(obj.dimy),video^);
end;
procedure disegna_oggetto(number:integer);
var h1,h2,rx,ry,ind2,ind3:integer;
begin
 with obj do
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
        end;
  end;
end;


procedure maschera;
 begin
  swritexy(1,42,6,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,43,6,0,'| CR: disegna [NO] | ''+'',''-'': colore | ''*'',''/'': sfondo | cattUra | sPeciale |',frame^);
  swritexy(3,43,15,0,'CR',frame^);swritexy(16,43,15,0,'NO',frame^);
  swritexy(23,43,15,0,'+',frame^);swritexy(27,43,15,0,'-',frame^);
  swritexy(41,43,15,0,'*',frame^);swritexy(45,43,15,0,'/',frame^);
  swritexy(62,43,15,0,'U',frame^);swritexy(69,43,15,0,'P',frame^);
  swritexy(1,44,6,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,45,6,0,'|                                                         | tRasparenza     |',frame^);
  swritexy(62,45,15,0,'R',frame^);
  swritexy(1,46,6,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,47,6,0,'| sTanza [   ] | lIvello [   ] | posiZione [  ,  ] | Dimensioni [ , ] | Help|',frame^);
  swritexy(4,47,15,0,'T',frame^);swritexy(19,47,15,0,'I',frame^);
  swritexy(38,47,15,0,'Z',frame^);swritexy(54,47,15,0,'D',frame^);
  swritexy(73,47,15,0,'H',frame^);
  swritexy(1,48,6,0,'+---------------------------------------------------------------------------+',frame^);
  swritexy(1,49,6,0,'| Nome [                    ] |       NUMERO OGGETTO ->[   ] |    [  ,  ]   |',frame^);
  swritexy(1,50,6,0,'+                                                                           |',frame^);
 end;

procedure clear;
var i:integer;
 begin
  for i:=1 to 8000 do frame^[i]:=0;
 end;

procedure raccogli_input;
 begin
  if (obj.nome='') then cmd:='n'
  else if (obj.nome<>'')and(obj.stanza=0) then cmd:='t'
  else if (obj.nome<>'')and(obj.stanza<>0)and(obj.livello=0) then cmd:='i'
  else cmd:=readkey;
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
             swritexy(16,43,7,0,'SI',frame^);
             repeat
              splat(moved);
              ch:=readkey;
              if ch=chr(13) then swritexy(16,43,7,0,'NO',frame^)
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
   't': begin
         swritexy(3,50,0,7,'stanza dell''oggetto?:',video^);
         textcolor(7);gotoxy(30,50);
         readln(obj.stanza);
        end;
   'i': begin
         swritexy(3,50,0,7,'livello dell''oggetto?:',video^);
         textcolor(7);gotoxy(30,50);
         readln(obj.livello);
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
         obj.dimx:=x2-x1+1;
         obj.dimy:=y2-y1+1;
         for j:=0 to obj.dimy-1 do
           for k:=0 to 2*obj.dimx-1 do
             obj.disegno[2*obj.dimx*j+k]:=
               frame^[160*(y1+j-1)+2*(x1)+k-1];
        end;
   'n': begin
         swritexy(3,50,0,7,'nuovo nome?:',video^);
         textcolor(7);gotoxy(16,50);
         readln(obj.nome);
        end;
   'p': begin
         swritexy(3,50,0,7,'inserisci il codice ascii:',video^);
         textcolor(7);gotoxy(30,50);
         readln(j);
         if (j>=1)and(j<=255) then swritexy(x,y,7,16,chr(j),frame^);
        end;
   'r': begin
         for j:=0 to 1 do frame^[160*(y-1)+2*x-1+j]:=255;
        end;
  end;
 end;

begin
 video:=ptr($B800,0);
 new(frame);
 x:=1;y:=1;
 colore:=7;sfondo:=0;
 moved:=true;
 clear;
 maschera;
 disegna_oggetto(numero);
 repeat
   splat(moved);
   raccogli_input;
   esegui;
   clear;maschera;disegna_oggetto(numero);
   if ((cmd='q')or(cmd='Q'))and(obj.dimx+obj.dimy=0) then
                begin
                 swritexy(2,50,15,0,'Prima si devono definire le dimensioni dell''oggetto',video^);
                 repeat until keypressed;cmd:=readkey;
                 cmd:='*';
                end;

 until (cmd='Q')or(cmd='q');
 dispose(frame);
end;

procedure collocaoggettovero(quale:integer);
var
    l,nuovolivello:byte;
    cursore:char;
    i,j,securityx,securityy:integer;
begin
  repeat
   swritexy(2,49,6,0,'A quale livello devo inserire?                           ',video^);
   gotoxy(34,49);
   read(nuovolivello);
   if nuovolivello>env.n_livelli then begin
                                       swritexy(2,49,6,0,'Livello non presente                     ',video^);
                                       delay(1000);
                                       swritexy(2,49,6,0,'                                       ',video^);
                                      end;
 until nuovolivello<=env.n_livelli;
 i:=5;j:=5;
 securityx:=obj^[quale].posx;securityy:=obj^[quale].posy;
 repeat
  swritexy(2,49,15,0,'A su | Z giu'' | X sinistra | C destra | M modifica oggetto | V inserisce e esce',video^);
  cursore:=readkey;
  case cursore of
   'X','x' : if i>1 then dec(i);
   'C','c' : if i<80 then inc(i);
   'A','a' : if j>1 then dec(j);
   'Z','z' : if j<41 then inc(j);
   'M','m' : editaoggetti(quale,obj^[quale]);
  end;
  splat;
  obj^[quale].posx:=i;obj^[quale].posy:=j;
  disegna_oggetto(obj^[quale]);
until (cursore='v') or (cursore='V');
swritexy(2,49,6,0,'Visualizzare risultato? (s/n)              ',video^);
cursore:=readkey;
swritexy(2,49,6,0,'                                          ',video^);
if (cursore='s') or (cursore='S') then
                                begin
                                 for l:=env.n_livelli downto nuovolivello do
                                 disegna_sfondo(env.livs[l],video^);
                                 disegna_oggetto(obj^[quale]);
                                 for l:=(nuovolivello-1) downto 0 do
                                     disegna_sfondo(env.livs[l],video^);
                                  delay(1000);
                                 end;
swritexy(2,49,6,0,'Soddisfatto? (s/n)              ',video^);
cursore:=readkey;
if (cursore='s') or (cursore='S') then
                                   begin
                                    obj^[quale].livello:=nuovolivello;
                                    obj^[quale].stanza:=stanzano;
                                   end
                                   else begin
                                        obj^[quale].posx:=securityx;
                                        obj^[quale].posy:=securityy;
                                        end;
end;

procedure inseriscioggettovero;
var a,corridore:integer;
    comando,answer:char;
    numerooggetto,doveorastanza,doveoralivello:string;
begin
 {qua si mettono gli oggetti veri sullo schermo}
  caricaoggetti;
  swritexy(2,49,15,0,'Oggetto nuovo o vecchio ? (n/v)     ',video^);
  answer:=readkey;
  if (answer='v') or (answer='V') then
                begin
                a:=1;
                while (obj^[a].dimx+obj^[a].dimy=0)and(obj^[a].nome<>'') do
                inc(a);
                repeat
                 str(obj^[a].stanza,doveorastanza);
                 str(obj^[a].livello,doveoralivello);
                 str(a,numerooggetto);
                 swritexy(2,49,15,0,'Oggetto('+numerooggetto+'):'+obj^[a].nome+' ora stanza:'
                 +doveorastanza+';livello:'+doveoralivello+' ? (S/N/neXt/Prev)',video^);
                 answer:=readkey;
                 case answer of
                 's','S': collocaoggettovero(a);
                 'x','X': begin
                           corridore:=a;
                           repeat
                            inc(corridore);
                           until not((obj^[corridore].dimx+obj^[corridore].dimy=0)and(obj^[corridore].nome<>''));
                           if obj^[corridore].nome='' then
                            begin
                             swritexy(2,49,6,0,'Sorry ultimo oggetto!!           ',video^);
                             delay(1000);
                            end
                           else a:=corridore;
                          end;
                 'P','p': begin
                           if a<>1 then
                           begin
                            corridore:=a;
                            repeat
                             dec(corridore);
                            until not((obj^[corridore].dimx+obj^[corridore].dimy=0)and(obj^[corridore].nome<>''));
                           end;
                           if (obj^[corridore].nome='') or (a=1) then
                            begin
                             swritexy(2,49,6,0,'Sorry primo oggetto!!           ',video^);
                             delay(1000);
                            end
                           else a:=corridore;
                          end;
                 end;
                 until (answer='q') or (answer='Q');
                 salvaoggetti;
                end
  else if (answer='n') or (answer='N') then
                  begin
                   a:=1;
                   while obj^[a].nome<>'' do inc(a);
                   str(a,numerooggetto);
                   swritexy(2,49,15,0,'Questo sar… l''oggetto '+numerooggetto+'           ',video^);
                   repeat until keypressed;
                   editaoggetti(a,obj^[a]);
                   swritexy(2,50,15,0,'Soddisfatto ? (s/n)              ',video^);
                   answer:=readkey;
                   splat;
                   if (answer='s') or (answer='S') then
                   begin
                    salvaoggetti;
                    collocaoggettovero(a);
                   end;
                   dispose(obj);
                  end;
end;

procedure immettioggetto(quale:integer);
var start2,end2,end1,start1,startx,starty,i,j:integer;
    answer:char;
begin
 i:=40;j:=20;
 repeat
 swritexy(2,49,15,0,'A su|Z giu''|X sx|C dx|V insert|L livello|F from|T to|R resetmove|Q esce ',video^);
 answer:=readkey;
 case answer of
 'X','x' : if i>1 then dec(i);
 'C','c' : if i<80 then inc(i);
 'A','a' : if j>1 then dec(j);
 'Z','z' : if j<41 then inc(j);
 'R','r' : env.moveable[i,j]:=0;
 'V','v' : env.moveable[i,j]:=quale;
 'F','f' : begin startx:=i;starty:=j; end;
 'T','t' : begin
           if (startx<=i) then begin start1:=startx;end1:=i; end
                          else begin start1:=i;end1:=startx; end;
           if (starty<=j) then begin start2:=starty;end2:=j; end
                          else begin start2:=j;end2:=starty; end;
           for ind1:=start1 to end1 do
               for ind2:=start2 to end2 do
                                  env.moveable[ind1,ind2]:=quale;
           end;
 'l','L': begin
           repeat
           swritexy(2,49,15,0,'A quale livello va l''oggetto?                             ',video^);
           gotoxy(30,55);readln(obj^[quale].livello);
           until obj^[quale].livello<=env.n_livelli;
          end;
 end;
 splat;
 swritexy(i,j,13,0,'o',video^);
 mostramoveable(0);
 until (answer='q') or (answer='Q');
 swritexy(2,49,15,0,'                          ',video^);
 end;

procedure inseriscioggettofinto;
var as,numerooggetto:string;
    a,corridore:integer;
    answer:char;
begin
 caricaoggetti;
 swritexy(2,49,15,0,'Nuovo oggetto? (s/n)',video^);
 answer:=readkey;
 swritexy(2,49,15,0,'                  ',video^);
 case answer of
 'S','s' : begin
            a:=1;
            while obj^[a].nome<>'' do inc(a);
            str(a,as);
            swritexy(2,49,15,0,'Questo sara'' l''oggetto numero '+as,video^);
            delay(50);
            swritexy(2,49,15,0,'Nome dell''oggetto?                ',video^);
            gotoxy(30,49);readln(obj^[a].nome);
            immettioggetto(a);
            salvaoggetti;
           end;
 'N','n' : begin
            a:=1;
            while (obj^[a].dimx+obj^[a].dimy>0)and(obj^[a].nome<>'') do
            inc(a);
            repeat
            str(a,numerooggetto);
            swritexy(2,49,15,0,'Oggetto('+numerooggetto+'):'+obj^[a].nome+' ? (S/N/neXt/Prev)                    ',video^);
            answer:=readkey;
            case answer of
                 's','S': immettioggetto(a);
                 'x','X': begin
                           corridore:=a;
                           repeat
                            inc(corridore);
                           until not((obj^[corridore].dimx+obj^[corridore].dimy>0)and(obj^[corridore].nome<>''));
                           if obj^[corridore].nome='' then
                            begin
                             swritexy(2,49,6,0,'Sorry ultimo oggetto!!           ',video^);
                             delay(1000);
                            end
                           else a:=corridore;
                          end;
                 'P','p': begin
                           if a<>1 then
                           begin
                            corridore:=a;
                            repeat
                             dec(corridore);
                            until not((obj^[corridore].dimx+obj^[corridore].dimy>0)and(obj^[corridore].nome<>''));
                           end;
                           if (obj^[corridore].nome='') or (a=1) then
                            begin
                             swritexy(2,49,6,0,'Sorry primo oggetto!!           ',video^);
                             delay(1000);
                            end
                           else a:=corridore;
                          end;
            end;
            until (answer='q') or (answer='Q');
            salvaoggetti;
            end;
 end;
end;


procedure inseriscioggetto;
var answer:char;
    a:byte;

begin
 swritexy(2,49,15,0,'Oggetto vero o solo sfondo (v/s) ',video^);
 answer:=readkey;
 swritexy(2,49,15,0,'                                 ',video^);
 case answer of
 's','S': begin saved:=false;inseriscioggettofinto; end;
 'v','V': inseriscioggettovero;
 end;
end;

procedure mostrastanzaconoggetti;
var levels:byte;
    ogg:integer;
begin
 caricaoggetti;
 for levels:=env.n_livelli downto 0 do
  begin
   disegna_sfondo(env.livs[levels],video^);
   for ogg:=1 to MAXOGGETTI do
    if (obj^[ogg].stanza=stanzano) and (obj^[ogg].livello=levels)
    then disegna_oggetto(obj^[ogg]);
  end;
swritexy(2,49,15,0,'Premi un tasto per continuare',video^);
repeat until keypressed;
end;

procedure programma_che_disegna;
var clipo,maschera,frame:^screen;
    txf,tyf,txi,tyi,xi,yi,xf,yf,colore,sfondo,i,carattere,posix,posiy,
    lclip,aclip:integer;
    uscita1,forbini,foreini,trasparente,errore,trasparentemouse,mouseattivo:boolean;
    sf,colorc,sfondoc,caratterec,posixc,posiyc,filo:string;
    chief:file of byte;
    nullo:byte;
    tasto1:char;
    tipo:word;

procedure forecolor(x1,y1,x2,y2:integer;colore,sfondo:byte;s:string; var dove:screen);
var ind1,ind2,start1,end1,start2,end2:integer;
   begin
     if (x1<=x2) then begin start1:=x1;end1:=x2; end
                 else begin start1:=x2;end1:=x1; end;
     if (y1<=y2) then begin start2:=y1;end2:=y2; end
                 else begin start2:=y2;end2:=y1; end;
     for ind1:=start1 to end1 do
      for ind2:=start2 to end2 do
       swritexy(ind1,ind2,colore,sfondo,s,dove);
   end;

procedure getta(x1,y1,x2,y2:integer);
var posinprov,posx,posy,ind1,ind2:integer;
    basec,altezzac,s:string;
    color,sfond:byte;
    i:integer;
 begin
   for i:=1 to 6560 do clipo^[i]:=0;
   lclip:=abs(x2-x1)+1;
   aclip:=abs(y2-y1)+1;
   str(lclip,basec);str(aclip,altezzac);
   swritexy(2,50,15,0,basec,maschera^);swritexy(5,50,15,0,altezzac,maschera^);
   if y1<=y2 then posy:=y1
             else posy:=y2;
   ind1:=1;ind2:=1;
   for ind1:=1 to aclip do
      begin
        if x1<=x2 then posx:=x1
                  else posx:=x2;
         for ind2:=1 to lclip do
          begin
           posinprov:=((posy-1)*80+posx-1)*2;
           s:=chr(frame^[posinprov+1]);
           sfond:=frame^[posinprov+2] div 16;
           color:=frame^[posinprov+2] and 15;
           if (frame^[posinprov+1]=84) and (frame^[posinprov]=13) then
           swritexy(ind2,ind1,0,0,'',clipo^)
           else
           swritexy(ind2,ind1,color,sfond,s,clipo^);
           inc(posx);
          end;
      inc(posy);
      end;
 end;

procedure flippa(startx,starty,limx,limy,param:integer);
var posinprov,posx,posy,ind1,ind2,end1,end2:integer;
    basec,altezzac,s:string;
    color,sfond:byte;
begin
 end1:=startx+limx;
 end2:=starty+limy;
 str(end1,basec);str(end2,altezzac);
 swritexy(10,50,15,0,basec,maschera^);swritexy(15,50,15,0,altezzac,maschera^);
 ind2:=starty;
 posy:=1;
 while (ind2<=41)and(posy<=limy) do
 begin
   ind1:=startx;
   posx:=1;
   while (ind1<=80)and(posx<=limx) do
     begin
      case param of
       1: posinprov:=(((limy-posy)+1)*80+posx-1)*2;
       2: posinprov:=((posy-1)*80+(limx-posx+1)-1)*2;
       3: posinprov:=((posy-1)*80+posx-1)*2;
      end;
       if not((clipo^[posinprov+1]=0)or
      ((clipo^[posinprov+1]=219)and(clipo^[posinprov+2]=0))) then
      begin
       s:=chr(clipo^[posinprov+1]);
       sfond:=clipo^[posinprov+2] div 16;
       color:=clipo^[posinprov+2] and 15;
       swritexy(ind1,ind2,color,sfond,s,frame^);
      end;
      inc(ind1);
      inc(posx);
     end;
  inc(ind2);inc(posy);
  end;
end;

procedure crea_maschera;
 begin
  swritexy(1,42,6,0,'+------------------------------------------------------------------------------+',maschera^);
  swritexy(1,43,6,0,'|Colore :  |Sfondo :  |Carattere :   |  ORE:      | FORBIC :      |   asta     |',maschera^);
  swritexy(40,43,15,0,'F',maschera^);swritexy(45,43,15,0,'spento',maschera^);
  swritexy(59,43,15,0,'Y',maschera^);swritexy(61,43,15,0,'unused',maschera^);
  swritexy(70,43,15,0,'P',maschera^);
  swritexy(1,44,6,0,'+------------------------------------------------------------------------------+',maschera^);
  swritexy(1,45,6,0,'|Posizione x:    y:  |  /  salva e carica  |   reset schermo |        |   esce |',maschera^);
  swritexy(46,45,15,0,'R',maschera^);swritexy(73,45,15,0,'Q',maschera^);
  swritexy(64,45,15,0,'U',maschera^);
  swritexy(24,45,15,0,'S',maschera^);swritexy(26,45,15,0,'I',maschera^);
  swritexy(1,46,6,0,'+------------------------------------------------------------------------------+',maschera^);
  swritexy(1,47,6,0,'|X per inserire del testo| T cambia carattere |   trasparente|  irror | F ip   |',maschera^);
  swritexy(2,47,15,0,'O',maschera^);swritexy(28,47,15,0,'T',maschera^);
  swritexy(49,47,15,0,'V',maschera^);
  swritexy(64,47,15,0,'M',maschera^);swritexy(74,47,15,0,'l',maschera^);
  swritexy(1,48,6,0,'+------------------------------------------------------------------------------+',maschera^);
  swritexy(1,49,6,0,'|  /  colore |  /  sfondo |  /  carattere |                    |               |',maschera^);
  swritexy(3,49,15,0,'1',maschera^);swritexy(5,49,15,0,'2',maschera^);
  swritexy(16,49,15,0,'3',maschera^);swritexy(18,49,15,0,'4',maschera^);
  swritexy(29,49,15,0,'5',maschera^);swritexy(31,49,15,0,'6',maschera^);
  swritexy(66,49,15,0,'NF:',maschera^);
  swritexy(1,50,6,0,'|                                                                              |',maschera^);
 end;

begin
 {setta situazione iniziale: colore, sfondo, posizione}
 reset_mouse(errore,tipo);
 window_mouse(0,0,639,327);
 uscita1:=false;
 colore:=15;sfondo:=0;carattere:=219;
 posix:=x_mouse(false);posiy:=y_mouse(false);
 foreini:=false;forbini:=false;
 trasparente:=true;trasparentemouse:=true;mouseattivo:=false;
 new(clipo);new(maschera);new(frame);
 for i:=1 to 8000 do begin
                          maschera^[i]:=0;
                          frame^[i]:=0;
                          clipo^[i]:=0;
                      end;
 crea_maschera;
 while not (uscita1) do
  begin
  if mouseattivo then begin
                       posix:=x_mouse(false)+1;
                       posiy:=y_mouse(false)+1;
                       trasparente:=not(left_button);
                      end;
  {aggiorna maschera INIZIO}
  str(colore,colorc);str(sfondo,sfondoc);
  str(carattere,caratterec);str(posix,posixc);str(posiy,posiyc);
  if colore<10 then colorc:=' '+colorc;
  swritexy(10,43,15,0,colorc,maschera^);
  if sfondo<10 then sfondoc:=' '+sfondoc;
  swritexy(21,43,15,0,sfondoc,maschera^);
  for i:=1 to (3-length(caratterec)) do caratterec:=' '+caratterec;
  swritexy(35,43,15,0,caratterec,maschera^);
  for i:=1 to (2-length(posiyc)) do posiyc:=' '+posiyc;
  swritexy(20,45,15,0,posiyc,maschera^);
  for i:=1 to (2-length(posixc)) do posixc:=' '+posixc;
  swritexy(14,45,15,0,posixc,maschera^);
  if trasparente then swritexy(51,47,0,15,'trasparente',maschera^)
                 else swritexy(51,47,6,0,'trasparente',maschera^);
  if not mouseattivo then begin
                       swritexy(66,45,6,0,'mouse',maschera^);
                       swritexy(50,49,15,0,'per spostarsi',maschera^);
                       swritexy(45,49,15,0,'azxc',maschera^);
                       end
                 else
                 begin
                  swritexy(66,45,0,15,'mouse',maschera^);
                  swritexy(45,49,15,0,'                  ',maschera^);
                 end;
  {aggiorna maschera FINE}
  move(frame^,maschera^,6560);
  {stampa i caratteri invisibili}
  i:=1;
  while i<=6560 do
                begin
                 if (frame^[i]=0)or((frame^[i]=219)and(frame^[i+1]=0)) then
                                             begin
                                              maschera^[i]:=84;
                                              maschera^[i+1]:=13;
                                             end;
                 i:=i+2;
                end;
  {stampa i carattere invisibili FINE}
  if not mouseattivo then
  begin
   if trasparente then swritexy(posix,posiy,colore,sfondo,chr(carattere),maschera^)
                  else begin
                        swritexy(posix,posiy,colore,sfondo,chr(carattere),frame^);
                        move(frame^,maschera^,6560);
                       end;
  end
  else
  begin
   if trasparente then swritexy(x_mouse(false)+1,y_mouse(false)+1,colore,sfondo,chr(carattere),maschera^)
                  else begin
                        swritexy(x_mouse(false)+1,y_mouse(false)+1,colore,sfondo,chr(carattere),frame^);
                        move(frame^,maschera^,6560);
                       end;
  end;
  move(maschera^,video^,8000);
  if keypressed then begin
  tasto1:=readkey;
        case tasto1 of
        'q','Q':begin
                swritexy(2,50,15,0,'Sei sicuro????',video^);
                  tasto1:=readkey;
                  if (tasto1='s') or (tasto1='S') then
                uscita1:=true;
                swritexy(2,50,15,0,'               ',video^);
                end;
        '1' : colore:=(colore+1) mod 16;
        '2' : colore:=((colore-1)+16) mod 16;
        '3' : sfondo:=(sfondo+1) mod 16;
        '4' : sfondo:=((sfondo-1)+16) mod 16;
        '5' : carattere:=(carattere+1) mod 256;
        '6' : carattere:=((carattere-1)+256) mod 256;
        'z','Z': if not mouseattivo then if posiy<41 then inc(posiy);
        'a','A': if not mouseattivo then if posiy>1 then dec(posiy);
        'c','C': if not mouseattivo then if posix<80 then inc(posix);
        'x','X': if not mouseattivo then if posix>1 then dec(posix);
        'r','R': begin
                  swritexy(2,50,15,0,'Sei sicuro????',video^);
                  tasto1:=readkey;
                  if (tasto1='s') or (tasto1='S') then
                  for i:=1 to 6560 do frame^[i]:=0;
                 end;
        't','T': begin
                  swritexy(2,50,15,0,'Inserire numero carattere:',video^);
                  gotoxy(28,50);readln(carattere);
                 end;
        'y','Y': begin if not forbini then
                                      begin
                                       forbini:=true;
                                       txi:=posix;tyi:=posiy;
                                       swritexy(61,43,0,15,' used ',maschera^);
                                      end
                                      else
                                      begin
                                       txf:=posix;tyf:=posiy;
                                       getta(txi,tyi,txf,tyf);
                                       swritexy(61,43,15,0,'unused',maschera^);
                                       forbini:=false;
                                      end;
                  end;
        'f','F':begin
                 if not foreini then
                                begin
                                 foreini:=true;
                                 xi:=posix;yi:=posiy;
                                 swritexy(45,43,0,15,'acceso',maschera^);
                                end
                                else
                                 begin
                                  xf:=posix;yf:=posiy;
                                  forecolor(xi,yi,xf,yf,colore,sfondo,chr(carattere),frame^);
                                  swritexy(45,43,15,0,'spento',maschera^);
                                  foreini:=false;
                                 end;
              end;
        'p','P': flippa(posix,posiy,lclip,aclip,3);
        'm','M': flippa(txi,tyi,lclip,aclip,2);
        'l','L': flippa(txi,tyi,lclip,aclip,1);
        's','S': begin
                  swritexy(2,50,15,0,'Nome del file da salvare:',video^);
                  gotoxy(28,50);readln(filo);
                  swritexy(68,49,15,0,filo,maschera^);
                  assign(chief,filo);
                  rewrite(chief);
                  i:=1;
                  while i<=6560 do
                                 begin
                                  nullo:=255;
                                  if (frame^[i]=0) or
                                  ((frame^[i]=219)and(frame^[i+1]=0)) then
                                             begin
                                             write(chief,nullo);
                                             write(chief,nullo);
                                             end
                                            else
                                             begin
                                             write(chief,frame^[i]);
                                             write(chief,frame^[i+1]);
                                             end;
                                i:=i+2; end;
                                close(chief);
                                  end;
        'i','I': begin
                  swritexy(2,50,15,0,'Nome del file da caricare:',video^);
                  gotoxy(28,50);readln(filo);
                  assign(chief,filo);
                  {$i-}
                  reset(chief);
                  {$i+}
                  if ioresult<>0 then
                                  begin
                                       swritexy(2,50,0,15,'FILE NON TROVATO',video^);
                                       repeat until keypressed;
                                  end
                                 else
                                  begin
                                   swritexy(68,49,15,0,filo,maschera^);
                                   i:=1;
                                   while (i<=6560) and not eof(chief) do
                                   begin
                                    read(chief,frame^[i]);
                                    if frame^[i]=255 then frame^[i]:=0;
                                    inc(i);
                                   end;
                                   close(chief);
                                  end;
                 end;
        'o','O': begin
                  swritexy(2,50,15,0,'Testo da inserire:',video^);
                  gotoxy(20,50);readln(filo);
                  swritexy(posix,posiy,colore,sfondo,filo,frame^);
                 end;
        'v','V': if not mouseattivo then trasparente:=not trasparente;
        'u','U': begin
                 mouseattivo:=not mouseattivo;
                 if mouseattivo then pos_mouse(posix*8,posiy*8)
                 else begin
                       posix:=x_mouse(false);posiy:=y_mouse(false);
                      end;
                 end;
        end;
     end;
  end;
  dispose(clipo);dispose(frame);dispose(maschera);
end;

procedure cambiaadiacenze;
var quale:char;
    qualestanza:integer;
    stringanord,stringasud,stringaest,stringaovest:string;
begin
 repeat
 str(env.adiacenza[1],stringanord);
 str(env.adiacenza[4],stringasud);
 str(env.adiacenza[3],stringaest);
 str(env.adiacenza[2],stringaovest);
 swritexy(2,49,15,0,'Nord('+stringanord+') Sud('+stringasud+') Est('+stringaest+') Ovest('+stringaovest+')',video^);
 swritexy(40,49,15,0,'Modificare? (Nord,Sud,Est,Ovest) Q esce ',video^);
 quale:=readkey;
 case quale of
 'N','n': begin
            swritexy(2,49,15,0,'Quale stanza?                     ',video^);
            gotoxy(16,49);readln(env.adiacenza[1]);
          end;
 'S','s': begin
            swritexy(2,49,15,0,'Quale stanza?                     ',video^);
            gotoxy(16,49);readln(env.adiacenza[4]);
          end;
 'E','e': begin
            swritexy(2,49,15,0,'Quale stanza?                    ',video^);
            gotoxy(16,49);readln(env.adiacenza[3]);
          end;
 'O','o': begin
            swritexy(2,49,15,0,'Quale stanza?                    ',video^);
            gotoxy(16,49);readln(env.adiacenza[2]);
          end;
 end;
 until (quale='q') or (quale='Q')
end;

procedure acchiappalivello;
var quale:byte;
    disegno:file of byte;
    cursore:integer;
begin
 repeat
  swritexy(2,49,6,0,'Quale livello devo "catturare"?',video^);
  gotoxy(40,49);readln(quale);
  if quale>env.n_livelli then
     begin
      swritexy(2,49,6,0,'Livello non presente                     ',video^);
      delay(1000);
     end;
 until quale<=env.n_livelli;
 swritexy(2,49,6,0,'Nome sfondo livello da salvare:           ',video^);
 gotoxy(45,49); readln(filo);
 assign(disegno,filo);
 rewrite(disegno);
 cursore:=1;
 while (cursore<=6560) do
  begin
  write(disegno,env.livs[quale][cursore]);
  inc(cursore);
  end;
 close(disegno);
 swritexy(2,49,15,0,'Disegno salvato                 ',video^);
 delay(1000);
 swritexy(2,49,6,0,'                              ',video^);
end;

{corpo del programma vero e proprio}
begin
  filedellestanze:='room';
  filedeglioggetti:='oggetti';
  textmode(CO80+FONT8x8);
  video:=ptr($B800,0);
  new(schermo);
  for i:=1 to 8000 do schermo^[i]:=0;
  uscita:=false;working:=false;saved:=true;
  crea_maschera;
  while (not uscita) do
  begin
  tasto:=readkey;
  case tasto of
  'N','n': if saved then
                     begin
                     saved:=false;puliscivecchiocreanuovo;
                     working:=true;crea_maschera;
                     end;
  'Q','q': if not(saved) then
                         begin
                          swritexy(2,49,6,0,'Schermo non salvato, uscire?',video^);
                          gotoxy(30,49);
                          readln(tasto);
                          if (tasto='s') or (tasto='S') then uscita:=true
                          else swritexy(2,49,6,0,'                            ',video^);
                         end
                        else uscita:=true;
  'A','a': if working then begin saved:=false;aggiungilivello; end;
  'E','e': if working then begin saved:=false;eliminalivello; end;
  'S','s': if working then begin salvaschermo;
                                 swritexy(2,49,6,0,'Schermo salvato',video^);
                           end;
  'C','c': begin
            caricaschermo;
            if stanzano>0 then begin working:=true;crea_maschera;end;
           end;
  'L','l': if working then begin saved:=false; settalivello; end;
  'M','m': if working then mostralivelli;
  'V','v': if working then begin saved:=false; creamoveable; splat; end;
  'Z','z': if working then begin
                            mostramoveable(0);repeat until keypressed;
                            h:=readkey;splat;
                           end;
  'p','P': if working then acchiappalivello;
  'O','o': if working then begin inseriscioggetto; end;
  'T','t': if working then begin saved:=false;creaentrate; splat; end;
  'R','r': if working then begin mostraentrate;repeat until keypressed;end;
  'G','g': if working then giringirello;
  'k','K': if working then begin saved:=false;cambiascala(env.scala); end;
  'w','W': if working then mostrastanzaconoggetti;
  'd','D': programma_che_disegna;
  'u','U': if working then settamusica(env.backmusic);
  'i','I': if working then begin saved:=false; cambiaadiacenze; end;
  end;
  if not(uscita) then begin
                       stampaschermo(env.n_livelli,0);
                       splat;
                      end
  end;
  dispose(schermo);
  textmode(co80);
end.