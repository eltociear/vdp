ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS base

RUN apk add --update docker docker-compose docker-cli-compose docker-cli-buildx openrc containerd git bash make wget vim curl openssl

# Install k6
ARG TARGETARCH K6_VERSION
ADD https://github.com/grafana/k6/releases/download/v${K6_VERSION}/k6-v${K6_VERSION}-linux-$TARGETARCH.tar.gz k6-v${K6_VERSION}-linux-$TARGETARCH.tar.gz
RUN tar -xf k6-v${K6_VERSION}-linux-$TARGETARCH.tar.gz --strip-components 1 -C /usr/bin

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin

FROM alpine:${ALPINE_VERSION} AS latest

COPY --from=base /etc /etc
COPY --from=base /usr /usr
COPY --from=base /lib /lib
COPY --from=docker:dind /usr/local/bin /usr/local/bin

ARG CACHE_DATE
RUN echo "VDP latest codebase cloned on ${CACHE_DATE}"

WORKDIR /instill-ai

RUN git clone https://github.com/instill-ai/base.git

WORKDIR /instill-ai/vdp

RUN git clone https://github.com/instill-ai/pipeline-backend.git
RUN git clone https://github.com/instill-ai/connector-backend.git
RUN git clone https://github.com/instill-ai/controller-vdp.git

FROM alpine:${ALPINE_VERSION} AS release

COPY --from=base /etc /etc
COPY --from=base /usr /usr
COPY --from=base /lib /lib
COPY --from=docker:dind /usr/local/bin /usr/local/bin

ARG CACHE_DATE
RUN echo "VDP release codebase cloned on ${CACHE_DATE}"

WORKDIR /instill-ai

ARG INSTILL_BASE_VERSION
RUN git clone -b v${INSTILL_BASE_VERSION} -c advice.detachedHead=false https://github.com/instill-ai/base.git

WORKDIR /instill-ai/vdp

ARG PIPELINE_BACKEND_VERSION CONNECTOR_BACKEND_VERSION CONTROLLER_VDP_VERSION
RUN git clone -b v${PIPELINE_BACKEND_VERSION} -c advice.detachedHead=false https://github.com/instill-ai/pipeline-backend.git
RUN git clone -b v${CONNECTOR_BACKEND_VERSION} -c advice.detachedHead=false https://github.com/instill-ai/connector-backend.git
RUN git clone -b v${CONTROLLER_VDP_VERSION} -c advice.detachedHead=false https://github.com/instill-ai/controller-vdp.git
