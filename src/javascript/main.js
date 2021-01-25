import SortedSet from "collections/sorted-set";

let set = SortedSet();
for (let i = 0; i < 1000000; i++) {
    set.add(i);
}
console.log(set.length.toString());
