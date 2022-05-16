package main

import (
	"encoding/json"
	"github.com/pkg/errors"
	"log"
	"os"
)

func main() {
	failStagesEnv, ok := os.LookupEnv("failStages")
	if !ok {
		log.Fatal(errors.New("no failStages env var"))
	}
	stageEnv, ok := os.LookupEnv("stage")
	if !ok {
		log.Fatal(errors.New("no stage env var"))
	}
	_, ok = os.LookupEnv("COMMON_ENV_VAR")
	if !ok {
		log.Fatal(errors.New("no COMMON_ENV_VAR env var"))
	}

	failStages := make([]string, 0)
	if err := json.Unmarshal([]byte(failStagesEnv), &failStages); err != nil {
		log.Fatal(err)
	}

	for _, fs := range failStages {
		if fs == stageEnv {
			err := errors.Errorf("Simulated failure of the stage %s", stageEnv)
			log.Fatal(err)
		}
	}

	log.Printf("Stage %s completed successfully", stageEnv)
}
