import std.container.rbtree : redBlackTree;
import std.stdio : writeln;

void main() {
    auto set = redBlackTree!ulong;
    foreach (i; 0 .. 1000000) {
        set.insert(i);
    }
    writeln(set.length);
}
