# Used by buildah build --build-arg to create multiple different versions of the image
ARG VERSION=39

FROM fedora:${VERSION}

# Set version for the environment variables in the container.
ARG VERSION=39

ENV ARCH="x86_64"
ENV IMAGE_NAME="base-main"
ENV IMAGE_REPO="ghcr.io/ublue-os"
ENV IMAGE_TAG="${VERSION}"
ENV VARIANT="Kinoite"
ENV VERSION="${VERSION}"
ENV WEB_UI="false"
ENV SECURE_BOOT_KEY_URL=""
ENV ENROLLMENT_PASSWORD="ublue-os"

COPY / /isogenerator
WORKDIR /isogenerator

RUN dnf install -y make && make install-deps

VOLUME /isogenerator/output

ENTRYPOINT /isogenerator/entrypoint.sh
