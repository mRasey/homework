import MapReduce, sys
import json

mr = MapReduce.MapReduce()


def mapper():
    for line in sys.stdin:
        record = json.loads(line)
        name = record[0]
        mr.emit_intermediate(name, 1)
    print json.dumps(mr.intermediate)

mapper()