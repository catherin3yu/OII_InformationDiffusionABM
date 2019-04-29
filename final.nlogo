extensions [nw]

turtles-own
[
  infected?
  p
]

globals [disconnected-nodes-num ;; the number of disconnected nodes
         global-clustering-coefficient ;; global clustering coefficient of the network
         total-informed ;; the number of informed nodes
         total-uninformed ;; the number of un-informed nodes
         avg-dist ;; average shortest path lengths among all pairs of nodes across all components
         pa timestep
]

to setup
  clear-all
  reset-ticks
  set-default-shape turtles "circle"

  if network-structure = "Barabási–Albert"[
    ;create-turtles total-num
    ;ask turtles [set color green]
    setup-pa-network
  ]
  if network-structure = "Erdős–Rényi"[
    setup-er-network
  ]
  if network-structure = "Watts–Strogatz"[
    setup-ws-network
  ]
  ask turtles [ set size 100 / total-num ]
  ask turtles [become-susceptible]
  ask turtles [choose-p]

  layout-circle (sort turtles) max-pxcor - 2
  report-figures
  ;; seed with a certain number of information sources governed by seed-num
  ask n-of seed-num turtles with [count link-neighbors > 0] [become-infected]
  p-dist-plot
  deg-dist-plot
end


to setup-pa-network
  ;; generate a preferential attachement network
  ;; fully connected, degree distribution obeys power law
  nw:generate-preferential-attachment turtles links total-num neighbor-num [ set color green ]
end

to setup-er-network
  ;; generates a Erdos-Renyi network
  ;; each node is connected to any other node with the fixed probability edge-probability
  ;ask turtles [
  ;  ask other turtles  with [who < [who] of myself] [
  ;    if random-float 1 < edge-probability [
  ;      create-link-with myself
  ;    ]
  ;  ]
  ;]
  nw:generate-random turtles links total-num edge-probability [ set color green ]
end

to setup-ws-network
  nw:generate-watts-strogatz turtles links total-num neighbor-num rewire-probability [ set color green ]
end


to p-dist-plot
  set-current-plot "Distribution of transmission p"
  histogram [p] of turtles
end

to deg-dist-plot
  set-current-plot "Degree distribution"
  histogram [count link-neighbors] of turtles
end

to report-figures
  ;; find the number of disconnected points of the network
  set disconnected-nodes-num count turtles with [count link-neighbors = 0]
  ;; calculate global clustering coefficient
  let closed-triplets sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of turtles
  let triplets sum [ count my-links * (count my-links - 1) ] of turtles
  set global-clustering-coefficient closed-triplets / triplets
  ;; count the number of infected nodes
  set total-informed count turtles with [color = red]
  ;; count the number of uninfected nodes
  set total-uninformed count turtles with [color = green]
  compute-avg-distance

end


to compute-avg-distance
  let source-turtle 0
  let total-dist 0
  let total-pairs 0
  set avg-dist 0

  ask turtles
  [
     set source-turtle who
     ask other turtles with [who > source-turtle]
     [
       let dist nw:distance-to myself

       ;Following lines are for showing pairwise distances
       ;write source-turtle
       ;write "->"
       ;write who
       ;write ":"
       ;show dist

       if (dist != false) ;the two turtles are connected
       [
         set total-dist total-dist + dist
         set total-pairs total-pairs + 1
       ]
     ]
   ]

  if (total-pairs != 0) ; to avoid division by 0
  [
    set avg-dist total-dist / total-pairs
  ]

end


to go
  spread-virus
  let total-informed-old total-informed
  ask turtles with [ any? link-neighbors with [ color = red] ] [set color red]
  report-figures
  set-current-plot "Incremental percentage of nodes"
  let incre-perc (total-informed - total-informed-old) / total-num * 100
  if incre-perc = 0 [ ;; stop if all agents are infected
    stop
  ]
  plot incre-perc
  set-current-plot "Percentage of nodes infected"
    let percent-saturated ((count turtles with [color = red ] ) / (count turtles)) * 100
  plot percent-saturated
  display
  ;]
  set timestep timestep + 1
end

;to-report percent-saturated
;  report ((count turtles with [color = red ] ) / (count turtles)) * 100
;end



to layout
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links 0.2 6 0.2
    display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

to resize
  ifelse all? turtles [size <= 1]
  [
    ;; a node is a circle with diameter determined by
    ;; the SIZE variable; using SQRT makes the circle's
    ;; area proportional to its degree
    ask turtles [ set size sqrt count link-neighbors ]
  ]
  [
    ask turtles [ set size 1 ]
  ]
end


to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end

to choose-p
  ifelse p-dist [
    set p random-float transmission-prob
  ][
    set p transmission-prob
  ]
end

to become-infected
  set infected? true
  set color red
end

to become-susceptible
  set infected? false
  set color green
end


to spread-virus
  ask turtles with [infected?]
    [ ask link-neighbors
      ;; Reports the agentset of all turtles found at the other end of any links
      [ if random-float 1 < p
            [ become-infected ] ] ]
end
@#$#@#$#@
GRAPHICS-WINDOW
335
13
789
468
-1
-1
10.9
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
28
24
105
57
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
29
156
201
189
seed-num
seed-num
1
total-num
2.0
1
1
NIL
HORIZONTAL

BUTTON
28
69
111
102
resize
resize
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
29
115
201
148
total-num
total-num
10
1000
161.0
1
1
NIL
HORIZONTAL

SLIDER
29
345
202
378
neighbor-num
neighbor-num
1
total-num / 10
2.0
1
1
NIL
HORIZONTAL

SLIDER
29
254
202
287
transmission-prob
transmission-prob
0
1
0.2
0.001
1
NIL
HORIZONTAL

BUTTON
124
69
199
102
spread
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

PLOT
810
16
1010
148
Percentage of nodes infected
# spread
percentage
0.0
20.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

MONITOR
811
299
1081
344
transitivity
global-clustering-coefficient
3
1
11

MONITOR
1028
353
1227
398
NIL
disconnected-nodes-num
3
1
11

BUTTON
123
24
200
57
NIL
layout
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
29
205
119
238
p-dist
p-dist
0
1
-1000

PLOT
1025
18
1225
148
Distribution of transmission p
NIL
NIL
-0.1
1.1
0.0
30.0
true
false
"" ""
PENS
"default" 0.01 1 -16777216 true "" "histogram [p] of turtles"

MONITOR
810
406
901
451
total-informed
count turtles with [color = red]
3
1
11

MONITOR
906
405
1010
450
total-uninformed
count turtles with [color = green]
3
1
11

PLOT
810
158
1010
291
Incremental percentage of nodes
# spread
percentage
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

SLIDER
29
385
202
418
rewire-probability
rewire-probability
0
1
1.0
0.001
1
NIL
HORIZONTAL

CHOOSER
29
295
223
340
network-structure
network-structure
"Barabási–Albert" "Erdős–Rényi" "Watts–Strogatz"
0

MONITOR
1027
299
1227
344
edge-num
count links
3
1
11

PLOT
1027
158
1227
291
Degree distribution
NIL
NIL
0.0
20.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [count link-neighbors] of turtles"

TEXTBOX
213
256
328
298
input for fixed p \nor mean of i.i.d
11
0.0
1

TEXTBOX
132
193
272
249
choose distribution of transmission probability:\non: i.i.d \noff: fixed value
11
0.0
1

SLIDER
29
427
206
460
edge-probability
edge-probability
0
10 / total-num
0.008
0.0001
1
NIL
HORIZONTAL

TEXTBOX
209
348
359
376
input for Watts–Strogatz\nand Barabási–Albert
11
0.0
1

TEXTBOX
208
393
358
411
input for Watts–Strogatz
11
0.0
1

TEXTBOX
206
436
356
454
input for Erdős–Rényi 
11
0.0
1

MONITOR
811
352
1010
397
avg-shortest-path-length
avg-dist
3
1
11

MONITOR
1029
406
1138
451
NIL
timestep
17
1
11

@#$#@#$#@
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
<experiments>
  <experiment name="experiment 2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>count (turtles with [infected?])</metric>
    <enumeratedValueSet variable="recovery-chance">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="virus-check-frequency">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="gain-resistance-chance" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <steppedValueSet variable="virus-spread-chance" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count links</metric>
    <metric>disconnected-nodes-num</metric>
    <metric>global-clustering-coefficient</metric>
    <metric>avg-dist</metric>
    <metric>timestep</metric>
    <metric>total-informed</metric>
    <enumeratedValueSet variable="edge-probability">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-num">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-num">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-dist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;Erdős–Rényi&quot;"/>
      <value value="&quot;Watts–Strogatz&quot;"/>
      <value value="&quot;Barabási–Albert&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire-probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-num">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="dynamic" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>timestep</metric>
    <enumeratedValueSet variable="edge-probability">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-num">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-num">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-dist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;Erdős–Rényi&quot;"/>
      <value value="&quot;Watts–Strogatz&quot;"/>
      <value value="&quot;Barabási–Albert&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire-probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-num">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ws" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>timestep</metric>
    <metric>avg-dist</metric>
    <metric>global-clustering-coefficient</metric>
    <enumeratedValueSet variable="edge-probability">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-num">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-num">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-dist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;Watts–Strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire-probability">
      <value value="0.001"/>
      <value value="0.00316"/>
      <value value="0.01"/>
      <value value="0.03162"/>
      <value value="0.1"/>
      <value value="0.31623"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-num">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="dynamic" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>timestep</metric>
    <enumeratedValueSet variable="edge-probability">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-num">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="transmission-prob" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="total-num">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-dist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;Erdős–Rényi&quot;"/>
      <value value="&quot;Barabási–Albert&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire-probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-num">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ws" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>timestep</metric>
    <metric>avg-dist</metric>
    <metric>global-clustering-coefficient</metric>
    <enumeratedValueSet variable="edge-probability">
      <value value="0.008"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbor-num">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-num">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-dist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;Watts–Strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire-probability">
      <value value="0.001"/>
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed-num">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
