FROM alpine AS build
MAINTAINER HirotomoMoriwaki <hirotomo.moriwaki@gmail.com>

ARG RDKIT_VERSION=2018_09_3

RUN wget https://github.com/rdkit/rdkit/archive/Release_${RDKIT_VERSION}.tar.gz

RUN apk add --update\
    alpine-sdk cmake coreutils eigen-dev sqlite sqlite-dev\
    python3-dev py3-numpy py-numpy-dev py3-six py3-pillow\
    boost-dev boost-system boost-thread boost-serialization boost-python3 boost-regex

RUN pip3 install pandas

RUN tar xvf Release_${RDKIT_VERSION}.tar.gz

WORKDIR rdkit-Release_${RDKIT_VERSION}
RUN mkdir build
WORKDIR build
RUN cmake .. -DPYTHON_EXECUTABLE=/usr/bin/python3 -DRDK_INSTALL_INTREE=OFF -DCMAKE_INSTALL_PREFIX=/usr/local
RUN make -j`nproc`

RUN make install
RUN PYTHONPATH=/usr/local/lib/python3.6/site-packages RDBASE=$(pwd)/.. ctest

FROM alpine

COPY --from=build /usr/local /usr/local

RUN apk add --no-cache py3-numpy libstdc++\
    boost-python3 boost-serialization boost-system boost-thread boost-regex

RUN V=$(python3 -c 'import sys; print("{}.{}".format(*sys.version_info[:2]))') &&\
    echo /usr/local/lib/python$V/site-packages > /usr/lib/python$V/site-packages/usr_local.pth

ENTRYPOINT python3
