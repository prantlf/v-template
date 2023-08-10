# Benchmarks

The more complicated the template becomes, the faster is the compiled version. Not speaking about the incomplete functionality of the interpreted version for this benchmark:

    ❯ ./bench/bench-map-array.vsh
     SPENT   134.967 ms in literal interpreted
     SPENT   629.230 ms in literal compiled
     SPENT   843.317 ms in variable interpreted
     SPENT   644.828 ms in variable compiled
     SPENT  2453.389 ms in loop interpreted
     SPENT  1847.956 ms in loop compiled
