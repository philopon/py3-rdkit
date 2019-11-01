ARG PY_VERSION=3.8
ARG BASE_IMAGE=ubuntu:18.04

FROM $BASE_IMAGE AS base

ARG PY_VERSION

RUN apt-get update &&\
    apt-get install -y --no-install-recommends gpg gpg-agent dirmngr &&\
    apt-key adv --keyserver keyserver.ubuntu.com --recv BA6932366A755776 &&\
    echo deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu $(. /etc/lsb-release && echo $DISTRIB_CODENAME) main >> /etc/apt/sources.list.d/deadsnakes.list &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends python${PY_VERSION} libpython${PY_VERSION} &&\
    apt-get purge -y --auto-remove gpg gpg-agent dirmngr &&\
    rm -rf /var/lib/apt/lists/* &&\
    cd /usr/bin && ln -sf python${PY_VERSION} python3 && ln -sf python${PY_VERSION} python

FROM base AS base-dev

ARG PY_VERSION

RUN apt-get update &&\
    apt-get install --no-install-recommends -y python${PY_VERSION}-dev python${PY_VERSION}-distutils wget ca-certificates &&\
    wget https://bootstrap.pypa.io/get-pip.py &&\
    python get-pip.py &&\
    rm -rf /var/lib/apt/lists/*

FROM base-dev as building

SHELL ["bash", "-c"]

ARG PY_VERSION
ARG BOOST_VERSION=1_67_0
ARG RDKIT_VERSION=2019_09_1

ENV PYTHON_EXECUTABLE=python${PY_VERSION}

RUN apt-get update && apt-get install --no-install-recommends -y cmake make zlib1g-dev libeigen3-dev libjpeg-dev g++

RUN ${PYTHON_EXECUTABLE} -m pip wheel numpy pillow pandas -w /wheel &&\
    ${PYTHON_EXECUTABLE} -m pip install /wheel/*.whl

RUN wget -q https://dl.bintray.com/boostorg/release/${BOOST_VERSION//_/.}/source/boost_${BOOST_VERSION}.tar.gz
RUN wget -q https://github.com/rdkit/rdkit/archive/Release_${RDKIT_VERSION}.tar.gz

RUN tar xf boost_${BOOST_VERSION}.tar.gz
RUN tar xf Release_${RDKIT_VERSION}.tar.gz

ENV RDBASE=/rdkit-Release_${RDKIT_VERSION}
RUN mkdir ${RDBASE}/build

WORKDIR /boost_${BOOST_VERSION}
RUN ./bootstrap.sh --with-libraries=python,serialization,system,iostreams --with-python=${PYTHON_EXECUTABLE}
RUN ./b2 install -j$(nproc) --prefix=/opt/boost -d0

WORKDIR ${RDBASE}/build
RUN cmake ..\
    -DRDK_INSTALL_INTREE=OFF\
    -DBOOST_ROOT=/opt/boost\
    -DBoost_NO_SYSTEM_PATHS=ON\
    -DCMAKE_INSTALL_PREFIX=/opt/rdkit\
    -DRDK_INSTALL_STATIC_LIBS=OFF\
    -DPYTHON_EXECUTABLE=$(which $PYTHON_EXECUTABLE)
RUN make -j$(nproc)
RUN make install

ENV LD_LIBRARY_PATH=/opt/boost/lib:/opt/rdkit/lib:${LD_LIBRARY_PATH}\
    PYTHONPATH=/opt/rdkit/lib/python${PY_VERSION}/site-packages
RUN if [[ "${PY_VERSION}" = 3.8 ]]; then\
    CTEST_OUTPUT_ON_FAILURE=1 ctest -R pythonTestDirChem;\
    else\
    CTEST_OUTPUT_ON_FAILURE=1 ctest;\
    fi

ARG TINY=false
RUN if [[ "${TINY}" = true ]]; then\
    ${PYTHON_EXECUTABLE} -m pip install /wheel/numpy-*.whl /wheel/Pillow-*.whl --prefix=/opt/pythonlib --force-reinstall -I;\
    rm -rf /opt/rdkit/share;\
    else\
    ${PYTHON_EXECUTABLE} -m pip install /wheel/*.whl --prefix=/opt/pythonlib --force-reinstall -I;\
    fi
RUN find /opt | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf
RUN rm -rf /opt/rdkit/include /opt/boost/lib/*.a

FROM base
ARG PY_VERSION

COPY --from=building /opt/rdkit /opt/rdkit
COPY --from=building /opt/boost/lib /opt/boost/lib
COPY --from=building /opt/pythonlib /opt/pythonlib

ENV PYTHON_EXECUTABLE=python${PY_VERSION}
ENV LD_LIBRARY_PATH=/opt/boost/lib:/opt/rdkit/lib
ENV PYTHONPATH=/opt/rdkit/lib/python${PY_VERSION}/site-packages:/opt/pythonlib/lib/python${PY_VERSION}/site-packages

RUN apt-get update && apt-get install -y --no-install-recommends zlib1g libjpeg8 &&\
    rm -rf /var/lib/apt/lists/*

SHELL ["bash", "-c"]
CMD ["bash", "-c", "${PYTHON_EXECUTABLE}"]
