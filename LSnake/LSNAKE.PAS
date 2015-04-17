Program LSnake;

Uses Crt;

Const WielkoscEkranu = 320*200;
      WielkoscTekstury = 10*10;

      SzePolaGry = 30;
      WysPolaGry = 18;
      PoczPolaX = 10;
      PoczPolaY = 10;
      WysPola = 10;
      SzePola = 10;

      MaksDlugosc = 100;
      MaksPunktow = 200;
      DlugPocz = 7;

      Esc = #27;
      SGora = #72;
      SDol = #80;
      SLewo = #75;
      SPrawo = #77;

      Opoznienie = 70;

      SciezkaPalety = 'lsnake.pal';
      SciezkaTla = 'tlo.tex';
      SciezkaTekstury : Array[1..11] of String = ('tek01.tex','tek02.tex','tek03.tex','tek04.tex','tek05.tex',
                                                  'tek06.tex','tek07.tex','tek08.tex','tek09.tex','tek10.tex','tek11.tex');

Type Buf = Array[0..WielkoscEkranu-1] of Byte;
     Tek = Array[0..WielkoscTekstury-1] of Byte;

     Objekt = Record
      X,Y : Integer;
     End;

Var BuforEkranu,Tlo : ^Buf;
    Tekstura : Array[1..11] of ^Tek;
    Waz : Array[1..MaksDlugosc] of Objekt;
    Punkt : Objekt;
    Klawisz : Char;
    KierunekRuchu,DlugoscWeza,Punkty : Integer;

Procedure UstawTrybVGA; Assembler;

Asm
 mov ax,13h
 int 10h
End;

Procedure ZamknijTrybVGA; Assembler;

Asm
 mov ax,3h
 int 10h
End;

Procedure PokazKlatke;

Var X,Y : Integer;
    Kolor : Byte;

Begin
 For Y:=0 to 199 do
  For X:=0 to 319 do
   Begin
    Kolor:=BuforEkranu^[X+Y*320];
    Asm
     mov ax,Y
     mov bx,320
     mul bx
     add ax,X
     mov dx,0A000h
     mov es,dx
     mov di,ax
     mov al,Kolor
     mov es:[di],al
    End;
   End;
End;

Procedure PostawPunkt(X,Y : Integer; Kolor : Byte);

Begin
 If (X>=0) and (X<=319) and (Y>=0) and (Y<=199)
 then BuforEkranu^[X+Y*320]:=Kolor;
End;

Procedure UstawPal(NumerKoloru,C,Z,N : Byte);

Begin
 port[$3c8]:=NumerKoloru;
 port[$3c9]:=C;
 port[$3c9]:=Z;
 port[$3c9]:=N;
End;

Procedure WyczyscEkran;

Var X,Y : Integer;

Begin
 For Y:=0 to 199 do
  For X:=0 to 319 do
   PostawPunkt(X,Y,0);
End;

Procedure PokazTeksture(PoczatekX,PoczatekY,KoniecX,KoniecY,NumerTek : Integer);

Var WysokoscPunktu,SzerokoscPunktu : Real;
    I,J,A,B : Integer;

Begin
 WysokoscPunktu:=(KoniecY-PoczatekY)/10;
 SzerokoscPunktu:=(KoniecX-PoczatekX)/10;
 For I:=0 to KoniecY-PoczatekY do
  For J:=0 to KoniecX-PoczatekX do
   Begin
    A := Trunc(J/SzerokoscPunktu);
    B := Trunc(I/WysokoscPunktu);
    If (A = 10) then Dec(A);
    If (B = 10) then Dec(B);
    If Tekstura[NumerTek]^[A+B*10]<>0 then PostawPunkt(PoczatekX+J,PoczatekY+I,Tekstura[NumerTek]^[A+B*10])
   End;
End;

Procedure WgrajTeksture(Sciezka : String; NumerTek : Integer);

Var X,Y : Integer;
    Plik : File of Byte;

Begin
 Assign(Plik,Sciezka);
 Reset(Plik);
 For Y:=0 to 9 do
  For X:=0 to 9 do
   Read(Plik,Tekstura[NumerTek]^[X+Y*10]);
 Close(Plik);
End;

Procedure WgrajTlo(Sciezka : String);

Var X,Y : Integer;
    Plik : File of Byte;

Begin
 Assign(Plik,Sciezka);
 Reset(Plik);
 For Y:=0 to 199 do
  For X:=0 to 319 do
   Read(Plik,Tlo^[X+Y*320]);
 Close(Plik);
End;

Procedure InicjujWeza;

Var I : Integer;

Begin
 For I:=1 to  DlugPocz do Begin
  Waz[I].X:=(SzePolaGry div 2)+I;
  Waz[I].Y:=(WysPolaGry div 2);
 End;
 KierunekRuchu:=4;
 DlugoscWeza:=DlugPocz;
End;

Procedure InicjujPunkt;

Var I : Integer;
    PoleWolne : Boolean;

Begin
 Repeat
  PoleWolne:=True;
  Punkt.X:=Random(SzePolaGry)+1;
  Punkt.Y:=Random(WysPolaGry)+1;
  For I:=1 to DlugoscWeza do
   If (Punkt.X=Waz[I].X) and (Punkt.Y=Waz[I].Y) then PoleWolne:=False
 Until PoleWolne;
End;

Procedure PokazPoleGry;

Var I,X,Y : Integer;

Begin
 For Y:=1 to WysPolaGry do
  For X:=1 to SzePolaGry do Begin
   For I:=1 to DlugoscWeza do
    If (Waz[I].X=X) and (Waz[I].Y=Y) then Begin

     If (I>1) and (I<DlugoscWeza) and ((Waz[I-1].X=Waz[I].X-1) and (Waz[I+1].X=Waz[I].X+1)
     or (Waz[I+1].X=Waz[I].X-1) and (Waz[I-1].X=Waz[I].X+1)) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,5);

     If (I>1) and (I<DlugoscWeza) and ((Waz[I-1].Y=Waz[I].Y-1) and (Waz[I+1].Y=Waz[I].Y+1)
     or (Waz[I+1].Y=Waz[I].Y-1) and (Waz[I-1].Y=Waz[I].Y+1)) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,6);

     If (I>1) and (I<DlugoscWeza) and ((Waz[I-1].Y=Waz[I].Y-1) and (Waz[I+1].X=Waz[I].X+1)
     or (Waz[I+1].Y=Waz[I].Y-1) and (Waz[I-1].X=Waz[I].X+1)) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,7);

     If (I>1) and (I<DlugoscWeza) and ((Waz[I-1].Y=Waz[I].Y+1) and (Waz[I+1].X=Waz[I].X+1)
     or (Waz[I+1].Y=Waz[I].Y+1) and (Waz[I-1].X=Waz[I].X+1)) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,8);

     If (I>1) and (I<DlugoscWeza) and ((Waz[I-1].Y=Waz[I].Y+1) and (Waz[I+1].X=Waz[I].X-1)
     or (Waz[I+1].Y=Waz[I].Y+1) and (Waz[I-1].X=Waz[I].X-1)) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,9);

     If (I>1) and (I<DlugoscWeza) and ((Waz[I-1].Y=Waz[I].Y-1) and (Waz[I+1].X=Waz[I].X-1)
     or (Waz[I+1].Y=Waz[I].Y-1) and (Waz[I-1].X=Waz[I].X-1)) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,10);

     If (I=1) and (Waz[I+1].Y=Waz[I].Y-1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,3);

     If (I=1) and (Waz[I+1].Y=Waz[I].Y+1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,1);

     If (I=1) and (Waz[I+1].X=Waz[I].X-1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,2);

     If (I=1) and (Waz[I+1].X=Waz[I].X+1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,4);

     If (I=DlugoscWeza) and (Waz[I-1].Y=Waz[I].Y-1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,3);

     If (I=DlugoscWeza) and (Waz[I-1].Y=Waz[I].Y+1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,1);

     If (I=DlugoscWeza) and (Waz[I-1].X=Waz[I].X-1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,2);

     If (I=DlugoscWeza) and (Waz[I-1].X=Waz[I].X+1) then
      PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,4);
    End;
   If (Punkt.X=X) and (Punkt.Y=Y) then
    PokazTeksture(X*SzePola+PoczPolaX-SzePola,Y*WysPola+PoczPolaY-WysPola,X*SzePola+PoczPolaX-1,Y*WysPola+PoczPolaY-1,11);
  End;
End;

Procedure WgrajPalete(Sciezka : String);

Var I : Byte;
    C,Z,N : Char;
    Plik : Text;
    Linia : String;

Begin
 Assign(Plik,Sciezka);
 Reset(Plik);
 For I:=0 to 255 do Begin
  Read(Plik,C,Z,N);
  UstawPal(I,Ord(C) div 4,Ord(Z) div 4,Ord(N) div 4);
 End;
 Close(Plik);
End;

Function Wygrana : Boolean;

Begin
 Wygrana:=False;
 If Punkty=MaksPunktow then Wygrana:=True;
End;

Function Przegrana : Boolean;

Var I : Integer;

Begin
 Przegrana:=False;
 If (Waz[1].X<1) or (Waz[1].X>SzePolaGry) or (Waz[1].Y<1) or (Waz[1].Y>WysPolaGry) then Przegrana:=True;
 For I:=2 to DlugoscWeza do
  If (Waz[1].X=Waz[I].X) and (Waz[1].Y=Waz[I].Y) then Przegrana:=True;
End;

Procedure PrzemiescWeza;

Var I : Integer;

Begin
 If KeyPressed then Begin
  Klawisz:=ReadKey;
  If Klawisz=#0 then Klawisz:=ReadKey;
  If (Klawisz=SLewo) and (KierunekRuchu<>2) then KierunekRuchu:=4;
  If (Klawisz=SDol) and (KierunekRuchu<>1) then KierunekRuchu:=3;
  If (Klawisz=SPrawo) and (KierunekRuchu<>4) then KierunekRuchu:=2;
  If (Klawisz=SGora) and (KierunekRuchu<>3) then KierunekRuchu:=1;
 End;
 For I:=DlugoscWeza downto 2 do Begin
  Waz[I].X:=Waz[I-1].X;
  Waz[I].Y:=Waz[I-1].Y;
 End;
 If (KierunekRuchu=1) then Waz[1].Y:=Waz[1].Y-1;
 If (KierunekRuchu=2) then Waz[1].X:=Waz[1].X+1;
 If (KierunekRuchu=3) then Waz[1].Y:=Waz[1].Y+1;
 If (KierunekRuchu=4) then Waz[1].X:=Waz[1].X-1;
End;

Procedure SprawdzPunkt;

Begin
 If (Waz[1].X=Punkt.X) and (Waz[1].Y=Punkt.Y) then Begin
  Inc(Punkty);
  If DlugoscWeza<MaksDlugosc then Inc(DlugoscWeza);
  InicjujPunkt;
 End;
End;

Procedure PokazTlo;

Var X,Y : Integer;

Begin
 For Y:=0 to 199 do
  For X:=0 to 319 do
   PostawPunkt(X,Y,Tlo^[X+Y*320]);
End;

Var I : Integer;

Begin
 For I:=1 to 11 do
  New(Tekstura[I]);
 New(Tlo);
 New(BuforEkranu);

 Writeln('Loading files. Please wait...');
 WgrajTlo(SciezkaTla); Write('');
 For I:=1 to 11 do Begin
  WgrajTeksture(SciezkaTekstury[I],I);
  Write('');
 End;

 Randomize;
 UstawTrybVGA;

 WgrajPalete(SciezkaPalety);
 Delay(1000);

 InicjujWeza;
 InicjujPunkt;
 Punkty:=0;
 Repeat
  SprawdzPunkt;
  PrzemiescWeza;
  WyczyscEkran;
  PokazTlo;
  PokazPoleGry;
  PokazKlatke;
  Delay(Opoznienie);
 Until (Klawisz=Esc) or Wygrana or Przegrana;
 ZamknijTrybVGA;

 Dispose(BuforEkranu);
 Dispose(Tlo);
 For I:=11 downto 1 do
  Dispose(Tekstura[I]);
End.