package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/pkg/errors"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// Response is of type APIGatewayProxyResponse since we're leveraging the
// AWS Lambda Proxy Request functionality (default behavior)
//
// https://serverless.com/framework/docs/providers/aws/events/apigateway/#lambda-proxy-integration
type Response events.APIGatewayProxyResponse

type Input struct {
	Stage       string   `json:"stage"`
	WaitSeconds int      `json:"waitSeconds"`
	FailStages  []string `json:"failStages"`
}

func Handler(input Input) (Response, error) {
	if err := sleep(input); err != nil {
		return Response{StatusCode: 500}, err
	}
	if err := simulateFailure(input); err != nil {
		return Response{StatusCode: 500}, err
	}

	message := fmt.Sprintf("stage %s succeeded", input.Stage)
	body, err := json.Marshal(map[string]interface{}{
		"message": message,
	})
	if err != nil {
		return Response{StatusCode: 500}, err
	}

	var buf bytes.Buffer
	json.HTMLEscape(&buf, body)

	resp := Response{
		StatusCode:      200,
		IsBase64Encoded: false,
		Body:            buf.String(),
		Headers: map[string]string{
			"Content-Type":           "application/json",
			"X-MyCompany-Func-Reply": "worker-handler",
		},
	}

	return resp, nil
}

func sleep(input Input) error {
	if input.WaitSeconds > 120 {
		return errors.Errorf("invalid wait value: %d", input.WaitSeconds)
	}
	time.Sleep(time.Duration(input.WaitSeconds) * time.Second)
	return nil
}

func simulateFailure(input Input) error {
	for _, f := range input.FailStages {
		if f == input.Stage {
			return errors.Errorf("stage %s failed", input.Stage)
		}
	}
	return nil
}

func main() {
	lambda.Start(Handler)
}
