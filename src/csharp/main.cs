using System;
using System.Collections.Generic;

class Bst {
    static void Main() {
        var set = new SortedSet<ulong>();
        for (ulong i = 0; i < 1000000; i++) {
           set.Add(i);
        }
        Console.WriteLine(set.Count);
    }
}
