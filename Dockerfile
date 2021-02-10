#FROM innovanon/ia-tither-7 as builder

FROM innovanon/autofdo as converter
#COPY --from=builder   /var/cpuminer/ /var/cpuminer.data/
COPY ./var/cpuminer/data /var/cpuminer.data/
RUN create_gcov                    \
      --binary=$PREFIX/xmrig       \
      --profile=/var/cpuminer.data \
      --gcov=/var/cpuminer

#FROM bootstrap as builder
FROM innovanon/intel-builder as builder

ARG CPPFLAGS
ARG   CFLAGS
ARG CXXFLAGS
ARG  LDFLAGS

#ENV CHOST=x86_64-linux-gnu

ENV CPPFLAGS="$CPPFLAGS"
ENV   CFLAGS="$CFLAGS"
ENV CXXFLAGS="$CXXFLAGS"
ENV  LDFLAGS="$LDFLAGS"

#ENV PREFIX=/usr/local
ENV PREFIX=/opt/cpuminer

ARG ARCH=native
ENV ARCH="$ARCH"

ENV CCP=/opt/intel/oneapi/compiler/latest/linux/bin
ENV CC=$CCP/icx
ENV CXX=$CCP/icpx
ENV FC=$CCP/ifort
#ENV PATH=/opt/intel/oneapi/compiler/latest/linux/bin:$PATH

##ENV CPPFLAGS="-DUSE_ASM $CPPFLAGS"
#ENV   CFLAGS="-march=$ARCH -mtune=$ARCH $CFLAGS"
#
## PGO
##ENV   CFLAGS="-fipa-profile -fprofile-reorder-functions -fvpt -pg -fprofile-abs-path -fprofile-dir=/var/cpuminer  $CFLAGS"
##ENV  LDFLAGS="-fipa-profile -fprofile-reorder-functions -fvpt -pg -fprofile-abs-path -fprofile-dir=/var/cpuminer $LDFLAGS"
#ENV   CFLAGS="-pg -fprofile-abs-path -fprofile-generate=/var/cpuminer  $CFLAGS"
#ENV  LDFLAGS="-pg -fprofile-abs-path -fprofile-generate=/var/cpuminer $LDFLAGS"
ENV  CFLAGS="-fauto-profile=/var/cpuminer  $CFLAGS"
ENV LDFLAGS="-fauto-profile=/var/cpuminer $LDFLAGS"
#
## Debug
##ENV CPPFLAGS="-DNDEBUG $CPPFLAGS"
ENV   CFLAGS="-Ofast -g0 $CFLAGS"
#
## Static
##ENV  LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
#
## LTO
#ENV   CFLAGS="-fuse-linker-plugin -flto $CFLAGS"
#ENV  LDFLAGS="-fuse-linker-plugin -flto $LDFLAGS"
###ENV   CFLAGS="-fuse-linker-plugin -flto -ffat-lto-objects $CFLAGS"
###ENV  LDFLAGS="-fuse-linker-plugin -flto -ffat-lto-objects $LDFLAGS"
#
## Dead Code Strip
ENV   CFLAGS="-ffunction-sections -fdata-sections $CFLAGS"
ENV  LDFLAGS="-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections $LDFLAGS"
###ENV  LDFLAGS="-Wl,-Bsymbolic -Wl,--gc-sections $LDFLAGS"
#
## Optimize
##ENV   CLANGFLAGS="-ffast-math -fassociative-math -freciprocal-math -fmerge-all-constants $CFLAGS"
##ENV       CFLAGS="-fipa-pta -floop-nest-optimize -fgraphite-identity -floop-parallelize-all $CLANGFLAGS"
ENV CFLAGS="-fmerge-all-constants $CFLAGS"
#ENV CFLAGS="$CFLAGS -fPIE -pie"
#ENV CXXFLAGS="$CXXFLAGS -fPIE -pie"
#ENV LDFLAGS="$LDFLAGS -fPIE -pie"

#ENV CLANGXXFLAGS="$CLANGFLAGS $CXXFLAGS"
ENV CXXFLAGS="$CFLAGS $CXXFLAGS"

WORKDIR /tmp

#COPY    ./fingerprint.sh ./
#RUN     ./fingerprint.sh \
# && rm -v fingerprint.sh
COPY --from=builder $PREFIX/lib/libfingerprint.a $PREFIX/lib/libfingerprint.a

#COPY --from=builder /tmp/libevent/   /tmp/
#COPY --from=builder /tmp/libevent.sh /tmp/
#RUN     ./libevent.sh  2

#COPY --from=builder /tmp/tor/        /tmp/
#COPY --from=builder /tmp/tor.sh      /tmp/
#RUN     ./tor.sh       2

#COPY --from=builder /tmp/libuv/      /tmp/
#COPY --from=builder /tmp/libuv.sh    /tmp/
#RUN     ./libuv.sh     2

#COPY --from=builder /tmp/hwloc/      /tmp/
#COPY --from=builder /tmp/hwloc.sh    /tmp/
#RUN     ./hwloc.sh     2

COPY --from=builder /tmp/xmrig/      /tmp/
COPY --from=builder /tmp/xmrig.sh               \
                    /tmp/donate.h.sed           \
                    /tmp/DonateStrategy.cpp.sed \
                    /tmp/Config_default.h       \
                                     /tmp/
RUN ./xmrig.sh     2              \
 && rm -rf /tmp/*

# TODO
RUN ldd $PREFIX/bin/xmrig

RUN strip --strip-all          $PREFIX/bin/xmrig
RUN upx --best --overlay=strip $PREFIX/bin/xmrig
FROM scratch as final
COPY --from=builder-2 $PREFIX/bin/xmrig /
ENTRYPOINT ["/xmrig"]

#FROM scratch as squash
#COPY --from=builder / /
#RUN chown -R tor:tor /var/lib/tor
#SHELL ["/usr/bin/bash", "-l", "-c"]
#ARG TEST
#
#FROM squash as test
#ARG TEST
#RUN tor --verify-config \
# && sleep 127           \
# && xbps-install -S     \
# && exec true || exec false
#
#FROM squash as final
#VOLUME /var/cpuminer
#ENTRYPOINT []

