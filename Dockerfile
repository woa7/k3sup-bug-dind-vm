# docker build . -t k3sup-bug-dind-vm
# docker run --rm -it k3sup-bug-dind-vm bash
# docker run --rm -it k3sup-bug-dind-vm

ARG QEMUVER
#ARG QEMU_VER=${QEMUVER:-5}
ARG QEMU_VER=${QEMUVER:-5}
ARG TAG
ARG TAGvar=${TAG:-word}
#ENV env_var_name=$var_name
ARG HTTP_PROXY
ARG http_proxy
ARG HTTPS_PROXY
ARG https_proxy
ARG FTP_PROXY
ARG ftp_proxy
ARG NO_PROXY
ARG no_proxy
ARG TARGETPLATFORM
# - platform of the build result. Eg linux/amd64, linux/arm/v7, windows/amd64.
ARG TARGETOS
# - OS component of TARGETPLATFORM
ARG TARGETARCH
# - architecture component of TARGETPLATFORM
ARG TARGETVARIANT
# - variant component of TARGETPLATFORM
ARG BUILDPLATFORM
# - platform of the node performing the build.
ARG BUILDOS
# - OS component of BUILDPLATFORM
ARG BUILDARCH
# - architecture component of BUILDPLATFORM
ARG BUILDVARIANT
# - variant component of BUILDPLATFORM

ARG SOURCE_BRANCH
#: the name of the branch or the tag that is currently being tested.
ARG SOURCE_COMMIT
#: the SHA1 hash of the commit being tested.
ARG COMMIT_MSG
#: the message from the commit being tested and built.
ARG DOCKER_REPO
#: the name of the Docker repository being built.
ARG DOCKERFILE_PATH
#: the dockerfile currently being built.
ARG DOCKER_TAG
#: the Docker repository tag being built.
ARG IMAGE_NAME
#: the name and tag of the Docker repository being built. (This variable is a combination of DOCKER_REPO:DOCKER_TAG.)

#ARG QEMUVER=${QEMUVER:-5}
#ENV QEMU_VER=${QEMUVER:-5}
#ARG TAG
#ENV TAGvar=${TAG:-word}
##ARG TAG=${TAG:-word1}
##ARG TAGvar=${TAG:-word}
###ARG QEMU_VER=${QEMUVER:-5}
FROM tianon/qemu:${QEMU_VER} as builder
RUN echo tagvar $TAGvar tagvar
RUN echo tag $TAG tag

# https://unix.stackexchange.com/questions/480459/docker-debianstretch-slim-install-man-and-view-manpages
# https://github.com/debuerreotype/debuerreotype/blob/0.8/scripts/debuerreotype-slimify#L51
# https://wiki.ubuntu.com/ReducingDiskFootprint#Drop_unnecessary_files
#RUN mv /etc/dpkg/dpkg.cfg.d/docker /etc/dpkg/dpkg.cfg.d/docker.old && apt-get update && apt-get install -y --reinstall coreutils && apt-get install -y --reinstall man less

#RUN apk add --no-cache curl
RUN apt-get update && apt-get install -y curl gpgv1 gpgv2 gnupg1 nvi
RUN apt-get update && apt-cache policy cloud-init-tools && apt-get install -y cloud-init-tools || true
RUN apt-get update && apt-cache policy cloud-image-utils && apt-get install -y cloud-image-utils || true
RUN command -v cloud-localds && cloud-localds --help
RUN curl -L --fail https://github.com/docker/compose/releases/latest/download/run.sh -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose


FROM builder

#curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#/releases/latest
#sudo curl -L --fail https://github.com/docker/compose/releases/download/1.26.2/run.sh -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
ENV WORKDIR /data
RUN mkdir -p $WORKDIR
COPY run.sh /
#RUN bash run.sh
CMD ["bash", "/run.sh"]

