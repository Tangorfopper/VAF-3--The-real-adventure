{un oggetto grande tipo "mare", sara' sullo sfondo, non camminabile,
 ma avra' nome e tutto il resto (eccetto il disegno) nell'array
 obj. Dimx e dimy saranno a zero.
 Per rilevare un oggetto sotto il puntatore, controllero' moveable per
 gli oggetti grandi, e obj per gli altri.}

{$M 32768,0,300000}
program _19_step;

uses types,speed,dos,crt,mouse,vaf_unit,musnsnd,anim,parlar ;

const TOMMAIS=14; {Questi sono gli indici delle animazioni}
      INTRO=1;
      TITOLI=15;
      introduzione:array[1..4] of byte=(16,17,18,19);

var video,frame:^screen;
    i,idx:integer;
    stanza_corrente:integer; {l'indice della stanza attuale}
    tipo:word;
    obj:^oggetti_tipo;
    objfile:file of oggetti_tipo;
    object_filename:string[15]; {nome del file da passare a chiacchiera}
    livello_corrente:byte;{il livello al quale si trova l'omino}
    errore,inmotion:boolean;
    where,dest:posizione;
    env:Pstanza; {ä la stanza corrente}
    world:file of stanza;
    frasifile:string_file;
    newroom:boolean;{T se ho appena cambiato stanza (devo  ricaricarla)}
    mossa:integer; {mossa corrente}
    mx,my:integer; {posizione del mouse}
    clock:word;
    stanza_visitata:^stanze_visitate;
    stanzoggetto:^mappa_oggetti_tipo;
    mouse_map:^mappa_mouse;
    vincolo:array[0..1000] of boolean;{i vincoli da verificare}
    selected_object:integer;{indice in obj dell'oggetto selezionato}
    uscitoda:byte;{mi dice da che parte sono uscito dalla stanza}
    frase:string[80]; {la frase nel box della maschera}
    dispinv:byte; {spostamento dell'inventario rispetto a stanzoggetto^[0]}
    used_object:integer; {oggetto in corso di uso}
    action:longint; {1 cifra per l'azione, 3 per un ogg. e 3 per un altro ogg.}
    guida:^storia;{contiene la chiave e il puntat. al file delle reazioni}
    found:boolean;{T se si ä trovata una corrispondenza in guida}
    history:file of storia;{file da cui prelevare l'indice delle reazioni}
    istrfile:file of reazione;{file da cui prelevare le reazioni}
    stereo,_16bit:boolean;
    x_is_farer:boolean;
    omino:^omino_tipo;{sprite dell'omino}
    lastpos:boolean;{per alternare i frame dell'omino che cammina}
    ominofile:file of omino_tipo;
    dir1,dir2:byte;
    parte,n_parti:byte; {parte corrente e numero delle parti del gioco}
    general:file of string; {contiene il n¯ delle parti e i nomi di file}
    ch:char;{tasto premuto}
    istr:reazione;{la reazione da effettuare quando si compie qualcosa}
    ok_prendi:boolean; {T quando un ogg non sempre prend. lo e'}
    reload:boolean; {T quando la stanza corrente viene ricaricata}
    teleported:boolean; {T se l'omino si teletrasporta}
    debugging:boolean;
    path:array[1..1000] of byte;
    opt_path:array[1..1000] of byte;
    dist_path:integer;
    length_path:integer;
    path_index:integer;
    trovato_path:boolean;
    voglio_uscire:integer;
    sulla_retta:boolean;
    delta,ratio:real;
    espanso:array[1..80,1..50] of integer;
    down:integer;
    {rilasciatore:pointer; se il programma ä abbastanza pulito non serve.}

procedure splat;
begin
  move(frame^,video^,8000);
end;

procedure disegna_sfondo(indice_livello:byte);
var ind1:integer;
{per ora... spiattella sul video il livello n_livello-esimo}
  begin
    if indice_livello=5 then dec(indice_livello);
    for ind1:=1 to 8000-160*(50-MINYMASCH+1) do
        if env^.livs[indice_livello][ind1]<>255
          then frame^[ind1]:=env^.livs[indice_livello][ind1];
  end;

function scegli_verbo(arg:byte):string;
var i:byte;
 begin
   randomize;
  i:=random(NSINONIMI);
  if arg=9 then arg:=2;
  scegli_verbo:=CONST_FRASI[arg,i];
 end;

procedure wait_for_mouse_release;
begin
 repeat until not(left_button or right_button);
end;

function check_moveable(a,b:byte):boolean;
var par1:integer;
{T se mi posso muovere in where.wx,where.wy}
  begin
    par1:=env^.moveable[a,b];
    if par1>500 then check_moveable:=false
       else begin
              if par1=0 then check_moveable:=true
                 else if par1>0 then check_moveable:=
                                       obj^[par1].livello<livello_corrente
                 else {if par1>=-1000 then check_moveable:=vincolo[abs(par1)]
                      else begin
                             uscitoda:=-(par1+1000);
                             stanza_corrente:=env^.adiacenza[uscitoda];
                             newroom:=true;
                             check_moveable:=true;
                           end};
            end;
    if (a>80)or(a<1)or(b>=MINYMASCH)or(b<1) then check_moveable:=false;
  end;

function esco(a,b:byte):integer;
var idx,i1,i2:integer;
    done:boolean;
begin
  done:=false;
  idx:=0;
  while (idx<=5)and(not(done)) do
   begin
     i1:=a-idx;
     while (i1<=a+idx)and(not(done)) do
      begin
       i2:=b-idx;
       while (i2<=b+idx)and(not(done)) do
        begin
         if (i1<=80)and(i1>0)and(i2<MINYMASCH)and(i2>1)
          then if env^.moveable[i1,i2]<-1000
                 then begin
                       esco:=-(env^.moveable[i1,i2]+1000);
                       done:=true;
                      end;
         inc(i2);
        end;
       inc(i1);
      end;
     inc(idx);
   end;
end;

procedure evaluate_path(depth:integer;wx,wy:byte);
var dx,dy:integer;
    ix,iy:array[1..8] of byte;
    nx,ny:byte;
    idx:byte;
    done:byte;

function sgn(arg:integer):integer;
begin
 if arg=0 then sgn:=0 else sgn:=arg div abs(arg);
end;

procedure ordina_nodi;
var i1,i2:integer;
begin
 if sulla_retta then
  if x_is_farer then begin
                       i1:=sgn(dx);
                       if trunc(depth*ratio)>trunc((depth-1)*ratio)
                         then i2:=sgn(dy) else i2:=0;
                     end
                else begin
                       i2:=sgn(dy);
                       if ratio<>0 then
                         if trunc(depth/ratio)>trunc((depth-1)/ratio)
                            then i1:=sgn(dx) else i1:=0
                         else i1:=sgn(dx);
                     end
  else begin i1:=sgn(dx); i2:=sgn(dy) end;
 if i1<>0 then if i2<>0 then
                 begin
                  ix[1]:=i1+1;iy[1]:=i2+1;
                  ix[2]:=i1+1;iy[2]:=0+1;
                  ix[3]:=0+1;iy[3]:=i2+1;
                  ix[4]:=i1+1;iy[4]:=-i2+1;
                  ix[5]:=-i1+1;iy[5]:=i2+1;
                  ix[6]:=-i1+1;iy[6]:=0+1;
                  ix[7]:=0+1;iy[7]:=-i2+1;
                  ix[8]:=-i1+1;iy[8]:=-i2+1;
                 end
                 else begin
                       ix[1]:=i1+1;iy[1]:=0+1;
                       ix[2]:=i1+1;iy[2]:=-1+1;
                       ix[3]:=i1+1;iy[3]:=1+1;
                       ix[4]:=0+1;iy[4]:=-1+1;
                       ix[5]:=0+1;iy[5]:=1+1;
                       ix[6]:=-i1+1;iy[6]:=-1+1;
                       ix[7]:=-i1+1;iy[7]:=1+1;
                       ix[8]:=-i1+1;iy[8]:=0+1;
                      end
          else begin
                ix[1]:=0+1;iy[1]:=i2+1;
                ix[2]:=-1+1;iy[2]:=i2+1;
                ix[3]:=1+1;iy[3]:=i2+1;
                ix[4]:=-1+1;iy[4]:=0+1;
                ix[5]:=1+1;iy[5]:=0+1;
                ix[6]:=-1+1;iy[6]:=-i2+1;
                ix[7]:=1+1;iy[7]:=-i2+1;
                ix[8]:=0+1;iy[8]:=-i2+1;
               end;
end;

function spost(a,b:integer):byte;
begin
 case a of
  0 :case b of
      0: spost:=0;
      1: spost:=6;
      -1:spost:=2;
     end;
  1 :case b of
      0: spost:=4;
      1: spost:=5;
      -1:spost:=3;
     end;
  -1:case b of
      0: spost:=8;
      1: spost:=7;
      -1:spost:=1;
     end;
 end;
end;

begin
  if debugging then begin gotoxy(39,47);write(depth); end;
  done:=0;
  dx:=dest.wx-wx;
  dy:=dest.wy-wy;
  if depth=1 then begin
                    dist_path:=10000;
                    if dx<>0 then ratio:=abs(dy/dx) else ratio:=1000000;
                    if abs(dx)>=abs(dy) then x_is_farer:=true;
                    delta:=0;
                    sulla_retta:=true;
                  end
                  else if x_is_farer then delta:=delta+ratio
                                     else if ratio<>0 then
                                             delta:=delta+1/ratio;
  if (dx=0)and(dy=0) then
    begin
      trovato_path:=true;
      path[depth]:=0;
      for idx:=1 to depth do opt_path[idx]:=path[idx];
    end;
  if (dist_path>abs(dx)+abs(dy))or
     ((dist_path=abs(dx)+abs(dy))and(length_path>depth-1))and
     (not(trovato_path))  then
   begin
     for idx:=1 to depth-1 do opt_path[idx]:=path[idx];
     dist_path:=abs(dx)+abs(dy);
     length_path:=depth-1;
   end;
  ordina_nodi;
  if debugging then begin gotoxy(wx,wy);write('%'); end;
  for idx:=1 to 8 do
    begin
     nx:=wx+ix[idx]-1;ny:=wy+iy[idx]-1;
     if (nx>=1)and(nx<=80)and(ny>=1)and(ny<MINYMASCH) then
       if espanso[nx,ny]=0 then espanso[nx,ny]:=depth;
    end;
  for idx:=1 to 8 do
   begin
     nx:=wx+ix[idx]-1;ny:=wy+iy[idx]-1;
     if (nx>=1)and(nx<=80)and(ny>=1)and(ny<MINYMASCH) then
       begin
         if (not(trovato_path))and(check_moveable(nx,ny))and
            (espanso[nx,ny]<>-1)and(done<2)
            and((env^.moveable[nx,ny]>=-1000)or
                (voglio_uscire=-(1000+env^.moveable[nx,ny])))
            then begin
                   if down=depth then down:=0;
                   if (espanso[nx,ny]=0)or
                      (espanso[nx,ny]=depth) then
                      begin
                        if sulla_retta then sulla_retta:=idx=1;
                        espanso[nx,ny]:=-1;
                        path[depth]:=spost(ix[idx]-1,iy[idx]-1);
                        evaluate_path(depth+1,nx,ny);
                      end
                      else if espanso[nx,ny]<>0 then inc(done);
                 end;
       end;
   end;
end;

procedure muovi_omino;
var par1,par2:integer;
  begin
    par1:=where.wx; par2:=where.wy;
    if clock mod 2=0 then lastpos:=not lastpos;{per rallentare la mossa}
    case opt_path[path_index] of
     1: begin dec(par1); dec(par2) end;
     2: dec(par2);
     3: begin inc(par1); dec(par2) end;
     4: inc(par1);
     5: begin inc(par1); inc(par2) end;
     6: inc(par2);
     7: begin dec(par1); inc(par2) end;
     8: dec(par1);
     0: inmotion:=false;
    end;
    if check_moveable(par1,par2) then
     begin where.wx:=par1; where.wy:=par2; end
     else inmotion:=false;
    inc(path_index);
    if env^.moveable[where.wx,where.wy]<-1000 then
                       begin
                         uscitoda:=-(env^.moveable[where.wx,where.wy]+1000);
                         stanza_corrente:=env^.adiacenza[uscitoda];
                         newroom:=true;
                       end;
   {Forse devo rimetere l'if che ora e' in traccia schermo}
  end;

function scompatta(sc,p,indice:byte):byte;
var ind1,par1:integer;
  begin
    par1:=0;
    with omino^[p] do
      begin
        for ind1:=0 to sc-1 do par1:=par1+2*dim[ind1,1]*dim[ind1,2];
        scompatta:=sprite[par1+indice];
      end;
  end;

procedure disegna_omino(si_muove,sta_dando:boolean;sc:byte);
var ind2,ind3,h,x,y:integer;c:char;
  begin
    if path_index<=length_path then
      begin
        case opt_path[path_index] of
         1,7,8:dir1:=0;
         3,4,5:dir1:=1;
        end;
        case opt_path[path_index] of
         1,2,3:dir2:=4;
         5,6,7:dir2:=0;
        end;
      end;
    {if where.wx-dest.wx>0
       then dir1:=0
       else if where.wx-dest.wx<0 then dir1:=1;
    if where.wy-dest.wy>0
       then dir2:=4
       else if where.wy-dest.wy<0 then dir2:=0;}
    if si_muove then
      begin
        if lastpos then h:=3 else h:=5;
      end
      else if sta_dando then begin
                               h:=1;
                               dir2:=0;
                             end
                        else begin
                               h:=3;
                             end;
    with omino^[h+dir1+dir2] do
      begin
        x:=where.wx-(dim[sc,1] div 2);
        y:=where.wy-(dim[sc,2]-1);
        for ind2:=0 to dim[sc,2]-1 do
          for ind3:=0 to 2*dim[sc,1]-1 do
            if (scompatta(sc,h+dir1+dir2,dim[sc,1]*2*ind2+ind3)<>255)and
               (y+ind2>=1)and(y+ind2<MINYMASCH)and(x+ind3 div 2<=80)and
               (x+ind3 div 2>=1)
               then frame^[160*(y+ind2-1)+2*(x-1)+ind3+1]:=
                      scompatta(sc,h+dir1+dir2,dim[sc,1]*2*ind2+ind3);
      end;
  end;

procedure carica_stanza(indice_stanza:integer;ricarica:boolean);
var ind1,ind2,ind3,ind4,x,y,h1,h2:integer;
  begin  {carica la stanza e spiaccica gli oggetti sui livelli, crea la
          mappa per il mouse.}
    seek(world,indice_stanza-1);
    read(world,env^);
    for ind1:=0 to 4000 do mouse_map^[ind1]:=0;
    for ind1:=1 to stanzoggetto^[indice_stanza,0] do
      if obj^[stanzoggetto^[indice_stanza,ind1]].dimx>0 then
        begin with obj^[stanzoggetto^[indice_stanza,ind1]] do
                begin
                  h1:=1-dimx mod 2;h2:=1-dimy mod 2;
                  x:=posx-dimx div 2+h1;
                  y:=posy-dimy div 2+h2;
                  for ind2:=0 to dimy-1 do
                    for ind3:=0 to 2*dimx-1 do
                      if disegno[dimx*2*ind2+ind3]<>255 then
                        begin
                          env^.livs[livello][160*(y+ind2-1)+2*(x-1)+ind3+1]:=
                            disegno[dimx*2*ind2+ind3];
                          mouse_map^[80*(y+ind2-1)+x+ind3 div 2]:=
                            stanzoggetto^[indice_stanza,ind1];
                        end;
                end;
        end;
    if (not ricarica) then
     if (env^.backmusic<>0)and(current_tune<>env^.backmusic) then
       begin
         {dealloca_S3M;
         suona(current_tune,FOR_MAIN);}
         dealloca_S3M;{queste due righe sono schifezze perchÇ non si pianti}
         suona(env^.backmusic,FOR_MAIN);
       end;
    env^.levelpos[0]:=42;
    {^^^ Decommento se Filippo non mette automaticamente levelpos[0] a 42}
  end;

procedure vocifera(str:string); {fa dire str all'omino}
var ind1,ind2,ind3,ind4,ind5,ind6,par1,par2:integer;
    buf:string;
  begin
    par1:=length(str);
    par2:=where.wy-(omino^[3].dim[env^.scala,2]-1);
    ind1:=where.wx-10;
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
        swritexy(ind1+ind6,ind2+ind5,7,0,buf,frame^);
      end;
    splat;
    intdelay(round((100+5*par1)*((20-velocita_testo)/10)));
  end;

function intasca(ogg:integer):boolean; {T se ogg ä in inventario}
var ind1:integer;
  begin
    ind1:=1;
    while (ind1<=stanzoggetto^[0,0])and(ogg<>stanzoggetto^[0,ind1])
      do inc(ind1);
    intasca:=not(ind1>stanzoggetto^[0,0]);
  end;

procedure prendi_oggetto;
var ind1,ind2:integer;
{toglie l'oggetto dalla stanza e lo mette nell'inventario, aggiorna la stanza}
{se l'oggetto non ä prendibile, non fa un tubo.}
  begin
    if env^.moveable[mx,my]<>selected_object then
      begin
        ind1:=1;
        while (stanzoggetto^[stanza_corrente,0]>=ind1)and
              (stanzoggetto^[stanza_corrente,ind1]<>selected_object)
           do inc(ind1);
        if {ind1<=stanzoggetto^[stanza_corrente,0] togliere}
           not(intasca(selected_object)) then
          begin
            inc(stanzoggetto^[0,0]);
            stanzoggetto^[0,stanzoggetto^[0,0]]:=selected_object;
            obj^[selected_object].stanza:=0;
            if ind1<=stanzoggetto^[stanza_corrente,0] then
              begin
                for ind2:=ind1 to stanzoggetto^[stanza_corrente,0]-1 do
                stanzoggetto^[stanza_corrente,ind2]:=
                  stanzoggetto^[stanza_corrente,ind2+1];
                dec(stanzoggetto^[stanza_corrente,0]);
                reload:=true;
                carica_stanza(stanza_corrente,reload);
              end;
            dispinv:=(stanzoggetto^[0,0]-1) div 5;
            {sposta l'inv per il nuovo ogg.}
          end;
      end
      else begin
             mossa:=VAI;
             {vocifera('E'' l''idea pió stupida mai concepita');
              probabilmente ä meglio toglierlo e metterlo nel punto in cui
              prendi_oggetto ä chiamata, if not in_tasca dopo la chiamata}
           end;
  end;

procedure seleziona_oggetto;
var ind1,ind2:integer;
{guarda sopra quale oggetto ä il mouse e lo mette dentro selected_object}
  begin
    if my<MINYMASCH then
      if mouse_map^[80*(my-1)+mx]<>0
         then selected_object:=mouse_map^[80*(my-1)+mx]
         else if (env^.moveable[mx,my]>0)and(env^.moveable[mx,my]<=MAXOGGETTI)
                then selected_object:=env^.moveable[mx,my]
              else selected_object:=0
      else if (mx>=33)and(mx<=59)and(my-MINYMASCH-2>0)and
              (dispinv+my-MINYMASCH-2<=stanzoggetto^[0,0]) then
                selected_object:=stanzoggetto^[0,dispinv+my-MINYMASCH-2]
                else selected_object:=0;
  end; {controllare se ä giusta}

function allright(a:byte):boolean;
var ind1:byte;p:boolean;
  begin
    p:=true;
    with istr.does[a] do
      begin
        for ind1:=1 to 5 do
          if proof[ind1]>0 then p:=(p)and(vincolo[proof[ind1]])
          else if proof[ind1]<0 then p:=(p)and(not vincolo[-proof[ind1]]);
        if stanza_giusta<>0 then p:=(p)and(stanza_giusta=stanza_corrente);
      end;
    allright:=p;
  end;

procedure assegna_oggetto(var a,b:oggetto);
{assegna b ad a: non tocca la stanza}
var i:integer;
  begin
    {a.stanza:=b.stanza;}
    a.livello:=b.livello;
    a.posx:=b.posx;
    a.posy:=b.posy;
    a.dimx:=b.dimx;
    a.dimy:=b.dimy;
    a.nome:=b.nome;
    for i:=0 to 50 do a.disegno[i]:=b.disegno[i];
  end;

procedure scambia_oggetti(a,b:integer);{scambia a con b: non tocca la stanza}
var o:oggetto;
  begin
    assegna_oggetto(o,obj^[a]);
    assegna_oggetto(obj^[a],obj^[b]);
    assegna_oggetto(obj^[b],o);
  end;

procedure esegui(a:byte);
var ind1,ind2:byte;m:string;
    musfile:file of byte;
    id:string[3];

  begin
    with istr.does[a] do
      begin
        for ind1:=1 to 3 do if guadagna[ind1]<>0{si mette l'oggetto in tasca}
          then begin
                 selected_object:=guadagna[ind1];
                 prendi_oggetto;
                 if not(intasca(selected_object)) then vocifera('non posso...');
               end;
        for ind1:=1 to 3 do if perdi[ind1]<>0{elimina l'oggetto da eliminare}
          then begin
                 if intasca(perdi[ind1]) then
                   begin
                     ind2:=1;
                     while stanzoggetto^[0,ind2]<>perdi[ind1] do inc(ind2);
                     if ind2<>stanzoggetto^[0,0] then
                        stanzoggetto^[0,ind2]:=
                          stanzoggetto^[0,stanzoggetto^[0,0]];
                     dec(stanzoggetto^[0,0]);
                   end
                   else begin
                          ind2:=1;
                          while (ind2<=stanzoggetto^[stanza_corrente,0])and
                                (stanzoggetto^[stanza_corrente,ind2]<>
                                 perdi[ind1]) do inc(ind2);
                          if ind2<=stanzoggetto^[stanza_corrente,0] then
                           begin
                            if ind2<>stanzoggetto^[stanza_corrente,0] then
                               stanzoggetto^[stanza_corrente,ind2]:=
                                stanzoggetto^[stanza_corrente,stanzoggetto^[stanza_corrente,0]];
                            dec(stanzoggetto^[stanza_corrente,0]);
                            obj^[perdi[ind1]].stanza:=MAXSTANZE-1;
                            carica_stanza(stanza_corrente,reload);
                            reload:=true;
                           end
                           else
                            begin
                              stanza_visitata^[obj^[perdi[ind1]].stanza]:=
                                false;
                              obj^[perdi[ind1]].stanza:=MAXSTANZE-1;
                            end;
                        end;
               end;
        for ind1:=1 to 10 do
          if vinc[ind1]>0 then
             vincolo[vinc[ind1]]:=true
             else if vinc[ind1]<0 then vincolo[-vinc[ind1]]:=false;
             {rimuove/aggiunge i vincoli}
        {writeln(meffeig); DEBUG}
        play(suono,FOR_MAIN);

        if dialogo<>0 then {fa partire il dialog-esimo dialogo}
          chiacchiera(where.wx,where.wy-(omino^[3].dim[env^.scala,2]-1),dialogo,
                      video^,env,object_filename);
          {DECOMMENTARE CON PARLAR}
        for ind1:=1 to 5 do
          if swapobj[ind1,1]<>0
             then begin
                    scambia_oggetti(swapobj[ind1,1],swapobj[ind1,2]);
                    reload:=true;
                    carica_stanza(stanza_corrente,reload);
                  end;
        ok_prendi:=prendi;
        if meffeig<>0 then {dice la frase che deve dire}
          begin
                reset(frasifile);
                seek(frasifile,meffeig-1);
                carica_frase(frasifile,m);
                vocifera(m);
          end;
        if special<>0 then begin
                             play_anim(special,true);
                             if changed_music then
                               begin
                                 {dealloca_S3M;
                                 suona(current_tune,FOR_MAIN);}
                                 dealloca_S3M;{senno' si pianta...}
                                 suona(env^.backmusic,FOR_MAIN);
                                 changed_music:=false;
                               end;
                           end;
        if teleport[1]<>0 then begin
                                 stanza_corrente:=teleport[1];
                                 newroom:=true;
                                 teleported:=true;
                                 where.wx:=teleport[2];
                                 where.wy:=teleport[3];
                               end;
      end; {non e' finita...}
  end;

procedure reagisci_a(stimolo:longint);
var ind1,ind2,ind:word;alt:byte;reagito:boolean;
  begin
    ind1:=1;ind2:=MAXREAZIONI;{estremi di ricerca in guida}
    found:=false;
    while (ind2<>ind1)and(not found) do
      begin {ricerca binaria della chiave}
        ind:=(ind1+ind2) div 2;
        if guida^[ind].causa>stimolo then begin
                                            if ind2<>ind then ind2:=ind
                                               else ind1:=ind2
                                          end
           else if guida^[ind].causa<stimolo then begin
                                                    if ind1<>ind then ind1:=ind
                                                       else ind2:=ind1
                                                  end
                   else found:=true;
      end;
    if found then
      begin
        seek(istrfile,guida^[ind].effetto-1);
        read(istrfile,istr);
        reagito:=false;
        alt:=1;
        repeat
          if allright(alt) then begin esegui(alt);reagito:=true end;
          inc(alt);
        until (reagito)or(alt>istr.n_alt);
        mossa:=VAI;
        frase:=scegli_verbo(mossa);{'Vai verso'};
      end;
  end;

procedure traccia_schermo(m,s,c:boolean);
var ind:integer;
  begin
    if where.wy<env^.levelpos[livello_corrente] then inc(livello_corrente)
    else if where.wy>=env^.levelpos[livello_corrente-1]
            then dec(livello_corrente);
    {Controllare questo STRAMALEDETTISSIMO if!!!! <? >? =? <=? >=? <>? ???}
    {l'if sopra era alla fine di muovi omino}
    for ind:=env^.n_livelli downto 0 do
      begin
        disegna_sfondo(ind);
        if (livello_corrente=ind)and(not teleported)
          then disegna_omino(m,s,env^.scala);
      end;
    if c then swritexy(x_mouse(false)+1,y_mouse(false)+1,5,16,'+',frame^);
    splat;
  end;

function a_portata(ogg:integer):boolean;
{T se l'oggetto ä in pos. raggiung. o e' sullo sfondo.}
var xp,yp,ind1,ind2,par1,par2:integer;
    parz:boolean;
  begin
    {if obj^[ogg].dimx+obj^[ogg].dimy>0 then}
     begin
      xp:=where.wx;yp:=where.wy+1;
      par1:=omino^[1].dim[env^.scala,1] div 2;
      par2:=omino^[1].dim[env^.scala,2]+1;
      ind1:=xp-par1-1;
      parz:=false;
      while (not parz)and(ind1<=xp+par1+1) do
        begin
          ind2:=yp;
          while (not parz)and(ind2>=yp-par2) do
            begin
              if (ind1>=1)and(ind1<=80)and(ind2>=1)and(ind2<MINYMASCH) then
                parz:=(env^.moveable[ind1,ind2]=ogg)or
                      (mouse_map^[80*(ind2-1)+ind1]=ogg);
              dec(ind2);
            end;
          inc(ind1);
        end;
      a_portata:=parz;
     end
     {else a_portata:=true;}
  end;

procedure auto(x,y:byte); {disegna l'omino che si muove da solo verso x,y}
var ind1,i,j:integer;
  begin
    inmotion:=true;
    dest.wx:=x;dest.wy:=y;
    trovato_path:=false;
    path_index:=1;
    voglio_uscire:=esco(dest.wx,dest.wy);
    for i:=1 to 80 do
     for j:=1 to 50 do espanso[i,j]:=0;
    for i:=1 to 400 do opt_path[i]:=0;
    evaluate_path(1,where.wx,where.wy);
    repeat
      clock:=(clock+10001) mod 10000;
      if (clock mod delay_value)=0 then muovi_omino;
      ind1:=1;
      disegna_maschera(frame^);
      while (ind1+dispinv<=stanzoggetto^[0,0])and(ind1<=5) do
        begin
          swritexy(34,MINYMASCH+2+ind1,4,0,
                   obj^[stanzoggetto^[0,ind1+dispinv]].nome,frame^);
          inc(ind1)
        end;
      if where.wy<env^.levelpos[livello_corrente] then inc(livello_corrente)
      else if where.wy>=env^.levelpos[livello_corrente-1]
            then dec(livello_corrente);
      if ((where.wx=dest.wx)and(where.wy=dest.wy))or
         (a_portata(selected_object)) then inmotion:=false;
        {E' giusto che l'omino si fermi se l'oggetto selez. e' "a portata"?}
      for ind1:=env^.n_livelli downto 0 do
        begin
          disegna_sfondo(ind1);
          if (livello_corrente=ind1)and(not teleported)
            then disegna_omino(inmotion,false,env^.scala);
        end;
      splat;
    until not inmotion;
  end;

procedure mascherina;
begin
  center(23,7,0,'…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕSAVEÕÕTOÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª',frame^);
  center(24,7,0,'∫                                     ∫',frame^);
  center(25,7,0,'»ÕÕÕÕÕÕÕINPUTÕÕFILENAMEÕÕHEREÕÕÕÕÕÕÕÕÕº',frame^);
end;

function getfilename:string;
var res,aux:string;chara:char;ind1:integer;
  begin
    res:='';
    textcolor(3);
    repeat
      gotoxy(25+length(res),24);
      chara:=readkey;
      if (ord(chara)<>13)and(ord(chara)<>8)
        then begin res:=res+chara;write(chara); end;
      if (ord(chara)=8) then
        begin
          aux:='';
          for ind1:=1 to length(res)-1 do aux:=aux+res[ind1];
              res:=aux;
              gotoxy(25+length(res),24);
              write(' ');
        end;
    until (ord(chara)=13)or(length(res)=33);
    getfilename:=res;
    textcolor(7);
  end;

procedure save;
var f:string;ind1:integer;
    savevin:file of boolean;
    saveobj:file of oggetti_tipo;
    savepos:file of byte;
    saveinv:file of mappa_oggetti_tipo;
    s1,s2:byte;

  begin
    mascherina;
    splat;
    f:=getfilename;
    assign(savevin,f+'.sv1');
    assign(saveobj,f+'.sv2');
    assign(savepos,f+'.sv3');
    assign(saveinv,f+'.sv4');
    {$i-}
    rewrite(savevin);
    rewrite(saveobj);
    rewrite(savepos);
    rewrite(saveinv);
    {$i+}
    if ioresult<>0 then begin
                          center(26,7,0,'Gioco NON salvato (nome non valido?)',video^);
                          delay(1000);
                        end
       else begin
              for ind1:=0 to 1000 do write(savevin,vincolo[ind1]);
              write(saveobj,obj^);
              s1:=stanza_corrente div 256;s2:=stanza_corrente mod 256;
              write(savepos,parte);write(savepos,s1);write(savepos,s2);
              write(savepos,livello_corrente);{inutile...}
              write(savepos,where.wx);write(savepos,where.wy);
              write(saveinv,stanzoggetto^);
              close(savevin);close(saveobj);close(savepos);close(saveinv);
              center(26,7,0,'Gioco salvato',video^);
              delay(1000);
            end;
  end;

procedure load;
var f:string;ind1:integer;
    loadvin:file of boolean;
    loadobj:file of oggetti_tipo;
    loadpos:file of byte;
    loadinv:file of mappa_oggetti_tipo;
    s1,s2:byte;

  begin
    mascherina;
    swritexy(35,23,7,0,'LOADÕÕFROM',frame^);
    splat;
    f:=getfilename;
    assign(loadvin,f+'.sv1');
    assign(loadobj,f+'.sv2');
    assign(loadpos,f+'.sv3');
    assign(loadinv,f+'.sv4');
    {$i-}
    reset(loadvin);
    reset(loadobj);
    reset(loadpos);
    reset(loadinv);
    {$i+}
    if ioresult<>0 then begin
                          center(26,7,0,'Gioco NON caricato (nome non valido?)',
                                 video^);
                          delay(1000);
                        end
       else begin
              for ind1:=0 to 1000 do read(loadvin,vincolo[ind1]);
              read(loadobj,obj^);
              read(loadpos,parte);read(loadpos,s1);read(loadpos,s2);
              stanza_corrente:=s1*256;
              stanza_corrente:=stanza_corrente+s2;
              read(loadpos,livello_corrente);{inutile...}
              read(loadpos,where.wx);read(loadpos,where.wy);
              read(loadinv,stanzoggetto^);
              close(loadvin);close(loadobj);close(loadpos);close(loadinv);
              center(26,7,0,'Gioco caricato',video^);
              delay(1000);
            end;
    object_filename:=f+'.sv2';{gli oggetti sono in f+'.sv2', ora...}
    newroom:=true;
    inmotion:=false;
  end;

procedure prendilo;
var p1,p2:longint;
  begin
    seleziona_oggetto;
    if (selected_object<>0)and(not intasca(selected_object)) then
       begin
         if (not a_portata(selected_object)) then auto(mx,my);
         if (not a_portata(selected_object)) then
             begin vocifera('Non credo che ad alcun essere umano sia'+
                            ' dato di arrivarci...') end
             else begin
                    ok_prendi:=false;
                    p1:=PRENDI; p2:=selected_object;
                    action:=p1*1000000+p2*1000;
                    reagisci_a(action);
                    if (not found)or(ok_prendi) then
                       begin
                         traccia_schermo(false,true,false);
                         delay (500);
                         prendi_oggetto;
                         if not intasca(selected_object) then
                           vocifera('Davvero credevi di poter prendere '+
                                    obj^[selected_object].nome+' ?');
                         frase:=scegli_verbo(VAI);{'Vai verso';}
                         mossa:=VAI;
                       end;
                    ok_prendi:=false;
                  end
       end
       else begin
              mossa:=VAI;
              frase:=scegli_verbo(mossa);
            end;
    repeat until not left_button;
  end;

procedure usalo;
var p1,p2:longint;
  begin
    seleziona_oggetto;
    if selected_object<>0 then
      begin
        if (not intasca(selected_object))and(not a_portata(selected_object))
          then auto(mx,my);
        if (not intasca(selected_object))and(not a_portata(selected_object))
          then vocifera('non c''arrivo')
        else begin
               p1:=USA; p2:=selected_object;
               action:=p1*1000000+p2*1000;
               reagisci_a(action);
               if not found then
                 begin
                   {prendilo; lo tolgo perchä combina pasticci...}
                   {traccia_schermo(false,false,false); serve solo con prendilo}
                   if (not intasca(selected_object)) then
                     begin
                       vocifera('Non vedi che non ce l''ho?');
                       mossa:=VAI;
                       frase:=scegli_verbo(mossa);{'Vai verso';}
                     end
                     else begin
                            mossa:=USAOGGETTO;
                            frase:=frase+' '+obj^[selected_object].nome+' con';
                            used_object:=selected_object;
                          end;
                 end;
             end;
      end;
    repeat until not left_button;
  end;

procedure usalocon;
var p1,p2,p3:longint;
  begin
    p1:=USA;
    seleziona_oggetto;
    if selected_object<>0 then
      begin
       if (not intasca(selected_object))and (not a_portata(selected_object))
         then auto(mx,my);
       if (not a_portata(selected_object))and(not(intasca(selected_object)))
         then vocifera('Non c''arrivo...')
       else begin
              p2:=used_object; p3:=selected_object;
              action:=p1*1000000+p2*1000+p3;
              reagisci_a(action);
              if not found then
                begin
                  p2:=selected_object; p3:=used_object;
                  action:=USA*1000000+p2*1000+p3;
                  reagisci_a(action);
                  if not found then begin vocifera('Niente da fare...'); end;
               end;
            end;
      end;
      {else}
           begin
             mossa:=VAI;
             frase:=scegli_verbo(mossa);{'Vai verso';}
           end;
  end;

procedure manipola(modo:byte);
var p1,p2:longint;
  begin
    seleziona_oggetto;
    if selected_object<>0 then
      begin {NON farlo camminare nel caso che debba parlare!}
       if (not a_portata(selected_object))and(not intasca(selected_object))
          then auto(mx,my);
       if (modo<>GUARDA)and(modo<>PARLA)and(not a_portata(selected_object))and
          (not intasca(selected_object))
          then vocifera('Dovrï prima arrivarci vicino...')
       else begin
              p1:=modo; p2:=selected_object;
              action:=p1*1000000+p2*1000;
              reagisci_a(action);
              if not found then
               case modo of
                GUARDA: vocifera('Passerei un''ora a guardare '+
                                 obj^[selected_object].nome);
                PARLA: vocifera('Non vorrai veramente che io mi metta a'+
                                ' parlare con '+obj^[selected_object].nome);
                else vocifera('Non posso muorerlo(tm)');
               end;
            end
      end;
    mossa:=VAI;
    frase:=scegli_verbo(mossa);{'Vai verso';}
  end;

procedure aggiorna_mossa_e_frase(ics,ipsilon:integer);
           begin case ipsilon of
                    45:begin
                         case ics of
                           2..10: mossa:=VAI;
                           12..20:mossa:=APRI;
                           22..30:mossa:=SPINGI;
                         end;
                       end;
                    47:begin
                         case ics of
                           2..10: mossa:=USA;
                           12..20:mossa:=CHIUDI;
                           22..30:mossa:=TIRA;
                         end;
                       end;
                    49:begin
                         case ics of
                           2..10: mossa:=PARLA;
                           12..20:mossa:=PRENDI;
                           22..30:mossa:=GUARDA;
                         end;
                       end;
                  end;
                  if ipsilon in [45,47,49] then frase:=scegli_verbo(mossa);
                  wait_for_mouse_release;
            end;

procedure esegui_mossa(ics,ipsilon:integer);
var i,j:integer;
begin
  case mossa of
    VAI:if ipsilon<MINYMASCH then
          begin
            inmotion:=true;
            dest.wx:=ics;
            dest.wy:=ipsilon;
            trovato_path:=false;
            path_index:=1;
            voglio_uscire:=esco(dest.wx,dest.wy);
            for i:=1 to 80 do
             for j:=1 to 50 do espanso[i,j]:=0;
            for i:=1 to 400 do opt_path[i]:=0;
            evaluate_path(1,where.wx,where.wy);
          end;
    PRENDI:prendilo;
    USA:usalo;
    USAOGGETTO:usalocon;
    PARLA,SPINGI,TIRA,APRI,CHIUDI,GUARDA:manipola(mossa);
  end{del case};
end;

procedure disegna_inventario(ics,ipsilon:integer);
var scorri:word;
begin
  {disegna l'inventario}
  scorri:=1;
  while (scorri+dispinv<=stanzoggetto^[0,0])and(scorri<=5) do
   begin
    swritexy(34,MINYMASCH+2+scorri,4,0,
             obj^[stanzoggetto^[0,scorri+dispinv]].nome,frame^);
    if (ics>32)and(ics<=59)and(ipsilon=MINYMASCH+2+scorri) then
    forecolor(33,ipsilon,59,ipsilon,14,frame^);
    inc(scorri)
   end;
end;

procedure set_text_speed;
var s:string[3];
    d:byte;
    carat:char;
begin
 repeat
  center(23,7,0,'…ÕÕÕÕÕÕÕÕÕÕTEXTÕÕÕÕÕÕÕÕÕÕª',frame^);
  center(24,7,0,'∫--------------------    ∫',frame^);
  center(25,7,0,'»ÕÕÕÕÕÕÕÕÕÕSPEEDÕÕÕÕÕÕÕÕÕº',frame^);
  swritexy(27+velocita_testo,24,12,0,'+',frame^);
  if velocita_testo>=10 then d:=0 else d:=1;
  str(velocita_testo,s);
  swritexy(49+d,24,12,0,s,frame^);
  splat;
  carat:=readkey;
  case carat of
   '-': if velocita_testo>1 then dec(velocita_testo);
   '+': if velocita_testo<20 then inc(velocita_testo);
  end;
 until (carat<>'+')and(carat<>'-');
end;

procedure set_music_volume;
var s:string[3];
    d:byte;
    carat:char;
begin
 repeat
  center(23,7,0,'…ÕÕÕÕÕÕÕÕÕÕMUSICÕÕÕÕÕÕÕÕÕª',frame^);
  center(24,7,0,'∫--------------------    ∫',frame^);
  center(25,7,0,'»ÕÕÕÕÕÕÕÕÕÕVOLUMEÕÕÕÕÕÕÕÕº',frame^);
  swritexy(27+volume_level,24,12,0,'+',frame^);
  if volume_level>=10 then d:=0 else d:=1;
  str(volume_level,s);
  swritexy(49+d,24,12,0,s,frame^);
  splat;
  carat:=readkey;
  case carat of
   '/': if volume_level>1 then setta_volume(volume_level-1);
   '*': if volume_level<20 then setta_volume(volume_level+1);
  end;
 until (carat<>'/')and(carat<>'*');
end;

procedure go_to_room; {Di DEBUG!!!!}
var i:byte;
begin
  center(23,7,0,'…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª',video^);
  center(24,7,0,'∫ Inserisci indice:      ∫',video^);
  center(25,7,0,'»ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº',video^);
  gotoxy(47,24);readln(i);
  stanza_corrente:=i;
  center(24,7,0,'∫ Inserisci pos. X:      ∫',video^);
  gotoxy(47,24);readln(i);
  where.wx:=i;
  center(24,7,0,'∫ Inserisci pos. Y:      ∫',video^);
  gotoxy(47,24);readln(i);
  where.wy:=i;
  teleported:=true;
  newroom:=true;
end;

procedure replay_music;
begin
  if current_tune<>0 then
   begin
    dealloca_S3M;
    suona(current_tune,FOR_MAIN);
   end;
end;

procedure set_omino_speed;
var s:string[3];
    d:byte;
    carat:char;
begin
 repeat
  center(23,7,0,'…ÕÕÕÕÕÕÕÕVELOCITAÕÕÕÕÕÕÕÕª',frame^);
  center(24,7,0,'∫--------------------    ∫',frame^);
  center(25,7,0,'»ÕÕÕÕÕÕÕÕÕOMINOÕÕÕÕÕÕÕÕÕÕº',frame^);
  swritexy(27+21-delay_value,24,12,0,'+',frame^);
  if 21-delay_value>=10 then d:=0 else d:=1;
  str(21-delay_value,s);
  swritexy(49+d,24,12,0,s,frame^);
  splat;
  carat:=readkey;
  case carat of
   '8': if delay_value>1 then dec(delay_value);
   '2': if delay_value<20 then inc(delay_value);
  end;
 until (carat<>'8')and(carat<>'2');
end;

procedure raccogli_input_da_tastiera;
var pippo:char;
begin
  if keypressed then begin
                       ch:=readkey;
                       case ch of
                         's','S':save;
                         'l','L':load;
                         '+','-':set_text_speed;
                         '/','*':set_music_volume;
                         'g','G':if debugging then go_to_room;
                         'r','R':if not no_music then replay_music;
                         '8','2':set_omino_speed;
                         'b','B':begin
                                  if not(no_music) then
                                   begin
                                    dealloca_S3M;
                                    suona(250,FOR_MAIN);
                                   end;
                                  clrscr;
                                  writeln('segmentation fault');
                                  pippo:=readkey;
                                  if not(no_music) then
                                   begin
                                    dealloca_S3M;
                                    suona(current_tune,FOR_MAIN);
                                   end;
                                 end;
                       end;
                     end
                else ch:=' ';
end;

procedure inizializza;
var str:string;code:integer;
    pippo:byte;
  begin
    textmode(CO80+FONT8x8);
    reset_mouse(errore,tipo);
    window_mouse(0,0,639,399);
    video:=ptr($B800,0);
    new(frame);new(mouse_map);new(env);new(omino);
    new(obj);new(stanzoggetto);new(stanza_visitata);new(guida);
    assign(ominofile,'omino.spt');
    reset(ominofile);
    read(ominofile,omino^);
    close(ominofile);
    hide_cursor;
    assign(general,'parts');
    reset(general);
    read(general,str);
    val(str,n_parti,code);
    reload:=false;
    teleported:=false;
    velocita_testo:=10;
    volume_level:=10;
    changed_music:=true;
    current_tune:=0;
    ch:=' ';
    no_sound:=false;
    no_music:=false;
    debugging:=false;
    {DECOMMENTARE CON MUSNSND}
    evaluate_machine_speed;
    writeln(difference,' machine rated as ',delay_value,' (1=slow)');
    if paramcount<>0 then
     begin
       for pippo:=1 to paramcount do
        begin
         if paramstr(pippo)='nosound' then
           begin writeln('starting with no digital sound');
                 no_sound:=true end
         else if paramstr(pippo)='nomusic' then
                begin writeln('starting with no music');
                      no_music:=true end
         else if paramstr(pippo)='termini' then writeln('pirla...')
         else if paramstr(pippo)='fast' then delay_value:=1
         else if paramstr(pippo)='debug' then debugging:=true
         else writeln('switch ',paramstr(pippo),' ignored. Valid are: nosound nomusic termini');
        end;
        delay(1000);
     end;
    if not no_music then init_Sound_Blaster;
    p:=nil;
  end;

procedure carica_dati(n:byte);
var fname:string;
  begin
    seek(general,1+5*(n-1));{5 ä il numero di file per parte}
    read(general,fname); {salta il file degli oggetti (lo carica azzera)}
    read(general,fname); {nome del file di stanze}
    assign(world,fname);
    reset(world);
    read(general,fname); {nome del file con le reazioni}
    assign(history,fname);
    reset(history);
    {dovrï caricare history in guida...}
    {writeln(fname); ch:=readkey; DEBUG!}
    read(history,guida^);
    close(history);
    read(general,fname);       {nome del}
    assign(istrfile,fname);    {file delle istruzioni}
    reset(istrfile);
    read(general,fname);       {nome del file delle frasi}
    {writeln(fname); ch:=readkey; DEBUG!}
    assign(frasifile,fname);
    reset(istrfile);
    clock:=0;
    used_object:=0;
    frase:=scegli_verbo(VAI);{'Vai verso';}
    newroom:=true;
    selected_object:=0;
    mossa:=VAI;
    uscitoda:=2;
    dispinv:=0;
    dir1:=1;dir2:=0;
  end;

procedure azzera(n:byte);{ricarica gli ogetti e annulla stanzoggetto}
var fname:string;
    i:integer;
  begin
    for i:=0 to 1000 do vincolo[i]:=false;
    seek(general,1+5*(n-1));{5 ä il numero di file per parte}
    read(general,fname);
    assign(objfile,fname);
    object_filename:=fname;
    reset(objfile);
    read(objfile,obj^);
    close(objfile);
    for i:=1 to MAXSTANZE do stanza_visitata^[i]:=false;
    stanzoggetto^[0,0]:=0;
    stanza_corrente:=1;
    livello_corrente:=1;
  end;

begin {main}
  {mark(rilasciatore);}
  inizializza;
  play_anim(TOMMAIS,false);
  play_anim(TITOLI,true);
  play_anim(INTRO,true);
  parte:=1;
  while (parte<=n_parti)and(ch<>'q')and(ch<>'Q') do
  begin
    carica_dati(parte);
    if (ch<>'l')and(ch<>'L') then
     begin
       azzera(parte);
       play_anim(introduzione[parte],false);
     end;
    {if (ch<>'l')and(ch<>'L) then intro(parte);}
    repeat
      clock:=(clock+10001) mod 10000;
      disegna_maschera(frame^); {mette la maschera sullo sfondo}
      if newroom then {carica la nuova stanza}
        begin
          reload:=false;
          if (not(stanza_visitata^[stanza_corrente])) then
            begin {crea la nuova posizione di stanzoggetto}
              idx:=1;
              for i:=1 to MAXOGGETTI{-1}
                do begin
                     if (obj^[i].stanza=stanza_corrente)
                        then begin
                               stanzoggetto^[stanza_corrente,idx]:=i;
                               inc(idx);
                             end;
                   end;
              stanzoggetto^[stanza_corrente,0]:=idx-1;
            end;
          carica_stanza(stanza_corrente,reload);
          newroom:=false;
          if (ch<>'l')and(ch<>'L')and(not teleported) then
            begin
              where.wx:=env^.entrata[5-uscitoda].wx;{aggiorna la posizione}
              where.wy:=env^.entrata[5-uscitoda].wy;{se non ho caricato}
            end;
          inmotion:=false;
          teleported:=false;
          livello_corrente:=1;
          while (env^.levelpos[livello_corrente]>where.wy)and
                (livello_corrente<env^.n_livelli) do inc(livello_corrente);
            {aggiorna il livello}
        end;
      mx:=x_mouse(false)+1;
      my:=y_mouse(false)+1;
      if debugging then
        begin
          gotoxy(63,43);
          write(mx,' ',my,' ',stanza_corrente,' ',
                selected_object,' ',memavail);
        end;
        {^^^st'affare verrÖ rimosso}
      {controlla se il mouse ä sopra qualcosa e scrive nel box della maschera}
      seleziona_oggetto;
      if selected_object<>0
         then if selected_object<>used_object
                 then center(43,2,0,frase+' '+obj^[selected_object].nome,
                             frame^)
                 else center(43,2,0,frase,frame^)
         else center(43,2,0,frase,frame^);
      {accende il verbo}
      if (my>MINYMASCH) then
        begin
          if (mx>=2)and(mx<=10)and(my in [49,47,45]) then
            forecolor(2,my,10,my,14,frame^)
          else if (mx>=12)and(mx<=20)and(my in [49,47,45]) then
            forecolor(12,my,20,my,14,frame^)
          else if (mx>=22)and(mx<=30)and(my in [49,47,45]) then
            forecolor(22,my,30,my,14,frame^)
          else if (mx in [60..62]) then
            case my-MINYMASCH of
              3,4:if dispinv>0 then
                    forecolor(60,MINYMASCH+3,61,MINYMASCH+4,14,frame^);
              6,7:if dispinv+5<stanzoggetto^[0,0] then
                    forecolor(60,MINYMASCH+6,61,MINYMASCH+7,14,frame^);
            end
        end;
      {fine accendi verbo}
      if left_button then {vede un po' cosa cacchio stai facendo col mice}
        begin
          if (my>=MINYMASCH)and(mx<=30) then
            aggiorna_mossa_e_frase(mx,my)
            {seleziona la mossa in funzione di se stessa e di mx,my}
            else begin
                   if (my>MINYMASCH)and(mx>=60)and(mx<=62)
                       then begin {sposta l'inventario}
                              if (my in [MINYMASCH+3,MINYMASCH+4])and
                                 (dispinv>0) then dec(dispinv)
                                 else if (my in [MINYMASCH+6,MINYMASCH+7])and
                                         (dispinv+5<stanzoggetto^[0,0]) then
                                         inc(dispinv);
                            end
                       else esegui_mossa(mx,my);
                 end;
          if mossa<>USAOGGETTO then used_object:=0;
        end
        else if (where.wx=dest.wx)and(where.wy=dest.wy) then inmotion:=false;
      if (inmotion)and((clock mod delay_value)=0) then muovi_omino;
      disegna_inventario(mx,my);
      {disegna lo schermo (eccetto la maschera)}
      if (not teleported) then traccia_schermo(inmotion,false,true);
      raccogli_input_da_tastiera;
    until (ch='q')or(ch='l')or(vincolo[1000])or(ch='Q')or(ch='L');
          {rimuovo un vincolo fondamentale}
    {if vincolo[1000] then fine(parte);}
    close(istrfile);
    close(world);
    if (ch<>'l')and(ch<>'L') then inc(parte);
  end;
  close(general);
  view_cursor;
  textmode(CO80);
  writeln('ok, ok... esco subito...');
  dealloca_S3M;
  dispose(obj);dispose(frame);dispose(stanzoggetto);dispose(omino);
  dispose(guida);dispose(env);dispose(stanza_visitata);dispose(mouse_map);
  {release(rilasciatore);}
end.