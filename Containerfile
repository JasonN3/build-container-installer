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
COPY /lorax_templates /build-container-installer/lorax_templates
COPY /xorriso /build-container-installer/xorriso
COPY /Makefile /build-container-installer
COPY /entrypoint.sh /

WORKDIR /build-container-installer
VOLUME /build-container-installer/build
VOLUME /cache

RUN dnf install -y make && make install-deps
RUN ln -s ~/.local/share/containers/cache /cache/skopeo

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

