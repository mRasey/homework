import sys,json,MapReduce

mr = MapReduce.MapReduce()


def mapper():
    for line in sys.stdin:
        dnaseq = json.loads(line)
        seqId = dnaseq[0]
        nucleotide = dnaseq[1]
        trimmedNucleotide = nucleotide[:-10]
        mr.emit_intermediate(trimmedNucleotide, seqId)
    print json.dumps(mr.intermediate)

mapper()