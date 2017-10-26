FROM alpine
MAINTAINER HirotomoMoriwaki <hirotomo.moriwaki@gmail.com>

RUN echo https://philopon.github.io/alpine-repo >> /etc/apk/repositories  && \
    echo "-----BEGIN PUBLIC KEY-----"                                       >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6BHPHRq5bL0UO0WwC0lL" >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "XtYHWoA2ocWziK+KpTsU4Id+umFG6vs4YWeVNhbx5xOl4NgBco6IBMUEc6Xv2jbP" >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "kCdZKClm1qPjosMzg8nIhCS0BhjC51SPyL24TkQDbdjvDXnpi5X2n74y2Cdp+m4e" >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "2julC8rItC6J+tkDcbmlvocw6cPizml2+BHBuHd0QZsf4uu5peuUdgxqBd6SLCgr" >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "IyJo6H7S3Zx/t1EW7+5FvkSPEW8ww2RhbYejn9w8f8uWBEZQdAtWcZpnhQyIJYJo" >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "hNX0prKVdZO1DdXsNggevixrMPhMln37ZT6pp0NndXt20l3sqp7Rt0M1oSZ2V8Xr" >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "HwIDAQAB"                                                         >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    echo "-----END PUBLIC KEY-----"                                         >> /etc/apk/keys/philopon-alpine-repo.rsa.pub && \
    apk add --no-cache --update py3-rdkit && \
    rm -r /var/cache/apk

CMD python3
