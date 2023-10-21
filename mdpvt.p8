pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- main

-- current level.
-- stored on dget(1)
level = 7

-- music to play for each level
-- in order, starting from 1
level_music =
  {0,0,0,12,12,12,20,35,-1}

-- music to play for each level
-- dialogs, in order.
level_dialog_music =
  {6,6,6,9,9,9,18,9,18}

-- hard difficulty enabled?
-- (o or 1), stored on dget(6)
hard = 1

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

-- Level on wich the player
-- gains the ability to break
-- cracked bricks
break_bricks_level = 7

-- music track currently playing
music_playing = -1

-- frames of input transition.
black = 9

-- camera does the thug shaker
camera_shake_x=0
camera_shake_y=0
camera_shake_time=0

-- stars for the background
stars = {}

cracked_bricks={}
void_blocks={}

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
  for y = 0,63 do

   t = mget(x,y)

   -- ambibalent death-blocks
   if t==3 or t==6 then
    t = t+2-t*hard
    mset(x,y,t)
   end

   -- look at the tile under
   -- for a level marker
   levelmark = -1
   nxt = mget(x,y+1)
   if 64 <= nxt and nxt <= 74 then
    levelmark = nxt-63
    mset(x,y+1,0)
   end

   if t==16 then
    if levelmark == level then
     pla.x = 8*x
     pla.y = 8*y
     level_has_player = true
    end
    mset(x,y,0)
   elseif fget(t, 4) then
    if levelmark == level then
     w = create_worker(
       x*8,y*8,t)
     workers_req += w.lives
    end
    mset(x,y,0)
   elseif t==101 then
    if levelmark == level then
     add(spawn_points, {8*x,8*y})
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

   t = mget(x,y)
   if fget(t, 5) then
    local brick = {x=x*8,y=y*8,w=8,h=8}
    add(cracked_bricks, brick)
   elseif t == 90 then
    -- turn direction switchers
    -- into their invisible
    -- variant
    mset(x,y,87)
   elseif t == 14 then
    add(void_blocks, {x,y})
   end
  end
 end

 -- initialize stars
 for i=1,80 do
  add(stars,
    {rnd(128),rnd(128),1})
 end
 for i=1,10 do
  add(stars, {
    rnd(128),rnd(128),rnd(5)})
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
  music(track, 0, 3)
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
  -- update music track
  if level_dialog_music[level] then
   play_music(
     level_dialog_music[level])
  end
 elseif level_has_player then
  foreach(rockets, rocket_update)
  player_update()
  foreach(workers, worker_update)
  foreach(particles, particle_update)
  foreach(railshots, railshot_update)
  foreach(knives, knife_update)
  foreach(electroballs, electroball_update)
  shake_update()
  void_blocks_update()
  -- update music track
  if level_music[level] then
   play_music(level_music[level])
  end
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
 pal(15,133,1)
 pal(4,128,1)

 if level==0 then
  menu_draw()
  goto draw_end
 end

 cls()
 camx=pla.x-64+3+camera_shake_x
 camy=pla.y-64+7+camera_shake_y

 -- draw stars
 for s in all(stars) do
  sx = (s[1]-camx\16)%128
  sy = (s[2]-camy\16)%128
  circfill(sx,sy,s[3],7)
 end


 camera(camx, camy)

 -- draw wallpaper
 palt(0, false)
 bgx = camx\8
 bgy = camy\8
 for tx=bgx,bgx+16 do
  for ty=bgy,bgy+16 do
   if not fget(mget(tx,ty),6) then
    spr(88+ty%2*16+tx%2,
      8*tx,8*ty)
   end
  end
 end
 palt(0, true)


 -- draw map
 map()

 knives_draw(false)
 player_draw()
 foreach(workers, worker_draw)
 foreach(railshots, railshot_draw)
 knives_draw(true)
 foreach(electroballs, electroball_draw)
 foreach(particles, particle_draw)
 foreach(rockets, rocket_draw)

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
 if workers_req > 0 then
  s = "kills:"..workers_dead
    .."/"..(workers_req)
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
   -- computer
   if 106<=t and t<=108 then
    mset(x, y, 106+frame%48\16)
   end
   -- goal tiles
   if t==1 or t==9 or t==10 then
    if workers_dead >= workers_req then
     mset(x, y, 9 + frame%32\16)
    else
     mset(x, y, 1)
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
  return o1.x + o1.w > o2.x and
    o2.x + o2.w > o1.x and
    o1.y + o1.h > o2.y and
    o2.y + o2.h > o1.y
end

-- can the object move by
-- (dx, dy)?
function objcanmove(o, dx, dy, flag)
 return not rectcol(o.x+dx,
   o.y + dy, o.w, o.h, flag)
end

-- apply gravity (no more than terminal velocity)
grav = 0.2

function objapplygravity(o)
 if o.vy < 7 then
  o.vy = min(o.vy + grav, 7)
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
    o.ground = sy > 0
   end
  end
 end
end

-- move object using its speed.
-- the object will get stuck on the solids.
-- fast computation.
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
-- NOTE: assuming object has portrait shape
function objinside(o,cx,cy,r)
 pts = (o.h+3)\4
 for t=1,pts do
  if inside(
    o.x+o.w/2, o.y-2+4*t,
    cx, cy, r) then
   return true
  end
 end
 return false
end

function veclimit(vx, vy, lim)
 m = lim/sqrt(vx*vx + vy*vy + 0.001)
 if m < 1 then
  vx *= m
  vy *= m
 end
 return vx, vy
end

function objaimto(o,x,y,s,relative)
 dx = (x - o.x)/4
 dy = (y - o.y)/4
 if abs(dx) < 128 and
   abs(dy) < 128 then
  dx,dy = veclimit(dx, dy, s)
  if relative then
   dx += o.vx
   dy += o.vy
  end
  o.vx = dx
  o.vy = dy
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
  end
  if btn(➡️) and not btn(⬅️) then
   pla.vx += 1
   -- limit horizontal speed
   if pla.vx > 3 then
    pla.vx = 3
   end
   pla.animb += 1
   pla.facer = true
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
      x=pla.x-8,
      y=pla.y+8,
      w=24,
      h=14
     }
     for worker in all(workers) do
      if objcol(worker,slamkillzone) and not worker.dead then
       worker_hit(worker)
       worker_hit(worker)
      end
     end
     for brick in all(cracked_bricks) do
       slamkillzone.y=pla.y+8
       if objcol(brick, slamkillzone) then
        brick_break(brick)
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
   workers_dead >= workers_req
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
function rocket_update(r)
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
    if w.facedir == -1 then
     front = r.x+2 < w.x
    else
     front = w.x+6 < r.x
    end
    if not w.dead and
      objinside(w, r.x+3,
        r.y+1, rocket_xrad) then
     if w.type == "hunter" then
      w.stun = 90
      w.animhit = 6
      w.vx = 0
     elseif w.type=="thad"
       and front then
      w.pipeanim = 12
     else
      worker_hit(w)
     end
    end
   end
   for brick in all(cracked_bricks) do
    if objinside(brick, r.x+3,
      r.y+1, rocket_xrad) then
     brick_break(brick)
    end
   end
  end
 end
end

function brick_break(brick)
 if level >= break_bricks_level then
  add_blood(brick.x+4,brick.y+4,{5,6,7}, rnd(6)+4)
  mset(brick.x/8,brick.y/8,0)
  del(cracked_bricks, brick)
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
function rocket_draw(r)
 if r.explosiont > 0 then
  add_explosion(r.x,r.y, 1)
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
workers_req = 0

railshots={}
knives={}
electroballs={}
spawn_points={}

function create_worker(x1, y1, id)
 worker = {
  x = x1,
  vx = 0,
  y = y1,
  vy = 0,
  h = 16,
  w = 8,
  dead = false,
  canmove = false,
  canfollow = false,
  canflip = true,
  touchdeath = true,
  blood = {2,5,6},
  facedir = rnd({-1,1}),
  blink = rnd({8,9,10,11,12}),
  flying = false,
  stun = 0,
  animhit = 0,
  lives = 1,
  startx = x1,
  starty = y1,
  id = id,
  maxhp = 1
 }
 if 23<=id and id<=25 then
  worker.type = "uzi"
  worker.railgundelay = 0
  worker.sprite = 23
  if id==24 then
   worker.canflip = false
   worker.facedir = -1
  elseif id==25 then
   worker.canflip = false
   worker.facedir = 1
  end
 elseif id==26 then
  worker.type = "thad"
  worker.canflip = true
  worker.touchdeath = false
  worker.sprite = 26
  worker.pipeanim = 0
  worker.blood = {8,5,6}
  worker.facedir = 1
 elseif 84<=id and id<=86 then
  worker.type = "hunter"
  worker.touchdeath = false
  worker.sprite = 84
  worker.blood = {8,13,6}
  worker.facedir = 1
  worker.flying = true
  worker.knivedelay = 50+5*#workers
  worker.lives = 3 + hard
  worker.canfollow = id==84
 elseif id==29 then
  worker.type = "mech"
  worker.h = 24
  worker.touchdeath = false
  worker.sprite = 29
  worker.blood = {5,6,13}
  worker.facedir = 1
  worker.maxhp = 15+5*hard
  worker.hands = {
   {x=x1+1, y=y1+9, w=6, h=6,
    vx=0, vy=0, moving=false},
   {x=x1+1, y=y1+9, w=6, h=6,
    vx=0, vy=0, moving=false}
  }
  worker.t = 0
  worker.angry = 0
 elseif id==43 then
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
 worker.hp = worker.maxhp
 add(workers, worker)
 return worker
end

function worker_hit(worker)
 if worker.hp>1 then
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
 if worker.dead then
  return
 end
 sfx(2)
 worker.dead = true
 worker.vy -= 0.5
 worker.vx = 0
 worker.h -= 8
 worker.flying = false
 if worker.type != "mech" then
  add_blood(
    worker.x+3, worker.y+9,
    worker.blood)
 else
  add_blood(
    worker.x+3, worker.y+9,
    worker.blood,22)
    music(43)
  electroballs = {}
 end
 workers_dead += 1
 for railshot in all(railshots) do
  if railshot.owner==worker then
   del(railshots,railshot)
   sfx(4,-2)
  end
 end

 if worker.lives > 1 then
  if #spawn_points == 0 then
   sx = worker.startx
   sy = worker.starty
  else
   spawn = rnd(spawn_points)
   sx = spawn[1]
   sy = spawn[2]
  end
  sfx(60)
  id2 = worker.id
  -- hunter 85 creates hunter 84
  if (worker.id == 85) id2 = 84
  worker2 = create_worker(sx,sy,id2)
  worker2.lives = worker.lives-1
  add_hole(sx+4, sy+4)
 end
end

function mech_chainsaws(worker)
 chs = {}
 for h in all(worker.hands) do
  for p in all({0.333, 0.666}) do
   ch={
    x=p*worker.x+(1-p)*h.x+1,
    y=p*(worker.y+8)+(1-p)*h.y+1,
    w=6,
    h=6,
   }
   add(chs, ch)
  end
 end
 return chs
end

function worker_update(worker)
 if worker.type == "target" then
  return
 end

 if not worker.dead then
   -- die if touching a void block
  if rectcol(worker.x, worker.y,
    worker.w, worker.h, 3) then
   worker_hit(worker)
  end
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
   if worker.stun > 0 then
    worker.flying = false
    worker.stun -= 1
   elseif not worker.dead then
    worker.flying = true
    if pla.x>worker.x then
     worker.facedir=1
    else
     worker.facedir=-1
    end

    worker.knivedelay -= 1
    if worker.knivedelay==0 then
     worker_throw_knives(worker)
    end

    if frame%35 == 0 then
     objaimto(worker,
       pla.x + rnd(90)-45,
       pla.y + rnd(40)-20,1)
     if not worker.canfollow then
       worker.vx = 0
       worker.vy = 0
     end
    end
    worker.vy += 0.5*cos(frame*0.1)
   end
  end
 end

 -- mech update
 if worker.hands then
  if not worker.dead then

   if worker.hp <= worker.maxhp\2 then
    worker.angry = 1
   end

   for t=1,2+worker.angry do
    local fr = worker.t%1200

    if fr < 600 then -- spinning attack
     -- throw energy ball
     if fr%(10540-10000*worker.angry) == 58 then
      eball = {x=worker.x+2, y=worker.y+10, vx=0, vy=0, w=4, h=4, t=0}
       add(electroballs, eball)
       sfx(1)
     end
     -- move the hands
     for h = 1,2 do
       if fr < 60 then
        mech_reset_hand(worker, h, 0.1)
       else
        worker.hands[h].x = worker.x+1+116*sin((fr-60)/540+0.5*h)
        -- hop
        if worker.ground then
         worker.vy -= 3
         worker.ground = false
        end
       end
     end
    else -- pincer attack
     fr %= 300
     p = 0.01
     if (fr%75 > 45) p = 0.3

     if fr==25 then
       mech_launch_hand(worker, 1)
     elseif 75<fr and fr<150 then
       mech_reset_hand(worker, 2, p)
     elseif fr==175 then
       mech_launch_hand(worker, 2)
     elseif 225<fr then
       mech_reset_hand(worker, 1, p)
     end

     -- aim for the player
     fr %= 150
     if fr == 9 then
      worker.tx = pla.x+1
      worker.ty = pla.y+4
      sfx(41)
     elseif fr == 50 then
      worker.tx = nil
     end
    end
    -- increase counter
    worker.t += 1
   end

   -- kill player with chainsaws
   chs = mech_chainsaws(worker)
   for ch in all(chs) do
    if objcol(ch, pla) then
     player_die()
    end
   end

   for hand in all(worker.hands) do
    objmovecheap(hand)
    -- kill player with hands
    if objcol(pla,hand) then
     player_die()
    end
    -- make sound if colliding
    if hand.moving and hand.vx == 0
      and hand.vy == 0 then
     hand.moving = false
     camera_thug_shake(5,3)
    end
    -- destroy bricks
    for brick in all(cracked_bricks) do
     if objinside(brick, hand.x+3,
       hand.y+3, 11) then
      hand.vx /= 4
      hand.vy /= 4
      brick_break(brick)
     end
    end
   end
  else
   for hand in all(worker.hands) do
    objapplygravity(hand)
    objmovecheap(hand)
   end
  end
 end

 if not worker.flying then
  objapplygravity(worker)
 end
 objmove(worker)

 if worker.animhit > 0 then
  worker.animhit -= 1
 end
end

function change_direction(worker)
 worker.vx=0
 worker.facedir*=-1
end

function mech_launch_hand(worker, h)
 hand = worker.hands[h]
 hand.moving = true
 objaimto(hand, worker.tx, worker.ty, 4+hard)
end

function mech_reset_hand(worker, h, p)
 hand = worker.hands[h]
 hand.vx = 0
 hand.vy = 0
 hand.x = (1-p)*hand.x+p*(worker.x-23+16*h)
 hand.y = (1-p)*hand.y+p*(worker.y+9)
end

function worker_draw(worker)
 if worker.animhit > 0 then
  pal(8,7)
  pal(9,7)
  pal(10,7)
 end

 if worker.type == "target" then
  if not worker.dead then
   spr(worker.sprite, worker.x, worker.y)
  end
  goto worker_draw_end
 end

 if worker.type == "mech" then
  -- change color if angry
  if worker.angry == 1 then
   pal(9, 2)
  end

  -- shoulder pads
  for t = 0,1 do
   circfill(worker.x+1+5*t,worker.y+10,3,13)
  end

  -- chainsaws
  chs = mech_chainsaws(worker)
  for ch in all(chs) do
   spr(62+frame%2, ch.x-1, ch.y-1,
     1, 1, frame%4>=2,
     frame%4>=2)
  end

  -- target
  if worker.tx then
   spr(94+frame%2, worker.tx-1, worker.ty-1)
  end
  -- body
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
   print(worker.hp,
     worker.x+4,
     worker.y-8, 8)
  end

  for h in all(worker.hands) do
   spr(46, h.x-1, h.y-1,
     1, 1, h.x-1 < worker.x)
  end

  goto worker_draw_end
 end

 -- glitch effect
 if worker.type == "hunter" and
   worker.flying then
  draw_glitch(
    worker.x-2,worker.y+3,
    12,12,{0,8})
 end

 -- black rectangle under head
 rectfill(worker.x+1, worker.y+3,
  worker.x+6, worker.y+5, 0)

 if worker.dead then
  spr(worker.sprite+2, worker.x, worker.y, 1, 1)
  spr(worker.sprite+18, worker.x - 7, worker.y, 1, 1)
 else

  blink = worker.stun > 0 or
    (frame\4)%worker.blink==0
  spr(worker.sprite+tonum(blink),
    worker.x, worker.y,
    1, 1,worker.facedir == 1)
  if worker.type == "hunter" then
   spr(worker.sprite+16,
     worker.x,
     worker.y+8,
     1, 1,
     worker.facedir == 1)
  elseif worker.canmove then
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

  ::worker_draw_end::
 -- reset palette
 pal(8,8)
 pal(9,9)
 pal(10,10)
end

function railshot_update(railshot)
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

function railshot_draw(railshot)
 rectfill(railshot.x,
   railshot.y,
   railshot.x+railshot.w-1,
   railshot.y+railshot.h-1,
   railshot.color)
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

knive_delay = 30

function knife_update(kni)
 kni.t += 1
 if kni.t < knive_delay then
  if kni.owner.dead or
    kni.owner.stun > 0 then
   kni.disabled = true
   kni.t = knive_delay
  else
   own = kni.owner
   p = min(kni.t/20, 1)
   kni.x = (1-p)*kni.x +
     p*(own.x+3+7*kni.tx)
   kni.y = (1-p)*kni.y +
     p*(own.y+8+7*kni.ty)
  end
 else
  if kni.t == knive_delay then
   spd=5
   sfx(1, -1, 0, 1)
   px = pla.x+3+rnd(16)-8
   py = pla.y+10+rnd(16)-8
   objaimto(kni,px,py,spd)
   kni.tx = kni.vx/spd
   kni.ty = kni.vy/spd
  elseif kni.t > 150 then
   del(knives, kni)
  end
  moving = abs(kni.vx) >= 1
    or abs(kni.vy) >= 1
  if moving then
    if objcol(pla,kni) and
      not kni.disabled then
     player_die()
    end
  end
  if kni.disabled then
   objapplygravity(kni)
  end
  objmovecheap(kni)
 end
end

function knives_draw(front)
 for kni in all(knives) do
  if front == (kni.t > knive_delay)
    then
   line(kni.x-3*kni.tx+1,
    kni.y-3*kni.ty+1,
    kni.x+3*kni.tx+1,
    kni.y+3*kni.ty+1, 7)
   circfill(kni.x-kni.tx+1,
     kni.y-kni.ty+1, 1, 6)
  end
 end
end

function worker_throw_knives(
  worker)
 worker.knivedelay=85-hard*20
 if worker.id == 84 then
  nknives = 6+2*hard
 elseif worker.id == 85 then
  nknives = 3+hard
 else
  nknives = 1
 end
 for i=1,nknives do
  local kni = {
   owner=worker,
   x = worker.x+2,
   y = worker.y+5,
   vx = 0,
   vy = 0,
   w = 3,
   h = 3,
   tx = cos(i/nknives)*worker.facedir,
   ty = sin(i/nknives),
   t=i*2,
   disabled = false,
  }
  add(knives, kni)
 end
 sfx(3)
end

function electroball_update(ball)
 ball.t += 1
 if ball.t > 270 then
  del(electroballs, ball)
  add_blood(ball.x+2, ball.y+2, {7, 10, 12})
 else
  -- Accelerate towards the player
  objaimto(ball, pla.x+2, pla.y+6, 0.03, true)
  ball.vx, ball.vy = veclimit(ball.vx, ball.vy, 3+hard)
  if objcol(pla, ball) then
   player_die()
  end
  objmove(ball)
 end
end

function electroball_draw(ball)
 spr(53+frame\2%3, ball.x-2, ball.y-2)
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
  lifetime = rnd(40)+25
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

function add_explosion(x, y, amount)
 for i = 1, amount do
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

function add_hole(x, y)
 add(particles,{
   type="hole",
   x=x,
   vx=0,
   y=y,
   vy=0,
   size=10,
   w=1,
   h=1,
   gravity=false,
   color={0,5,8},
   lifetime=100,
  })
end

function draw_glitch(x,y,w,h,cols)
 for i=1,3 do
  ry = y+rnd(h)
  rectfill(x+rnd(w-.5), ry,
   x+rnd(w-.5), ry+1, rnd(cols))
 end
end

function particle_update(p)
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
 elseif p.type == "hole" then
  p.size *= 0.95
  if p.size < 1 then
   del(particles,p)
  end
 end

 p.lifetime -= 1
end

function particle_draw(p)
 if p.type == "explosion" then
  circfill(p.x,p.y,p.size,
    p.color[flr(p.size/2)])
 elseif p.type == "hole" then
  s = p.size
  circfill(p.x,p.y,s,0)
  draw_glitch(p.x-s, p.y-s,
  2*s,2*s, p.color)
 else
  circfill(p.x,p.y,p.size,p.color)
 end
end

-- camera does the thug shaker
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
 "∧ zzzZZZ... zzzZZZ... ∧",
 "∧ zzzzzzZZZZZZ... ∧",
 20,
 "*beep*",
 22,
 "uh... where... who am i?",
 10,
 "it took you some time to",
 "wake up rookie.",
 20,
 "who are you?",
 10,
 "i am your supervisor.",
 "this is your training.",
 "you have been reset, and",
 "retrofitted as a",
 "disassembly drone.",
 21,
 "cool! what will i be",
 "disassembling?",
 11,
 "worker drones, mostly.",
 22,
 "oh...",
 10,
 "let's try the wings.",
 "press ❎ to flutter.",
 "move to the next area,",
 "and avoid the death-",
 "blocks.",
 20,
 "what do you mean with...",
 10,
 "they will kill you.",
 23,
 "kill me!?",
 11,
 "don't worry, it is just",
 "a simulation.",
 10,
 "...",
 "the pain is very real",
 "though...",
 22,
 "*gulp*"
}

dialog_2 = {
 10, 0, 2,
 "excelent!",
 10, 2, 9999,
 "try to be faster from now",
 "on, rookie.",
 "management is watching.",
 10,
 "now, i need you to",
 "disassemble all the",
 "drones in this area and",
 "reach the goal.",
 20,
 "i know it's my job and",
 "everything...but how do i",
 "do that exactly?",
 10,
 "simple! just get close and",
 "let your instincts handle",
 "the rest.",
}

dialog_3 = {
 20,
 "so...",
 "is there a reason why i'm",
 "disassembling all these",
 "worker drones?",
 10,
 "once you have completed",
 "your training in time,",
 "then maybe i'll give you",
 "an answer.",
 20,
 "`kay!",
 10,
 "worker drones may be",
 "unpredictably armed.",
 "management instructed me",
 "to add angsty teenagers",
 "with railguns in this",
 "part, for some reason.",
 20,
 "what is a railgun?",
 10,
 "kill 'em all, rookie!",
}

dialog_4 = {
 10, 0, 1,
 "...huh.",
 20, 0, 1,
 "did i mess up?",
 10, 0, 1,
 "no, nothing like that.",
 "been a while since a",
 "drone's done this",
 "well though.",
 10,
 "alright, next on the list",
 "is weapons.",
 "you're doing good, but",
 "it's about time you start",
 10, 0, 4,
 "using some more weaponry.",
 10, 4, 9999,
 "using your brain.",
 20, 4, 9999,
 "hey!",
 10,
 "i've enabled your rocket",
 "launcher.",
 "press 🅾️ to shoot.",
 "also, you don't have to",
 "worry about ammo, but",
 "you do have to detonate",
 "them manually, pressing",
 "🅾️ a second time.",
 "here's a few targets to",
 "practice on.",
 "knock 'em dead, rookie!",
}

dialog_5 = {
 10,
 "having fun rookie?",
 20,
 "feels like there's a",
 "correct answer here, but",
 "yeah!",
 10,
 "correct answer! looks like",
 "there's no need for any",
 "behavior correction, good",
 "for you!",
 20,
 "...should i be worried?",
 10,
 "since you're having fun,",
 "no.",
 20,
 "...cool!",
 10,
 "alright rookie, time to",
 "spice things up a bit.",
 "not every drone is going",
 "to sit there and take it",
 "if they see something",
 "coming at them.",
 "you might have to think",
 "outside the box for",
 "these drones.",
 10, 6, 9999,
 "hopefully that tip didn't",
 "go over your head...",
 10,
 "good luck!",
}

dialog_6 = {
 10,
 "since you seem to have ",
 "your aiming down, time to",
 "see if you can still shoot",
 "when there's return fire",
 "added back into the mix.",
 20,
 "does this mean more",
 "railguns?",
 10,
 "that and more!",
 "worker drones are designed",
 "to work together, so you",
 "may have to deal with",
 "teams that cover each",
 "other's weaknesses.",
 "chin up though, if you're",
 "outnumbered, then it's ",
 "almost a fair fight!",
}

dialog_7 = {
 10,
 "okay rookie, now you will",
 "have to face a real",
 "threat.",
 "at the end of this",
 "testroom there is a drone",
 "that has telekinetic",
 "powers and can also fly.",
 22,
 "wait, isn't that a little",
 "overpowered for a worker",
 "drone?",
 "such a thing doesn't",
 "really exist, right?",
 14,
 "...",
 "rookie, listen carefully,",
 "because i am only going",
 "to say this once.",
 13,
 "you may live long enough",
 "to see man-made horrors",
 "beyond your comprehension.",
 10,
 "you better be prepared.",
 24,
 "...",
 "hold on a moment!",
 12,
 "what? did i scare you?",
 24,
 "yes... i mean no.",
 22,
 "i just don't see the",
 "way out of this tunnel.",
 11,
 "oh yeah! almost forgot to",
 "mention that your rockets",
 "and stomp maneuver gained",
 "a small improvement.",
 "now you are able to break",
 "through the debris.",
 20,
 "...",
 "stomp maneuver?",
 10,
 "ah, yes, that thing you",
 "can do once you gain",
 "enough height, and press",
 "⬇️.",
 20,
 "oh!",
 13,
 "also you need that to",
 "disassemble these beasts.",
 "conventional explosives",
 "aren't enough for this",
 "kind.",
}

dialog_bonus_2 = {
 10,
 "next up is a simple fight",
 "against a worker piloting",
 "a mecanical suit. it's",
 "sturdy enough to take more",
 "than one hit, and each",
 "segment of its arms can",
 "kill you. best of luck.",
}

dialog_bonus_3 = {
 10,
 "lastly, you'll be facing",
 "two of these at the same",
 "time. take care not to let",
 "them tag-team you.",
 "good luck.",
}

dialog_demo_end = {
 10,
 "congrats on beating the",
 "extra trials! if you",
 "played on easy mode, why",
 "not see how you fare in",
 "hard mode? regardless",
 "your feedback would be",
 "appreciated in helping",
 "future development.",
 "thank you for playing!",
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
 dialog_7,
 dialog_bonus_2,
 dialog_bonus_3,
 dialog_demo_end
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

function unflatten(d1)
 d2 = {}
 numbs = {-1}
 next = true
 for e in all(d1) do
  if type(e) == "number" then
    if next then
     numbs = {}
     next = false
    end
    add(numbs, e)
  else
    add(d2, {e, unpack(numbs)})
    next = true
  end
 end
 return d2
end

-- start next dialog
function dialog_start(n)
 if n <= #dialogs then
  current_dial = unflatten(dialogs[n])
  filter_current_dial()
  dialog_on = true
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
 incomplete = dialog_c <
   #current_dial[dialog_l][1]
 if btnp(❎) or btn(🅾️) then
  if incomplete and not btn(🅾️) then
    dialog_c = 100
  else
    dialog_l += 1
    dialog_c = 0
    if dialog_l > #current_dial then
     dialog_l = 1
     dialog_on = false
     frame = 0
    end
  end
  sfx(13)
 elseif incomplete then
  dialog_c += 1
  sfx(13)
 end
end

function draw_portrait(s)
 if s>9 then
  chara = s\10 - 1
  expre = s%10 - 1
  spr(80+2*chara,2,108,2,2)
  if expre >= 0 then
   rectfill(7,116,14,123,0)
   spr(112+4*chara+expre,7,116)
  end
 end
end

-- draw the current dialog
function dialog_draw()
 if not dialog_on then
  return
 end

 line1 = current_dial[dialog_l]
 -- only show a substring
 text1 = sub(line1[1], 1, dialog_c)

 -- black background
 if line1[2] < 0 then
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
  text0 = line0[1]
  if line0[2] == line1[2] then
   draw_portrait(line1[2])
   print(text0,22,109, 5)
   print(text1,22,117, 10)
   return
  end
 end

 -- draw a single line
 draw_portrait(line1[2])
 print(text1,22,109, 10)
end


-->8
-- main menu

-- selected option
menu_option = 0

-- number particles
numparts = {}

function menu_init()
 -- level saved in the cart
 menu_saved_level = dget(1)
 -- difficulty saved in the cart
 menu_saved_hard = dget(6)
  -- initialize number particles
  -- (x, y, vy)
  for i=0,9 do
    for sx in all({1, 104}) do
     np = {sx + i\2*4, rnd(128),
       1+rnd(2)}
     add(numparts, np)
    end
   end
end

-- camera angle in radians
cama = 0
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
  col = 10
  if (frame < 80) col = 0
  circfill(vx,vy,1,col)
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

function draw_rookie()
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
 if cosa > 0.75 and frame > 79 then
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

function update_numparts()
  for np in all(numparts) do
   np[2] -= np[3]
   if np[2] < -8 then
    np[2] = 128
    np[3] = 1 + rnd(2)
   end
  end
 end

function menu_update()
 -- update camera
 cama = 0.82 - frame*0.01
 cosa = cos(cama)
 sina = sin(cama)

 update_numparts()

 if frame < 79 then
  if btnp(❎) then
   frame = 79
  end
 else
  if btnp(⬇️) then
   menu_option += 1
   sfx(7)
  elseif btnp(⬆️) then
   menu_option -= 1
   sfx(7)
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

 if frame == 80 then
   play_music(0)
 end
end

function printx(s,x,y,c)
 l = {-1,0,0,0,1}
 dx = rnd(l)
 dy = rnd(l)
 print(s,x,y,c)
 print(s,x+dx,y+dy,c)
 print(s,x-dx,y-dy,c)
end

function menu_draw()
 cls()
 camera(0,min(-20,frame-100))
 draw_rookie()
 camera()

 for part in all(numparts) do
  col = 5
  if (frame > 80) col = 8
  txt = sub(tostr(100+rnd(100)),
    2, 3)
  print(txt, part[1],
    part[2], col)
 end

 t1 = sub("VIRTUAL TRAINING",
   1, frame\5)
 printx(t1, 32, 10, 10)

 if frame < 80 then
  if frame % 5 == 0 then
   sfx(13)
  end
 elseif frame == 80 then
  cls(7)
  sfx(9)
 else
  print("murder drones", 38, 2, 9)
  if menu_saved_level == 0 then
   print("continue",38,84,5)
  elseif menu_saved_hard == 1 then
   print("continue (hard)",38,84,7)
  else
   print("continue (easy)",38,84,7)
  end
  print("new game (easy)",38,94,7)
  print("new game (hard)",38,104,7)
  printx("∧", 28, 84+10*menu_option, 9)

  rectfill(-1, 118, 128, 125, 0)
  rect(-1, 118, 128, 125, 5)
  print("FANGAME BY AUTOPAWN, MISZUK, CRJONCH & REMIMIXER. MUSIC BY REMIMIXER. SPECIAL THANKS TO THE MDP DISCORD SERVER!",
   128-(frame-80)%580, 119, 5)
 end
end
-->8
-- void blocks

function void_blocks_update()
 void_blocks_2={}
 for p in all(void_blocks) do
  x,y = unpack(p)
  in_cam = inside_camera(8*x,8*y)
  repl_frame = frame%(12-3*hard)==0
  if repl_frame then
    sfx(60)
  end
  if repl_frame or not in_cam then
   del(void_blocks, p)
   for sx=x-1,x+1 do
    for sy=y-1,y+1 do
     t = mget(sx,sy)
     if not fget(t,0) and
       not fget(t,1) then
      mset(sx,sy,14)
      add(void_blocks_2, {sx,sy})
     end
    end
   end
  else
   add(void_blocks_2, p)
  end
 end
 void_blocks = void_blocks_2
end
-->8
-- sprite flags

-- 0: solid sprites
-- 1: death-blocks
-- 2: the level goal
-- 3: block that kills workers
-- 4: sprite is a worker
-- 5: block is breakable
-- 6: display stars behind
-- 7: direction switcher
__gfx__
00000000550055008888888816661666106610606616661617771777717710777717771799009900008800880000000000000000d00000000505055044444000
00000000550055008aaaaaa85aaaaaa15051100151555155daaaaaa1d0d11d01d1ddd1dd99009900008800880000005a0000005add00000050555505ca66c000
00700700005500558a5aa5a86a0aa0a666166016166616667a0aa0a77717701717771777009900998800880000000d9000000d9a59d00000055575550cac0000
00077000005500558a8aa8a85a8aa8a55105515555515551da8aa8add10dd10dddd1ddd1009900998800880007777d9a07777d9009d777705557a75000a00000
00077000550055008aaaaaa81aaaaaa600061660661666161aaaaaa70077170777177717990099000088008808667d9a08667d9009d76630055797550c6c0000
007007005500550085a55a5850a00a015001555051555155d0a00a01ddd1ddd0d1ddd1dd990099000088008800000d9000000d9a59d0000055557550c6aac000
00000000005500558858858866066016661006101666166677077017071077101777177700990099880088000000005a0000005a5d0000005055550544444000
000000000055005588888888515551550151006555515551d1ddd1dd01d10dddddd1ddd100990099880088000000000000000000dd0000000550505000000000
0555550005555500055555000555550005151100051511000515110002555550025555500255555008aa870008aa870008aa870006da660006da660006da6600
0a5a55550a5a5555085855550a5a555505151111051511110515111102225555022255550222555508aa877708aa877708aa877706ad666606ad666606ad6666
55555a5555555a555555585555555a55111111111111111111111111222222252222222522222225999999779999997799999977cccccc66cccccc66cccccc66
60000555600005556800855569009555600000116000001168008011600002226000022268008222600000996000009968008099600000cc600000cc680080cc
0a0a00660000006600880066009900660c0c006600000066008800660202002200000022008800220b0b00660000006600880066060600660000006600880066
790907767909977678008776790097767c0c077671011776780087767202072272022722780087227b0b07767303377678008776760607767505577678008776
07777776077777760777777607777d76077777760777777607777776077777720777777207777772077777760777777607777776077777760777777607777776
007777000077770000777700007dd700007777000077770000777700007777000077770000777700007777000077770000777700977777099777770997777709
00099066000990a0000990006609900000060000000600000000000000060000d2222000000000000006000000888800000000009d5555d905555000905550d0
6669666600666690066666666669666600d6d00000d6d0000000000000d6d0000bbb222d0000000000d6d00008777780000000009dddddd95666655090ddd0d9
660660a0006666000666606606666066011d1100011d11000000000005525500d222d11d000000000a8b8a008778877800dd0000999999995666666590990099
0006669000066aa000666090066660a0611111606111116000000000656565600000002d0000222d6a878a6087877878055dd00009dddd90a756565009d00d90
006606aa00066aa00066aa00aa06669071111170711111700555550075565570000000000002888078878870878778780566dd009d6777d9a65565659d0507d0
006000aa00060aa00006aa00aa0006600011100000111000010000510065600000000000d222222d008880008778877808000dd89d6667d9566666650d555509
aaa000aa0aaa000000aaaa00aa00aaa00550600000605500110055110020200000000000d11d66520060600008777780880075da9d6666d95666655000055009
aaa000000aaa000000aaa0000000aaa00000550005500000011111110550550000000000d255222205505500008888000888888899dddd9905555000990dd099
00550000000500000000550000005500000990000a0cc700a00aa07000a770070000000000000000000000000007707700007700099999900066000000066000
005500000055600000555600000556007666660aa0caac7000a77a070a7cc70000000000000000000dd000000077007000007007955555590099996000999900
05556000055666000556066000556660766666090ca77ac70a7cc7a0a7caac70000000000000000055dd00000770070000070077955555590956659669566596
5556600055660660550660665556060000066650ca7cc7aca7caac7a7ca77ac70000000000000000500dd0000dd0700700700770955005596960069069600696
0556600050606060566066060666600000666660ca7cc7aca7caac7a7ca77ac700000000000000000000dd0005ddd0770dd0dd00955005596960069009600690
00660000006660000066060000660000006606607ca77ac00a7cc7a007caac7a000000000000000000005dd05500ddd0ddddd5dd955005590956659609566590
00660000000660000006000000060000aaa0aaa007caac0a70a77a00007cc7a06666666600000000000000dd500005dd55000000a990099a0099996006999960
00600000000600000006000000000000aaa0aaa0007cc0a0070aa00a70077a0055555555000000000000000d0000000050000000aaa00aaa0066000000600600
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f00000004005500050066000600000000000000000000500005111111555555555
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f00000004000500050006000600000000000770000006050005dd00dd5d1d1d1d1
08800080099900900aaa00a00b0b00b00ccc00c00ddd00d00eee00e00fff00f00444004005550050066600600770000077dd77000060500051111115d1d1d1d1
0080008000090090000a00a00b0b00b00c0000c00d0000d0000e00e00f0f00f00404004000000050000000607dd7700700dd0077000600005dd00dd501010101
00800880099909900aaa0aa00bbb0bb00ccc0cc00ddd0dd0000e0ee00fff0ff00444044005550550066006600dd0077000dd0000000500005111111501010101
0080000009000000000a0000000b0000000c00000d0d0000000e00000f0f00000004000005050000006000000dd0000000dd0000006050005dd00dd5d1d1d1d1
08880000099900000aaa0000000b00000ccc00000ddd0000000e00000fff00000444000005050000006000005515551500dd00000060500051111115d1d1d1d1
00000000000000000000000000000000000000000000000000000000000000000000000005550000066600005155515500dd0000000600005dd00dd555555555
0020000000000000000000000000000008888800088888000888880000000000ee101ee101eee10e000000000000000077000000000500000077770000888800
0282040000000000000000555550000008a8888808a8888808a8888800000000000000000eeeee0000c000000000000000770000000050000707707008000080
22284455555500000000555555555000aaaaaa88aaaaaa88aaaaaa880000000001eee1000eeeee000ccdddd00000000000dd7700000050007000000780000008
02244500aa0a5000000555aa5aa5aa00622222aa622222aa682282aa000000000eee00000eee000000c000007700000000dd0077000600007700007780088008
00445aa59956a500005aa5a95a95a9500808022200000222008802220000000001ee01ee01ee01ee00000c000070000000dd0000000500007700007780088008
04450a9555556500005a9555555555507808072278088722780087220000000000000eee00000eee0ddddcc00007000000dd0000000050007000000780000008
005a055555556500055555111111111127777722277777222777772200000000ee0e0eeeee000eee00000c000000770000dd0000000000000707707008000080
005a555555555000055551111111111022777722227777222277772200000000e10e0eee000001ee000000000000007700dd0000000000000077770000888800
05055555550005000555600000000600025652220055550000000000f444444f000e01ee01e100000ffffff00ffffff00ffffff00ffffff00000000000000000
05555555500005000066009900990600025552220566665000000000f444464f0eee00000eee0eeefa5aaa5ffaa5a55ffaaa5aaff588885f0000000000000000
0555550990099500006600aa00aa0600828882875665566500000000f444444f0eeeee000eee0ee1f555555ff555555ff555555ff588885f0000000000000000
0555000aa00aa550007770aa00aa07007055552256500565000222000ffffff00eeeee0000000000faa5a55ffaaa5aaffa5aaa5ff558855f0000000000000000
0555000aa00aa5500007777777777000008888205650056502222220f444444f01eee101eee101eef555555ff555555ff555555ff558855f0000000000000000
0555700007777000090007777777000000d00d005665566528555588f444464f0000000eeeee0eeef5aa5aaffa5aaa5ffaa5a55ff555555f0000000000000000
055557777770ffffa900009999000000008008800566665088008858f444444feee01e01eee10eeef555555ff555555ff555555ff558855f0000000000000000
005550662600ff67a900055559500000008000000055550008558888ffffffffeee0ee000000000e0ffffff00ffffff00ffffff00ffffff00000000000000000
555550005555500055555000555550000990099000000000000000000000000000f0f0000ffffff00ffffff00ffffff00ffffff0000666600006666000066660
55550000555500005555000055550000000aa00000900900090000900990099000ffff00ff5555ffff5554ffff4444ffff4445ff000060000000670000007777
509000905000000050110011500000000990099009a00a900a9009a09aa00aa900ffbf00f455444ff555444ff544455ff444555f077780000000870000008777
09090909099909990011001100000000000000000aa00aa00aa00aa09aa00aa900ffff00f44ff44ff45ff44ff55ff55ff54ff55f077770000000770000000000
0000000000aa00aa00110011099909997d7ddd77777777777d7777777dddd77700ffff00f44ff44ff44ff54ff55ff55ff55ff45f000000000000770000000000
000077770000777700007777000077777dddd7707777777077ddd7707dddd77000ffff00f444554ff444555ff554445ff555444f000000000000000000000000
777777047777770477777704777777040999900009999000099966000999900000000000ff5555ffff4555ffff4444ffff5444ff000000000000000000000000
066260040662600406626004066260045555a500555595005556776055559500000000000ffffff00ffffff00ffffff00ffffff0000000000000000000000000
800000c200c10000d400d40000808080800000d40000000000000000240065410024248383830000e700819090e4010000000000000000000000004100800000
0000000000e7000000000000000000000000000000000000000000000000003434e4004400000080808000000000000000008080000000808080800000000080
8080808080807070d400d40000008080e70000d471000020009700008000642400040400006000004141242424e43400000000b2009393939300003400540000
00000000000000000000b200000000009393930000000000000000000000008080808080800000d400d400000000000000008080000000808080800000000080
8000d4d4d5800000d400d40000008080000000d464002024007600802480808000000000002480006424808080800000000000340083838383007100a1000000
0000000041000000000034000000910083838300004100000000b2000000008080808080800000d4002000000000000000008080000000808080200000000080
8000d5d400800000d400d40000008080000000d47070247080808024242424248080808080808080808080808080000000000000000000000000540054000000
00000000540000000000000000005400000000000034000000003400000000808080808080202020200020202020202020208080000000808020000000000080
800000c100800000808080000000808000000070000000006000e75600000000242424d5808000e7000080808080000080808080808080808080808080808000
00008080808080800000008080808080808080808080808080808080000000808080808080808080808080808080808080808080000000802000000000000080
800055000080000080808000000080809100000000000000000000640000000004040400642400410000008080800000000000008000000000000000e7000000
000020000000002000000000000000000000e700000000008000000000000080808000000000000000000000e700000000000000000000800000000000000080
8000000000000000000000000000808024a10000560000419393000080808000000000006424a524000000808080000000000000540000000000b20000000000
00005400b20000540000000000000000000000000000000054000000000000808080000000000000000000000000000000000000000000800000000000000080
800000000000000000000000000080800064c4b5640000648383000024240000000000006424808080000080808000a5004141a1a500000041003400000000a5
00a5540034714154a500a5000000410000b200004100a5a100000000000100e49090a1000000000000a50000410000a50000000000000000a100000000000080
806100c200006162000000808080808080808000c5b5000000000000040441004120000064002424240001808080000000543454540000005400000000000000
00345400005434543400000000005400003400003400545400000000a55400e44444440000000000000000004400000000000000000000004400000070000080
80808080808080808080808080808080808080808000c5c4b5202000000024006424000064000404040024808080808080808080808080808080808080808080
80808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808060606070708080
8080808080808080808080808080808080808080808080808080807070708080808080808080f4f4f4f480808080808080808080808080808080808080808080
80808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
80808080808080808080808080808080808080808080808080808070707080808080808080802424242480808080808080808080808080808080505080808080
50808080808050808080805050508080808080508080808080805080808080808080000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000050808020200000e790909000d4d48050808050f4f4f4f480808050505080808080505080505050505050505050
50505050505050505050505050505050505050505050505050505050505050505050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000505050505000000064646400d4205050805050141414145050505050505080808050505050503000e700000000
00d4d40000d4d4d4000000d4d4d4d4d4d4d4d4d400000000e700000000d4d4d45050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005064640041006464644120005050505050a0a0a0a050505050505050505050505050505030000000000000
0020200000d4d4d4000000202020202020202020000000000000000000d4d4d55050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050646400140000010014505050505050501414141450505050505050505050505050505030000000000000
0020200000d4d4d4000000000000000000000000000000000000000000d4d4005050000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000506464c4c4c4b574c4c4646450505050501414141450505050505050505050505050505030000000505000
00000000003030300000009393930000939393939300000000000000002020005050000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000506464505050505050506464e7000000d400000000d4000000e70000000050505050505030000000505000
00000000000000000000008383830000838383838300005050000000002020005050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050000050505050505050009393000000d400939300d4000000000000000050505050505000000000505000
00000000000000000000000000000000000000000000005050000000000000005050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005000410000d4000000d40083830000410000838300d50000000000410000000000e4909000000000505000
00000000000000000000000000000000000000000000005050505000000000005050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005000140000d4000000d4000000000014000000000000000000000014000000010014040400000050505000
00b4b4b4b40000000000003030303030000000000000005050505000000000005050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050b4b4b4b4d4000000d400000000b4b4b400000000b4b4b4505050505000001400140404000000505050b4
b4505050502020202020205050505050202020205050505050505050000000005050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050505050505050505050000000005050500000000050505050505050505050505050505050505050505050
50505050504040405050505050505050505050505050502050505050505000005050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005050505050505050505000000000505050000000005050d4e700d45050505050505050505000d4d40097d4
0097d400000050505000000000d4d4000000d4d40000000020202050202000005050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005000e70000d4000000d400000000505050000000000000d40000d4505050505050505050e700d4000000d5
0000d500000000000000000000202000000000d40000000000000050000000005050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005000000000d4000000d400000000505050000000000000d400002050505050505050505000000000000093
93939300000000000000000000202000000000d400000000000000e7000000005050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005000000000d4000000d40000000000e700000000000000d400000050505050505050505000000000000093
93939300000000000000000000000000000000200000000000000000000000005050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050000041002020202020000000410000000000000000002000410050505050505050505000000000000083
83838300c4c40000005050b500000000000020200000970000000000000000005050000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005000001400141414141400000014000000b4b4b4b40000000014005050505050505050500000a600010000
000000005050000000505000c5c4c40000002000000076000000c4c4b50000305050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050c4c4c4c41414141414c4c4c4c4c4c4c45050505050505050505050505050505050505000007600040000
0000000050500000005050505050505050505050505050202020505000c5c4305050000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050b4b45050505050
b4b4b4b4505030303050505050505050505050505050505050505050505050405050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
50505050505050505050505050505050505050505050505050505050505050505050000000000000000000000000000000000000000000000000000000000000
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
00040201210101210104040000004a0100000000100000101010100000100000000000000000000000000010000000000000000000000000404000000000000000000000000000000000000000000101000000001010108000008000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808080808080808080808080808080808080808080808080808080808000000000000000000000000000000000000080808080808080808080808080808080808080808080808080808080808080808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000080808080707070000000000000000000000000000000000000007070708080808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000650000000000000000000000000008000000000000000000000000000000000000080807070707070000000000393939000000393939000000000007070707070808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000650000000000480000080000000000000000560008000000000000000000000000000000000000080807070739393900000000393939000000393939000000003939390707070808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000800000000480000550000000000080000000000000000000008000000000000000000000000000000000000080800000039393900000000383838000000383838000000003939390000000808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000808000000000000000000000008080000006500000800000008000000000000000000000000000000000000080600000039393900000000070707000000070707000000003939390000000608
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000008080808000000000000000000000000004800080800000008000000000000000000000000000000000000080600000039393900000000474747001d00474747000000003939390000000608
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000006500000008000000080800000000000000000008080000000008000000000000000000000000000000000000080600000039393900000000000000004700000000000000003939390000000608
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000484800000000000000080000000000000000080800000000650008000000000000000000000000000000000000080600000038383800000000000000000000000000000000003838380000000608
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008005600000000000000000000080000000000000000000000000000480008000000000000000000000000000000000000080600000007070700000000000000393939000000000000000707070000000608
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000006500000000006500000000000000000000000008000000000000000000000000000000000000080600000047474700000000000000393939000000000000004747470000000608
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000004800000000004800000055000000000000000008000000000000000000000000000000000000080600000000000000000000000000393939000000000000000000000000000608
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000008080808080800000000000000000000000000006500080800000008000000000000000000000000000000000000080807070707070707070707070700393939000707070707070707070707070808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000808000000000055000000000000004800000808000008000000000000000000000000000000000000080847474747474747474747474700393939004747474747474747474747470808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000065000008000000080048000008080800000000000000000008000000000000000000000000000000000000080847474747474747474747474700393839004747474747474747474747470808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000048000000000000000808000000000808000000000000000008000000000000000000000000000000000000080807070707070700000000000000020802000000000000000707070707070808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000006500000000006500000008080000000065000008000000000000000000000000000000000000080847474747474700001000000000474747000000000909094747474747470808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000004800000000004800000000080000000048000808000000000000000000000000000000000000080808080808080800004700000000474747000000004747470808080808080808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080800000000000000000000000000000000000000000000000000000808000000000000000000000000000000000000080808080808080808080808080202020802020208080808080808080808080808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808100000000000000000080808080000000000000000000000080808000000000000000000000000000000000000080808080808080808080808080808080808080808080808080808080808080808
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808480000000000000008080808080808000000000000000000080808000000000000000000000000000000000000080808080808080808080808080808080808080808080808080808080808080808
0808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808
080000000000000000000000000000000000000000000000000000000808080808070707000000000000004e090900000000000000000800000000000000000000000000000000000000000000000000081400007e0000000000000000000008081a0000000000000000007e004d4d0000004d00000000020000000808080808
080000000000000000000000000000000000000000000000000000000842424242070707000000000000104e4545000000000000000045000000000000003939000000000000000000000000000000004543000000000000002b000000000008084400000000000000000000004d4d0000004d00000000020000000808080808
080000000000000000000000000000000808080808080808080808080842424242070707000000000000464e454500000000002b0000001a17001400000038380000000000000000002b000000000000001a170000000000004300000000000808080000001400005a1a0000004d4d0000004d0000000002001a000808080808
0808080807070708080808080808080800004d0000000000000000000842424242080808080808080808080808080000000000430000004545004300000000000000000000000000004300000000000000454500000000000000000000000008080000000044000000440000004d4d0000004d00000000020044000808080808
08000008000000004d004d000000000800004d00000000000000000000424242427e00004d004d080808080808080000080808080808080808080808080808080800000000080808080808080000000808080808080808080808080800000008080808080808080808080808084d4d0008080808000000080808080808080808
08000008000000004d004d000000000800004d65000008080808000014000000000000004d005d007e000808080800000000000800007e0000000000000000000000000000000800000000000000000000000800002b00000000000000000008080808080808080808080808084d4d0002020808000000004d00007e4d000008
0800000800000000080808000000000800004d46000000020242080046000000000000000808000000000008080700000000004500000000000000002b000000000000000000452b000000000000000000004500004300000000000000000008080808000000007e00000000084d4d0000020208000000004d0000004d000008
08000008000000004d004d000000000800144d000000000000004208080808080000000042420800001800080807000000171a14000000000000001a4300140000000017001a5a430000000000140014001a5a00000000000000000000000008080707000000000000000000084d4d0000000208000000004d0000004d000008
08000000000000004d004d000000000800424d0700000000000000080000006507000000404042000042000808070000004545430000000000000045000045000000004500454500000000000043004500454500000000000000000000000009094e0000000000001a00000008024d0000000808000000004d1a00004d000008
08000000000000004d004d00000808080808080600000000000000421700004600020239393940000808080808080000080808080808000000080808080808080808080808080808000000080808080808080808000000080808080800000043434e001000000000440000000000060000000808000000004d4400005d000008
__sfx__
01020000000000664006610096100c6401c0101d1101c1101d110116101d110290401e1401e0301e130200401e16036660366603566034660346603466033640146401d640296402464000000000000000000000
180200002b62327553285532a5532b5532a5532a5532a553281432814327133261332612325133231232211321113207031e7031c7031f603186031260313603196031b603006030060300603000030000300003
01030000306502d6402a63029630266202462022610206101e6101b6101961017610156101460012600106000f6000d6000c6000b600000000000000000000000000000000000000000000000000000000000000
4103000000331043750000009335000001a371000000067504675093771a377003012360023600236000030100301000000000000000000000000000000000000000000000000000000000000000000000000000
91040000005160251604516085260c52612526165361a5361d53622546275462e546355463a5463d5563d5563d5563d5563d5563d5563d5563d5563d5563d5563d5563d5563d556296062860626606216061f606
010200002d6332e6432f6532e6532d6532b65333153311532e1332a133271532515323143201431e1331b133191331813317133151331413312123101230e1130d1130c1130b1130811306113041030210301103
a1040000126231362317623246472e647000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030400000561411610216302f6401e630356403f6453f647006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0102000014610166101a6201e630266302f6403f6402f6503166005060090400c0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002a660296602666025660216601d6601966016650002550065500255006450024500645002450064500235006350023500625002250062500225006250022500625002250061500215006150021500615
010200002e6622e6522e6522c6422c6422a6422864225642216421f6321d6321b63218632166321462214622106220f6120e6120b6120a6120961207612056120461202602016020060200002000020000200002
0102000023221282212d2212f22128621276212562123621216211e6211c4211b4211942115421134210a52107521055210262100001000010000100001000010000100001000010000100001000010000100001
01050000135172a6223a5372363218137121310412102121021220212203107031070010700107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700107
04020000225341e5341d53216530225341e5341d53216530007040000400002000000000400004000020000000002000020000200002000020000200002000020000200002000020000200002000020000200002
081e0000225341e5341d53216530225341e5341d53216530225341e5341d53216530225341e5342453225530225321e5321d53216532225321e5321d53216532225321e5321d53216532225321e5322453225532
491e00000a1540a1500a1400a1400a1320a1300a1210a1200d1540d1400d1320d1210c1540c1400c1320c1210a1540a1500a1400a1400a1320a1300a1210a1200d1540d1400d1320d1210c1540c1400c1320c121
491e00000a1540a1530a1420a1410a1340a1330a1220a1210d1540d1430d1320d1210c1540c1430c1320c1210a1540a1530a1420a1410a1340a1330a1220a1210d1540d1430d1320d1210c1540c1430c1320c121
001e00000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c04300000000000000024615000000000000000
091e000018100181001810018100191001a1001a10000001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000011810018100181101813118161
091e00001a1511a1321a1211a1121c1421c1321d1421d13219151191321912119112161421514213142111420e1510e1320e1210e112101421013211142111320d1510d1310d1220d11208151081310812108112
111e00001a1511a1321a1211a1121c1421c1321d1421d13219151191321912119112161421514213142111420e1520e1321115211132101521013210122101120e1520e132111521315210152101321012210112
902800200a5500a5550a5400a5450a5300a5350a5200a5250d5500d5450d5300d5250c5500c5450c5300c5250a5500a5550a5400a5450a5300a5350a5200a5250d5500d5450d5300d5250c5500c5450c5300c525
5828000016755167351975519735187551873518725187151675516735197551b7551875518735187251871516755167351975519735187551873518725187151575515735157251571516755167351875519755
0028002011043000000000000000186150000000000000000c04300000000000c043186150000000000000000c043000000000000000186150000000000000000c04300000000000c04318615000000000018615
113400001655516555165351653516525165251651516515155551555515535155351552515525155151551516555165551653516535165251652516515165151755517555175351753517525175251751517515
91340000274452e445294452a4452f4452e4452c4452a445264452e445294452a4452c4452a4452944526445274452e445294452a4452f4452e4452c4452a445264452f445294452c4452c4052c4452944526445
03340010086650000038665000000866500000386650000008665000003866500000086650e073386650e073086000000038600000000860000000386000000008600000003860000000086000e000386000e000
153400002240022400254002540024400244002540025400224002240025400254002440024400274002740022445224252544525425244452442525445254252244522425254452542524445244252744527425
053400000a5750a5750a5650a5650a5450a5450a5250a52509575095750956509565095450954509525095250a5750a5750a5650a5650a5450a5450a5250a5250b5750b5750b5650b5650b5450b5450b5250b525
a53400000f4651246516465114650f4651246516465114650f465124651646511465174651446516465124650f4651246516465114650f4651246516465114651746514465164651246511465164651446517465
5d3400001b455234552345522455234551e455204551d4551b455224551d4551e4552345520455224551e4551b455234552345522455234551e455204551d4551b45522455204551e4551a455204551e4551d455
951a000027445274222e4452e4222c4452c4222a4452a42226445264222c4452c4222a4452a422294452942227445274222f4452f4222e4452e4222c4452c42226445264222e4452e4222c4452c4222a4452a422
591a00200e4421544210442114420e4421544210442114420d442154421044211442164421544213442114420e4421544210442114420e4421544210442114420d4421644210442134420d442154421144210442
011a00200c0000c0530c0530c053246350c0530c05318f000c0530c0530c0530c053246350c0530c0530c0000c0000c0530c0530c053246350c0530c0530c0000c0530c0530c0530c053246350c0530c0530c053
141a000016152161321915219132181521810018157181001615216132191521b1521815218153181531815316152161321915219132181521810018157181001515215132151221511216152161321815219153
1534000016335113350d3350c3350d335113350a3350d33516335113350f335113351233514335123351133516335113350d3350c3350d335113350a3350d33516355163351135519355163551d3551835519345
593400000d4500c4500b4500a4500d4500c4500b4500a4530d4520c4520b4520a4520d4520c4520b4520a4530d4520c4520f4520c4520d4520c4520f4520c452104521043210412104122540024400274000d373
153400001915018150171501615019150181501715016153191521815217152161521915218152171521615319152181521b1521815219152181521b152181521c1521c1321c1121c1122510024100271000d173
110d00100045500455004550045500455004550145201452044520445202452024520545205452024520245200400004000040001400044000240005400024000040000400004000140004400024000540002400
010d00200c0730e0730c0730e073246750c0730c0730c0730c0730c0730c0730c073246750c07324675246750c0730c0730c0730c073246750c0730c0730c0730c0730c0730c0730c073246750c0732467524675
110d000002462024620246202462024520245202452024520244202442024420244202432024320243202432024220242202422024220241202412024120241202463004630b4530945307443054430000000000
011000003117035170272532b2532b2532b2532b2002b2000c2030c2030c2030c203242050c2030c2030c203002000020000200272002b2002b2002b200002000020000200002000020000200002000020000200
0128001008635000002c6150000008635000002c6150000008635000002c61500000086350e0432c6150e043086000000038600000000860000000386000000008600000003860000000086000e000386000e000
b12800001425519255152551425514255192551525514255142551b2551525514255142551b2551525514255142551c2551525514455154551c455194551545519455214551a455194551a455214552045519255
c52800081462515625196251462514625156251962514625006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000000000000000000000000000
9428000808265092650d2650826508265092650d26508265002050020500205002050020000200002000020000200002000020000200002000020000200002000020000000000000000000000000000000000000
d12800002c355313552d3552c3552c355313552d3552c3552c355333552d3552c3552c355333552d3552c3552c355342552d2552c2552d25534255312552d2553145539455324553145532455394553845531255
d42800000f344163441134412344173441634414344123440e3441634411344123441434412344113440e3440f344163441134412344173441634414344123440e3441734411344143441734414344113440e344
882800002633425334263342533423334223342333421334283342633425334263342533423334223342333428344263422534426342233442234223344213422834226342253422634225342233422234222322
8c1400002635226352253522535223352233522235222352263522635225352253522335223352223522235226352263552535225355233522335522352223552835028352263502635225350253522335023352
3c1400000e1220e1220d1220d1220b1220b1220a1220a1220e1220e1220d1220d1220b1220b1220a1220a1220e1220e1250d1220d1250b1220b1250a1220a12510120101220e1200e1220d1200d1220b1200b112
00141020000000000000000000000000000000000000000000000000000000000000000000000000000000002c625086252c625086252c625086252c625086252c625086252c625086252c625086252c62508625
8c1400002333023330233322331023310233122390023900239002390023900239002390023900239002390023900239002390000000000000000000000000000000000000000000000000000000000000000000
491a0000295511d5531d1521d15524152241552915229155281522815524152241552413524115281522815527152271552315223155231352311527152271552615226155221522215522135221152211522115
611a000000000000001d1521d155241522415529152291552b1522b155241522415524145241152b1522b1552d1522d155261522615526145261152d1522d1552c1522c1552c1452c1252c1152c1152c1002c100
59500000227351d7351973518735197351d7351673519735227351d7351b7351d7351e735207351e7351d735227351d7351973518735197351d735167351973522735227151d7352573522735297352473525735
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0504000000000000000000000000000000000000376043710007609376000061a37600006006761b6731b6771b4731b67700307172751767709307000061a3710000000670006770000600006000060000000000
010200001825014240112400f2300d2200c2100a2100c0100a0500905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000023676236762267621666206661e6561c6561b646196461663614636126360f6360d6260b62608626066260462601616016160061603606016060160611606106060c0061800624006000060000600006
00010000216732266322653206531b65315653116430e6430b6430a64309633096330962309623096130661305613000030000300003000030000300003000030000300003000030000300003000030000300003
__music__
01 0e0f4344
00 0e101112
00 0e101113
00 0e101114
00 0e0f1144
02 410f4344
01 15424344
00 15164344
02 15161744
01 2c2b6b44
01 2a2c6b44
02 2b2a2c6a
01 2b2d2a2c
00 2e2d2a2c
00 2f2a4344
00 302d2a2c
00 3132332a
02 342a2c44
01 18424344
02 18194344
01 191a4344
00 191a1844
00 1a1b185b
00 1a1d1c5b
00 1a1e1c5b
02 1f424344
01 191a4344
00 191a1844
00 1b35181a
00 1a1d1c5b
00 1a1e1c5b
00 351a1c5c
02 361a1c5c
01 20614344
02 20216244
01 20216244
01 20212244
00 20212223
00 24252123
00 26274344
00 26274344
00 26272044
02 26272022
04 28274344
01 15424344
00 15164344
02 15371744

