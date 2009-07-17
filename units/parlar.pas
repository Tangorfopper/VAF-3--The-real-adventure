unit parlar;
interface
uses vaf_unit,types;
const MAXLIVELLI=5;
var velocita_testo:byte; {fattore della velocita' del testo}

type frasedialogo=record
                   chiparla:byte;{se e' 0 parlo io}
                                 {altrimenti e' il numero dell'oggetto
                                 che parla}
                   cosadice:string;
                  end;

procedure chiacchiera(whereamix,whereamiy:integer;
                  n_dialogo:integer;
                  schermo:array of byte;
                  stazza:Pstanza;
                  filedeglioggetti:string);

implementation

procedure chiacchiera(whereamix,whereamiy:integer;
                  n_dialogo:integer;
                  schermo:array of byte;
                  stazza:Pstanza;
                  filedeglioggetti:string);{serve?????}

var tmp,nome_file_dialogo:string;
    fhrase:frasedialogo;
    file_dialoghi: file of frasedialogo;
    ogge: file of oggetto;
    parlante: oggetto;
    dovex,dovey:integer;
    video:^screen;
    trovato:boolean;

procedure vocifera(x,y:byte;str:string);
var ind1,ind2,ind3,ind4,ind5,ind6,par1,par2:integer;
    buf:string;
    colore:byte;
  begin
    par1:=length(str);
    par2:=y{da rinserire se parla l'omino -(omino^[3].dim[env^.scala,2]-1)};
    ind1:=x-10;
    ind2:=par2-5;
    while not((ind1>=1)and(ind2>=1)) do
      if ind1<1 then inc(ind1) else inc(ind2);
    ind3:=1;ind4:=0;ind5:=0;
    while ind3<=par1 do
      begin
        buf:='';
        repeat
          buf:=buf+str[ind3];
          inc(ind3);inc(ind4);
        until (str[ind3-1]='-')or(str[ind3-1]='.')or
              (str[ind3-1]=' ')or(ind3>par1);
        ind6:=ind4-length(buf);
        if ((ind1+ind4>=80)or(ind4>30)) then
          begin inc(ind5);ind4:=length(buf);ind6:=0 end;
        if fhrase.chiparla=0 then
                             swritexy(ind1+ind6,ind2+ind5,7,0,buf,video^)
                             else
                             begin
                              colore:=fhrase.chiparla mod 15;
                              if (colore=7) or (colore=0)then inc(colore);
                              swritexy(ind1+ind6,ind2+ind5,colore,0,buf,video^);
                             end;
      end;
    intdelay(round((100+5*par1)*((20-velocita_testo)/10)));
  end;

begin
 video:=ptr($B800,0);
 str(n_dialogo,tmp);
 assign(file_dialoghi,'talks\tlk'+tmp+'.tlk');
 {$i-}reset(file_dialoghi);{$i+}
 if ioresult=0 then
  begin
   assign(ogge,filedeglioggetti);
   reset(ogge);
   move(schermo,video^,8000);
   while not eof(file_dialoghi) do
     begin
       read(file_dialoghi,fhrase);
       if fhrase.chiparla=0 then
         begin
           dovex:=whereamix;
           dovey:=whereamiy;
         end
         else begin
               seek(ogge,fhrase.chiparla);
                read(ogge,parlante);
                if parlante.dimx+parlante.dimy>0 then
                 begin
                  dovex:=parlante.posx;
                  dovey:=parlante.posy;
                 end
                 else begin
                       trovato:=false;
                       dovey:=1;
                       while(dovey<=MINYMASCH-1)and(not(trovato)) do
                        begin
                         dovex:=1;
                         while(dovex<=80)and(not(trovato)) do
                          begin
                           if stazza^.moveable[dovex,dovey]=fhrase.chiparla
                              then trovato:=true
                              else inc(dovex);
                          end;
                         if not(trovato) then inc(dovey);
                        end;
                      end;
              end;
       decripta(fhrase.cosadice);
       vocifera(dovex,dovey,fhrase.cosadice);
       move(schermo,video^,8000);
     end;
   close(file_dialoghi);
   close(ogge);
  end;
end;

end.