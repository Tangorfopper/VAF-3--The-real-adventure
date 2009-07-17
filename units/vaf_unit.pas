unit vaf_unit;
interface
uses types;

procedure hide_cursor;
procedure view_cursor;
procedure intdelay(value:word);
procedure swritexy(x,y:integer;colore,sfondo:byte;s:string;var dove:array of byte);
procedure center(y:integer;colore,sfondo:byte;s:string;var dove:array of byte);
procedure forecolor(x1,y1,x2,y2,colore:byte;var dove:array of byte);
procedure backcolor(x1,y1,x2,y2,sfondo:byte;var dove:array of byte);
procedure disegna_maschera(var dove:array of byte);
procedure cripta(var f:string);
procedure decripta(var f:string);
procedure carica_frase(var from:string_file; var f:string);

implementation

uses crt,dos,mouse;

procedure hide_cursor; assembler;
 asm
   mov  ah,01
   mov  cx,32*256+32
   int  10h
 end;

procedure view_cursor; assembler;
 asm
   mov  ah,01
   mov  cx,15*256+16
   int  10h
 end;

procedure intdelay(value:word); {da mettere in un unit}
var ind1:word;ch:char;
  begin
    ind1:=1;
    repeat
      delay(10);
      inc(ind1);
    until (keypressed)or(ind1>value)or(right_button);
    if keypressed then ch:=readkey;
    repeat until not(right_button);
  end;

procedure swritexy(x,y:integer;colore,sfondo:byte;s:string;var dove:array of byte);
{colore=16 per cambiare solo lo sfondo,
 sfondo=16 per cambiare solo il colore}
{HO AGGIUNTO +1 ALL'ARRAY DOVE PERCHE' IN SCREEN PARTE DA UNO E QUI DA ZERO}
var ind1,par1:integer;
    over1,over2:boolean;
  begin
    par1:=((y-1)*80+x-1)*2;
    ind1:=1-1;{<-- prima era 1}
    over1:=sfondo=16;
    over2:=colore=16;
    while ind1<=2*length(s)-1 {<-- prima era 2*lengt(s)}
      do if (par1+ind1>=0)and(par1+ind1<8000-1) then
           begin
             dove[par1+ind1]:=ord(s[(ind1 div 2)+1]);
             if over1 then dove[par1+ind1+1]:=(dove[par1+ind1+1])and(240)+colore
             else if over2 then dove[par1+ind1+1]:=(dove[par1+ind1+1])and(16)+16*sfondo
             else dove[par1+ind1+1]:=16*sfondo+colore;
             ind1:=ind1+2;
           end
           else ind1:=ind1+2;
  end;

procedure center(y:integer;colore,sfondo:byte;s:string;var dove:array of byte);
  begin
    swritexy(40-length(s) div 2,y,colore,sfondo,s,dove);
  end;

procedure forecolor(x1,y1,x2,y2,colore:byte;var dove:array of byte);
var ind1,ind2:integer;
  begin
    if (x1<=x2)and(y1<=y2)
      then
        for ind1:=y1 to y2 do
          for ind2:=(80*(ind1-1)+x1) to (80*(ind1-1)+x2)
            do dove[2*ind2-1]:=colore+dove[2*ind2-1] div 16;
  end;         {      ^^^^^^^ prima era    ^^^^^^^^ senza il -1}

procedure backcolor(x1,y1,x2,y2,sfondo:byte;var dove:array of byte);
var ind1,ind2:integer;
  begin
    if (x1<=x2)and(y1<=y2)
      then
        for ind1:=y1 to y2 do
          for ind2:=(80*(ind1-1)+x1) to (80*(ind1-1)+x2)
            do dove[2*ind2-1]:=sfondo*16+dove[2*ind2-1] mod 16;
  end;

procedure disegna_maschera(var dove:array of byte);
var s,sap:string[8];
    hh,mm,ss,s100:word;
  begin
    swritexy(1,42,11,0,'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',dove);
    swritexy(1,43,11,0,'บ                                                                              บ',dove);
    swritexy(1,44,11,0,'ฬอออออออออัอออออออออัออออออออออัอออออออออออออออออออออออออออออออออออออออออออออออน',dove);
    swritexy(1,45,11,0,'บ  Vaje   ณ   Apr   ณ  Sping   ณ                           /\    VAF 3:  The   บ',dove);
    swritexy(1,46,11,0,'วฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤด                           ณณ       REAL       บ',dove);
    swritexy(1,47,11,0,'บ   Us    ณ  Chiud  ณ   Tir    ณ                                  Adventure    บ',dove);
    swritexy(1,48,11,0,'วฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤด                           ณณ  ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',dove);
    swritexy(1,49,11,0,'บ  Parl   ณ  Prend  ณ  Guard   ณ                           \/  ณore:           บ',dove);
    swritexy(1,50,11,0,'ศอออออออออฯอออออออออฯออออออออออฯอออออออออออออออออออออออออออออออฯอออออออออออออออผ',dove);
    gettime(hh,mm,ss,s100);
    str(hh,sap); if hh>=10 then s:=sap+':' else s:='0'+sap+':';
    str(mm,sap); if mm>=10 then s:=s+sap+':' else s:=s+'0'+sap+':';
    str(ss,sap); if ss>=10 then s:=s+sap+':' else s:=s+'0'+sap+':';
    swritexy(70,49,2,0,s,dove);
  end;

procedure cripta(var f:string);
var l:integer;i:integer;
    c:byte;
  begin
   l:=length(f);
   for i:=1 to l do
    begin
     c:=ord(f[i]);
     c:=c+((l div 2)-i);
     f[i]:=char(c);
    end;
  end;

procedure decripta(var f:string);
var l,i:integer;
    c:byte;
  begin
   l:=length(f);
   for i:=1 to l do
    begin
     c:=ord(f[i]);
     c:=c-((l div 2)-i);
     f[i]:=char(c);
    end;
  end;

procedure carica_frase(var from:string_file; var f:string);
begin
 read(from,f);
 decripta(f);
end;

end.
