FROM maven:3-amazoncorretto-8 AS builder-ms3

RUN yum install -y git

WORKDIR /build/arcturus-community
RUN git clone --branch dev --recurse-submodules https://git.mc8051.de/nitro/Arcturus-Community.git .
# explicit pin this version
RUN git checkout f051d1d1
RUN mvn package
RUN mvn install

WORKDIR /build/arcturus-ws
RUN git clone --recurse-submodules https://git.mc8051.de/nitro/nitrowebsockets-for-ms.git .
RUN sed -i 's#<version>3.0.0</version>#<version>[1.0.0,)</version>#g' pom.xml
RUN mvn package
RUN cp target/NitroWebsockets-*.jar target/websockets.jar



FROM maven:3-amazoncorretto-19 AS builder-ms4

ARG BRANCH=archived/ms4/dev
ARG COMMIT=3bb8ce16

RUN yum install -y git

WORKDIR /build/arcturus-community
RUN git clone --branch ${BRANCH} --recurse-submodules https://git.mc8051.de/nitro/Arcturus-Community.git .
RUN git checkout $COMMIT
RUN sed -i 's#Scanner scanner = new Scanner(System.in);##g' src/main/java/com/eu/habbo/Emulator.java
RUN sed -i 's#scanner.nextLine();##g' src/main/java/com/eu/habbo/Emulator.java
ADD patches/ /build/arcturus-community/patches/
RUN find "$(readlink -f patches/)" -type f -name "*.patch" | xargs -I {} sh -c 'echo "Applying {}"; git apply --ignore-space-change --ignore-whitespace {}'
RUN mvn package
RUN mvn install
RUN cp target/Morningstar*-with-dependencies.jar target/emulator.jar


WORKDIR /build/apollyon
ARG APOLLYON_COMMIT=4bc5cc3
RUN git clone https://git.mc8051.de/nitro/apollyon-ms4.git .
RUN git checkout $APOLLYON_COMMIT
RUN sed -i 's#<version>4.0-DEVPREVIEW</version>#<version>[1.0.0,)</version>#g' pom.xml
RUN mvn package
RUN cp target/Apollyon-*.jar target/apollyon.jar



FROM maven:3-amazoncorretto-19 AS builder-mentionplugin
COPY --from=builder-ms4 /root/.m2 /root/.m2
WORKDIR /build/mentionplugin
ADD plugins-src/mentionplugin/ .
RUN mvn package



FROM maven:3-amazoncorretto-19 AS builder-prizeplugin
COPY --from=builder-ms4 /root/.m2 /root/.m2
WORKDIR /build/PrizePlugin
ADD plugins-src/PrizePlugin/ .
RUN mvn package



FROM maven:3-amazoncorretto-19 AS builder-nftplugin
COPY --from=builder-ms4 /root/.m2 /root/.m2
WORKDIR /build/NFTPlugin
ADD plugins-src/NFTPlugin/ .
RUN mvn package



FROM amazoncorretto:19

WORKDIR /app

RUN yum install -y mariadb bash

COPY --from=builder-ms4 /build/arcturus-community/target/emulator.jar /app/emulator.jar
RUN mkdir -p /app/plugins
COPY --from=builder-ms3 /build/arcturus-ws/target/websockets.jar /app/plugins/websockets.jar
COPY --from=builder-ms4 /build/apollyon/target/apollyon.jar /app/plugins/apollyon.jar
COPY --from=builder-mentionplugin /build/mentionplugin/target/MentionPlugin-*-jar-with-dependencies.jar /app/plugins/mentionplugin.jar
COPY --from=builder-prizeplugin /build/PrizePlugin/target/PrizePlugin-*-jar-with-dependencies.jar /app/plugins/prizeplugin.jar
COPY --from=builder-nftplugin /build/NFTPlugin/target/NFTAvatarPlugin-*-jar-with-dependencies.jar /app/plugins/nftplugin.jar

ENTRYPOINT ["/usr/bin/java", "-Xms128m", "-Xmx384m", "-XX:+ExitOnOutOfMemoryError", "-jar", "/app/emulator.jar"]