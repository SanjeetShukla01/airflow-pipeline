# Use a smaller base image for Python
FROM python:3.11.6 AS base

# Set environment variables
ENV PYTHONBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/IST \
    PIPENV_VENV_IN_PROJECT=1 \
    SPARK_VERSION=3.4.2 \
    HADOOP_VERSION=3 \
    JAVA_VERSION=11 \
    SCALA_VERSION=2.13 \
    UNAME=sam \
    UID=1000 \
    GID=1000

# Upgrade packages and install necessary dependencies
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
#    "openjdk-${JAVA_VERSION}-jre-headless" \
    default-jdk \
    ca-certificates-java \
    ssh \
    curl \
    sudo \
    tree && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd /home/sam/.ssh /home/spark/logs && \
    chmod 0755 /var/run/sshd /home/sam/.ssh && \
    groupadd -g "${GID}" samgroup && \
    useradd -u "${UID}" -g "${GID}" -p "$(openssl passwd admin-sam)" --create-home --shell /bin/bash --groups sudo sam && \
    chown -R "${UID}:${GID}" /home/sam/.ssh /home/spark/logs


RUN service ssh start

## Download and install Spark
RUN DOWNLOAD_URL_SPARK="https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}-scala${SCALA_VERSION}.tgz" \
    && wget --verbose -O apache-spark.tgz "${DOWNLOAD_URL_SPARK}" \
    && tar -xf apache-spark.tgz -C /home/spark --strip-components=1 \
    && rm apache-spark.tgz

## Configure Spark
ENV SPARK_HOME="/home/spark" \
    PATH="${SPARK_HOME}/bin:${PATH}" \
    PYSPARK_PYTHON=/usr/bin/python3 \
    PYSPARK_DRIVER_PYTHON='jupyter' \
    PYSPARK_DRIVER_PYTHON_OPTS='notebook --ip=0.0.0.0 --port=4041 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='''

## Configure Spark defaults
RUN cp -p "${SPARK_HOME}/conf/spark-defaults.conf.template" "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.driver.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.executor.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.eventLog.enabled true' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.eventLog.dir file:///home/sam/app/spark_events' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.history.fs.logDirectory file:///home/sam/app/spark_events' >> "${SPARK_HOME}/conf/spark-defaults.conf"


## Switch to the sam user
USER $UNAME

## Copy authorized_keys for SSH
COPY --chown=sam:sam id_rsa.pub /home/sam/.ssh/authorized_keys
RUN chmod 600 /home/sam/.ssh/authorized_keys


## Set the working directory
WORKDIR /home/$UNAME/app

USER root

## Start Spark History Server and Jupyter Notebook
CMD ["sh", "-c", "$SPARK_HOME/sbin/start-history-server.sh && jupyter notebook"]
