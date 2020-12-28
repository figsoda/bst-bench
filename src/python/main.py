from bintrees.rbtree import RBTree

xs = RBTree()
for i in range(0, 1000000):
    xs.insert(i, ())
print(len(xs))
