package main

import "fmt"

func add(a, b int) int {
	return a + b
}

func main() {
	fmt.Println("Hello from Go!")
	fmt.Printf("Sum of 5 and 3: %d\n", add(5, 3))
}
