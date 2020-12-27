import java.util.TreeSet;

class Main {
    public static void main(String[] args) {
        TreeSet<Long> set = new TreeSet<Long>();
        for (long i = 0; i < 1000000; i++) {
            set.add(i);
        }
        System.out.println(set.size());
    }
}
