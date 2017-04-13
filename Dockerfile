# Compile and configure Lmod image, which will be base image for docker-easybuild.
# Stole some code and ideas from, rjeschmi/lmod:
# https://hub.docker.com/r/rjeschmi/lmod/

FROM ubuntu:16.04

MAINTAINER Erik Swanson "erik.swanson@cidresearch.orgr"

ENV LMOD_VER 7.4.5

# Install package dependencies for lmod and lua.
RUN apt-get update
RUN apt-get -y install \
      build-essential \
      curl \
      liblua5.2-dev \
      lua-filesystem \
      lua-json \
      lua-posix \
      lua5.2 \
      tclsh \
    && rm -rf /var/lib/apt/lists/*

# Add easybuild user so ownership is consistent with future images.
RUN useradd -u 1000 easybuild
RUN mkdir -p /build && \
    mkdir -p /easybuild
RUN chown easybuild.easybuild /build /easybuild

# Download, build and install lmod then clean up.
WORKDIR /build
RUN su easybuild -c "curl -LO http://github.com/TACC/Lmod/archive/${LMOD_VER}.tar.gz"
RUN su easybuild -c "mv /build/${LMOD_VER}.tar.gz /build/Lmod-${LMOD_VER}.tar.gz"
RUN su easybuild -c "tar xvf Lmod-${LMOD_VER}.tar.gz"
WORKDIR /build/Lmod-${LMOD_VER}
RUN su easybuild -c "./configure --prefix=/easybuild/deps"
RUN su easybuild -c "make install"
RUN ln -s /easybuild/deps/lmod/lmod/init/profile /etc/profile.d/modules.sh
RUN ln -s /easybuild/deps/lmod/lmod/init/cshrc /etc/profile.d/modules.csh
WORKDIR /root
RUN rm -rf /build

# Need to add this for non-interactive login shells.
RUN echo 'if [ -d /etc/profile.d ]; then\n\
  for i in /etc/profile.d/*.sh; do\n\
    if [ -r $i ]; then\n\
      . $i\n\
    fi\n\
  done\n\
  unset i\n\
fi\n'\
>> /etc/bash.bashrc

CMD /bin/bash
