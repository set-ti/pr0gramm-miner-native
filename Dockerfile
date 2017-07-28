FROM aaronmboyd/xmrminer:latest

ENV DEBIAN_FRONTEND noninteractive

# install curl ca-certificates gnupg apt-transport-https
RUN apt-get update -y
RUN apt-get install -y --no-install-recommends curl ca-certificates gnupg apt-transport-https

# install Node.js
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

# Node.js package to keep the proxy running in case of failure
RUN npm -g i forever

# Add Node.js proxy server to container
ADD xm /xm
WORKDIR /xm
RUN npm i

ADD run.sh /xmrMiner/build/

WORKDIR /xmrMiner/build/
ENTRYPOINT ["./run.sh"]
