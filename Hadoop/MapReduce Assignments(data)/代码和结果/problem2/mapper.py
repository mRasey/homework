import MapReduce, sys
import json

mr = MapReduce.MapReduce()

def mapper():
    for line in sys.stdin:
        args = json.loads(line)
        order_id = args[1]
        value = args
        mr.emit_intermediate(order_id, value)
    print json.dumps(mr.intermediate)


mapper()