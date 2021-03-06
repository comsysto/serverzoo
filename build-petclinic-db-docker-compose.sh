#!/usr/bin/env bash

####
#### this script is used to build the mysql image which already has petclinic data in it
####

DB_IMAGE_NAME=comsysto/petclinic-db
BUILD_DIR=build/docker
TMP_DATA_DIR=mysql-data
TMP_DATA_PATH_IN_BUILD_DIR=${BUILD_DIR}/${TMP_DATA_DIR}

mkdir -p ${TMP_DATA_PATH_IN_BUILD_DIR}

# start up the database
docker-compose --file docker-compose-mysql-image-builder.yml up -d mysql

# wait for DB to get initialized
sleep 15

# flyway container will find the running DB within the network and migrate its data
docker-compose --file docker-compose-mysql-image-builder.yml up flyway

# we are done, shut down the DB as well
docker-compose --file docker-compose-mysql-image-builder.yml stop

# unfortunately, we cannot simply commit the result as the content of volumes
# is ignored - therefore we use cp. The image is tagged with the MD5 checksum
# of the migration files, so we may skip the whole process if migration files
# haven't changed:
docker cp `docker-compose --file docker-compose-mysql-image-builder.yml ps -q mysql`:/var/lib/mysql ${TMP_DATA_PATH_IN_BUILD_DIR}
cp Dockerfile-db ${BUILD_DIR}/Dockerfile
docker build --build-arg data_directory=${TMP_DATA_DIR} -t ${DB_IMAGE_NAME}:latest -t ${DB_IMAGE_NAME}:MD5_$(<build/distributions/spring-petclinic-1.5.1-migration.zip.MD5) ${BUILD_DIR}

# clean up everything
docker-compose --file docker-compose-mysql-image-builder.yml rm -f
