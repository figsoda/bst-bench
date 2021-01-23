import scala.collection.mutable.TreeSet

object Main {
  def main(args: Array[String]) = {
    var set = TreeSet.empty[Long];
    for (i <- 0 to 999999) {
      set += i;
    }
    println(set.size);
  }
}
