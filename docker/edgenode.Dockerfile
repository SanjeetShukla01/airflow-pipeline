# Image used on ec2 boxes: ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210223

FROM python:3.11.6
ENV PYTHONBUFFERED = 1

RUN apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/IST apt-get install -y netcat-traditional ssh iputils-ping sudo python3-pip default-jdk vim && \
    mkdir /var/run/sshd && \
    chmod 0755 /var/run/sshd && \
    ssh-keygen -A && \
    useradd -p $(openssl passwd executoradmin) --create-home --shell /bin/bash --groups sudo executor


# Make repository for your common python code if there (my-common-python)
RUN mkdir -p var/lib/my-python
RUN #chown -R executor /var/lib/my-common-python
RUN service ssh start

ARG MY_JOB_ENVIRONMENT=${MY_JOB_ENVIRONMENT}
ARG SAVE_TEMP_TABLE=${SAVE_TEMP_TABLE}
ARG MY_SNOWFLAKE_WAREHOUSE_OVERRIDE=${MY_SNOWFLAKE_WAREHOUSE_OVERRIDE}
ARG MY_SNOWFLAKE_DATABASE_OVERRIDE=${MY_SNOWFLAKE_DATABASE_OVERRIDE}
ARG AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ARG AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ARG AWS_CLI_DOWNLOAD_PATH=${AWS_CLI_DOWNLOAD_PATH}
ARG ADDITIOANL_JAR_PATH=${ADDITIOANL_JAR_PATH}
# Make directory for your etl code
RUN mkdir -p /usr/local/sf_data_pipeline && chown executor:executor /usr/local/sf_data_pipeline
RUN mkdir -p /usr/local/pyspark_pipeline && chown executor:executor /usr/local/pyspark_pipeline

USER executor
RUN mkdir -p /home/executor/environments
RUN mkdir /home/executor/.ssh && chmod 700 /home/executor/.ssh
RUN echo "export MY_JOB_ENVIRONMENT=$MY_JOB_ENVIRONMENT" > home/executor/.bash_profile && \
    echo "export MY_SNOWFLAKE_WAREHOUSE_OVERRIDE=$MY_SNOWFLAKE_WAREHOUSE_OVERRIDE" >> home/executor/.bash_profile && \
    echo "export MY_SNOWFLAKE_DATABASE_OVERRIDE=$MY_SNOWFLAKE_DATABASE_OVERRIDE" >> home/executor/.bash_profile && \
    echo "export AWS_REGION=us-east-1" >> home/executor/.bash_profile && \
    echo "export SAVE_TEMP_TABLES=$SAVE_TEMP_TABLES" >> home/executor/.bash_profile && \
    mkdir -p /home/executor/.aws && \
    echo "[default]" >> /home/executor/.aws/credentials && \
    echo "AWS_ACCESS_KEY=$AWS_ACCESS_KEY" >> /home/executor/.aws/credentials && \
    echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> /home/executor/.aws/credentials && \
    echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >> /home/executor/.aws/credentials \
# Copy common python setup.py to environments
COPY setup.py /home/executor/environments
#COPY /var/lib/my-common-python/sf-data-pipeline/requirements.txt /home/executor/environments
#COPY aws_config /home/executor/.aws/config
COPY --chown=executor:executor id_rsa.pub /home/executor/.ssh/authorized_keys
RUN chmod 600 /home/executor/.ssh/authorized_keys && \
    pip3 install virtualenv && \
    /home/executor/.local/bin/virtualenv /home/executor/environments/my-virtualenv-python3_11
#    pip3 install /home/executor/environments &&
#    pip3 install /home/executor/environments/requirements.txt
COPY *.jar /usr/local/sf_data_pipeline

USER root
EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]
