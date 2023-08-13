pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- main

-- current level.
-- stored on dget(1)
level = 1

-- this level dialog was shown?
-- stored on dget(2)
dialog_shown = 0

-- time on the clock, minutes
-- and frames.
-- stored on dget(3) and dget(4)
timer_m = 0
timer_f = 0

-- death counter tally (player)
-- stored on dget(5)
deathcount = 0

-- frame for animations
frame = 0

-- if this level had a player
-- sprite somewhere
level_has_player = false

-- level on which the player
-- gets the rockets
first_rocket_level = 4

-- music track currently playing
music_playing = -1

-- frames of input transition.
black = 9

function _init()
 -- set the cart data.
 cartdata("murder_drones_mdpvt")

 -- check if we should load checkpoint
 state = dget(0)
 if state == 1 then
  level = dget(1)
  dialog_shown = dget(2)
  timer_m = dget(3)
  timer_f = dget(4)
  deathcount = dget(5)
  -- by default, don't load
  -- checkpoint on next reset
  dset(0, 0)
 end

 -- enable objects of the
 -- current level
 for x = 0,127 do
  for y=0,63 do
   t = mget(x,y)

   -- look at the tile under
   -- for a level marker
   levelmark = -1
   if 64 <= mget(x,y+1) and
     mget(x,y+1) <= 74 then
    levelmark = mget(x,y+1)-63
    mset(x,y+1,0)
   end

   if t==16 then
    if levelmark == level then
     pla.x = 8*x
     pla.y = 8*y
     level_has_player = true
    end
    mset(x,y,0)
   elseif t==20 or t==23 or
     t==24 or t==25 or t==26 or
     t==43 then
    if levelmark == level then
     create_worker(x*8,y*8,t)
    end
    mset(x,y,0)
   else
    -- non-object tile with a
    -- level marker gets either
    -- deleted or duplicated
    if levelmark != -1 then
     if levelmark == level then
      mset(x,y+1,t)
     else
      mset(x,y,0)
     end
    end
   end
   
   -- turn direction switchers
   -- into their invisible
   -- variant
   if t == 6 then
    mset(x,y,7)
   end
  end
 end

 if dialog_shown == 0 then
  dialog_start(level)
 end
end

function reset_level()
 dset(0, 1) -- load checkpoint
 dset(1, level) -- this level
 dset(2, 1) -- after the dialog
 dset(3, timer_m)
 dset(4, timer_f)
 dset(5, deathcount)

 run()
end

function next_level()
 dset(0, 1) -- load checkpoint
 dset(1, level+1) -- next level
 dset(2, 0) -- before the dialog
 dset(3, timer_m)
 dset(4, timer_f)
 dset(5, deathcount)

 run()
end

function play_music(track)
 if (track != music_playing) then
  music(track)
  music_playing = track
 end
end

function stop_music()
 music(-1)
 music_playing = -1
end

function _update()
 if dialog_on then
  dialog_update()
 elseif level_has_player then
  rockets_update()
  player_update()
  workers_update()
  particles_update()
  railshots_update()
  -- update music track
  -- (may make this depend on "level" later)
  play_music(0)
  -- update speedrun timer
  timer_f += 1
  if timer_f >= 1800 then
   timer_f = 0
   timer_m += 1
  end
 end
 
 decor_tiles_update()
 -- update frame counter
 frame += 1
 -- advance input animation
 if black > 0 then
  black -= 1
 end
end

function _draw()
 cls()
 camera(pla.x-64+3, pla.y-64+8)

 map()

 workers_draw()
 railshots_draw()
 player_draw()
 particles_draw()
 rockets_draw()

 -- start gui
 camera()

 if dialog_on then
  dialog_draw()
 end

 -- input transition
 if black >= 8 then
  fillp(0)
  rectfill(0, 0, 127, 127, 0)
 elseif black > 6 then
  fillp(0b0101000001010000.1)
  rectfill(0, 0, 127, 127, 0)
 elseif black > 4 then
  fillp(0b0101101001011010.1)
  rectfill(0, 0, 127, 127, 0)
 elseif black > 2 then
  fillp(0b1111101011111010.1)
  rectfill(0, 0, 127, 127, 0)
 end
 fillp(0)

 -- death counter
 d = "deaths:"..deathcount
 print(d, 1, 2, 9)
 print(d, 1, 1, 10)

 -- kill count
 if #workers > 0 then
  s = "kills:"..workers_dead
    .."/"..(#workers)
  print(s, 1, 9, 9)
  print(s, 1, 8, 10)
 end

 -- speedrun clock
 secs = timer_f\30
 centis = flr(timer_f%30*3.333)
 c1 = centis\10
 c2 = centis%10
 s1 = secs\10
 s2 = secs%10
 tstr = timer_m..":"..s1..s2
   .."."..c1..c2

 print(tstr,100,2,6)
 print(tstr,100,1,7)
 spr(3,92,1)

end

function decor_tiles_update()
 px = pla.x\8
 py = pla.y\8
 for x=px-8,px+8 do
  for y=py-8,py+8 do
   t = mget(x, y)
   -- cameras follow the player
   if 125<=t and t<=127 then
    if abs(px-x) < abs(py-y) then
     mset(x, y, 126)
    elseif px < x then
     mset(x, y, 125)
    else
     mset(x, y, 127)
    end
   end
   -- torches
   if t==123 or t==124 then
    mset(x, y, 123+frame%4\2)
   end
  end
 end
end
-->8
-- physics
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

-- check whether the rectangle
-- is totally inside tiles
-- that have the given flag on
function rectinside(x, y, w, h, fl)
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
   -- if flag off, this is false.
   if not f then return false end
  end
 end

 return true
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
function objcanmove(o, dx, dy, flag)
 return not rectcol(o.x+dx,
   o.y + dy, o.w, o.h, flag)
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
   if objcanmove(o, sx, 0, 0) then
    rx -= sx
    o.x += sx
   elseif abs(ry) > 0.01 and
     objcanmove(o, 0, sy, 0) then
    ry -= sy
    o.y += sy
    o.ground = false
   else
    o.vx = 0
    rx = 0
   end
  else
   if objcanmove(o, 0, sy, 0) then
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
 objcanmove(o, o.vx, o.vy, 0) do
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

-- is the point inside a circle?
function inside(x, y, cx, cy, r)
  dx = cx - x
  dy = cy - y
  if abs(dx) > r or abs(dy) > r then
   return false
  end
  return dx*dx + dy*dy <= r*r
end

-- is the object inside a circle
function objinside(o,cx,cy,r)
 if o.h <= 8 then
  i1 = inside(
    o.x+o.w/2, o.y+o.h/2,
    cx, cy, r)
  return i1
 else
  i1 = inside(
    o.x+o.w/2, o.y+o.h*0.25,
    cx, cy, r)
  i2 = inside(
    o.x+o.w/2, o.y+o.h*0.75,
    cx, cy, r)
  return i1 or i2
 end
end

function inside_camera(x, y)
 dx = abs(x - pla.x)
 dy = abs(y - pla.y)
 return dx <= 86 and dy <= 86
end
-->8
-- player
-- this tab is for the player's
-- behavior.

pla = {
 x=-200,
 y=0,
 vx=0,
 vy=0,
 animb=0, -- body animation
 animw=0, -- wing animation
 animr=0, -- shooting animation
 animkill = 0, -- kill animation
 w=8, -- width
 h=16, -- height
 facer=true, -- facing right?
 ground=false, -- touching ground
 dead=false, -- is dead?
 deadt=0, -- time dead.
}

rockets = {}

function player_update()
 if pla.dead then
  -- increase dead time
  pla.deadt += 1

  -- reset the game from
  -- last checkpoint
  if pla.deadt > 40 then
   reset_level()
  end

 else
  -- update animation counters
  pla.animw -= 1
  pla.animkill -= 1
  pla.animr -= 1

  -- react to controls
  if btn(0) and not btn(1) then
   pla.vx -= 1
   -- limit horizontal speed
   if pla.vx < -3 then
    pla.vx = -3
   end
   pla.animb += 1
   pla.facer = false
   if pla.ground then
    sfx(3)
   end
  end
  if btn(1) and not btn(0) then
   pla.vx += 1
   -- limit horizontal speed
   if pla.vx > 3 then
    pla.vx = 3
   end
   pla.animb += 1
   pla.facer = true
   if pla.ground then
    sfx(3)
   end
  end
  if not btn(0) and not btn(1) then
   pla.vx /= 4
  end
  -- flutter flight
  if btnp(2) then
   pla.vy -= 3
   pla.animw = 7
   sfx(6 + tonum(pla.ground))
  end

  -- shoot
  if btnp(5) and #rockets==0
    and level >= first_rocket_level
    then
   player_shoot()
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

 -- die if touching death block
 if not pla.dead and
   rectcol(pla.x, pla.y, pla.w,
   pla.h, 1) then
  player_die()
 end

 -- go to next level
 if not pla.dead and
   workers_dead == #workers
   and rectinside(pla.x, pla.y,
   pla.w, pla.h, 2) then
  next_level()
 end

 objapplygravity(pla)
 objmove(pla)
end

function player_die()
 sfx(0)
 pla.dead = true
 pla.vy -= 2
 pla.vx /= 2
 pla.h = 8
 add_blood2(
   pla.x+3,pla.y+9,{5,6,9,10})
 deathcount+=1
end

function player_draw()
 fr = pla.facer

 rectfill(pla.x+1, pla.y+3,
   pla.x+6, pla.y+5, 0)
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
  if pla.animr > 0 then
   bodyspr = 52
  end
  spr(bodyspr, pla.x, pla.y+8,
    1, 1, fr)
 end
end

-- radious of the rocket explosion
rocket_xrad = 18

-- rockets_update function: handles the movement, collisions and explosions of rockets.
function rockets_update()
 -- cycle through each rocket
 for r in all(rockets) do
  -- if a rocket is exploding, continue to animate the explosion
  if r.explosiont > 0 then
   r.explosiont += 1
  -- if the explosion animation is over, remove the rocket
  if r.explosiont > 5 then
  del(rockets, r)
   end
  else
   -- check the rocket's ability to move and possible collisions, trigger explosion if required
   local explode = false
   objmove(r)
   -- check collision with thad
   for w in all(workers) do
    if not w.dead and 
      w.type == "thad" and
      objcol(r, w) then
     w.pipeanim=12
     sfx(11)
     deflect_rocket(r, w.facedir == 1)
    end
   end

   -- explode after enough time
   -- on a wall
   if abs(r.vx) < 1 then
    r.timeonwall += 1
   end
   if r.timeonwall > 15 then
    explode = true
   end

   -- check collision with player and whether the rocket was deflected
   if not pla.dead and
     objcol(r, pla) and
     r.deflected then
    explode = true
   end
   -- check for player input to explode the rocket
   if btnp(5) then
    explode = true
   end

   -- if explosion is needed, animate the explosion, kill player and workers in the blast radius
   if explode then
    sfx(10)
    sfx(9)
    r.explosiont = 1
    if not pla.dead and
      r.deflected and
      objinside(pla, r.x+3,
        r.y+1, rocket_xrad) then
     player_die()
    end
    for w in all(workers) do
     local front = ((r.x+3 < w.x+4)
       == (w.facedir == -1))
     if not w.dead and
       objinside(w, r.x+3,
         r.y+1, rocket_xrad) then
      if not (w.type=="thad" and front) then
       worker_die(w)
      end
     end
    end
   end
  end
 end
end

-- deflect_rocket function: Changes the direction of the rocket
function deflect_rocket(r, facer)
 if facer then
  r.vx = abs(r.vx)
 else
  r.vx = -abs(r.vx)
 end
 r.facer = facer
 r.deflected = true
end

-- rockets_draw function: Draw rockets, including explosion animations
function rockets_draw()
 for r in all(rockets) do
  if r.explosiont > 0 then
   add_explosion(r.x,r.y)
  else
   spr(11+frame%2,
     r.x-1, r.y-3, 1, 1,
     r.facer)
  end
 end
end

-- creates a rocket and makes 
-- the player character fire it
function player_shoot()
 local rocket = {
  x = pla.x,
  y = pla.y + 8,
  vx = 0,
  vy = 0,
  w = 6,
  h = 2,
  explosiont = 0,
  facer = pla.facer,
  deflected = false,
  timeonwall = 0
 }
 if pla.facer then
  rocket.x += 8
  rocket.vx = 4
 else
  rocket.x -= 6
  rocket.vx = -4
 end
 add(rockets, rocket)
 pla.animr = 6
end
-->8
-- worker drones
-- this tab is for declaring and
-- adding worker drones

workers = {}
workers_dead = 0

railshots={}

function create_worker(x1, y1, type)
 if type==23 then
  worker = {
   type = "uzi",
   x = x1,
   vx = 0,
   y = y1,
   vy = 0,
   h = 16,
   w = 8,
   dead = false,
   canmove = false,
   canflip = true,
   touchdeath = true,
   railgundelay = 0,
   sprite = 23,
   blood = {2,5,6},
   facedir = rnd({-1,1}),
   blink = rnd({8,9,10,11,12})
  }
 elseif type == 24 then
  worker = {
   type = "uzi",
   x = x1,
   vx = 0,
   y = y1,
   vy = 0,
   h = 16,
   w = 8,
   dead = false,
   canmove = false,
   canflip = false,
   touchdeath = true,
   railgundelay = 0,
   sprite = 23,
   blood = {2,5,6},
   facedir = -1,
   blink = rnd({8,9,10,11,12})
  }
 elseif type == 25 then
  worker = {
   type = "uzi",
   x = x1,
   vx = 0,
   y = y1,
   vy = 0,
   h = 16,
   w = 8,
   dead = false,
   canmove = false,
   canflip = false,
   touchdeath = true,
   railgundelay = 0,
   sprite = 23,
   blood = {2,5,6},
   facedir = 1,
   blink = rnd({8,9,10,11,12})
  }
 elseif type == 26 then
  worker = {
   type = "thad",
   x = x1,
   vx = 0,
   y = y1,
   vy = 0,
   h = 16,
   w = 8,
   dead = false,
   canmove = false,
   canflip = true,
   touchdeath = false,
   sprite = 26,
   pipeanim=0,
   blood = {8,5,6},
   facedir = 1,
   blink = rnd({8,9,10,11,12})
  }
 elseif type == 43 then
  worker = {
   type = "target",
   x = x1,
   vx = 0,
   y = y1,
   vy = 0,
   h = 8,
   w = 8,
   dead = false,
   canmove = false,
   canflip = false,
   touchdeath = false,
   sprite = 43,
   blood = {6, 7, 8},
   facedir = 0,
   blink = 0
  }
 else
  worker = {
   type = "normal",
   x = x1,
   vx = 0,
   y = y1,
   vy = 0,
   h = 16,
   w = 8,
   dead = false,
   canmove = true,
   canflip = true,
   touchdeath = true,
   sprite = 20,
   blood = {1,5,6},
   facedir = rnd({-1,1}),
   blink = rnd({8,9,10,11,12})
  }
 end
 add(workers, worker)
end

function worker_die(worker)
 sfx(2)
 worker.dead = true
 worker.vy -= 0.5
 worker.vx = 0
 worker.h = 8
 add_blood(
   worker.x+3, worker.y+9,
   worker.blood)
 workers_dead += 1
 for railshot in all(railshots) do
  if railshot.owner==worker then
   del(railshots,railshot)
   sfx(4,-2)
  end
 end
end

function workers_update()
 for worker in all(workers) do
  if worker.type == "target" then
   goto worker_update_skip
  end
  if not worker.dead then
   if not pla.dead and
     objcol(pla, worker) and
     worker.touchdeath then
    worker_die(worker)
    pla.animkill = 10
   end
  if worker.canmove then
   if objcanmove(worker,
     worker.facedir, 0, 0) and
     objcanmove(worker,
       worker.facedir, 0, 1) and
     objcanmove(worker,
       worker.facedir, 0, 7) and
     not objcanmove(worker,
       worker.facedir * 6, 1) then
    worker.vx = 0.5*worker.facedir
   else
    if worker.canflip then
     change_direction(worker)
    end
   end
  end
  if worker.type=="uzi" then
   if worker.railgundelay==0 then
    worker_shoot(worker)
   end
   worker.railgundelay-=1
  end
   if worker.type == "thad" then
    if objcol(pla, worker) and
      pla.dead == false then
     sfx(11)
     worker.pipeanim=12
     pla.vx+=10*worker.facedir
     pla.vy-=2
    end
    if pla.x>worker.x then
     worker.facedir=1
    else
     worker.facedir=-1
    end
    worker.pipeanim-=1
   end
  end
  objapplygravity(worker)
  objmove(worker)
  ::worker_update_skip::
 end
end

function change_direction(worker)
 worker.vx=0
 worker.facedir*=-1
end

function workers_draw()
 for worker in all(workers) do
  if worker.type == "target" then
   if not worker.dead then
    spr(worker.sprite, worker.x, worker.y)
   end
   goto workers_draw_continue
  end
 
  rectfill(worker.x+1, worker.y+3,
    worker.x+6, worker.y+5, 0)
  if worker.dead then
   spr(worker.sprite+2, worker.x, worker.y, 1, 1)
   spr(worker.sprite+18, worker.x - 7, worker.y, 1, 1)
  else
   spr(worker.sprite+tonum((
     frame\4)%worker.blink==0),
     worker.x, worker.y,
     1, 1,worker.facedir == 1)
   if worker.canmove then
    spr(worker.sprite+16
      +(frame\16)%2, worker.x,
      worker.y+8, 1, 1)
    else
     spr(worker.sprite+16,
       worker.x, worker.y+8,
       1, 1)
   end
   if worker.type=="uzi" then
    spr(worker.sprite+17,
      worker.x+worker.facedir*3,
      worker.y+9,1,1,
      worker.facedir == 1)
   end
  if worker.type=="thad" then
   if worker.pipeanim>0 then
    spr(worker.sprite+32+worker.pipeanim/4,
      worker.x+worker.facedir*4,
      worker.y+7,1,1,
      worker.facedir == 1)
   else
   spr(worker.sprite+32,
    worker.x+worker.facedir*4,
    worker.y+7,1,1,
    worker.facedir == 1)
   end
  end
  end
  ::workers_draw_continue::
 end
end

function railshots_update()
 for railshot in all(railshots) do
  while(railshot.w < 160) do
   if objcanmove(railshot,
     railshot.facedir, 0, 0) then
    if railshot.facedir == -1 then
     railshot.x -= 1
    end
    railshot.w += 1
   else
    break
   end
  end
  if railshot.delay==30 then
   sfx(2)
   sfx(5)
   railshot.y-=2
   railshot.h=5
   railshot.color=11
  elseif railshot.delay==0 then
   if railshot.owner.canflip then
    change_direction(railshot.owner)
   end
   del(railshots,railshot)
  end
  if railshot.delay<30 then
   if objcol(pla,railshot)
     and not pla.dead then
    player_die()
   end
  end
  railshot.delay-=1
 end
end

function railshots_draw()
 for railshot in all(railshots) do
  rectfill(railshot.x,
    railshot.y,
    railshot.x+railshot.w-1,
    railshot.y+railshot.h-1,
    railshot.color)
 end
end

function worker_shoot(worker)
 worker.railgundelay = 90
 local railshot = {
  owner=worker,
  x = worker.x + 4 +worker.facedir*7 ,
  y = worker.y + 10,
  x2 = 1,
  w = 0,
  h = 1,
  facedir = worker.facedir,
  color=7,
  delay = 60
 }
 if inside_camera(worker.x, worker.y) then
  sfx(4)
 end
 add(railshots,railshot)
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
    type="blood",
    x=x,
    vx=rnd(4)-2,
    y=y,
    vy=-rnd(4),
    size=rnd(1)+1,
    w=1,
    h = 1,
    color=rnd(colors),
    gravity=true,
    lifetime=rnd(60)+50,
  })
 end
end

function add_blood2(x, y, colors)
 for dx=-2,2 do
  for dy=-2,2 do
   if dy%2!=0 or dx%2!=0 then
    add(particles,{
      type="blood",
      x=x+dx,
      vx=dx,
      y=y+dy,
      vy=dy,
      size=1,
      w=1,
      h=1,
      gravity=true,
      color=rnd(colors),
      lifetime=100,
    })
   end
  end
 end
end

function add_explosion(x, y)
 for i = 1, 1 do
  add(particles,{
   type="explosion",
   x=x+rnd(4)*rnd({-1,1}),
   vx=0,
   y=y+rnd(4)*rnd({-1,1}),
   vy=0,
   size=rnd({9,10,11,12}),
   endsize=rnd({1,2,3}),
   w=1,
   h=1,
   gravity=false,
   color={4,9,9,10,7},
   lifetime=24,
  })
 end
end

function particles_update()
 for p in all(particles) do
  if p.lifetime < 0 then
   del(particles,p)
  end

  if p.gravity then
   objapplygravity(p)
  end
  objmovecheap(p)

  if p.type == "explosion" then
   if p.endsize<p.size then
    p.size-=1
   else
    del(particles,p)
   end
  end

  p.lifetime -= 1
 end
end

function particles_draw()
  for p in all(particles) do
   if p.type == "explosion" then
    circfill(p.x,p.y,p.size,
      p.color[flr(p.size/2)])
    else
    circfill(p.x,p.y,p.size,
      p.color)
   end
  end
end
-->8
-- dialog texts

dialog_1 = {
 {-8, "∧ zzzZZZ... zzzZZZ... ∧"},
 {-8, "∧ zzzzzzZZZZZZ... ∧"},
 {98, "*beep*"},
 {98, "uh... where... who am i?"},
 {96, "it took you some time to"},
 {96, "wake up rookie."},
 {98, "who are you?"},
 {96, "i am your supervisor."},
 {96, "this is your training."},
 {96, "you have been reset, and"},
 {96, "retrofitted as a"},
 {96, "disassembly drone."},
 {98, "cool! what will i be"},
 {98, "disassembling?"},
 {96, "worker drones, mostly."},
 {98, "oh..."},
 {96, "let's try the wings."},
 {96, "move to the next area,"},
 {96, "and avoid the death-"},
 {96, "blocks."},
 {98, "what do you mean with..."},
 {96, "they will kill you."},
 {98, "kill me!?"},
 {96, "don't worry, it is just"},
 {96, "a simulation."},
 {96, "..."},
 {96, "the pain is very real"},
 {96, "though..."},
 {98, "*gulp*"},
}

dialog_2 = {
 {96, "excelent!"},
 {96, "now, i need you to murder"},
 {96, "all the drones in this"},
 {96, "area and then reach the"},
 {96, "goal."},
 {96, "just touch them and let"},
 {96, "your instinct do the rest."},
}

dialog_3 = {
 {98, "so..."},
 {98, "is there a reason why i"},
 {98, "must kill those worker"},
 {98, "drones?"},
 {96, "once you have completed"},
 {96, "your training, then maybe"},
 {96, "i'll give you an answer."},
 {98, "`kay."},
 {96, "worker drones may be"},
 {96, "unpredictably armed."},
 {96, "management instructed me"},
 {96, "to add angsty teenagers"},
 {96, "with railguns in this"},
 {96, "part, for some reason."},
 {98, "what is a railgun?"},
 {96, "kill 'em all, rookie!"},
}

dialog_demo = {
 {96, "this demo is now over,"},
 {96, "thank you for playing!"},
 {96, "here's a few more bonus"},
 {96, "tests while we finish"},
 {96, "your training regiment."},
}
-->8
-- dialog system

-- the dialogs should be
-- in this array:
dialogs = {
  dialog_1,
  dialog_2,
  dialog_3,
  dialog_demo
}

-- current dialog
dialog_n = 1

-- current line in dialog
dialog_l = 1

-- current char in dialog
dialog_c = 0

-- is a dialog currently playing?
dialog_on = false

-- start next dialog
function dialog_start(n)
 dialog_n = n
 if n <= #dialogs then
  dialog_on = true
  music(7)
 end
end

-- update the current dialog
function dialog_update()
 current_dial = dialogs[dialog_n]
 if btnp(5) or btn(4) then
  dialog_l += 1
  dialog_c = 0
  if dialog_l > #current_dial then
   dialog_l = 1
   dialog_on = false
   frame = 0
  end
 elseif dialog_c <
   #current_dial[dialog_l][2] then
  dialog_c += 1
  sfx(13)
 end
end

-- draw the current dialog
function dialog_draw()
 if not dialog_on then
  return
 end

 current_dial = dialogs[dialog_n]
 line1 = current_dial[dialog_l]
 -- only show a substring
 text1 = sub(line1[2], 1, dialog_c)

 -- black background
 if line1[1] < 0 then
  cls(0)
 end

 rectfill(0,106,127,127,0)
 rect(1,107,18,124,7)
 rect(20,107,126,124,7)

 -- draw next icon
 print("❎",119,123, 2)
 print("❎",119,122+(frame\8)%2,
   8)

 -- draw two lines
 if dialog_l > 1 then
  line0 = current_dial[dialog_l-1]
  text0 = line0[2]
  if line0[1] == line1[1] then
   spr(line1[1],2,108,2,2)
   print(text0,22,109, 5)
   print(text1,22,117, 10)
   return
  end
 end

 -- draw a single line
 spr(line1[1],2,108,2,2)
 print(text1,22,109, 10)
end


__gfx__
00000000166616668888888844444000990099001066106000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555155518aaaaaa8ca66c000990099005051100100c00000000000000000000000000000000000000000005a0000005a000000000000000000000000
00700700661666168a5aa5a80cac000000990099661660160ccdddd00000000000000000000000000000000000000d9000000d9a000000000000000000000000
00077000515551558a8aa8a800a00000009900995105515500c000000000000000000000000000000000000007777d9a07777d90000000000000000000000000
00077000166616668aaaaaa80c6c0000990099000006166000000c000000000000000000000000000000000008667d9a08667d90000000000000000000000000
007007005551555185a55a58c6aac00099009900500155500ddddcc00000000000000000000000000000000000000d9000000d9a000000000000000000000000
00000000661666168858858844444000009900996610061000000c00000000000000000000000000001111000000005a0000005a000000000000000000000000
00000000515551558888888800000000009900990151006500000000000000000000000000000000055555500000000000000000000000000000000000000000
0555550005555500055555000555550005151100051511000515110002555550025555500255555008aa870008aa870008aa8700000000000000000000000000
0a5a55550a5a5555085855550a5a555505151111051511110515111102225555022255550222555508aa877708aa877708aa8777000000000000000000000000
55555a5555555a555555585555555a55111111111111111111111111222222252222222522222225999999779999997799999977000000000000000000000000
60000555600005556800855569009555600000116000001168008011600002226000022268008222600000996000009968008099000000000000000000000000
0a0a00660000006600880066009900660c0c006600000066008800660202002200000022008800220b0b00660000006600880066000000000000000000000000
790907767909977678008776790097767c0c077671011776780087767202072272022722780087227b0b07767303377678008776000000000000000000000000
07777776077777760777777607777d76077777760777777607777776077777720777777207777772077777760777777607777776000000000000000000000000
007777000077770000777700007dd700007777000077770000777700007777000077770000777700007777000077770000777700000000000000000000000000
00099066000990a0000990006609900000060000000600000000000000060000d222200000000000000600000088880000000000000000000000000000000000
6669666600666690066666666669666600d6d00000d6d0000000000000d6d0000bbb222d0000000000d6d0000877778000000000000000000000000000000000
660660a0006666000666606606666066011d1100011d11000000000005525500d222d11d000000000a8b8a008778877800000000000000000000000000000000
0006669000066aa000666090066660a0611111606111116000000000656565600000002d000000006a878a608787787800000000000000000000000000000000
006606aa00066aa00066aa00aa066690711111707111117005555500755655700000000006666600788788708787787806666600000000000000000000000000
006000aa00060aa00006aa00aa0006600011100000111000010000510065600000000000020000250088800087788778080000a8000000000000000000000000
aaa000aa0aaa000000aaaa00aa00aaa005506000006055001100551100202000000000002200665200606000087777808800778a000000000000000000000000
aaa000000aaa000000aaa0000000aaa0000055000550000001111111055055000000000002552222055055000088880008888888000000000000000000000000
00550000000500000000550000005500000990000000000000000000000000000000000000000000000000000007707700007700000000000000000000000000
005500000055600000555600000556007666660a00000000000000000000000000000000000000000dd000000077007000007007000000000000000000000000
0555600005566600055606600055666076666609000000000000000000000000000000000000000055dd00000770070000070077000000000000000000000000
55566000556606605506606655560600000666500000000000000000000000000000000000000000500dd0000dd0700700700770000000000000000000000000
055660005060606056606606066660000066666000000000000000000000000000000000000000000000dd0005ddd0770dd0dd00000000000000000000000000
0066000000666000006606000066000000660660000000000000000000000000000000000000000000005dd05500ddd0ddddd5dd000000000000000000000000
00660000000660000006000000060000aaa0aaa00000000000000000000000000000000000000000000000dd500005dd55000000000000000000000000000000
00600000000600000006000000000000aaa0aaa000000000000000000000000000000000000000000000000d0000000050000000000000000000000000000000
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f00000004000000020000000700000000000000000000500005111111553333335
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f00000004002200020077000700000000000770000006050005dd00dd55bb00bb5
08800080099900900aaa00a00b0b00b00ccc00c00ddd00d00eee00e00fff00f00444004000200020007000700770000077dd7700006050005111111553333335
0080008000090090000a00a00b0b00b00c0000c00d0000d0000e00e00f0f00f00404004002220020077700707dd7700700dd0077000600005dd00dd55bb00bb5
00800880099909900aaa0aa00bbb0bb00ccc0cc00ddd0dd0000e0ee00fff0ff00444044000000220000007700dd0077000dd0000000500005111111553333335
0080000009000000000a0000000b0000000c00000d0d0000000e00000f0f00000004000002220000077000000dd0000000dd0000006050005dd00dd55bb00bb5
08880000099900000aaa0000000b00000ccc00000ddd0000000e00000fff00000444000002020000007000005515551500dd0000006050005111111553333335
00000000000000000000000000000000000000000000000000000000000000000000000002220000077700005155515500dd0000000600005dd00dd55bb00bb5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000000500005555555559999995
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000005000a9a9a9a95aa00aa5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd770000005000a9a9a9a959999995
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000000dd007700060000090909095aa00aa5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000dd0000000500000909090959999995
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000dd000000005000a9a9a9a95aa00aa5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000dd000000000000a9a9a9a959999995
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700dd000000000000555555555aa00aa5
00200000000000000000000000000000000000000000000000000000000000000000000000000000000000001666166616661666166616660000000000000000
02820400000000000000005555500000000000000000000000000000000000000000000000000000000000005551555155515551555155510000000000000000
22284455555500000000555555555000000000000000000000000000000000000000000000000000000000001aaaaaaaaaaaaaaaaaaaa9910000000000000000
02244500aa0a5000000555aa5aa5aa0000000000000000000000000000000000000000000000000000000000111aaaaaaaaaaaaa999991110000000000000000
00445aa59956a500005aa5a95a95a950000000000000000000000000000000000000000000000000000000000011111111111111111111000000000000000000
04450a9555556500005a955555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005a0555555565000555551111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005a5555555550000555511111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05055555550005000555600000000600000000000000000000000000000000000000000000000000000000000090900000090900000666600006666000066660
05555555500005000066009900990600000000000000000000000000000000000000000000000000000000000009900000099000000060000000670000007777
0555550990099500006600aa00aa0600000000000000000000000000000000000000000000000000000000000099990000999900077780000000870000008777
0555000aa00aa550007770aa00aa0700000000000000000000000000000000000000000000000000000000000098990000998900077770000000770000000000
0555000aa00aa5500007777777777000000000000000000000000000000000000000000000000000000000000008800000088000000000000000770000000000
05557000077770000900077777770000000000000000000000000000000000000000000000000000000000000044450000444500000000000000000000000000
0555577777704444a900009999000000000000000000000000000000000000000000000000000000000000000004500000045000000000000000000000000000
0055506626004467a900055559500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101000000000000000000000000000101010101010101010101000000000000000000000000000100000
00000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10400000000000000000000000000000000000101010101000000000000000000000000000000000000000100000000000000000000000000000000000000000
00000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10400000000000000000000000000000000000001010101010000000000000000000000000000000000000100000000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10400000000100000000000000000000000000000010101010100000000000000000000000000000000000100000000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10400000003400000000000000000000000000000000101000101000000000000000000000000000000000100000000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10100000101010101010202000000000000000000000001000002010000000000000000000000010101010100000000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000000000000000000000000000002010100000000000000000101000e400101010000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000001000000010100000000041000000000000101010101010101010100000e400000010000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000008100000000001000000000101010000034000000410000000010000000000000000000e400000010100000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000034000000001010000000000000000000000000003400000000000000000000000000101000000000100000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10001010101010101010101000000000000041000000000000101010101000000000000000101000101000000000101000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000202000000000000034000000000000000000000000000000200010100000001000000000001000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000001010000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000001010101000000000000000000000000000000000000071002000000000000010101010101010101010101010101000
00000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000034002000000000000020100000d40000000000000000001010
10101010101010101000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000102020000010100000000000000000000010101020000000001010101010000000101010101000000000000020100000d40000000000000000000000
000000000000d400d410101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000007100000041000000000000000000000000000000000000101010000000000000000020100000d40000001010101000000000
000000000000d400d500000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000003400000034000000000000000000000000000000000010100000000000000000000010100000d40000000020202410000000
00000000000010100000000000f54010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000001000000010102020101000101010101000000000000000000000000000101010000000001020100000000010100041d40000000000000024101010
10100000000000001000000081f54010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000001000000000000000000000000000000000000000000000101020202010100000000000000000000000001010100024d45000000000000000100000
00005000000000000000000024f54010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000001010100000000000000000000000000000000000001010101010102000000000000000247100
00000020200000000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000101000000000000000001010101010102020101000000000000000000000410000001020100000001010101000000000000000000000002400
00410000000000000000000081100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000101000000000000000101000000000710000000000000000000000000000340000000000000000101050500000000000000020000000001000
00240000000000200000004124100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010000010101010102020101010100000000000340000000000000000101000000000000000000000000010340034240000000000002024000000102410
10100000000000201000002410100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10100000000000000000000020202020200000000000101000000000000000000000000010101000000000001034000050500000000050505050101010242424
24241010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000201000000020200000000000000000000000000000103400000034240000005000000000200000000000
000000000000d5100000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000201000000000000000000010101000000000000010340000004150509100000000000000000000000000
00000000000000240041000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000101034000000003434242400000000000000000000001010
10000000000000240024000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00101010101010101010000000000000000000000000000000000000000000000000007100000000000000000000001010100000c4b500000000000000000000
00000000000000241010100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010001010
000000000000000000101010202020202000000000000000000041000041000000000034000000000000000000000010101010101000c5b50000000000000041
00000020000000000000000001100000000000000000000000000000000000000000000000000000000000000000001010100010100010100000000000000000
0000000000000000000000101010101010101010101010101000340000340010101010101010101010101010202020101010101010101000c5c4b52020000024
00000024000000000000000024100000000000000000000000000010100010001000001000101010100000000010101000000000000000000000000000000000
00000000000000000000000000000000000000000000000010101010101010100000000000000000000000000000001010101010101010101010101010101010
10101010101010101010101010100010100010000000100000001000000000100000000000000000000010101010000000000000000000000000000000000000
__label__
00051555155515551555155515551555155515551550000000000000000000000000000000051555155515551555155515551555155515551555155515551555
0a0a6aaa6a616a6166aa666166616aa1666a6aaa6660000000000000000000000000000000016661666166616661444446617771666176717771666177717771
0a0a59a95a155a155a9955a5551559a555a95a9a5510000000000000000000000000000000055515551555155515ca66c5157675571575756675551576756675
0aa961a66a666a666aaa6196616661a661a66aaa61600000000000000000000000000000000661666166616661666cac61667176666677766776616677766776
0a9a15a51a551a55199a15a5155515a515a51a9a155000000000000000000000000000000005155515551555155515a515557575175566751675155566751675
0a0a0aaa0aaa0aaa0aa9009000000aaa0a900aaa00000000000000000000000000000000000000500000000000000c6c00007770060166717771676166717771
09090999099909990990000000000999090009990000000000000000000000000000000000000605000000000000c6aac0006660000555656665561555656665
000000000000000000000000000000000000060500000000000000000000000000000000000006050000000000004444400000000001aaaaaaaaaaaaaaaaaaaa
00000000000000000000000000000000000000600000000000000000000000000000000000000060000000000000000000000000000111aaaaaaaaaaaaa99999
00000000000000000000000000000000000000500000000000000000000000000000000000000050000000000000000000000000000001111111111111111111
00000000000000000000000000000000000006050000000000000000000000000000000000000605000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006050000000000000000000000000000000000000605000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000600000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000500000000000000000000000000000000000000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006050000000000000000000000000000000000000605000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006050000000000000000000000000000000000000605000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000600000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000500000000000000000000000000000000000000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006050000000000000000000000000000000000000605000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006050000000000000000000000000000000000000605000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000600000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000005151100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005151
00000000000000000000000005151111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005151
00000000000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111
00000000000000000000000060000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068008
0000000000000000000000000c0c0066000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555000880
0000000000000000000000007c0c0776000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000518008
00000000000000000000000007777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000110055117777
00000000000000000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111110777
00000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000016661666166616661666166616661
00000000000000000000000000d6d000000000000000000000000000000000000000000000000000000000000000000000055515551555155515551555155515
000000000000000000007700011d1100000077000000000000000000000000000000000000007700000077000000770000066166616661666166616661666166
00000000000000000007dd77611111670077dd77007000000000000000000000000000000007dd770077dd770077dd7700751555155515551555155515551555
00000000000000000000dd00711111707700dd00770000000000000000000000000000000000dd007700dd007700dd0077016661666166616661666166616661
00000000000000000000dd0000111d000000dd00000000000000000000000000000000000000dd000000dd000000dd0000055515551555155515551555155515
00000000000000000006616665566166616661666160000000000000000000000000000000066166616661666166616661666166616661666166616661666166
00000000000000000005155515555555155515551550000000000000000000000000000000051555155515551555155515551555155515551555155515551555
00000000000000000001666166616661666166616660000000000000000000000000000000016661666166616661666166616661666166616661666166616661
00000000000000000005551555155515551555155510000000000000000000000000000000055515551555155515551555155515551555155515551555155515
00000000000000000006616661666166616661666160000000000000000000000000000000066166616661666166616661666166616661666166616661666166
00000000000000000005155515551555155515551550000000000000000000000000000000051555155515551555155515551555155515551555155515551555
00000000000000000001666166616661666166616660000000000000000000000000000000016661666166616661666166616661666166616661666166616661
00000000000000000005551555155515551555155510000000000000000000000000000000055515551555155515551555155515551555155515551555155515
00000000000000000006616661666166616661666160000000000000000000000000000000066166616661666166616661666166616661666166616661666166
00000000000000000005155515551555155515551550000000000000000000000000000000051555155515551555155515551555155515551555155515551555
00000000000000000001666166616661666166616660000000000000000000000000000000016661666166616660005000016661666166616660005000016661
00000000000000000005551555155515551555155510000000000000000000000000000000055515551555155510060500055515551555155510060500055515
0000000000000000000661666166616661666166616000000000000000000000000000000006616661666166616006050001aaaaaaaaaaaa9910060500066166
000000000000000000051555155515551555155515500000000000000000000555550000000515551555155515500060000111aaaaa999991110006000051555
00000000000000000001666166616661666166616660000000000000000005555a5a000000016661666166616660005000000111111111111000005000016661
000000000000000000055515551555155515551555100000000000000000055a5555500000055515551555155510060500000000000000000000060500055515
00000000000000000006616661666166616661666160000000000000000005550000600000066166616661666160060500000000000000000000060500066166
00000000000000000005155515551555155515551550000000000000000006600a0a000000051555155515551550006000000000000000000000006000051555
00000000000000000001666166616661666166616660000000000000055006770909700550000000000000000000005000000000000000000000005000016661
00000000000000000005551555155515551555155510000000000000065506777777005560000000000000000000060500000000000000000000060500055515
00000000000000000006616661666166616661666160000000000000666550077770055666000000000000000000060500000000000000000000060500066166
00000000000000000005155515551555155515551550000000000000060656609905556060000000000000000000006000000000000000000000006000051555
00000000000000000001666166616661666166616660000000000000006666666966666600000000000000000000005000000000000000000000005000016661
00000000000000000005551555155515551555155510000000000000000660a06606666000000000000000000000060500000000000000000000060500055515
00000000000000000006616661666166616661666160000000000000000600966600006000000000000000000000060500000000000000000000060500066166
0000000000000000000515551555155515551555155000000000000000000aa60660000000000000000000000000006000000000000000000000006000051555
0000000000000000000166616661666166616661666000000000000000000aa00060000000000000000000000000005000000000000000000008888888816661
0000000000000000000555155515551555155515551000000000000000000aa000aaa00000000000000000000000060500000000000000000008aaaaaa855515
000000000000000000066166616661666166616661600000000000000000000000aaa00000000000000000000000060500000000000000000008a5aa5a866166
00000000000000000005155515551555155515551550000000000000000000000000000000000000000000000000006000000000000000000008a8aa8a851555
00000000000000000001666166616661666166616660000000000000000000000000000000000000000000000000005000000000000000000008aaaaaa816661
000000000000000000055515551555155515551555100000000000000000000000000000000000000000000000000605000000000000000000085a55a5855515
00000000000000000006616661666166616661666160000000000000000000000000000000000000000000000000060500000000000000000008858858866166
00000000000000000005155515551555155515551550000000000000000000000000000000000000000000000000006000000000000000000008888888851555
00000000000000000001666166616661666166616660000000000000000000000000000000000000000000000000005000000000000000000000000000016661
00000000000000000005551555155515551555155510000000000000000000000000000000000000000000000000060500000000000000000000000000055515
00000000000000000001aaaaaaaaaaaaaaaaaaaa9910000000000000000000000000000000000000000000000000060500000000000000000000000000066166
0000000000000000000111aaaaaaaaaaaaa999991110000000000000000000000000000000000000000000000000006000000000000000000000000000051555
00000000000000000000011111111111111111111000000000000000000000000000000000000000000000000000005000000000000000000000000000016661
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060500000000000000000000000000055515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060500000000000000000000000000066166
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000051555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888888800000515110000000000000016661
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008aaaaaa800000515111100000000000055515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008a5aa5a800001111111100000000000066166
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008a8aa8a800006000001100000000000051555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008aaaaaa800000c0c006600000000000016661
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085a55a5800007c0c077600000000000055515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008858858800000777777600000000000066166
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888888800000077770000000000000051555
15000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000016661
150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6d00000000000000055515
1110000000000000000000000000000000000000000077000000770000007700000077000000000000000000000000000000000011d110000000000000066166
00600000000000000000000000000000000000000007dd770077dd770077dd770077dd7700700000000000000000000000000006111116000000000000051555
0c000000000000000000000000000000000000000000dd007700dd007700dd007700dd0077000000000000000000000000000007111117000000000000016661
0c700000000000000000000000000000000000000000dd000000dd000000dd000000dd0000000000000000000000000000000000011100000000000000055515
77000000000000000000000000000000000000000006616661666166616661666166616661600000000000000000000000000000550600000000000000066166
70000000000000000000000000000000000000000005155515551555155515551555155515500000000000000000000000000000000550000000000000051555
00000000000000000000000000000000000000000001666166616661666166616661666166616661666166616661666166616661666166616661666166616661
00000770000007700000077000000770000007700005551555155515551555155515551555155515551555155515551555155515551555155515551555155515
10077dd770077dd770077dd770077dd770077dd77006616661666166616661666166616661666166616661666166616661666166616661666166616661666166
16700dd007700dd007700dd007700dd007700dd00775155515551555155515551555155515551555155515551555155515551555155515551555155515551555
17000dd000000dd000000dd000000dd000000dd00001666166616661666166616661666166616661666166616661666166616661666166616661666166616661
00000dd000000dd000000dd000000dd000000dd00005551555155515551555155515551555155515551555155515551555155515551555155515551555155515
00000dd000000dd000000dd000000dd000000dd00006616661666166616661666166616661666166616661666166616661666166616661666166616661666166
50000dd000000dd000000dd000000dd000000dd00005155515551555155515551555155515551555155515551555155515551555155515551555155515551555
66616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661
55155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515
61666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166
15551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555
66616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661
55155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515
61666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166
15551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001020004018080000080000000000004040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000101010101010101010101010101010101010101010101010101010101010101010101010101010100000001010101010101010101020201010101010101010101010101010101010101010101
010101010101010102007e00000000004d4d00004d4d4d00007e00004d5d0000004d4d0000007e00000000004d4d4d01000000000000000102026b6c6d006b6c6d4d4d01010101010101010101010101010101010101010101010100000001000000000000000000000000000001000000000000000000020000000000000002
01010101010101010200000000000000020200004d4d4d00000000004d0000000002020000000000000000004d4d5d0100000000000000010000000000000000004d0201010101010404040401010101010101010101010101010100000001000000000000000000000000000001000000000000000000020000000000000002
01010101010101010200000000000000020200004d4d4d00000000004d0000000002020000000000000000004d4d000100000000000000010000001400000014000200010101010104040404010101010101010101010101010101000000010000000000000000001a0000000001000000000000000000020000000000000002
0101010101010101020000000101000000000000020202000000000002000000000000000000010100000000020200010000000000000001000000410000004100000001010101015e5e5e5e01010101010101010101010101010100000001001000000000000000440000000000000000000002000014000000020000000002
6c6d00000101010102000000010100000000000000000000000000000202007c000000007c0001010000000002020001000000000000000100004c4c4c4c4c4c4c000001010101010000000001010101010101010101010101010100000001004400000000000001010100000000000000000002000044000000020000000001
00000000010101010000000001010000000000000000000000000000000200000000000000000101010100000000000100000000000000010000010101010101010000000000004d000000004d0000006b6c6d00000101010101010000000101010101010100004d004d00000000000101000001010101010101010000000001
00150000000004040000000001010000000000000000000000000001010501010101010101010101010100000000000100000000000000010000010101010101010000000000004d000000004d00000000000000000101010101010000000000000000000100004d00000000000000004d000001000000004d004d0000000001
002500000000040400000001010100004b4b4b4b0000004b4b4b4b0101010101010101010101010101010000000000010000000000000001001400004d0000004d00000000001400000000005d00000000001400000000004e010100000000000000000001000000000000000000000000000001000000004d00000000000001
01010100000004040000000101014b4b01010101020202010101010101014d4d4d4d4d4d4d4d4d0101010100000000010000000000000001004100004d0000004d00000000004100000000000000000000004100000010004e010100000000000000000002020202020202020202020202020201000200000000000000000001
0101010101010101010101010101010101010101050505010101010101014d4d4d4d4d4d4d4d4d01010101010100000100000000000000014b4b4b4b4d0000004d000000004b4b4b000000004b4b4b0101010101000041004e010100000000000000000000000000000000000000000001010101000000000000000000000001
010101010101010101004d4d00004d0000007e00000101010000010101010202020202020202020101010102020000010000000000000001010101010101010101000000000101010000000001010101010101010101010101010100000000000000000000000000000000000000000001040000000000000100000014000001
010101010101010100004d0000005d0000000000000101010000010101010000000000000000000000010100000000010000000000000001010101010101010101000000000101010000000001014d6b6d4d01010101010101010100000000000000000000000000000000000000000001040014000000000000000044000001
01000000000000000000000000000001010000000000000000000000000000000000000000000000007e00000000000100000000000000016b6c6c6d4d0000004d000000000101010000000000004d00004d01010101010101010100000000000000000000000000000000000000000001040044000000000000000101010001
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000001000000004d0000004d000000000101010000000000004d00000201010101010101010100000000000000000000000000000000000000000001010101010102020202010101010101
010000001400000000000000000000000000004c4c0000004c4c5b0000000000000000000000000000000000000000010000000000000001000000004d0000004d000000006b6c6d0000000000004d00000001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000
01000a0040000a0000007c0010007c0000000001010000000101005c4c4c02020202020202020201014c4c5b000002010000000000000001000014000202020202000000140000000000000000000200140001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010000000040000000000000010100000001010101010101010101010101010101010101005c4c02010000000000000001000041000202020202000000410000004b4b4b4b00000000410001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101014b4b01010101014b4b4b4b010102020201010101010101010101010101010101010101010101050100000000000000014c4c4c4c02020202024c4c4c4c4c4c4c0101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000001010101010505050505010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000002b00002b00002b00002b000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000049000049000049000049000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000010000002b00002b00002b00002b000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000100000049000049000049000049000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000100101a0000000000001a000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000100494900000000000049000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000000000665006620096200c6501c0201d1201c1201d120116201d120290501e1501e0401e140200501e17036670366703567034670346703467033650146501d650296502465000000000000000000000
041000000000200002100221202214022160221b0221f0222302226022290222b0222c022290221c022130221102214022190221b0221d0221e022210221f022180221202213022190221b022000020000200002
00030000306702d6602a65029650266402464022630206301e6301b6201962017620156101460012600106000f6000d6000c6000b600000000000000000000000000000000000000000000000000000000000000
00040000266100b6100b6101f6001f6001d6001c6001a60013600116000e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90040000005760257604576085760c57612576165761a5761d57622576275762e576355763a5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d576296062860626606216061f606
00020000371733517333173311732f1732e1732b17329173281732515323153211531f1531d1531a1531715314153111530f1530c153091530715305153021530015300103021030010300003000030000300003
a0040000126531365317653246572e657000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020400000563411630216502f6601e650356603f6653f667006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000f6700d6700b6700867006670046700367001660002650066500265006550025500655002550065500245006450024500635002350063500235006350023500635002350062500225006250022500625
000300002e6722e6622e6622c6522c6522a6522865225652216521f6421d6421b64218642166421463214632106320f6220e6220b6220a6220962207612056120461202602016020060200002000020000200002
0002000023210282102d2102f21028610276102561023610216101e6101c4101b4101941015410134100a51007510055100261000000000000000000000000000000000000000000000000000000000000000000
00050000135372a6323a5372363218137121310413102131021320213203107031070010700107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700107
04020000225341e5341d53216530225341e5341d53200700007040000400002000000000400004000020000000002000020000200002000020000200002000020000200002000020000200002000020000200002
081e0000225341e5341d53216530225341e5341d53216530225341e5341d53216530225341e5342453225530225321e5321d53216532225321e5321d53216532225321e5321d53216532225321e5322453225532
481e00000a1540a1500a1400a1400a1320a1300a1210a1200d1540d1400d1320d1210c1540c1400c1320c1210a1540a1500a1400a1400a1320a1300a1210a1200d1540d1400d1320d1210c1540c1400c1320c121
481e00000a1540a1530a1420a1410a1340a1330a1220a1210d1540d1430d1320d1210c1540c1430c1320c1210a1540a1530a1420a1410a1340a1330a1220a1210d1540d1430d1320d1210c1540c1430c1320c121
001e00000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c04300000000000000024615000000000000000
091e000018100181001810018100191001a1001a10000001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000011810018100181101813118161
091e00001a1511a1321a1211a1121c1421c1321d1421d13219151191321912119112161421514213142111420e1510e1320e1210e112101421013211142111320d1510d1310d1220d11208151081310812108112
111e00001a1511a1321a1211a1121c1421c1321d1421d13219151191321912119112161421514213142111420e1520e1321115211132101521013210122101120e1520e132111521315210152101321012210112
902800000a5500a5550a5400a5450a5300a5350a5200a5250d5500d5450d5300d5250c5500c5450c5300c5250a5500a5550a5400a5450a5300a5350a5200a5250d5500d5450d5300d5250c5500c5450c5300c525
5928000016755167351975519735187551873518725187151675516735197551b7551875518735187251871516755167351975519735187551873518725187151575515735157251571516755167351875519755
0128000011043000000000000000186150000000000000000c04300000000000c043186150000000000000000c043000000000000000186150000000000000000c04300000000000c04318615000000000018615
000400000d7000f700127000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
__music__
01 0e0f4344
00 0e101112
00 0e101113
00 0e101114
00 0e0f1144
02 410f4344
03 01424344
01 15424344
00 15164344
02 15161744

