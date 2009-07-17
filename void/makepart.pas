program parti;
uses crt,dos;

var f:file of string;
    s:string;

begin
  assign(f,'parts');
  rewrite(f);
  s:='4';
  write(f,s);
  {Numero di parti}

  s:='oggetti';
  write(f,s);
  s:='room';
  write(f,s);
  s:='storia.str';
  write(f,s);
  s:='reazioni.ist';
  write(f,s);
  s:='frasi.frs';
  write(f,s);
  s:='oggett02';
  write(f,s);
  s:='room02';
  write(f,s);
  s:='storia02.str';
  write(f,s);
  s:='reaz02.ist';
  write(f,s);
  s:='frasi02.frs';
  write(f,s);
  s:='oggett03';write(f,s);
  s:='room03';write(f,s);
  s:='storia03.str';write(f,s);
  s:='reaz03.ist';write(f,s);
  s:='frasi03.frs';write(f,s);
  s:='oggett04';write(f,s);
  s:='room04';write(f,s);
  s:='storia04.str';write(f,s);
  s:='reaz04.ist';write(f,s);
  s:='frasi04.frs';write(f,s);
  close(f);
end.