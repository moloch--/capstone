FROM emscripten/emsdk:4.0.18 AS builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get upgrade -y

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  cmake \
  curl \
  git \
  python3 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN emcmake cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCAPSTONE_BUILD_SHARED_LIBS=OFF \
  -DCAPSTONE_BUILD_STATIC_LIBS=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_STATIC_LIBS=ON \
  -DCAPSTONE_BUILD_CSTOOL=OFF \
  -DCAPSTONE_BUILD_TESTS=OFF \
  -DCAPSTONE_INSTALL=OFF \
  -DCMAKE_INSTALL_PREFIX=/opt/capstone \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON

RUN cmake --build build --target capstone_static -- -j"$(nproc)"
RUN mkdir -p /opt/capstone/lib && \
  CAPSTONE_A="$(find build -name libcapstone.a -print -quit)" && \
  test -n "$CAPSTONE_A" && \
  emcc -sSIDE_MODULE=1 -sEXPORT_ALL=1 -sWASM_BIGINT=1 -sERROR_ON_UNDEFINED_SYMBOLS=0 \
    -Wl,--whole-archive "$CAPSTONE_A" -Wl,--no-whole-archive \
    -o /opt/capstone/lib/libcapstone.wasm

FROM scratch AS artifact
COPY --from=builder /opt/capstone/lib/libcapstone.wasm /libcapstone.wasm
