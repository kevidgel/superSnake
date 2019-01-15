globals[
  inputxy-1 ;state of snake 1, as list. ex. [0 1] would be 0 horizontal and 1 vertical.
  inputxy-2 ;state of snake
  length-1 ;length of snake 1
  length-2 ;length of snake 2
  bomb-2; cooldown for 2nd snake.
  bomb-1; cooldown for 1st snake.
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

;;Main functions
;Setup sets up world
to setup
  ca
  ask patches [
    set length-1 0
    set length-2 0
    set food-value 0
  ]
  snake-setup
  world-setup
  reset-ticks
end

;Go runs the game (model)
to go
  if count turtles > 0 [
    if any? snakes-1 [snake-1move]
    if any? snakes-2 [snake-2move]
    food-spawn-go
    reset-patches
    if bombs? [bomb-tick
      bomb-explode]
    tick
  ]
end
;

;;Snake life-cycle
;sets up the snakes
to snake-setup
  ask n-of Players patches [set snake? 1] ;player 1
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
    snake-die
    snake-eat 1
    set pcolor blue set snake? 1 set id 1
    set heading xy-to-heading inputxy-1
  ]
  ask patches with [tail-1 = length-1][
    if (pxcor + pycor) mod 2 = 0 [ set pcolor 56]
    if (pxcor + pycor) mod 2 = 1 [ set pcolor 57]
  ]
  ask patches with [pcolor = blue][set tail-1 tail-1 + 1]
end

to snake-2move ;controls how player 2 moves
  ask snake-2 1 [
    move-to patch-at (item 0 inputxy-2)(item 1 inputxy-2)  ;moves to patch depending on controller input
    snake-die
    snake-eat 2
    set pcolor red set snake? 1 set id 2
    set heading xy-to-heading inputxy-2
  ]
  ask patches with [tail-2 = length-2] [
    if (pxcor + pycor) mod 2 = 0 [ set pcolor 56]
    if (pxcor + pycor) mod 2 = 1 [ set pcolor 57]
  ]
  ask patches with [pcolor = red][set tail-2 tail-2 + 1]
end

to snake-eat [long] ;how snakes eat
  if shade-of? pcolor brown[
    if long = 1
    [set length-1 length-1 + food-value] ;depending on the player, if a snake is on a food patch, it sets its length to the length + the food value of the patch.
    if long = 2
    [set length-2 length-2 + food-value]
    if (pxcor + pycor) mod 2 = 0 [ set pcolor 56]
    if (pxcor + pycor) mod 2 = 1 [ set pcolor 57]
    ask patch-here [set food-value 0] ;resets patch food-value
  ]
end

to snake-die
  if member? pcolor [red blue yellow white] ;if a snake hits another or itself, it dies.
  [
    ask patches with [pcolor = [color] of myself] [
      if (pxcor + pycor) mod 2 = 0 [ set pcolor 56]
      if (pxcor + pycor) mod 2 = 1 [ set pcolor 57]
    ]
    die
  ]
end

to reset-patches
  ask patches with [member? pcolor [56 57]]
  [set id 0 set snake? 0 set tail-1 0 set tail-2 0]
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
  ]
end

to world-setup ;sets up the world
  ask patches [ if (pxcor + pycor) mod 2 = 0 [ set pcolor 56] ]
  ask patches [ if (pxcor + pycor) mod 2 = 1 [ set pcolor 57] ]
  food-spawn food
end

to food-spawn-go ;spawns food as the game runs
  if count patches with [food-value > 0] < food
  [food-spawn 1]
end
;

;;Modes (Bombs)
to bomb-summon [n]
  if bomb-1 = 100 and n = 1[ask patches with [tail-1 = length-1][set tail-1 0 set pcolor white set bomb-timer 200] set bomb-1 0]
  if bomb-2 = 100 and n = 2[ask patches with [tail-2 = length-2][set tail-2 0 set pcolor white set bomb-timer 200] set bomb-1 0]
end
to bomb-tick
  if bomb-1 != 100 [set bomb-1 bomb-1 + 2]
  if bomb-2 != 100 [set bomb-2 bomb-2 + 2]
  ask patches with [bomb-timer = 0 and member? pcolor [orange yellow]][
    if (pxcor + pycor) mod 2 = 0 [ set pcolor 56]
      if (pxcor + pycor) mod 2 = 1 [ set pcolor 57]
  ]
  ask patches with [bomb-timer != 0][set bomb-timer bomb-timer - 1]
end
to bomb-eat
end

to bomb-explode
  ask patches with [bomb-timer = 0 and pcolor = white]
  [ask patches in-radius 2[set pcolor yellow set bomb-timer 10]
    ask patches in-radius 1[set pcolor orange set bomb-timer 10]
  ]
end
;
@#$#@#$#@
GRAPHICS-WINDOW
383
20
820
458
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
100
11
247
44
Players
Players
1
2
1.0
1
1
NIL
HORIZONTAL

BUTTON
3
10
97
119
NIL
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
252
10
348
120
NIL
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
57
143
123
176
NIL
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
49
292
127
325
NIL
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
49
223
128
256
NIL
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
51
383
130
416
NIL
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
98
183
167
216
NIL
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
21
183
78
216
NIL
west 1\n
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
96
337
166
370
NIL
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
8
337
79
370
NIL
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
248
83
Food
Food
1
5
3.0
1
1
NIL
HORIZONTAL

BUTTON
233
184
328
217
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
228
137
313
182
bomb timer
bomb-1
17
1
11

MONITOR
228
293
313
338
bomb timer
Bomb-2
17
1
11

BUTTON
237
341
332
374
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
248
120
Bombs?
Bombs?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model will be a modified version of the classic game Snake. 
Snake is a game where a “snake” moves around the world and eats food pellets in order to grow. 
The snake can only move in the four cardinal directions, and if the snake manages to hit itself, it “dies.” If its head manages to hit other snakes, it dies.

## HOW IT WORKS

There will be three types of functions that we will use, the ones that control the movements and life cycles for the snake, the ones that control the environment (food pellets, etc.), and the ones that control the different game modes (bombs, # of snakes, etc.). Two main functions, called “setup” and “go” will set up the world of Snake and start the game. These two functions will also incorporate the other functions through modular design. 
We have four functions for the life cycle of a snake. The first function will be called “snake-setup,” which will spawn snakes randomly throughout the world, and set their respective snake variables. The second function will be “snake-move,” which will control how the snakes move throughout the world. This function will most likely utilize modular design, for left, right, up, and down controls. The third function will be “snake-die,” as it will detect if a snake has touched itself or another snake and that kill that snake. The last function will be “snake-eat,” which will manage snake-eating.
For the functions that will control and modify the environment of the snakes, there will be two. One is “world-setup” which will setup the world, clearing the world of food pellets and snakes, and resetting patch and turtle variables. The second function is “food-spawn,” which will spawn food for the snakes to eat. 
Finally, we have ideas for functions for a game mode. These functions will be called “bombs-setup,” “bomb-eat,” and “bomb-explode.” Some unactivated bombs (2-3) are randomly distributed throughout the world, where snakes can eat them. The snakes then leave a bomb at the end of their tail, and the bomb will explode after a certain amount of time, killing other nearby snakes. 

## CONTROLS

WASD to move snake 1. IJKL to move snake 2.
E will cause snake 1 to drop bombs.
O will cause snake 2 to drop bombs.
Sliders for food and number of players.
Setup creates the snakes and world.
Go starts the game.


## COMMENTS

Overall, this project is using the classic game Snake and putting an interesting twist to it in order to make it more fun. 

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

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

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
