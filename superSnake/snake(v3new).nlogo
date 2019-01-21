;brad-2 - infinity
;Steven Lee, David Hu, Lukas Chin
;IntroCS1 pd04
;Final Project -- superSnake
;2018-01-18

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
  Spawn-1;Where first snake spawns
  Spawn-2;Where second snake spawns.
  Restrict-1;What patches kills snake1
  Restrict-2;same but for snake2
  Mode-selector;Allows you to change Gamemode in-game without breaking game.
  Comp-timer; timer for competitive
  bombs?;decides if there are bombs for that gamemode (no longer a choice)
  Name1;Label of snake 1
  Name2;Label of snake 2
  Map0;Used as the base for the functions
  Map1;1st Player-Created Maps
  Map2;2nd Map
  Map3;3rd Map
]

patches-own [
  tail-1;Which part of snake 1 it is. Tail would be length. Head would be 1
  tail-2;Which part of snake 2 it is.
  snake? ;if it is a snake or not
  id ;identity of the snake
  #_Of_Cakes-value; how much length the #_Of_Cakes provides
  bomb-timer; how much time left until bomb disappears/explodes.
]
breed [snakes-1 snake-1]
breed [snakes-2 snake-2]
breed [cakes cake]
breed [bombs bomb]

;;Startup Functions
to startup;this should ask you to select mode and names
  set name1 user-input "Name of Snake 1"
  set name2 user-input "Name of Snake 2"
  switch-mode
  Credits-screen
end

to switch-mode;Prompts you to select gamemode and player number.
  set gamemode user-one-of "Which Gamemode?"
  ["Normal" "No Competition" "Friendly World Dig" "Competitive"]
  set #_Of_Players user-one-of "How many #_Of_Players?"
  [1 2]
end
;
;;Main functions
;Setup sets up world
to setup
  variable-setup
  Mode
  world-setup
  Map-selector
  snake-setup
  reset-ticks
end

to variable-setup ;workaround for ca. Not all globals will be cleared, only some of them after each setup.
  set inputxy-1 []
  set inputxy-2 []
  set length-1 0
  set length-2 0
  set bomb-2 0
  set bomb-1 0
  set restrict-1 []
  set restrict-1 []
  set gamewinner 0
  set mode-selector "normal"
  set Comp-timer 0
  set bombs? true
  set Map0 0
  ifelse reset? = 0 [
    set wins [0 0]
    set game-number 0
    set reset? 1
  ]
  [set game-number game-number + 1]
  cp
  ct
end

;Go runs the game (model)
to go
  if any? snakes-1 or any? snakes-2[
    if any? snakes-1 [snake-1move]
    if any? snakes-2 [snake-2move]
    Mode-go
    if bombs? [bomb-tick
      bomb-explode]
    wait (10 - speed) * .015
    single-player-message
    tick
  ]
end
;

;;Snake life-cycle
;sets up the snakes
to snake-setup
  ask Spawn-1 [set snake? 1] ;player 1
  ask one-of patches with [snake? = 1] [
    set pcolor blue
    set length-1 3
    set id 1
    sprout-snakes-1 1[ ;makes snake head
      set label Name1
      set shape "snake-head"
      set color blue
      set size 2.5
      set heading 0
    ]
    set tail-1 1
  ]
  ask Spawn-2 [set snake? 1]
  if #_Of_Players != 1 [ ;checks if there is more than 1 player
    ask one-of patches with [snake? = 1 and pcolor != blue] [ ;player 2
      set pcolor red
      set length-2 3
      set id 2
      sprout-snakes-2 1[ ;makes snake head
        set label Name2
        set shape "snake-head"
        set color red
        set size 2.5
        set heading 1
      ]
      set tail-2 1
    ]
  ]
  set inputxy-1 [0 1]
  set inputxy-2 [0 -1]
end

to snake-1move ;controls how player 1 moves
  ask snake-1 0 [
    move-to patch-at (item 0 inputxy-1)(item 1 inputxy-1) ;moves to patch depending on controller input
    snake-eat 1
    snake-die restrict-1
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
    snake-die restrict-2
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
    [set length-1 length-1 + #_Of_Cakes-value] ;depending on the player, if a snake is on a #_Of_Cakes patch, it sets its length to the length + the #_Of_Cakes value of the patch.
    if long = 2
    [set length-2 length-2 + #_Of_Cakes-value]
    Reset-patches
    ask patch-here [
      set #_Of_Cakes-value 0
      ask cakes with [xcor = [pxcor] of myself and ycor = [pycor] of myself] [die]
    ] ;resets patch #_Of_Cakes-value
  ]
end

to snake-die [n]
  if member? pcolor n;if a snake hits another or itself, it dies.
  [
    ask patches with [pcolor = [color] of myself] [
      Reset-patches
    ]
    die
  ]
  if pcolor = white ;if a snake hits a bomb, it dies, regardless if the bomb explodes or not
  [
    set bomb-timer 0 bomb-explode
  ]

end

to reset-patches ;resets patches to background color. Also clears patch variables.
  set pcolor (pxcor + pycor) mod 2 + 56
  set id 0 set snake? 0 set tail-1 0 set tail-2 0 set #_Of_Cakes-value 0
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
to #_Of_Cakes-spawn [num] ;spawns the #_Of_Cakes depending on the #_Of_Cakes slider
  ask n-of num patches with [pcolor = 56 or pcolor = 57] [
    set #_Of_Cakes-value (random 3) + 1
    set pcolor scale-color brown #_Of_Cakes-value -3 6
    sprout-cakes 1  [set shape "cake" set size 3]
  ]
end

to #_Of_Cakes-spawn-competitive [side] ;spawns #_Of_Cakes for competitive gamemode
  if count patches with [#_Of_Cakes-value > 0 and (side * pxcor) > 0] < #_Of_Cakes
  [
    ask one-of patches with [pcolor = 56 or pcolor = 57 and (side * pxcor) > 0] [
      set #_Of_Cakes-value (random 3) + 1
      set pcolor scale-color brown #_Of_Cakes-value -3 6
      sprout-cakes 1  [set shape "cake" set size 3]
  ]]
end

to world-setup ;sets up the world
  set-patch-size 14
  ask patches with [pcolor = 0][Reset-patches] ;creates checkerboard pattern
end

to #_Of_Cakes-spawn-go ;spawns #_Of_Cakes as the game runs
  if count patches with [#_Of_Cakes-value > 0] < #_Of_Cakes
  [#_Of_Cakes-spawn 1]
end

;;Maps- using chooser "Maps," creates different maps with different obstacles
to map-selector
  if Maps = "Border" [border_map]
  if Maps = "Hideout" [hideout_map]
  if Maps = "Space" [space_map]
  if Maps = "Mount" [mount_map]
  if Maps = "Minecraft" [minecraft_map]
  if Maps = "Map1" [Original-Map Map1]
  if Maps = "Map2" [Original-Map Map2]
  if Maps = "Map3" [Original-Map Map3]
end

;maps are made using pxcor and pycor and certain rules for the pxcor and pycor.
to border_map
  ask patches with [pxcor = max-pxcor or pxcor = min-pxcor or pycor = min-pycor or pycor = max-pycor]
  [set pcolor 88]
end

to hideout_map
  ask patches with [(abs pxcor = max-pxcor and abs pycor > 4) or (abs pycor = max-pycor and abs pxcor > 4)
    or (abs pxcor = 4 and abs pycor > 10) or (abs pycor = 4 and abs pxcor > 10)
    or (8 < abs pxcor and abs pxcor < 12 and 8 < abs pycor and abs pycor < 12)]
  [set pcolor 88]
end

to space_map
  ask patches with [(pxcor = 0 and max-pycor >= abs pycor and abs pycor > 13) or (pycor = 0 and max-pxcor >= abs pxcor and abs pxcor > 13)
    or (abs pxcor >= 15 and abs pxcor <= 16 and abs pycor >= 15 and abs pycor <= 16)
    or (abs pxcor >= 23 and abs pxcor <= 24 and abs pycor >= 23 and abs pycor <= 24)]
  [set pcolor 88]
end

to mount_map
  ask patches with [(abs pxcor > 3 and abs pxcor < 10 and abs pycor = 13) or (abs pycor > 3 and abs pycor < 10 and abs pxcor = 13)
    or (abs pxcor >= 16 and abs pxcor <= 21 and abs pycor >= 16 and abs pycor <= 21)
    or (abs pxcor >= 6 and abs pxcor <= 10 and pycor >= -2 and pycor <= 2)
    or (abs pycor = max-pycor and abs pxcor <= 3)]
  [set pcolor 88]
end

to minecraft_map
  ask patches with [abs pxcor >= 3 and abs pycor >= 3 and pxcor mod 2 + pycor mod 2 = 2]
  [set pcolor 88]
end

;;All Bomb Functions
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

;Bomb Explodes and blinks shortly before exploding.
to bomb-explode
  ask patches with [bomb-timer = 0 and pcolor = white]
  [ask bombs in-radius 3[die]
    if gamemode = "normal" [bomb-reduce]
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

to snake2-win ;snake2's victory annimation
  ask snakes-2 [set shape "snake-winner"]
  if gamewinner = 0 [
    set wins replace-item 1 wins ((item 1 wins) + 1)
    set gamewinner 1
    victory-animation 2]
end

to snake1-win ;snake1's victory animation
  ask snakes-1 [set shape "snake-winner"]
  if gamewinner = 0 [
    set wins replace-item 0 wins ((item 0 wins) + 1)
    set gamewinner 1
    victory-animation 1]
end

to victory ;victory crown for snake
  if #_Of_Players > 1[
    if (count snakes-1 + count snakes-2 = 0)
      [User-message (word "You both died")
        if ask-mode? [switch-mode] setup]
    if (not any? snakes-1) [
      snake2-win
    ]
    if (not any? snakes-2) [
      snake1-win
    ]
  ]
end

to comp-victory ;Competitive timer-victory
  ifelse length-1 = length-2
  [ifelse user-yes-or-no? (word  "It's a tie. Restart?" )
    [if ask-mode? [switch-mode] setup][set comp-timer 300]]
  [ifelse length-1 > length-2
    [snake1-win]
    [snake2-win]]
end

to victory-animation [snake] ;sends the message to the user that the winning snake has won. Then asks whether to continue to another game (yes), let the winning snake keep playing (no), or to stop (halt).
  if user-yes-or-no? (word "Snake " snake " has won the game. Restart?" )
  [if ask-mode? [switch-mode] setup]
end

to single-player-message
  if #_Of_Players = 1 and
  not any? snakes-1
  [if user-yes-or-no? (word  "Restart?" )
    [if ask-mode? [switch-mode]
      setup]]
end

to-report P1-Score ;reports how many times player 1 won
  report item 0 wins
end

to-report P2-Score ;reports how many times player 2 won.
  report item 1 wins
end

to reset-wins ;resets win counter
  set wins [0 0]
end


;
;Gamemodes Like Mini-Games.
;;;VERY IMPORTANT PLACE.

to Mode

  if Gamemode = "Normal";Typical setup. Everything basically kills you
  [normal-game
  ]

  if Gamemode = "No Competition";Typical setup. opponent can't kill you
  [nocompetition-game
  ]

  if Gamemode = "Friendly World Dig";Causal Minecraft mining
  [Dig-Game
  ]

  if Gamemode = "Competitive"; Competition style snake. No bombs
  [Competitive-game
  ]

  if Gamemode = "Death-Match"; DeathMatch, no food self increases.
  [DeathMatch-Game
  ]
  SPaWn-selector
  set Mode-selector Gamemode ;prevents game glitches when switching in game.
end

to normal-game
  resize-world -24 24 -24 24
  set restrict-1 [red blue yellow orange 88 18 1];These are the patch colors that kill in normal
  set restrict-2 restrict-1
  set bombs? true
end

to nocompetition-game
  resize-world -24 24 -24 24
  set restrict-1 [blue yellow orange 88 18 1]
  set restrict-2 [red yellow orange 88 18]
  set bombs? true
end

to Dig-game
  resize-world -24 24 -24 24
  set bombs? true
  ask patches [Reset-patches]
  ask n-of 50 patches with [abs (pxcor) > 4]
  [ask patches in-radius (random 3 + 1)[set pcolor 4 + random 3]]
  set maps "Plain"
  set restrict-1 [4 5 6]
  set restrict-2 [4 5 6]
end

to Competitive-game
  set restrict-1 [red blue yellow orange 88]
  set bombs? false
  set restrict-2 restrict-1
  set maps "Plain"
  resize-world -49 49 -24 24
  ask patches with
  [member? pxcor [0 -49 49] or member? pycor [-24 24]]
  [set pcolor 88]
  set comp-timer 900
end

to Deathmatch-game
  set comp-timer 75
  set restrict-1 [red blue yellow orange 88 18 1]
  set restrict-2 restrict-1
  set bombs? true
end


to spawn-selector;Chooses snakes spawn points (depends on the gamemode)
  ifelse Gamemode = "Competitive"
  [
    set Spawn-1 (patch -24 0)
    set Spawn-2 (patch 24 0)
  ][
    set Spawn-1 (patch -1 0)
    set Spawn-2 (patch 1 0)
  ]
end

to Mode-go; This is the basis for the changed actions during the different modes. Includes #_Of_Cakes-spawn and other non-universal functions here.
  if member? Mode-selector ["Normal" "No Competition"]
    [#_Of_Cakes-spawn-go Victory]

  if Mode-selector = "Friendly World Dig"
  [bomb-tick
    if count patches with [member? pcolor [4 5 6]] = 0
    [set Mode-selector "Normal"
      ask turtles with [who <= 1][set shape "snake-winner"]
      User-message (word "You cleared the world")
  ]]

  if Mode-selector = "Competitive"
  [Comp-go
  ]

  if Mode-selector = "Death-Match"
  [Match-go
  ]
end

to Comp-go;competitive go
  #_Of_Cakes-spawn-competitive -1
  #_Of_Cakes-spawn-competitive 1
  set comp-timer comp-timer - 1
  if comp-timer = 0 [comp-victory]
  Victory
end

to Match-go
  set comp-timer comp-timer - 1
  if comp-timer = 0
  [set length-1 length-1 + random 2 + 1
    set length-2 length-2 + random 2 + 1
    set comp-timer 45]
  Victory
end


;;Misc
to credits-screen ;credit screen, makes patches form the words "Super Snake by b-rad2 - infinity"
  ct
  ask patches [ reset-patches ]
  ask patches at-points [[2 7] [19 13] [13 7] [-3 12] [10 13] [5 10];Don't Worry We did not manually create this
    [-18 15] [0 12] [-11 18] [-8 10] [5 8] [11 7] [-13 19] [0 6] [-17 13]
    [0 8] [3 7] [-4 7] [-13 7] [16 9] [-16 13] [16 10] [-8 11] [11 13]
    [-11 12] [-5 7] [-18 19] [13 10] [0 2] [-17 7] [4 13] [3 13] [0 5]
    [-11 11] [5 12] [9 7] [17 13] [-18 16] [0 3] [8 7] [10 10] [8 11]
    [0 13] [-17 19] [8 8] [0 4] [0 1] [-11 8] [13 13] [-12 7] [10 7]
    [12 10] [-18 8] [-15 7] [-8 13] [16 11] [-14 19] [-11 7] [16 12]
    [0 11] [-3 13] [-3 8] [8 10] [16 7] [-18 14] [13 12] [4 7] [9 13]
    [-8 9] [2 13] [-16 19] [8 12] [-11 19] [16 8] [-12 19] [12 7] [-11 17]
    [-12 13] [-8 7] [16 13] [5 9] [-11 13] [12 13] [-18 18] [-3 7] [-14 13]
    [-15 19] [8 9] [-14 7] [-18 17] [-18 13] [-3 10] [5 7] [13 11] [8 13]
    [1 13] [-15 13] [-11 9] [-11 10] [-8 8] [5 13] [-7 7] [0 10] [0 7]
    [5 11] [0 9] [-3 11] [18 13] [11 10] [-6 7] [-13 13] [-16 7] [-8 12] [-3 9] [-18 7]]
  [ask patch-at -4 0 [set pcolor red]]
  ask patches at-points [[-14 4] [11 -2] [15 -6] [15 -5] [-13 -8] [0 -8] [-7 -2] [5 -6];We used our Devtools to do most of the work
    [-17 -2] [-6 -2] [8 -8] [-11 3] [12 0] [-16 -2] [-18 3] [-8 -3] [15 -3] [20 -8] [0 -2]
    [19 -2] [-11 -4] [10 -4] [8 2] [-8 -7] [9 -2] [-11 -6] [20 -3] [-12 -8] [12 -5] [-15 -8]
    [17 -8] [8 -2] [-11 -7] [11 -5] [-18 -7] [-18 4] [5 -2] [12 -2] [17 -2] [15 -2] [0 -4]
    [12 -7] [4 -8] [-14 -8] [10 -2] [-8 -2] [8 -4] [-14 -2] [20 -5] [-17 -8] [0 -6] [15 -7]
    [-13 -2] [16 -2] [-15 4] [-16 4] [5 -4] [-3 -8] [-13 4] [3 -8] [-8 -8] [19 -8] [-11 -8]
    [-3 -5] [-18 -2] [8 -5] [-3 -3] [-18 0] [0 -7] [-11 -2] [0 -3] [-15 -2] [12 -6] [-8 -4]
    [16 -8] [-17 4] [2 -2] [18 -5] [5 -8] [19 -5] [18 -2] [11 -4] [-18 1] [-3 -4] [-8 -5]
    [18 -8] [5 -5] [5 -3] [-18 2] [8 -1] [9 -4] [20 -4] [8 0] [-12 4] [12 -1] [17 -5] [8 -7]
    [-3 -2] [-11 -3] [15 -8] [-3 -6] [3 -2] [-12 -2] [-3 -7] [0 -5] [-16 -8] [-11 4] [-4 -2]
    [15 -4] [-18 -1] [-5 -2] [8 1] [-18 -8] [1 -2] [-8 -6] [4 -2] [2 -8] [-11 -5] [1 -8] [20 -2] [8 -6] [12 -8]]
  [ask patch-at -4 0 [set pcolor blue]]
  ask patches at-points [[-11 17] [-8 13] [0 1] [10 10] [19 13] [-18 -7] [-3 -8] [12 0] [8 -8] [17 -5] [5 -6]]
  [
    ask patch-at -4 0
    [sprout 1 [set shape "snake-head" set color pcolor set size 2.5]]
  ]
  ask patches at-points [[22 -20] [15 -20] [-13 -19] [12 -18] [22 -16] [0 -16] [16 -19] [-4 -20] [3 -18];MODULAR DESIGN BOIS
    [-6 -16] [-15 -20] [7 -18] [3 -16] [4 -16] [-11 -19] [-4 -18] [-9 -20] [-13 -20] [1 -16] [0 -17] [2 -16];We just don't want to import pcolors
    [-13 -18] [18 -19] [2 -21] [-11 -22] [-6 -19] [19 -16] [-12 -20] [13 -16] [3 -21] [-6 -17] [16 -17] [-6 -18]
    [12 -16] [12 -17] [-11 -20] [14 -16] [-6 -20] [2 -18] [21 -20] [2 -19] [-9 -18] [-5 -20] [2 -23] [22 -17]
    [4 -20] [-17 -20] [-15 -19] [8 -18] [22 -18] [18 -17] [-4 -19] [-11 -18] [-16 -18] [-2 -19] [9 -18] [2 -22]
    [20 -20] [0 -18] [-17 -19] [-11 -21] [17 -18] [22 -19] [-15 -18] [12 -20] [-17 -16] [-17 -17] [19 -20]
    [21 -16] [15 -16] [13 -20] [14 -20] [-5 -18] [4 -19] [-17 -18] [3 -23] [-1 -20] [4 -23] [4 -18] [0 -19]
    [12 -19] [20 -16] [-16 -20] [-13 -22] [-12 -22]]
  [ask patch-at -5 0 [set pcolor black]]
end

;;Dev Tools- Create own maps and stuff
to Canvas
  Variable-setup
  reset-ticks
  world-setup
end

to paint [color-z];Painting function for maps and credits screen
  if mouse-down?
  [repeat 5
    [ask patch mouse-xcor mouse-ycor [set pcolor color-z]]
    reset-ticks]
end

to erase ;Erasing function- Resets pcolor.
  if mouse-down?
  [ask patch mouse-xcor mouse-ycor [ reset-patches ]
    reset-ticks]
end

to big-erase ;Erases a larger area
  if mouse-down?
  [ask patch mouse-xcor mouse-ycor
    [reset-patches
      ask neighbors[reset-patches]
    ]
    Reset-ticks]
end

to edit ;The all-in-one function depends on Color_
  ifelse any? turtles
  [stop]
  [
    if Color_ = "Paint Blue"[paint 88]
    if Color_ = "Paint Red" [paint 18]
    if Color_ = "Paint Black"[paint 1]
    if Color_ = "Erase" [erase]
    if Color_ = "Big Eraser" [big-erase]
  ]
end

to-report save [color-z] ;Saves patches with a certain pcolor as a list.
  let list-z []
  ask patches with [pcolor = color-z]
  [
    set list-z lput (list (pxcor) (pycor)) list-z
  ]
  report list-z
end

to save-map-go; Saves the patches with an intermedierary
  set Map0 [true]
  set Map0 lput (save 88) Map0
  set Map0 lput (save 18) Map0
  Set Map0 lput (save 1) Map0
end

to Save-map
  let Choice user-one-of "which map?" ["Map1" "Map2" "Map3" "Don't Save"]
  if Choice != "Don't Save"
  [Save-Map-go
    if Choice = "Map1" [set Map1 Map0]
    if Choice = "Map2" [set Map2 Map0]
    if Choice = "Map3" [set Map3 Map0]
  ]
end

to Original-Map [num]; Reads the player-created maps and summons them
  if (is-list? num)
  [ask patches at-points (item 1 num)
    [set pcolor 88]
    ask patches at-points (item 2 num)
    [set pcolor 18]
    ask patches at-points (item 3 num)
    [set pcolor 1]
  ]
end

;;Fun / Experimental
to Divide-by-cake; When length of a snake is 0. everything @#$&! up
  set length-1 0
  set length-2 0
end
@#$#@#$#@
GRAPHICS-WINDOW
446
51
1140
746
-1
-1
14.0
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

BUTTON
7
51
120
160
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
120
51
216
161
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
66
259
129
293
Up
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
300
262
363
296
Up
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
66
326
130
360
Down
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
300
330
364
364
Down
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
129
303
194
337
Right
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
9
304
66
338
Left
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
363
307
429
341
Right
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
243
306
300
340
Left
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

BUTTON
66
292
129
326
Bomb
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
129
259
195
304
Cooldown
100 - bomb-1
17
1
11

MONITOR
363
262
429
307
Cooldown
100 - bomb-2
17
1
11

BUTTON
300
296
363
330
Bomb
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

MONITOR
9
259
66
304
Length
Player1
17
1
11

MONITOR
243
262
300
307
Length
Player2
17
1
11

CHOOSER
12
635
155
680
Maps
Maps
"Plain" "Border" "Hideout" "Space" "Mount" "Minecraft" "Map1" "Map2" "Map3"
3

SLIDER
155
590
298
623
Speed
Speed
0
10
10.0
1
1
NIL
HORIZONTAL

CHOOSER
12
590
155
635
Gamemode
Gamemode
"Normal" "No Competition" "Friendly World Dig" "Competitive" "Death-Match"
4

BUTTON
120
160
216
208
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
228
108
309
165
NIL
P1-Score
17
1
14

MONITOR
309
108
390
165
NIL
P2-Score
17
1
14

BUTTON
14
715
148
748
Cake Apocalypse
Divide-by-Cake
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
12
545
155
590
#_Of_Players
#_Of_Players
1 2
0

CHOOSER
155
545
298
590
#_Of_Cakes
#_Of_Cakes
1 2 3 4 5
1

MONITOR
228
51
390
108
Competitive Timer
ceiling (Comp-timer / 15)
17
1
14

SWITCH
155
623
298
656
Ask-Mode?
Ask-Mode?
1
1
-1000

BUTTON
7
160
120
208
Reset Game
Startup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
12
412
89
501
NIL
Canvas
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
11
380
122
411
DevTools
25
124.0
1

BUTTON
89
412
204
456
NIL
Edit
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
89
456
204
501
Color_
Color_
"Paint Blue" "Paint Red" "Paint Black" "Erase" "Big Eraser"
4

BUTTON
204
412
291
502
Save Map
Save-Map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
121
379
425
409
Note: Use \"Continuous\" mode for the best experience
12
125.0
1

TEXTBOX
8
10
158
49
Play
32
0.0
1

TEXTBOX
8
236
158
261
Player 1
20
105.0
1

TEXTBOX
243
237
393
262
Player 2
20
15.0
1

TEXTBOX
11
515
161
546
Ruleset
25
5.0
1

TEXTBOX
13
687
252
713
Fun / Experimental
25
25.0
1

TEXTBOX
75
10
225
49
super
32
15.0
1

TEXTBOX
156
10
306
49
Snake
32
105.0
1

TEXTBOX
446
12
960
168
The World <ザ・ワールド(世界)>
32
43.0
1

TEXTBOX
228
688
378
708
Note: Use at your own risk
12
25.0
1

@#$#@#$#@
# Welcome to superSnake!

## What is it?

This model will be a modified version of the classic game Snake. 
Snake is a game where a “snake” moves around the world and eats food pellets in order to grow. 
This games adds an interesting twist to Snake; now there are several modes such as "Friendly World Dig" and "Competitive." Snakes can also leave bombs, which you can damage your opponents with. Be wary, however, as you can damage yourself with the bombs too.  
Overall, this project is using the classic game Snake and putting an interesting twist to it in order to make it more fun. 


## Controls

Press "Start" to setup the game. 
Press "Go" to begin the game. 
Pressing "Reset Game" will reset everything, and will start the game from the beginning (from the time you opened the game).
Pressing "Reset Scores" will reset the scores that the players have to 0.

Use WASD to move snake 1.  
Use IJKL to move snake 2.
(Directions should become obvious looking at the keyboard; otherwise, go to the interface tab). 
E will cause snake 1 to drop bombs.
O will cause snake 2 to drop bombs.

## Ruleset

The "Players" chooser will determine how many players there will be in the game. 
The "Gamemode" chooser will choose which gamemode you wish to play in. More information is in the GAMEMODE section. 
The "Maps" chooser will choose which map the world is set to. (For competitive, you cannot choose your map). 
The "# Of Cakes" chooser will determine how many cakes will spawn in the world. (For competitve, it will determine how many cakes per world).
The switch "Ask-Mode?" will toggle whether you wish to be prompted to switch your gamemode everytime. 
You can choose which map to play on using the chooser "Maps." 

## Gamemodes

(insert stuff about gamemodes David)

## DevTools

You can now customize maps in superSnake!
Press "Canvas" to create a blank world, where you will "paint" your masterpiece. 
Press "Edit" to edit the canvas; use the chooser "Edit-mode" to choose how you want to paint or erase. 
Press "Save Map" to save your masterpiece to "Map 1," "Map 2," or "Map 3."
Go back to the chooser "Maps" to choose your saved map, and press Start to play. 

## How it Works

There will be three types of functions that we will use, the ones that control the movements and life cycles for the snake, the ones that control the environment (food pellets, etc.), and the ones that control the different game modes (bombs, # of snakes, etc.). Two main functions, called “setup” and “go” will set up the world of Snake and start the game. These two functions will also incorporate the other functions through modular design. 
Four functions dictate the life cycle of a snake. The first function is called “snake-setup,” which will spawn snakes randomly throughout the world, and set their respective snake variables. The second function will be “snake-move,” which controls how the snakes move throughout the world. This function utilizes modular design, for left, right, up, and down controls. The third function will be “snake-die,” as it will detect if a snake has touched itself or another snake and that kill that snake. The last function will be “snake-eat,” which will manage snake-eating.
For the functions that will control and modify the environment of the snakes, there will be two. One is “world-setup” which will setup the world, clearing the world of food pellets and snakes, and resetting patch and turtle variables. The second function is “food-spawn,” which will spawn food for the snakes to eat. 
Gamemodes are made by modifying the go and setup functions in such a way that they are tailored to each type of gamemode.

## NEW IN VERSION 4.0
+New startup popup
+Choose the names of the snakes
+Victory messages improved
+Removed bombs? switch(if you don't like bombs don't press "E" or "O")
+Competitive Gamemode
+Changed color of the Walls.

VERSION 3.0
+new victory popup
+controllable speed
+bombs now take off length of snake
+new score count
+new game modes

VERSION 2.0
+added bombs mode
+added cake 
+added victory crown for winning snake
+snake is slowed down
+new background for easy viewing
+organized interface 

## CREDITS AND REFERENCES

Original Snake Game - by us.
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
