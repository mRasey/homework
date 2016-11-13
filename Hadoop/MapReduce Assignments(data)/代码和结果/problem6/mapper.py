import sys, MapReduce
import json

# globals
mr = MapReduce.MapReduce()


# record [matrix, i, j, value]
def mapper():
    # print json.dumps(mr.intermediate)
    for line in sys.stdin:
        record = json.loads(line)
        maxI = 10
        maxJ = 10

        if record[0] == 'a':
            i = record[1]
            for j in range(maxJ + 1):
                mr.emit_intermediate(str((i, j)), record)
        elif record[0] == 'b':
            j = record[2]
            for i in range(maxI + 1):
                mr.emit_intermediate(str((i, j)), record)
        else:
            pass

    # print mr.intermediate
    print json.dumps(mr.intermediate)


mapper()
