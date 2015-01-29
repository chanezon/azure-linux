FROM python:2-onbuild
# docker machine
RUN curl -L https://github.com/docker/machine/releases/download/v0.1.0-rc2/docker-machine_linux-386 -o /usr/bin/machine && chmod a+x /usr/bin/machine

# docker
RUN curl -sSL https://get.docker.com/ubuntu/ | sh

#Node
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y nodejs

#Azure cli
RUN npm install azure-cli -g

VOLUME /usr/data

CMD ["bash"]
