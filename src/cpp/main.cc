#include <cstdint>
#include <iostream>
#include <set>

int main() {
    std::set<uint64_t, std::greater<uint64_t>> set;
    for (auto i = 0; i < 1000000; i++) {
        set.insert(i);
    }
    std::cout << set.size() << std::endl;

    return 0;
}
