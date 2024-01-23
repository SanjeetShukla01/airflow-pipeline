import json
import sys
from time import sleep

import requests
from requests.auth import HTTPBasicAuth

MAX_WAIT_TIME = 900
SLEEP_TIME = 20


def run_dag(dag_id, dag_run_conf):
    print(f"Running dag {dag_id} with conf: {dag_run_conf}")
    basic_auth = HTTPBasicAuth('admin', 'test')
    requests.patch(f"http://localhost:8080/api/v1/dags/{dag_id}", json={"is_paused": False}, auth=basic_auth)
    body = {
        "conf": json.loads(dag_run_conf)
    }
    response = requests.post(f"http://localhost:8080/api/v1/dags/{dag_id}/dagRuns", json=body, auth=basic_auth).json()
    if not "dag_run_id" in response:
        raise Exception(response)
    dag_run_id = response["dag_run_id"]
    wait_time = 0
    while True:
        if not "state" in response:
            raise Exception(response)
        print(response)
        state = response["state"]
        if state.lower() in ["success", "failed"] or wait_time > MAX_WAIT_TIME:
            fetch_and_print_logs(basic_auth, dag_id, dag_run_id)
            if state.lower() != "success":
                raise Exception(f"Dag {dag_id} run failed (or exceeded max time): {state}")
            return
        sleep(SLEEP_TIME)
        wait_time += SLEEP_TIME
        response =  requests.get(f"http://localhost:8080/api/v1/dags/{dag_id}/dagRuns/{dag_run_id}",
                                 auth=basic_auth).json()


def fetch_and_print_logs(basic_auth, dag_id, dag_run_id):
    """
    Fetch and print logs, gets the failed task instance, Response from airflow looks like below:
    {
        "task_instancees":[
        {
            "dag_id": "name_of_the_dag",
            "task_id": "name_of_the_task",
            "end_data": "2022-03-23T14:34:42+00:00",
            "state": "failed",
            "try_number": 2
        }
        ]
    }
    """
    response = requests.get(f"http://localhost:8080/api/v1/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances",
                            auth=basic_auth).json()
    print(response)
    failed_task_id_and_retry_no = []
    if "task_instance" in response:
        failed_task_id_and_retry_no.extend(
            [{"task_id": item["task_id"], "try_number": item["try_number"]}
             for item in response["task_instances"]])
        for item in failed_task_id_and_retry_no:
            header = {"Content-Type": "test/plain"}
            print(requests.get(f"http://localhost:8080/api/v1/dags/{dag_id}/dagRuns/{dag_run_id}"
                               f"/taskInstances/{item['task_id']}/logs/{item['try_number']}",
                               headers=header, auth=basic_auth).text)


if __name__ == "__main__":
    run_dag(dag_id=sys.argv[1], dag_run_conf=sys.argv[2])
