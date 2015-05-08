FROM python:2-onbuild
# docker machine
RUN curl -L https://github.com/docker/machine/releases/download/v0.2.0/docker-machine_linux-amd64 -o /usr/bin/docker-machine && chmod a+x /usr/bin/docker-machine

# docker
RUN curl -L https://get.docker.com/builds/Linux/x86_64/docker-latest -o /usr/bin/docker && chmod +x /usr/bin/docker

#Node
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y nodejs

#Azure cli
RUN npm install azure-cli -g

VOLUME /usr/data
VOLUME /root/.docker

CMD ["bash"]
