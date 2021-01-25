fn main() {
    let mut set = treez::rb::TreeRb::new();
    for i in 0u64 .. 1000000 {
        set.insert(i, ());
    }
    println!("{}", set.len());
}
