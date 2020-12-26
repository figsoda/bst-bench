use std::collections::BTreeSet;

fn main() {
    let mut set = BTreeSet::new();
    for x in 0 .. 1000000 {
        set.insert(x);
    }
}
