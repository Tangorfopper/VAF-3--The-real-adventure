unit types;
interface

const MAXLIVELLI=5;
      MAXOGGETTI=500;
      VAI=0;PRENDI=1;USA=2;USAOGGETTO=9;PARLA=3;SPINGI=4;TIRA=5;
      APRI=6;CHIUDI=7;GUARDA=8;
      MINYMASCH=42;
      MAXSTANZE=256;
      MAXREAZIONI=1000;
      NSINONIMI=5;
      CONST_FRASI: array[0..8,0..NSINONIMI-1] of string[30] =
       (('Vai verso','Trotterella verso','Deambula fino a',
         'Incamminati verso','Scatta verso'),
        ('Prendi','Arraffa','Sgraffigna','Raccatta','Intasca'),
        ('Usa','Sfrutta','Manipola','Maneggia','Armeggia'),
        ('Parla a','Chiacchiera con','Spettegola con','Interpella',
         'Parlotta a'),
        ('Spingi','Premi','Fai forza su','Pigia','Appoggiati a'),
        ('Tira','Attrai','Attira','Risucchia','Avvicina'),
        ('Apri','Sfonda','Divelgi','Passa attraverso','Scardina'),
        ('Chiudi','Sbatti','Sbatacchia','Inibisci l''accesso attraverso',
         'Spranga'),
        ('Guarda','Osserva','Sbircia','Squadra','Esamina')
       );

type screen=array[1..8000] of byte;
     posizione=record
                 wx,wy:byte;
               end;
     stanza=record
              n_livelli:byte;
              livs:array[0..MAXLIVELLI-1] of screen;{la grafica dei livelli}
              moveable:array[1..80,1..50] of integer;
                {0=ci si puo' andare, n>0 e' l'oggetto n, n<0 deve essere
                 verificato il vincolo n. n>500 NON ci si pu• andare,
                 n<-1000 Š l'uscita verso la stanza adiacenza[-(n+1000)].}
              levelpos:array[0..MAXLIVELLI-1] of byte;
                  {levelpos[i]: y alla quale finisce il livello i}
              adiacenza:array[1..4] of integer;
                  {1=nord,3=est,4=sud,2=ovest: indice della stanza confinante}
              entrata:array[1..4] of posizione;
              scala:byte; {la grandezza dell'omino nella stanza}
              backmusic:byte; {indice del sottofondo musicale: 0=non cambia}
            end;
     Pstanza=^stanza;
     alternativa=record
                   proof:array[1..5] of integer; {vincoli da verificare}
                   guadagna,perdi:array [1..3] of integer;
                   meffeig,dialogo:word;{la frase che deve dire}
                   vinc:array [1..10] of integer;{il vincolo che deve rimuovere}
                   special:integer;{l'azione speciale da compiere}{animaz...}
                   prendi:boolean;{T se l'oggetto cui si rif. e' prendibile}
                   stanza_giusta:integer;{stanza dove reagire}
                   swapobj:array[1..5,1..2] of integer;
                           {scambia l'ogg. swapobj[i][1] con swapobj[i][2]
                            otile per fare tipo porta ap. o chiusa}
                   suono:byte; {se e' <>0 e' il suono da produrre}
                   teleport:array[1..3] of byte;
                     {1 e' la stanza in cui teletrasportarsi, 2 e 3 la pos
                      x,y ini cui apparire}
                 end;
     reazione=record
                n_alt:1..3; {numero alternative}
                does:array[1..3] of alternativa;
              end;
     reactions=record
                 causa:longint;
                 effetto:word;
               end;
     storia=array[1..MAXREAZIONI] of reactions;
     oggetto=record
               stanza:integer; {dove si trova inizialmente}
               livello:byte;   {su che livello}
               posx,posy:byte; {in che punto (e' il centro dell'oggetto)}
               dimx,dimy:integer; {quanto e' grosso}
               disegno:array[0..50] of byte; {il suo disegno}
               nome:string[20]; {il suo nome}
             end;
     oggetti_tipo=array[0..MAXOGGETTI] of oggetto;
     omuncolo=record
                dim:array[0..2,1..2] of byte;{dim[0,1]= dimx per la scala 0}
                sprite:array[0..123] of byte;{parte da zero!}
              end;
     mappa_oggetti_tipo=array[0..MAXSTANZE,0..100] of integer;
     mappa_mouse=array[0..4000] of integer;
     stanze_visitate=array[1..MAXSTANZE] of boolean;
     omino_tipo=array[1..10] of omuncolo;
     {posizioni: 1 daisx, 2 daidx, 3 fermo sx, 4 fermo dx, 5 cammina sx}
     {6 cammina dx, 7 fermo sch. sx, 8 fermo sch. dx, 9 schiena sx, 10 schiena dx}
     string_file = file of string;
     Tnodiespansi= array [1..80,1..50] of integer;

implementation
end.