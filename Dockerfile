# An Ubuntu environment configured for building the phd repo.
FROM nvidia/opencl

MAINTAINER Beau Johnston <beau.johnston@anu.edu.au>

ENV DEBIAN_FRONTEND noninteractive

# Setup the environment.
ENV HOME /root
ENV USER docker
ENV LSB_SRC /libscibench-source
ENV LSB /libscibench
ENV LEVELDB_SRC /leveldb-source
ENV LEVELDB_ROOT /leveldb
ENV OCLGRIND_SRC /oclgrind-source
ENV OCLGRIND /oclgrind
ENV OCLGRIND_BIN /oclgrind/bin/oclgrind
ENV GIT_LSF /git-lsf
ENV PREDICTIONS /opencl-predictions-with-aiwc
ENV EOD /OpenDwarfs
ENV OCL_INC /opt/khronos/opencl/include
ENV OCL_LIB /opt/intel/opencl-1.2-6.4.0.25/lib64
ENV LLVM_SRC_ROOT /downloads/llvm
ENV LLVM_BUILD_ROOT /downloads/llvm-build
ENV COCL /coriander/bin/bin/cocl

# Install essential packages.
RUN apt-get update
RUN apt-get install --no-install-recommends -y software-properties-common \
    ocl-icd-opencl-dev \
    pkg-config \
    build-essential \
    git \
    make \
    zlib1g-dev \
    apt-transport-https \
    dirmngr \
    wget \
    gcc \
    g++

# Install cmake -- newer version than with apt
RUN wget -qO- "https://cmake.org/files/v3.12/cmake-3.12.1-Linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C /usr

# Install OpenCL Device Query tool
RUN git clone https://github.com/BeauJoh/opencl_device_query.git /opencl_device_query

#Install Cuda
RUN apt-get update -q && apt-get install --no-install-recommends -yq nvidia-cuda-toolkit

# Install LibSciBench
RUN git clone https://github.com/spcl/liblsb.git $LSB_SRC
WORKDIR $LSB_SRC
RUN ./configure --prefix=$LSB
RUN make
RUN make install

# Install leveldb (optional dependency for OclGrind)
RUN git clone https://github.com/google/leveldb.git $LEVELDB_SRC
RUN mkdir $LEVELDB_SRC/build
WORKDIR $LEVELDB_SRC/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX=$LEVELDB_ROOT
RUN make
RUN make install

# Pull down coriander
WORKDIR /coriander
RUN apt-get update && apt-get install -y --no-install-recommends git gcc g++ libc6-dev zlib1g-dev \
    libtinfo-dev \
    curl ca-certificates build-essential wget xz-utils \
    apt-utils bash-completion
RUN git clone --recursive https://github.com/beaujoh/coriander -b master
RUN cd coriander && \
    mkdir soft

# Install LLVM 3.9.0 -- with dynamic libraries
WORKDIR /coriander/soft
RUN wget http://releases.llvm.org/3.9.0/llvm-3.9.0.src.tar.xz && tar -xf llvm-3.9.0.src.tar.xz
WORKDIR /coriander/soft/llvm-3.9.0.src/tools
RUN wget http://releases.llvm.org/3.9.0/cfe-3.9.0.src.tar.xz && tar -xf cfe-3.9.0.src.tar.xz && mv cfe-3.9.0.src clang
WORKDIR /coriander/soft/llvm-3.9.0.build
RUN cmake -DBUILD_SHARED_LIBS=On -DLLVM_BUILD_LLVM_DYLIB=On -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/coriander/soft/llvm-3.9.0.bin /coriander/soft/llvm-3.9.0.src
RUN make -j32
RUN make install

##Install coriander
WORKDIR /coriander/build
RUN cmake /coriander/coriander -DCMAKE_BUILD_TYPE=Debug -DCLANG_HOME=/coriander/soft/llvm-3.9.0.bin -DCMAKE_INSTALL_PREFIX=/coriander/bin && make -j 32 && make install
RUN apt-get update && apt-get install -y --no-install-recommends gcc-multilib g++-multilib
RUN wget --directory-prefix=/coriander/bin/include/cocl/ https://raw.githubusercontent.com/llvm-mirror/clang/master/lib/Headers/__clang_cuda_builtin_vars.h
RUN python3 /coriander/bin/bin/cocl_plugins.py install --repo-url https://github.com/hughperkins/coriander-CLBlast.git
RUN mv /coriander/bin/lib/coriander_plugins/* /coriander/bin/lib/
RUN make install

# Install utilities
RUN apt-get install -y --no-install-recommends vim less silversearcher-ag

# Install OclGrind
RUN apt-get install --no-install-recommends -y libreadline-dev
RUN git clone https://github.com/BeauJoh/Oclgrind.git $OCLGRIND_SRC
RUN mkdir $OCLGRIND_SRC/build
WORKDIR $OCLGRIND_SRC/build
ENV CC /coriander/soft/llvm-3.9.0.bin/bin/clang
ENV CXX /coriander/soft/llvm-3.9.0.bin/bin/clang++
RUN cmake $OCLGRIND_SRC -DUSE_LEVELDB=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLLVM_DIR=/coriander/soft/llvm-3.9.0.bin/lib/cmake/llvm -DCLANG_ROOT=/coriander/soft/llvm-3.9.0.bin -DCMAKE_INSTALL_PREFIX=$OCLGRIND -DBUILD_SHARED_LIBS=On
RUN make
RUN make install

WORKDIR /workspace
COPY . /workspace

CMD make test
