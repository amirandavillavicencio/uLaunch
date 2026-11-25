ARG DKP_BASE
FROM ${DKP_BASE}
USER root
ENV DEVKITA64=/opt/devkitpro/devkitA64
RUN git init /tmp/libnx && cd /tmp/libnx && \
    git fetch --depth 1 https://github.com/switchbrew/libnx b156b4774fb2df7b93402169509266da7547fc4c && \
    git checkout --detach FETCH_HEAD && make -j$(nproc) && make -C nx install
