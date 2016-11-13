import MapReduce, sys
import json

mr = MapReduce.MapReduce()


def mapper():
    for line in sys.stdin:
        friendship = json.loads(line)
        mr.emit_intermediate(friendship[0], friendship[1])
        mr.emit_intermediate(friendship[1], friendship[0])
    print json.dumps(mr.intermediate)


mapper()
