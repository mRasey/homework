import sys,json,MapReduce

mr = MapReduce.MapReduce()


def reducer():
    for line in sys.stdin:
        intermediate = json.loads(line)
        for key in intermediate:
            trimmedNucleotide = key
            mr.emit(trimmedNucleotide)
    print json.dumps(mr.result)

reducer()