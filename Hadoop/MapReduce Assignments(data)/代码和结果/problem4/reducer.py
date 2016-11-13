import MapReduce, sys
import json

mr = MapReduce.MapReduce()


def reducer():
    for line in sys.stdin:
        intermediate = json.loads(line)
        for key in intermediate:
            person = key
            list_of_friends = intermediate[key]
            friendCount = {}
            for friend in list_of_friends:
                friendCount.setdefault(friend, 0)
                friendCount[friend] = friendCount[friend] + 1

            asymfriends = filter(lambda x : friendCount[x] == 1, friendCount.keys())

            for friend in asymfriends:
                mr.emit((person, friend))

    print json.dumps(mr.result)

reducer()