import MapReduce, sys
import json

mr = MapReduce.MapReduce()


def reducer():
    for line in sys.stdin:
        intermediate = json.loads(line)
        for key in intermediate:
            name = key
            list_of_values = intermediate[key]
            total = 0
            for v in list_of_values:
                total += v
            mr.emit((name, total))
    print json.dumps(mr.result)

reducer()