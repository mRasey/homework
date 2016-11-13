import MapReduce, sys
import json

mr = MapReduce.MapReduce()


def reducer():
    for line in sys.stdin:
        intermediate = json.loads(line)
        for key in intermediate:
            values = intermediate[key]
            global order
            for value in values:
                if value[0] == 'order':
                    order = value

            for value in values:
                if value[0] == 'line_item':
                    mr.emit((order + value))

    print json.dumps(mr.result)

reducer()