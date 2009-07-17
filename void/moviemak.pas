{$M 16384 0 200000}
program moviemaker;
uses dos,crt,anim,musnsnd;
const MAXAZIONI=255;
      STOP=255;
      MAXFRAMES=100;
type action=record
             n_fotogramma:word; {# del fotogramma da stampare}
             suono:byte;        {# del suono da produrre}
             ritardo:word;      {# millisecondi da asp. per il pross. frame}
            end;
     Tfotogramma=array [1..8000] of byte;
     actionset=array [0..MAXAZIONI] of action;

var comando,comando2:char;
    corrente:boolean;
    indicenuova,animazionecorrente:integer;
    llaa:file of actionset;
    fcif:file of Tfotogramma;
    stringa,risposta:string;
    azionicorrenti:actionset;

procedure aprifile;
begin
 assign(llaa,'clips\actions.dat');
 {$i-}
 reset(llaa);
 {$i+}
 if ioresult<>0 then
                begin
                 rewrite(llaa);
                 animazionecorrente:=1;
                end
                else
                seek(llaa,animazionecorrente-1);
 str(animazionecorrente,stringa);
 assign(fcif,'clips\mov'+stringa+'.mov');
 {$i-}
 reset(fcif);
 {$i+}
 if ioresult<>0 then rewrite(fcif);
end;

procedure disegnaildisegnonelframe(nomedelframe:string;dadove:longint);
type disegni=array [1..6560] of byte;
var frames:string;
    fof:file of disegni;
    frame:Tfotogramma;
    disegno:disegni;
    i:integer;
begin
 assign(fof,nomedelframe);
 {$i-}
 reset(fof);
 {$i+}
 if ioresult<>0 then writeln('FILE NON TROVATO')
                else begin
                      read(fof,disegno);
                      seek(fcif,dadove);
                      for i:=1 to 800 do frame[i]:=0;
                      for i:=1 to 6560 do frame[i+800]:=disegno[i];
                      for i:=7361 to 8000 do frame[i]:=0;
                      write(fcif,frame);
                      close(fof);
                     end;
end;

procedure aggiungiframe;
var frames:string;
begin
 writeln('Frame presenti:',filesize(fcif));
 write('Nome del frame da aggiungere ->  ');readln(frames);
 disegnaildisegnonelframe(frames,filesize(fcif));
end;

procedure cambiaframe;
var frames:string;
    numframe:integer;
begin
 writeln('Numero del frame da modificare:');
 readln(numframe);
 writeln('Nome del disegno da inserire');readln(frames);
 disegnaildisegnonelframe(frames,numframe-1);
end;

procedure visualizzaactions;
var a:integer;
begin
 a:=1;
 while azionicorrenti[a].n_fotogramma<>STOP do
  begin
   if a=1 then writeln(' Azione Num fotogr  Suono  Ritardo');
   if a=20 then begin gotoxy(35,1);
                      writeln(' Azione Num fotogr  Suono  Ritardo');
                end;
   if a>=20 then gotoxy (35,a-18);            writeln('   ',a:3,'      ',azionicorrenti[a].n_fotogramma:3,
   '     ',azionicorrenti[a].suono:3,'      ',azionicorrenti[a].ritardo:4);
   inc(a);
  end;
end;

procedure cambiaactions;
var numfotog,tochange:integer;
    comd:char;
begin
 writeln('Quale azione devo cambiare?');readln(tochange);
 writeln('Numero fotogramma:',azionicorrenti[tochange].n_fotogramma);
 writeln('Suono:', azionicorrenti[tochange].suono);
 writeln('Ritardo:',azionicorrenti[tochange].ritardo);writeln;
 repeat
 writeln('F fotogramma | S suono | R ritardo | Q finisce');
 comd:=readkey;
 case comd of
  'f','F': begin
            repeat
            write('Numero nuovo fotogramma:');readln(numfotog);
            if (numfotog>filesize(fcif))and(numfotog<>STOP) then writeln('Fotogramma non presente');
            until numfotog<=filesize(fcif)or(numfotog=STOP);
            azionicorrenti[tochange].n_fotogramma:=numfotog;
            writeln;
           end;
  's','S': begin
            write('Numero del suono:');readln(azionicorrenti[tochange].suono);
           end;
  'r','R': begin
            write('Ritardo (in millisecondi):');readln(azionicorrenti[tochange].ritardo);
            writeln;
           end;
 end;
 until (comd='q') or (comd='Q');
end;

procedure nuovaactions;
var numfotog,a:integer;
    comd:char;
begin
 a:=1;
 while azionicorrenti[a].n_fotogramma<>STOP do a:=a+1;
 writeln('Numero fotogramma:',azionicorrenti[a].n_fotogramma);
 writeln('Suono:', azionicorrenti[a].suono);
 writeln('Ritardo:',azionicorrenti[a].ritardo);writeln;
 repeat
 writeln('F fotogramma | S suono | R ritardo | Q finisce');
 comd:=readkey;
 case comd of
  'f','F': begin
            repeat
            write('Numero nuovo fotogramma:');readln(numfotog);
            if (numfotog>filesize(fcif))and(numfotog<>STOP) then writeln('Fotogramma non presente');
            until numfotog<=filesize(fcif)or(numfotog=STOP);
            azionicorrenti[a].n_fotogramma:=numfotog;
            writeln;
           end;
  's','S': begin
            write('Numero del suono:');readln(azionicorrenti[a].suono);
           end;
  'r','R': begin
            write('Ritardo (in millisecondi):');readln(azionicorrenti[a].ritardo);
           end;
 end;
 until (comd='q') or (comd='Q');
end;

procedure caricaazionicorrenti;
var j:integer;
begin
 {$i-}
 seek(llaa,animazionecorrente-1);
 read(llaa,azionicorrenti);
 {$i+}
 if ioresult<>0 then for j:=0 to MAXAZIONI do
                       begin
                        azionicorrenti[j].n_fotogramma:=255;
                        if j=0 then azionicorrenti[j].n_fotogramma:=0;
                        azionicorrenti[j].suono:=0;
                        azionicorrenti[j].ritardo:=0;
                       end;
end;

procedure salvaazionicorrenti;
begin
 seek(llaa,animazionecorrente-1);
 write(llaa,azionicorrenti);
end;

procedure modificaactions;
var comando:char;
begin
 repeat
 clrscr;
 visualizzaactions;
 gotoxy(1,22); writeln(' MODIFICA AZIONI');
 writeln(' C cambia una azione | N nuova actions | Q esce');
 comando:=readkey;
 case comando of
 'c','C': cambiaactions;
 'n','N': nuovaactions;
 end;
 until (comando='q') or (comando='Q');
end;

procedure uniscele2animazioni(tipo:string);
var azionidaunire:actionset;
    fdoextnome,fdaextnome,stinga:string;
    fcifda:file of Tfotogramma;
    fdoext:file of actionset;
    dis:Tfotogramma;
    a,b,quale:integer;

begin
 if tipo='e' then
              begin
               writeln('Da quale file devo importare?');
               write('(nome file delle azioni)');
               readln(fdoextnome);
               writeln('(nome file animazione)');
               readln(fdaextnome);
               assign(fdoext,fdoextnome);
               assign(fcifda,fdaextnome);
               reset(fdoext);
               reset(fcifda);
               repeat
                write('Quale animazione devo aggiungere ->');readln(quale);
                if quale>filesize(fdoext) then writeln(' ANIMAZIONE NON PRESENTE ');
              until quale<=filesize(fdoext);
              seek(fdoext,quale-1);
              read(fdoext,azionidaunire);
              end;
 if tipo='i'then
             begin
              repeat
               write('Quale animazione devo aggiungere ->');readln(quale);
               if quale>filesize(llaa) then writeln(' ANIMAZIONE NON PRESENTE ');
              until quale<=filesize(llaa);
              seek(llaa,quale-1);
              read(llaa,azionidaunire);
              str(quale,stinga);
              assign(fcifda,'clips\mov'+stinga+'.mov');
              reset(fcifda);
             end;
 a:=1;
 while azionicorrenti[a].n_fotogramma<>stop do a:=a+1;
 b:=1;
 while azionidaunire[b].n_fotogramma<>stop do
                                           begin
                                            azionicorrenti[a].n_fotogramma:=
                                            azionidaunire[b].n_fotogramma+filesize(fcif);
                                            azionicorrenti[a].suono:=
                                            azionidaunire[b].suono;
                                            azionicorrenti[a].ritardo:=
                                            azionidaunire[b].ritardo;
                                            a:=a+1;b:=b+1;
                                           end;

 seek(fcif,filesize(fcif));
 while not eof(fcifda) do
                       begin
                        read(fcifda,dis);
                        write(fcif,dis);
                       end;
 close(fcifda);
end;

procedure cambiasuono;
begin
 writeln('Musica attuale:',azionicorrenti[0].n_fotogramma);
 write('Nuovo suono -> ');readln(azionicorrenti[0].n_fotogramma);
end;

procedure catturaframe;
var i,numframcatt:integer;
    nomeframecatturato:string;
    cursore:byte;
    frame:^Tfotogramma;
    ffc:file of byte;
begin
 write('Numero del frame da catturare (numero frame presenti ora=',filesize(fcif),')');
 repeat
 readln(numframcatt);
 if numframcatt>filesize(fcif) then writeln('Frame non presente (cretino)');
 until numframcatt<=filesize(fcif);
 write('Nome del file da salvare:');readln(nomeframecatturato);
 assign(ffc,nomeframecatturato);
 rewrite(ffc);
 seek(fcif,numframcatt-1);
 new(frame);
 read(fcif,frame^);
 for i:=1 to 6560 do write(ffc,frame^[i+800]);
 close(ffc);
 end;

{inizio programma principale}
begin
 no_sound:=false;
 no_music:=false;
 init_Sound_Blaster;
 volume_level:=10;
 changed_music:=false;
 animazionecorrente:=1;
 repeat
  clrscr;
  writeln('Q esce | W vede animazione corrente');
  writeln('C cambia animazione corrente (',animazionecorrente,')| E crea animazione');
  writeln('M modifica azione corrente | J unisce due animazioni (corrente+un''altra)');
  comando:=readkey;
  case comando of
  'w','W': begin
            textmode(CO80+FONT8x8);
            if animazionecorrente<>0 then play_anim(animazionecorrente,true);
            if changed_music then
              begin
                dealloca_S3M;
                changed_music:=false;
                suona(250,FOR_MAIN)
              end;
            textmode(co80);
           end;
  'c','C': begin
            aprifile;
            write('Indice animazione:');readln(indicenuova);
            if (indicenuova>filesize(llaa))or(indicenuova<1) then begin
                                                writeln('Animazione non presente');
                                                repeat until keypressed;
                                               end
                                          else animazionecorrente:=indicenuova;
           close(llaa);close(fcif);
           end;
  'e','E': begin
           aprifile;
           animazionecorrente:=filesize(llaa)+1;
           seek(llaa,animazionecorrente);
           caricaazionicorrenti;
           close(llaa);close(fcif);
           aprifile;
           repeat
            clrscr;
            writeln('CREAZIONE ANIMAZIONE',animazionecorrente);
            writeln('F aggiunge frame | A modifica actions | S suono | Q finito');
            comando2:=readkey;
            case comando2 of
            'f','F': aggiungiframe;
            'a','A': modificaactions;
            's','S': cambiasuono;
            end;
           until (comando2='q') or (comando2='Q');
           salvaazionicorrenti;
           close(llaa);
           close(fcif);
           end;
  'm','M': begin
           aprifile;
           caricaazionicorrenti;
           repeat
            clrscr;
            writeln('MODIFICA ANIMAZIONE ',animazionecorrente);
            writeln('C cambia frame | F aggiunge frame | A modifica actions | S suono');
            writeln('T cattura frame | Q finito');
            comando2:=readkey;
            case comando2 of
            'f','F': aggiungiframe;
            'a','A': modificaactions;
            'c','C': cambiaframe;
            's','S': cambiasuono;
            't','T': catturaframe;
            end;
           until (comando2='q') or (comando2='Q');
           salvaazionicorrenti;
           close(llaa);
           close(fcif);
           end;
  'j','J': begin
            clrscr;
            aprifile;
            caricaazionicorrenti;
            write('Unione dall''interno o dall''esterno?(i/e)');
            readln(risposta);
            uniscele2animazioni(risposta);
            salvaazionicorrenti;
            close(llaa);close(fcif);
           end;
  end;
 until (comando='q') or (comando='Q');
end.


