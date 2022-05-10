package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/pkg/errors"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// Response is of type APIGatewayProxyResponse since we're leveraging the
// AWS Lambda Proxy Request functionality (default behavior)
//
// https://serverless.com/framework/docs/providers/aws/events/apigateway/#lambda-proxy-integration
type Response events.APIGatewayProxyResponse

type Input struct {
	Stage      string   `json:"stage"`
	FailStages []string `json:"failStages"`
}

func Handler(input Input) (Response, error) {
	var buf bytes.Buffer

	for _, f := range input.FailStages {
		if f == input.Stage {
			return Response{
				StatusCode: 500,
			}, errors.Errorf("stage %s failed", input.Stage)
		}
	}

	message := fmt.Sprintf("stage %s succeeded", input.Stage)
	body, err := json.Marshal(map[string]interface{}{
		"message": message,
	})
	if err != nil {
		return Response{StatusCode: 500}, err
	}
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

func main() {
	lambda.Start(Handler)
}
