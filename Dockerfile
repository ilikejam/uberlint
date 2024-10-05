FROM golang:bullseye AS golang-builder

FROM debian:bookworm-slim
ARG ANSIBLELINTVERS=6.12.2
ARG HADOLINTVERS=v2.12.0
ARG HADOLINTSUMAMD=56de6d5e5ec427e17b74fa48d51271c7fc0d61244bf5c90e828aab8362d55010
ARG HADOLINTSUMARM=5798551bf19f33951881f15eb238f90aef023f11e7ec7e9f4c37961cb87c5df6
ARG CFNFORMATVERS=v1.1.3
ARG CFNFORMATSUMAMD=918e00633bfba937109ba78b5da3d64a51a25d48640cfa8e85ef416dc3735eb8
ARG CFNFORMATSUMARM=300e8e3b4357583f5bee19b74375c4b2131736e01a9de152b771732e8585c1e9
ARG RUBOCOPVERS=1.64.1
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
                https://github.com/awslabs/aws-cloudformation-template-formatter/releases/download/$CFNFORMATVERS/cfn-format-${CFNFORMATVERS}_linux-amd64.zip && \
            unzip cfn-format-${CFNFORMATVERS}_linux-amd64.zip cfn-format-${CFNFORMATVERS}_linux-amd64/cfn-format && \
            cp cfn-format-${CFNFORMATVERS}_linux-amd64/cfn-format /usr/bin/cfn-format && \
            echo "$CFNFORMATSUMAMD  /usr/bin/cfn-format" | sha256sum --check && \
            chmod +x /usr/bin/cfn-format && \
            rm -rf cfn-format-${CFNFORMATVERS}_linux-amd64.zip cfn-format-${CFNFORMATVERS}_linux-amd64 \
            ;; \
        aarch64) \
            curl -f -L -o /usr/bin/hadolint \
                https://github.com/hadolint/hadolint/releases/download/$HADOLINTVERS/hadolint-Linux-arm64 && \
            echo "$HADOLINTSUMARM  /usr/bin/hadolint" | sha256sum --check && \
            chmod +x /usr/bin/hadolint && \
            curl -f -L -O \
                https://github.com/awslabs/aws-cloudformation-template-formatter/releases/download/$CFNFORMATVERS/cfn-format-${CFNFORMATVERS}_linux-arm64.zip && \
            unzip cfn-format-${CFNFORMATVERS}_linux-arm64.zip cfn-format-${CFNFORMATVERS}_linux-arm64/cfn-format && \
            cp cfn-format-${CFNFORMATVERS}_linux-arm64/cfn-format /usr/bin/cfn-format && \
            echo "$CFNFORMATSUMARM  /usr/bin/cfn-format" | sha256sum --check && \
            chmod +x /usr/bin/cfn-format && \
            rm -rf cfn-format-${CFNFORMATVERS}_linux-arm64.zip cfn-format-${CFNFORMATVERS}_linux-arm64 \
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
