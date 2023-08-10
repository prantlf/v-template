# Benchmarks

The more complicated the template becomes, the faster is the compiled version. Not speaking about the vastly incomplete functionality of the interpreted version for this benchmark. Replacing placeholders in a loop is added just for comparison how slow it is:

    ❯ ./bench/bench-engine.vsh
     SPENT   140.147 ms in literal replaced
     SPENT   134.651 ms in literal interpreted
     SPENT   596.321 ms in literal compiled template
     SPENT   498.110 ms in literal compiled replacer
     SPENT  1927.581 ms in variable replaced
     SPENT   734.509 ms in variable interpreted
     SPENT   584.025 ms in variable compiled template
     SPENT   512.390 ms in variable compiled replacer
     SPENT   239.992 ms in loop interpreted
     SPENT   171.463 ms in loop compiled template
     SPENT  2325.957 ms in version replaced
     SPENT   516.118 ms in version interpreted
     SPENT   473.142 ms in version compiled template
     SPENT   381.282 ms in version compiled replacer
     SPENT  1961.059 ms in commit interpreted
     SPENT  1178.638 ms in commit compiled template

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
