program aposto;
uses crt,dos;
var origine,destinazione:text;
    linea,filo,dfilo:string;

begin
write('Nome del file da sistemare?');readln(filo);
write('Nome del file destinazione?');readln(dfilo);
assign(origine,filo);
assign(destinazione,dfilo);
{$i-}
reset(origine);rewrite(destinazione);
{$i+}
if ioresult<>0 then
               begin
                writeln('FILE NON TROVATO');
                repeat until keypressed;
               end
               else
               begin

               while not eof(origine) do
               begin
                readln(origine,linea);
                if length(linea)>1 then
                                   writeln(destinazione,linea);

               end;
               close(origine);close(destinazione);
               end;
end.