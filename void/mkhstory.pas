program mkhistory;
uses crt;

const MAXOGGETTI=500;
      MAXREAZIONI=1000;
      ENDCAUSA=9999999;

type reactions=record
                 causa:longint;
                 effetto:word;
               end;

     Tstoria=array [1..MAXREAZIONI] of reactions;

     oggetto=record
               stanza:integer; {dove si trova inizialmente}
               livello:byte;   {su che livello}
               posx,posy:byte; {in che punto (alto a sx.)}
               dimx,dimy:integer; {quanto e' grosso}
               disegno:array[0..50] of byte; {il suo disegno}
               nome:string[20]; {il suo nome}
             end;
     oggetti_tipo=array[0..MAXOGGETTI] of oggetto;
     nome_oggetti=array [0..MAXOGGETTI] of string[20];

     Pelemento=^elemento;
     elemento=record
                c:longint;
                next:Pelemento;
              end;


var caus:longint;
    causa_corrente:longint;
    causa_parz:longint;
    effett:word;
    reazione:reactions;
    nomefile,ack:string;
    cmd:char;
    storia:Tstoria;
    storia_list:Pelemento;
    f:file of Tstoria;
    objfile: file of oggetti_tipo;
    obj:^oggetti_tipo;
    objname:nome_oggetti;
    i,oggetto_corrente:integer;
    causeff:text;
    digit:byte;
    code:integer;

const VAI=0;PRENDI=1;USA=2;USAOGGETTO=9;PARLA=3;SPINGI=4;TIRA=5;
      APRI=6;CHIUDI=7;GUARDA=8;

procedure crea_storia;
var i:integer;
begin
  for i:=1 to MAXREAZIONI do
    begin
      storia[i].causa:=ENDCAUSA;
      storia[i].effetto:=i;
    end;
end;

procedure storia2list;
var runner,coda:Pelemento;
    i:integer;
begin
  storia_list:=nil;
  coda:=nil;
  i:=1;
  while (storia[i].causa<ENDCAUSA) do
    begin
      new(runner);
      if i=1 then storia_list:=runner
             else coda^.next:=runner;
      coda:=runner;
      runner^.c:=storia[i].causa;
      runner^.next:=nil;
      inc(i);
    end;
end;

procedure list2storia;
var runner,minrunner:Pelemento;
    i:integer;
    min:longint;
begin
  runner:=storia_list;
  minrunner:=nil;
  min:=storia_list^.c;
  i:=1;
  while (min<ENDCAUSA) do
    begin
      runner:=storia_list;
      min:=ENDCAUSA;
      while (runner<>nil) do
        begin
          if runner^.c<min then begin
                                  minrunner:=runner;
                                  min:=runner^.c;
                                end;
          runner:=runner^.next;
        end;
      storia[i].causa:=min;
      storia[i].effetto:=i;
      inc(i);
      minrunner^.c:=ENDCAUSA;
    end;
  while (storia_list<>nil) do
    begin
      runner:=storia_list;
      storia_list:=storia_list^.next;
      dispose(runner);
    end;
end;

procedure inserisci_causa(c:longint);
var runner,padre,nuovo:Pelemento;
    stop:boolean;
begin
  new(nuovo);
  nuovo^.c:=c;
  runner:=storia_list;
  padre:=runner;
  stop:=false;
  while (runner<>nil)and(not stop) do
    if (runner^.c<c) then begin
                            padre:=runner;
                            runner:=runner^.next;
                          end
                     else stop:=true;
  if runner<>storia_list then
     begin
       padre^.next:=nuovo;
       nuovo^.next:=runner;
     end
     else begin
            storia_list:=nuovo;
            nuovo^.next:=runner;
          end
end;

function fraseDaStoria(idx:integer):string;
var parz:longint;
    j:integer;
    st,index:string;
  begin
    parz:=storia[idx].causa;
    str(parz,st);
    case (parz div 1000000) of
     0: st:=st+' VAI ';
     1: st:=st+' PRENDI ';
     2: st:=st+' USA ';
     3: st:=st+' PARLA A ';
     4: st:=st+' SPINGI ';
     5: st:=st+' TIRA ';
     6: st:=st+' APRI ';
     7: st:=st+' CHIUDI ';
     8: st:=st+' GUARDA ';
    end;
    parz:=parz mod 1000000;
    if (parz div 1000)<>0 then st:=st+objname[parz div 1000];
    parz:=parz mod 1000;
    if parz<>0 then st:=st+' CON '+objname[parz];
    for j:=length(st)+1 to 50 do st:=st+'.';
    str(idx,index);
    st:=st+index;
    fraseDaStoria:=st;
  end;

function fraseDaCausa(c:longint):string;
var parz:longint;
    j:integer;
    st,index:string;
  begin
    parz:=c;
    str(parz,st);
    case (parz div 1000000) of
      0: st:=st+' VAI ';
      1: st:=st+' PRENDI ';
      2: st:=st+' USA ';
      3: st:=st+' PARLA A ';
      4: st:=st+' SPINGI ';
      5: st:=st+' TIRA ';
      6: st:=st+' APRI ';
      7: st:=st+' CHIUDI ';
      8: st:=st+' GUARDA ';
    end;
    parz:=parz mod 1000000;
    if (parz div 1000)<>0 then st:=st+objname[parz div 1000];
    parz:=parz mod 1000;
    if parz<>0 then st:=st+' CON '+objname[parz];
    fraseDaCausa:=st;
  end;

procedure insert;
begin
      repeat
        clrscr;
        gotoxy(1,1);
        writeln('VAI=0;PRENDI=1;USA=2;PARLA=3;SPINGI=4');
        writeln('TIRA=5;APRI=6;CHIUDI=7;GUARDA=8;');
        gotoxy(1,3);
        writeln('Causa corrente: ',fraseDaCausa(causa_corrente));
        writeln(oggetto_corrente,' ',objname[oggetto_corrente]:20,
                ' > avanti, < indietro, c ins. causa, q stop');
        ack[1]:=readkey;
        case ack[1] of
          '0','1','2','3','4','5','6','7','8','9':
             begin
               val(ack[1],digit,code);
               causa_corrente:=causa_corrente+causa_parz*digit;
               causa_parz:=causa_parz div 10;
             end;
          '-','_': begin
                     if causa_parz<1000000 then
                       begin
                         if causa_parz<>0 then causa_parz:=causa_parz*10
                            else causa_parz:=1;
                         causa_corrente:=
                           causa_corrente-(causa_corrente mod (10*causa_parz));
                       end;
                   end;
          'c','C': begin
                     write ('causa: ');readln(caus);
                     inserisci_causa(caus);
                     writeln('Causa inserita');
                     delay(1000);
                   end;
          '>': if oggetto_corrente<MAXOGGETTI then inc(oggetto_corrente);
          '<': if oggetto_corrente>1 then dec(oggetto_corrente);
          chr(13): begin
                     inserisci_causa(causa_corrente);
                     causa_corrente:=0;
                     causa_parz:=1000000;
                     writeln('Causa inserita');
                     delay(1000);
                   end;
          end;
      until ack[1]='q';
end;

procedure elimina;
var com:string;
    elim_causa:longint;
    code:integer;
    running,vecchio:Pelemento;

begin
 repeat
  clrscr;
  writeln('Quale causa devo eliminare? (ins la causa, 0 per stop)');
  readln(com);
  val(com,elim_causa,code);
  if (elim_causa<>0) then
   begin
    vecchio:=storia_list;
    running:=storia_list;
    while (running<>nil)and(running^.c<>elim_causa) do
     begin
      vecchio:=running;
      running:=running^.next;
     end;
    if running<>nil then
      begin
        if running=storia_list then storia_list:=storia_list^.next
           else vecchio^.next:=running^.next;
        dispose(running);
        writeln('Causa eliminata');
      end
      else writeln('Causa non trovata');
    delay(1000);
   end;
 until elim_causa=0;
end;

procedure stampa;
var running:Pelemento;
    righe:word;
    h:char;

begin
  running:=storia_list;
  righe:=1;
  while (running<>nil) do
    begin
      writeln(righe:3,' ',fraseDaCausa(running^.c));
      running:=running^.next;
      inc(righe);
      if (righe mod 20)=0 then h:=readkey;
    end;
  if (not ((righe mod 20)=0)) then h:=readkey;
end;

begin
  causa_corrente:=0;
  causa_parz:=1000000;
  clrscr;
  new(obj);
  writeln('nome file degli oggetti?');
  readln(nomefile);
  assign(objfile,nomefile);
  reset(objfile);
  read(objfile,obj^);
  for i:=0 to MAXOGGETTI do objname[i]:=obj^[i].nome;
  dispose(obj);
  close(objfile);
  writeln('nome file? (NO ESTENSIONE!! per default e'' .str)');
  readln(nomefile);
  assign(f,nomefile+'.str');
  {$i-}
  reset(f);
  {$i+}
  if ioresult<>0 then begin
                        rewrite(f);
                        crea_storia;
                      end
     else if filesize(f)>0 then read(f,storia);
  storia2list;
  oggetto_corrente:=1;
  repeat
    clrscr;
    writeln('(I)nserisci nuova cause; (E)limina cause esistenti; (S)tampa cause');
    cmd:=readkey;
    case cmd of
     'i','I': insert;
     'e','E': elimina;
     's','S': stampa;
    end;
  until cmd='q';
  list2storia;
  rewrite(f);
  write(f,storia);
  close(f);
  assign(causeff,nomefile+'.c_e');
  rewrite(causeff);
  for i:=1 to MAXREAZIONI do if storia[i].causa<ENDCAUSA then
    writeln(causeff,fraseDaStoria(i));
  close(causeff);
end.
