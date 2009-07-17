program creadialogo;
uses crt,dos,parlar,types;
type frasedialogo= record
                    chiparla:byte;{se e' 0 parlo io}
                                  {altrimenti e' il numero dell'oggetto
                                   che parla}
                    cosadice:string;
                   end;

var dialogo: file of frasedialogo;
    dic:frasedialogo;
    ok:char;
    numerodeldialogo:string;
    parte,i,numerovero,code:integer;
    schermo:array[1..8000] of byte;
    filedellestanze:file of stanza;
    stanzaprova:Pstanza;
    cosacambia:char;

procedure prendiinput;
begin
write('Inserire il numero del dialogo ->');
readln(numerodeldialogo);
assign(dialogo,'talks\tlk'+numerodeldialogo+'.tlk');
{$i-}
reset(dialogo);
{$i+}
if ioresult <>0 then begin
                      rewrite(dialogo);
                      writeln('NUOVO DIALOGO!!');
                      repeat until keypressed;
                     end;
end;

begin
clrscr;
prendiinput;
repeat
clrscr;
writeln(' Numero del dialogo:',numerodeldialogo);
writeln(' V vede dialogo fatto | I inserisce nuova parte | C cambia parte');
writeln(' H cambia dialogo | Q esce');
ok:=readkey;
case ok of
'h','H': begin
          close(dialogo);
          clrscr;
          prendiinput;
         end;
'i','I': begin
          write('Chi parla? ');
          readln(dic.chiparla);
          if dic.chiparla=0 then writeln('Cosa dico?')
                            else writeln('Cosa dice?');
          readln(dic.cosadice);
          seek(dialogo,filesize(dialogo));
          write(dialogo,dic);
         end;
'v','V': begin
          new(stanzaprova);
          assign(filedellestanze,'room');
          reset(filedellestanze);
          read(filedellestanze,stanzaprova^);
          close(filedellestanze);
          for i:=1 to 8000 do schermo[i]:=2;
          close(dialogo);
          val(numerodeldialogo,numerovero,code);
          textmode(CO80+FONT8x8);
          chiacchiera(10,10,numerovero,schermo,stanzaprova,'oggetti');
          textmode(CO80);
          assign(dialogo,'talks\tlk'+numerodeldialogo+'.tlk');
          reset(dialogo);
          seek(dialogo,filesize(dialogo));
          dispose(stanzaprova);
          end;
'c','C' : begin
          writeln(' Parti presenti :',filesize(dialogo));
          repeat writeln('Quale parte devo cambiare?');
                 readln(parte);
          until parte<=filesize(dialogo);
          writeln('Parte presente ora:');
          seek(dialogo,parte-1);
          read(dialogo,dic);
          writeln('CHI: ',dic.chiparla);
          writeln('COSA: ',dic.cosadice);
          write('Cambia cosa?(cHi o Cosa)');readln(cosacambia);
          case cosacambia of
          'h','H': begin
                    write('Chi parla? ');
                    readln(dic.chiparla);
                   end;
          'c','C': begin
                    if dic.chiparla=0 then writeln('Cosa dico?')
                                      else writeln('Cosa dice?');
                    readln(dic.cosadice);
                    seek(dialogo,parte-1);
                   end;
          end;
          seek(dialogo,parte-1);
          write(dialogo,dic);
          end;
end;
until (ok='q') or (ok='Q');
close(dialogo);
end.
