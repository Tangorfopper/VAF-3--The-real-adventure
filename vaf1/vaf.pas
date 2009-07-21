program vaf;
  uses dos,crt,detect,smix,animasci;
  const xms=512;  {quantitÖ di XMS}
        numsounds=9;{numero di samples}
        sharedemb=true;
        destra=77;thrust=80;sinistra=75;fire=57;ptasto=25;
        destra2=46;sinistra2=44;fire2=29;
        esci=16;effedodici=88;  {codici dei tasti}
        numenemies=256;{max numero nemici}
        me='Va=f';
        pro1='ù';
        pro2='≠';
        pro3='<'+pro2+'>';{sprite}
        pro4='ùˇùˇùˇùˇù';
        MAXLANDSCAPE=750; {max righe sfondo}
        MAXRIGHE=8;{max righe sprite}
        MAXCOLONNE=18;{max colonne sprite}
        NTIPI=8;{n¯ tipi di sprite}
        ALTEZZA=23;{altezza schermo di gioco}
        LARGHEZZA=60;{larghezza schermo di gioco}
        SUPERFIREWAIT=15;{attesa per il raggio spettrale}
        SCHERMI=15;{n¯ scudi}
        LIVELLI=10;{n¯ livelli}
        BARA=[48,23,38,34,30,20,18,31,48+128,23+128,38+128,34+128,30+128,
              20+128,18+128,31+128];

  type spritepos=record
                   x:byte;
                   y:byte;
                 end;
       enemy=record
               pos:spritepos;
               incx,incy:integer;{incremento posizione}
               countx,county:byte;{contatore per rallent. spostamento}
               alive:boolean;  {mi dice se ä vivo o no}
               sparato:boolean;{mi dice se ha sparato}
               hit,colpito:boolean; {mi dice se ä stato colpito}
               expframe:byte;{dice quanti frame dell'espl. devo disegnare}
               tipo,forza:integer; {mi dice che tipo di nemico ä}
             end;
       frame=array[1..4000] of byte;
       explosion=array[1..NTIPI,1..8,1..MAXRIGHE] of string[MAXCOLONNE];
  var
    BaseIO: word; IRQ, DMA, DMA16: byte;
    Sound: array[0..NumSounds-1] of PSound;{array dei suoni}
    position:array [1..2] of byte;   {la mia posizione}
    enemies: array[1..numenemies] of enemy;{i nemici}
    projectiles: array[1..numenemies] of spritepos;{posizioni dei proiett.}
    bomb:array [1..2] of spritepos;{posizione del mio proiettile}
    int09mio,saveint:pointer;
    vivo,stasto,dtasto,ftasto,fired,superfire,fuoco:array [1..2] of boolean;
    etasto,pausa,nsnd,boss,stopboss:boolean;
    screen:array [0..MAXLANDSCAPE] of string[LARGHEZZA];{sfondo}
    i,j,k,won:byte;{won: numero dei nemici vivi}
    sfondo,sfondilist:text;{sfondilist: lista dei file di sfondo}
    numplayer,scroll,vel,numlines:integer;
    energy,presstime:array [1..2] of integer;
    expl:^explosion;{frame dell'esplosione}
    sprite:array[1..NTIPI,1..MAXRIGHE] of string[MAXCOLONNE];
    clock:word;  {n¯ di cicli principali effettuati modulo qualcosa}
    expcolor:array[0..7] of byte;
    scvel,nlines,numbenemy:array[1..LIVELLI] of integer;
    enemycolor,nrighe,ncol,strength,pro:array[1..NTIPI] of byte;
    aggr:array[1..NTIPI] of integer;
    tipologie:array[1..LIVELLI,1..numenemies] of byte;
    sfondofile,sfondoname:string;
    h:char;
    fastness:byte;
    color,panel:array [1..2] of byte;
    schermo:array[1..2000] of char;
    attrib:array[1..2000] of byte;
    phantom:^frame;
    aux:string;
    cheat:array[1..9] of boolean;


procedure setiton;
var k:integer;

begin
  getintvec($09,saveint);
  setintvec($09,int09mio);
  for k:=1 to 2 do
    begin
      stasto[k]:=false;dtasto[k]:=false;
      etasto:=false;pausa:=false;fuoco[k]:=false;
    end;
  for k:=1 to 9 do cheat[k]:=false;
end;

procedure setitoff;
var h:char;

begin
  setintvec($09,saveint);
  if keypressed then h:=readkey;
end;

procedure fast;
var i,h,m,s,s100,burp:word;
    once,now,h1,m1,s1,s1001:longint;
    c:char;

begin
  gettime(h,m,s,s100);
  h1:=h;m1:=m;s1:=s;s1001:=s100;
  once:=h1*360000+m1*60000+100*s1+s1001;
  for i:=1 to 1000 do writeln(i);
  gettime(h,m,s,s100);
  h1:=h;m1:=m;s1:=s;s1001:=s100;
  now:=h1*360000+m1*60000+100*s1+s1001;
  writeln(now-once);
  writeln(40-((now-once) div 10));
  {c:=readkey;}
  if 40-((now-once) div 10)>0 then fastness:=40-((now-once) div 10)
     else fastness:=0;
end;


procedure caricasfondo(source:string;scrollvel:integer;lines:integer);
{carica lo sfondo dentro screen}
var i:integer;
    filez:text;

begin
  assign(filez,source);
  reset(filez);
  i:=0;
  while (i<=lines) do begin
                    readln(filez,screen[i]);
                    inc(i)
                  end;
  close(filez);
  vel:=scrollvel;
  numlines:=lines;
end;

procedure initialize;
{inizializza la sound blaster}

begin
  nsnd:=paramstr(1)='nosound';
  if (not nsnd) then nsnd:=not getsettings(baseio,irq,dma,dma16);
  if nsnd then begin
                  writeln('e comprati una scheda !');
                  intdelay(2000);
                end;
  if (not nsnd) then
     begin
       nsnd:=not initsb(baseio,irq,dma,dma16);
     end;
  if (not nsnd) then
     begin
       nsnd:=not initxms;
       if nsnd then begin
                     writeln('nienteXMS niente sonoro!');
                     intdelay(2000);
                   end;
     end;
  if (not nsnd)
  then begin
         if SharedEMB then InitSharing;
         OpenSoundResourceFile('VAF.SND');
         LoadSound(Sound[0], 'SPAZIO');
         LoadSound(Sound[1], 'RAGGIO');
         LoadSound(Sound[2], 'ESAME');
         LoadSound(Sound[3], 'HIT');
         LoadSound(Sound[4], 'FERITO');
         LoadSound(Sound[5], 'SHOT');
         LoadSound(Sound[6], 'EXP1');
         LoadSound(Sound[7], 'WIN95');
         LoadSound(Sound[8], 'GETREADY');
         CloseSoundResourceFile;
         InitMixing;
       end;
end;

procedure muovinemico(nemico:integer);
{modifica la posizione dell'i-esimo nemico in funzione della precedente}
begin
  with enemies[i] do
    begin
      if countx=0 then incx:=round(random*2)-1;
      if county=0 then incy:=round(random*2)-1;
      if ((pos.x>=LARGHEZZA-ncol[tipo])and(incx>0))or((pos.x<2)and(incx<0))
         then incx:=-incx;
      if clock mod 2=0 then pos.x:=(pos.x+incx){+78-ncol) mod (78-ncol)};
      countx:=(countx+1+10) mod 10;
      if ((pos.y>ALTEZZA-4-nrighe[tipo])and(incy>0))or((pos.y<2)and(incy<0))
         then incy:=-incy;
      if clock mod 5=0 then pos.y:=(pos.y+incy){+21-nrighe) mod (21-nrighe)};
      county:=(county+1+5) mod 5
    end
end;

procedure swrite(x,y:byte;stringa:string;c,b:byte);
var index:integer;
begin
  for index:=0 to length(stringa)-1
    do if ord(stringa[index+1])<>255
          then begin
                 schermo[(80*(y-1))+x+index]:=stringa[index+1];
                 attrib[(80*(y-1))+x+index]:=b*16+c;
               end;
end;

procedure splat;
var index1:integer;

begin
  for index1:=1 to 2000 do begin
                             phantom^[2*index1-1]:=ord(schermo[index1]);
                             phantom^[2*index1]:=attrib[index1];
                           end;
end;

procedure disegnanemico(nemico:integer);
{disegna l'i-esimo nemico alla posizione corrente}
var i1:integer;
begin
  with enemies[nemico] do
      for i1:=1 to nrighe[tipo]
        do swrite(1+pos.x,pos.y+i1,sprite[tipo,i1],enemycolor[enemies[nemico].tipo],0)
end;

procedure esplodi(nemico:integer);
{disegna un'esplosione alla posizione dell'i-esimo nemico}
var ind,n:integer;

begin
with enemies[nemico] do
  begin
    if nrighe[tipo]<3 then n:=3
       else n:=nrighe[tipo];
    for ind:=1 to n
      do begin
           if tipo=5 then begin delay(1);writeln; end;
           if 1+pos.x+length(expl^[tipo,8-expframe,ind])>LARGHEZZA
              then dec(pos.x);
           swrite(1+pos.x,pos.y+ind-1,expl^[tipo,8-expframe,ind],expcolor[expframe],0);
           {8 ä il n. di frame che compongono l'esplosione}
         end;
    if (expframe=0)and(clock mod 3=0) then
       begin
         alive:=false;
         dec(won);
       end;
    if (clock mod 3)=0 then dec(expframe);
  end
end;

procedure getnumplayers;
const frase1='Ottima scelta chi fa da sä fa per tre';
      frase2='Allora funziona cosç:';
      frase3='uno muove l''astronave';
      frase4='e l''altro spara.';
      frase5='a destra';
      frase6='a sinistra';
      frase7='Scelta eccellente se chi fa da sä fa per tre';
      frase8='chi fa in due fa per sei.';
      frase9='Uno comanda l''astronave';
var
  OrigMode: Integer;
begin
OrigMode:=LastMode;
  TextMode(CO40);
  gotoxy(13,10);
  writeln('ASPETTA !');
  intdelay(20);
  clrscr;
  gotoxy(11,10);
  writeln('Prima di cominciare...');
  intdelay(25);
  clrscr;
  gotoxy(11,9);
  writeln('un piccolo quiz ');
  gotoxy(8,11);
  writeln('sulla storia dei pirati:');
  intdelay(25);
  TextMode(OrigMode);
  writeln(' Chi indovina la citazione avrÖ in regalo una maglietta con ');
  writeln(' i nostri faccioni sopra.');
  writeln;
  writeln(' Quanti giocatori ? (pigiare tasto corrispondente)');
  writeln(' ModalitÖ supportate:');
  writeln(' a) numero giocatori 1');
  writeln(' b) numero giocatori 2');
  writeln(' c) numero giocatori 3');
  writeln(' d) numero giocatori 1+1');
  writeln(' e) numero giocatori 1+2');
  writeln(' f) numero giocatori 1+3');
  writeln(' g) numero giocatori 2+1');
  writeln(' h) numero giocatori 3+1');
  writeln(' i) numero giocatori 2+2');
  writeln(' j) numero giocatori 3+2');
  writeln(' k) numero giocatori 2+3');
  writeln(' l) numero giocatori 3+3');
  h:=readkey;
  clrscr;
  case h of
   'A','a': begin
            writeln(frase1);
            numplayer:=1;
            end;
   'B','b': begin
            writeln(frase2);
            write(frase3);write(' 1 ');writeln(frase4);
            numplayer:=1;
            end;
   'C','c': begin
            writeln(frase2);
            write(frase3);write(' 1 ');writeln(frase5);
            write(frase3);write(' 1 ');writeln(frase6);
            writeln ('                       il terzo spara.');
            numplayer:=1;
            end;
   'D','d': begin
            writeln(frase7);
            writeln(frase8);
            numplayer:=2;
            end;
   'E','e': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase9);writeln(' 1 ');
            write(frase3);write(' 2 ');writeln(frase4);
            numplayer:=2;
            end;
   'F','f': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase9);writeln(' 2 ');
            write(frase3);write(' 1 ');writeln(frase5);
            write(frase3);write(' 1 ');writeln(frase6);
            writeln ('                       il terzo spara.');
            numplayer:=2;
            end;
   'G','g': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase9);writeln(' 2 ');
            write(frase3);write(' 1 ');writeln(frase4);
            numplayer:=2;
            end;
   'H','h': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase9);writeln(' 2 ');
            write(frase3);write(' 1 ');writeln(frase5);
            write(frase3);write(' 1 ');writeln(frase6);
            writeln ('                       il terzo spara.');
            numplayer:=2;
            end;
   'I','i': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase3);write(' 1 ');writeln(frase4);
            write(frase3);write(' 2 ');writeln(frase4);
            numplayer:=2;
            end;
   'J','j': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase3);write(' 1 ');writeln(frase5);
            write(frase3);write(' 1 ');writeln(frase6);
            writeln ('                       il terzo spara.');
            write(frase3);write(' 2 ');writeln(frase4);
            numplayer:=2;
            end;
   'K','k': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase3);write(' 1 ');writeln(frase4);
            write(frase3);write(' 2 ');writeln(frase5);
            write(frase3);write(' 2 ');writeln(frase6);
            writeln ('                       il terzo spara.');
            numplayer:=2;
            end;
   'L','l': begin
            writeln(frase7);writeln(frase8);
            writeln(frase2);
            write(frase3);write(' 1 ');writeln(frase5);
            write(frase3);write(' 1 ');writeln(frase6);
            writeln ('                       il terzo spara.');
            write(frase3);write(' 2 ');writeln(frase5);
            write(frase3);write(' 2 ');writeln(frase6);
            writeln ('                       il terzo spara.');
            numplayer:=2;
            end
    else numplayer:=1;
   end;
   intdelay(40);
end;

procedure gioca(livello:integer);
{gioca l'i-esimo livello finchä non hai vinto, perso o interrotto}
var index:integer;

begin
  startsound(sound[8],8,false);
  delay(1000);
  won:=numbenemy[livello];
  if vivo[1] then energy[1]:=SCHERMI;
  if vivo[2] then energy[2]:=SCHERMI;
  position[1]:=LARGHEZZA div 2;
  position[2]:=(LARGHEZZA div 2)-7;
  fired[1]:=false;fired[2]:=false;
  reset(sfondilist);
  i:=1;
  while i<=livello*3-2 do begin readln(sfondilist,sfondofile); inc(i); end;
  read(sfondilist,nlines[livello]);
  readln(sfondilist,scvel[livello]);
  caricasfondo(sfondofile,scvel[livello],nlines[livello]);
  readln(sfondilist,sfondoname);
  for i:=1 to numbenemy[livello]
    do with enemies[i] do
         begin
           countx:=0;
           county:=0;
           incx:=0;
           incy:=0;
           alive:=true;
           sparato:=false;
           hit:=false;
           colpito:=false;
           expframe:=7;
           tipo:=tipologie[livello,i];
           forza:=strength[tipo];
           pos.x:=round(random*(LARGHEZZA-ncol[tipo]-1)+1);
           pos.y:=round(random*(ALTEZZA div 2))+1
         end;
  clrscr;
  str(livello,aux);
  swrite(LARGHEZZA+2,ALTEZZA div 2,'Livello: '+aux,7,0);
  swrite(LARGHEZZA+2,ALTEZZA div 2+1,'                  ',7,0);
  swrite(LARGHEZZA+2,ALTEZZA div 2+1,sfondoname,7,0);
  for j:=1 to numplayer
    do begin
         str(j,aux);
         swrite(LARGHEZZA+2,panel[j]-1,'RAGGIO SPETTRALE '+aux,7,0);
         swrite(LARGHEZZA+2,panel[j],'[',7,0);
         swrite(LARGHEZZA+2,panel[j]-3,'ENERGIA '+aux+':',7,0);
         swrite(LARGHEZZA+2,panel[j]-2,'[',7,0);
         swrite(LARGHEZZA+SCHERMI+3,panel[j]-2,']',7,0);
         for i:=1 to energy[j] do
           begin
             if i<=(SCHERMI div 3) then begin
                                          swrite(LARGHEZZA+SCHERMI+3-i,
                                                 panel[j]-2,'≤',11,0)
                                        end
             else if i<=((2*SCHERMI) div 3)
                     then swrite(LARGHEZZA+SCHERMI+3-i,panel[j]-2,'±',12,0)
                  else swrite(LARGHEZZA+SCHERMI+3-i,panel[j]-2,'∞',5,0);
           end;
      end;
  scroll:=0;
  clock:=0;
  repeat
    clock:=(clock+10000+1) mod (10000);
    for i:=1 to ALTEZZA do
      swrite(1,i,screen[(i-scroll+numlines) mod numlines],7,0);
    if (abs(vel)>0) then
       if (clock mod abs(vel)=0)
          then scroll:=(scroll+numlines+vel div abs(vel)) mod numlines;
    for i:=1 to numbenemy[livello] do
      with enemies[i] do
          if alive then
            begin
              if not hit then
                begin
                  muovinemico(i);
                  disegnanemico(i);
                  if (abs(ncol[tipo] div 2+pos.x-bomb[1].x)<ncol[tipo] div 2)and
                     (abs((1+pos.y)+nrighe[tipo] div 2-bomb[1].y)<(nrighe[tipo]+1) div 2)
                     and(fired[1])
                     then begin
                            if (not colpito)
                               then begin
                                      dec(forza);
                                      if not superfire[1]
                                         then fired[1]:=false
                                         else dec(forza);
                                      colpito:=true;
                                      if forza<=0 then
                                         begin
                                           hit:=true;
                                           {stopsound(1);}
                                           if tipo<>5 then
                                              startsound(sound[3],3,false)
                                              else startsound(sound[6],6,false);
                                         end
                                         else startsound(sound[4],4,false);
                                    end;
                          end
                     else colpito:=false;
                  {rileva collisione bomba2}
                  if (numplayer=2) then
                  begin if (abs(ncol[tipo] div 2+pos.x-bomb[2].x)<ncol[tipo] div 2)and
                           (abs((1+pos.y)+nrighe[tipo] div 2-bomb[2].y)<(nrighe[tipo]+1) div 2)
                           and(fired[2])and(not colpito)
                           then begin
                                  dec(forza);
                                  if not superfire[2] then fired[2]:=false
                                     else dec(forza);
                                  colpito:=true;
                                  if forza<=0 then
                                    begin
                                      hit:=true;
                                      {stopsound(1);}
                                      startsound(sound[3],3,false);
                                    end
                                    else startsound(sound[4],4,false);
                                end
                           else colpito:=false;
                  end;
                  {fine rileva collisione bomba2}
                end
              else esplodi(i);
              if (not sparato)and(round(random*1000)<aggr[tipo]*numplayer)
                 then begin
                        sparato:=true;
                        projectiles[i].x:=pos.x+ncol[tipo] div 2;
                        {if tipo=5 then projectiles[i].x:=projectiles[i].x-4;}
                        projectiles[i].y:=pos.y+nrighe[tipo];
                      end;
              if sparato then
                 begin
                   if projectiles[i].y<ALTEZZA-1 then inc(projectiles[i].y)
                      else sparato:=false;
                   if tipo<>5 then
                      swrite(projectiles[i].x,projectiles[i].y,pro1,9,0)
                      else swrite(projectiles[i].x-4,projectiles[i].y,pro4,9,0);
                   if (projectiles[i].y=ALTEZZA-1)and
                      (abs(projectiles[i].x-position[1]-3)<pro[tipo])and(vivo[1])
                      then begin
                             dec(energy[1]);
                             if (energy[1]>0)
                                then begin
                                      if (not soundplaying(2))
                                         then startsound(sound[2],2,false);
                                     end
                                else begin
                                       startsound(sound[6],6,false);
                                       delay(1000);
                                     end;
                             swrite(LARGHEZZA+3+energy[1],3,'.',7,0);
                             sparato:=false;
                           end;
                   {controllo se colpito player 2}
                   if (numplayer=2)and(vivo[2]) then
                   begin
                   if (projectiles[i].y=ALTEZZA-1)and
                      (abs(projectiles[i].x-position[2]-3)<pro[tipo])
                      then begin
                             dec(energy[2]);
                             if (energy[2]>0)
                                then begin
                                      if (not soundplaying(2))
                                         then startsound(sound[2],2,false);
                                     end
                                else begin
                                       startsound(sound[6],6,false);
                                       delay(1000);
                                     end;
                             swrite(LARGHEZZA+3+energy[2],ALTEZZA-3,'.',7,0);
                             sparato:=false;
                           end;
                   end;
                   {fine controllo se colpito 2}
                 end;
          end;
    for i:=1 to numplayer
      do begin
           swrite(LARGHEZZA+2+SUPERFIREWAIT,panel[i],']',7,0);
           if vivo[i] then swrite(position[i]+1,ALTEZZA-1,me,color[i],0);
           if (not fired[i])and(ftasto[i])and(vivo[i])
              then begin
                     if presstime[i]>=((2*SUPERFIREWAIT) div 3)-1
                            then swrite(LARGHEZZA+presstime[i]+3,panel[i],'o',7,0)
                            else swrite(LARGHEZZA+presstime[i]+3,panel[i],'.',7,0);
                     if clock mod 5=0
                     then presstime[i]:=(presstime[i]+SUPERFIREWAIT) mod (SUPERFIREWAIT-1);
                     if presstime[i]=0 then
                        sWRite(LARGHEZZA+3,panel[i],'              ',7,0);
                   end;
           if (not fired[i])and(not ftasto[i])and(fuoco[i])and(vivo[i])
              then begin
                     fired[i]:=true;
                     bomb[i].x:=position[i]+2;
                     bomb[i].y:=ALTEZZA-1;
                     superfire[i]:=presstime[i]>=(2*SUPERFIREWAIT) div 3-1;
                     presstime[i]:=0;
                     swrite(LARGHEZZA+3,panel[i],'                 ',7,0);
                     if superfire[i] then startsound(sound[1],1,false)
                        else startsound(sound[5],5,false);
                        fuoco[i]:=false;
                   end;
           if fired[i] then begin
                              {textbackground(4);}
                              if superfire[i]
                                 then swrite(bomb[i].x,bomb[i].y,pro3,14,4)
                                 else swrite(bomb[i].x,bomb[i].y,pro2,14,4);
                              {textbackground(0);}
                              if (superfire[i])and(clock mod 2=0)
                                 then dec(bomb[i].y)
                                 else if not superfire[i]
                                         then dec(bomb[i].y);
                              if bomb[i].y<1 then fired[i]:=false;
                            end;
           if (dtasto[i])and(position[i]<LARGHEZZA-5)and(vivo[i])
              then inc(position[i]);
           if (stasto[i])and(position[i]>0)and(vivo[i])
              then dec(position[i]);
         end;
    if pausa then begin
                    gotoxy(35,24);
                    write('PAUSA...');
                    repeat until not pausa;
                    gotoxy(35,24);
                    write('        ')
                  end;
    for i:=1 to numplayer do vivo[i]:=energy[i]>0;
    splat;
    if cheat[9] then begin won:=0;delay(2500); end;
    if boss then begin
                   clrscr;
                   write('segmentation fault');
                   repeat until stopboss;
                 end;
    delay(fastness);
  until (etasto)or(won=0)or((not vivo[1])and(not vivo[2]));
end;

procedure caricatipi(filename:string);
{carica il numero e i tipi dei nemici}
var f:text;
    t:byte;
    i1,i2:integer;
    h:char;

begin
  assign(f,filename);
  reset(f);
  i1:=1;i2:=1;
  while not eof(f) do
    begin
      while not eoln(f) do
        begin
          read(f,t);
          tipologie[i1,i2]:=t;
          {writeln(tipologie[i1,i2],' ',i1,' ',i2);
          delay(100);}
          inc(i2);
        end;
      numbenemy[i1]:=i2-1;
      readln(f);
      if not eof(f) then writeln('loading level:',i1);
      inc(i1);
      i2:=1;
    end;
  close(f);
end;
begin
  fast;
  for i:=1 to ALTEZZA+2 do for j:=1 to 80 do schermo[80*(i-1)+j]:=' ';
  phantom:=ptr($B800,0);
  caricatipi('types.vaf');
  initialize;
  clrscr;
  if not nsnd then goascii('ares1.mcr')
     else goascii('aresnsnd.mcr');
  startsound(Sound[0],0,false);
  intdelay(40);
  if soundplaying(0) then stopsound(0);
  if keypressed then h:=readkey;
  clrscr;writeln('vuoi leggere la mitica storia del ratto di DRINKTHEWATER?');
  h:=readkey;
  if (h='s')or(h='S') then goascii('ares2.mcr');
  getnumplayers;
  vivo[1]:=true;
  vivo[2]:=numplayer>1;
  panel[1]:=5;panel[2]:=ALTEZZA-1;{posizione y dell'indicatore i-esimo}
  color[1]:=12;color[2]:=11;{colore dell'i-esimo giocatore}
  randomize;
  new(expl);
  expl^[1,1,1]:='';expl^[1,3,1]:='ˇ_';expl^[1,4,1]:='ˇ/8\ˇ';
  expl^[1,1,2]:='Axob ';expl^[1,3,2]:='A|_|b';expl^[1,4,2]:='(∞±∞)';
  expl^[1,1,3]:='';expl^[1,3,3]:='';expl^[1,4,3]:='ˇ\8/ˇ';
  expl^[1,5,1]:='∞±≤±∞';expl^[1,6,1]:='±±±±±';expl^[1,7,1]:='∞∞∞∞∞';
  expl^[1,5,2]:='∞≤≤≤∞';expl^[1,6,2]:='±∞o∞±';expl^[1,7,2]:='∞oˇo∞';
  expl^[1,5,3]:='∞±≤±∞';expl^[1,6,3]:='±±±±±';expl^[1,7,3]:='∞∞∞∞∞';
  expl^[1,8,1]:='∞ˇ∞ˇ∞';expl^[1,2,1]:='';
  expl^[1,8,2]:='oˇˇˇo';expl^[1,2,2]:='AxOb ';{expl[i,j]: j-esima riga dello}
  expl^[1,8,3]:='∞ˇ∞ˇ∞';expl^[1,2,3]:='';{i-esimo sprite dell'esplosione}
  for i:=4 to 8 do for j:=1 to 3 do
    begin
      aux:=expl^[1,i,j];
      expl^[2,i,j]:=aux;      {gli ultimi frame sono uguali...}
      expl^[3,i,j]:=aux;
      expl^[4,i,j]:=aux;
      expl^[5,i,j]:=aux+aux+aux;
      expl^[5,i,j+3]:=aux+aux+aux;
    end;
  for i:=4 to 8 do for j:=7 to 8 do expl^[5,i,j]:='ˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇ';
  expl^[2,1,1]:='';expl^[2,1,3]:='';
  expl^[2,2,1]:='';expl^[2,2,3]:='';
  expl^[2,3,1]:='ˇˇ_';expl^[2,3,3]:='';
  expl^[2,1,2]:='A=oU ';expl^[2,2,2]:='A=0U ';expl^[2,3,2]:='A|_|U';
  for i:=1 to 3 do for j:=1 to 3 do expl^[4,j,i]:='xXxXx';
  for i:=1 to 3 do for j:=1 to 3 do expl^[3,j,i]:='XxXxX';
  for i:=1 to 8 do for j:=1 to 3 do expl^[5,j,i]:='xXxXxXxXxXxXxXxXx';
  for i:=0 to 1 do expcolor[i]:=6; {colore dell'i-esimo frame}
  for i:=2 to 3 do expcolor[i]:=4; {dell'esplosione}
  for i:=4 to 5 do expcolor[i]:=12;
  for i:=6 to 7 do expcolor[i]:=14;
  sprite[1,1]:='Ax=b';{sprite[a,b]: b-esima riga dello sprite}
  sprite[2,1]:='A=LU';{di tipo a}
  sprite[3,1]:='÷‹‹‹∑';sprite[3,2]:='≠ˇ€ˇ≠';sprite[3,3]:='ˇˇ';
  sprite[4,1]:='/ÏÏÏ\';sprite[4,2]:='› ÛÚ ›';sprite[4,3]:='ö\||/';
  sprite[5,1]:='vˇˇˇˇˇ˛˛˛˛˛˛˛ˇˇˇˇv';sprite[5,2]:='√ƒƒƒ /       \ƒƒƒ¥';
  sprite[5,3]:='≥∞∞∞Star Chief∞∞∞≥';sprite[5,4]:='ˇ\ ∞∞≥  ÈÈ  ≥∞∞ /ˇ';
  sprite[5,5]:='ˇˇ≥∞∞≥  ÈÈ  ≥∞∞≥ˇˇ';sprite[5,6]:='ˇˇ≥∞∞≥  ÈÈ  ≥∞∞≥ˇˇ';
  sprite[5,7]:='ˇˇˇ\ ∞\    /∞ /ˇˇˇ';sprite[5,8]:='ˇˇˇˇ\∞/    \∞/';
  enemycolor[1]:=10;{colore del nemico di tipo i}
  enemycolor[2]:=5;enemycolor[3]:=5;enemycolor[4]:=3;
  enemycolor[5]:=14;
  strength[1]:=1;aggr[1]:=10;{colpi per distruggere l'astronave di tipo i}
  strength[2]:=2;aggr[2]:=20;
  strength[3]:=3;aggr[3]:=20;
  strength[4]:=3;aggr[4]:=15;
  strength[5]:=20;aggr[5]:=500;
  nrighe[1]:=1;ncol[1]:=4;{n¯ righe e colonne che compongono lo}
  nrighe[2]:=1;ncol[2]:=4;{sprite dell'i-esimo tipo}
  nrighe[3]:=3;ncol[3]:=5;
  nrighe[4]:=3;ncol[4]:=6;
  nrighe[5]:=8;ncol[5]:=18;
  {scvel[1]:=3;scvel[2]:=5;scvel[3]:=2;scvel[4]:=4;scvel[5]:=-5;}
  for i:=1 to 4 do pro[i]:=2;
  pro[5]:=6;
  {velocitÖ dello scroll del livello i:1=max, inf=min, 0=schermo fisso}
  {nlines[1]:=621;nlines[2]:=266;nlines[3]:=44;nlines[4]:=377;nlines[5]:=121;}
  {numero righe dello sfondo del livello i}
  assign(sfondilist,'backlist.vaf');
  setiton;
  gioca(1);
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl01.mcr')
                     else goascii('aresl01x.mcr');
                  delay(1000);
                  setiton;
                  gioca(2);
                end;
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl02.mcr')
                     else goascii('aresl02x.mcr');
                  delay(1000);
                  setiton;
                  gioca(3)
                end;
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl03.mcr')
                     else goascii('aresl03x.mcr');
                  delay(1000);
                  setiton;
                  gioca(4);
                end;
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl04.mcr')
                     else goascii('aresl04x.mcr');
                  delay(1000);
                  setiton;
                  gioca(5);
                end;
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl05.mcr')
                     else goascii('aresl05x.mcr');
                  delay(1000);
                  setiton;
                  gioca(6);
                end;
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl06.mcr')
                     else goascii('aresl06x.mcr');
                  delay(1000);
                  setiton;
                  gioca(7);
                end;
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl07.mcr')
                     else goascii('aresl07x.mcr');
                  delay(1000);
                  setiton;
                  gioca(8);
                end;
  if won=0 then begin
                  delay(1000);
                  setitoff;
                  if not nsnd then goascii('aresl08.mcr')
                     else goascii('aresl08x.mcr');
                  delay(1000);
                  setiton;
                  gioca(9);
                end;
  setitoff;
  close(sfondilist);
  clrscr;
  if won=0 then begin if not nsnd then goascii('aresa.mcr')
                         else goascii('aresax.mcr');
                end;
  if (not vivo[1])and(not vivo[2])
     then begin if not nsnd then goascii('aresb.mcr')
                   else goascii('aresbx.mcr');
          end;
  for i:=0 to numsounds-1 do
    if sound[i]<>nil then freesound(sound[i]);
  if sharedemb then shutdownsharing;
end.