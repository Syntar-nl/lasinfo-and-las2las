FROM alpine:3.24.1 AS builder

ARG LASTOOLS_VERSION=2.0.5
ARG LASTOOLS_HASH=3d66320076faed754c2b0bf353a00c5ba8c11d78a9cc4903289ca99a9cb308fe

ADD --checksum=sha256:${LASTOOLS_HASH} https://github.com/LAStools/LAStools/archive/refs/tags/v${LASTOOLS_VERSION}/LAStools.tar.gz /tmp/LAStools.tar.gz

RUN apk add --no-cache \
    build-base \
    cmake \
    && mkdir /tmp/LAStools \
    && tar -xzf /tmp/LAStools.tar.gz \
        --strip-components=1 \
        -C /tmp/LAStools \
    && cmake \
        -S /tmp/LAStools \
        -B /tmp/LAStools/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_EXE_LINKER_FLAGS="-static" \
    && cmake --build /tmp/LAStools/build \
        --target lasinfo las2las \
        -j"$(nproc)" \
    && mv /tmp/LAStools/bin64/lasinfo64 /usr/local/bin/lasinfo \
    && mv /tmp/LAStools/bin64/las2las64 /usr/local/bin/las2las \
    && cp -r /tmp/LAStools/bin/serf /usr/local/bin/serf

FROM gcr.io/distroless/static-debian13:nonroot

ENV PATH="/usr/local/bin:${PATH}"
COPY --from=builder /usr/local/bin/lasinfo /usr/local/bin/lasinfo
COPY --from=builder /usr/local/bin/las2las /usr/local/bin/las2las
COPY --from=builder /usr/local/bin/serf /usr/local/bin/serf

ENTRYPOINT ["lasinfo"]