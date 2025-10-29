FROM emscripten/emsdk:4.0.18 AS builder
ENV DEBIAN_FRONTEND=noninteractive

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
  -DCAPSTONE_BUILD_SHARED_LIBS=ON \
  -DCAPSTONE_BUILD_STATIC_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=/opt/capstone \
  -DCMAKE_SHARED_LIBRARY_SUFFIX=.wasm \
  -DCMAKE_C_FLAGS="-sWASM_BIGINT=1" \
  -DCMAKE_CXX_FLAGS="-sWASM_BIGINT=1" \
  -DCMAKE_SHARED_LINKER_FLAGS="-sSIDE_MODULE=1 -sEXPORT_ALL=1 -sWASM_BIGINT=1 -sERROR_ON_UNDEFINED_SYMBOLS=0"

RUN cmake --build build --target capstone_shared -- -j"$(nproc)"
RUN cmake --install build

FROM scratch AS artifact
COPY --from=builder /opt/capstone/lib/libcapstone.wasm /libcapstone.wasm
