import MapReduce, sys
import json

mr = MapReduce.MapReduce()


def mapper():
    # key: document identifier
    # value: document contents
    for line in sys.stdin:
        args = json.loads(line)
        fileName = args[0]
        value = args[1]
        words = value.split()
        for w in words:
            mr.emit_intermediate(w, fileName)
        print json.dumps(mr.intermediate)


mapper()