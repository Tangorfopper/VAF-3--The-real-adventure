Unit Mouse;

Interface

Procedure RESET_MOUSE(var Errore:Boolean; var Num:Word);
   {Consente di resettare  lo  stato del Mouse;  deve essere utilizzata al-
    l'inizio  di un programma, dato che consente di inizializzare il driver
    di gestione del Mouse.
    DESCRIZIONE DEI PARAMETRI:
    - Errore:   Consente  di  determinare se  e' stato o meno installato il
                driver del Mouse;
    - Num(ero): Consente di determinare il numero dei tasti attivi presenti
                nel Mouse;}

Procedure OPEN_MOUSE;
   {Consente di attivare il Mouse sullo schermo}

Procedure CLOSE_MOUSE;
   {Consente di "disattivare" il puntatore del Mouse attivo sullo schermo.
    N.B.: In  ogni  programma  ad  ogni  OPEN_MOUSE  deve corrispondere una
    CLOSE_MOUSE,  altrimenti si potranno avere spiacevoli errori in fase di
    esecuzione del programma stesso}

Function LEFT_BUTTON : Boolean;
Function MIDDLE_BUTTON : Boolean;
Function RIGHT_BUTTON : Boolean;
Function A_Button:boolean;
   {Consentono di determinare se e' stato premuto il pulsante del Mouse.}

Function X_MOUSE(w:Boolean):Word;
Function Y_MOUSE(w:Boolean):Word;
   {Consentono di determinare  la  posizione del puntatore del Mouse attivo
    sullo schermo; i valori restituiti sono le coordinate x,y del puntatore
    del Mouse.
    DESCRIZIONE DEL PARAMETRO:
    - W: True  ==> Il valore restituito sara' in forma di Pixels;
         False ==> Il valore restituito  sara'  in termini di posizione del
                   cursore (0..24x0..79)
                   (si effettua DIV 8 in quanto 1 CARATTER=8 PIXELS)}

Procedure POS_MOUSE(x,y:Word);
   {Consente di posizionare il puntatore del Mouse attivo  sullo schermo in
    una determinata posizione specificata dalle coordinate (parametri) x,y.}

Procedure WINDOW_MOUSE(x,y,x1,y1:Word);
   {Consente  di  definire la porzione di video nella quale potra' mouversi
    il puntatore del Mouse sullo schermo. [x,y=зд] , [x1,y1=ды]}

Procedure GRAPHIC_CURSOR(Nome:String; var Errore:Boolean; Hotx,Hoty:Word);
   {Consente di far attivere sullo schermo un nuovo puntatore del Mouse de-
    finito dall'utente. Tale nuovo simbolo  dovra' essere presente sul sup-
    porto magnetico.
    DESCRIZIONE DEI PARAMETRI:
    - Nome: Rappresenta il nome con il relativo precorso del file contenen-
            te il nuovo simbolo grafico da caricare in memoria;
    - Errore: Consente di determinare se si  e' verficato un errore in fase
              di lettura del file contenente il simbolo grafico;
    - Hotx,Hoty: Rappresentano  le  coordinate relative nel simbolo grafico
                 per  la  determinazione del pixel puntato dal Mouse con il
                 suo cursore (0,0=зд).}

Procedure TEXT_CURSOR1(Inizio,Fine:Word);
   {Consente di modificare  la  forma  del cursore hardware del mouse nella
    modalita' testo. Il cursore hardware del Mouse non e' altro che il nor-
    male cursore lampeggiante visibile in tutte le  modalita' testo del vi-
    deo. Le dimensioni  del  cursore possono essere modificate  con  questa
    procedura. Infatti ha 2 parametri che possono variare (0..13) e rappre-
    sentano le linee del cursore che dovranno lampeggiare.}

Procedure TEXT_CURSOR2(Sfondo,Colore:Byte);
   {Consente di modificare, sempre in modo testo, i colori del cursore del
    Mouse. (COLORE=colore di primo piano, SFONDO=colore di sfondo)
    (SFONDO>7 ==> il carattere nella posizione del cursore lampeggiera')}

Procedure XY_REL(var x,y:Word);
   {Consentono di determinare gli spostamenti relativi del Mouse.  Determi-
    nano cioe' lo spostamento fisico del Mouse avvenuto all'atto dell'ulti-
    ma chiamata di una funzione di lettura dello stato del Mouse.
    Il valore restituito viene espressa in termini di "Mickey",  corrispon-
    dente a 1/200 di pollice (0.127 mm).  Per determinare  il  valore in mm
    bastera' dunque moltiplicare il valore restituito per 0.127.}

Procedure RAPPORTO_MOUSE(Oriz,Vert:Word);
   {Consente di impostare la  sensibitita' del Mouse, definita come il rap-
    porto tra lo spostamento fisico del Mouse e lo spostamento in pixel del
    cursore sul video.  Tali rapporti devono essere specificati alla proce-
    dura tramite  l'uso  dei  2  parametri,  che rappresentano il numero di
    Mickey necessari a far mouvere il cursore sullo schermo di 8 pixels.
    Quindi il parametro ORIZ stabilira' la sensibilita' orizzontale, mentre
    VERT quella verticale.}

Procedure NOWINDOW_MOUSE(x,y,x1,y1:Word);
   {Consente di definire la porzione di video in cui  il  Mouse  non  sara'
    piu' visibile. (x,y,x1,y1 identici alla WINDOW_MOUSE)}

Implementation

Uses Dos;
Var r:Registers;

Procedure GEST_MOUSE(Inf:Word);
Begin
  r.ax:=Inf;
  Intr($33,r)
end;

Procedure RESET_MOUSE(Var Errore:Boolean; Var Num:Word);
Begin
  GEST_MOUSE(0);
  Errore:=(r.ax=-1);
  Num:=r.bx
end;

Procedure OPEN_MOUSE;
Begin
  GEST_MOUSE(1)
end;

Procedure CLOSE_MOUSE;
Begin
  GEST_MOUSE(2)
end;

Function LEFT_BUTTON : Boolean;
Begin
  GEST_MOUSE(3);
  LEFT_BUTTON:=(r.bx=1) or (r.bx=3) or (r.bx=5) or (r.bx=7)
end;

Function MIDDLE_BUTTON : Boolean;
Begin
  GEST_MOUSE(3);
  MIDDLE_BUTTON:=(r.bx=4) or (r.bx=5) or (r.bx=6) or (r.bx=7)
end;

Function RIGHT_BUTTON : Boolean;
Begin
  GEST_MOUSE(3);
  RIGHT_BUTTON:=(r.bx=2) or (r.bx=3) or (r.bx=6) or (r.bx=7)
end;

function A_Button: boolean;
begin
  GEST_MOUSE(3);
  A_BUTTON:=(r.bx>=1) and (r.bx<=7)
end;

Function X_MOUSE(w:Boolean):Word;
Begin
  GEST_MOUSE(3);
  if w then X_MOUSE:=r.cx
       else X_MOUSE:=r.cx div 8
end;

Function Y_MOUSE(w:Boolean):Word;
Begin
  GEST_MOUSE(3);
  if w then Y_MOUSE:=r.dx
       else Y_MOUSE:=r.dx div 8
end;

Procedure POS_MOUSE(x,y:Word);
Begin
  r.cx:=x;
  r.dx:=y;
  GEST_MOUSE(4)
end;

Procedure WINDOW_MOUSE(x,y,x1,y1:Word);
Begin
  r.cx:=x;
  r.dx:=x1;
  GEST_MOUSE(7);
  r.cx:=y;
  r.dx:=y1;
  GEST_MOUSE(8)
end;

Procedure GRAPHIC_CURSOR(Nome:String; Var Errore:Boolean; Hotx,Hoty:Word);
Const
  n=16;
Type
  Vettore=Array[1..n] of Word;
  Vettore2=Array[1..n*2] of Word;
Var
  Cursore:File of Vettore;
  Buffer:Vettore;
  Mappa:Vettore2;
  i:Byte;
Begin
  Assign(Cursore,Nome);
  {$I-}
  Reset(Cursore);
  {$I+}
  Errore:=(IOResult<>0);
  If not(Errore) then Begin
                        Read(Cursore,Buffer);
                        Close(Cursore);
                        For i:=1 to 16 do Mappa[i]:=not(Buffer[i]);
                        For i:=17 to 32 do Mappa[i]:=Buffer[i-16];
                        r.bx:=Hotx;
                        r.cx:=Hoty;
                        r.es:=Seg(Mappa);
                        r.dx:=Ofs(Mappa);
                        GEST_MOUSE(9)
                      end
end;

Procedure TEXT_CURSOR1(Inizio,Fine:Word);
Begin;
  r.bx:=1;
  r.cx:=Inizio;
  r.dx:=Fine;
  GEST_MOUSE(10)
end;

PROCEDURE TEXT_CURSOR2(Sfondo,Colore:Byte);
Begin
  if (Sfondo<16) and (Colore<16) then Begin
                                      r.bx:=0;
                                      r.cx:=$00FF;
                                      r.dx:=(Colore*256)+(Sfondo*4096);
                                      GEST_MOUSE(10)
                                    end
end;

Procedure XY_REL(var x,y:Word);
Begin
  GEST_MOUSE(11);
  x:=r.cx; y:=r.dx
end;

Procedure RAPPORTO_MOUSE(Oriz,Vert:Word);
Begin
  r.cx:=oriz;
  r.dx:=vert;
  GEST_MOUSE(15)
end;

Procedure NOWINDOW_MOUSE(x,y,x1,y1:Word);
Begin
  r.cx:=x;
  r.dx:=y;
  r.si:=x1;
  r.di:=y1;
  GEST_MOUSE(16);
end;


end.

