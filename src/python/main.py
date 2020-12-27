from BTrees.QQBTree import QQTreeSet

xs = QQTreeSet()
for i in range(0, 1000000):
    xs.insert(i)
print(len(xs))
