unit speed;
interface

procedure evaluate_machine_speed;

var delay_value:integer;
var difference:longint;

implementation
uses crt,dos;

const a=-1.5/11; b=11.32;

procedure evaluate_machine_speed;
var h,m,s,c:longint;
    h1,m1,s1,c1:word;
    start,finish:longint;
    pippo:word;

procedure niente;
var s:string;
    i:word;
    arr:array[1..5] of byte;

begin
  {i:=(pippo mod 400);
  if i<100 then write('|')
  else if i<200 then write('/')
  else if i<300 then write('-')
  else write('\');}
  if (pippo mod 100)=0 then gotoxy(27,1);
  case (pippo mod 400) of
   0: write('|');
   100: write('/');
   200: write('-');
   300: write('\');
   else for i:=1 to 5 do arr[i]:=(pippo mod 3)*5+20;
  end;
end;

begin
  gettime(h1,m1,s1,c1);
  h:=h1;m:=m1;s:=s1;c:=c1;
  start:=c+100*s+100*60*m+100*60*60*h;
  clrscr;
  write('Evaluating machine speed: ');
  for pippo:=1 to 65000 do niente;
  gettime(h1,m1,s1,c1);
  h:=h1;m:=m1;s:=s1;c:=c1;
  finish:=c+100*s+100*60*m+100*60*60*h;
  writeln('... done.');
  difference:=finish-start;
  delay_value:=round(a*difference+b)-1;{devo mettere il valore vero...}
  if delay_value<1 then delay_value:=1;
end;

end.
