{$N+}
program engine;

const
  degtorad = pi/180;
  texsize = 128;

type
  Tbuff = array[0..0] of byte;

  Tvertex = record
    x, y, z, u, v: single;
  end;

  Tpolygon = array[0..2] of Tvertex;
  Tpolypnt = ^Tpolygon;

  Tobject = array[0..0] of Tpolygon;

var
  faces: ^Tobject;
  angle: single;
  hmface: integer;
  screen, zbuff, texture: ^Tbuff;
  pal: array[0..255,0..2] of byte;

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

procedure polygon(src: Tpolypnt);
var
  i, j, s, e, adr: integer;
  l, r, dl, dr, zl, zr: single;
  dzl, dzr, dz, zi, z: single;
  ul, ur, dul, dur, u, du: single;
  vl, vr, dvl, dvr, v, dv: single;

  x0, y0, x1, y1, x2, y2: integer;
  z0, u0, v0, z1, u1, v1, z2, u2, v2: single;
begin
  x0 := round(src^[0].x/src^[0].z*200)+(320-1) shr 1;
  y0 := round(src^[0].y/src^[0].z*200)+(200-1) shr 1;
  x1 := round(src^[1].x/src^[1].z*200)+(320-1) shr 1;
  y1 := round(src^[1].y/src^[1].z*200)+(200-1) shr 1;
  x2 := round(src^[2].x/src^[2].z*200)+(320-1) shr 1;
  y2 := round(src^[2].y/src^[2].z*200)+(200-1) shr 1;

  z0 := 1/src^[0].z; z1 := 1/src^[1].z; z2 := 1/src^[2].z;
  u0 := src^[0].u*z0; v0 := src^[0].v*z0;
  u1 := src^[1].u*z1; v1 := src^[1].v*z1;
  u2 := src^[2].u*z2; v2 := src^[2].v*z2;

  if (y0 > y1) then
    begin
      i := x0; j := y0; z := z0; u := u0; v := v0;
      x0 := x1; y0 := y1; z0 := z1; u0 := u1; v0 := v1;
      x1 := i; y1 := j; z1 := z; u1 := u; v1 := v;
    end;
  if (y0 > y2) then
    begin
      i := x0; j := y0; z := z0; u := u0; v := v0;
      x0 := x2; y0 := y2; z0 := z2; u0 := u2; v0 := v2;
      x2 := i; y2 := j; z2 := z; u2 := u; v2 := v;
    end;
  if (y1 > y2) then
    begin
      i := x1; j := y1; z := z1; u := u1; v := v1;
      x1 := x2; y1 := y2; z1 := z2; u1 := u2; v1 := v2;
      x2 := i; y2 := j; z2 := z; u2 := u; v2 := v;
    end;

  if (y0 <> y1) then
    begin
      dl := (x2-x0)/(y2-y0);
      dr := (x1-x0)/(y1-y0);
      dzl := (z2-z0)/(y2-y0);
      dzr := (z1-z0)/(y1-y0);
      dul := (u2-u0)/(y2-y0);
      dur := (u1-u0)/(y1-y0);
      dvl := (v2-v0)/(y2-y0);
      dvr := (v1-v0)/(y1-y0);
    end;
  l := x0; r := x0;
  zl := z0; zr := z0;
  ul := u0; ur := u0;
  vl := v0; vr := v0;
  for i := y0 to y1-1 do
    begin
      s := round(l); e := round(r);
      if (s > e) then begin zi := zr; u := ur; v := vr; end
      else begin zi := zl; u := ul; v := vl; end;
      if (s < e) then
        begin
          dz := (zr-zl)/(e-s);
          du := (ur-ul)/(e-s);
          dv := (vr-vl)/(e-s);
        end;
      if (s > e) then
        begin
          j := s; s := e; e := j;
          dz := (zl-zr)/(e-s);
          du := (ul-ur)/(e-s);
          dv := (vl-vr)/(e-s);
        end;
      adr := s+i*320;
      for j := 0 to e-s do
        begin
          z := 1/zi;
          if (z < zbuff^[adr]) or (zbuff^[adr] = 0) then
            begin
              screen^[adr] := texture^[trunc(u*z*texsize)+trunc(v*z*texsize)*texsize];
              zbuff^[adr] := trunc(z);
            end;
          zi := zi+dz; u := u+du; v := v+dv; inc(adr);
        end;
      l := l+dl; r := r+dr;
      zl := zl+dzl; zr := zr+dzr;
      ul := ul+dul; ur := ur+dur;
      vl := vl+dvl; vr := vr+dvr;
    end;

  if (y1 <> y2) then
    begin
      dl := (x2-x0)/(y2-y0);
      dr := (x2-x1)/(y2-y1);
      dzl := (z2-z0)/(y2-y0);
      dzr := (z2-z1)/(y2-y1);
      dul := (u2-u0)/(y2-y0);
      dur := (u2-u1)/(y2-y1);
      dvl := (v2-v0)/(y2-y0);
      dvr := (v2-v1)/(y2-y1);
    end;
  if (y0 = y1) then
    begin
      l := x0; r := x1;
      zl := z0; zr := z1;
      ul := u0; ur := u1;
      vl := v0; vr := v1;
    end;
  for i := y1 to y2 do
    begin
      s := round(l); e := round(r);
      if (s > e) then begin zi := zr; u := ur; v := vr; end
      else begin zi := zl; u := ul; v := vl; end;
      if ( s < e ) then
        begin
          dz := (zr-zl)/(e-s);
          du := (ur-ul)/(e-s);
          dv := (vr-vl)/(e-s);
        end;
      if (s > e) then
        begin
          j := s; s := e; e := j;
          dz := (zl-zr)/(e-s);
          du := (ul-ur)/(e-s);
          dv := (vl-vr)/(e-s);
        end;
      adr := s+i*320;
      for j := 0 to e-s do
        begin
          z := 1/zi;
          if (z < zbuff^[adr]) or (zbuff^[adr] = 0) then
            begin
              screen^[adr] := texture^[trunc(u*z*texsize)+trunc(v*z*texsize)*texsize];
              zbuff^[adr] := trunc(z);
            end;
          zi := zi+dz; u := u+du; v := v+dv; inc(adr);
        end;
      l := l+dl; r := r+dr;
      zl := zl+dzl; zr := zr+dzr;
      ul := ul+dul; ur := ur+dur;
      vl := vl+dvl; vr := vr+dvr;
    end;
end;

procedure renderscene;
var
  f: Tpolygon;
  r: single;
  i, j: integer;
begin
  for i := 0 to hmface-1 do
    begin
      f := faces^[i];
      for j := 0 to 2 do
        begin
          r := f[j].x;
          f[j].x := r*cos(angle*degtorad)+f[j].z*sin(angle*degtorad);
          f[j].z := f[j].z*cos(angle*degtorad)-r*sin(angle*degtorad);
          r := f[j].y;
          f[j].y := r*cos(angle*degtorad*0.5)+f[j].z*sin(angle*degtorad*0.5);
          f[j].z := f[j].z*cos(angle*degtorad*0.5)-r*sin(angle*degtorad*0.5);
          f[j].z := f[j].z+50;
        end;
      polygon(@f);
    end;
end;

procedure loadtex;
var
  texfile: file of byte;
  i: integer;
begin
  assign(texfile,'texture.raw');
  reset(texfile);
  for i := 0 to texsize*texsize-1 do
    read(texfile,texture^[i]);
  close(texfile);
end;

procedure loadobj;
var
  objfile: text;
  i, j: integer;
begin
  assign(objfile,'object.obj');
  reset(objfile);
  read(objfile,hmface);
  getmem(faces,sizeof(Tpolygon)*hmface);
  for i := 0 to hmface-1 do
    for j := 0 to 2 do
      read(objfile,faces^[i][j].x,faces^[i][j].y,faces^[i][j].z,faces^[i][j].u,faces^[i][j].v);
  close(objfile);
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

begin
  getmem(screen,sizeof(byte)*64000);
  getmem(zbuff,sizeof(byte)*64000);
  getmem(texture,sizeof(byte)*sqr(texsize));

  writeln('Loading files. Please wait...');
  loadpal; write('');
  loadobj; write('');
  loadtex; write('');

  angle := 0;

  setvga;
  setpal;
  repeat
    fillchar(screen^,64000,0);
    fillchar(zbuff^,64000,0);

    renderscene;
    screenupdate;

    angle := angle+1.5;
  until port[$60] = 1;
  endvga;

  freemem(faces,sizeof(Tpolygon)*hmface);
  freemem(texture,sizeof(byte)*sqr(texsize));
  freemem(zbuff,sizeof(byte)*64000);
  freemem(screen,sizeof(byte)*64000);
end.