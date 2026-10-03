FROM hexpm/elixir:1.20.2-erlang-29.0.2-debian-trixie-20260623-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV CC=gcc-14
ENV CXX=g++-14

RUN apt-get update && \
  apt-get dist-upgrade --yes && \
  apt-get install --yes --no-install-recommends \
    build-essential \
    ca-certificates \
    clang-format \
    cmake \
    curl \
    g++-14 \
    gcc-14 \
    git \
    inotify-tools \
    ninja-build \
    openssh-client \
    pkg-config \
    python3 \
    python3-venv \
    sudo \
    zsh && \
  update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 140 && \
  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 140 && \
  update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-14 140 && \
  update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-14 140 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/zsh -u 1000 -G sudo dev && \
  echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev && \
  chmod 0440 /etc/sudoers.d/dev && \
  mkdir -p /workspace && \
  chown dev:dev /workspace

USER dev

RUN git config --global --add safe.directory /workspace && \
  mix local.hex --force && \
  mix local.rebar --force

WORKDIR /workspace
