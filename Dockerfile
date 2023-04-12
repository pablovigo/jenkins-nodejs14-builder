FROM docker-registry-XXXXX.com/catalog/docker-init-setup:2.3.0 as ca-certs
RUN /usr/local/init.sh && \
    tar xzvf /opt/ca-certs/ca-sources.tar.gz -C /etc/pki/ca-trust/source/anchors

FROM docker-registry-XXXXX.com/rhel8/nodejs-14:1.63.0

USER root

ARG BASE_URL_ARTIFACTORY=https://artifacts-XXXXX.com/artifactory/path

ENV YARN_VERSION=1.22.4 \
    YARN_SHA=bc5316aa110b2f564a71a3d6e235be55b98714660870c5b6b2d2d3f12587fb58 \
    SONAR_SHA=889f75c535471d426fcc4d75d4496ec6df6dd0a34c805988329fa58300775b4a \
    KEYTOOL_SHA=1ead20afee911372c4c97626409ed672d6a1fca9ec17f3ba91c3b41dae20d4b0 \
    DOWNLOAD_FOLDER=/assets \
    PROXY=proxy.com:8080

COPY --from=ca-certs /etc/pki/ca-trust/source/anchors /etc/pki/ca-trust/source/anchors
RUN update-ca-trust

# should solve DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN groupadd --gid 1001 node \
  && useradd --uid 1001 --gid node --shell /bin/bash --create-home node

# should solve DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN  curl -fsSLOk --compressed "${BASE_URL_ARTIFACTORY}/yarn-v1.22.4.tar.gz" \
  && echo ${YARN_SHA} yarn-v1.22.4.tar.gz | sha256sum -c - \
  && mkdir -p /opt \
  && tar -xzf yarn-v1.22.4.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v1.22.4/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v1.22.4/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v1.22.4.tar.gz \
  && yarn --version \
  && chown -R 1001:1001 /opt/app-root/src/

# should solve DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSLOk --compressed "${BASE_URL_ARTIFACTORY}/sonar-scanner-cli-4.4.0.2170-linux.zip" \
  && echo ${SONAR_SHA} sonar-scanner-cli-4.4.0.2170-linux.zip | sha256sum -c - \
  && unzip sonar-scanner-cli-4.4.0.2170-linux.zip -d /opt/ \
  && rm sonar-scanner-cli-4.4.0.2170-linux.zip \
  && ln -s /opt/sonar-scanner-4.4.0.2170-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner \
  && ln -s /opt/sonar-scanner-4.4.0.2170-linux/bin/sonar-scanner-debug /usr/local/bin/sonar-scanner-debug

RUN curl -fsSLOk --compressed "${BASE_URL_ARTIFACTORY}/keytool" \
  && cp -pf keytool /opt/sonar-scanner-4.4.0.2170-linux/jre/bin \
  && echo ${KEYTOOL_SHA} /opt/sonar-scanner-4.4.0.2170-linux/jre/bin/keytool | sha256sum -c - \
  && ln -s /opt/sonar-scanner-4.4.0.2170-linux/jre/bin/keytool /usr/local/bin/keytool \
  && chmod +x /usr/local/bin/keytool

COPY ./scripts/keytoolimport.sh /opt/
RUN chmod a+x /opt/keytoolimport.sh \
  && bash -vvv /opt/keytoolimport.sh

COPY docker-entrypoint.sh /usr/local/bin/

USER 1001

ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "node" ]
