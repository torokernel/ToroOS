FROM debian:buster
WORKDIR /root
RUN apt update && apt install python3-pip apt-utils make git wget libcap-dev libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev libglib2.0-dev libpixman-1-dev libseccomp-dev autoconf -y
RUN pip3 install ninja
RUN wget https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%202.0.10/fpc-laz_3.2.0-1_amd64.deb/download && mv download fpc-laz_3.2.0-1_amd64.deb && apt install ./fpc-laz_3.2.0-1_amd64.deb -y
RUN wget https://sourceforge.net/projects/freepascal/files/Linux/3.2.0/fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar/download && mv download fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar && tar -xf fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar && rm fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar
RUN cd fpc-3.2.0-i386-embedded.cross.x86_64-linux && echo $PWD | ./install.sh && cd ..
RUN ln -s /root /home/debian
RUN git clone https://github.com/qemu/qemu.git qemuforvmm
# TODO: remove branch
RUN git clone https://github.com/torokernel/ToroOS.git -b fixforsprint ToroOS
RUN cd qemuforvmm && git checkout 51204c2f && git apply ../ToroOS/patches/patch_for_fdc.patch && mkdir build && cd build && ../configure --target-list=x86_64-softmmu && make 
RUN git clone https://github.com/torokernel/freepascal.git -b fpc-for-toroos fpc-for-toroos
RUN sed -i '/LD=/c\LD="'"$PWD"'/fpc-3.2.0-i386-embedded.cross.x86_64-linux/bin/i386-unknown-elf-ld"' ./ToroOS/src/make.rules
RUN sed -i '/FPC=/c\FPC="'"$PWD"'/fpc-3.2.0-i386-embedded.cross.x86_64-linux/bin/x86_64-linux/ppcross386"' ./ToroOS/src/make.rules
RUN sed -i '/AS=/c\AS="'"$PWD"'/fpc-3.2.0-i386-embedded.cross.x86_64-linux/bin/i386-unknown-elf-as"' ./ToroOS/src/make.rules
RUN sed -i '/FPC_RTL=/c\FPC_RTL="'"$PWD"'/fpc-for-toroos/rtl"' ./ToroOS/src/make.rules
RUN sed -i '/FPC_EMB=/c\FPC_EMB="'"$PWD"'/fpc-3.2.0-i386-embedded.cross.x86_64-linux/units/i386-embedded/rtl"' ./ToroOS/src/make.rules
RUN sed -i '2 c\"'"$PWD"'/fpc-3.2.0-i386-embedded.cross.x86_64-linux\/units\/i386-embedded\/rtl\/system.o"' ./ToroOS/src/linkfile
RUN sed -i '3 c\"'"$PWD"'/fpc-3.2.0-i386-embedded.cross.x86_64-linux\/units\/i386-embedded\/rtl\/multiboot.o"' ./ToroOS/src/linkfile
RUN sed -i '4 c\"'"$PWD"'/fpc-3.2.0-i386-embedded.cross.x86_64-linux\/units\/i386-embedded\/rtl\/objpas.o"' ./ToroOS/src/linkfile
WORKDIR /root/ToroOS
