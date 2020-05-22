
FROM ubuntu:16.04

ARG NUM_PROCESSORS=8

# Valgrind
RUN apt-get update && \ 
    apt-get install -y bzip2 libc6-dbg gcc wget git make

RUN wget -O /tmp/valgrind.tar.bz2 "https://sourceware.org/pub/valgrind/valgrind-3.13.0.tar.bz2" && \
    tar -xf /tmp/valgrind.tar.bz2 -C /tmp/

# Patch with ctgrind
COPY valgrind.patch /tmp/valgrind.patch
RUN cd /tmp/valgrind-3.13.0 && \
    git apply /tmp/valgrind.patch

RUN cd /tmp/valgrind-3.13.0 && \
    ./configure --prefix=/usr/share/valgrind && \
    make -j${NUM_PROCESSORS} && \
    make install

ENV PATH="$PATH:/usr/share/valgrind/bin"

# Libraries for ctgrind
RUN mkdir /usr/share/ctgrind
COPY src/ctgrind/ctgrind.h /usr/share/ctgrind/
COPY src/ctgrind/ctgrind.c /usr/share/ctgrind/
RUN cd /usr/share/ctgrind && \
    gcc -o libctgrind.so -shared ctgrind.c -Wall -std=c99 -fPIC -Wl,-soname,/usr/share/ctgrind/libctgrind.so.1 && \
    ln -s libctgrind.so libctgrind.so.1

COPY src/ctgrind/test.c /usr/share/ctgrind/test.c

RUN cd /usr/share/ctgrind && \
    gcc test.c -std=c99 -Wall -Wextra -Wshadow -O2 -ggdb -o test.o /usr/share/ctgrind/libctgrind.so -lm && \
    valgrind ./test.o

RUN rm -rf /var/lib/apt/lists/*

CMD ["bash"]