package main

import (
	"fmt"
	"github.com/emirpasic/gods/sets/treeset"
	"github.com/emirpasic/gods/utils"
)

func main() {
	set := treeset.NewWith(utils.UInt64Comparator)
	for i := uint64(0); i < 1000000; i++ {
		set.Add(i)
	}
	fmt.Println(set.Size())
}
