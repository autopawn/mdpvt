pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- camera angle in radians
cama = 0.0
-- camera cos(angle)
-- and sin(angle)
cosa = 1
sina = 0

-- radius in view space, given
-- the current camera angle
function viewrad(rx,ry,rz)
 xx = rx*cosa
 zz = rz*sina
 return sqrt(xx*xx + zz*zz),ry
end

-- position in view space.
function viewpos(x,y,z)
 vx = x*cosa-z*sina
 vz = x*sina+z*cosa
 return 64+vx, y, vz
end
 
function oval3d(x,y,z,rx,ry,rz,c)
 vx,vy,_ = viewpos(x,y,z)
 vrx,vry = viewrad(rx,ry,rz)
 ovalfill(vx-vrx+0.5,vy-vry+0.5,
   vx+vrx-0.5,vy+vry-0.5, c)
end

function cili3d(x,y,z,rx,ry,rz,c)
 vx,vy,_ = viewpos(x,y,z)
 vrx,vry = viewrad(rx,ry,rz)
 rectfill(vx-vrx+0.5,vy-vry+0.5,
   vx+vrx-0.5,vy+vry-0.5, c)
end

function _update()
 -- update camera
 cama += 0.01
 cosa = cos(cama)
 sina = sin(cama)
end

function draw_arm(s, front)
 oval3d(s*6,20,0,4,3,4,6)
 oval3d(s*11,21,0,4,3,4,6)
 oval3d(s*14,22,0,4,3,4,6)
 oval3d(s*17,24,0,4,4,4,7)
end

function draw_leg(s)
 if cosa<0 then
  oval3d(s*6,50,3,4,4,8,10)
 end
 oval3d(s*4,36,0,3,4,3,6)
 oval3d(s*5,40,1,3,4,3,6)
 oval3d(s*6,44,0,3,4,3,6)
 if cosa>=0 then
  oval3d(s*6,50,3,4,4,8,10)
 end
 cili3d(s*6,52,3,4,2,8,10)
 cili3d(s*6,54.5,3,4,0.4,8,9)
end

function draw_led(phi,y)
 px = cos(phi)*9
 pz = sin(phi)*9
 vx,vy,vz = viewpos(px,y,pz)
 if vz >= 0 then
  circfill(vx,vy,1,10)
 end
end

function draw_flask()
 cili3d(0,23,-17,2,4,2,5)
 cili3d(0,23,-17,2,3,2,10)
end

function draw_tail()
 if cosa<0 then
  draw_flask()
 end
 p = {
   30,-5,
   35,-9,
   35,-15,
   30,-19,
   16,-19}
 for i=1,7,2 do
  x1,y1 = viewpos(0,p[i],p[i+1])
  x2,y2 = viewpos(0,p[i+2],p[i+3])
  line(x1, y1, x2, y2, 13)
 end
 if cosa>=0 then
  draw_flask()
 end
end

function draw_eye(x)
 oval3d(x,10,7,1,2,1,9)
 oval3d(x,11,7,1,1,1,10)
end

function _draw()
 cls()
 camera(0,-10)
 
 side = sgn(sina)
 front = cosa>=0
 
 -- back arm
 draw_arm(-side)
 draw_leg(-side)
 
 if front then
  -- back tail
  draw_tail()
 end

 -- neck
 cili3d(0,16,0,3,2,3,9)
 
 -- body
 oval3d(0,25,0,6,7,5,6)
 oval3d(0,30,0,5,4,5,6)
  
 -- head
 oval3d(0,10,0,9,6,9,7)
 cili3d(0,9,0,9,3,9,6)
 if front then
  oval3d(0,10,18,9,4,9,0)
 end
 if cosa > 0.75 then
  oval3d(0,14,8,3,1,1,7)
  draw_eye(-3)
  draw_eye(3)
 end
 
 -- cap
 oval3d(0,7,6,9,1,9,5)
 oval3d(0,4,0,9,4,9,5)
 cili3d(0,5,0,9,3,9,5)
 
 -- lights
 for i=0,4 do
  draw_led(0.65+0.05*i,
    4-min(i%4,1))
 end
 
 if front then
  -- draw zipper
  oval3d(0,21,3,2,3,1,9)
  cili3d(0,23,4,2,3,1,9)
  cili3d(0,23,4,0.5,2,1,6)
 else
  -- front tail
  draw_tail()
 end
 -- front arm
 draw_arm(side)
 -- front leg
 draw_leg(side)
 
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
