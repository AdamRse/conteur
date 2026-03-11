FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    rsync\
    gettext-base \
    diffutils \
    git \
    sudo \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash devuser

RUN echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN usermod -aG docker devuser

WORKDIR /home/devuser/conteur_src

COPY . .

RUN chown -R devuser:devuser /home/devuser/conteur_src

USER devuser

CMD ["/bin/bash"]