ARG version=39

FROM fedora:${version}

ENV ARCH="x86_64"
ENV IMAGE_NAME="base-main"
ENV IMAGE_REPO="ghcr.io/ublue-os"
ENV IMAGE_TAG="${version}"
ENV VARIANT="Kinoite"
ENV VERSION="${version}"
ENV WEB_UI="false"

COPY / /isogenerator
WORKDIR /isogenerator

RUN dnf install -y make && make install-deps

VOLUME /isogenerator/output

ENTRYPOINT ["make" ]
CMD [ "ARCH=${ARCH}", "VERSION=${VERSION}", "IMAGE_REPO=${IMAGE_REPO}", "IMAGE_NAME=${IMAGE_NAME}", "IMAGE_TAG=${IMAGE_TAG}", "VARIANT=${VARIANT}", "WEB_UI=${WEB_UI}"]
