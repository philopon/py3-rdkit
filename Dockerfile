FROM alpine
MAINTAINER HirotomoMoriwaki <hirotomo.moriwaki@gmail.com>

RUN echo https://philopon.gitlab.io/alpine-repo >> /etc/apk/repositories  && \
    wget -P /etc/apk/keys https://philopon.gitlab.io/alpine-repo/philopon.dependence@gmail.com-5add7efe.rsa.pub &&\
    apk add --no-cache --update 'py3-rdkit=2019.03.3-r0' && \
    rm -r /var/cache/apk

CMD python3
