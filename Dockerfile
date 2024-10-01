FROM docker.io/sbtscala/scala-sbt:eclipse-temurin-jammy-17.0.10_7_1.10.2_3.5.1 AS builder


RUN apt-get update && apt-get install -y \
    curl \
    bash \
    unzip \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Define UC_VERSION
ARG REF
ENV VERSION=${REF#v}

# Limit the memory usage of the sbt process to 2GB
ENV SBT_OPTS="-Xmx2G"
RUN git clone https://github.com/unitycatalog/unitycatalog.git \
  && cd unitycatalog \
  && git fetch && git checkout ${REF} -b ${VERSION}

WORKDIR /app/unitycatalog

# Compile unity catalog and remove useless target directory
RUN sbt clean createTarball \
  && mkdir /app/dist \
  && tar -xf target/unitycatalog-${VERSION}.tar.gz -C /app/dist

# Build the final image with the compiled unity catalog
FROM docker.io/eclipse-temurin:17.0.12_7-jre

COPY --from=builder /app/dist /app/unitycatalog/

WORKDIR /app/unitycatalog

ADD https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.4.0/mysql-connector-j-8.4.0.jar ./jars/mysql-connector-j-8.4.0.jar
ADD https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.4/postgresql-42.7.4.jar ./jars/postgresql-42.7.4.jar


# Listen to port 8080
EXPOSE 8080

# Run the server
CMD ["bin/start-uc-server"]
