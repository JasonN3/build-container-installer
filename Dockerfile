FROM fedora:latest

ENV ARCH="x86_64"
ENV IMAGE_NAME="base-main"
ENV IMAGE_REPO="ghcr.io/ublue-os"
ENV IMAGE_TAG="$(version)"
ENV VARIANT="Kinoite"
ENV VERSION="39"
ENV WEB_UI="false"

WORKDIR /isogenerator

RUN dnf install -y make git && \
    git clone https://github.com/ublue-os/isogenerator.git . && \
    make install-deps


ENTRYPOINT ["make", "arch=${ARCH}", "version=${VERSION}", "image_repo=${IMAGE_REPO}", "image_name=${IMAGE_NAME}", "image_tag=${IMAGE_TAG}", "variant=${VARIANT}", "web_ui=${WEB_UI}"]
