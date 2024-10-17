FROM golang:bullseye AS golang-builder

FROM debian:bookworm-slim
ARG ANSIBLELINTVERS=6.12.2
ARG HADOLINTVERS=v2.12.0
ARG HADOLINTSUMAMD=56de6d5e5ec427e17b74fa48d51271c7fc0d61244bf5c90e828aab8362d55010
ARG HADOLINTSUMARM=5798551bf19f33951881f15eb238f90aef023f11e7ec7e9f4c37961cb87c5df6
ARG RAINVERS=v1.16.1
ARG RAINSUMAMD=be661510fbbc57e2e85d9e9617d69b261bba6f2b0d5725319397730bf77b88bf
ARG RAINSUMARM=f42412c622ba150d27aa4fd94014610cc73e9254dbb1a5dc9b05438af27374e3
ARG RUBOCOPVERS=1.64.1
ARG CACHEBUST=__NONCE__
ENV DEBIAN_FRONTEND=noninteractive
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

# hadolint ignore=DL3008,DL3013,DL3016
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        curl \
        file \
        git \
        jq \
        libxml2-utils \
        make \
        npm \
        python-is-python3 \
        python3-pip \
        python3-venv \
        rpm \
        rpmlint \
        rsync \
        ruby \
        shellcheck \
        unzip && \
    rm -rf /var/lib/apt/lists/* && \
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
    chmod 777 /.ansible

COPY --from=golang-builder /usr/local/go/bin/gofmt /usr/bin/gofmt
COPY lint /lint
COPY eslintrc.json /eslintrc.json
WORKDIR /repo
CMD [ "/lint/all.docker" ]
