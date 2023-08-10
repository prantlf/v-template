# Benchmarks

The more complicated the template becomes, the faster is the compiled version. Not speaking about the vastly incomplete functionality of the interpreted version for this benchmark. Replacing placeholders in a loop is added just for comparison how slow it is:

    ❯ ./bench/bench-engine.vsh
     SPENT   127.275 ms in literal replaced
     SPENT   117.054 ms in literal interpreted
     SPENT   564.426 ms in literal compiled
     SPENT  1899.587 ms in variable replaced
     SPENT   740.287 ms in variable interpreted
     SPENT   593.109 ms in variable compiled
     SPENT   247.030 ms in loop interpreted
     SPENT   172.086 ms in loop compiled
     SPENT  2581.635 ms in version replaced
     SPENT   545.186 ms in version interpreted
     SPENT   496.592 ms in version compiled
     SPENT  1845.515 ms in commit interpreted
     SPENT  1210.958 ms in commit compiled

A structure with six fields is faster or on par with a string map:

    ❯ ./bench/bench-maps.vsh
     SPENT    65.044 ms in string-array map has one
     SPENT    69.445 ms in two map has one
     SPENT    22.880 ms in struct has one
     SPENT    38.297 ms in string-array map has more
     SPENT    47.984 ms in two map has more
     SPENT    10.692 ms in struct has more
     SPENT   234.070 ms in string-array map get one from one
     SPENT   274.706 ms in two map get one from one
     SPENT   113.140 ms in struct get one from one
     SPENT    35.674 ms in string-array map get one from more
     SPENT    50.266 ms in two map get one from more
     SPENT    62.973 ms in struct get one from more
     SPENT    82.240 ms in string-array map get more from one
     SPENT   248.378 ms in two map get more from one
     SPENT   163.975 ms in struct get more from one
     SPENT    83.744 ms in string-array map get more from more
     SPENT   105.447 ms in two map get more from more
     SPENT    53.286 ms in struct get more from more
