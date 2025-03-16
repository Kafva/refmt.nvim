package main

import (
	"fmt"
	"os"
)

func main() {
    fmt.Fprintf(os.Stderr, "Usage: %s [OPTIONS]\n\n", os.Args[0])
}
