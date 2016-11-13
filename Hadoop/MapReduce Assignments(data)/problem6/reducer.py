import sys,MapReduce
import json

# globals
mr = MapReduce.MapReduce()


# key is (row,col) and values have to be operated on
def reducer():
    for line in sys.stdin:
        intermediate = json.loads(line)
        for key in intermediate:
            values = intermediate[key]
            values = list(values)
            a_rows = filter(lambda x : x[0] == 'a', values)
            b_rows = filter(lambda x : x[0] == 'b', values)

            result = 0
            for a in a_rows:
                for b in b_rows:
                    if (a[2]==b[1]):
                        result += a[3] * b[3]

            # emit non-zero results
            if (result != 0):
                key = eval(key)
                mr.emit((key[0], key[1], result))

    print json.dumps(mr.result)

reducer()