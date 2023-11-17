# Estágio 1: Construa o mutation-analysis-plugin.jar
FROM alpine:3.18.4
WORKDIR /root/

RUN apk update && apk upgrade

RUN apk add ca-certificates wget && update-ca-certificates && apk add curl
RUN apk add --no-cache \
       curl

RUN apk add curl && apk add jq


RUN LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/devcon5io/mutation-analysis-plugin/releases/latest); \
    LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/'); \
    ARTIFACT_URL="https://github.com/devcon5io/mutation-analysis-plugin/releases/download/$LATEST_VERSION/mutation-analysis-plugin-${LATEST_VERSION/v/""}.jar"; \
    wget -O mutation-analysis-plugin.jar "$ARTIFACT_URL" -P ./;

# Estágio 2: Construa a imagem final
# This image is based on a LTS version of SonarQube
FROM sonarqube:8.9.6-community
COPY --from=0 /root/mutation-analysis-plugin.jar /opt/sonarqube/extensions/plugins
