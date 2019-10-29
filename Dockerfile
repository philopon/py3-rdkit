ARG PY_VERSION=3.8

FROM python:${PY_VERSION}-alpine AS building

ARG PY_VERSION
ARG BOOST_VERSION=1_67_0
ARG RDKIT_VERSION=2019_09_1

RUN wget https://dl.bintray.com/boostorg/release/${BOOST_VERSION//_/.}/source/boost_${BOOST_VERSION}.tar.gz
RUN wget https://github.com/rdkit/rdkit/archive/Release_${RDKIT_VERSION}.tar.gz

RUN tar xf boost_${BOOST_VERSION}.tar.gz
RUN tar xf Release_${RDKIT_VERSION}.tar.gz

ENV RDBASE=/rdkit-Release_${RDKIT_VERSION}
RUN mkdir ${RDBASE}/build

RUN apk add --no-cache alpine-sdk zlib-dev cmake eigen-dev jpeg-dev

RUN pip wheel numpy pillow pandas -w /wheel && pip install /wheel/*.whl

WORKDIR /boost_${BOOST_VERSION}
RUN ./bootstrap.sh --with-libraries=python,serialization,system,iostreams
RUN export CPLUS_INCLUDE_PATH="/usr/local/include/python${PY_VERSION}$(python -c 'import sys; print(sys.abiflags)')/";\
    ./b2 install -j$(nproc) --prefix=/opt/boost -d0

WORKDIR ${RDBASE}/build
RUN cmake .. -DRDK_INSTALL_INTREE=OFF -DBOOST_ROOT=/opt/boost -DBoost_NO_SYSTEM_PATHS=ON -DCMAKE_INSTALL_PREFIX=/opt/rdkit -DRDK_INSTALL_STATIC_LIBS=OFF
RUN make -j$(nproc)
RUN make install
ENV LD_LIBRARY_PATH=/opt/boost/lib:/opt/rdkit/lib PYTHONPATH=/opt/rdkit/lib/python${PY_VERSION}/site-packages/
RUN CTEST_OUTPUT_ON_FAILURE=1 ctest --exclude-regex pythonTestDirChem

ARG TINY=false
RUN if [[ "${TINY}" = true ]]; then\
    pip install /wheel/numpy-*.whl /wheel/Pillow-*.whl --prefix=/opt/pythonlib --force-reinstall;\
    rm -rf /opt/rdkit/share;\
    else\
    pip install /wheel/*.whl --prefix=/opt/pythonlib --force-reinstall;\
    fi
RUN find /opt | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf
RUN rm -rf /opt/rdkit/include /opt/boost/lib/*.a

FROM python:${PY_VERSION}-alpine
ARG PY_VERSION

COPY --from=building /opt/rdkit /opt/rdkit
COPY --from=building /opt/boost/lib /opt/boost/lib
COPY --from=building /opt/pythonlib /opt/pythonlib

ENV LD_LIBRARY_PATH=/opt/boost/lib:/opt/rdkit/lib
ENV PYTHONPATH=/opt/rdkit/lib/python${PY_VERSION}/site-packages:/opt/pythonlib/lib/python${PY_VERSION}/site-packages

RUN apk add --no-cache libstdc++ zlib libjpeg
CMD ["python"]

