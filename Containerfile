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

COPY / /isogenerator
WORKDIR /isogenerator

RUN dnf install -y make && make install-deps

VOLUME /isogenerator/output

ENTRYPOINT ["sh", "-c", "make output/${IMAGE_NAME}-${IMAGE_TAG}.iso ARCH=${ARCH} VERSION=${VERSION} IMAGE_REPO=${IMAGE_REPO} IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${IMAGE_TAG} VARIANT=${VARIANT} WEB_UI=${WEB_UI}"]
