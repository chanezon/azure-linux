#an image with jdk 1.8, maven, to run the spring-doge sample app
# https://github.com/joshlong/spring-doge
# https://www.youtube.com/watch?v=eCos5VTtZoI
FROM jamesdbloom/docker-java8-maven

MAINTAINER Patrick Chanezon <patrick@chanezon.com>

EXPOSE 8080

#checkout and build spring-doge
WORKDIR /local/git
RUN git clone https://github.com/joshlong/spring-doge.git
WORKDIR /local/git/spring-doge
RUN mvn package
CMD java -Dserver.port=8080 -Dspring.data.mongodb.uri=$MONGODB_URI -jar spring-doge/target/spring-doge.jar
