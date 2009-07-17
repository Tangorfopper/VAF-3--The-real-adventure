program cryptafrasi;
{programma di test per cripitare/decriptare le frasi}
uses vaf_unit;
var f:file of string;
    var s:string;
    i:longint;

begin
 readln(s);
 assign(f,s);
 reset(f);
 i:=0;
 while not(eof(f)) do
  begin
    read(f,s);
    cripta(s);
    seek(f,i);
    write(f,s);
    inc(i);
  end;
 close(f);
end.
