pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- main

-- current level.
-- stored on dget(1)
level = 10

-- hard difficulty enabled?
-- (o or 1), stored on dget(6)
hard = 0

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

-- camera shake
camera_shake_x=0
camera_shake_y=0
camera_shake_time=0

function _init()
 -- set the cart data.
 cartdata("drones_mdpvt")

 -- check if we should load checkpoint
 if dget(0) == 1 then
  level = dget(1)
  dialog_shown = dget(2)
  timer_m = dget(3)
  timer_f = dget(4)
  deathcount = dget(5)
  hard = dget(6)
  
  -- by default, go to main menu
  -- on next load
  dset(0, 0)
 end
 
 -- on main menu
 if level == 0 then
  menu_init()
  goto init_end
 end

 -- enable objects of the
 -- current level
 for x = 0,127 do
  for y=0,63 do

   -- ambibalent death-blocks
   if mget(x,y)==3 then
    mset(x,y,1+hard)
   end

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
     t==29 or t==30 or t==43 or
     t==84 then
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
 
 ::init_end::
end

function reset_level()
 dset(0, 1)
 dset(1, level) -- this level
 dset(2, 1) -- after the dialog
 dset(3, timer_m)
 dset(4, timer_f)
 dset(5, deathcount)
 dset(6, hard)
 
 run()
end

function next_level()
 dset(0, 1)
 dset(1, level+1) -- next level
 dset(2, 0) -- before the dialog
 dset(3, timer_m)
 dset(4, timer_f)
 dset(5, deathcount)
 dset(6, hard)

 run()
end

function load_game()
 dset(0, 1)
 dset(2, 0) -- before the dialog

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
 if level==0 then
  menu_update()
 elseif dialog_on then
  dialog_update()
 elseif level_has_player then
  rockets_update()
  player_update()
  workers_update()
  particles_update()
  railshots_update()
  shake_update()
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
 -- use hiden palette
 pal(14,129,1)
 pal(15,1,1)

 if level==0 then
  menu_draw()
  goto draw_end
 end

 cls()
 camx=pla.x-64+3+camera_shake_x
 camy=pla.y-64+7+camera_shake_y

 -- draw background
 offx = (-camx\2)%16
 offy = (-camy\2)%16
 for tx=-1,8 do
  for ty=-1,8 do
   spr(88,
     offx+16*tx,
     offy+16*ty,
     2,2)
  end
 end

 camera(camx, camy)

 -- draw map
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
 spr(15,92,1)

 ::draw_end::
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
   -- fans
   if 121<=t and t<=124 then
    mset(x, y, 121+frame\3%4)
   end
   -- goal tiles
   if t==4 or t==9 or t==10 then
    if workers_dead == #workers then
     mset(x, y, 9 + frame%32\16)
    else
     mset(x, y, 4)
    end
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

-- apply gravity (no more than terminal velocity)
function objapplygravity(o)
 if o.vy < 7 then
  o.vy = min(o.vy + 0.2, 7)
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
   o.vx = 0
   o.vy = 0
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

function objmoveto(o,x,y,s)
 dx = (x - o.x)/4
 dy = (y - o.y)/4
 if abs(dx) < 128 and
   abs(dy) < 128 then
  p = sqrt(dx*dx + dy*dy)
  o.vx = s*dx/p
  o.vy = s*dy/p
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
  if btn(⬅️) and not btn(➡️) then
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
  if btn(➡️) and not btn(⬅️) then
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
  if not btn(⬅️) and not btn(➡️) then
   pla.vx /= 4
  end
  -- flutter flight
  if btnp(❎) then
   pla.vy -= 3
   pla.animw = 7
   sfx(6 + tonum(pla.ground))
  end

  -- shoot
  if btnp(🅾️) and #rockets==0
    and level >= first_rocket_level
    then
   player_shoot()
   sfx(12)
  end

  -- limit vertical speed
  if pla.vy < -4 and not pla.slam then
   pla.vy = -4
  end

  -- ground slam activate
  if not pla.ground then
   if btnp(⬇️) and
     not btnp(⬆️) and
     not pla.slam then
    sfx(8)
    pla.slam=true
   end
   pla.animb = 0
  end

  if pla.slam then
   if pla.ground then
    pla.slam=false
    if pre_vy<8 then
     sfx(63)
    elseif pre_vy>8 then
     sfx(62)
     add_blood(pla.x+4,pla.y+16,
       {1,5,6}, rnd(6)+12,
       rnd({30,35,40,45}))
     camera_thug_shake(2,4)
     local slamkillzone={
      x=pla.x-16,
      y=pla.y,
      w=32,
      h=16
     }
     for worker in all(workers) do
      if objcol(worker,slamkillzone) and not worker.dead then
       worker_hit(worker)
      end
     end
    end
   end
   pre_vy = pla.vy
   pla.vy = max(7, pla.vy+0.5)
   add_blood(pla.x+4,pla.y+16,
     {7}, 1 , 2 )
   pla.animw=7
   pla.animkill = 5
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
 if pla.dead then
  return
 end
 sfx(0)
 pla.dead = true
 pla.vy -= 2
 pla.vx /= 2
 pla.h = 8
 add_blood(
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
   if r.timeonwall == 1 then
    sfx(61)
   end
   -- explode if deflected
   if not pla.dead
     and r.deflected and
     ((r.x-1 < pla.x) == (r.vx<0))
     then
    explode = true
   end
   -- check for player input to explode the rocket
   if btnp(🅾️) and not r.deflected then
    explode = true
   end

   -- if explosion is needed, animate the explosion, kill player and workers in the blast radius
   if explode then
    sfx(9)
    camera_thug_shake(1,2)
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
       worker_hit(w)
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
   if r.deflected then
    pal(8,9)
    pal(7,8)
    pal(6,8)
   end
   if r.timeonwall > 0 then
    spr(13,
      r.x-1, r.y-3, 1, 1,
      r.facer)
   else
    spr(11+frame%2,
      r.x-1, r.y-3, 1, 1,
      r.facer)
   end
   pal(8,8)
   pal(7,7)
   pal(6,6)
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
 sfx(12)
end

-->8
-- worker drones
-- this tab is for declaring and
-- adding worker drones

workers = {}
workers_dead = 0

railshots={}

function create_worker(x1, y1, type)
 worker = {
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
  blood = {2,5,6},
  facedir = rnd({-1,1}),
  blink = rnd({8,9,10,11,12}),
  flying = false,
 }
 if type==23 or type == 24 or type == 25 then
  worker.type = "uzi"
  worker.railgundelay = 0
  worker.sprite = 23
  if type==24 then
   worker.canflip = false
   worker.facedir = -1
  elseif type==25 then
   worker.canflip = false
   worker.facedir = 1
  end
 elseif type == 26 then
  worker.type = "thad"
  worker.canflip = true
  worker.touchdeath = false
  worker.sprite = 26
  worker.pipeanim = 0
  worker.blood = {8,5,6}
  worker.facedir = 1
 elseif type == 84 then
  worker.type = "hunter"
  worker.touchdeath = false
  worker.sprite = 84
  worker.blood = {8,13,6}
  worker.facedir = 1
  worker.flying = true
 elseif type == 29 or type==30 then
  worker.type = "mech"
  worker.h = 24
  worker.canmove = type==30
  worker.touchdeath = false
  worker.sprite = 29
  worker.blood = {5,6,9,10,13}
  worker.facedir = 1
  worker.hp = 3+2*hard
  worker.animhit=0
  worker.hands = {
   {x=x1-7, y=y1+9, w=6, h=6,
    vx=0, vy=0},
   {x=x1+9, y=y1+9, w=6, h=6,
    vx=0, vy=0}
  }
  if type==30 then
   worker.hp=6+4*hard
   add(worker.blood, 8)
  end
 elseif type == 43 then
  worker.type = "target"
  worker.h = 8
  worker.canflip = false
  worker.touchdeath = false
  worker.sprite = 43
  worker.blood = {6, 7, 8}
  worker.facedir = 0
  worker.blink = 0
 else
  worker.type = "normal"
  worker.sprite = 20
  worker.blood = {1,5,6}
  worker.canmove = true
 end
 add(workers, worker)
end

function worker_hit(worker)
 if worker.hp and worker.hp>1 then
  worker.hp -= 1
  add_blood(
    worker.x+3, worker.y+9,
    worker.blood)
  worker.animhit=6
 else
  worker_die(worker)
 end
end

function worker_die(worker)
 sfx(2)
 worker.dead = true
 worker.vy -= 0.5
 worker.vx = 0
 worker.h -= 8
 worker.flying = false
 if not worker.type == "mech" then
  add_blood(
    worker.x+3, worker.y+9,
    worker.blood)
 else
  add_blood(
    worker.x+3, worker.y+9,
    worker.blood,rnd(6)+18)
 end
 workers_dead += 1
 for railshot in all(railshots) do
  if railshot.owner==worker then
   del(railshots,railshot)
   sfx(4,-2)
  end
 end
end

function mech_chainsaws(worker)
 chs = {}
 for h in all(worker.hands) do
  for p in all({0.25, 0.5, 0.75}) do
   ch={}
   ch.x=p*worker.x+(1-p)*h.x+1
   ch.y=p*(worker.y+8)+(1-p)*h.y+1
   ch.w=6
   ch.h=6
   add(chs, ch)
  end
 end
 return chs
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
    worker_hit(worker)
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
   elseif worker.type == "thad" then
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
   elseif worker.type=="hunter" then
   
    if pla.x>worker.x then
     worker.facedir=1
    else
     worker.facedir=-1
    end

    if frame%35 == 0 then
     objmoveto(worker,
       pla.x + rnd(90)-45,
       pla.y + rnd(40)-20,1)
    end
    worker.vy += 0.5*cos(frame*0.1)
   end
  end

  if worker.hands then
   if not worker.dead then
    fr = frame%120+1
    hand = nil
    ret = nil
    if fr<30 then
     hand = worker.hands[1]
     ret = {worker.x-7, worker.y+9}
    elseif fr==30 then
     hand = worker.hands[1]
    elseif 60<fr and fr<90 then
     hand = worker.hands[2]
     ret = {worker.x+9, worker.y+9}
    elseif fr==90 then
     hand = worker.hands[2]
    end
    if hand then
     if ret then
      hand.vx = 0
      hand.vy = 0
      hand.x = 0.8*hand.x+0.2*ret[1]
      hand.y = 0.8*hand.y+0.2*ret[2]
     else
      objmoveto(hand,
        pla.x, pla.y+4, 6)
      if worker.canmove then
       worker.vx += step(hand.vx)*0.75
       worker.vy += hand.vy*0.75
      end
     end
    end

    chs = mech_chainsaws(worker)
    for ch in all(chs) do
     if objcol(ch, pla) then
      player_die()
     end
    end
    if objcol(pla,worker.hands[1])
      or objcol(pla,worker.hands[2])
      then
     player_die()
    end
   else
    objapplygravity(
      worker.hands[1])
    objapplygravity(
      worker.hands[2])
   end
   objmove(worker.hands[1])
   objmove(worker.hands[2])
  end

  if not worker.flying then
   objapplygravity(worker)
  end
  objmove(worker)

  if worker.animhit
    and worker.animhit > 0 then
   worker.animhit -= 1
  end

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

  if worker.type == "mech" then

   if worker.animhit > 0 then
    pal(9,7)
    pal(10,7)
   elseif worker.canmove then
    pal(9,2)
    pal(10,8)
   end

   chs = mech_chainsaws(worker)
   for ch in all(chs) do
    spr(62+frame%2, ch.x-1, ch.y-1,
      1, 1, frame%4>=2,
      frame%4>=2)
   end

   rectfill(worker.x+1, worker.y+3,
     worker.x+6, worker.y+5, 0)
   if worker.dead then
    spr(worker.sprite+2,
      worker.x, worker.y, 1, 2)
   else
    if worker.animhit > 0 then
     spr(worker.sprite+2,
       worker.x, worker.y, 1, 1,
       worker.x < pla.x)
    else
     spr(worker.sprite+tonum((
       frame\4)%worker.blink==0),
       worker.x, worker.y, 1, 1,
       worker.x < pla.x)
    end
    spr(worker.sprite+16,
      worker.x, worker.y+8, 1, 2)
    if worker.hp<10 then
     print(worker.hp,
       worker.x+4,
       worker.y-8, 8)
    end
   end

   h = worker.hands
   spr(46, h[1].x-1, h[1].y-1,
     1, 1, h[1].x-1 < worker.x)
   spr(46, h[2].x-1, h[2].y-1,
     1, 1, h[2].x-1 < worker.x)

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
   if worker.type=="uzi" or 
     worker.type == "hunter" then
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
  -- reset palette
  pal(9,9)
  pal(10,10)
 end
end

function railshots_update()
 for railshot in all(railshots) do
  if railshot.delay==30 then
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
  if railshot.owner.dead then
   del(railshots,railshot)
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

function extend_railshot(r)
 a=1
 b=161
 while a+1 < b do
  c = (a+b)\2
  if r.facedir == -1 then
   col = rectcol(r.x-c, r.y,
     c, r.h, 0)
  else
   col = rectcol(r.x, r.y,
     c, r.h, 0)
  end
  if col then
   b = c
  else
   a = c
  end
 end

 if r.facedir == -1 then
  r.x = r.x-a
  r.w = a
 else
  r.w = a
 end
end

function worker_shoot(worker)
 worker.railgundelay = 150 - 60*hard
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
 extend_railshot(railshot)
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

function add_blood(x,y,colors,amountt,life)
 if not amountt then
  amount = rnd(6)+6
 else
  amount=amountt
 end
 if not life then
  lifetime = rnd(60)+25
 else
  lifetime = life
 end

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
    lifetime=lifetime,
   })
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

-- Camera does the thug shaker

function camera_thug_shake(strength, time)
 camera_shake_x = rnd(strength)
 camera_shake_y = rnd(strength)
 camera_shake_time = max(camera_shake_time, time)
end

function shake_update()
 if camera_shake_time<=0 then
  camera_shake_y=0
  camera_shake_x=0
 end
 if camera_shake_time > 0 then
  camera_shake_y=rnd({-2, -1, 1, 2})
  camera_shake_x=rnd({-2, -1, 1, 2})
  camera_shake_time-=1
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
 {96, "press ❎ to flutter."},
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
 {96, "excelent!",
   0, 2},
 {96, "try to be faster from now",
   2, 9999},
 {96, "on, rookie.",
   2, 9999},
 {96, "management is watching.",
   2, 9999},
 {96, "now, i need you to"},
 {96, "disassemble all the"},
 {96, "drones in this area and"},
 {96, "reach the goal."},
 {98, "i know it's my job and"},
 {98, "everything...but how do i"},
 {98, "do that exactly?"},
 {96, "simple! just get close and"},
 {96, "let your instincts handle"},
 {96, "the rest."},
}

dialog_3 = {
 {98, "so..."},
 {98, "is there a reason why i'm"},
 {98, "disassembling all these"},
 {98, "worker drones?"},
 {96, "once you have completed"},
 {96, "your training in time,"},
 {96, "then maybe i'll give you"},
 {96, "an answer."},
 {98, "`kay!"},
 {96, "worker drones may be"},
 {96, "unpredictably armed."},
 {96, "management instructed me"},
 {96, "to add angsty teenagers"},
 {96, "with railguns in this"},
 {96, "part, for some reason."},
 {98, "what is a railgun?"},
 {96, "kill 'em all, rookie!"},
}

dialog_4 = {
 {96, "...huh.",
   0, 1},
 {98, "did i mess up?",
   0, 1},
 {96, "no, nothing like that.",
   0, 1},
 {96, "been a while since a",
   0, 1},
 {96, "drone's done this",
   0, 1},
 {96, "well though.",
   0, 1},
 {96, "alright, next on the list"},
 {96, "is weapons."},
 {96, "you're doing good, but"},
 {96, "it's about time you start"},
 {96, "using some more weaponry.",
   0, 4},
 {96, "using your brain.",
   4, 9999},
 {98, "hey!",
   4, 9999},
 {96, "i've enabled your rocket"},
 {96, "launcher."},
 {96, "press 🅾️ to shoot."},
 {96, "also, you don't have to"},
 {96, "worry about ammo, but"},
 {96, "you do have to detonate"},
 {96, "them manually, pressing"},
 {96, "🅾️ a second time."},
 {96, "here's a few targets to"},
 {96, "practice on."},
 {96, "knock 'em dead, rookie!"},
}

dialog_5 = {
 {96, "having fun rookie?"},
 {98, "feels like there's a"},
 {98, "correct answer here, but"},
 {98, "yeah!"},
 {96, "correct answer! looks like"},
 {96, "there's no need for any"},
 {96, "behavior correction, good"},
 {96, "for you!"},
 {98, "...should i be worried?"},
 {96, "since you're having fun,"},
 {96, "no."},
 {98, "...cool!"},
 {96, "alright rookie, time to"},
 {96, "spice things up a bit."},
 {96, "not every drone is going"},
 {96, "to sit there and take it"},
 {96, "if they see something"},
 {96, "coming at them."},
 {96, "you might have to think"},
 {96, "outside the box for"},
 {96, "these drones."},
 {96, "hopefully that tip didn't",
   6, 9999},
 {96, "go over your head...",
   6, 9999},
 {96, "good luck!"},
}

dialog_6 = {
 {96, "since you seem to have "},
 {96, "your aiming down, time to"},
 {96, "see if you can still shoot"},
 {96, "when there's return fire"},
 {96, "added back into the mix."},
 {98, "does this mean more"},
 {98, "railguns?"},
 {96, "that and more!"},
 {96, "worker drones are designed"},
 {96, "to work together, so you"},
 {96, "may have to deal with"},
 {96, "teams that cover each"},
 {96, "other's weaknesses."},
 {96, "chin up though, if you're"},
 {96, "outnumbered, then it's "},
 {96, "almost a fair fight!"},
}

dialog_demo = {
 {96, "this demo is now over,"},
 {96, "thank you for playing!"},
 {96, "here's an epic boss fight"},
 {96, "for you while we finish"},
 {96, "up your training."},
 {96, "any feedback you leave"},
 {96, "would be appreciated."},
}
-->8
-- dialog system

-- the dialogs should be
-- in this array:
dialogs = {
 dialog_1,
 dialog_2,
 dialog_3,
 dialog_4,
 dialog_5,
 dialog_6,
 dialog_demo
}


-- current dialog
-- filtered by conditions.
current_dial = {}

-- current line in dialog
dialog_l = 1

-- current char in dialog
dialog_c = 0

-- is a dialog currently playing?
dialog_on = false

-- start next dialog
function dialog_start(n)
 if n <= #dialogs then
  current_dial = dialogs[n]
  filter_current_dial()
  dialog_on = true
  music(7)
 end
end

function filter_current_dial()
 dial2 = {}
 tm = timer_m+timer_f/1800
 for l in all(current_dial) do
  if ((not l[3]) or l[3]<=tm)
    and ((not l[4]) or tm<l[4])
    then
   add(dial2, l)
  end
 end
 current_dial = dial2
end

-- update the current dialog
function dialog_update()
 if btnp(❎) or btn(🅾️) then
  dialog_l += 1
  dialog_c = 0
  if dialog_l > #current_dial then
   dialog_l = 1
   dialog_on = false
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


-->8
-- main menu

-- selected option
menu_option = 0

function menu_init()
 -- level saved in the cart
 menu_saved_level = dget(1)
 -- difficulty saved in the cart
 menu_saved_hard = dget(6)
end

function menu_update()
 if btnp(⬇️) then
  menu_option += 1
 elseif btnp(⬆️) then
  menu_option -= 1
 end
 
 if menu_saved_level == 0 then
  menu_option = max(1, menu_option)
 else
  menu_option = max(0, menu_option)
 end
 menu_option = min(2, menu_option)
 
 if btnp(❎) then
  if menu_option == 0 then
  	load_game()
  elseif menu_option == 1 then
   hard = 0
   next_level()
  else
   hard = 1
   next_level()
  end
 end
end

function menu_draw()
 cls()
 print("m.d.p.", 50, 1)
 print("virtual training",
   32, 8)
 if menu_saved_level == 0 then
  print("continue",30,80,5)
 elseif menu_saved_hard == 1 then
  print("continue (hard)",30,80,7)
 else
  print("continue (easy)",30,80,7)
 end
 print("new game (easy)",30,90,7)
 print("new game (hard)",30,100,7)
 print("∧", 22, 80+10*menu_option, 9)
end
__gfx__
00000000166616668888888816661666550055001066106000000000000000001777177799009900008800880000000000000000d00000000000000044444000
00000000555155518aaaaaa85aaaaaa1550055005051100100c0000000000000ddd1ddd199009900008800880000005a0000005add00000000000000ca66c000
00700700661666168a5aa5a86a0aa0a600550055661660160ccdddd00000000077177717009900998800880000000d9000000d9a59d00000000000000cac0000
00077000515551558a8aa8a85a8aa8a5005500555105515500c0000000000000d1ddd1dd009900998800880007777d9a07777d9009d777700000000000a00000
00077000166616668aaaaaa81aaaaaa6550055000006166000000c000000000017771777990099000088008808667d9a08667d9009d76630000000000c6c0000
007007005551555185a55a5850a00a0155005500500155500ddddcc000000000ddd1ddd1990099000088008800000d9000000d9a59d0000000000000c6aac000
00000000661666168858858866066016005500556610061000000c00000000007717771700990099880088000000005a0000005a5d0000000000000044444000
0000000051555155888888885155515500550055015100650000000000000000d1ddd1dd00990099880088000000000000000000dd0000000000000000000000
0555550005555500055555000555550005151100051511000515110002555550025555500255555008aa870008aa870008aa870006da660006da660006da6600
0a5a55550a5a5555085855550a5a555505151111051511110515111102225555022255550222555508aa877708aa877708aa877706ad666606ad666606ad6666
55555a5555555a555555585555555a55111111111111111111111111222222252222222522222225999999779999997799999977cccccc66cccccc66cccccc66
60000555600005556800855569009555600000116000001168008011600002226000022268008222600000996000009968008099600000cc600000cc680080cc
0a0a00660000006600880066009900660c0c006600000066008800660202002200000022008800220b0b00660000006600880066060600660000006600880066
790907767909977678008776790097767c0c077671011776780087767202072272022722780087227b0b07767303377678008776760607767505577678008776
07777776077777760777777607777d76077777760777777607777776077777720777777207777772077777760777777607777776077777760777777607777776
007777000077770000777700007dd700007777000077770000777700007777000077770000777700007777000077770000777700907777099077770990777709
00099066000990a0000990006609900000060000000600000000000000060000d2222000000000000006000000888800000000009d5555d905555000905550d0
6669666600666690066666666669666600d6d00000d6d0000000000000d6d0000bbb222d0000000000d6d00008777780000000009dddddd95666655090ddd0d9
660660a0006666000666606606666066011d1100011d11000000000005525500d222d11d000000000a8b8a008778877800000000999999995666666590990099
0006669000066aa000666090066660a0611111606111116000000000656565600000002d000000006a878a60878778780000000009dddd90a756565009d00d90
006606aa00066aa00066aa00aa0666907111117071111170055555007556557000000000066666007887887087877878066666009d6777d9a65565659d0507d0
006000aa00060aa00006aa00aa0006600011100000111000010000510065600000000000020000250088800087788778080000a89d6667d9566666650d555509
aaa000aa0aaa000000aaaa00aa00aaa005506000006055001100551100202000000000002200665200606000087777808800778a9d6666d95666655000055009
aaa000000aaa000000aaa0000000aaa000005500055000000111111105505500000000000255222205505500008888000888888899dddd9905555000990dd099
00550000000500000000550000005500000990000000000000000000000000000000000000000000000000000007707700007700099999900066000000066000
005500000055600000555600000556007666660a00000000000000000000000000000000000000000dd000000077007000007007955555590099996000999900
0555600005566600055606600055666076666609000000000000000000000000000000000000000055dd00000770070000070077955555590956659669566596
55566000556606605506606655560600000666500000000000000000000000000000000000000000500dd0000dd0700700700770955005596960069069600696
055660005060606056606606066660000066666000000000000000000000000000000000000000000000dd0005ddd0770dd0dd00955005596960069009600690
0066000000666000006606000066000000660660000000000000000000000000000000000000000000005dd05500ddd0ddddd5dd955005590956659609566590
00660000000660000006000000060000aaa0aaa00000000000000000000000000000000000000000000000dd500005dd55000000a990099a0099996006999960
00600000000600000006000000000000aaa0aaa000000000000000000000000000000000000000000000000d0000000050000000aaa00aaa0066000000600600
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f00000004000000020000000700000000000000000000500005111111555555555
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f00000004002200020077000700000000000770000006050005dd00dd5d1d1d1d1
08800080099900900aaa00a00b0b00b00ccc00c00ddd00d00eee00e00fff00f00444004000200020007000700770000077dd77000060500051111115d1d1d1d1
0080008000090090000a00a00b0b00b00c0000c00d0000d0000e00e00f0f00f00404004002220020077700707dd7700700dd0077000600005dd00dd501010101
00800880099909900aaa0aa00bbb0bb00ccc0cc00ddd0dd0000e0ee00fff0ff00444044000000220000007700dd0077000dd0000000500005111111501010101
0080000009000000000a0000000b0000000c00000d0d0000000e00000f0f00000004000002220000077000000dd0000000dd0000006050005dd00dd5d1d1d1d1
08880000099900000aaa0000000b00000ccc00000ddd0000000e00000fff00000444000002020000007000005515551500dd00000060500051111115d1d1d1d1
00000000000000000000000000000000000000000000000000000000000000000000000002220000077700005155515500dd0000000600005dd00dd555555555
0000000000000000099009900000000008888800088888000888880000000000eef0feef0feeef0e000000000000000077000000000500000000000000000000
0000000000000000000aa000009009000ddd88880ddd88880ddd888800000000000000000eeeee00000000000000000000770000000050000000000000000000
0000000000000000099009900aa00aa0888888888888888888888888000000000feeef000eeeee00000000000000000000dd7700000050000000000000000000
00000000000000000000000000000000600000dd600000dd680080dd000000000eee00000eee0000000000007700000000dd0077000600000000000000000000
00000000000000007d7ddd7777777777080080dd000000dd008800dd000000000fee0fee0fee0fee000000000070000000dd0000000500000000000000000000
00000000000000007dddd7707777777078088ddd72022ddd78008ddd0000000000000eee00000eee000000000007000000dd0000000050000000000000000000
00000000000000000999900009999000d777ddddd777ddddd777dddd00000000ee0e0eeeee000eee000000000000770000dd0000000000000000000000000000
00000000000000005555a5005555950000777700007777000077770000000000ef0e0eee00000fee000000000000007700dd0000000000000000000000000000
0020000000000000000000000000000000565000000000000000000000000000000e0fee0fef0000000000000000000000000000000000000000000000000000
02820400000000000000005555500000085558000000000000000000000000000eee00000eee0eee000000000000000000000000000000000000000000000000
22284455555500000000555555555000689898670000000000000000000000000eeeee000eee0eef000000000000000000000000000000000000000000000000
02244500aa0a5000000555aa5aa5aa00788888800000000000000000000000000eeeee0000000000000000000000000000000000000000000000000000000000
00445aa59956a500005aa5a95a95a950008880000000000000000000000000000feeef0feeef0fee000000000000000000000000000000000000000000000000
04450a9555556500005a955555555550002020000000000000000000000000000000000eeeee0eee000000000000000000000000000000000000000000000000
005a055555556500055555111111111100505500000000000000000000000000eee0fe0feeef0eee000000000000000000000000000000000000000000000000
005a555555555000055551111111111000500000000000000000000000000000eee0ee000000000e000000000000000000000000000000000000000000000000
05055555550005000555600000000600000000000000000000000000000000000040400004444440044444400444444004444440000666600006666000066660
05555555500005000066009900990600000000000000000000000000000000000044440044555544445550444400004444000544000060000000670000007777
0555550990099500006600aa00aa0600000000000000000000000000000000000044b40040550004455500044500055440005554077780000000870000008777
0555000aa00aa550007770aa00aa0700000000000000000000000000000000000044440040044004405440044554455445044554077770000000770000000000
0555000aa00aa5500007777777777000000000000000000000000000000000000044440040044004400445044554455445544054000000000000770000000000
05557000077770000900077777770000000000000000000000000000000000000044440040005504400055544550005445550004000000000000000000000000
0555577777704444a900009999000000000000000000000000000000000000000000000044555544440555444400004444500044000000000000000000000000
0055506626004467a900055559500000000000000000000000000000000000000000000004444440044444400444444004444440000000000000000000000000
00000000000000000000000000000000000000000010b4b4b4b4d4000000d400000000b4b4b400000000b4b4b4101010101000001400140404000000101010b4
b4101010102020202020201010101010202020201010101010101010000000001010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010101010101010101010000000001010100000000010101010101010101010101010101010101010101010
10101010105050501010101010101010101010101010102010101010101000001010000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001010101010101010101000000000101010000000001010d4e700d41010101010101010101000d4d40000d4
0000d400000010101000000000d4d4000000d4d40000000020202010202000001010000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001000e70000d4000000d400000000101010000000000000d40000d4101010101010101010e700d4000097d5
0097d500000000000000000000202000000000d40000000000000010000000001010000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001000000000d4000000d400000000101010000000000000d400002010101010101010101000000000008700
00870000000000000000000000202000000000d400000000000000e7000000001010000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001000000000d4000000d40000000000e700000000000000d400000010101010101010101000000000000000
00000000000000000000000000000000000000200000000000000000000000001010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010000041002020202020000000410000000000000000002000410010101010101010101000000000000000
00000000c4c40000001010b500000000000020200000000000000000000000001010000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001000001400141414141400000014000000b4b4b4b400000000140010101010101010101000000000010000
000000001010000000101000c5c4c40000002000000000000000c4c4b50000301010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010c4c4c4c41414141414c4c4c4c4c4c4c41010101010101010101010101010101010101000000000040000
0000000010100000001010101010101010101010101010202020101000c5c4301010000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000101010101050505050501010101010101010101010101010101010101010101010101010b4b41010101010
b4b4b4b4101020202010101010101010101010101010101010101010101010501010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010101010505050505010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000000000000000000000001010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000000010100000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010100000
00000000100000001010000000000000000000001010000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000101000
00000000100000000000000000010000000000001010000000000000000010101000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000001000
00000000100000000000000000940000000000001000000000000000000000001000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000001010000000000000100000000000000000000000800000001000
00000000100000000000000000000000000000001000000000450000000000001010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000100000000000000000000080800000001000
00000000100000000000000000000000000000001000000000940000000000000010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000101000000000100000000000000080800000000000800000001010
00000000100045000000101010101010100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000080800000000000000000000010
00000010100094000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000001010100000001000000000000000000000000000e10000000000000010
00000010000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000001090900000001000010000000000000000000000640000000000000010
00000010000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000001090900000000000640000000000000000000000000000000000100010
00000010101010101000000000000000000000000000000010101010101010101000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000100010
00000000000000001010101010101010000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000010
00000000000000000000000000000000101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000010100000001010101000000000808000000000000000000000000010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101010101010101010101010101010101010
__label__
000000h55515551555155515551555155515551555155515500550h55hh55hh5500550h55hh55hh5551555155515551555155515551555155515551555155515
haa1haaa6aaa6aaa6a6a61aa61666aaa616661666166616hh551h55hh550h55hh551h55hh550h556616661666166444441667776616677667166616677767776
ha9aha991a9a19a91a5a1a9915a51a9a155515551555155hh55hh5500550055hh55hh55005500555155515551555ca66c5557675175567557555155576756675
ha0ahaa16aaa66a16aaa6aaa66916a6a666166616661666551055h155hh550h551055h155hh550h16661666166616cac66617671666167617771666176716771
0a0a0a955a9a55a55a9a599a55a55a1a5515551555155515500550055hh55005500550055hh5500555155515551555a555157575571557157675551575755675
1aaa1aaa6a6a61a66a6a6aa961966aaa6166616661666160155h1550h55hh550155h1550h55hh5566166616661666c6c61667776666677767776676677767776
h99909991959159519591995155519991555155515551550h5500550h5500550h5500550h5500555155515551555c6aac5556665155566656665165566656665
1hh01hh01h6666h01hh01hh01hh01hh01hh01hh01h501hh01hh01hh01hh01hh01hh01hh01hh01hh01h501hh01hh044444hh01hh01hh01hh01h6666h01hh01hh0
0a0ahaaa0a077a7000aahhh00aa0hhha0aaahhh00605hhh00000hhh00000hhh00000hhh00000hhh00605hhh00000hhh00000hhh00000hhh00006hhh00000hhh0
hahah9a9ha087a7hha99hhahh9a0hha9ha9ahhhhh605hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh6h5hhhhh000hhhhh0h0hhhhh000hhhh7778hhhhh000hhhh
1aa9hha00a001ahh1aaahh9000a01hah1aaahhh000601hhh10h0hhh000001hhh10h0hhh000001hhh1060hhh000001hhh10h0hhh000001hhh7777hhh000001hhh
0a9a1ha01a100a00099a1ha01ha000a00a9a1hh01h50000000h01hh01h10000000h01hh01h10000000501hh01h10000000h01hh01h10000000h01hh01h100000
haha0aaahaaahaaahaa90090haaaha90haaa0000h6h5hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0h6h50000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0
h9h9h999h999h999h99hh000h999h910h999h000h6h5hh10hhhhh000hhh0hh10hhhhh000hhh0hh10h6h5h000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10
hhhhh00000000000hhhhh00000000000hhhhh00000600000hhhhh00000000000hhhhh00000000000hh6hh00000000000hhhhh00000000000hhhhh00000000000
1hhh101hhh101hh01hhh101hhh101hh01hhh101hhh501hh01hhh101hhh101hh01hhh101hhh101hh01h5h101hhh101hh01hhh101hhh101hh01hhh101hhh101hh0
000000hhhhh0hhh0000000hhhhh0hhh0000000hhh6h5hhh0000000hhhhh0hhh0000000hhhhh0hhh0060500hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0
hh01h01hhh10hhhhhh01h01hhh10hhhhhh01h01hh615hhhhhh01h01hhh10hhhhhh01h01hhh10hhhhh605h01hhh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhh
hh0hh000000000hhhh0hh000000000hhhh0hh000006000hhhh0hh000000000hhhh0hh000000000hhhh6hh000000000hhhh0hh000000000hhhh0hh000000000hh
h101hh101hhh10hhh101hh101hhh10hhh101hh101h5h10hhh101hh101hhh10hhh101hh101hhh10hhh151hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hh
00000000hhhhh00000000000hhhhh00000000000h6h5h00000000000hhhhh00000000000hhhhh00006050000hhhhh00000000000hhhhh00000000000hhhhh000
1hhh1000hhhhh0001hhh1000hhhhh0001hhh1000h6h5h0001hhh1000hhhhh0001hhh1000hhhhh00016h51000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh000
hhh00000hhh00000hhh00000hhh00000hhh00000hh600000hhh00000hhh00000hhh00000hhh00000hh600000hhh00000hhh00000hhh00000hhh00000hhh00000
1hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01h501hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh0
0000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00005hhh00000hhh00000hhh00000hhh00000hhh00000hhh0
h0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h5hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhh
10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh1060hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh
00h01hh01h10000000h01hh01h10000000h01hh01h10000000h01hh01h10000000h01hh01h10000000501hh01h10000000h01hh01h10000000h01hh01h100000
hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0hhh50000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0
hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10
hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000
1hhh101hhh101hh01hhh101hhh101hh01h11515hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh0
000000hhhhh0hhh0000000hhhhh0hhh01111515hhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0
hh01h01hhh10hhhhhh01h01hhh10hhhh11111111hh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhh
hh0hh000000000hhhh0hh000000000hh11000006000000hhhh0hh000000000hhhh0hh000000000hhhh0hh000000000hhhh0hh000000000hhhh0hh000000000hh
h101hh101hhh10hhh101hh101hhh10hh6600c0c01hhh10hhh101hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hh
00000000hhhhh00000000000hhhhh0006770c0c7hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh000
1hhh1000hhhhh0001hhh1000hhhhh00067777770hhhhh0001hhh1000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh001
hhh00000hhh00000hhh00000hhh00000hh777700hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000
1hh01hh01hh01hh01hh01hh01hh01hh01hh61hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh1666166616661666166616661
0000hhh00000hhh00000hhh00000hhh000d6dhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh5551555155515551555155515
h0h0hhhhh000hhhhh0h0hhhh7700hhhh711d11hh7700hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhh77h0hhhh7700hhhh77h0hhh6616661666166616661666166
10h0hhh000001hhh10h0hhh7dd771h7761111167dd771h7h10h0hhh000001hhh10h0hhh000001hh7dd77hh77dd771h77dd77hh75155515551555155515551555
00h01hh01h10000000h01hh0dd10770071111170dd10770000h01hh01h10000000h01hh01h100000ddh077h0dd107700ddh077h1666166616661666166616661
hhh00000hhh0hhh0hhh00000ddh0hhh0dd111000ddh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0ddh00000ddh0hhh0ddh00005551555155515551555155515
hhhhh000hhh0hh10hhhhh005515551555555615551555150hhhhh000hhh0hh10hhhhh000hhh0hh15515551555155515551555156616661666166616661666166
hhhhh00000000000hhhhh005155515551555555515551550hhhhh00000000000hhhhh00000000005155515551555155515551555155515551555155515551555
1hhh101hhh101hh01hhh10116661666166616661666166601hhh101hhh101hh01hhh101hhh101hh1666166616661666166616661666166616661666166616661
000000hhhhh0hhh0000000h5551555155515551555155510000000hhhhh0hhh0000000hhhhh0hhh5551555155515551555155515551555155515551555155515
hh01h01hhh10hhhhhh01h01661666166616661666166616hhh01h01hhh10hhhhhh01h01hhh10hhh6616661666166616661666166616661666166616661666166
hh0hh000000000hhhh0hh00515551555155515551555155hhh0hh000000000hhhh0hh000000000h5155515551555155515551555155515551555155515551555
h101hh101hhh10hhh101hh1166616661666166616661666hh101hh101hhh10hhh101hh101hhh10h1666166616661666166616661666166616661666166616661
00000000hhhhh0000000000555155515551555155515551000000000hhhhh00000000000hhhhh005551555155515551555155515551555155515551555155515
1hhh1000hhhhh0001hhh10066166616661666166616661601hhh1000hhhhh0001hhh1000hhhhh006616661666166616661666166616661666166616661666166
hhh00000hhh00000hhh00005155515551555155515551550hhh00000hhh00000hhh00000hhh00005155515551555155515551555155515551555155515551555
1hh01hh01hh01hh01hh01hh16661666166616661666166601hh01hh01hh01hh01hh01hh01hh01hh166616661666166601h501hh01h6666h01hh01hh01h501hh1
0000hhh00000hhh00000hhh55515551555155515551555100000hhh00000hhh00000hhh00000hhh555155515551555100605hhh00006hhh00000hhh00605hhh5
h0h0hhhhh000hhhhh0h0hhh661666166616661666166616hh0h0hhhhh000hh555550hhhhh000hhh6616661666166616hh6h5hhhh7778hhhhh0h0hhhhh605hhh6
10h0hhh000001hhh10h0hhh515551555155515551555155h10h0hhh000001ha5a5555hh000001hh5155515551555155h1060hhh077771hhh10h0hhh000601hh5
00h01hh01h10000000h01hh166616661666166616661666000h01hh01h10055555a55hh01h100001666166616661666000501hh01h10000000h01hh01h500001
hhh00000hhh0hhh0hhh00005551555155515551555155510hhh00000hhh0h60000555000hhh0hhh55515551555155510h6h50000hhh0hhh0hhh00000h6h5hhh5
hhhhh000hhh0hh10hhhhh006616661666166616661666160hhhhh000hhh0hha0a0066000hhh0hh166166616661666160h6h5h000hhh0hh10hhhhh000h6h5hh16
hhhhh00000000000hhhhh005155515551555155515551550hhhhh0000005079090776050000000051555155515551550hh6hh00000000000hhhhh00000600005
1hhh101hhh101hh01hhh10116661666166616661666166601hhh101hhh655h7777776556hh101hh01hhh101hhh101hh01h5h101hhh101hh01hhh101hhh501hh1
000000hhhhh0hhh0000000h5551555155515551555155510000000hhh66655h7777055666hh0hhh0000000hhhhh0hhh0060500hhhhh0hhh0000000hhh6h5hhh5
hh01h01hhh10hhhhhh01h01661666166616661666166616hhh01h01h6616655h9906666h6610hhhhhh01h01hhh10hhhhh605h01hhh10hhhhhh01h01hh615hhh6
hh0hh000000000hhhh0hh00515551555155515551555155hhh0hh0006060666696666606060000hhhh0hh000000000hhhh6hh000000000hhhh0hh000006000h5
h101hh101hhh10hhh101hh1166616661666166616661666hh101hh101h66666h660ah6661hhh10hhh101hh101hhh10hhh151hh101hhh10hhh101hh101h5h10h1
00000000hhhhh0000000000555155515551555155515551000000000hh66h00066690066hhhhh00000000000hhhhh00006050000hhhhh00000000000h6h5h005
1hhh1000hhhhh0001hhh10066166616661666166616661601hhh1000hhh6h0066h6aa060hhhhh0001hhh1000hhhhh00016h51000hhhhh0001hhh1000h6h5h006
hhh00000hhh00000hhh00005155515551555155515551550hhh00000hhh00006hhhaa000hhh00000hhh00000hhh00000hh600000hhh00000hhh00000hh600005
1hh01hh01hh01hh01hh01hh16661666166616661666166601hh01hh01hh01aaa1hhaahh01hh01hh01hh01hh01hh01hh01h501hh01hh01hh01hh01hh888888881
0000hhh00000hhh00000hhh55515551555155515551555100000hhh00000haaa0000hhh00000hhh00000hhh00000hhh00605hhh00000hhh00000hhh8aaaaaa85
h0h0hhhhh000hhhhh0h0hhh661666166616661666166616hh0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh6h5hhhhh000hhhhh0h0hhh8a5aa5a86
10h0hhh000001hhh10h0hhh515551555155515551555155h10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh1060hhh000001hhh10h0hhh8a8aa8a85
00h01hh01h10000000h01hh166616661666166616661666000h01hh01h10000000h01hh01h10000000h01hh01h10000000501hh01h10000000h01hh8aaaaaa81
hhh00000hhh0hhh0hhh00005551555155515551555155510hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0h6h50000hhh0hhh0hhh000085a55a585
hhhhh000hhh0hh10hhhhh006616661666166616661666160hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10h6h5h000hhh0hh10hhhhh00885885886
hhhhh00000000000hhhhh005155515551555155515551550hhhhh00000000000hhhhh00000000000hhhhh00000000000hh6hh00000000000hhhhh00888888885
1hhh101hhh101hh01hhh101hhh101hh01h66661hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01h5h101hhh101hh01hhh101hhh101hh1
000000hhhhh0hhh0000000hhhhh0hhh00007777hhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0060500hhhhh0hhh0000000hhhhh0hhh5
hh01h01hhh10hhhhhh01h01hhh10hhhhhh08777hhh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhhh605h01hhh10hhhhhh01h01hhh10hhh6
hh0hh000000000hhhh0hh000000000hhhh0hh000000000hhhh0hh000000000hhhh0hh000000000hhhh0hh000000000hhhh6hh000000000hhhh0hh000000000h5
h101hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hhh101hh101hhh10hhh151hh101hhh10hhh101hh101hhh10h1
00000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00006050000hhhhh00000000000hhhhh005
1hhh1000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh0001hhh1000hhhhh00016h51000hhhhh0001hhh1000hhhhh006
hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hh600000hhh00000hhh00000hhh00005
1hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh8888888801h5151101hh01hh01hh01hh1
0000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh00000hhh8aaaaaa80005151111000hhh00000hhh5
h0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhhhh0h0hhhhh000hhh8a5aa5a8hh111111110h0hhhhh000hhh6
10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hhh10h0hhh000001hh8a8aa8a800600000110h0hhh000001hh5
00h01hh01h10000000h01hh01h10000000h01hh01h10000000h01hh01h10000000h01hh01h10000000h01hh01h100008aaaaaa801hc0c00660h01hh01h100001
hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh0hhh00000hhh0hhh85a55a580h7c0c0776hh00000hhh0hhh5
hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh10hhhhh000hhh0hh1885885880hh7777776hhhh000hhh0hh16
hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh00000000000hhhhh000000000088888888000077770hhhhh00000000005
1h11515hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh106hh01hhh101hhh101hh1
1111515hhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhh0hhh0000000hhhhhd6dh0000000hhhhh0hhh5
11111111hh10hhhhhh01h01hhh10hhhhhh01h01hhh10hhhh7701h01h7710hhhh7701h01h7710hhhhhh01h01hhh10hhhhhh01h01hhh11d11hhh01h01hhh10hhh6
11000006000000hhhh0hh000000000hhhh0hh000000000h7dd77h077dd770077dd77h077dd77007hhh0hh000000000hhhh0hh00006111116hh0hh000000000h5
6600c0c01hhh10hhh101hh101hhh10hhh101hh101hhh10hhdd017710ddhh77hhdd017710ddhh77hhh101hh101hhh10hhh101hh1017111117h101hh101hhh10h1
6770c0c7hhhhh00000000000hhhhh00000000000hhhhh000dd000000ddhhh000dd000000ddhhh00000000000hhhhh00000000000hhh1110000000000hhhhh005
67777770hhhhh0001hhh1000hhhhh0001hhh1000hhhhh005515551555155515551555155515551501hhh1000hhhhh0001hhh1000hh55h6001hhh1000hhhhh006
hh777700hhh00000hhh00000hhh00000hhh00000hhh0000515551555155515551555155515551550hhh00000hhh00000hhh00000hhh00550hhh00000hhh00005
1hh61hh01hh01hh01hh01hh01hh01hh01hh01hh01hh01hh166616661666166616661666166616661666166616661666166616661666166616661666166616661
07d6dhh00770hhh00770hhh00770hhh00770hhh00770hhh555155515551555155515551555155515551555155515551555155515551555155515551555155515
711d11h77dd77hh77dd77hh77dd77hh77dd77hh77dd77hh661666166616661666166616661666166616661666166616661666166616661666166616661666166
611111600dd0177h1dd0h7700dd0177h1dd0h7700dd0177515551555155515551555155515551555155515551555155515551555155515551555155515551555
711111701dd000000dd01hh01dd000000dd01hh01dd0000166616661666166616661666166616661666166616661666166616661666166616661666166616661
hd111000hdd0hhh0hdd00000hdd0hhh0hdd00000hdd0hhh555155515551555155515551555155515551555155515551555155515551555155515551555155515
h55h6000hdd0hh10hddhh000hdd0hh10hddhh000hdd0hh1661666166616661666166616661666166616661666166616661666166616661666166616661666166
hddh55000dd00000hddhh0000dd00000hddhh0000dd0000515551555155515551555155515551555155515551555155515551555155515551555155515551555
66616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661
55155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515
61666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166
15551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555
66616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661
55155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515
61666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166
15551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555
66616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661
55155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515
61666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166
15551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555
66616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661
55155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515
61666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166
15551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555155515551555
1hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh01hhh101hhh101hh0

__gff__
0001020104018080010404000000000104040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0001010101010101010101010101000000000000000000000000000000000000000000000000000000000000000808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080801010101080808080808080808080808
000100000000000000000000000100000000000000000000000000000000000000000000000000000000000000080000000000000000080000000000000000000000000000000000000000000000000008140000000000000000000000000008081a0000000000000000007e004d4d0000004d00000000020000000808080808
00010000000000000000000000010000000000000000000000000000000000000000000000000000000000000008000000000000000045000000000000000000000000000000000000000000000000004543000000000000002b000000000008084400000000000000000000004d4d0000004d00000000020000000808080808
0001000000000017000000000001000808080808080808080808080808000000000000000000000000000000000800000000002b0000001a17001400000000000000000000000000002b000000000000001a17000000000000430000000000080808000000140000061a0000004d4d0000004d0000000002001a000808080808
0001000001000047000000010001000800004d0000000000000000000808080808080808080808080808080808080000000000430000004545004300000000000000000000000000004300000000000000454500000000000000000000000008080000000044000000440000004d4d0000004d00000000020044000808080808
0001000001010101010101010001000800004d00000000000000000000000000007e00004d004d080808080808080000080808080808080808080808080808080800000000080808080808080000000808080808080808080808080800000008080808080808080808080808084d4d0008080808000000080808080808080808
0001000000000000000000000001000800004d00000008080808000000000000000000004d005d007e18080808080000000000080000000000000000000000000000000000000800000000000000000000000800002b00000000000000000008080808080808080808080808084d4d0002020808000000004d00007e4d000008
0001000000000000000000000001000800004d0000000002024208000000000000000000080800000042004e040400000000004500000000000000002b000000000000000000452b000000000000000000004500004300000000000000000008080808000000000000000000084d4d0000020208000000004d0000004d000008
0001000000000000000000000001000800144d0000000000000042080808080800000000424208000000004e4545000000171a14000000000000001a4300140000000017001a06430000000000140014001a0600000000000000000000000008080505000000000000000000084d4d0000000208000000004d0000004d000008
00010000100000001a001a000001000800424d0500000000000000080000000005000000404042000000004e45450000004545430000000000000045000045000000004500454500000000000043004500454500000000000000000000000004044e0000000000001a00000008024d0000000808000000004d1a00004d000008
000100004700000047004700000100080808080200000000000000421700000000020200000040000808080808080000080808080808000000080808080808080808080808080808000000080808080808080808000000080808080800000043434e001000000000440000000000020000000808000000004d4400005d000008
000101010101010101010101010100080800004d00000000000000004200001400424200000000007e001804044e1000000000000000000000000014000800000000000000000000000000000000000000000000000000000000000000000043434e004400000008080800000000000000000808000000080808080000000008
000000000000000000000000000005057e00004d000000020000000008000042004040000002000000144242424e43000000002b000000000000004300450000000000000000000000002b000000000000000000000000000000000000000008080808080800004d004d00000000000000000808000000080808080000000008
000000000000000000000000000005050000004d000002420000000842080808000000000002080000420808080800000000004300000000000017001a00000000000000140000000000430000001900000000000014000000002b0000000008080808080800004d000200000000000000000808000000080808020000000008
000000000000000000000000000005050000004d050542050808084242424242080808080808080808080808080800000000000000000000000045004500000000000000450000000000000000004500000000000043000000004300000000080808080808020202020002020202020202020808000000080802000000000008
00000000000000000000000000000505000000050000000002007e0000000000000000005d08007e00000808080800000808080808080808080808080808080000000808080808080000000808080808080808080808080808080808000000080808080808080808080808080808080808080808000000080200000000000008
0000000000000000000000000000050519000000000000000000000000000000000000000042001400000008080800000000000008000000000000000000000000000200000000020000000000000000000000000000000008000000000000080808000000000000000000007e00000000000000000000080000000000000008
000000000000000000000000000005054200000000000000000000000808080000000000004200420000000808080000000000004500000000002b0000000000000045002b0000450000000000000000000000000000000045000000000000080808000000000000000000000000000000000000000000080000000000000008
0000000000000000000000000000050500004c5b000000000000000000000000000000000042080808000008080800060014141a06000000140043000000000600064500431714450600060000001400002b00001400061a000000000010004e04041a0000000000000600001400000600000000000000001a00000000000008
00000000000000000000000000000008080808005c5b000000000000001400000002000000004242420010080808000000454345450000004500000000000000004345000045434543000000000045000043000043004545000000000645004e4444440000000000000000004400000000000000000000004400000005000008
000000000000000000000000000000080808080808005c4c5b02020000420000004200000000404040004208080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080802020205050808
00000000000000000000000000000000000008080808080808080808080808080808080808084f4f4f4f0808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808
0000000000000000000000000000000000000808080808080808080808080808080808080808424242420808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010101020200007e000000004d4d01010101014f4f4f4f0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000101010000000000000000004d0201010101014141414101010101010101010101010101010103007e00000000004d4d00004d4d4d0000004d4d4d4d4d4d4d4d4d000000007e000000004d4d4d0101000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000010100000014000000140002000101010101040404040101010101010101010101010101010300000000000000020200004d4d4d0000000202020202020202020000000000000000004d4d5d0101000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000010100000041000000410000000101010101414141410101010101010101010101010101010300000000000000020200004d4d4d0000000000000000000000000000000000000000004d4d000101000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000100004c4c4c4c4c4c4c00000101010101414141410101010101010101010101010101010300000001010000000000000303030000000000000000000000000000000000000000000202000101000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000100000101010101010100007e0000004d000000004d0000007e000000000101010101010300000001010000000000000000000000000000000000000000000000000101000000000202000101000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000010000010101010101010000000000004d000000004d00000000000000000101010101010000000001010000000000000000000000000000000000000000000000000101000000000000000101000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001001400004d0000004d00000000001400000000005d00000000001400000000004e04040000000001010000000000000000000000000000000000000000000000000101010100000000000101000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001004100004d0000004d000000000041000000000000000000000041000000100041404000000001010100004b4b4b4b0000000000000303030303000000000000000101010100000000000101000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000000000665006620096200c6501c0201d1201c1201d120116201d120290501e1501e0401e140200501e17036670366703567034670346703467033650146501d650296502465000000000000000000000
041000000000200002100221202214022160221b0221f0222302226022290222b0222c022290221c022130221102214022190221b0221d0221e022210221f022180221202213022190221b022000020000200002
00030000306702d6602a65029650266402464022630206301e6301b6201962017620156101460012600106000f6000d6000c6000b600000000000000000000000000000000000000000000000000000000000000
00040000266100b6100b6101f6001f6001d6001c6001a60013600116000e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90040000005760257604576085760c57612576165761a5761d57622576275762e576355763a5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d5763d576296062860626606216061f606
000200002d6532e6632f6732e6732d6732b67333173311732e1532a153271732517323163201631e1531b153191531815317153151531415312143101430e1330d1330c1230b1230811306113041030210301103
a0040000126531365317653246572e657000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020400000563411630216502f6601e650356603f6653f667006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0002000014620166201a6301e640266402f6503f6502f6603167005070090500c0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002a670296702667025670216701d6701967016660002650066500265006550025500655002550065500245006450024500635002350063500235006350023500635002350062500225006250022500625
000200002e6722e6622e6622c6522c6522a6522865225652216521f6421d6421b64218642166421463214632106320f6220e6220b6220a6220962207612056120461202602016020060200002000020000200002
0002000023210282102d2102f21028610276102561023610216101e6101c4101b4101941015410134100a51007510055100261000000000000000000000000000000000000000000000000000000000000000000
00050000135372a6323a5372363218137121310413102131021320213203107031070010700107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700107
04020000225341e5341d53216530225341e5341d53216530007040000400002000000000400004000020000000002000020000200002000020000200002000020000200002000020000200002000020000200002
081e0000225341e5341d53216530225341e5341d53216530225341e5341d53216530225341e5342453225530225321e5321d53216532225321e5321d53216532225321e5321d53216532225321e5322453225532
481e00000a1540a1500a1400a1400a1320a1300a1210a1200d1540d1400d1320d1210c1540c1400c1320c1210a1540a1500a1400a1400a1320a1300a1210a1200d1540d1400d1320d1210c1540c1400c1320c121
481e00000a1540a1530a1420a1410a1340a1330a1220a1210d1540d1430d1320d1210c1540c1430c1320c1210a1540a1530a1420a1410a1340a1330a1220a1210d1540d1430d1320d1210c1540c1430c1320c121
001e00000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c04300000000000000024615000000000000000
091e000018100181001810018100191001a1001a10000001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000011810018100181101813118161
091e00001a1511a1321a1211a1121c1421c1321d1421d13219151191321912119112161421514213142111420e1510e1320e1210e112101421013211142111320d1510d1310d1220d11208151081310812108112
111e00001a1511a1321a1211a1121c1421c1321d1421d13219151191321912119112161421514213142111420e1520e1321115211132101521013210122101120e1520e132111521315210152101321012210112
902800000a5500a5550a5400a5450a5300a5350a5200a5250d5500d5450d5300d5250c5500c5450c5300c5250a5500a5550a5400a5450a5300a5350a5200a5250d5500d5450d5300d5250c5500c5450c5300c525
5828000016755167351975519735187551873518725187151675516735197551b7551875518735187251871516755167351975519735187551873518725187151575515735157251571516755167351875519755
0128000011043000000000000000186150000000000000000c04300000000000c043186150000000000000000c043000000000000000186150000000000000000c04300000000000c04318615000000000018615
000400000d7000f700127000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001827014260112600f2500d2400c2300a2300c0200a0700907000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000023676236762267621666206661e6561c6561b646196461663614636126360f6360d6260b62608626066260462601616016160061603606016060160611606106060c0061800624006000060000600006
00010000216732266322653206531b65315653116430e6430b6430a64309633096330962309623096130661305613000030000300003000030000300003000030000300003000030000300003000030000300003
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

