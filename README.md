# Jobs server

**HTTP server that can give an evaluation order of tasks**

## Setup
1. `mix deps.get`
2. `mix run --no-halt`

## Endpoint(s)

### /get_execution_order

Example request:  
`curl -X POST -H "Accept: application/json" -d @data.json http://localhost:3000/get_execution_order`

**Expects** a JSON with the following structure:
```JSON
{
  "tasks": [
    {
      "name": "task-name",
      "command": "touch file",
      "requires": ["required-task-name"]
    }
    ...
  ]
}
```
Where
* `"name"` is the task name and uniquely identifies the task.
* `"command"` is a shell executable command
* `"requires"` is a list of task names representing the tasks that should be executed prior to the given task

**Returns** the given tasks in a correct order for evaluation.  
Depending on the `Accept` header of the request, two types of responses are implemented - JSON and plain text.  
**Example JSON response**
```JSON
{
  "tasks": [
    {
      "name": "task_name_1",
      "command": "touch file_1",
    },
    {
      "name": "task_name_2",
      "command": "touch file_2",
    }
    ...
  ]
}
```
The plain text response is meant to be executed via bash  
**Example plain text response**
```bash
#!/usr/bin/env bash 

touch file_1
touch file_2
```

**Possible error responses**
* `422` if the request body is in incorrect format
* `400` if there is a cyclic dependency between the tasks
