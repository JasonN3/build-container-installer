FROM fedora:39

ARG VERSION=39

ENV ARCH="x86_64"
ENV IMAGE_NAME="base"
ENV IMAGE_REPO="quay.io/fedora-ostree-desktops"
ENV IMAGE_TAG="${VERSION}"
ENV VARIANT="Server"
ENV VERSION="${VERSION}"
ENV WEB_UI="false"

RUN mkdir /build-container-installer
COPY / /build-container-installer/

WORKDIR /build-container-installer

RUN dnf install -y make && make install-deps

VOLUME /build-container-installer/build

ENTRYPOINT ["/bin/bash", "/build-container-installer/entrypoint.sh"]

