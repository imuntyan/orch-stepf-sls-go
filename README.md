# Stepfunctions as data pipeline orchestration framework

## Build

### Configuration

- The lambda, ECS task and step function names are
currently hardcoded:
  - For ECS task, in `ecs/go/worker/Taskfile.yml`
  - For lambda, in `terraform/dev-vars.tfvars`
- The AWS account ID is hardcoded in `tasks/.env.dev`

### Build commands
- To locally build lambda, run
```shell
task build-lambda
```
This will build the lambda zip file. It will be uploaded with terraform.  

- To build and upload the Docker image to ECR, run
```shell
task build-ecs
```
This will build the Docker image and will upload it to ECR.
You must have a valid active AWS session. (This only currently works
if `AWS_PROFILE=dev`)

- To create an ECS task, lambda and step functions state machine,
run in the `./terraform` directory:
```shell
terraform apply -var-file dev-vars.tfvars
```
