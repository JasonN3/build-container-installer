FROM fedora:39

ARG VERSION=39

ENV ARCH="x86_64"
ENV IMAGE_NAME="base-main"
ENV IMAGE_REPO="ghcr.io/ublue-os"
ENV IMAGE_TAG="${VERSION}"
ENV VARIANT="Kinoite"
ENV VERSION="${VERSION}"
ENV WEB_UI="false"

RUN mkdir /build-container-installer
COPY /lorax_templates /build-container-installer
COPY /xorriso /build-container-installer
COPY /Makefile /build-container-installer
COPY /entrypoint.sh /

WORKDIR /build-container-installer

RUN dnf install -y make && make install-deps

VOLUME /build-container-installer/build

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]