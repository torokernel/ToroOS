FROM debian:buster
WORKDIR /root
RUN apt update && apt install python3-pip apt-utils make git wget libcap-dev libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev libglib2.0-dev libpixman-1-dev libseccomp-dev autoconf -y
RUN git clone https://github.com/ninja-build/ninja.git
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN cd ninja && git checkout v1.7.0 && ./configure.py --bootstrap && cp ./ninja /usr/bin/ninja
RUN wget https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%202.0.10/fpc-laz_3.2.0-1_amd64.deb/download && mv download fpc-laz_3.2.0-1_amd64.deb && apt install ./fpc-laz_3.2.0-1_amd64.deb -y
RUN wget https://sourceforge.net/projects/freepascal/files/Linux/3.2.0/fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar/download && mv download fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar && tar -xf fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar && rm fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar
RUN cd fpc-3.2.0-i386-embedded.cross.x86_64-linux && echo $PWD | ./install.sh && cd ..
RUN ln -s /root /home/debian
RUN git clone https://github.com/qemu/qemu.git qemufortoroos
RUN wget https://raw.githubusercontent.com/torokernel/ToroOS/master/patches/patch_for_fdc.patch
# TODO: remove patch on qemu
RUN cd qemufortoroos && git checkout 51204c2f && git apply /root/patch_for_fdc.patch && mkdir build && cd build && ../configure --target-list=x86_64-softmmu && make
RUN git clone https://github.com/torokernel/freepascal.git -b fpc-for-toroos fpc-for-toroos
RUN wget https://sourceforge.net/projects/toro/files/images/toro-1.1.3/toro-1.1.3.img/download && mv download /root/floppy-disk.img
