import java.util.TreeSet;

fun main() {
    var set = TreeSet<Long>()
    LongRange(0, 999999).forEach({ i -> set.add(i) })
    println(set.size)
}
