{$N+}
program engine;

const
  degtorad = pi/180;

  mapsize = 32;
  texsize = 128;

  posx: single = 320;
  posy: single = 320;
  angle: single = 0;

  colidst = 16;
  mspeed = 8;
  rspeed = 2;

  vk_esc = 1;
  vk_up = 72;
  vk_left = 75;
  vk_down = 80;
  vk_right = 77;

type
  buff = array[0..0] of byte;

var
  ceiltex, floortex, walltex, screen, map: ^buff;

var
  pal: array[0..255,0..2] of byte;
  keys: array[0..128] of boolean;
  oldirq: longint;
  sina, cosa: single;

{$F+}
procedure keyirq; interrupt;
var
  key: byte;
begin
  key := port[$60];
  if (key < 129) then keys[key] := true else keys[key-128] := false;
  port[$20] := $20;
end;
{$F-}

procedure setkeyboard;
begin
  asm
    cli
  end;
  oldirq := meml[0:9*4];
  meml[0:9*4] := longint(@keyirq);
  asm
    sti
  end;
end;

procedure endkeyboard;
begin
  asm
    cli
  end;
  meml[0:9*4] := oldirq;
  asm
    sti
  end;
end;

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
      port[$3c9] := pal[i,0] div 4;
      port[$3c9] := pal[i,1] div 4;
      port[$3c9] := pal[i,2] div 4;
    end;
end;

procedure wallfloor(x: integer; y: single; tex: integer);
var
  t, s, z: single;
  j, u, v, up, down: integer;
  adr, adq, adt: longint;
begin
  if (y > 0) then
    begin
      up := trunc(-(texsize shr 1)*200/y)+(200-1) shr 1;
      down := trunc((texsize shr 1)*200/y)+(200-1) shr 1;
      t := (x-(320-1) shr 1)*(texsize shr 1)*cosa+200*(texsize shr 1)*sina;
      s := 200*(texsize shr 1)*cosa-(x-(320-1) shr 1)*(texsize shr 1)*sina;

      adr := x; adq := 64000-2*320+x;
      for j := 0 to up-1 do
        begin
          z := 1/((200-1) shr 1-j);
          u := trunc(posx+t*z) mod texsize;
          v := trunc(posy+s*z) mod texsize;

          adt := u+v*texsize;
          screen^[adr] := ceiltex^[adt];
          screen^[adq] := floortex^[adt];
          inc(adr,320); dec(adq,320);
        end;

      for j := up to down do
        begin
          if (j < 0) then j := 0;
          if (j > 200-1) or (down = up) then break;
          v := trunc((j-up)/(down-up)*texsize); u := tex;
          { v := trunc(y*(j-(100-1))/200+texsize shr 1); u := tex;}
          if (v = texsize) then dec(v);
          screen^[adr] := walltex^[u+v*texsize];
          inc(adr,320);
        end;

      adq := 64000-320+x;
      if (down < 200-1) then
        begin
          z := 1/(200-1-(200-1) shr 1);
          u := trunc(posx+t*z) mod texsize;
          v := trunc(posy+s*z) mod texsize;

          adt := u+v*texsize;
          screen^[adq] := floortex^[adt];
        end;
    end;
end;

procedure renderscene;
var
  xdone, ydone: boolean;
  dx, dy, x, y, dstx, dsty: single;
  i, mx, my, tx, ty, txx, txy: integer;
begin
  for i := 0 to 320-1 do
    begin
      dx := (i-(320-1) shr 1)*cosa+200*sina;
      dy := 200*cosa-(i-(320-1) shr 1)*sina;
      dsty := 1 shl 15; dstx := 1 shl 15;

      ydone := false;
      if (dy > 0) then y := texsize-posy+(trunc(posy) div texsize)*texsize
      else y := -posy+(trunc(posy) div texsize)*texsize;
      my := trunc(y+posy) div texsize;
      if (dy <> 0) then
        while not ydone do
          begin
            x := y*dx/dy;

            if (int(x+posx) < 1 shl 15) and (int(x+posx) > -1 shl 15) then
              begin
                mx := trunc(x+posx) div texsize;
                if (mx < 1) or (mx >= mapsize) or (my < 1) or (my >= mapsize) then ydone := true;
                if not ydone and ((map^[mx+(my-1)*mapsize] <> 0) or (map^[mx+my*mapsize] <> 0)) then
                  begin
                    dsty := y*cosa+x*sina;
                    tx := trunc(x+posx) mod texsize;
                    txy := tx; ydone := true;
                  end;
              end
            else ydone := true;

            if (dy > 0) then begin y := y+texsize; inc(my); end
            else begin y := y-texsize; dec(my); end;
          end;

      xdone := false;
      if (dx > 0) then x := texsize-posx+(trunc(posx) div texsize)*texsize
      else x := -posx+(trunc(posx) div texsize)*texsize;
      mx := trunc(x+posx) div texsize;
      if (dx <> 0) then
        while not xdone do
          begin
            y := x*dy/dx;

            if (int(y+posy) < 1 shl 15) and (int(y+posy) > -1 shl 15) then
              begin
                my := trunc(y+posy) div texsize;
                if (mx < 1) or (mx >= mapsize) or (my < 1) or (my >= mapsize) then xdone := true;
                if not xdone and ((map^[mx-1+my*mapsize] <> 0) or (map^[mx+my*mapsize] <> 0)) then
                  begin
                    dstx := y*cosa+x*sina;
                    ty := trunc(y+posy) mod texsize;
                    txx := ty; xdone := true;
                  end;
              end
            else xdone := true;

            if (dx > 0) then begin x := x+texsize; inc(mx); end
            else begin x := x-texsize; dec(mx); end;
          end;

      if (dsty < 1 shl 15) and (dstx < 1 shl 15) then
        if (dsty > dstx) then wallfloor(i,dstx,txx)
        else wallfloor(i,dsty,txy)
      else
        if (dsty < 1 shl 15) then wallfloor(i,dsty,txy)
        else wallfloor(i,dstx,txx);

    end;
end;

function coll: boolean;
begin
  if (map^[(trunc(posx)-colidst) div texsize+(trunc(posy)-colidst) div texsize*mapsize] <> 0) or
    (map^[(trunc(posx)+colidst) div texsize+(trunc(posy)-colidst) div texsize*mapsize] <> 0) or
    (map^[(trunc(posx)-colidst) div texsize+(trunc(posy)+colidst) div texsize*mapsize] <> 0) or
    (map^[(trunc(posx)+colidst) div texsize+(trunc(posy)+colidst) div texsize*mapsize] <> 0) then
    coll := true else coll := false;
end;

procedure loadpal;
var
  palfile: file of byte;
  i: byte;
begin
  assign(palfile,'palette.act');
  reset(palfile);
  for i := 0 to 255 do
    read(palfile,pal[i,0],pal[i,1],pal[i,2]);
  close(palfile);
end;

procedure loadtex;
var
  texfile: file of byte;
  i: integer;
begin
  assign(texfile,'ceil.raw');
  reset(texfile);
  for i := 0 to sqr(texsize)-1 do
    read(texfile,ceiltex^[i]);
  close(texfile);

  assign(texfile,'floor.raw');
  reset(texfile);
  for i := 0 to sqr(texsize)-1 do
    read(texfile,floortex^[i]);
  close(texfile);

  assign(texfile,'wall.raw');
  reset(texfile);
  for i := 0 to sqr(texsize)-1 do
    read(texfile,walltex^[i]);
  close(texfile);
end;

procedure loadmap;
var
  mapfile: file of byte;
  i: integer;
begin
  assign(mapfile,'world.map');
  reset(mapfile);
  for i := 0 to sqr(mapsize)-1 do
    read(mapfile,map^[i]);
  close(mapfile);
end;

begin
  getmem(screen,sizeof(byte)*64000);
  getmem(map,sizeof(byte)*sqr(mapsize));
  getmem(ceiltex,sizeof(byte)*sqr(texsize));
  getmem(floortex,sizeof(byte)*sqr(texsize));
  getmem(walltex,sizeof(byte)*sqr(texsize));

  writeln('Loading files. Please wait...');
  loadpal; write('');
  loadtex; write('');
  loadmap; write('');

  setvga;
  setpal;
  setkeyboard;
  repeat
    sina := sin(angle*degtorad);
    cosa := cos(angle*degtorad);

    renderscene;
    screenupdate;

    if keys[vk_left] then angle := angle-rspeed;
    if keys[vk_right] then angle := angle+rspeed;

    if keys[vk_up] then posy := posy+mspeed*cosa;
    if coll then posy := posy-mspeed*cosa;
    if keys[vk_up] then posx := posx+mspeed*sina;
    if coll then posx := posx-mspeed*sina;

    if keys[vk_down] then posy := posy-mspeed*cosa;
    if coll then posy := posy+mspeed*cosa;
    if keys[vk_down] then posx := posx-mspeed*sina;
    if coll then posx := posx+mspeed*sina;

    if (angle > 360) then angle := angle-360;
    if (angle < 0) then angle := angle+360;
  until keys[vk_esc];
  endkeyboard;
  endvga;

  freemem(walltex,sizeof(byte)*sqr(texsize));
  freemem(floortex,sizeof(byte)*sqr(texsize));
  freemem(ceiltex,sizeof(byte)*sqr(texsize));
  freemem(map,sizeof(byte)*sqr(mapsize));
  freemem(screen,sizeof(byte)*64000);
end.