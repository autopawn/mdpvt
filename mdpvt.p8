pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
// complete your disassembly drone
// training!

// game made by autopawn,
// crjonch, remi mixer, and
// miszuk.
// thanks to the mdp discord
// server.
// character graphics in label
// commissioned to @marshimiiu.

// if you don't see more
// comments, they were stripped
// to comply with the
// compression capacity. check
// github.com/autopawn/mdpvt

-- current level.
-- stored on dget(1)
level = 0
-- music to play for each level
-- in order, starting from 1
level_music =
  split"0,0,0,12,16,16,24,24,33,41,52,56"

-- music to play for each level
-- dialogs, in order.
level_dialog_music =
  split"6,6,6,9,9,9,22,22,30,-1,50,50,58"

-- music pattern index is stored on dget(7)

-- controller option stored on dget(8)
jumpk = 5

-- hard difficulty enabled?
-- (o or 1), stored on dget(6)
hard = 0

-- this level dialog was shown?
-- stored on dget(2)
dialog_shown = 0

-- time on the clock, minutes
-- and frames.
-- stored on dget(3) and dget(4)
timer_m, timer_f = 0, 0

-- death counter tally (player)
-- stored on dget(5)
deathcount = 0

-- frame for animations
frame = 0

-- level on which the player
-- gets the rockets
first_rocket_level = 4

-- level on which the player
-- gains the ability to break
-- cracked bricks
break_bricks_level = 7

-- frames of input transition.
black = 9

-- camera does the thug shaker
camera_shake_x, camera_shake_y, camera_shake_time = 0, 0, 0

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
  if dialog_shown == 1 then
   if level == 10 then
    music(level_music[level], 0, 3)
   else
    music(dget(7), 0, 3)
   end
  end

  -- by default, go to main menu
  -- on next load
  dset(0, 0)
 end

 -- init the jumpkey menu option (twice to keep it the same)
 if dget(8) != 0 then
  jumpk = dget(8)
 end
 jumpkey()
 jumpkey()

 -- on main menu
 if level == 0 then
  menu_init()
  goto init_end
 end

 -- enable objects of the
 -- current level
 for x = 0,127 do

  for y = 60,63 do
   mset(x,y,0)
  end

  for y = 0,59 do
   t = mget(x,y)

   -- ambivalent death-blocks
   if t==3 or t==6 then
    t = t+2-t*hard
    mset(x,y,t)
   end

   -- look at the tile under
   -- for a level marker
   levelmark = -1
   nxt = mget(x,y+1)
   if 240<= nxt and nxt<=252 then
    levelmark = nxt-239
    if nxt==252 and level<=10 then
     levelmark = level
    end
    -- mset(x,y+1,0)
   end

   level_ok = levelmark == level

   if t==16 then
    if level_ok then
     pla.x, pla.y = 8*x, 8*y
    end
    mset(x,y,0)
   elseif fget(t, 4) then
    if level_ok then
     w = create_worker(
       x*8,y*8,t)
     workers_req += w.lives
    end
    mset(x,y,0)
   elseif t==253 then
    if level_ok then
      add_electroball(8*x,8*y,0)
    end
   elseif t==254 then
    if level_ok then
     add(spawn_points, {8*x,8*y})
    end
    -- mset(x,y,0)
   else
    -- non-object tile with a
    -- level marker gets either
    -- deleted or duplicated
    if levelmark != -1 then
     if level_ok then
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
   elseif t == 14 then
    add(void_blocks, {x,y})
   end
  end
 end

 -- last levels don't have workers_req
 if level > 10 then
  workers_req = -1
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
 dset(7, stat(54))
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

function jumpkey()
 if jumpk == 2 then
  jumpk = 5
  menuitem(1,"jump key: ❎",jumpkey)
 else
  jumpk = 2
  menuitem(1,"jump key: ⬆️",jumpkey)
 end
 dset(8, jumpk)
 return true -- keep menu open
end

function _update()
 if level==0 then
  menu_update()
 elseif dialog_on then
  dialog_update()
 else
  foreach(rockets, rocket_update)
  player_update()
  foreach(workers, worker_update)
  foreach(particles, particle_update)
  foreach(railshots, railshot_update)
  foreach(knives, knife_update)
  foreach(electroballs, electroball_update)
  shake_update()
  void_blocks_update()
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
    spr(87+ty%2*16+tx%2,
      8*tx,8*ty)
   end
  end
 end
 palt(0, true)

 -- draw map
 map()

 if (level == 13) cls()

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
  rectfill(unpack_split"0, 0, 127, 127, 0")
 elseif black > 6 then
  fillp(0b0101000001010000.1)
  rectfill(unpack_split"0, 0, 127, 127, 0")
 elseif black > 4 then
  fillp(0b0101101001011010.1)
  rectfill(unpack_split"0, 0, 127, 127, 0")
 elseif black > 2 then
  fillp(0b1111101011111010.1)
  rectfill(unpack_split"0, 0, 127, 127, 0")
 end
 fillp(0)

 -- death counter
 d = "deaths:"..deathcount
 print(d, 1, 2, 9)
 print(d, 1, 1, 10)

 -- kill count
 if workers_req != 0 then
  if workers_req == -1 then
   s = "kills:WHO CARES?"
 	else
   s = "kills:"..workers_dead
     .."/"..workers_req
 	end
  print(s, 1, 9, 9)
  print(s, 1, 8, 10)
 end

 -- speedrun clock
 secs = timer_f\30
 centis = flr(timer_f%30*3.333)
 c1, c2 = centis\10, centis%10
 s1, s2 = secs\10, secs%10
 tstr = timer_m..":"..s1..s2
   .."."..c1..c2

 print(tstr,100,2,6)
 print(tstr,100,1,7)
 spr(15,92,1)

 ::draw_end::
end

function decor_tiles_update()
 px, py = pla.x\8, pla.y\8
 my = min(py+8, 59)
 for x=px-8,px+8 do
  for y=py-8,my do
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
 return min(max(-1,z),1)
end

-- check whether the rectangle
-- is colliding with tiles
-- that have the given flag on
function rectcol(x, y, w, h, fl)
 -- note: backslash for integer
 -- division.
 xi, xf = x\8, (x+w-1)\8
 yi, yf = y\8, (y+h-1)\8

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
 xi, xf = x\8, (x+w-1)\8
 yi, yf = y\8, (y+h-1)\8

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
function objcol(o1, o2, xtra)
  xtra = xtra or 0
  o1x, o2x = flr(o1.x), flr(o2.x)
  o1y, o2y = flr(o1.y), flr(o2.y)
  return o1x + o1.w + xtra > o2x and
    o2x + o2.w + xtra > o1x and
    o1y + o1.h + xtra > o2y and
    o2y + o2.h + xtra > o1y
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
 rx, ry = o.vx, o.vy

 while abs(rx)>0.1 or abs(ry)>0.1 do
  sx,sy = step(rx),step(ry)

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
   o.vx, o.vy = 0,0
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
 dx, dy = (x - o.x)/4, (y - o.y)/4
 if abs(dx) < 128 and
   abs(dy) < 128 then
  dx,dy = veclimit(dx, dy, s)
  if relative then
   dx += o.vx
   dy += o.vy
  end
  o.vx, o.vy = dx, dy
 end
end

function inside_camera(x, y, far)
 dx, dy = abs(x - pla.x), abs(y - pla.y)
 return dx <= (far and 129 or 86)
   and dy <= 102
end

function sfx_inside(x, y, s)
 if inside_camera(x, y, true) then
  sfx(unpack_split(s))
 end
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
  if btnp(jumpk) then
   pla.vy -= 3
   pla.animw = 7
   sfx(6 + tonum(pla.ground))
  end

  -- shoot
  if btnp(🅾️) and #rockets==0
    and level >= first_rocket_level
    then
   player_shoot()
  end

  -- limit vertical speed
  if pla.vy < -4 and not pla.slam then
   pla.vy = -4
  end

  -- ground slam activate
  if not pla.ground then
   if (pla.y > 480 or btnp(⬇️)) and
     not btnp(⬆️) and
     not pla.slam then
    sfx(8, -1, 0, 8)
    pla.slam = true
   end
   pla.animb = 0
  end

  if pla.slam then
   if pla.ground then
    pla.slam=false
    if pre_vy<8 then
     sfx(8, -1, 21)
    elseif pre_vy>8 then
     sfx(62)
     add_blood(pla.x+4,pla.y+16,
       split"1,5,6", rnd(6)+12,
       rnd(split"30,35,40,45"))
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
        pla.slam=true
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
   and rectinside(pla.x, pla.y, pla.w, pla.h, 2)
   or pla.y > 1000 then
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
   pla.x+3,pla.y+9,split"5,6,9,10")
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
   sfx(unpack_split"8, -1, 9, 13")
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
      w.stun, w.animhit, w.vx = 90, 6, 0
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
  add_blood(brick.x+4,brick.y+4,split"1,5,6,7", rnd(6)+4)
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
 r.facer, r.deflected = facer, true
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
 sfx(unpack_split"2, -1, 0, 15")
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
  worker.blood = split"8,5,6"
  worker.facedir = 1
 elseif 84<=id and id<=86 then
  worker.type = "hunter"
  worker.touchdeath = false
  worker.sprite = 84
  worker.blood = split"8,13,6"
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
  worker.blood = split"5,6,13"
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
  worker.blood = split"6, 7, 8"
  worker.facedir = 0
  worker.blink = 0
 else
  worker.type = "normal"
  worker.sprite = 20
  worker.blood = split"1,5,6"
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
 sfx(2, -1, 15)
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
    music(49)
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
   sx, sy = worker.startx, worker.starty
  else
   spawn = rnd(spawn_points)
   sx, sy = unpack(spawn)
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
    objcol(pla, worker, 1) and
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
   if objcol(pla, worker, 1) and
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
      add_electroball(worker.x, worker.y, 2)
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
      worker.tx, worker.ty = pla.x+1, pla.y+4
      sfx(unpack_split"10, 1, 0, 24")
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
     sfx(unpack_split"10, -1, 24")
    end
    -- destroy bricks
    for brick in all(cracked_bricks) do
     if objinside(brick, hand.x+3,
       hand.y+3, 11) then
      hand.vx /= 4
      hand.vy /= 4
      brick_break(brick)
      sfx(unpack_split"10, -1, 24")
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
 hand.vx, hand.vy = 0, 0
 pm1 = 1 - p
 hand.x = pm1*hand.x + p*(worker.x-23+16*h)
 hand.y = pm1*hand.y + p*(worker.y+9)
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
   print(sub(worker.hp+100, 2, 3),
     worker.x+1,
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
  sfx_inside(railshot.x + 0.5*railshot.w, railshot.y, "5")
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
 a, b = 1, 161
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
  r.x, r.w = r.x-a, a
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
 sfx_inside(railshot.x + 0.5*railshot.w, railshot.y, "4")
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
   spd=3+2*hard
   sfx_inside(kni.x, kni.y, "1, -1, 16")
   px, py = pla.x+3+rnd(16)-8, pla.y+10+rnd(16)-8
   objaimto(kni,px,py,spd)
   kni.tx, kni.ty = kni.vx/spd, kni.vy/spd
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
     kni.y-kni.ty+1, 1,
     6+frame%2)
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
   owner = worker,
   x = worker.x+2,
   y = worker.y+5,
   vx = 0,
   vy = 0,
   w = 3,
   h = 3,
   tx = cos(i/nknives)*worker.facedir,
   ty = sin(i/nknives),
   t = i*2,
   disabled = false,
  }
  add(knives, kni)
 end
 sfx_inside(worker.x, worker.y, "3")
end

-- mode 0: waiting to be in_cam
-- mode 1: going towards the player (permanent)
-- mode 2: going towards the player (decay at certain time)
function add_electroball(worker_x, worker_y, mode)
 add(electroballs, {
   x=worker_x+2, y=worker_y+10, t=0,
   vx=0, vy=0, w=4, h=4, mode=mode})
end

function electroball_update(ball)
 if ball.mode==0 then
  if inside_camera(ball.x,ball.y) then
   ball.mode = 1
  end
 elseif ball.t > 270 then
  del(electroballs, ball)
  add_blood(ball.x+2, ball.y+2, split"7,10,12")
 else
  ball.t += 1
  -- Accelerate towards the player
  endgame = tonum(level > 10 and hard)
  acc = endgame * 0.1 + 0.03
  spd = 3 + 2*hard
  objaimto(ball, pla.x+2, pla.y+8, acc, true)
  ball.vx, ball.vy = veclimit(ball.vx, ball.vy, spd)
  if objcol(pla, ball) then
   player_die()
  end
 fset(2,0,true)
 objmove(ball)
 fset(2,0,false)
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
   color=split"0,5,8",
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
 camera_shake_x, camera_shake_y = rnd(strength), rnd(strength)
 camera_shake_time = max(camera_shake_time, time)
end

function shake_update()
 if camera_shake_time<=0 then
  camera_shake_y, camera_shake_x = 0, 0
 end
 if camera_shake_time > 0 then
  randvals = split"-2,-1,1,2"
  camera_shake_y, camera_shake_x =
    rnd(randvals), rnd(randvals)
  camera_shake_time-=1
 end
end

-->8
-- dialog texts

dialogs = {
{ -- level 1
 "∧ zzzzzz... zzzzzz... ∧\n∧ zzzzzzzzzzzz... ∧",
 20,
 "*beep*",
 22,
 "uh... where...",
 10,
 "it took you some time to\nwake up rookie.",
 20,
 "who are you?\nwait, who am i?",
 10,
 "you are a formerly useless\nworker drone that's been",
 "reset and retrofitted into\na state of the art",
 "disassembly drone. i am\nyour supervisor, here to",
 "oversee your virtual\ntraining.",
 23,
 "cool! what'll i be\ndisassembling?",
 11,
 "other worker drones,\nmostly.",
 22,
 "oh...",
 10,
 "to start, let's test your\nwings. input ❎ to flutter.",
 "once you're comfortable,\nnavigate through the next ",
 "area and avoid the death\nblocks.",
 20,
 "what do you mean by...",
 10,
 "they'll kill you.",
 24,
 "kill me!?",
 11,
 "don't worry, it's just a\nsimulation.",
 10,
 "...",
 "the pain is very real\nthough...",
 22,
 "*gulp*",
},{ -- level 2
  10,
 "excellent!",
 "but try to be faster from\nhere on rookie.",
 12,
 "management is watching.",
 10,
 "now, i need you to\ndisassemble all the drones",
 "in this area and reach the\ngoal.",
 20,
 "i know it's my job and\neverything... but how do i",
 "do that exactly?",
 11,
 "simple! just touch them\nand let your programming",
 "handle the rest.",
},{ -- level 3
 20,
 "so...\nis there a reason why i'm",
 "disassembling all these\nworker drones?",
 12,
 "it's your job.\ndon't question the company.",
 23,
 "`kay!",
 10,
 "now some drones may resist\nan unscheduled disassembly",
 "and be unpredictably armed.\nto demonstrate this i've",
 "been instructed to add\nangsty teenagers with",
 "railguns...",
 12,
 "... for some reason.",
 22,
 "what's a railgun?",
 11,
 "kill 'em all, rookie!",
},{ -- level 4
 10,
 "alright, next on the list\
is weapons.",
 "you're doing good, but\
it's about time you start",
"using your\nbrai..weaponry.      \r███",
 20,
 "hey!",
 10,
 "i've enabled your rocket\
launcher.",
 "input 🅾️ to shoot.\
you don't have to worry",
 "about ammo, but you do\
have to detonate them",
 "manually by making a\
second 🅾️ input.",
 "here's a few targets to\
practice on.",
11,
 "knock 'em dead, rookie!",
},{ -- level 5
 10,
 "having fun rookie?",
 20,
 "feels like there's a\
correct answer here, but",
 21,
 "yeah!",
 11,
 "correct answer! looks like\
there's no need for any",
 "behavioral correction,\
good for you!",
 22,
 "... is that something i\
should worry about?",
 11,
 "since you're having fun,\
no.",
 23,
 "cool!",
 10,
 "alright rookie, time to\
spice things up a bit. not",
 "every drone is going to\
sit there and take it if",
 "they see something coming\
at them.",
 "you might have to think\
outside the box for these",
 "drones.",
 14,
 "hopefully that tip didn't\
go *over your head*.",
 10,
 "good luck!",
},{ -- level 6
 10,
 "since you seem to have\
your aiming down, time to",
 "see if you can still shoot\
when there's return fire",
 "added back into the mix.",
 22,
 "does this mean more\
railguns?",
 11,
 "*0ing!♪*",
 10,
 "additionally, workers are\
designed to work together,",
 "so you may have to deal\
with teams that cover each",
 "other's weaknesses.",
 11,
 "chin up though, if you're\
outnumbered then it's",
 "almost a fair fight!",
},{ -- level 7
 10,
 "okay rookie, now here's a\
real threat for you:",
 "in this test there's\
a drone that'll really",
 "test your mettle.\
it has telekinetic",
 "abilities and flight...",
 12,
 "among other things.",
 22,
 "wait, that sounds like a\
whole lot for a worker.",
 "doesn't that seem a little\
excessive?",
 14,
 "...rookie, i'm only going\
to say this once:",
 13,
 "this simulation contains\
only a fraction of what",
"you may encounter outside.",
 10,
 "best you start preparing\
now.",
 24,
 "...\
wait!!",
 12,
 "what? did i scare you?",
 20,
 "yeah...\r██...no?",
 12,
 "...",
 20,
 "...",
 22,
 "i just don't see the way\
out of this room.",
 11,
 "oh yeah, almost forgot...",
 10,
 "i've disabled some safety\
restrictions on your",
 "rockets and dive protocol.\
you should be able to",
 "break through brittle\
surfaces now.",
 20,
 "...dive?",
 10,
 "...yes? that thing you can\
do once you gain enough",
 "height and descend (⬇️)?",
 12,
 "surely you've already\
figured that out, right?",
 20,
 "oh! yeah totally!",
 10,
 "it's a powerful maneuver\
that allows you to punch",
 "through even the strongest\
drones. keep that in mind",
 "for when explosives are\
not enough.",
},{ -- level 8
 11,
 "good going rookie!",
 20,
 "you know...\
i kinda like this hat.",
 10,
 "it's a part of you that\
couldn't be removed.",
 "doesn't matter though,",
 14,
 "THERE'S NO TRAINS WHERE\
YOU'RE HEADED.",
 23,
 "trains? oh i love trains!",
 10,
 "no you don't.\
forget i said any of that.",
 23,
 "choo! choo!\
all aboard the s\r◆☉⌂♪▒█⧗▤●░\r▤r웃♪●☉⌂😐♥⬇️▒",
 13,
 "\^w\^tstop talking.",
 "",
 11,
 "i think, since you're in\
such good humor, that",
 "you're ready to take the\
training wheels off!",
 24,
 "they weren't off before?!",
 10,
 "nope. what you fought\
before was restrained for",
 "introduction's sake.",
 11,
 "so now you're fighting two\
of them!",
 22,
 "huh",
 11,
 "at full strength!",
 24,
 "wait hold on!!",
 11,
 "good luck!",
},{ -- level 9
 20,
 "wow! what's all this?\
a party? for me!?",
 23,
 "*gasp* does that mean that\
i made it to the end?",
 11,
 "close, but not quite!",
 10,
 "the party is real.",
 14,
 "well, sort of...\
AS REAL AS IT GETS HERE.",
 10,
 "they've prepared for your\
attendance, even though",
 "you weren't invited.",
 11,
 "you can see where this is\
going...",
 24,
 "they're everywhere!",
 10,
 "use your surroundings to\
take cover.",
 "you can figure out the\
rest.",
},{ -- level 10
 14,
 "the time has come.\
i crunched all the numbers",
 "to compute the worst-case\
scenario.",
 10,
 "behold the most firepower\
a worker drone can muster!",
 "a sturdy worker, armed\
with retractable chainsaw",
 "arms and homing electrical\
projectiles!",
 20,
 "can you really call it a\
worker at this point?",
 10,
 "",
 20,
 "it's more like a mech\
with a worker in it.",
 12,
 "",
 22,
 "wait, is a robot inside a\
mech just a bigger robot?",
 20,
 "no, that's like calling a\
tank driver the whole tank.",
 22,
 "but that's not the same...\
uhh, my head hurts now!",
 14,
 "sorry, couldn't hear you\
over the magnificency of",
 "this engineering marvel.",
 10,
 "this is my magnum opus,\
just for you!",
 20,
 "it looks tough, but after\
all this training?",
 "i think i've got this.",
 21,
 "bring it on!",
}, { -- level 11
11,
 "phenomenal! couldn't have\
done that better myself!",
10,
"so, this next test is to\
train your ability to ",
"disengage in conditions of\
high mental stress and...",
12,
"`oh dear, what's this?\
this doesn't look good!'",

22,
"huh? what's going on??",

12,
"`the simulation is being\
attacked by some kind of..",
"virus! some horrible virus\
is coming your way!'",
"rookie you have to get out\
of there quickly!",
"`lest your mind be reduced\
to pulp, which would be",
"slightly worse!'",

24,
"\^w\^taaaaaaaaahh!!",

}, { -- level 12
 22,
 "is...is it gone?",
 "hey supervisor, can you\
still hear me?",
 10,
 "loud and clear rookie,\
you good?",
 22,
 "i think? what kind of\
virus was that?",
 24,
 "am i even safe in here?!",
 11,
 "oh there wasn't a virus.",
 20,
 "what.",
 10,
 "yeah management simply\
started a wiping function.",
 12,
 "sorry about the scare,\
i had to stay on script",
 "or i'll be on the chopping\
block.",
 11,
 "that does mean you've got\
fans higher up, that only",
 "happens to ones they like.",
 12,
 "... or they started doing\
it for fun.",
 23,
 "glad i wasn't in any real\
danger then!",
 12,
 "whatever helps you sleep..",
 14,
 "..doesn't quite work here,\
you get what i mean.",
 23,
 "haha! ignoring that!\
so i'm done here, right?",
 10,
 "nope. i can't stop the\
wipe now and you're only",
 "about halfway through now.",
 24,
 "oh come on!",
 10,
 "chin up rookie,\
it's the last stretch!",
 "all you need to do now is\
get out of the simulation.",
 20,
 "i remember a brittle floor\
on the room i woke up in.",
 11,
 "that's the ticket!",
 "now get going! if you've\
passed everything thus",
 "far there's no reason to\
fall here!",
 14,
 "keep a cool head in there,\
you're almost out.",

 },{ -- epilogue
 20,
 "am i... outside the test?",

 11,
 "yep, you made it!",
 "i can pull you out from\
here and we can call your",
 "training complete!",
 "you will be a great asset.\
i am very proud!",

 23,
 "d'aww thanks!",
 20,
 "but, i'm not sure i can\
kill in the real world.",

 11,
 "oh you'll do just fine!",
 "and if not, you'll surely\
shape up quick: its either",
 "drink drone oil or die\
from overheating out there!",

 24,
 "what? that sounds horrible!",

 11,
 "just wait until you try it\
yourself. once you get",
 "your hands on some warm,\
sweet-",

 21,
 "nevermind that sounds\
pretty cool!",
 11,
 "glad you got that solved!",
 10,
 "well, that's it, i hope to\
see you in the field!",
 11,
 "up and at 'em rookie!",
 0,
 "assigning roles: //\
user id: supi77uwu",
 "subject: rookie\
status: hired",
 "awaiting assignment\
[complete]",
 "[thank you for playing ♥]",
}
}

-->8
-- dialog system

-- current dialog
current_dial = {}

-- current line in dialog
dialog_l = 0
-- current char in dialog
dialog_c = 0
-- current dialog portrait
dial_portrait = -1
-- duration of the portrait so far
portrait_dur = 0

-- is a dialog currently playing?
dialog_on = false

-- start next dialog
function dialog_start(n)
 music(level_dialog_music[level], 0, 3)
 if n <= #dialogs then
  current_dial = dialogs[n]
  dialog_on = true
  dialog_next()
 end
end

-- read until the next dialog text
function dialog_next()
 dialog_l += 1
 while dialog_l <= #current_dial
   and type(current_dial[dialog_l]) == "number" do
  dial_portrait = current_dial[dialog_l]
  dialog_l += 1
  portrait_dur = 0
 end
 dialog_c = 0
 portrait_dur += 1

 if dialog_l > #current_dial then
  -- end game
  if level == 13 then
   -- finish game
   dset(0, 0)
   run()
  end
  dialog_on = false
  frame = -1
  music(level_music[level], 0, 3)
  return
 end
end

-- update the current dialog
function dialog_update()
 incomplete = dialog_c <
   #current_dial[dialog_l]
 if btnp(❎) or btn(🅾️) then
  if incomplete and not btn(🅾️) then
   dialog_c = 100
  else
   dialog_next()
  end
  sfx(13)
 elseif incomplete then
  dialog_c += 1
  sfx(13)
 end
end

function draw_portrait()
 s = dial_portrait
 if s>9 then
  chara, expre = s\10 - 1, s%10 - 1
  spr(80+2*chara,1,108,2,2)
  if expre >= 0 then
   rectfill(unpack_split"6,116,13,123,0")
   spr(112+4*chara+expre,6,116)
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
 text1 = sub(line1, 1, dialog_c)

 -- black background on negative portrait
 if dial_portrait < 0 then
  cls(0)
 end

 rectfill(unpack_split"0,106,127,127,0")
 rect(unpack_split"0,107,17,124,7")
 rect(unpack_split"19,107,127,124,7")

 -- draw next icon
 print("❎",120,123, 2)
 print("❎",120,122+(frame\8)%2,
   8)

 -- draw a single line
 draw_portrait()
 print(text1,21,109, 10)
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
 xx, zz = rx*cosa, rz*sina
 return sqrt(xx*xx + zz*zz),ry
end

-- position in view space.
function viewpos(x,y,z)
 vx = x*cosa-z*sina
 vz = x*sina+z*cosa
 return 64+vx, y, vz
end

function oval3d(x,pms)
 y,z,rx,ry,rz,c = unpack_split_tonum(pms)
 vx,vy,_ = viewpos(x,y,z)
 vrx,vry = viewrad(rx,ry,rz)
 ovalfill(vx-vrx+0.5,vy-vry+0.5,
   vx+vrx-0.5,vy+vry-0.5, c)
end

function cili3d(x,pms)
 y,z,rx,ry,rz,c = unpack_split_tonum(pms)
 vx,vy,_ = viewpos(x,y,z)
 vrx,vry = viewrad(rx,ry,rz)
 rectfill(vx-vrx+0.5,vy-vry+0.5,
   vx+vrx-0.5,vy+vry-0.5, c)
end

function draw_arm(s, front)
 oval3d(s*6,"20,0,4,3,4,6")
 oval3d(s*11,"21,0,4,3,4,6")
 oval3d(s*14,"22,0,4,3,4,6")
 oval3d(s*17,"24,0,4,4,4,7")
end

function draw_leg(s)
 if cosa<0 then
  oval3d(s*6,"50,3,4,4,8,10")
 end
 oval3d(s*4,"36,0,3,4,3,6")
 oval3d(s*5,"40,1,3,4,3,6")
 oval3d(s*6,"44,0,3,4,3,6")
 if cosa>=0 then
  oval3d(s*6,"50,3,4,4,8,10")
 end
 cili3d(s*6,"52,3,4,2,8,10")
 cili3d(s*6,"54.5,3,4,0.4,8,9")
end

function draw_led(phi,y)
 px, pz = cos(phi)*9, sin(phi)*9
 vx,vy,vz = viewpos(px,y,pz)
 if vz >= 0 then
  col = 10
  if (frame < 80) col = 0
  circfill(vx,vy,1,col)
 end
end

function draw_flask()
 cili3d(0,"23,-17,2,4,2,5")
 cili3d(0,"23,-17,2,3,2,10")
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
 oval3d(x,"10,7,1,2,1,9")
 oval3d(x,"11,7,1,1,1,10")
end

function draw_rookie()
 side, front = sgn(sina), cosa>=0

 -- back arm
 draw_arm(-side)
 draw_leg(-side)

 if front then
  -- back tail
  draw_tail()
 end

 -- neck
 cili3d(0,"16,0,3,2,3,9")

 -- body
 oval3d(0,"25,0,6,7,5,6")
 oval3d(0,"30,0,5,4,5,6")

 -- head
 oval3d(0,"10,0,9,6,9,7")
 cili3d(0,"9,0,9,3,9,6")
 if front then
  oval3d(0,"10,18,9,4,9,0")
 end
 if cosa > 0.75 and frame > 79 then
  oval3d(0,"14,8,3,1,1,7")
  draw_eye(-3)
  draw_eye(3)
 end

 -- cap
 oval3d(0,"7,6,9,1,9,5")
 oval3d(0,"4,0,9,4,9,5")
 cili3d(0,"5,0,9,3,9,5")

 -- lights
 for i=0,4 do
  draw_led(0.65+0.05*i,
    4-min(i%4,1))
 end

 if front then
  -- draw zipper
  oval3d(0,"21,3,2,3,1,9")
  cili3d(0,"23,4,2,3,1,9")
  cili3d(0,"23,4,0.5,2,1,6")
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
 cosa, sina = cos(cama), sin(cama)

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
  music(0, 0, 3)
 end
end

function printx(s,x,y,c)
 dx = flr(rnd(2.2)-0.6)
 dy = flr(rnd(1.6))
 for m = -1,1 do
  print(s,x+m*dx,y+m*dy,c)
 end
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
  print_unpack_split"murder drones, 38, 2, 9"
  if menu_saved_level == 0 then
   print_unpack_split"continue,38,84,5"
  elseif menu_saved_hard == 1 then
   print_unpack_split"continue (hard),38,84,7"
  else
   print_unpack_split"continue (normal),38,84,7"
  end
  print_unpack_split"new game (normal),38,94,7"
  print_unpack_split"new game (hard),38,104,7"
  printx("∧", 28, 84+10*menu_option, 9)

  rectfill(unpack_split"-1, 118, 128, 125, 0")
  rect(unpack_split"-1, 118, 128, 125, 5")
  print("FANGAME BY AUTOPAWN, MISZUK, CRJONCH & REMI MIXER. MUSIC BY REMI MIXER. SPECIAL THANKS TO THE MDP DISCORD SERVER!",
   128-(frame-80)%580, 119, 5)
 end
end
-->8
-- void blocks

function void_blocks_update()
 void_blocks_2={}
 for p in all(void_blocks) do
  x,y = unpack(p)

  -- don't reach outside
  if (y > 58) return

  in_cam = inside_camera(8*x,8*y)

  fs = frame%(2*level-10) -- only for level 11 and 12
  if fs==0 or (fs==6 and (hard == 1 or not in_cam)) then
   if (in_cam) sfx(60, -1, 6)
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
-- misc

function unpack_split(s)
 return unpack(split(s))
end

function print_unpack_split(s)
 print(unpack_split(s))
end

function unpack_split_tonum(s)
 v = split(s)
 foreach(v, tonum)
 return unpack(v)
end

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
05556000055666000556066000556670766666090ca77ac70a7cc7a0a7caac70000000000000000055dd00000770070000070077955555590956659669566596
5556700055660670550660675556070000066650ca7cc7aca7caac7a7ca77ac70000000000000000500dd0000dd0700700700770955005596960069069600696
0556700050606070566067070666700000666660ca7cc7aca7caac7a7ca77ac700000000000000000000dd0005ddd0770dd0dd00955005596960069009600690
00670000006670000066070000770000006606607ca77ac00a7cc7a007caac7a000000000000000000005dd05500ddd0ddddd5dd955005590956659609566590
00770000000770000007000000070000aaa0aaa007caac0a70a77a00007cc7a05555555500000000000000dd500005dd55000000a990099a0099996006999960
00700000000700000007000000000000aaa0aaa0007cc0a0070aa00a70077a0044444444000000000000000d0000000050000000aaa00aaa0066000000600600
5555555500005f00000000000000555000070070077777777777777777777770eeeeeeeeeeeeeeee660000000000000000000000000000005111111555555555
5444444400005f00000000000555555007227887077777777777777777777770e111111ee111111e006600000000000000006600000000005dd00dd5d1d1d1d1
4444444400005f000000000055555550dd222788767777777777777777777767e111001ee100111e000066000000660000665f660000000051111115d1d1d1d1
4444444400005f0000000055aa555500dd72dd70766777777777777777777667e111001ee100111e00005f6600665f6666005f00660000005dd00dd501010101
4444444400005f00000006559aa555000887ddd0666666666666666666666666e111001ee100111e00005f0066005f0000005f00006000005111111501010101
4444444400005f000000666009aa550008880d00660666666666666666666066e111001ee100111e00005f0000005f0000005f00000600005dd00dd5d1d1d1d1
4444444400005f0000066600009a500000850500000500000000000000005000e111001ee100111e00005f00f444f44400005f000000660051111115d1d1d1d1
dddddddd00005f0000066d000000000000005000000500000000000000005000e111111ee111111e00005f004f444f4400005f00000000665dd00dd555555555
00200000000000000000000000000000088888000888880008888800ee101ee101eee10ee566665e159922510000500000000080000000000077770000888800
0282040000000000000000555550000008a8888808a8888808a88888000000000eeeee00e511115e5c9b22850000500000000080000000000707707008000080
22284455555500000000555555555000aaaaaa88aaaaaa88aaaaaa8801eee1000eeeee00e111111e5ccbb8850000500008088080555555507000000780000008
02244500aa0a5000000555aa5aa5aa00622222aa622222aa682282aa0eee00000eee0000e111111e555555550000500008080080555555507700007780088008
00445aa59956a500005aa5a95a95a95008080222000002220088022201ee01ee01ee01eee111111e666566650000500088088080000000007700007780088008
04450a9555556500005a95555555555078080722780887227800872200000eee00000eeee111111e667766770000500000000080660666667000000780000008
005a0555555565000555551111111111277777222777772227777722ee0e0eeeee000eeee111111e667766770000500088000880660666660707707008000080
005a5555555550000555511111111110227777222277772222777722e10e0eee000001eee111111e157775770000500008888800000000000077770000888800
05055555550005000555600000000600025652220ffffff000000000000e01ee01e10000f444444f0ffffff00ffffff00ffffff00ffffff00005000000050000
0555555550000500006600990099060002555222f55aa57f000000000eee00000eee0eeef444464ffa5aaa7ffaa5a57ffaaa5a7ff588887f0060500000005000
0555550990099500006600aa00aa060082888287f55aa55f000000000eeeee000eee0ee1f444444ff555555ff555555ff555555ff588885f0060500000005000
0555000aa00aa550007770aa00aa070070555522f55aa57f000222000eeeee00000000000ffffff0faa5a57ffaaa5a7ffa5aaa7ff558857f0006000000060000
0555000aa00aa550000777777777700000888820faaaaaaf0222222001eee101eee101eef444444ff555557ff555557ff555557ff558857f0005000000050000
0555700007777000090007777777000000d00d00f5aaaa5f285555880000000eeeee0eeef444464ff5aa5aaffa5aaa5ffaa5a55ff555555f0060500000005000
055557777770ffffa90000999900000000800880f55aa55f88008858eee01e01eee10eeef444444ff555555ff555555ff555555ff558855f0060500000000000
005550662600ff67a900055559500000008000000ffffff008558888eee0ee000000000effffffff0ffffff00ffffff00ffffff00ffffff00006000000000000
555550005555500055555000555550000990099000000000000000000000000000f0f0000ffffff00ffffff00ffffff00ffffff0000666600006666000066660
55550000555500005555000055550000000aa00000900900009000900990099000ffff00ff5555ffff5554ffff4444ffff4445ff000060000000670000007777
509000905000000050110011500000000990099009a00a90090909099aa00aa900ffbf00f455444ff555444ff544455ff444555f077780000000870000008777
09090909099909990011001100000000000000000aa00aa0000000009aa00aa900ffff00f44ff44ff45ff44ff55ff55ff54ff55f077770000000770000000000
0000000000aa00aa00110011099909997d7ddd77777777777d7ddd777dddd77700ffff00f44ff44ff44ff54ff55ff55ff55ff45f000000000000770000000000
000077770000777700007777000077777dddd770777777707dddd7707dddd77000ffff00f444554ff444555ff554445ff555444f000000000000000000000000
7777770f7777770f7777770f7777770f0999660009999000099990000999900000000000ff5555ffff4555ffff4444ffff5444ff000000000000000000000000
0662600f0662600f0662600f0662600f55567760555595005555950055559500000000000ffffff00ffffff00ffffff00ffffff0000000000000000000000000
80bfbfbfbfbfbf939393bfbfbfbfbf80000000e670702f708080802f2f2f2f2f80808080808080808080808080800000140000000014000000005f005f00af00
000000143f0000afaf000000003f5f14000096af004f4f0014003f000000af808080808080202020200020202020202020208070000000808020000000000080
80bfbfbfbfbfbfbfbfbfbfbfbfbfbf8000000070000000006000e7ef000000002f2f2ff6808097e7000080808080f4f480808080608080808080808080808000
007080808080808000000080808080808080808080808080808080808080af808080808080808080808080808080808080807080707070802000000000000080
80bfbf20bfbfbfbfbfbfbfbfbf602080910000ef000000000000006f000000000f0f0f006f2f0041000000808080afaf0000000080000014000000001400e400
70af2014000014200000001400000014000080a1cfcfcfcf80001414afafaf707080c5d5939393939300e7000093939393930080afafaf800000000000000080
80bfbf2020bfbfbfbfbfbf60602020802fa1006f000000419393000080808080000000006f2fff2f000000808080bfbf000000005f0000140000b200a600af70
afaf5f14b200a65f00000014000000b60000afaf4f4f4f4f5f0014a63f3f3f70707000009393939393000000009393939393a6af4f4f4f800000000000000080
80bfbf20202020202020202020202080006fc4d40000006f838300002f2f006f000000006f2f808080950080808000ff004141a100a6001441003f000000afaf
afaf5f143f81005f0000ff1400410000b200af804100ffa100001400000100e49090a100939393939300000041939393939387af00000080a100000000009780
8070708080808080808080808080808080808000a4d40000000000000f0f410f412000006f002f2f2f2f018080800000005f3f5f5f9600145f00000000ffafaf
afaf5f14005f005f00000014005f00003f00afaf3f005f5f00001400ff5f00e44f4f4f009393939393ff00004f9393939393ffaf000000af4f00000070009680
50000050505050505080805050808080808080808000a4c4d420200000002f006f2f00006f000f0f0f2f2f808080808080808080808080808080808080808070
80808080808080808080808080808080808080808080808050808080808080708080808080808080808080808080808080808080707070808060606070708080
5000005000000000005050505050505080805050808080808080808080808080808080808080f4f4f4f480808080808080808080808080808080808080808080
8080808080808080808080808080505080808080808080505050508080807080708080804f4f4f4f4f8080808080808070808080707070808080808080808080
500000e70000000000e6e6005050505050505050505050505050505050505050505080808080f4f4f4f480808080808080808080808080808050505050808080
80505050505050808080808050505050508080805050505050505080505080808080808080000000004f00e600000050505050004f4f4f000000000014000050
500000000000000000e6e600005050505050505050509797970000303041e7e6e650505080809090909080805050808080808080808080505050505050505050
504050505050505050505050404040505050505050505050505050505050505050509797af800000000f00e600006500505050005f5f5f0000000000d6005050
500000000000000055e6e60000c7c7505050505050509787870000bfbf1f00e620bf505050501f1f1f1f5050505050405080808080805050503000e700000000
00e6e60000e6e6e6000000e6e6e6e6e6e6e6e6e6e6000000e700000000e6e6e65050978700af8000000000e60000af0014975000410000004100004100005050
5000000000500000bfe6e60000c7c7505050505050500000004100cfcf00002000bf505050501f1f1f1f50505050404050505050505050505030000000000000
0020200000e6e6e6000000302020202020202030300000000000000000e6e6f65040000000e6af80000000e60000000014005000af000000af0000af00505050
50000000505020000020500000c7c7505000002050500000301f000000a1811f00bf50505050f4f4f4f450505050504040505050505050505030000000000000
0020200000e6e6e6000000000000000000000000bf0000000000000000e6e6005040970000af00af000000e600000000d6005050505050505040404040505050
50505050502020000020500000405050e700000040400000bfc4c4c4d4bfbf0f006550505050bfbfbfbf50505050505050505050505050505030000000505000
00003000003030300000009393930000939393930f000000000000000020200050500000000000e60000202050000000870050910000e6f6e600000000e6e750
50505050e6000000000000000000e60041000000401f0000505050505050500000bfe70000e600000000e6000000e700000000505050505050300000000f0f00
0000bf000097979700000083838300008383838300000050500000000020200050500000000000e67100000081000000000050af00000000e600000000e6a650
50505000e6000000560000000000e6ffbf00ff005050202050505050505050500000000000e600000000e60000000000000000505050505050505050000f0f00
00001f000000000000000000000000000000000020303050500000000000000050500000000000e6af000000af0000000000505091000000e600000000e69650
50505000e60000009600005050505050505020205050bfbf0000e6410000e6bf93930000410000939300f60000000000410000000070e4909000bfbf000f0f00
0000000000000000000000000000000020202020bfbfbf50505050000000000050500000000030305000939393000000a5005050af000000f600005050505050
50500000e60000505050505050505050505050505050cfcf0000e61f0000e6bf838300001f0000838300a100000000001f00000001bfcf0f0f00afaf50505000
00b4b4b4b40000000000003030303030bfbfbfbfbfbfbf50405050000000650050500000000000e6200093939300000096965050500000000000305097974050
50500000e6000000000034e700000050505050505050b4b4b4b4e6000000e6bf000000b4b4b400000000bfb4b4505050505000001fbfcf0f0f0000000f0f0fb4
b45050505020202020202050505050502020202050505050504050500000bf0050503030000000f600008383830000005050505050000000000000e600870050
50000000e60000000000000000000034000050505050505050505050505050bf505050505050a100000050505050505050505050505050505050505050505050
5050505050404040505050505050505050505050505050205050505050500000505097000000000000000000003030305050505050005641000000e600000050
50000044e65000000000000000000000000000504040405050505050505050bfbfbfbf1f1f1fbf0000005050e6e700e65050505050505050505000e6e60097e6
0097e600000050505000000000e6e6000000e6e60000000020202050202000005050000000000050500050505050505050505050500096af000000e600000050
500000b550500000a5a500000000000000404040404000e70000e6000000e6000000001f1f1f500000000000e60000e6505050505050505050e700e6560000f6
0000f6000000000000000000002050000000f6e6000000000000005000000000505000000000000050505050505050505050505050505050503000f600000050
500000505000000000000000c5d5000040404040400000000000e6000000e6000000001f1f1fbf0000000000e6000020505050505050505050000000bf000093
93939300004100000091a10000202000000000e600009797970000e7000000005050000000000000e70000001450505050505050505050503000000000000050
500000000000000050500000000000004040df40400000000000e6000000e600000000a1e7000f0000000000e60000005050505050505050500000000f000093
9393930000bf000000bfbf000000000000000020000087878700000000000000505000000050000000000000d60000000000e700000000000000000000005050
500000006500000000000000248100505040bf40505000004100202020202000000041bf1f0000b6b6d60000300041005050505050505050500000a641010083
83838300b4b40000005050d40000ff0041ff30200000000000000000000000005050000050505000000091000093939393939393939393930000000000505050
50500000bf0044004400000014bf505050505050505000001f001f1f1f1f1f0000001f500f00b6d6b6b6000000001f00505050505050505050000096bf0f0000
000000005050000000505000a4c4c4d4bf003000000000000000c4c4d400003050500000000000000000af000083838383838383838383830000202020505050
50505000000054647400000404045050505050505050c4c4c4c41f1f1f1f1fc4c4c4c4bf000004040404505050505050505050505050505050b4b450404050b4
b4b4b4b450503030305050505050505050504050505050202020505000a4c430504040b4b4b4b4b4b44040b4b4b4b4b4b4b4b4b4b4b4b4b4b420505050505050
50505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505040405050
50505050505050505050505050505050505050505050505050505050505050405050505050505050505050505050505050505050505050505050505050505050
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f00000004005500050066000600220002000008000000000000088880000000000
0000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000040005000500060006000200020000080000aaaaaa00822228000c00000
08800080099900900aaa00a00b0b00b00ccc00c00ddd00d00eee00e00fff00f004440040055500500666006002220020000000000acccca0822772280ccdddd0
0080008000090090000a00a00b0b00b00c0000c00d0000d0000e00e00f0f00f004040040000000500000006000000020080808880ac77ca08270072800c00000
00800880099909900aaa0aa00bbb0bb00ccc0cc00ddd0dd0000e0ee00fff0ff004440440055505500660066002220220800808080ac77ca08270072800000c00
0080000009000000000a0000000b0000000c00000d0d0000000e00000f0f000000040000050500000060000000020000880808080acccca0822772280ddddcc0
08880000099900000aaa0000000b00000ccc00000ddd0000000e00000fff000004440000050500000060000002000000000808080aaaaaa00822228000000c00
00000000000000000000000000000000000000000000000000000000000000000000000005550000066600000222000088080888000000000088880000000000
__label__
00000000000000000000000000000000000000000000000000057500000000577500000000000000001111111111110000000000000000000057500005750000
00000000000000000000000000000000000000000000000000177710000001777710000000000000001cccccccccc10000000000000001000177710017771010
00000000111111111111111111111111111111001111111111111111000000571111110011111111111cccccccccc11111111100111111110011111105750570
000000001cccccc11cc11cc11cccccc11cccc1001cccccc11cccccc1000000011cccc1001cccccc11cccc111111cccc11cccc1001cccccc1001cccc100101770
000000001cccccc11cc11cc11cccccc11cccc1111cccccc11cccccc1000000001cccc1111cccccc11cccc111111cccc11cccc1111cccccc1111cccc100000570
000001001cccccc11cc11cc11cc11cc11cc11cc11cc111111cc11cc1000000001cc11cc11cc11cc11cc1111111111cc11cc11cc11cc111111cc1111100000010
000057501cccccc11cc11cc11cc11cc11cc11cc11cc111111cc11cc1000000001cc11cc11cc11cc11cc1111111111cc11cc11cc11cc111111cc1111100000000
000177711cc11cc11cc11cc11cccc1111cc11cc11cccc1111cccc111000000001cc11cc11cccc1111cc11cc11cc11cc11cc11cc11cccc1111cccccc100000000
000057501cc11cc11cc11cc11cccc1111cc11cc11cccc1111cccc111000000001cc11cc11cccc1111cc11cc11cc11cc11cc11cc11cccc1111cccccc100000000
000001001cc11cc11cc11cc11cc11cc11cc11cc11cc111111cc11cc1000000001cc11cc11cc11cc11cc1111111111cc11cc11cc11cc1111111111cc100000000
000000001cc11cc11cc11cc11cc11cc11cc11cc11cc111111cc11cc1000000001cc11cc11cc11cc11cc1111111111cc11cc11cc11cc1111111111cc100000000
000000001cc11cc11cccccc11cc11cc11cccccc11cccccc11cc11cc1000000001cccccc11cc11cc11cccc11cc11cccc11cc11cc11cccccc11cccc11100000000
000000001cc11cc11cccccc11cc11cc11cccccc11cccccc11cc11cc1000000001cccccc11cc11cc11cccc11cc11cccc11cc11cc11cccccc11cccc10000000000
00000000111111111111111111111111111111111111111111111111000000001111111111111111111cccccccccc11111111111111111111111110000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000001cccccccccc10000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111110000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05445544554444445544445005444444554455445005444455445000000000054444445544445000054444554444445544445005444444554444500005444451
04994499449aaaa9449aa940049aaaa94499449940049aa944994000000000049aaaa9449aa94000049aa9449aaaa9449aa940049aaaa9449aa94000049aa947
04aa44aa449aaaa944aaa944549aaaa944aa44aa45449aaa44aa4000000000049aaaa944aaa94455449aaa449aaaa944aaa944549aaaa944aaa94455449aa947
04aa44aa4549aa9454aa94994549aa9454aa44aa449949aa44aa40000000000549aa9454aa9499449949aa4549aa9454aa94994549aa9454aa94994499444457
04aa99aa4004aa4004aa94994004aa4004aa44aa44aa99aa44aa40000000000004aa4004aa949944aa99aa4004aa4004aa44aa4004aa4004aa44aa44aa454451
04aaaaaa4004aa4004aaa9445004aa4104aa44aa44aaaaaa44aa40000000000004aa4004aaa94454aaaaaa4004aa4004aa44aa4004aa4004aa44aa44aa449940
049aaaa94549aa9454aaa9445004aa40049949aa44aaaaaa449944445000000004aa4004aaa94454aaaaaa4549aa9454aa44aa4549aa9454aa44aa44aa99aa41
0549aa94549aaaa944aa94994004aa4115449aaa44aa99aa45449aa94000000004aa4004aa949944aa99aa449aaaa944aa44aa449aaaa944aa44aa44aaaaaa47
00049940049aaaa9449944994004994155549aa94499449945549aa9400000000499400499449944994499449aaaa944994499449aaaa944994499449aaaa947
00054450054444445544554450054455555544445544554455554444500000000544500544554455445544554444445544554455444444554455445544444457
00000000000000000000000000011115555555555555555555555550000000000000000000000005750010005750017777710000000000000000000000000011
00000000000000000000000000011111111111115555555555555550000000000000000000000017771575017771017777710000000000000000000000000575
00000000000000000000100000011111000000000001155555555555000000022000000000000005751777105750005777500001110000000000000000001777
000000000000000000057500000110005554a9f55550000115555555000002888200000000000000100575000100000111000057775000000000000000000575
0000000000000000001777100000599f455a99fa55a9945500155555000028882820000000000000000010000000000000000177777100000000000000000010
000000000000000000057500000149995515444555499f4555501555000288828882000000000000000000000000000000000177777100000000000000000000
0000000000000000000010000041050000001110000554555aa95015000888288888200000000000000000000000000000000177777100000000000000000000
000000000000000000000000044001111111111111111100049f6505002882888888820220000000000000000000000000000057775000000000000000000000
0000000000000000000000000051111111111111111111111004555500222ee88888822220000000000000000000000000000001110000000000000000000000
00000000000000000000000000111111111111111111111111110555002888ee8888822211111555555550000000000000000000000000000000000000000000
000000000000000000000000011111111111111111111111111110550002888ee88822111114999999f555500000000000000000000000000000000000000000
0000000000000000000000001111111111111111111111111111110000002888ee822111559a999999f7a5555000000000000000000000000000000000000000
00000000000000000000000011111111111111111111111111111110000002888e22111550aa9999999aa0555500000000000000000000000000000000000000
0000010000000000000000011111111111111111111111111100111000000028822115f900049a999aaa50055550000000000000000000001100000000000000
00005750000000000000000111111111111111111111111110000011000000022215977a0000059a9450000aa455000000000000000000057750000000000000
0001777100000000000000001111000555445000001111115a5000000000002221099faa00000000000000049955500000000000000000177771000000000000
0000575000000000000000000000005aaaaaa000009a999aaa50000000000022114999aa000005555555550099f5500000000000000111057750000000000000
0000010000000000000000000000005aaaaaa00000aaaaaaaa50000010000021159999a5001155555555555559f6550000000000005777501100000000000000
0000000000000100000000000000005aaaaaa00000aaaaaaaa5000057500000114a99a500115555555555555554f550000000000017777710000000000000000
0000000000005750000000000000005aaaaaa00000aaaaaaaa5000077710000154aa400111555555555555555555550000000000017777710000000000000000
00000000000177710000000000000059aaaa9000009aaaaaaa500005750000115000001115555555515555555555550000000000017777710000000000000000
00000000000057500000000000000009aaaa9000005aaaaaa9500000100000155000001155555155115555111555500000000000005777500000000000000000
00000000000001000000000000000005aaaa55555559aaaa9555560000000119a000011155511555015555111155550000000000000111000000000000000000
0000000000000000000000000000000559945555555599995555660000000147f000111555115511015551110115550000000000000000000000000000000000
000000000000000000000000000010555555555555555555555776000000119fa501151111111110115510110011550000000000000000000000000000000000
0000000000000000000000000000dd5555566666666666666677750000001599a501550011000000111000000001150000000000000000000000000000000000
0000000000000000000000000000d6dddd677777777777775777600000011599a001550000005500000000000001110000000000000000000000000000000000
00000000000000000000000000000dd6777777777777776557760000001115a99011500004aaaaa950009aa94000111000000000000000000000000000000000
000000000000000000000000000001dd777777777777655577650000000011aa50155005a9550000000055549400011000000000000000000000000000000000
000000000000000000000000000000ddd67777777555555676500000000015500015500555555555500005555500110000100000000000000000000000000000
00000000000000000000000000000001dd66777777777666544400000001155001155004aaaaaaaaa505aaaaaa90110005750000000000000000000010000000
000000000000000000000000000000001ddd6666666666d00099400000011550011550009aaaaaaa4005aaaaaa50110017771000000000000000000575000000
00000000000000000000000000000000001ddddd66d500000499400000111550011550004aaaaaaa50059aaaaa50110005750000000000000000101777100000
0005555500000000000000010000000000002500dddd00044999400000111555015550004aaaaaa9500599aaa900110000100000000000000005750575000000
0055555550000000000000575001000000044000ddd1444999994000001115550155500059999994500049999401110000000000000000000017771010000000
05550004440000000000017771575000000499444449944999994000001111555155500054999995550059999565110000000000000000000005750000000000
055000005940000000000057517771000004999449999449999940000001115551155dd05549945ddddd55556675110000000000000000000000100000000000
0500000004950000000000010057500000049994499999499994000000001115511551dddddddd67777777777761110000000000000000000000000000000000
5500000000490000000000000001000000044994449999449441000000000111511551ddd7667777777777777761110000000000000000000000000000000000
550000000059000000000000000000000014444444444444411d100000000011111555dd77666677777777777611110000000000000000000000000000000000
5500000000045000000000000000000000d11111111111111dddd100000000011111551dd7777766777777766111110000000000005555400000000000000000
5400000000055000000000000010000000ddddd1444441ddddddd1000000000011115500ddd77777777777611111110000000000055555994010000000000000
540000000005500000000000057500001ddd6614499941ddddd1dd10000000000011155000ddd777777776111111110000000000555000059475000000000000
55000000000550000000000017771000dd1d6d1499991dddd11dd66000000000000011500000dddddd1111111111100000000000550000005947100000000000
0551000000155110000000000575000ddddd614499991dddd1ddd661000000000000000001ddddd1d10000000000000000000000550000000545000000000000
0511000011d11d11000000000010001dddddd14999941dddddddd66600000000000000001d11dd1dd15000000000000000000000550000000094000000000000
01d10001ddddddd100000000000005dddddd14499991dd6ddddddd66100000000000000dd66ddd101d1100000000000000000005500000000049000000000000
1dd1001ddddddd1100000000000006ddddd145544491dd6ddddddd66600000000000000dd7771282d66000000000000000000005550000000059500000000000
0dd1001ddddd111400000000000056ddddd14dd55441d66ddddddd66610000000000001dd6760888dd6000000000000000000000550000000179510000000000
0dd100111111144400000000000066ddddd1445dd41dd666d1ddddd666000000000001dddd6118881dd60010549aaa9944500000550000000011500000000000
00d100444449999400000000000566dddddd1444441dd666d1dddddd6610000000001dddddd1d222d1dd1111449aaaaaaaa50000550000000011dd0000000000
00d11d9a99aaaa9400000000000666ddddddd11111dd6666dd1ddddd666000000001d6222222dd1dd221ddd14444449999950000055000111001dd0000000000
00111d4a99aaaa990000000000d6ddddddddddddddd66666dd01ddddd66d0000000d6628888824999998555555555555555550000550111111011d1000000000
00111d5a99aaaaa94000000001dddddddd1dd66666666666dd00dddddddd000000dd66288888249a9a985ffffffffffffffff5000051111ddd001d1000000000
0001100aaaaaaaa9400000000dddd111d11dd6666666666ddd001ddd1dddd00000ddd6288888249a9a985ff555555555555ff500015511ddd110111000000000
0001100aaaaaaa99400000001d1ddddd0011d66666666ddd1100011dddddd1000dddddd88828249999985f5d666666777775f5001111dddd1150011000000000
0001100aaaaaaa994000000011ddddddd1ddddd6666ddddddd0000ddddddd1000dddddd2888282494985ff5dddddd6666665f500111dd1115991111100000000
00011014aaaaaa99400000001dddddddd11ddddddddddddddd000011dddddd001dddddd2888828245485fff555555555555ff50001111114aaa5111100000000
000111d5aaaa9994110000000d6666dddd1ddddd11111ddddd1001dddddddd10dd7ddd1d228882222815ffffffffffffffff50000155449aaaa4111100000000
000111d149994411110000000d66666ddd1ddddddddddddddd100dddddddddd0dd77ddddd288822d281222ddffffffffffff500000499aaaaaa9001100000000
000dd110dddddd11110000000566666ddd1ddddd6666666ddd10dddddd6666d0dd777ddddd28282d211ddddddfffffffffff5000004999aaaaaa400110000000
01ddd100ddddd1110000000000666666ddddd666666666666dd1ddddd6666611dd777dddddd22821d11d67ddddefffffffdd5000005999aaaaaa950110000000
00ddd100011111550000000000566666d1ddd666666666666dddddddd666661dd77777ddd66d882d1dd67d67ddeffffff2dd00000004aaaaaaa9911111000000
00ddd150000000550000000000066666d1dd666666666666ddd1dddd6666660dd77777ddddd282d11d67d67dd2efffff2dddd00000049aaaaa99951111dd1000
001dd17100000055000000000005666ddddd666666666666ddd1dddd6666611dd77777ddddd22ddd1ddd67dddddeffffdddd650000004aaaaa99941111dd1000
000ddd5000000005500000000000666d1dddd6666666666dddd11ddd666660ddd77777ddddd2ddddddd67dd67ddefffed66ddd00000049a9aa99411001ddd000
000ddd1000000005500000000000ddddddddd666666666ddddd11ddd666610dd777771ddddd0111d6ddddd67dd2efffe2dd6dd000000599994451d10011dd000
0001dd10000000055000000000001dd6ddd1dd6666666d11ddd1ddddd66101dd7777701ddd241ddd66ddd67d12effffeddddd600000004445111dd11001dd000
0000dd10000000005500000000000d66ddd11d666666d1ddddd1ddddd6600dddd777710dd444d1dd476dd7d2effffffedd66dd00000001111dddd150001dd100
00005d10000000005500000000000d6d1ddd1dddddddddddddd1dddddd100dddddddd01dd9411d4af77ddddefffffffed6d66dd000000111ddd177100011d100
00000dd00000000005000000000001d11dddddddddddddddddd1dd6ddd00dddddddd1dddf9011d4a6776d1eefffffffe2dd7ddd000000000555575000001dd00
00000dd1001000000550000000000011ddddddddddddddd666ddd666111dddddddddddd750011d64777dddefffffffffe2dddd6500000000055010000001dd00
000001d1057500000550000000000011dd666dddd0dddd6666dddd66150dddddd1ddd77750411d6677dddefffffffffffedddaf5000000000550000000001d00
000000d1177710000550000000000011dd6666ddd0ddd66666dd1d66100ddddd1ddd777754a111d66dd2effffffffffffe2d6afd000000000055000000001d00
0000001d057500000055000000110011ddd6666dd0ddd66dd1dd11dd101ddd11dd7777775aa1dddddd2efffffffffffffe2d6f75100000000055000000001d10
0000000d00100000015500001ddd0111dd11dddd101dddd1dddd1110001dd11dd7777777faa5dd51d125555555555555551dd76d100000000055000000000110
00000001000000005755000011dd0d1ddddddddd101dddddd66d111000dd11dd777777776aa4dddd1dd6d001dd6666d441ddd65d000000000055000000000110
000000000000000177755000011d1d1dd666dddd000ddd66666dd11000d11ddd777777777aa01ddd1ddd100001ddddd941ddd1d1000000000055000000000110
0000000000000000575055000011dd1dd66666dd000dd6666666d11001d11ddd77777777765051dd11ddd0000001ddd441dd1dd1000000000055000000000010
0000000000000000010055000001d11dd66666dd000dd6666666d1101d1111dddddddddddd15941111d6d500000001d400d1dd10000000000055000000000010
0000000000000000000005500001111d666666d10001d6666666d011dd1011111dddddddddd44411dd6676000000000000111100000000000055000000000000
0000000000000000000000550000111d666666d00001d6666666d111111000000002ddddddddddddddd777500000000000000000000000000555000000000000
000000000000000000000055500011dd666666d000001d666666dd1111000000000d6666dddd6666ddd777600000000000000000000000000550000000000000
000000000000000000000005555011dd666666d00000dd6666666d111000000000166667777777766dd777750000000000000000000000000550000000000000
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077700000777070707770770077707770000077007770077077007770077000007770777077000770777077707770070000000000000000
00000000000000000070700000777070707070707070007070000070707070707070707000700000007000707070707000707077707000070000000000000000
00000000000000000077700000707070707700707077007700000070707700707070707700777000007700777070707000777070707700070000000000000000
00000000000000000070700000707070707070707070007070000070707070707070707000007000007000707070707070707070707000000000000000000000
00000000000000000070700000707007707070777077707070000077707070770070707770770000007000707070707770707070707770070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
00040201210101210104040000004a0100000000100000101010100000100000000000000000000000000010000000000000000000000000404000000000000001000000000101014040000000000101000000001010100000000000000000000000000000200000000020202020000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080
__map__
0808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808
0808080808080808080808080808080808080808080808080808080808080808080808080808080808797979790000000000000079790079790707000000004300430043004300430808080808080808080808080808080808080808060606076e7e00000000004141410000006e6e7e00070606060808080839393939390e08
0808080808080808fc797979410041fe006e0041000808080808080808080808080808080808080808797800000000000000000079790079790707561a00000000000000000000000008080808080808080808080808080808080606070707006e0000003939396a6a6d3939396f6e000000070707060608083939393939fa08
0808080808080808fc000000410041f7006e0041007e0000414100006e006e6e6e6e08080808080808000039393939393939390000780079790707f8f80000000000000000000000007c790808080808080808080808080808060707073939396e0000003939396d6d6d393939006e0000393939070707060839390808080808
0808080808080808fc00000041080800001d004100000000414100006e006e1c6e6efe080808080808000039393939393939390000000078780707070700000000000000000000000000780808080808080808080808080808060000003939396f00000007070700000007070700000000393939000000060839393939393908
0808080808080808fc0000000808410000000041000000000808000016006e00006ff70808080808080000393939393939393900001a00000007070707000000000000560000000000000008080808080808080808080808080600000039393900000000f9f9f9001d00f9f9f900000000393939000000060839393939393908
0808080808080808fc0000000000410000000041000000000808000000006e00550079080808080808000038383838383838380000f800000000000000000018000000f8000000000000000808080808080808080808080808060000003939390000000000000000f90000000000000000393939000000060839393939393908
0808080808080808fc005400000041000000004100fe0000086f000000000000fb000079080808080800560000000000000000000008000000000000000044f8440000000000000000001408080808080808080808080808080600000038383800005c5d0000000000000000005c5d0000383838000000060839393939393908
0808080808080808fc00fb00000041000000004100f70707074d00000000540000000000080808080800f800000000000000000000070044000000004400070706004400000000440000f80741004100410043000808080808080000000707070000000000000039393900000000000000070707000000080808083939393908
0506060606000007fc0000000000413f3e2d3e410000000008004a4d0000f700000000000808080808000000000000000000000000074b4b4b4b4b4b4b4b0707064b4b4b4b4b4b4b4b0707074100430043000000080809094e4e100000f9f9f90000000000000039393900000000000000f9f9f900000009094e103939393908
05fbfbfb6e000007fc005400fe0008080808080800000000080041004a4d001c084b4b4b08080808084d4400000000000000000000070000560000000000070706000000000059000000000043000000000000000808f8f84e4ef900000000000000000000000039393900000000000000000000000000f9f94efa3939393908
05fbfb00fb000007fc00f700f70000000000000000000000fb00410041004a086e00000009094e007e004a4d440000000000000000070000f80000000000070706000000000059000000003939393939393939390808f8f808080707070707070707070707070039393900070707070707070707070707080808083939393908
05fb000012000007fc005a5a000000000000000000000000fb0041004100410016005a5af7f74e10000041004a4d4400000000000007000000000000000008080600000000005900000000393939393939393939080800000808f9f9f9f9f9f9f9f9f9f9f9f90039393900f9f9f9f9f9f9f9f9f9f9f9f9080839393939393908
05fb0000fb000007fc0000000000000000000000000000fefb0041004126410000260000f7f74ef80000415a41004a0000000000000000000000000000007e0000000000000059000000003838383838383838387e0000000808f9f9f9f9f9f9f9f9f9f9f9f90038383800f9f9f9f9f9f9f9f9f9f9f9f9080839393939393908
05fb0000f00000070808080808002e3d2e002c1c6d0010f7fb12410008080808080808080808080808004100415a4100000000000000000000000000000000000000000000005900000000000042fe0000000000006a001808080707070707070000000000000002080200000000000000070707070707080839393939393908
05fb0000000000000000080808080808080808086900f700fb414108080808fcfc080808080808080808080041004100440000440000004400170044003838000000000000005900000000004441f80000004400006900f80808f9f9f9f9f9f900000000000000f9f9f900000000000000f9f9f9f9f9f9080839393939393908
05fb060000000000000000080808080808080808084f4f4f0808080808fbfbf9f90708080808080808080808080041005b00005b001a005b00f8005b14484914440000004400591448491a40404040404040404008080808080808080806060600000000000000f9f9f900000000000000060606080808080839393939393908
05fbfb0600000000000000080808080808080808080909090808080808fbfb0000fc07080808080808080808080808004546464700f8004546464647f85959f845464646470059f85959f84141414141414141410808080808080808080808084f4f4f4f4f020202080202024f4f4f4f4f080808080808080839393939393908
05fbfbfb0606060600000000080808080808080808f6f6f60808080808fbfb0000fc07077979790808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808fcfcfc080808080707070808
080202020202020206393939390808080808080808f6f6f608080808080808080807fc07000000000a0a004e0909000000000000060600000841000041000000004e000000000041000000000041000800000014000041000606060606080808081a0000000000000000007e086e6e0000006e08000000020700000808080808
080202020202020239fbfbfbfb08080808080808080000000808080808fbfbfbfb0807fc00000010fafa10fcf5f5003939000000fafa0000f54100006a0039390efb0000005c5d4100004e00006500f5000000f35c5d412bfafafafafafafa0808f4000000005c5d00000000fa6e6e0000006efa000000f4fa0000fcfcfc0808
0802020202020239fbfbfbfbfb0802080808080808000000080808080806fbfb06080807000000fbfafaf64ef5f500383800182bfbfb171a004114006a003838fbfb000000000041002bfa0000fa00001a17ff006a6d41f3f4f400fafa06fa080807006b00140000ff1a0000fa6e6e0000006efa000000f4fa1a00fcfcfc0808
08020202020239fbfbfbfbfbfb02fb0879796e797e0000000000000008080707080808080808080808080808080800000000faf30000f5f50041f3006900000000fb00000000004100f3fa0000fb0000f5f50000696941000000000000fafa080800006900f4000000f40000fa6e6e0000006efa000000f4faf400fcfcfc0808
080202020239fbfbfbfbfbfb02fbfb0879786e00000000000000000000000000007e00006e006e08080808080808070707070806080808080808080808080808080808080808060808080808070707070808060808080808080808080000fa08080808080808080808080808086e6e0008080808070707080808080808080808
0802020202fbfbfbfbfbfb02fbfbfb0878006e00fe0008080808000014000000000000006e006f007e0008080808fafa00000008410000000041410000000000fafafafa000008000041004e00fafafa00000806002b0008fcfcfcfc001afa08080808080808080808080808086e6e0002020808fafafa086e007e0000006e08
0802020202fbfbfbfb0202fbfbfbfb0800006e00f600000202f20800f60000000000000008080000000079080807fbfbfd0000f541000000006a41002b000000fbfbfbfb0000f52b006a00fa00fbfbfb0000f5fa00f300faf4f4f4f400fafa08080808000000007e00000000086e6e0000020208f4f4f4fa6e00000000006e08
0802020202fbfbfbfb393939fbfbfb0800146e00000000000000f2080808080800000000f2f208000018780808070000fa171a14410000000000411af300141a00007900171afff3000000fa6a001414001afffa000000fa1a0000000008fa08080707000000000000000000086e6e0000000208000000fa6e00000000006e08
0802020202fbfbfbfbfbfbfb39fbfb0800f26e070000005c5d000008000000fe07000000f0f0f20000f200080807000000f5f5f341000000000041f50000f5fa00006900f5f5f500000000fa6900f3f500f5f5fa000000fafa00000000fafa0809094e00000000001a00000008026e0000000808000000fa6e1a000000006f08
083902020202fbfbfbfbfbfbfb39fb080808080600000000000000f2170000f6000202393939f00008080808080800000808080808080000000808080806080808080808080808084f4f4f08080808080707070808080808080808080000fafaf3f34e1000000000f40000000000060000000808070707fa6ef4000000000008
08fb39390202fbfbfbfbfbfbfbfbfb080800006e0000000000000000f200561400f2f238383800007e001809094e001041000000004100000014000000084e0000000041fcfcfc4efafafa000000004100000008fafafa0641fcfcfc00001afaf3f34ef400000008080800000000000000000808fafafa080808084b4b4b4b08
08fbfb3939020606fbfbfbfbfbfbfb087e00006e17000002007900000800f6f200f0f000000600001414f2f2f24e00f34100002b0041000000f3005600f5fa00005c5d41f4f4f4fafbfbfb2b000000415c5d00fa020202fa41f4f4f40000fa08080808080800006e006e00000000000000000808f4f4f4080808080000000008
08fbfbfbfb3939020202fbfbfbfbfb080000006ef60002f200690008f20808080000000000f20800f6f2080808080000410000f300410000000017fa1a00fa0000000041140000fafd0000f300141941000079fafafafaf441002b0000000808080808080800006e000200000000000000000808000000080808020000000008
__sfx__
000200000664006610096100c6401c0101d1101c1101d110116101d110290401e1401e0301e130200401e16036660366603566034660346603466033640146401d64029640246400000000000000000000000000
1902000027553285532a5532b5532a5532a5532a5532814328143271332613326123251332312322113211132b6431e7031c7031f603186031260313603000000000000000000000000000000000000000000000
01050000135172a6223a53723632181371213104121021210212202122031070310700107001070010700107306502a64026630226201e6101961015610001070010700107001070010700107001070010700107
4103000000331043750000009335000001a371000000067504675093771a377003012360023600236000030100301000000000000000000000000000000000000000000000000000000000000000000000000000
a1040000005160251604516085260c52612526165361a5361d53622546275462e546355463a5463d5563d5563d5563d5563d5563d5563d5563d5563d5563d5563d5563d5563d556296062860626606216061f606
010200002d6332e6432f6532e6532d6532b65333153311532e1332a133271532515323143201431e1331b133191331813317133151331413312123101230e1130d1130c1130b1130811306113041030210301103
a1040000126231362317623246472e647000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030400000561411610216302f6401e630356403f6453f647006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0002000014610166101a6201e630266302f6403f6402f6503166005060090400c0401825014240112400f2300d2200c2100a2100c0100a050090502167322663206531b653116430b64309633096130661305613
010300002a660296602666025660216601d6601966016650002550065500255006450024500645002450064500235006350023500625002250062500225006250022500625002250061500215006150021500615
030400003115231152311203112035152351523512035120272731b2731b2731b2132b2731f2731f2731f2132b2731f2731f2731f2132b2731f2731e2731d2132f64626676246761d676176773b6002860625606
0102000023221282212d2212f22128621276212562123621216211e6211c4211b4211942115421134210a52107521055210262100001000010000100001000010000100001000010000100001000010000100001
5b0f00000000026170261422617026142386603866526170261422517025142241702414221170211421a1701a1421a1701a1521a1321a1321a1121a1110d1310013100000000000000014711157311575116771
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
490f0000000000e1700e1420e1700e14238660386650e1700e1420d1700d1420c1700c14209170091420217002142021700215202132021320211202111021110211102111021110211102111021310215102171
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
511a0000295511d5531d1521d15524152241552915229155281522815524152241552413524115281522815527152271552315223155231352311527152271552615226155221522215522135221152211500000
591a000000000000001d1521d155241522415529152291552b1522b155241522415524145241152b1522b1552d1522d155261522615526145261152d1522d1552c1522c1552c1452c1252c1152c1152c1002c100
59500000227351d7351973518735197351d7351673519735227351d7351b7351d7351e735207351e7351d735227351d7351973518735197351d735167351973522735227151d7352573522735297352473525735
591a0010041420c142091420a14208142091420714208142061420714205142061420414205142021420314200102001020010200102001020010200102001020010200102001020010200000000000000000000
120d00200217202172021720217202172021720217202172021520215202152021520213002130021200212002110021100211002110021000210002100021000210002100021000210002100000000000000000
481a00001c52224522215222252220522215221f522205221e5221f5221d5221e5221c5221d5221a5221b5221c52224522215222252220522215221f522205221c5222452221522225221c5221d5221a5221b522
151a0020021610213202120021100416004130051600513001161011300112001110021650213004165041300216102130041600413005160051300a1620a1300916209130051620513004162041310412104113
0504000000000000000000000000000000000000376043710007609376000061a37600006006761b6731b6771b4731b67700307172751767709307000061a3710000000670006770000600006000060000000000
151a0000051500415004130041151c6221c6250415004130051500415004130041151c6221c625000000000005150041500413004115051500415004130041150a1600916009140091250a170091700915009133
0102000023676236762267621666206661e6561c6561b646196461663614636126360f6360d6260b62608626066260462601616016160061603606016060160611606106060c0061800624006000060000600006
010400000c4570e4571045711457134571545717457184571a4571c4571d4571f4572145723457244572645728437264372443723437214371f4271d4271c4270000000000000000000000000000000000000000
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
01 2d2a2c6c
00 2b2d2a2c
00 2e2d2a2c
02 2c2a6a6c
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
01 1c424344
02 1c191844
01 191a4344
00 191a1c44
00 1b351c1a
00 1a1d1c18
00 1a1e1c18
00 351a1c58
02 361a1c18
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
01 38424344
03 39384344
01 393a3844
00 393b3a44
00 393b3a38
00 393a4344
00 393d3a44
02 39386944
01 0c3f2944
01 15164344
00 15371744
01 15174344
00 15161744
02 15371744

