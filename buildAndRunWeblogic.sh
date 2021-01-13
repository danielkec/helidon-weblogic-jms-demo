CURR_DIR=$(pwd)
TEMP_DIR=${CURR_DIR}/target
IMAGES_DIR=${TEMP_DIR}/ora-images
JAVA_DIR=${IMAGES_DIR}/java
WLS_DIR=${IMAGES_DIR}/wls
WLS_DOMAIN_DIR=${IMAGES_DIR}/wls-sample-domain
IMAGES_ZIP_URL=https://github.com/oracle/docker-images/archive/master.zip
WLS_IMAGES_ZIP_DIR=docker-images-master/OracleWebLogic/dockerfiles
SAMPLES_IMAGES_ZIP_DIR=docker-images-master/OracleWebLogic/samples
JAVA_IMAGES_ZIP_DIR=docker-images-master/OracleJava/8
WLS_VERSION=12.2.1.3
BASE_IMAGE_NAME=oracle/weblogic:${WLS_VERSION}
IMAGE_NAME=helidon/oracle-aq-example
CONTAINER_NAME=oracle-aq-example
ORACLE_PWD=frank

mkdir -p ${TEMP_DIR}

# cleanup
rm -rf "${IMAGES_DIR}"
rm "${TEMP_DIR}/ora-images.zip"

# download official oracle docker images
curl -LJ -o ${TEMP_DIR}/ora-images.zip ${IMAGES_ZIP_URL}

# unzip only relevant images for server Java, WLS and sample domain
unzip -qq ${TEMP_DIR}/ora-images.zip "${WLS_IMAGES_ZIP_DIR}/*" -d ${IMAGES_DIR}
unzip -qq ${TEMP_DIR}/ora-images.zip "${SAMPLES_IMAGES_ZIP_DIR}/*" -d ${IMAGES_DIR}
unzip -qq ${TEMP_DIR}/ora-images.zip "${JAVA_IMAGES_ZIP_DIR}/*" -d ${IMAGES_DIR}
mv ${IMAGES_DIR}/${WLS_IMAGES_ZIP_DIR} ${WLS_DIR}/
mv ${IMAGES_DIR}/${SAMPLES_IMAGES_ZIP_DIR} ${WLS_DOMAIN_DIR}/
mv ${IMAGES_DIR}/${WLS_IMAGES_ZIP_DIR}/buildDockerImage.sh ${WLS_DIR}/
mv ${IMAGES_DIR}/${JAVA_IMAGES_ZIP_DIR} ${JAVA_DIR}/
# x-www-browser https://www.oracle.com/middleware/technologies/weblogic-server-downloads.html
echo Download and copy server-jre-8u271-linux-x64.tar.gz to ${JAVA_DIR}/
echo from https://www.oracle.com/java/technologies/javase-server-jre8-downloads.html
echo "Hit [ENTER] when ready to continue ..."
read ;


echo Download and copy fmw_12.2.1.3.0_wls_quick_Disk1_1of1.zip to ${WLS_DIR}/${WLS_VERSION}/
echo from https://www.oracle.com/middleware/technologies/weblogic-server-downloads.html
echo "Hit [ENTER] when ready to continue ..."

read ;

cd ${JAVA_DIR};
docker build --tag oracle/serverjre:8 .;

cd ${WLS_DIR};
bash buildDockerImage.sh -s -d -v ${WLS_VERSION};

cd ${WLS_DOMAIN_DIR}/12213-domain;
docker build -f Dockerfile -t 12213-weblogic-sample-domain .

docker run -d \
-p 7001:7001 \
-p 9001:9001 \
-p 9002:9002 \
--name wls-admin \
--hostname WLSAdmin \
-v ${CURR_DIR}/weblogic/properties:/u01/oracle/properties \
-v ${CURR_DIR}/weblogic/custom-scripts:/u01/oracle/custom-scripts \
12213-weblogic-sample-domain;

printf "Waiting for WLS to start ."
while true;
do
  if docker logs wls-admin | grep -q "Server state changed to RUNNING"; then
    break;
  fi
  printf "."
  sleep 5
done
printf " [READY]\n"

echo Deploying example JMS queues
docker exec wls-admin \
/bin/bash \
/u01/oracle/wlserver/common/bin/wlst.sh \
/u01/oracle/custom-scripts/setupTestJMSQueue.py;

echo Example JMS queues deployed!
echo Console avaiable at http://localhost:7001/console with admin/Welcome1

