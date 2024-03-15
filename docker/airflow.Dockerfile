# Stage 1: Build stage
FROM amazonlinux:2023 AS build

## Version specific ARGs
ARG AIRFLOW_VERSION="2.8.1"
ARG WATCHTOWER_VERSION=2.0.1
ARG PROVIDER_AMAZON_VERSION=8.17.0

ARG AIRFLOW_UID="50000"
ARG ADDITIONAL_AIRFLOW_EXTRAS=""
ARG ADDITIONAL_PYTHON_DEPS=""

## General ARGs
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ARG SYSTEM_DEPS=""
ARG INDEX_URL=""

# Set environment variables
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}
ENV PATH="$PATH:/usr/local/airflow/.local/bin:/root/.local/bin:/usr/local/airflow/.local/lib/python3.10/site-packages"
ENV PYTHON_VERSION=3.11.6

# Install system dependencies and setup environment
COPY script/systemlibs.sh /systemlibs.sh
RUN chmod u+x /systemlibs.sh && /systemlibs.sh


# Copy scripts and configuration files
COPY script/bootstrap.sh /bootstrap.sh
COPY config/constraints.txt /constraints.txt
COPY config/base-providers-requirements.txt /base-providers-requirements.txt
# Install Python dependencies
RUN chmod u+x /bootstrap.sh && /bootstrap.sh

COPY script/generate_key.sh /generate_key.sh
COPY script/run-startup.sh /run-startup.sh
COPY script/shell-launch-script.sh /shell-launch-script.sh
COPY script/verification.sh /verification.sh
# Make scripts executable and execute them
RUN chmod u+x /generate_key.sh && /generate_key.sh \
    && chmod u+x /run-startup.sh \
    && chmod u+x /shell-launch-script.sh \
    && chmod u+x /verification.sh


# Stage 2: Runtime stage
FROM amazonlinux:2023 AS runtime

# Set environment variables
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}
ENV PATH="$PATH:/usr/local/airflow/.local/bin:/root/.local/bin:/usr/local/airflow/.local/lib/python3.10/site-packages"
ENV PYTHON_VERSION=3.11.6

# Copy artifacts from the build stage
COPY --from=build /usr/local/airflow ${AIRFLOW_USER_HOME}
COPY script/entrypoint.sh /entrypoint.sh
COPY id_rsa ${AIRFLOW_USER_HOME}/.ssh/id_rsa
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg
COPY config/webserver_config.py ${AIRFLOW_USER_HOME}/webserver_config.py

# Copy airflow user from the build stage
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group

# Adjust permissions
RUN chmod 600 ${AIRFLOW_USER_HOME}/.ssh/id_rsa
RUN chown -R airflow: ${AIRFLOW_USER_HOME}
RUN chmod +x /entrypoint.sh

# Expose ports and set user
EXPOSE 8080 5555 8793
USER airflow
WORKDIR ${AIRFLOW_USER_HOME}

# Define entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["local-runner"]
