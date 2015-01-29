FROM python:2-onbuild
# docker machine
RUN curl -L https://github.com/docker/machine/releases/download/v0.1.0-rc2/docker-machine_linux-386 -o /usr/bin/machine && chmod a+x /usr/bin/machine

# docker
RUN curl -sSL https://get.docker.com/ubuntu/ | sudo sh

CMD ["bash"]
