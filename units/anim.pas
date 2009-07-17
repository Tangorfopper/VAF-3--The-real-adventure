{$M 32768 0 300000}
unit anim;
interface

var point:pointer;

procedure play_anim(idanim:byte;interrompibile:boolean);
{clips\actions.dat e' un file of actionset: contiene le azioni di tutte
 le animazioni (della prima in pos. 1 eccetera)}
{clips\movxx.mov e' la sequenza dei frame dell.animazione xx}
{sounds\sndxx.snd e' il suono digitale numero xx}

var changed_music:boolean; {T se l'animaz. ha cambiato la musica}

implementation

uses crt,dos,musnsnd;

const MAXAZIONI=255;STOP=255;MAXFRAMES=100;

type action=record
             n_fotogramma:word; {# del fotogramma da stampare}
             suono:byte;        {# del suono da produrre}
             ritardo:word;      {# millisecondi da asp. per il pross. frame}
            end;

     Tfotogramma=array [1..8000] of byte;

     actionset=array [0..MAXAZIONI] of action;

     pellicola=array[1..MAXFRAMES] of ^Tfotogramma;

     Tmovie=record
              azioni:actionset;
              film:pellicola;
            end;

var azione:action;
    movie:Tmovie;
    low_memory:boolean;
    filmfile:file of Tfotogramma;

function load_file(idanim:byte):boolean;
var s:string;
    actionfile:file of actionset;
    ind,j:byte;

begin
  low_memory:=false;
  str(idanim,s);
  assign(filmfile,'clips\mov'+s+'.mov');
  {$i-}reset(filmfile);{$i+}
  if ioresult=0 then
   if (memavail>8000*filesize(filmfile)+3000) then
    begin
     assign(actionfile,'clips\actions.dat');
     reset(actionfile);
     seek(actionfile,idanim-1);
     read(actionfile,movie.azioni);
     close(actionfile);
     ind:=1;
     while (not eof(filmfile)) do
       begin
         new(movie.film[ind]);
         read(filmfile,movie.film[ind]^);
         inc(ind);
       end;
     for j:=ind to MAXFRAMES do movie.film[j]:=nil;
     load_file:=true;
    end
    else begin
          assign(actionfile,'clips\actions.dat');
          reset(actionfile);
          seek(actionfile,idanim-1);
          read(actionfile,movie.azioni);
          close(actionfile);
          low_memory:=true;
          load_file:=true;
         end
   else load_file:=false;
end;

procedure play_anim(idanim:byte;interrompibile:boolean);
var i:word;
    video:^Tfotogramma;
    esci:boolean;

begin
  if keypressed then readkey;
  video:=ptr($B800,0);
  {mark(point);}
  if load_file(idanim) then
   begin
    i:=1;
    if (movie.azioni[0].n_fotogramma<>0)
        then begin
               dealloca_S3M;
               suona(movie.azioni[0].n_fotogramma,FOR_ANIM);
               changed_music:=true;
             end
             else changed_music:=false;
    with movie do
      begin
        esci:=false;
        while (azioni[i].n_fotogramma<>STOP)and(not esci) do
          begin
            if interrompibile then esci:=keypressed;
            if not(low_memory)
             then move(film[azioni[i].n_fotogramma]^,video^,8000)
             else begin
                    seek(filmfile,azioni[i].n_fotogramma-1);
                    read(filmfile,video^);
                  end;
            {gotoxy(1,49);write('Mem: ',memavail,' musica:',azioni[0].n_fotogramma,' I= ',i);}
            {^^^^^^^^^^^^^^^^^^^^^^^^^^ DEBUG!}
            if azioni[i].suono<>0 then
             begin
               play(azioni[i].suono,FOR_ANIM);
               if no_sound then delay(sound_length div 10);
             end;
            if azioni[i].ritardo<>0 then delay(azioni[i].ritardo);
            inc(i);
          end;
        if not(low_memory) then
          for i:=1 to MAXFRAMES do if film[i]<>nil then dispose(film[i]);
        if keypressed then readkey;
      end;
     close(filmfile);
    end;
  {release(point);}
end;

end.