FROM golang:bookworm AS golang-builder

FROM debian:bookworm-slim
ARG ANSIBLELINTVERS=25.1.3
ARG HADOLINTVERS=v2.12.0
ARG HADOLINTSUMAMD=56de6d5e5ec427e17b74fa48d51271c7fc0d61244bf5c90e828aab8362d55010
ARG HADOLINTSUMARM=5798551bf19f33951881f15eb238f90aef023f11e7ec7e9f4c37961cb87c5df6
ARG RAINVERS=v1.21.0
ARG RAINSUMAMD=27a0673c2ee089328938ae27355349ee95e3156a351a543ef04e327279ee0e01
ARG RAINSUMARM=7fe35e499510630a13f6fc39845a571c2a9fe99e8242ce0e3cfd4dbcc42fa647
ARG RUBOCOPVERS=1.75.1
ARG CACHEBUST=__NONCE__
ENV DEBIAN_FRONTEND=noninteractive
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

# hadolint ignore=DL3008,DL3013,DL3016
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        curl \
        file \
        gcc \
        git \
        jq \
        libc6-dev \
        libxml2-utils \
        make \
        npm \
        python-is-python3 \
        python3-pip \
        rpm \
        rpmlint \
        rsync \
        ruby \
        ruby-dev \
        shellcheck \
        unzip && \
    pip3 install --no-cache-dir --break-system-packages \
        ansible \
        ansible-lint==$ANSIBLELINTVERS \
        black \
        cfn-lint \
        hvac \
        isort \
        jmespath \
        mypy \
        ruff \
        yamllint && \
    npm install --global \
        prettier \
        eslint-plugin-prettier \
        eslint-config-prettier \
        eslint-plugin-immutable && \
    npx -y install-peerdeps --global \
        eslint-config-airbnb && \
    gem install rubocop:$RUBOCOPVERS && \
    arch="$(uname -m)" && \
    case "$arch" in \
        x86_64) \
            curl -f -L -o /usr/bin/hadolint \
                https://github.com/hadolint/hadolint/releases/download/$HADOLINTVERS/hadolint-Linux-x86_64 && \
            echo "$HADOLINTSUMAMD  /usr/bin/hadolint" | sha256sum --check && \
            chmod +x /usr/bin/hadolint && \
            curl -f -L -O \
                https://github.com/aws-cloudformation/rain/releases/download/$RAINVERS/rain-${RAINVERS}_linux-amd64.zip && \
            unzip rain-${RAINVERS}_linux-amd64.zip rain-${RAINVERS}_linux-amd64/rain && \
            cp rain-${RAINVERS}_linux-amd64/rain /usr/bin/rain && \
            echo "$RAINSUMAMD  /usr/bin/rain" | sha256sum --check && \
            chmod +x /usr/bin/rain && \
            rm -rf rain-${RAINVERS}_linux-amd64.zip rain-${RAINVERS}_linux-amd64/ \
            ;; \
        aarch64) \
            curl -f -L -o /usr/bin/hadolint \
                https://github.com/hadolint/hadolint/releases/download/$HADOLINTVERS/hadolint-Linux-arm64 && \
            echo "$HADOLINTSUMARM  /usr/bin/hadolint" | sha256sum --check && \
            chmod +x /usr/bin/hadolint && \
            curl -f -L -O \
                https://github.com/aws-cloudformation/rain/releases/download/$RAINVERS/rain-${RAINVERS}_linux-arm64.zip && \
            unzip rain-${RAINVERS}_linux-arm64.zip rain-${RAINVERS}_linux-arm64/rain && \
            cp rain-${RAINVERS}_linux-arm64/rain /usr/bin/rain && \
            echo "$RAINSUMARM  /usr/bin/rain" | sha256sum --check && \
            chmod +x /usr/bin/rain && \
            rm -rf rain-${RAINVERS}_linux-arm64.zip rain-${RAINVERS}_linux-arm64/ \
            ;; \
        *) \
            echo "ERROR: Unknown architecture. Bailing out now."; \
            exit 1 \
            ;; \
    esac && \
    mkdir /.ansible && \
    chmod 777 /.ansible && \
    apt-get remove -y curl gcc libc6-dev ruby-dev unzip && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

COPY --from=golang-builder /usr/local/go/bin/gofmt /usr/bin/gofmt
COPY lint /lint
COPY eslintrc.json /eslintrc.json
WORKDIR /repo
CMD [ "/lint/all.docker" ]
