# Copy wlthint3client.jar from docker container
docker cp wls-admin:/u01/oracle/wlserver/server/lib/wlthint3client.jar ./target/wlthint3client.jar

# Install wlthint3client.jar to local msv repo
mvn install:install-file \
-Dfile=./target/wlthint3client.jar \
-DgeneratePom=true \
-DgroupId=custom.com.oracle \
-DartifactId=wlthint3client \
-Dversion=12.2.1.3 \
-Dpackaging=jar