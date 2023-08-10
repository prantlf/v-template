# Benchmarks

The more complicated the template becomes, the faster is the compiled version. Not speaking about the vastly incomplete functionality of the interpreted version for this benchmark:

    ❯ ./bench/bench-map-array.vsh
     SPENT   143.810 ms in literal interpreted
     SPENT   573.106 ms in literal compiled
     SPENT   761.469 ms in variable interpreted
     SPENT   566.645 ms in variable compiled
     SPENT  2401.161 ms in loop interpreted
     SPENT  1723.871 ms in loop compiled
     SPENT  4981.797 ms in heading interpreted
     SPENT  4697.501 ms in heading compiled
     SPENT 19559.776 ms in commit interpreted
     SPENT 11612.019 ms in commit compiled
