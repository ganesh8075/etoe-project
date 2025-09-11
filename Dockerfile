FROM alpine/git as clone
MAINTAINER stangella<sreatcloud@gmail.com>
WORKDIR /app
RUN git clone https://github.com/sresrinivas/etoe.git
# stage-two
FROM maven:3.5-jdk-8-alpine as build
WORKDIR /app
COPY --from=clone  /app/etoe  /app
RUN mvn package
# stage-third
#lets try
FROM tomcat:7-jre7

ADD tomcat-users.xml /usr/local/tomcat/conf
COPY --from=build /app/target/Ecomm.war /usr/local/tomcat/webapps
