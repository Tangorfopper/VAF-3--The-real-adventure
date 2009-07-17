unit musnsnd;
interface

const FOR_MAIN=0;
      FOR_ANIM=1;

var no_music,no_sound:boolean;
    p:pointer;
    volume_level:byte;
    current_tune:byte; {musica correntemente in play}
    sound_length:word;

procedure init_Sound_Blaster;
procedure setta_volume(value:byte);
procedure dealloca_S3M;
procedure play(idx,from:byte);
procedure suona(idx,from:byte);

implementation

uses s3Mplay,crt,dos;

procedure init_Sound_Blaster;
begin
  if not init_device(1) then
    begin
      writeln(' SoundBlaster not found sorry ... ');
      no_music:=true;
    end
    else set_mastervolume(100);
end;

procedure setta_volume(value:byte);
begin
  volume_level:=value;
  set_mastervolume(10*value);
end;

procedure play(idx:byte;from:byte);
var i:byte;
    s:string[3];
    pippo:file of byte;
  begin
    str(idx,s);
    assign(pippo,'sounds\snd'+s+'.snd');
    {$i-} reset(pippo);
    sound_length:=filesize(pippo); {$i+}
    if ioresult<>0 then sound_length:=0 else close(pippo);
    if (not no_sound)and(idx<>0) then
      begin
        if not no_music
          then begin
                if from=FOR_MAIN then
                 for i:=10 downto 1 do
                  begin set_mastervolume(10*round(volume_level*(i/10)));
                  delay(1); end;
                set_mastervolume(1);
               end;
        swapvectors;
        exec('sound.exe','sounds\snd'+s+'.snd 44');
        {swapvectors;
        swapvectors;}
        exec('sound.exe','sounds\snd'+s+'.snd 0 0 0');
        swapvectors;
        if not no_music then
          if from=FOR_MAIN then
            for i:=1 to 10 do
             begin set_mastervolume(10*round(volume_level*(i/10)));
             delay(1); end
            else set_mastervolume(10*volume_level)
          else;
      end;
  end;

procedure suona(idx,from:byte);
var Samplerate:word;stereo,_16bit:boolean;
    s:string[3];
    h:char;
  begin
    if (not no_music)and(idx<>0)and(idx<>255) then
      begin
        {writeln('PROVO A SUONARE');
        h:=readkey;}
        {mark(p);}
        str(idx,s);
        current_tune:=idx;
        Samplerate:=45454;
        Stereo:=true;
        _16bit:=false;
        if from=FOR_MAIN then if not load_S3M('music\mus'+s+'.s3m') then ;
        if from=FOR_ANIM then if not load_S3M('music\mus'+s+'.s3m') then ;
        {writeln('HO CARICATO!');}
        if not Init_S3Mplayer then ;
        setsamplerate(samplerate,stereo);
        set_ST3order(true);
        loopS3M:=true;
        {writeln('STO PER SUONARE...');}
        {h:=readkey;}
        set_mastervolume(10*volume_level);
        startplaying(stereo,_16bit,false);
        {writeln('FATTO!');}
        {release(p);}
      end;
  end;

procedure dealloca_S3M;
var h:char;
begin
 if not no_music then
  begin
    done_S3Mplayer;
    done_module;
    {release(p);}
  end;
end;

end.