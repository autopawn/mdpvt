pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main

frame = 0

function _init()
 for x=0,127 do
  for y=0,63 do
   t = mget(x,y)
   if t==16 then
    pla.x = 8*x
    pla.y = 8*y
    mset(x,y,0)
   elseif t==20 then
    create_worker(x*8,y*8)
    mset(x,y,0)
   end
  end
 end
end

function _update()
 player_update()
 workers_update()
 particles_update()
 -- update frame counter
 frame += 1
end

function _draw()
  cls()
  camera(pla.x-64+3, pla.y-64+8)
  
  map()

  workers_draw()
  particles_draw()

  player_draw()
  
  -- kill count
  camera()
  s = "kills: "..workers_dead
    .."/"..(#workers)
  print(s, 1, 2, 9)
  print(s, 1, 1, 10)
  -- speedrun clock
  if workers_dead<#workers then
   centis = flr(frame/30*100)
   s = centis\100
   c2 = (centis\10)%10
   c1 = centis%10
   time=s.."."..c1..c2.."s"
  end
  print(time,100,2,6)
  print(time,100,1,7)
  spr(3,92,1)
end


-->8
--physics
-- this tab is for object
-- movement and the collision 
-- system.

function step(z)
 if z > 1 then return 1 end
 if z < -1 then return -1 end
 return z
end

-- check whether the rectangle
-- is colliding with tiles
-- that have the given flag on
function rectcol(x, y, w, h, fl)
 -- note: backslash for integer
 -- division.
 xi = x\8
 xf = (x+w-1)\8
 yi = y\8
 yf = (y+h-1)\8
  
 for y=yi,yf do
  for x=xi,xf do
   -- get sprite at pos
   s = mget(x, y)
   -- get flag fl on the sprite
   f = fget(s, fl)
   -- if flag on, this counts.
   if f then return true end
  end
 end

 return false
end

--function for checking collisions of two objects
function objcol(o1, o2)
  if o1.x + o1.w <= o2.x then return false end
  if o2.x + o2.w <= o1.x then return false end
  if o1.y + o1.h <= o2.y then return false end
  if o2.y + o2.h <= o1.y then return false end
  return true
end

-- can the object move by
-- (dx, dy)?
function objcanmove(o, dx, dy)
 return not rectcol(o.x+dx,
   o.y+dy, o.w, o.h, 0)
end

-- apply gravity and terminal
-- velocity.
function objapplygravity(o)
  o.vy += 0.2
  if o.vy > 7 then
   o.vy = 7
  end
end

-- move object using its speed.
-- pixel-perfect.
-- as a bonus, set o.ground if
-- the object is touching the
-- ground.
function objmove(o)
  -- remaining movement
 rx = o.vx
 ry = o.vy
 
 while abs(rx)>0.1 or abs(ry)>0.1 do
  sx = step(rx)
  sy = step(ry)
  
  -- horizontal movement has
  -- preference.
  if abs(rx) > 0.01 then
   if objcanmove(o, sx, 0) then
    rx -= sx
    o.x += sx
   elseif abs(ry) > 0.01 and
     objcanmove(o, 0, sy) then
    ry -= sy
    o.y += sy
    o.ground = false
   else
    o.vx = 0
    rx = 0
   end
  else
   if objcanmove(o, 0, sy) then
    ry -= sy
    o.y += sy
    o.ground = false
   else
    o.vy = 0
    ry = 0
   	o.ground = (sy > 0)
   end
  end
 end
end

-- move object using its speed
-- fast computation
function objmovecheap(o)
 while not 
   objcanmove(o,o.vx,o.vy) do
  o.vx *= 0.5
  o.vy *= 0.5
  if abs(o.vx) < 0.1
    and abs(o.vy) < 0.1 then
   break
  end
 end
 o.x += o.vx
 o.y += o.vy
end
-->8
--player
-- this tab is for the player's
-- behavior.

pla = {
 x=64,
 y=64,
 vx=0,
 vy=0,
 animb=0, -- body animation
 animw=0, -- wing animation
 animkill = 0, -- kill animation
 w=8, -- width
 h=16, -- height
 facer=true, -- facing right?
 ground=false, -- touching ground
 dead=false, -- is dead?
 deadt=0, -- time dead.
}

function player_update()
 if pla.dead then
  -- increase dead time
  pla.deadt += 1
  -- reset the game
  if pla.deadt > 60 then
   run()
  end
  
 else
  -- update animation counters
  pla.animw -= 1
  pla.animkill -= 1
 
  -- react to controls
  if btn(0) and not btn(1) then
   pla.vx -= 1
   pla.animb += 1
   pla.facer = false
   if pla.ground then
    sfx(3)
   end
  end
  if btn(1) and not btn(0) then
   pla.vx += 1
   pla.animb += 1
   pla.facer = true
   if pla.ground then
    sfx(3)
   end
  end
  if not btn(0) and not btn(1) then
   pla.vx /= 4
  end
  if btnp(2) then
   pla.vy -= 3
   pla.animw = 7
  end

  -- limit horizontal speed
  if pla.vx > 4 then
   pla.vx = 4
  end
  if pla.vx < -4 then 
   pla.vx = -4
  end

  -- limit vertical speed
  if pla.vy < -4 then 
   pla.vy = -4
  end
  
  -- update body animation
  if not pla.ground then
   pla.animb = 0
  end
 end
 
 objapplygravity(pla)
 objmove(pla)
 
 -- die if touching death block
 if not pla.dead and
   rectcol(pla.x, pla.y, pla.w,
   pla.h, 1) then
  player_die()
 end
end

function player_die()
 sfx(0)
 pla.dead = true
 pla.vy -= 2
 pla.vx /= 2
 pla.h = 8
 add_explosion(
   pla.x+3,pla.y+9,{5,6,9,10})
end

function player_draw()
 fr = pla.facer

 if pla.dead then
  -- draw head
  spr(18, pla.x, pla.y,
	 		1, 1, fr)
 else
	 -- draw head
	 if pla.animkill > 0 then
	  headspr = 19
	 elseif frame % 60 < 4 then
	  headspr = 17 -- blink
	 else
	  headspr = 16
	 end
	 spr(headspr, pla.x, pla.y,
	 		1, 1, fr)
 
	 -- draw wings
	 if pla.animw >= 0 then
 	 spr(48+pla.animw/2,
 	   pla.x-6, pla.y+5, 1, 1, true)
 	 spr(48+pla.animw/2,
 	   pla.x+6, pla.y+5, 1, 1, false)
	 end
 
	 -- draw body
	 bodyspr = 32+pla.animb%4		
 	spr(bodyspr, pla.x, pla.y+8,
  	 1, 1, fr)
 end
end
-->8
--worker drones
--this tab is for declaring and
--adding worker drones

workers = {}
workers_dead = 0

function create_worker(x1, y1)
 local worker = {
  x = x1,
  vx = 0,
  y = y1,
  vy = 0,
  h = 16,
  w = 8,
  dead = false,
  facedir=rnd({-1,1})
 }
 add(workers, worker)
end

function worker_die(worker)
 sfx(2)
 worker.dead = true
 worker.vy -= 0.5
 worker.h = 8
 add_blood(
 worker.x+3, worker.y+9,
 {1, 5, 6})
 workers_dead += 1
end

function workers_update()
 for worker in all(workers) do
  if not worker.dead then
   if not pla.dead and
    objcol(pla, worker) then
    worker_die(worker)
    pla.animkill = 10
   end
  end
  if not worker.dead and
   objcanmove(worker,worker.facedir,0) and
   not objcanmove(worker, worker.facedir + worker.facedir*5, 1) then
   worker.vx=worker.facedir/2
  else
   worker.vx=0
   worker.facedir*=-1
  end
  objapplygravity(worker)
  objmove(worker)
 end
end

function workers_draw()
 for worker in all(workers) do
  if worker.dead then
   spr(21, worker.x, worker.y, 1, 1)
   spr(38, worker.x - 7, worker.y, 1, 1)
  else
   if worker.facedir == 1 then
    spr(20, worker.x, worker.y, 1, 1,true)
   else
    spr(20, worker.x, worker.y, 1, 1)
   end
   spr(36 + (frame\16)%2, worker.x, worker.y+8, 1, 1)
  end
 end
end

-->8
-- particles
-- this tab is for defining
-- the particle's behavior

particles={}

function add_blood(x,y,colors)
  amount = rnd(6)+10
  for i=1,amount do
    add(particles,{
      x=x,
      vx=rnd(4)-2,
      y=y,
      vy=-rnd(4),
      size=rnd(1)+1,
      w=1,
      h=1,
      color=rnd(colors),
      lifetime=rnd(60)+50,
    })
  end
end

function add_explosion(x,y,colors)
 for dx=-2,2 do
  for dy=-2,2 do
   if dy%2!=0 or dx%2!=0 then
    add(particles,{
      x=x+dx,
      vx=dx,
      y=y+dy,
      vy=dy,
      size=1,
      w=1,
      h=1,
      color=rnd(colors),
      lifetime=100,
    })
	  end
	 end
	end
end

function particles_update()
 for p in all(particles) do
  if p.lifetime < 0 then
   del(particles,p)
  end
  
  objapplygravity(p)
  objmovecheap(p)
  
  p.lifetime -= 1
 end
end

function particles_draw()
  for p in all(particles) do
    circfill(p.x,p.y,p.size,
      p.color)
  end
end
__gfx__
00000000166616668888888844444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555155518aaaaaa8ca66c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700661666168a5aa5a80cac0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000515551558a8aa8a800a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000166616668aaaaaa80c6c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007005551555185a55a58c6aac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000661666168858858844444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000515551558888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555500055555000555550005555500051511000515110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a5a55550a5a5555085855550a5a5555051511110515111100000000000000000000000000000000000000000000000000000000000000000000000000000000
55555a5555555a555555585555555a55111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
60000555600005556800855569009555600000116800801100000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a00660000006600880066009900660c0c00660088006600000000000000000000000000000000000000000000000000000000000000000000000000000000
790907767909977678008776790097767c0c07767800877600000000000000000000000000000000000000000000000000000000000000000000000000000000
07777776077777760777777607777d76077777760777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
007777000077770000777700007dd700007777000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099066000990a00009900066099000000600000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6669666600666690066666666669666600d6d00000d6d00000000000000000000000000000000000000000000000000000000000000000000000000000000000
666660a0006666000666606606666066011d1100011d110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006669000066aa000666090066660a0611111606111116000000000000000000000000000000000000000000000000000000000000000000000000000000000
006606aa00066aa00066aa00aa066690711111707111117005555500000000000000000000000000000000000000000000000000000000000000000000000000
006000aa00060aa00006aa00aa000660001110000011100001000051000000000000000000000000000000000000000000000000000000000000000000000000
aaa000aa0aaa000000aaaa00aa00aaa0055060000060550011005511000000000000000000000000000000000000000000000000000000000000000000000000
aaa000000aaa000000aaa0000000aaa0000055000550000001111111000000000000000000000000000000000000000000000000000000000000000000000000
00550000000500000000550000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00550000005560000055560000055600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05556000055666000556066000556660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55566000556606605506606655560600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05566000506060605660660606666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00660000006660000066060000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00660000000660000006000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000600000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000661666166616
0a0a0aaa0a000a0000aa000000000aaa000a0aa00aaa000000000000000000000000000000000000000000000000000000000000000000000000515551555155
0a0a09a90a000a000a9900a000000a9a00a909a00a9a000000000000000000000000000000000000000000000000000000000000000000000000000000001666
0aa900a00a000a000aaa009000000a0a00a000a00a0a000000000000000000000000000000000000000000000000000000000000000000000000000000005551
0a9a00a00a000a00099a00a000000a0a00a000a00a0a000000000000000000000000000000000000000000000000000000000000000000000000000000006616
0a0a0aaa0aaa0aaa0aa9009000000aaa0a900aaa0aaa000000000000000000000000000000000000000000000000000000000000000000000000000000005155
09090999099909990990000000000999090009990999000000000000000000000000000000000000000000000000000000000000000000000000000000001666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005551
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006616
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005155
16661666166616661666166616668888888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55515551555155515551555155518aaaaaa88aaaaaa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66166616661666166616661666168a5aa5a88a5aa5a8000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51555155515551555155515551558a8aa8a88a8aa8a8000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16661666166616661666166616668aaaaaa88aaaaaa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555155515551555155515551555185a55a5885a55a58000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66166616661666166616661666168858858888588588000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51555155515551555155515551558888888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000166616660000000000000000000000001666166616661666000000000000000000000000000000000000
00000000000000000000000000000000000000000000555155510000000000000000000000005551555155515551000000000000000000000000000000000000
00000000000000000000000000000000000000000000661666160000000000000000000000006616661666166616000000000000000000000000000000000000
00000000000000000000000000000000000000000000515551550000000000000000000000005155515551555155000000000000000000000000000000000000
00000000000000000000000000000000000000000000166616660000000000000000000000001666166616661666000000000000000000000000000000000000
00000000000000000000000000000000000000000000555155510000000000000000000000005551555155515551000000000000000000000000000000000000
00000000000000000000000000000000000000000000661666160000000000000000000000006616661666166616000000000000000000000000000000000000
00000000000000000000000000000000000000000000515551550000000000000000000000005155515551555155000000000000000000000000000000000000
00000000000000000000000000000515110000000000166616660000000000000000000000000000000016661666166616661666166600000000000000000000
00000000000000000000000000000515111100000000555155510000000000000000000000000000000055515551555155515551555100000000000000000000
00000000000000000000000000001111111100000000661666160000000000000000000000000000000066166616661666166616661600000000000000000000
00000000000000000000000000006000001100000000515551550000000000000000000000000000000051555155515551555155515500000000000000000000
00000000000000000000000000000c0c006600000000166616660000000000000000000000000000000016661666166616661666166600000000000000000000
00000000000000000000000000007c0c077600000000555155510000000000000000000000000000000055515551555155515551555100000000000000000000
00000000000000000000000000000777777600000000661666160000000000000000000000000000000066166616661666166616661600000000000000000000
00000000000000000000000000000077770000000000515551550000000000000000000000000000000051555155515551555155515500000000000000000000
00000000000000000000000000000006000016661666166616660000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000d6d00055515551555155510000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000011d110066166616661666160000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000006111116051555155515551550000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007111117016661666166616660000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000011100055515551555155510000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000060600066166616661666160000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000550550051555155515551550000000000000000000000000000000000000000000000000000000000000000000000000000
16661666166616661666166616661666166616661666000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55515551555155515551555155515551555155515551000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66166616661666166616661666166616661666166616000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51555155515551555155515551555155515551555155000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16661666166616661666166616661666166616661666000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55515551555155515551555155515551555155515551000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66166616661666166616661666166616661666166616000000000000000000055555000000000000000000000000000000000000000000000000000000000000
51555155515551555155515551555155515551555155000000000000000005555a5a000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000088888888888888880000000000000000055a5555500000000000000000000000051511000000000000000000000000000000
00000000000000000000000000008aaaaaa88aaaaaa8000000000000000005550000600000000000000000000000051511110000000000000000000000000000
00000000000000000000000000008a5aa5a88a5aa5a8000000000000000006600a0a000000000000000000000000111111110000000000000000000000000000
00000000000000000000000000008a8aa8a88a8aa8a8000000000000055006770909700550000000000000000000600000110000000000000000000000000000
00000000000000000000000000008aaaaaa88aaaaaa80000000000000655067777770055600000000000000000000c0c00660000000000000000000000000000
000000000000000000000000000085a55a5885a55a580000000000006665500777700556660000000000000000007c0c07760000000000000000000000000000
00000000000000000000000000008858858888588588000000000000060656609905556060000000000000000000077777760000000000000000000000000000
00000000000000000000000000008888888888888888000000000000006666666966666600000000000000000000007777000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000660a06666666000000000000000000000000600000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000060096660000600000000000000000000000d6d0000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000aa60660000000000000000000000000011d11000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000aa00060000000000000000000000000611111600000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000aa000aaa00000000000000000000000711111700000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000aaa00000000000000000000000001110000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000016661666166616661666166616661666000000000515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000055515551555155515551555155515551000000000515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000066166616661666166616661666166616000000001111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000051555155515551555155515551555155000000006000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000016661666166616661666166616661666000000000c0c
00000000000000000000000000000000000000000000000000000000000000000000000000000000000055515551555155515551555155515551000000007c0c
00000000000000000000000000000000000000000000000000000000000000000000000000000000000066166616661666166616661666166616000000000777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000051555155515551555155515551555155000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011d
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000550
88880000000000000000166616661666166600000000000000000000000000000000000000000000000000000000000000000000000000000000166616661666
aaa80000000000000000555155515551555100000000000000000000000000000000000000000000000000000000000000000000000000000000555155515551
a5a80000000000000000661666166616661600000000000000000000000000000000000000000000000000000000000000000000000000000000661666166616
a8a80000000000000000515551555155515500000000000000000000000000000000000000000000000000000000000000000000000000000000515551555155
aaa80000000000000000166616661666166600000000000000000000000000000000000000000000000000000000000000000000000000000000166616661666
5a580000000000000000555155515551555100000000000000000000000000000000000000000000000000000000000000000000000000000000555155515551
85880000000000000000661666166616661600000000000000000000000000000000000000000000000000000000000000000000000000000000661666166616
88880000000000000000515551555155515500000000000000000000000000000000000000000000000000000000000000000000000000000000515551555155
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051511000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051511110000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000110000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c00660000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007c0c07760000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777760000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6d0000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011d11000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000611111600000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711111700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055000000000000000000000000000000
00000000000000000000166616661666166688888888888888881666166616661666000000001666166616661666166616661666166616661666000000000000
0000000000000000000055515551555155518aaaaaa88aaaaaa85551555155515551000000005551555155515551555155515551555155515551000000000000
0000000000000000000066166616661666168a5aa5a88a5aa5a86616661666166616000000006616661666166616661666166616661666166616000000000000
0000000000000000000051555155515551558a8aa8a88a8aa8a85155515551555155000000005155515551555155515551555155515551555155000000000000
0000000000000000000016661666166616668aaaaaa88aaaaaa81666166616661666000000001666166616661666166616661666166616661666000000000000
00000000000000000000555155515551555185a55a5885a55a585551555155515551000000005551555155515551555155515551555155515551000000000000
00000000000000000000661666166616661688588588885885886616661666166616000000006616661666166616661666166616661666166616000000000000
00000000000000000000515551555155515588888888888888885155515551555155000000005155515551555155515551555155515551555155000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010100000101010100010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000101010100000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000010101000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000100000000000000000000000000000000101000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000001010001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000001010101010102020000000000000000000000010000020100000000000000000000000101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000201010000000000000000010100000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000014000100000001010000000014000000000000010101010102020101010000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000100000000010101000000000000140000000001000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000010100000000000000000000000000000000000000000000000000000001010000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100010101010101010101010000000000001400000000000001010101010000000000000001010001010000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000002020000000000000000000000000000000000000000000000000101000000010000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000010101010000000000000000000000000000000000000000020000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000010101010100000000000000020000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000001020200000101000000000000000000000101010200000000000000000000000000000001010000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000001400000000000000000000000000000000000000010100000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010000000101020201010001010101010000000000000000000000000001010100000000010201000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010000000000000000000000000000000000000000000001010202020101000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000010101000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000001010000000000000000010101010101020201010000000000000000000014000000010201000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000001010000000000000001010000000014000000000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000101010101020201010101000000000000000000000000000001010000000000000000000000000101000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000202020202000000000001010000000000000000000000000101010000000000010100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000000000000000000000000000000000002010000000202000000000000000000000000000001010000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000000000000000000000000000000000002010000000000000000000101010000000000000101000000140100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000000000000000000000000000000000000000000000000000000000000000000000001010100000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001010101010101010100000000000000000000000000000000001400001400000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000101010202020202000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000010101010101010101010101010101010000000001010101010101010101010101020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000000000665006620096200c6501c0201d1201c1201d120116201d120290501e1501e0401e140200501e17036670366703567034670346703467033650146501d650296502465000000000000000000000
001000000000000000100501205014050160501b0501f0502305026050290502b0502c050290501c050130501105014050190501b0501d0501e050210501f050180501205013050190501b050000000000000000
00030000306702d6602a65029650266402464022630206301e6301b6201962017620156101460012600106000f6000d6000c6000b600000000000000000000000000000000000000000000000000000000000000
00040000266100b6100b6101f6001f6001d6001c6001a60013600116000e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344

