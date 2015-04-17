{$N+}
program engine;

type
  scr = array[0..64000-1] of byte;

var
  screen, bump: ^scr;
  a, b, x, y, m: integer;
  s: single;

procedure setvga; assembler;
asm
  mov ax,13h
  int 10h
end;

procedure endvga; assembler;
asm
  mov ax,3h
  int 10h
end;

procedure screenupdate; assembler;
asm
  push ds
  mov ax,0A000h
  lds si,screen
  mov es,ax
  xor di,di
  mov cx,16000
  cld
  db 66h
  rep movsw
  pop ds
end;

procedure setpal;
var
  i: byte;
begin
  for i:= 0 to 255 do
    begin
      port[$3c8] := i;
      port[$3c9] := i div 4;
      port[$3c9] := i div 4;
      port[$3c9] := i div 4;
    end;
end;

procedure makebump;
var
  i, j, dx, dy, c: longint;
begin
  for j := 0 to 200-1 do
    for i := 0 to 320-1 do
      begin
        if (i = 0) or (i = 320-1) then dx := 0
        else dx := bump^[(i-1)+j*320]-bump^[(i+1)+j*320];
        if (j = 0) or (j = 200-1) then dy := 0
        else dy := bump^[i+(j-1)*320]-bump^[i+(j+1)*320];
        c := m-trunc(sqrt(sqr(i-x+dx)+sqr(j-y+dy))/s);
        if c > 255 then c := 255;
        if c < 0 then c := 0;
        screen^[i+j*320] := c;
      end;
end;

procedure loadbump;
var
  bfile: file of byte;
  i: longint;
begin
  assign(bfile,'bump.raw');
  reset(bfile);
  for i := 0 to 64000-1 do
    read(bfile,bump^[i]);
  close(bfile);
end;

begin
  new(screen);
  new(bump);

  setvga;
  setpal;
  loadbump;

  asm
    mov ax,0Bh
    int 33h
    mov a,cx
    mov b,dx
  end;

  x := 160;
  y := 100;
  m := 128;
  s := 0.5;

  repeat
    asm
      mov ax,0Bh
      int 33h
      mov a,cx
      mov b,dx
    end;
    inc(x,a);
    inc(y,b);
    makebump;
    screenupdate;
  until (port[$60] = 1);
  endvga;

  dispose(bump);
  dispose(screen);
end.
