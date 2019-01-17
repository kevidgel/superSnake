globals[
  inputxy-1 ;state of snake 1, as list. ex. [0 1] would be 0 horizontal and 1 vertical.
  inputxy-2 ;state of snake
  length-1 ;length of snake 1
  length-2 ;length of snake 2
  bomb-2; cooldown for 2nd snake.
  bomb-1; cooldown for 1st snake.
  wins ;how many wins each snake has
  reset? ;resets wins
  game-number ;how many setups counted
  gamewinner ;how many wins per game
  Restrict-1
  Restrict-2
]

patches-own [
  tail-1;Which part of snake 1 it is. Tail would be length. Head would be 1
  tail-2;Which part of snake 2 it is.
  snake? ;if it is a snake or not
  id ;identity of the snake
  food-value; how much length the food provides
  bomb-timer; how much time left until bomb disappears/explodes.
]
breed [snakes-1 snake-1]
breed [snakes-2 snake-2]
breed [cakes cake]
breed [bombs bomb]

;;Main functions
;Setup sets up world
to setup
  variable-setup
  cp
  ct
  ask patches [
    set length-1 0
    set length-2 0
    set food-value 0
  ]
  world-setup
  if Maps = "Border" [border_map]
  if Maps = "Battlefield" [battlefield_map]
  if Maps = "Hideout" [hideout_map]
  snake-setup
  food-spawn food
  reset-ticks
end

to variable-setup ;workaround for ca. Not all globals will be cleared, only some of them after each setup.
  set inputxy-1 []
  set inputxy-2 []
  set length-1 0
  set length-2 0
  set bomb-2 0
  set bomb-1 0
  set gamewinner 0
  ifelse reset? = 0 [
    set wins [0 0]
    set game-number 0
    set reset? 1
  ]
  [set game-number game-number + 1]
end

;Go runs the game (model)
to go
  if any? snakes-1 or any? snakes-2[
    if any? snakes-1 [snake-1move]
    if any? snakes-2 [snake-2move]
    food-spawn-go
    if bombs? [bomb-tick
      bomb-explode]
    victory
    wait (10 - speed) * .02
    tick
  ]
end
;

;;Snake life-cycle
;sets up the snakes
to snake-setup
  ask patches at-points[ [0 1] [1 0] ] [set snake? 1] ;player 1
  ask one-of patches with [snake? = 1] [
    set pcolor blue
    set length-1 3
    set id 1
    sprout-snakes-1 1[ ;makes snake head
      set label 1
      set shape "snake-head"
      set color blue
      set size 2.5
    ]
    set inputxy-1 [0 1]
    set tail-1 1
  ]
  if Players != 1 [ ;checks if there is more than 1 player
    ask one-of patches with [snake? = 1 and pcolor != blue] [ ;player 2
      set pcolor red
      set length-2 3
      set id 2
      sprout-snakes-2 1[ ;makes snake head
        set label 2
        set shape "snake-head"
        set color red
        set size 2.5
      ]
      set inputxy-2 [0 -1]
      set tail-2 1
    ]
  ]
end

to snake-1move ;controls how player 1 moves
  ask snake-1 0 [
    move-to patch-at (item 0 inputxy-1)(item 1 inputxy-1) ;moves to patch depending on controller input
    snake-eat 1
    snake-die
    set pcolor blue set snake? 1 set id 1
    set heading xy-to-heading inputxy-1
  ]
  ask patches with [tail-1 >= length-1][
    Reset-patches
  ]
  ask patches with [pcolor = blue][set tail-1 tail-1 + 1]
end

to snake-2move ;controls how player 2 moves
  ask snake-2 1 [
    move-to patch-at (item 0 inputxy-2)(item 1 inputxy-2)  ;moves to patch depending on controller input
    snake-eat 2
    snake-die
    set pcolor red set snake? 1 set id 2
    set heading xy-to-heading inputxy-2
  ]
  ask patches with [tail-2 >= length-2] [
    Reset-patches
  ]
  ask patches with [pcolor = red][set tail-2 tail-2 + 1]
end

to snake-eat [long] ;how snakes eat
  if shade-of? pcolor brown[
    if long = 1
    [set length-1 length-1 + food-value] ;depending on the player, if a snake is on a food patch, it sets its length to the length + the food value of the patch.
    if long = 2
    [set length-2 length-2 + food-value]
    Reset-patches
    ask patch-here [
      set food-value 0
      ask cakes with [xcor = [pxcor] of myself and ycor = [pycor] of myself] [die]
    ] ;resets patch food-value
  ]
end

to snake-die
  if member? pcolor [red blue yellow orange 44];if a snake hits another or itself, it dies.
  [
    ask patches with [pcolor = [color] of myself] [
      Reset-patches
    ]
    die
  ]
  if pcolor = white
  [
    set bomb-timer 0 bomb-explode
  ]

end

to reset-patches
  set pcolor (pxcor + pycor) mod 2 + 56
  set id 0 set snake? 0 set tail-1 0 set tail-2 0 set food-value 0
end

;

;;Controls
;All the controls make the snake move in the direction specified by the function
;They use inputxy-1 or 2, a list [x y]. x is the horizontal distance it moves, y is the vertical distance.
to north [player]
  if player = 1
  [if (item 1 inputxy-1) = 0
    [set inputxy-1 [0 1]]]
  if player = 2
  [if (item 1 inputxy-2) = 0
    [set inputxy-2 [0 1]]]
end

to south [player]
  if player = 1
  [if (item 1 inputxy-1) = 0
    [set inputxy-1 [0 -1]]]
  if player = 2
  [if (item 1 inputxy-2) = 0
    [set inputxy-2 [0 -1]]]
end

to west [player]
  if player = 1
  [if (item 0 inputxy-1) = 0
    [set inputxy-1 [-1 0]]]
  if player = 2
  [if (item 0 inputxy-2) = 0
    [set inputxy-2 [-1 0]]]
end

to east [player]
  if player = 1
  [if (item 0 inputxy-1) = 0
    [set inputxy-1 [1 0]]]
  if player = 2
  [if (item 0 inputxy-2) = 0
    [set inputxy-2 [1 0]]]
end

to-report xy-to-heading [xy] ;converts directional coordinates to heading
  if xy = [0 1]
  [report 0]
  if xy = [0 -1]
  [report 180]
  if xy = [1 0]
  [report 90]
  if xy = [-1 0]
  [report 270]
end
;

;;Environment
to food-spawn [num] ;spawns the food depending on the food slider
  ask n-of num patches with [pcolor = 56 or pcolor = 57] [
    set food-value (random 3) + 1
    set pcolor scale-color brown food-value -3 6
    sprout-cakes 1  [set shape "cake" set size 3]
  ]
end

to world-setup ;sets up the world
  ask patches [Reset-patches] ;creates checkerboard pattern
end

to food-spawn-go ;spawns food as the game runs
  if count patches with [food-value > 0] < food
  [food-spawn 1]
end

;;Maps- using chooser "Maps," creates different maps with different obstacles
to border_map
  ask patches with [pxcor = max-pxcor or pxcor = min-pxcor or pycor = min-pycor or pycor = max-pycor]
  [set pcolor 44]
end

to battlefield_map
  ask patches with [pxcor = max-pxcor or pxcor = min-pxcor or (abs pycor < 13 and abs pxcor = 11) or (abs pycor > 4 and abs pxcor = 8)]
  [set pcolor 44]
end

to hideout_map
  ask patches with [(abs pxcor = max-pxcor and abs pycor > 4) or (abs pycor = max-pycor and abs pxcor > 4)
    or (abs pxcor = 4 and abs pycor > 10) or (abs pycor = 4 and abs pxcor > 10)
    or (8 < abs pxcor and abs pxcor < 12 and 8 < abs pycor and abs pycor < 12)]
  [set pcolor 44]
end

;;Modes: Bombs
to bomb-summon [n] ;asks snakes to create bombs on their tails.
  if bomb-1 = 100 and n = 1[ask patches with [tail-1 = length-1]
    [reset-patches set pcolor white set bomb-timer 20
      sprout-bombs 1[set shape "bomb" set size 3 set color blue]] set bomb-1 0]
  if bomb-2 = 100 and n = 2[ask patches with [tail-2 = length-2]
    [reset-patches set pcolor white set bomb-timer 20
      sprout-bombs 1[set shape "bomb" set size 3 set color red]] set bomb-2 0]
end
to bomb-tick;Counts down the time until you can place a bomb
  if bomb-1 != 100 [set bomb-1 bomb-1 + 4]
  if bomb-2 != 100 [set bomb-2 bomb-2 + 4]
  ask patches with [bomb-timer = 0 and member? pcolor [orange yellow]][
    Reset-patches
  ]
end

;Bomb Expoldes and blinks shortly before exploding.
to bomb-explode
  ask patches with [bomb-timer = 0 and pcolor = white]
  [ask bombs in-radius 3[die]
    bomb-reduce
    ask patches in-radius 3[reset-patches ask cakes-here [die]
      set pcolor yellow set bomb-timer 10]
    ask patches in-radius 2[set pcolor orange set bomb-timer 9]
  ]
  ask bombs-on patches with [bomb-timer < 10]
  [set color color + (bomb-timer mod 3 - 1) * -4]
  ask patches with [bomb-timer != 0][set bomb-timer bomb-timer - 1]
end

;If you get hit by a bomb reduce your life
to bomb-reduce
  if any? patches with [pcolor = blue] in-radius 3
  [set length-1 min [tail-1] of patches in-radius 3 with [pcolor = blue]]
  if any? patches with [pcolor = red] in-radius 3
  [set length-2 min [tail-2] of patches in-radius 3 with [pcolor = red]]
  if length-1 = 0 [ask snake-1 0 [ask patches with [pcolor = [color] of myself]
    [Reset-patches]die]]
  if any? snakes-2 [
    if length-2 = 0 [ask snake-2 1 [ask patches with [pcolor = [color] of myself]
      [Reset-patches]die]]
  ]
end
;

;;Scores / Victory
to-report Player1 ;reports length of player 1
  report count patches with[pcolor = blue]
end

to-report Player2 ;reports length of player 2
  report count patches with[pcolor = red]
end

to victory ;victory crown for snake
  if Players > 1 [
    if (not any? snakes-1) [
      ask snakes-2 [set shape "snake-winner"]
      if gamewinner = 0 [
        set wins replace-item 1 wins ((item 1 wins) + 1)
        set gamewinner 1
        victory-animation 2
      ]
    ]
    if (not any? snakes-2) [
      ask snakes-1 [set shape "snake-winner"]
      if gamewinner = 0 [
        set wins replace-item 0 wins ((item 0 wins) + 1)
        set gamewinner 1
        victory-animation 1
      ]
    ]
  ]
end

to victory-animation [snake]
  set inputxy-1 [0 0]
  set inputxy-2 [0 0]
  if user-yes-or-no? (word "Snake " snake " has won the game. Restart?" )[setup]
end
to-report P1-Score
  report item 0 wins
end

to-report P2-Score
  report item 1 wins
end

to reset-wins ;resets win counter
  set wins [0 0]
end
;
;Gamemodes Like Mini-Games.
;;;VERY IMPORTANT PLACE.

to Mode
  if Gamemode = "Normal"
  [set restrict-1 [red blue yellow orange 44]
    set restrict-2 restrict-1
    food-spawn food
  ]
  if Gamemode = "No Competition"
  [set restrict-1 [blue yellow orange 44]
    set restrict-2 [red yellow orange 44]
    food-spawn food
  ]
  if Gamemode = "Friendly World Dig"
  [ask patches [Reset-patches]
    ask n-of 35 patches with [abs (pxcor) > 4]
    [set pcolor 4 + random 3]
    set restrict-1 [4 5 6]
    set restrict-2 [4 5 6]]
end

to Mode-go
  if member? gamemode ["Normal" "No Competition"]
    [food-spawn-go]
  if Gamemode = "Friendly World Dig" and
  count patches with [member? pcolor [4 5 6]] = 0
  [set gamemode "normal"
    set food 3
    ask turtles [set shape "snake-winner"]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
397
10
944
558
-1
-1
11.0
1
10
1
1
1
0
1
1
1
-24
24
-24
24
1
1
1
ticks
30.0

SLIDER
100
11
292
44
Players
Players
1
2
2.0
1
1
NIL
HORIZONTAL

BUTTON
3
10
97
119
Start
setup
NIL
1
T
OBSERVER
NIL
`
NIL
NIL
1

BUTTON
295
10
391
120
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
62
193
133
226
Up 1
north 1
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
54
342
132
375
Up 2
north 2\n\n
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

BUTTON
54
273
149
306
Down 1
south 1\n
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
56
433
151
466
Down 2
south 2\n
NIL
1
T
OBSERVER
NIL
K
NIL
NIL
1

BUTTON
103
233
193
266
Right 1
east 1
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
12
234
90
267
Left 1
west 1
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
101
387
191
420
Right 2
east 2\n
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

BUTTON
13
387
91
420
Left 2
west 2
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

SLIDER
101
50
292
83
Food
Food
1
5
4.0
1
1
NIL
HORIZONTAL

BUTTON
238
234
333
267
Bomb 1
bomb-summon 1\n
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
1

MONITOR
233
187
318
232
Cooldown
100 - bomb-1
17
1
11

MONITOR
233
343
318
388
Cooldown
100 - Bomb-2
17
1
11

BUTTON
242
391
337
424
Bomb 2
bomb-summon 2
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
1

SWITCH
100
87
200
120
Bombs?
Bombs?
0
1
-1000

MONITOR
227
272
284
317
NIL
Player1
17
1
11

MONITOR
228
426
285
471
NIL
Player2
17
1
11

CHOOSER
202
85
294
130
Maps
Maps
"Plain" "Border" "Battlefield" "Hideout"
0

SLIDER
65
123
200
156
speed
speed
1
10
8.0
1
1
NIL
HORIZONTAL

CHOOSER
982
72
1183
117
Gamemode
Gamemode
"Normal" "No Competition" "Friendly World Dig"
2

BUTTON
973
15
1093
48
Reset Wins
reset-wins 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
974
130
1037
175
NIL
P1-Score
17
1
11

MONITOR
976
186
1039
231
NIL
P2-Score
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model will be a modified version of the classic game Snake. 
Snake is a game where a “snake” moves around the world and eats food pellets in order to grow. 
In this model, there is an option to play multiplayer snake. There is also a mode called "bombs," in which snakes drop bombs and try to kill each other.

## CONTROLS

WASD to move snake 1. IJKL to move snake 2.
E will cause snake 1 to drop bombs.
O will cause snake 2 to drop bombs.
Sliders for food and number of players.
Setup creates the snakes and world.
Go starts the game.

The switch "Bombs?" will toggle the bombs mode on or off. 
You can choose which map to play on using the chooser "Maps." 

Bombs can destroy walls.

## HOW IT WORKS

There will be three types of functions that we will use, the ones that control the movements and life cycles for the snake, the ones that control the environment (food pellets, etc.), and the ones that control the different game modes (bombs, # of snakes, etc.). Two main functions, called “setup” and “go” will set up the world of Snake and start the game. These two functions will also incorporate the other functions through modular design. 
We have four functions for the life cycle of a snake. The first function will be called “snake-setup,” which will spawn snakes randomly throughout the world, and set their respective snake variables. The second function will be “snake-move,” which will control how the snakes move throughout the world. This function will most likely utilize modular design, for left, right, up, and down controls. The third function will be “snake-die,” as it will detect if a snake has touched itself or another snake and that kill that snake. The last function will be “snake-eat,” which will manage snake-eating.
For the functions that will control and modify the environment of the snakes, there will be two. One is “world-setup” which will setup the world, clearing the world of food pellets and snakes, and resetting patch and turtle variables. The second function is “food-spawn,” which will spawn food for the snakes to eat. 
Finally, we have functions for a game mode. These functions will make the snakes drop bombs, and kill other snakes, potentially including themselves.

## THINGS TO NOTICE
The patch that the snake "head" is on has a variable "length-x"
That variable is set to dist-2, the distance of the entire snake.
As the snake head moves to a different patch, the previous patch(es) decreases its length-x by 1.
Eventually, if length-x = 0, it stop being part of the tail.
Ex.
 00030000 ;3 is location of the head, numbers are the length-x of the patch.

 snake moves right by 1
 00023000 ;1, 2 is the tail

 snake moves right by 1
 00012300

 snake moves right by 1
 00001230
 ...

The snake's head owns the highest length-x. Each time it eats, its length-x increases, creating a larger snake.

## COMMENTS

Overall, this project is using the classic game Snake and putting an interesting twist to it in order to make it more fun. 

## NEW IN VERSION 2.0
+added bombs mode
+added cake 
+added victory crown for winning snake
+snake is slowed down
+new background for easy viewing
+organized interface 

## CREDITS AND REFERENCES

Original Snake Game - 
Netlogo dictionary - https://ccl.northwestern.edu/netlogo/docs/dictionary.html#listsgroup
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bomb
false
0
Circle -7500403 true true 74 93 153
Rectangle -1 true false 172 140 194 159
Polygon -2674135 true false 147 60 106 34 144 68
Rectangle -6459832 true false 135 60 150 90
Rectangle -7500403 true true 120 75 180 105
Circle -2674135 true false -44 160 16

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

cake
false
0
Polygon -7500403 true true 67 144 82 114 112 99 157 84 202 99 232 114 247 144 232 174 202 189 157 204 112 189 82 174 67 144
Polygon -6459832 true false 90 135 90 150 180 180 180 165 90 135
Polygon -1 true false 90 135 180 165 180 150 90 120 90 135
Polygon -6459832 true false 180 180 225 135 225 120 180 165
Polygon -1 true false 180 150 225 105 225 120 180 165 180 150
Polygon -6459832 true false 90 120 180 150 225 105 225 90 180 135 90 105 90 120 180 150
Polygon -1 true false 90 105 180 135 225 90 135 60 90 105
Circle -2674135 true false 120 60 30
Circle -2674135 true false 135 90 30
Circle -2674135 true false 180 75 30

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

snake-head
true
13
Polygon -2064490 true true 74 73 74 223 224 223 224 73 74 73
Rectangle -1 true false 165 135 195 180
Rectangle -1 true false 105 135 135 180
Rectangle -16777216 true false 120 135 135 165
Rectangle -16777216 true false 165 135 180 165
Rectangle -7500403 true false 131 90 135 111
Rectangle -7500403 true false 165 90 169 107
Polygon -1 true false 120 75 135 60 150 75 165 60 180 75 120 75

snake-winner
true
13
Polygon -2064490 true true 74 73 74 223 224 223 224 73 74 73
Rectangle -1 true false 165 135 195 180
Rectangle -1 true false 105 135 135 180
Rectangle -16777216 true false 120 135 135 165
Rectangle -16777216 true false 165 135 180 165
Rectangle -7500403 true false 131 90 135 111
Rectangle -7500403 true false 165 90 169 107
Polygon -1 true false 120 75 135 60 150 75 165 60 180 75 120 75
Polygon -1184463 true false 225 225
Polygon -1184463 true false 225 195 75 195 75 270 105 240 150 270 195 240 225 270 225 195
Polygon -2674135 true false 150 210 135 240 150 255 165 240 150 210
Polygon -13791810 true false 210 210 210 240 195 225 210 210
Polygon -13791810 true false 90 210 90 240 105 225 90 210

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
