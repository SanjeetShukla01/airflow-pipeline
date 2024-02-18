Errors:
1. docker.errors.DockerException: Error while fetching server API version: ('Connection aborted.', FileNotFoundError(2, 'No such file or directory'))
   - Docker Desktop was not running

2. Pulling local-runner (airflow-dev:2_8)... ERROR: pull access denied for airflow-dev, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
   - airflow-dev:2.8 was not built, first build the airflow image then use docker compose up.

3. Postgres uses an image, skipping, local-runner uses an image, skipping. docker-compose -f docker-compose-local.yml build
   - build **context** is missing in docker-compose file

4. The package `apache-airflow-providers-common-io:1.2.0` needs Apache Airflow 2.8.0+
   - apache-airflow-providers-common-io
5. Need to fix requirement version for below components:
   - apache-airflow-providers-amazon==8.16.0
   - apache-airflow-providers-celery==3.5.1 
   - apache-airflow-providers-common-sql==1.10.0 
   - apache-airflow-providers-ftp==3.7.0 
   - apache-airflow-providers-http==4.8.0 
   - apache-airflow-providers-imap==3.5.0 
   - apache-airflow-providers-postgres==5.10.0 
   - apache-airflow-providers-sqlite==3.7.0 
   - apache-airflow-providers-common-io==1.2.0
   - apache-airflow-providers-snowflake==5.2.1

6. error: COPY --chown=executor:executor id_rsa.pub /home/executor/.ssh/authorized_keys
    This error is thrown after running `de-local-env.sh build` command 
    run `generate_ssh_key` before running build. 



7. Service "postgres" uses an undefined network "common"
    Error is thrown after running `de-local-env.sh start` command
    This error points out that there is a network named "common" used in docker-compose.yml which is not defined

8. Mount Error with edgenode: Error: (HTTP code 500) server error - Mounts denied: The path /pyspark_pipeline is not shared from the host and is not known to Docker. You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing. See https://docs.docker.com/ for more info.
    The mount directory need to be present on host machine
    Temporary solution: comment it untill host has code directory to mount

9. While running python code to create airflow connection, it was throwing following error: <Response [401]>
    To reproduce/test: curl -X GET -u admin:test http://localhost:8080/api/v1/connections/ssh_executor_local -v
    or run `setup_pools_connections.py`
    Did following changes: 
    # Commenting out user session based authentication for API
    ; auth_backends = airflow.api.auth.backend.session

    # Enabling basic authentication for api based on username:password
    >> auth_backends = airflow.api.auth.backend.basic_auth
