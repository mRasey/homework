import MapReduce, sys
import json

mr = MapReduce.MapReduce()


def reducer():
    for line in sys.stdin:
        json_info = json.loads(line)
        for key in json_info:
            fileList = []
            fileNames = json_info[key]
            for fileName in fileNames:
                if fileName not in fileList:
                    fileList.append(fileName)
            mr.emit((key, fileList))
    print json.dumps(mr.result)

reducer()