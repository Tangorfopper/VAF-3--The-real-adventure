program mkistrfile;
uses types,crt,vaf_unit;

{serve per generare le possibili
"reazioni" (istr sta per 'istruzioni'). Ogni 'istruzione' e' un record
che codifica tutto quello che puo' succedere: parte un'animazione, un
dialogo, si acquisisce un oggetto, ci si sposta in un'altra stanza, ecc.
ecc.

Questo programma si usava piu' o meno a partire dal risultato di
"mkhstory", che generava il file ".c_e", e che definiva tutte le azioni
possibili oltre a quelle default, associandole a degli indici di
"effetti" generati automaticamente. Quindi per ogni azione definita
c'era un indice di "effetto", relativamente al quale si potevano
definire fino a 3 possibili "istruzioni" (quale scegliere dipendeva
dallo stato dei vincoli -- un sistema a regole, diciamo...)}

type reazione_list=^elemento;
     elemento=record
                e:word;            {effetto}
                r:reazione;        {reazione}
                next:reazione_list;
                previous:reazione_list;
              end;

var nomefile,ack,frasifile:string;
    f:file of reazione;
    g:text;
    ff:string_file;
    no_file_frasi:boolean;
    istr:reazione;
    i,j:integer;
    stop:boolean;
    istrlist,current_reaction:reazione_list;
    evento:char;
    effetto_corrente:word;
    max_effetti:word;
    alternativa_corrente:1..3;
    esci,no_file:boolean;
    x:byte;

const VAI=0;PRENDI=1;USA=2;USAOGGETTO=9;PARLA=3;SPINGI=4;TIRA=5;
      APRI=6;CHIUDI=7;GUARDA=8;

procedure file2list;
var runner,old:reazione_list;
    ind:word;
begin
  ind:=0;
  old:=nil;
  istrlist:=nil;
  while (not eof(f)) do
    begin
      inc(ind);
      new(runner);
      runner^.e:=ind;
      runner^.next:=nil;
      runner^.previous:=old;
      read(f,runner^.r);
      if ind=1 then istrlist:=runner;
      old^.next:=runner;
      old:=runner;
    end;
  max_effetti:=ind;
  if ind<>0 then alternativa_corrente:=1;
  effetto_corrente:=1;
end;

procedure stampa_situazione;
var i,j:word;
    explain,frase_da_dire:string;
begin
  clrscr;
  if (not no_file)and(effetto_corrente<>0)
   then begin
    reset(g);
    for i:=1 to effetto_corrente do
     if not eof(g) then readln(g,explain)
       else explain:='Causa non ancora definita';
   end
   else explain:='Causa non ancora definita';
  gotoxy(1,1);
  write('FILE: ''',nomefile,''' n. effetti: ',max_effetti,' Frasi: ');
  if no_file_frasi then writeln('No File!') else writeln(filesize(ff));
  writeln('Effetto corrente: ',effetto_corrente,' ',explain);
  if current_reaction<>nil
    then with current_reaction^.r do
           begin
             write('N. alternative: ',n_alt);
             writeln('  alt. corrente: ',alternativa_corrente);
             writeln;
             with does[alternativa_corrente] do
              begin
               write('Vincoli da verificare: ');
               for i:=1 to 5 do if proof[i]<>0 then
                 write(proof[i],' ');
               writeln;
               write('Oggetti da guadagnare: ');
               for i:=1 to 3 do if guadagna[i]<>0 then
                 write(guadagna[i],' ');
               writeln;
               write('Oggetti da perdere: ');
               for i:=1 to 3 do if perdi[i]<>0 then
                 write(perdi[i],' ');
               writeln;
               writeln('Frase da dire: ',meffeig);
               if no_file_frasi then writeln
                 else if meffeig=0 then writeln
                 else if meffeig>filesize(ff) then writeln
                 else begin
                       seek(ff,meffeig-1);
                       carica_frase(ff,frase_da_dire);
                       writeln(frase_da_dire);
                      end;
               writeln('Dialogo da fare: ',dialogo);
               write('Vincoli da rimuovere: ');
               for i:=1 to 10 do if vinc[i]<>0 then
                 write(vinc[i],' ');
               writeln;
               writeln('Animazione da eseguire: ',special,
                       '    Suono da emettere: ',suono);
               writeln('Stanza in cui reagire: ',stanza_giusta);
               writeln('OK prendi oggetto: ',prendi);
               write('Oggetti da scambiare: ');
               for i:=1 to 5 do if swapobj[i,1]<>0 then
                 write(swapobj[i,1],'<->',swapobj[i,2],' ');
               writeln;
               write('Si teletrasporta nella stanza: ',teleport[1],' ');
               writeln('alla pos: ',teleport[2],',',teleport[3]);
               gotoxy(1,20);
               writeln('(A)lternative; (V)incoli da verificare; o(G)getti da guadagnare');
               writeln('ogg(E)tti da perdere; (F)rase; (D)ialogo; vincoli da (R)imuovere; tele(P)ort');
               writeln('an(I)mazione; (S)uono; s(T)anza; prendi (O)ggetto; s(C)ambia ogg.');
               writeln('6,4: inc dec effetto, 8,2: inc dec alternativa');
              end;
           end;
  gotoxy(1,19); write('(N)uovo elemento; sa(L)va file; (Z): inserici; (X): cancella');
end;

procedure raccogli_input;
begin
  evento:=readkey;
end;

procedure azzera_reazione(var re:reazione);
var indice,j,k:integer;
begin
  alternativa_corrente:=1;
  with re do
    begin
      n_alt:=1;
      for indice:=1 to 3 do
        with does[indice] do
          begin
            for j:=1 to 5 do proof[j]:=0;
            for j:=1 to 3 do begin guadagna[j]:=0; perdi[j]:=0; end;
            meffeig:=0;
            dialogo:=0;
            for j:=1 to 10 do vinc[j]:=0;
            special:=0;
            prendi:=false;
            stanza_giusta:=0;
            for j:=1 to 5 do begin swapobj[j,1]:=0; swapobj[j,2]:=0; end;
            suono:=0;
            for j:=1 to 3 do teleport[j]:=0;
          end;
    end;
end;

procedure echo(frase:string);
begin
  gotoxy(2,24);
  writeln(frase);
end;

function st(numero:integer):string;
var s:string;
begin
  str(numero,s);
  st:=s;
end;

procedure esegui_input;
var newelem,runner,prev:reazione_list;
    indice,ind:byte;
    intro:word;
    numero:word;
    fintro:integer;
    stringa:string;

procedure aggiorna_effetti;
begin
             numero:=1;
             runner:=istrlist;
             while runner<>nil do
              begin
                runner^.e:=numero;
                runner:=runner^.next;
                inc(numero);
              end;
end;

begin
  case evento of
   'q','Q':esci:=true; {esce}
   'n','N':begin       {nuova reazione al prossimo effetto}
             if current_reaction<>nil then
               while current_reaction^.next<>nil do
                 current_reaction:=current_reaction^.next;
             new(newelem);
             azzera_reazione(newelem^.r);
             if max_effetti<>0 then current_reaction^.next:=newelem
                               else istrlist:=newelem;
             newelem^.previous:=current_reaction;
             newelem^.next:=nil;
             newelem^.e:=max_effetti+1;
             current_reaction:=newelem;
             inc(max_effetti);
             effetto_corrente:=max_effetti;
             alternativa_corrente:=1;
           end;
   '6': if current_reaction^.next<>nil then {va al prossimo effetto}
          begin
            inc(effetto_corrente);
            current_reaction:=current_reaction^.next;
          end;
   '4': if current_reaction^.previous<>nil then   {va all'effetto precedente}
          begin
            dec(effetto_corrente);
            current_reaction:=current_reaction^.previous;
          end;
   '8': if alternativa_corrente<current_reaction^.r.n_alt {prossima alternativa}
           then inc(alternativa_corrente);
   '2': if alternativa_corrente>1 then dec(alternativa_corrente);
   'A','a': begin
              echo('Quante alternative?'); {alternativa precedente}
              readln(current_reaction^.r.n_alt);
            end;
   'Z','z': begin {inserisce PRIMA del corrente}
             new(newelem);
             azzera_reazione(newelem^.r);
             if current_reaction<>nil then
               prev:=current_reaction^.previous
               else prev:=nil;
             if prev<>nil then prev^.next:=newelem;
             newelem^.previous:=prev;
             if current_reaction<>nil
               then current_reaction^.previous:=newelem;
             newelem^.next:=current_reaction;
             if (max_effetti=0)or(effetto_corrente=1) then istrlist:=newelem;
             current_reaction:=newelem;
             aggiorna_effetti;
             inc(max_effetti);
             effetto_corrente:=newelem^.e;
             alternativa_corrente:=1;
            end;
   'X','x': begin  {Elimina la pos. corrente}
              if current_reaction<>nil then
               begin
                 if effetto_corrente>1 then
                  begin
                   prev:=current_reaction^.previous;
                   if prev<>nil then prev^.next:=current_reaction^.next;
                  end
                  else begin
                        istrlist:=current_reaction^.next;
                        prev:=nil;
                       end;
                 runner:=current_reaction^.next;
                 if runner<>nil then runner^.previous:=prev;
                 dispose(current_reaction);
                 if effetto_corrente>1 then current_reaction:=prev
                    else current_reaction:=runner;
                 aggiorna_effetti;
                 dec(max_effetti);
                 if current_reaction<>nil
                   then effetto_corrente:=current_reaction^.e
                   else effetto_corrente:=0;
                 alternativa_corrente:=1;
               end;
            end;
   'V','v': begin           {modifica i vincoli da verificare}
              indice:=1;
              with current_reaction^.r.does[alternativa_corrente] do
                begin
                  repeat
                    echo('Inserisci proof['+st(indice)+']');
                    readln(intro);
                    proof[indice]:=intro;
                    inc(indice);
                  until (intro=0)or(indice>5);
                  for ind:=indice to 5 do proof[ind]:=0;
                end;
            end;
   'F','f': begin        {frase da dire}
              echo('Inserisci l''indice della frase da dire (0 nessuna, n<0 edita frase -n)');
              readln(fintro);
              if fintro>=0 then
               current_reaction^.r.does[alternativa_corrente].meffeig:=fintro
               else if not(no_file_frasi) then
                begin
                 if -fintro<=filesize(ff)+1 then
                  begin
                   seek(ff,-fintro-1);
                   readln(stringa);
                   cripta(stringa);
                   write(ff,stringa);
                   current_reaction^.r.does[alternativa_corrente].meffeig:=-fintro;
                  end;
                end;
            end;
   'D','d': begin         {quale dialogo}
              echo('Inserisci l''indice del dialogo da attivare (0 nessuno)');
              readln(intro);
              current_reaction^.r.does[alternativa_corrente].dialogo:=intro;
            end;
   'R','r': begin         {vincoli da rimuovere}
              indice:=1;
              with current_reaction^.r.does[alternativa_corrente] do
               begin
                repeat
                  echo('Inserisci l''indice dell'''+st(indice)+
                       '-esimo vincolo da rimuovere');
                  readln(intro);
                  vinc[indice]:=intro;
                  inc(indice);
                until (intro=0)or(indice>10);
                for ind:=indice to 10 do vinc[ind]:=0;
               end;
            end;
   'I','i': begin         {animazione da mostrare}
              echo('Inserisci l''indice della animazione da mostrare (0 nessuna)');
              readln(intro);
              current_reaction^.r.does[alternativa_corrente].special:=intro;
            end;
   'S','s': begin         {suono da suonare}
              echo('Inserisci l''indice del suono da emettere (0 nessuno)');
              readln(intro);
              current_reaction^.r.does[alternativa_corrente].suono:=intro;
            end;
   'T','t': begin         {stanza in cui reagire}
              echo('Dimmi in quale stanza devo reagire (0 tutte)');
              readln(intro);
              current_reaction^.r.does[alternativa_corrente].stanza_giusta:=intro;
            end;
   'O','o': begin         {Posso prendere?}
              echo('Se l''azione e'' prendi, posso prendere l''oggetto? (0=no, n<>0 si)');
              readln(intro);
              current_reaction^.r.does[alternativa_corrente].prendi:=intro<>0;
            end;
   'C','c': begin         {scambia oggetti}
              indice:=1;
              repeat
                echo('Quale oggetto devo scambiare? (e'' il '+st(indice)+'o, 0 per stop)');
                readln(intro);
                current_reaction^.r.does[alternativa_corrente].swapobj[indice,1]:=intro;
                if intro<>0 then
                 begin
                  echo('OK. Scambio l''oggetto '+st(intro)+' con chi?');
                  readln(intro);
                  current_reaction^.r.does[alternativa_corrente].swapobj[indice,2]:=intro;
                 end;
                inc(indice);
              until (intro=0)or(indice>5);
              for ind:=indice to 5 do current_reaction^.r.does[alternativa_corrente].swapobj[ind,1]:=0;
            end;
   'G','g': begin
              indice:=1;
              with current_reaction^.r.does[alternativa_corrente] do
                begin
                  repeat
                   echo('inserisci l''oggetto da guadagnare n.'+st(indice)+' (0 nessuno)');
                   readln(intro);
                   guadagna[indice]:=intro;
                   inc(indice);
                  until (intro=0)or(indice>3);
                  for ind:=indice to 3 do guadagna[ind]:=0;
                end;
            end;
   'E','e': begin
              indice:=1;
              with current_reaction^.r.does[alternativa_corrente] do
                begin
                  repeat
                   echo('inserisci l''oggetto da perdere n.'+st(indice)+' (0 nessuno)');
                   readln(intro);
                   perdi[indice]:=intro;
                   inc(indice);
                  until (intro=0)or(indice>3);
                  for ind:=indice to 3 do perdi[ind]:=0;
                end;
            end;
   'P','p': begin
              for indice:=1 to 3 do
               begin
                 case indice of
                  1: echo('Stanza in cui apparire? ');
                  2: echo('Posizione x? ');
                  3: echo('Posizione y? ');
                 end;
                 readln(current_reaction^.r.does[alternativa_corrente].teleport[indice]);
               end;
            end;
   'L','l': begin         {salva file}
              runner:=istrlist;
              rewrite(f);
              while runner<>nil do
                begin
                  write(f,runner^.r);
                  runner:=runner^.next;
                end;
              echo('File salvato');
              repeat until keypressed;
            end;
  end;
end;

begin
  clrscr;
  write('Nome del file delle reazioni?');
  readln(nomefile);
  assign(f,nomefile);
  {$i-}
  reset(f);
  {$i+}
  if ioresult <> 0 then begin
                          rewrite(f);
                          writeln('nuovo file creato.');
                          delay(1000);
                        end;
  file2list;
  writeln('Nome del file causa-effetto? (no estensione)');
  readln(nomefile);
  assign(g,nomefile+'.c_e');
  {$i-}reset(g);{$i+}
  no_file:=ioresult<>0;
  writeln('Nome del file delle frasi?');
  readln(frasifile);
  assign(ff,frasifile);
  {$i-}reset(ff);{$i+}
  no_file_frasi:=ioresult<>0;
  if no_file_frasi then {$i-}rewrite(ff);{$i+}
  no_file_frasi:=ioresult<>0;
  esci:=false;
  current_reaction:=istrlist;
  repeat
    stampa_situazione;
    raccogli_input;
    esegui_input;
  until esci;
  while istrlist<>nil do
    begin
      if istrlist^.next<>nil then
        begin
          istrlist:=istrlist^.next;
          dispose(istrlist^.previous);
        end
        else begin
               dispose(istrlist);
               istrlist:=nil;
             end;
    end;
  close(f);
  if not(no_file) then close(g);
  if not(no_file_frasi) then close(ff);
  clrscr;
end.
