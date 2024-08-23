FROM scilus/scilus:2.0.2

ARG NFTEST_VERSION

ENV NODE_MAJOR=18
ENV NFTEST_VERSION=${NFTEST_VERSION:-0.9.0-rc1}

RUN apt update && apt install -y \
        curl \
        git \
        python3-venv \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install pipx && \
    python3 -m pipx ensurepath && \
    pipx install poetry

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - &&\
    apt-get install -y nodejs && \
    groupadd --gid 501 yeoman && \
    useradd --uid 501 --gid yeoman --shell /bin/bash --create-home yeoman && \
    echo "yeoman ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir /generated && chown yeoman:yeoman /generated
WORKDIR /generated
