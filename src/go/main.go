package main

import (
	"fmt"
	"github.com/emirpasic/gods/sets/treeset"
)

func main() {
	set := treeset.NewWithIntComparator()
	for i := 0; i < 1000000; i++ {
		set.Add(i)
	}
	fmt.Println(set.Size())
}
