package main

import (
	"github.com/pkg/errors"
	"log"
)

func main() {
	err := errors.New("Work In Progress")
	log.Fatal(err)
}
