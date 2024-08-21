#Current version from 28/02/2024
FROM alpine:3.19.1

RUN apk update && \
    apk upgrade && \
    apk add --no-cache git openssl-dev bash curl openssh-client jq

RUN wget --no-verbose -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.6.0/common.sh
RUN wget -O wizcli https://wizcli.app.wiz.io/latest/wizcli-linux-amd64 && chmod +x wizcli
RUN mv wizcli /usr/bin/wizcli

RUN wget https://releases.hashicorp.com/terraform/1.7.4/terraform_1.7.4_linux_amd64.zip
RUN unzip terraform_1.7.4_linux_amd64.zip && rm terraform_1.7.4_linux_amd64.zip
RUN mv terraform /usr/bin/terraform

COPY script/script.sh /script.sh
RUN chmod a+x /*.sh

ENTRYPOINT ["/script.sh"]