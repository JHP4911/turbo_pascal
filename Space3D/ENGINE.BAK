{$N+}
program engine;

const
  texsize = 64;

type
  Tbuff = array[0..0] of byte;

  Tvertex = record
    x, y, z, u, v: single;
  end;

  Tvector = record
    x, y, z: single;
  end;

  Tpolygon = array[0..2] of Tvertex;
  Tpolypnt = ^Tpolygon;

  Tobject = array[0..0] of Tpolygon;

  Tallfaces = array[0..0] of integer;
  Tallobjects = array[0..0] of ^Tobject;
  Talltextures = array[0..0] of ^Tbuff;

var
  obj: ^Tallobjects;
  tex: ^Talltextures;
  hmf: ^Tallfaces;
  screen, zbuff: ^Tbuff;
  pal: array[0..255,0..2] of byte;
  dark: array[0..255,0..63] of byte;
  keys: array[0..128] of boolean;
  oldirq: longint;

const
  light: Tvector = (x: 0; y: 1; z: -1);

  vk_esc = 1;
  vk_space = 57;
  vk_up = 72;
  vk_left = 75;
  vk_down = 80;
  vk_right = 77;
  vk_forw = 30;
  vk_back = 44;

  acc = 0.05;
  shotint = 12;
  maxspeed = 3.0;
  minspeed = 2.0;
  maxangle = 20;
  anxspeed = 1.0;
  anyspeed = 0.6;

  AIacc = 0.05;
  AIshotran = 3.0;
  AIshotint = 25;
  maxAIspeed = 2.5;
  minAIspeed = 2.0;
  anxAIspeed = 0.6;
  anyAIspeed = 0.4;

  maxshot = 100;
  shotspd = 7.0;
  shotstr = 25;
  shotlif = 100;

  maxexpl = 10;
  explmin = 15;
  explmax = 30;
  expllif = 25;

  tarsiz = 10;
  tradst = 200;
  traco1 = 8;
  traco2 = 5;
  traco3 = 177;
  traco4 = 202;

  camdst = 25;
  camran = 10;
  camhgh = 10;
  lodsw = 250;

  maxdust = 100;
  randust = 150;
  dustcol1 = 79;
  dustcol2 = 68;
  dustcol3 = 224;
  dustcol4 = 236;
  dustcol5 = 250;

  maxstars = 150;
  starcol1 = 15;
  starcol2 = 20;

  plateam = 2;
  eneteam = 5;

  maxdx = 50;
  maxdy = 50;
  muldx = 10;
  muldy = 7;

type
  Pship = ^Tship;
  Tship = record
    pos: Tvector;
    ang, anx, anz, speed: single;
    shotint, health: integer;
    target: Pship;
    typ: byte;
  end;

  Tspec = record
    on: boolean;
    pos: Tvector;
    ang, anx, anz, speed: single;
    life: integer;
    typ: byte;
  end;

var
  dx, dy, shotc, explc: integer;
  cam, box, tracer: Tvector;
  figh: array[1..plateam+eneteam] of Tship;
  shot: array[1..maxshot] of Tspec;
  expl: array[1..maxexpl] of Tspec;
  star: array[1..maxstars] of Tvector;
  dust: array[1..maxdust] of Tvector;
  temp, tlight: Tvector;
  camang: single;

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

procedure wait_f; assembler;
asm
  mov dx,03dah
@c1:
  in al,dx
  test al,8
  jnz @c1
@c2:
  in al,dx
  test al,8
  jz @c2
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

procedure polygon(src: Tpolypnt; texno, color: byte);
var
  i, j, s, e, adr: integer;
  l, r, dl, dr, zl, zr: single;
  dzl, dzr, dz, zi, z: single;
  ul, ur, dul, dur, u, du: single;
  vl, vr, dvl, dvr, v, dv: single;

  x0, y0, x1, y1, x2, y2: integer;
  z0, u0, v0, z1, u1, v1, z2, u2, v2: single;
begin
  x0 := round(src^[0].x/src^[0].z*150)+(320-1) shr 1;
  y0 := round(src^[0].y/src^[0].z*150)+(200-1) shr 1;
  x1 := round(src^[1].x/src^[1].z*150)+(320-1) shr 1;
  y1 := round(src^[1].y/src^[1].z*150)+(200-1) shr 1;
  x2 := round(src^[2].x/src^[2].z*150)+(320-1) shr 1;
  y2 := round(src^[2].y/src^[2].z*150)+(200-1) shr 1;

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
      if not (i < 200) then break;
      if (i < 0) then
        begin
          if (y1-1 < 0) then break;
          l := l-dl*i; r := r-dr*i;
          zl := zl-dzl*i; zr := zr-dzr*i;
          ul := ul-dul*i; ur := ur-dur*i;
          vl := vl-dvl*i; vr := vr-dvr*i;
          i := 0;
        end;
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
          if not (j+s < 320) then break;
          if (s < 0) then
            begin
              if (e < 0) then break;
              zi := zi-dz*s; u := u-du*s;
              v := v-dv*s; j := -s;
              adr := adr-s; s := 0;
            end;
          z := 1/zi;
          if (z < zbuff^[adr]) or (zbuff^[adr] = 0) then
            begin
              screen^[adr] := dark[tex^[texno]^[trunc(u*z*texsize)+trunc(v*z*texsize)*texsize],color];
              if (z < 256) then zbuff^[adr] := trunc(z)
              else zbuff^[adr] := 0;
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
  if (y1-1 < 0) then
    begin
      l := x0+dl*(y1-1-y0); r := x1;
      zl := z0+dzl*(y1-1-y0); zr := z1;
      ul := u0+dul*(y1-1-y0); ur := u1;
      vl := v0+dvl*(y1-1-y0); vr := v1;
    end;
  for i := y1 to y2 do
    begin
      if not (i < 200) then break;
      if (i < 0) then
        begin
          if (y2 < 0) then break;
          l := l-dl*i; r := r-dr*i;
          zl := zl-dzl*i; zr := zr-dzr*i;
          ul := ul-dul*i; ur := ur-dur*i;
          vl := vl-dvl*i; vr := vr-dvr*i;
          i := 0;
        end;
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
          if not (j+s < 320) then break;
          if (s < 0) then
            begin
              if (e < 0) then break;
              zi := zi-dz*s; u := u-du*s;
              v := v-dv*s; j := -s;
              adr := adr-s; s := 0;
            end;
          z := 1/zi;
          if (z < zbuff^[adr]) or (zbuff^[adr] = 0) then
            begin
              screen^[adr] := dark[tex^[texno]^[trunc(u*z*texsize)+trunc(v*z*texsize)*texsize],color];
              if (z < 256) then zbuff^[adr] := trunc(z)
              else zbuff^[adr] := 0;
            end;
          zi := zi+dz; u := u+du; v := v+dv; inc(adr);
        end;
      l := l+dl; r := r+dr;
      zl := zl+dzl; zr := zr+dzr;
      ul := ul+dul; ur := ur+dur;
      vl := vl+dvl; vr := vr+dvr;
    end;
end;

procedure renderobject(objno, texno: byte; dx, dy, dz, ay, ax, az: single; shaded: boolean; light: Tvector);
var
  f: Tpolygon;
  r, ang: single;
  i, j: integer;
  a, b, n: Tvector;
begin
  for i := 0 to hmf^[objno]-1 do
    begin
      f := obj^[objno]^[i];
      for j := 0 to 2 do
        begin
          r := f[j].x;
          f[j].x := r*cos(az*pi/180)+f[j].y*sin(az*pi/180);
          f[j].y := f[j].y*cos(az*pi/180)-r*sin(az*pi/180);
          r := f[j].y;
          f[j].y := r*cos(ax*pi/180)+f[j].z*sin(ax*pi/180);
          f[j].z := f[j].z*cos(ax*pi/180)-r*sin(ax*pi/180);
          r := f[j].x;
          f[j].x := r*cos(ay*pi/180)+f[j].z*sin(ay*pi/180);
          f[j].z := f[j].z*cos(ay*pi/180)-r*sin(ay*pi/180);

          f[j].x := f[j].x+dx;
          f[j].y := f[j].y+dy;
          f[j].z := f[j].z+dz;
        end;
      if (f[0].z > 5) and (f[1].z > 5) and (f[2].z > 5) then
        begin
          a.x := f[1].x-f[0].x; a.y := f[1].y-f[0].y; a.z := f[1].z-f[0].z;
          b.x := f[2].x-f[0].x; b.y := f[2].y-f[0].y; b.z := f[2].z-f[0].z;
          n.x := a.y*b.z-a.z*b.y; n.y := b.x*a.z-a.x*b.z; n.z := a.x*b.y-a.y*b.x;
          a.x := f[0].x; a.y := f[0].y; a.z := f[0].z;
          ang := (n.x*a.x+n.y*a.y+n.z*a.z)/sqrt(sqr(n.x)+sqr(n.y)+sqr(n.z))/sqrt(sqr(a.x)+sqr(a.y)+sqr(a.z));
          if (ang > 0) then
            if shaded then
              begin
                ang := (n.x*light.x+n.y*light.y+n.z*light.z)/sqrt(sqr(n.x)+sqr(n.y)+
                      sqr(n.z))/sqrt(sqr(light.x)+sqr(light.y)+sqr(light.z));
                polygon(@f,texno,16-trunc((ang+1)/2*16));
              end
            else
              polygon(@f,texno,0);
        end;
    end;
end;

procedure loadtex(filename: string; texno: byte);
var
  texfile: file of byte;
  i: integer;
begin
  assign(texfile,filename);
  reset(texfile);
  for i := 0 to texsize*texsize-1 do
    read(texfile,tex^[texno]^[i]);
  close(texfile);
end;

procedure loadobj(filename: string; objno: byte);
var
  objfile: text;
  i, j: integer;
begin
  assign(objfile,filename);
  reset(objfile);
  read(objfile,hmf^[objno]);
  getmem(obj^[objno],sizeof(Tpolygon)*hmf^[objno]);
  for i := 0 to hmf^[objno]-1 do
    for j := 0 to 2 do
      read(objfile,obj^[objno]^[i][j].x,obj^[objno]^[i][j].y,obj^[objno]^[i][j].z,obj^[objno]^[i][j].u,obj^[objno]^[i][j].v);
  close(objfile);
end;

procedure loadpal(filename: string);
var
  vr, vg, vb, r, g, b: integer;
  palfile: file of byte;
  i, j, k, c: byte;
  t, p: single;
begin
  assign(palfile,filename);
  reset(palfile);
  for i := 0 to 255 do
    read(palfile,pal[i,0],pal[i,1],pal[i,2]);
  close(palfile);

  pal[0,0] := 0; pal[0,1] := 0; pal[0,2] := 0;
  for j := 0 to 64 do
    dark[0,j] := 0;

  for j := 0 to 255 do
    for k := 0 to 63 do
      begin
        vr := pal[j,0]-k*4; vg := pal[j,1]-k*4; vb := pal[j,2]-k*4;
        c := 0; r := abs(pal[0,0]-vr); g := abs(pal[0,1]-vg); b := abs(pal[0,2]-vb);
        p := (r+g+b)/3;
        for i := 1 to 255 do
          begin
            r := abs(pal[i,0]-vr); g := abs(pal[i,1]-vg); b := abs(pal[i,2]-vb);
            t := (r+g+b)/3;
            if (t < p) then
              begin
                c := i;
                p := t;
              end;
          end;
        dark[j,k] := c;
      end;
end;

procedure control;
var
  dxdone, dydone: boolean;
  i, j: integer;
begin
  if (figh[1].health > 0) then
    begin
      dxdone := false;
      if keys[vk_left] then
        begin
          figh[1].ang := figh[1].ang-anxspeed;
          inc(dx,2);
          dxdone := true;
        end;
      if keys[vk_right] then
        begin
          figh[1].ang := figh[1].ang+anxspeed;
          dec(dx,2);
          dxdone := true;
        end;
      if not dxdone then
        begin
          if (dx > 0) then dec(dx);
          if (dx < 0) then inc(dx);
        end;

      if (dx > maxdx) then dx := maxdx;
      if (dx < -maxdx) then dx := -maxdx;
      figh[1].anz := 2*dx/maxdx*maxangle;

      dydone := false;
      if keys[vk_down] then
        begin
          figh[1].anx := figh[1].anx-anyspeed;
          inc(dy,2);
          dydone := true;
        end;
      if keys[vk_up] then
        begin
          figh[1].anx := figh[1].anx+anyspeed;
          dec(dy,2);
          dydone := true;
        end;
      if not dydone then
        begin
          if (dy > 0) then dec(dy);
          if (dy < 0) then inc(dy);
        end;

      if (dy > maxdy) then dy := maxdy;
      if (dy < -maxdy) then dy := -maxdy;

      if (figh[1].anx > maxangle) then figh[1].anx := maxangle;
      if (figh[1].anx < -maxangle) then figh[1].anx := -maxangle;

      if keys[vk_forw] then figh[1].speed := figh[1].speed+acc;
      if keys[vk_back] then figh[1].speed := figh[1].speed-acc;
      if (figh[1].speed > maxspeed) then figh[1].speed := maxspeed;
      if (figh[1].speed < minspeed) then figh[1].speed := minspeed;

      if (figh[1].shotint = shotint) then
        begin
          if keys[vk_space] then
            begin
              inc(shotc);
              if (shotc > maxshot) then shotc := 1;

              figh[1].shotint := 0;

              shot[shotc].on := true;
              shot[shotc].life := 0;
              shot[shotc].typ := 0;
              shot[shotc].speed := shotspd;

              temp.x := -(tarsiz shr 1)*cos(-figh[1].anz*pi/180);
              temp.y := -(tarsiz shr 1)*sin(-figh[1].anz*pi/180);
              temp.z := tarsiz shr 1;
              shot[shotc].pos := temp;
              temp.x := shot[shotc].pos.x;
              temp.y := shot[shotc].pos.y*cos(-figh[1].anx*pi/180)-shot[shotc].pos.z*sin(-figh[1].anx*pi/180);
              temp.z := shot[shotc].pos.z*cos(-figh[1].anx*pi/180)+shot[shotc].pos.y*sin(-figh[1].anx*pi/180);
              shot[shotc].pos := temp;
              temp.x := shot[shotc].pos.x*cos(figh[1].ang*pi/180)+shot[shotc].pos.z*sin(figh[1].ang*pi/180);
              temp.y := shot[shotc].pos.y;
              temp.z := shot[shotc].pos.z*cos(figh[1].ang*pi/180)-shot[shotc].pos.x*sin(figh[1].ang*pi/180);

              shot[shotc].pos.x := figh[1].pos.x+temp.x;
              shot[shotc].pos.z := figh[1].pos.z+temp.z;
              shot[shotc].pos.y := figh[1].pos.y+temp.y;

              shot[shotc].ang := figh[1].ang+arctan((tarsiz shr 1)/(2*tradst))*180/pi;
              shot[shotc].anz := figh[1].anz;
              shot[shotc].anx := figh[1].anx;

              inc(shotc);
              if (shotc > maxshot) then shotc := 1;

              figh[1].shotint := 0;

              shot[shotc].on := true;
              shot[shotc].life := 0;
              shot[shotc].typ := 0;
              shot[shotc].speed := shotspd;

              temp.x := (tarsiz shr 1)*cos(-figh[1].anz*pi/180);
              temp.y := (tarsiz shr 1)*sin(-figh[1].anz*pi/180);
              temp.z := tarsiz shr 1;
              shot[shotc].pos := temp;
              temp.x := shot[shotc].pos.x;
              temp.y := shot[shotc].pos.y*cos(-figh[1].anx*pi/180)-shot[shotc].pos.z*sin(-figh[1].anx*pi/180);
              temp.z := shot[shotc].pos.z*cos(-figh[1].anx*pi/180)+shot[shotc].pos.y*sin(-figh[1].anx*pi/180);
              shot[shotc].pos := temp;
              temp.x := shot[shotc].pos.x*cos(figh[1].ang*pi/180)+shot[shotc].pos.z*sin(figh[1].ang*pi/180);
              temp.y := shot[shotc].pos.y;
              temp.z := shot[shotc].pos.z*cos(figh[1].ang*pi/180)-shot[shotc].pos.x*sin(figh[1].ang*pi/180);

              shot[shotc].pos.x := figh[1].pos.x+temp.x;
              shot[shotc].pos.z := figh[1].pos.z+temp.z;
              shot[shotc].pos.y := figh[1].pos.y+temp.y;

              shot[shotc].ang := figh[1].ang-arctan((tarsiz shr 1)/(2*tradst))*180/pi;
              shot[shotc].anz := figh[1].anz;
              shot[shotc].anx := figh[1].anx;
            end;
        end
      else inc(figh[1].shotint);

      figh[1].pos.x := figh[1].pos.x+figh[1].speed*sin(pi/180*figh[1].ang)*cos(pi/180*figh[1].anx);
      figh[1].pos.z := figh[1].pos.z+figh[1].speed*cos(pi/180*figh[1].ang)*cos(pi/180*figh[1].anx);
      figh[1].pos.y := figh[1].pos.y+figh[1].speed*sin(pi/180*figh[1].anx);
    end;

  for i := 1 to maxshot do
    if shot[i].on then
      begin
        if (shot[i].life > shotlif) then shot[i].on := false
        else
          begin
            shot[i].pos.x := shot[i].pos.x+shot[i].speed*sin(pi/180*shot[i].ang)*cos(pi/180*shot[i].anx);
            shot[i].pos.z := shot[i].pos.z+shot[i].speed*cos(pi/180*shot[i].ang)*cos(pi/180*shot[i].anx);
            shot[i].pos.y := shot[i].pos.y+shot[i].speed*sin(pi/180*shot[i].anx);
          end;

        for j := 1 to plateam+eneteam do
          begin
            if (figh[j].health > 0) then
              if (abs(shot[i].pos.x-figh[j].pos.x) < tarsiz shr 1) and
                 (abs(shot[i].pos.y-figh[j].pos.y) < tarsiz shr 1) and
                 (abs(shot[i].pos.z-figh[j].pos.z) < tarsiz shr 1) then
                begin
                  shot[i].on := false;

                  dec(figh[j].health,shotstr);

                  inc(explc);
                  if (explc > maxexpl) then explc := 1;

                  expl[explc].on := true;
                  expl[explc].life := 0;
                  if (figh[j].health > 0) then
                    begin
                      expl[explc].typ := 0;
                      expl[explc].pos := shot[i].pos;
                    end
                  else
                    begin
                      expl[explc].typ := 255;
                      expl[explc].pos := figh[j].pos;
                    end;
                end;
          end;
        inc(shot[i].life);
      end;
end;

function clip(pos: Tvector): boolean;
var
  x2d, y2d: integer;
begin
  if (pos.z > 5) then
    begin
      x2d := round(pos.x/pos.z*150)+(320 shr 1)-1;
      y2d := round(pos.y/pos.z*150)+(200 shr 1)-1;

      if not (x2d < 0) and (x2d < 320) and not (y2d < 0) and (y2d < 200) then clip := false
      else clip := true;
    end
  else clip := true;
end;

procedure drawtracer;
var
  x, y: integer;
begin
  x := round(tracer.x/tracer.z*150)+(320-1) shr 1;
  y := round(tracer.y/tracer.z*150)+(200-1) shr 1;
  screen^[(x+1)+y*320] := traco2;
  screen^[(x-1)+y*320] := traco2;
  screen^[x+(y-1)*320] := traco1;
end;

procedure drawtarget(pos: Tvector; typ: byte);
var
  x, y, size: integer;
begin
  if (pos.z > 5) then
    begin
      x := round(pos.x/pos.z*150)+(320-1) shr 1;
      y := round(pos.y/pos.z*150)+(200-1) shr 1;
      size := round((pos.x+tarsiz)/pos.z*150-pos.x/pos.z*150) shr 1;
      if (size < 2) then size := 2;
      if (x > size) and (x < 320-1-size) and (y > size) and (y < 200-1-size) then
        if (typ = 0) then
          begin
            screen^[(x-size)+(y-size+1)*320] := traco2;
            screen^[(x-size+1)+(y-size)*320] := traco2;
            screen^[(x-size)+(y-size)*320] := traco1;

            screen^[(x+size)+(y-size+1)*320] := traco2;
            screen^[(x+size-1)+(y-size)*320] := traco2;
            screen^[(x+size)+(y-size)*320] := traco1;

            screen^[(x-size)+(y+size-1)*320] := traco2;
            screen^[(x-size+1)+(y+size)*320] := traco2;
            screen^[(x-size)+(y+size)*320] := traco1;

            screen^[(x+size)+(y+size-1)*320] := traco2;
            screen^[(x+size-1)+(y+size)*320] := traco2;
            screen^[(x+size)+(y+size)*320] := traco1;
          end
        else
          begin
            screen^[(x-size)+(y-size+1)*320] := traco4;
            screen^[(x-size+1)+(y-size)*320] := traco4;
            screen^[(x-size)+(y-size)*320] := traco3;

            screen^[(x+size)+(y-size+1)*320] := traco4;
            screen^[(x+size-1)+(y-size)*320] := traco4;
            screen^[(x+size)+(y-size)*320] := traco3;

            screen^[(x-size)+(y+size-1)*320] := traco4;
            screen^[(x-size+1)+(y+size)*320] := traco4;
            screen^[(x-size)+(y+size)*320] := traco3;

            screen^[(x+size)+(y+size-1)*320] := traco4;
            screen^[(x+size-1)+(y+size)*320] := traco4;
            screen^[(x+size)+(y+size)*320] := traco3;
          end
    end;
end;

procedure drawexpl(texno: byte; size, life: integer; pos: Tvector);
var
  x0, y0, x1, y1: integer;
  i, j, u, v, adr, tadr: integer;
begin
  if (pos.z > 5) then
    begin
      x0 := round((pos.x-size shr 1)/pos.z*150)+(320-1) shr 1;
      y0 := round((pos.y-size shr 1)/pos.z*150)+(200-1) shr 1;
      x1 := round((pos.x+size shr 1)/pos.z*150)+(320-1) shr 1;
      y1 := round((pos.y+size shr 1)/pos.z*150)+(200-1) shr 1;
      for j := y0 to y1 do
        for i := x0 to x1 do
          if not (i < 0) and (i < 320) and not (j < 0) and (j < 200) then
            begin
              u := 0; v := 0;
              if (life > expllif shr 2) then begin u := texsize shr 1; v := 0; end;
              if (life > expllif shr 1) then begin u := 0; v := texsize shr 1; end;
              if (life > expllif shr 1+expllif shr 2) then begin u := texsize shr 1; v := texsize shr 1; end;
              u := u+(i-x0)*(texsize shr 1) div (x1-x0+1);
              if (u = texsize) then dec(u);
              v := v+(j-y0)*(texsize shr 1) div (y1-y0+1);
              if (v = texsize) then dec(v);
              tadr := u+v*texsize;
              adr := i+j*320;
              if ((pos.z < zbuff^[adr]) or (zbuff^[adr] = 0)) and (tex^[texno]^[tadr] <> 0) then
                begin
                  screen^[i+j*320] := tex^[texno]^[tadr];
                  if (pos.z < 256) then zbuff^[adr] := trunc(pos.z)
                  else zbuff^[adr] := 0;
                end;
            end;
    end;
end;

procedure drawstar(j: integer);
var
  x, y: integer;
begin
  temp.x := star[j].x*cos(-camang*pi/180)+star[j].z*sin(-camang*pi/180);
  temp.z := star[j].z*cos(-camang*pi/180)-star[j].x*sin(-camang*pi/180);
  temp.y := star[j].y;

  if (temp.z > 5) then
    begin
      x := round(temp.x/temp.z*150)+(320-1) shr 1;
      y := round(temp.y/temp.z*150)+(200-1) shr 1;
      if not (x < 0) and (x < 320) and not (y < 0) and (y < 200) then
        if (j < maxstars shr 1) then screen^[x+y*320] := starcol1
        else screen^[x+y*320] := starcol2;
    end;
end;

procedure setstars;
var
  ang, anx, i: integer;
begin
  for i := 1 to maxstars do
    begin
      ang := random(360);
      anx := -30+random(60);
      star[i].x := 25*cos(ang*pi/180)*cos(anx*pi/180);
      star[i].z := 25*sin(ang*pi/180)*cos(anx*pi/180);
      star[i].y := 25*sin(anx*pi/180);
    end;
end;

procedure settracer;
var
  r: single;
begin
  tracer.y := figh[1].pos.y+tradst*sin(figh[1].anx*pi/180);
  tracer.x := figh[1].pos.x+tradst*sin(figh[1].ang*pi/180)*cos(figh[1].anx*pi/180);
  tracer.z := figh[1].pos.z+tradst*cos(figh[1].ang*pi/180)*cos(figh[1].anx*pi/180);
  r := tracer.x;
  tracer.x := (r-cam.x)*cos(-camang*pi/180)+(tracer.z-cam.z)*sin(-camang*pi/180)+muldx*sin(dx/maxdx*pi/2);;
  tracer.z := (tracer.z-cam.z)*cos(-camang*pi/180)-(r-cam.x)*sin(-camang*pi/180);
  tracer.y := tracer.y-cam.y+muldy*sin(dy/maxdy*pi/2);
end;

procedure setcamera;
var
  i: integer;
begin
  cam.y := figh[1].pos.y-camhgh;
  cam.x := figh[1].pos.x-camdst*sin(camang*pi/180);
  cam.z := figh[1].pos.z-camdst*cos(camang*pi/180);
  if (figh[1].ang > camang) then camang := camang+anxspeed*0.5;
  if (figh[1].ang < camang) then camang := camang-anxspeed*0.5;
  if (figh[1].ang-camang < -camran) then camang := figh[1].ang+camran;
  if (figh[1].ang-camang > camran) then camang := figh[1].ang-camran;
end;

procedure setlight;
begin
  tlight.x := light.x*cos(-figh[1].ang*pi/180)+light.z*sin(-figh[1].ang*pi/180);
  tlight.z := light.z*cos(-figh[1].ang*pi/180)-light.x*sin(-figh[1].ang*pi/180);
  tlight.y := light.y;
end;

procedure setobject(var obj, out: Tvector);
begin
  out.x := (obj.x-cam.x)*cos(-camang*pi/180)+(obj.z-cam.z)*sin(-camang*pi/180)+muldx*sin(dx/maxdx*pi/2);;
  out.z := (obj.z-cam.z)*cos(-camang*pi/180)-(obj.x-cam.x)*sin(-camang*pi/180);
  out.y := obj.y-cam.y+muldy*sin(dy/maxdy*pi/2);;
end;

procedure drawdust(j: integer);
var
  x, y: integer;
  r: single;
begin
  if (dust[j].x-cam.x > randust) then dust[j].x := dust[j].x-2*randust;
  if (dust[j].x-cam.x < -randust) then dust[j].x := dust[j].x+2*randust;
  if (dust[j].y-cam.y > randust) then dust[j].y := dust[j].y-2*randust;
  if (dust[j].y-cam.y < -randust) then dust[j].y := dust[j].y+2*randust;
  if (dust[j].z-cam.z > randust) then dust[j].z := dust[j].z-2*randust;
  if (dust[j].z-cam.z < -randust) then dust[j].z := dust[j].z+2*randust;

  setobject(dust[j],temp);
  if (temp.z > 5) then
    begin
      x := round(temp.x/temp.z*150)+(320-1) shr 1;
      y := round(temp.y/temp.z*150)+(200-1) shr 1;
      if not (x < 0) and (x < 320) and not (y < 0) and (y < 200) then
        begin
          if (temp.z < 1*randust/5) then screen^[x+y*320] := dustcol1
          else if (temp.z < 2*randust/5) then screen^[x+y*320] := dustcol2
          else if (temp.z < 3*randust/5) then screen^[x+y*320] := dustcol3
          else if (temp.z < 4*randust/5) then screen^[x+y*320] := dustcol4
          else if (temp.z < 5*randust/5) then screen^[x+y*320] := dustcol5;
        end;
    end;
end;

procedure setdust;
var
  i: integer;
begin
  for i := 1 to maxdust do
    begin
      dust[i].x := -randust+random(2*randust+1);
      dust[i].y := -randust+random(2*randust+1);
      dust[i].z := -randust+random(2*randust+1);
    end;
end;

procedure controlAI(j: byte);
var
  anglex, angley, dist, danz, dx, dz, dy: single;
  back: boolean;
  i: integer;
begin
  if (figh[j].health > 0) then
    begin

      if not (figh[j].target^.health > 0) then
        begin
          figh[j].target := nil;
          if (figh[j].typ = 0) then
            for i := 1 to eneteam do
              if (figh[plateam+i].health > 0) then figh[j].target := @figh[plateam+i];
          if (figh[j].typ <> 0) then
            for i := 1 to plateam do
              if (figh[i].health > 0) then figh[j].target := @figh[i];
        end;

      if (figh[j].target <> nil) then
        begin
          if (figh[j].target^.pos.z-figh[j].pos.z < 0) then back := true
          else back := false;

          dx := figh[j].pos.x-figh[j].target^.pos.x;
          dy := figh[j].pos.y-figh[j].target^.pos.y;
          dz := figh[j].pos.z-figh[j].target^.pos.z;

          if (dz = 0) then
            if (dx <> 0) then anglex := dx/abs(dx)*90
            else anglex := figh[j].ang
          else anglex := arctan(dx/dz)/pi*180;
          if back then anglex := anglex+180;
          anglex := anglex-figh[j].ang;
          while (anglex > 180) do anglex := anglex-360;
          while (anglex < -180) do anglex := anglex+360;
          danz := 2/maxdx*maxangle;
          if (anglex > AIshotran) then
            begin figh[j].ang := figh[j].ang+anxAIspeed; figh[j].anz := figh[j].anz-2*danz; end
          else if (anglex < 0) then
            begin figh[j].ang := figh[j].ang-anxAIspeed; figh[j].anz := figh[j].anz+2*danz; end
          else if (figh[j].anz > 0) then
            begin if not (figh[j].anz-danz < 0) then figh[j].anz := figh[j].anz-danz; end
          else figh[j].anz := figh[j].anz+danz;
            begin if not (figh[j].anz+danz > 0) then figh[j].anz := figh[j].anz+danz; end;

          if (figh[j].anz > 2*maxangle) then figh[j].anz := 2*maxangle;
          if (figh[j].anz < -2*maxangle) then figh[j].anz := -2*maxangle;

          if (dz = 0) then angley := figh[j].anx
          else angley := arctan(dy/dz)/pi*180;
          if back then angley := -angley;
          angley := angley-figh[j].anx;
          while (angley > 180) do angley := angley-360;
          while (angley < -180) do angley := angley+360;
          if (abs(anglex) < AIshotran) then
            begin
              if (angley > AIshotran) then figh[j].anx := figh[j].anx+anyAIspeed
              else figh[j].anx := figh[j].anx-anyAIspeed;
            end
          else
            begin
              if (figh[j].anx > 0) then figh[j].anx := figh[j].anx-anyAIspeed
              else figh[j].anx := figh[j].anx+anyAIspeed;
            end;

          if (figh[j].anx > maxangle) then figh[j].anx := maxangle;
          if (figh[j].anx < -maxangle) then figh[j].anx := -maxangle;

          dist := sqrt(sqr(figh[j].target^.pos.x-figh[j].pos.x)+
                  sqr(figh[j].target^.pos.y-figh[j].pos.y)+
                  sqr(figh[j].target^.pos.z-figh[j].pos.z));
          if (dist > shotspd*shotlif) then figh[j].speed := figh[j].speed+AIacc
          else
            begin
              if (abs(anglex) < AIshotran) and (abs(angley) < AIshotran) then figh[j].speed := figh[j].speed-AIacc
              else figh[j].speed := figh[j].speed+AIacc;

              if (figh[j].shotint = AIshotint) then
                begin
                  if (abs(anglex) < AIshotran) and (abs(angley) < AIshotran) then
                    begin
                      inc(shotc);
                      if (shotc > maxshot) then shotc := 1;

                      figh[j].shotint := 0;

                      shot[shotc].on := true;
                      shot[shotc].life := 0;
                      shot[shotc].typ := figh[j].typ;
                      shot[shotc].speed := shotspd;
                      shot[shotc].pos.x := figh[j].pos.x+tarsiz*sin(figh[j].ang*pi/180)*cos(figh[j].anx*pi/180);
                      shot[shotc].pos.z := figh[j].pos.z+tarsiz*cos(figh[j].ang*pi/180)*cos(figh[j].anx*pi/180);
                      shot[shotc].pos.y := figh[j].pos.y+tarsiz*sin(figh[j].anx*pi/180);

                      shot[shotc].ang := figh[j].ang;
                      shot[shotc].anz := figh[j].anz;
                      shot[shotc].anx := figh[j].anx;
                    end;
                end
              else inc(figh[j].shotint);
            end;

          if (figh[j].speed > maxAIspeed) then figh[j].speed := maxAIspeed;
          if (figh[j].speed < minAIspeed) then figh[j].speed := minAIspeed;
        end
      else
        begin
          if (figh[j].anz < 0) then
            begin figh[j].ang := figh[j].ang+anxAIspeed; figh[j].anz := figh[j].anz-2/maxdx*2*maxangle; end
          else if (figh[j].anz > 0) then
            begin figh[j].ang := figh[j].ang-anxAIspeed; figh[j].anz := figh[j].anz+2/maxdx*2*maxangle; end;

          if (figh[j].anz > 2*maxangle) then figh[j].anz := 2*maxangle;
          if (figh[j].anz < -2*maxangle) then figh[j].anz := -2*maxangle;
        end;

      figh[j].pos.x := figh[j].pos.x+figh[j].speed*sin(pi/180*figh[j].ang)*cos(pi/180*figh[j].anx);
      figh[j].pos.z := figh[j].pos.z+figh[j].speed*cos(pi/180*figh[j].ang)*cos(pi/180*figh[j].anx);
      figh[j].pos.y := figh[j].pos.y+figh[j].speed*sin(pi/180*figh[j].anx);
    end;
end;

var
  i: integer;

begin
  getmem(screen,sizeof(byte)*64000);
  getmem(zbuff,sizeof(byte)*64000);

  getmem(tex,sizeof(pointer)*6);
  for i := 0 to 5 do
    getmem(tex^[i],sizeof(byte)*sqr(texsize));
  getmem(hmf,sizeof(integer)*6);
  getmem(obj,sizeof(pointer)*6);

  writeln('Loading files. Please wait...');
  loadpal('palette.act'); write('');
  loadobj('skybox.obj',0); write('');
  loadtex('skybox.raw',0); write('');
  loadobj('player.obj',1); write('');
  loadobj('play_low.obj',2); write('');
  loadtex('player.raw',1); write('');
  loadobj('enemy.obj',3); write('');
  loadobj('enem_low.obj',4); write('');
  loadtex('enemy.raw',2); write('');
  loadobj('shot.obj',5); write('');
  loadtex('shotb.raw',3); write('');
  loadtex('shotr.raw',4); write('');
  loadtex('expl.raw',5); write('');

  for i := 1 to plateam do
    begin
      figh[i].speed := minspeed;
      figh[i].pos.x := -200+random(400);
      figh[i].pos.y := -100+random(200);
      figh[i].pos.z := -700+random(400);
      figh[i].target := @figh[plateam+random(eneteam)+1];
      figh[i].health := 100;
      figh[i].typ := 0;
    end;

  for i := 1 to eneteam do
    begin
      figh[plateam+i].pos.x := -200+random(400);
      figh[plateam+i].pos.y := -100+random(200);
      figh[plateam+i].pos.z := 300+random(400);
      figh[plateam+i].target := @figh[random(plateam)+1];
      figh[plateam+i].ang := 180;
      figh[plateam+i].health := 100;
      figh[plateam+i].speed := minAIspeed;
      figh[plateam+i].typ := 255;
    end;

  setstars;
  setdust;

  setvga;
  setpal;
  setkeyboard;
  repeat
    fillchar(screen^,64000,0);
    fillchar(zbuff^,64000,0);

    setcamera;
    setlight;

    for i := 1 to maxstars do
      drawstar(i);

    for i := 1 to maxdust do
      drawdust(i);

    renderobject(0,0,0,0,0,-camang,0,0,false,tlight);
    fillchar(zbuff^,64000,0);

    for i := 1 to maxexpl do
      begin
        if expl[i].on then
          begin
            if (expl[i].life > expllif) then expl[i].on := false
            else
              begin
                setobject(expl[i].pos,temp);
                if not clip(temp) then
                  if (expl[i].typ = 0) then drawexpl(5,explmin,expl[i].life,temp)
                  else drawexpl(5,explmax,expl[i].life,temp);
              end;
            inc(expl[i].life);
          end;
      end;

    if (figh[1].health > 0) then
      begin
        setobject(figh[1].pos,temp);
        renderobject(1,1,temp.x,temp.y,temp.z,figh[1].ang-camang,figh[1].anx,figh[1].anz,true,tlight);
      end;

    for i := 1 to maxshot do
      if shot[i].on then
        begin
          setobject(shot[i].pos,temp);
          if not clip(temp) then
            if (shot[i].typ = 0) then
              renderobject(5,3,temp.x,temp.y,temp.z,shot[i].ang-camang,shot[i].anx,shot[i].anz,false,tlight)
            else
              renderobject(5,4,temp.x,temp.y,temp.z,shot[i].ang-camang,shot[i].anx,shot[i].anz,false,tlight)
        end;

    for i := 1 to eneteam do
      if (figh[plateam+i].health > 0) then
        begin
          setobject(figh[plateam+i].pos,temp);
          if not clip(temp) then
            if (temp.z < lodsw) then
              renderobject(3,2,temp.x,temp.y,temp.z,figh[plateam+i].ang-camang,
                           figh[plateam+i].anx,figh[plateam+i].anz,true,tlight)
            else
              renderobject(4,2,temp.x,temp.y,temp.z,figh[plateam+i].ang-camang,
                           figh[plateam+i].anx,figh[plateam+i].anz,true,tlight);
          drawtarget(temp,255);
        end;

    for i := 2 to plateam do
      if (figh[i].health > 0) then
        begin
          setobject(figh[i].pos,temp);
          if not clip(temp) then
            if (temp.z < lodsw) then
              renderobject(1,1,temp.x,temp.y,temp.z,figh[i].ang-camang,figh[i].anx,figh[i].anz,true,tlight)
            else
              renderobject(2,1,temp.x,temp.y,temp.z,figh[i].ang-camang,figh[i].anx,figh[i].anz,true,tlight);
          drawtarget(temp,0);
        end;

    if (figh[1].health > 0) then
      begin
        settracer;
        drawtracer;
      end;

    wait_f;
    move(screen^,ptr($A000,0)^,64000);

    for i := 2 to plateam+eneteam do
      controlAI(i);

    control;
  until keys[vk_esc];
  endkeyboard;
  endvga;

  for i := 5 downto 0 do
    freemem(obj^[i],sizeof(Tpolygon)*hmf^[i]);
  freemem(obj,sizeof(pointer)*6);
  freemem(hmf,sizeof(integer)*6);

  for i := 5 downto 0 do
    freemem(tex^[i],sizeof(byte)*sqr(texsize));
  freemem(tex,sizeof(pointer)*6);

  freemem(zbuff,sizeof(byte)*64000);
  freemem(screen,sizeof(byte)*64000);
end.