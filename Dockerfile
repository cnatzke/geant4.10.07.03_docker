#----------------------------------------------------------
# Author: C. Natzke
# Creation Date: July 2022
# Update: 
# Purpose: Multistage docker container for Geant4
#----------------------------------------------------------

#-------------------------------------------
# Build Container
#-------------------------------------------
# use OSG base container
FROM opensciencegrid/osgvo-ubuntu-20.04:latest as stage1

# versions of installed software
ARG version_geant4="geant4.10.07.p03"

# labeling information
LABEL description="Container for running GEANT4 with two-photon emission physics installed"
LABEL version="0.1.0"

# updating base container
RUN apt-get update && \
    apt-get install --no-install-recommends -yy build-essential && \
    rm -rf /var/lib/apt/lists/*

# make software directory
RUN mkdir /softwares

#-------------------------------------------
# GEANT4
#-------------------------------------------
RUN mkdir /softwares/geant4-src /softwares/geant4-src/build /softwares/${version_geant4}

# Downloads clean geant4 from internet
RUN wget https://geant4-data.web.cern.ch/geant4-data/releases/${version_geant4}.tar.gz --output-document /var/tmp/geant4.tar.gz && \
    tar zxf /var/tmp/geant4.tar.gz -C /softwares/geant4-src && rm /var/tmp/geant4.tar.gz

WORKDIR /softwares

# clone two-photon emission libraries
COPY ./install.sh .
RUN git clone https://github.com/cnatzke/geant4_2photon_physics.git && \
    mv install.sh geant4_2photon_physics && cd geant4_2photon_physics && \
    ./install.sh && rm -rf /softwares/geant4_2photon_physics

RUN cd /softwares/geant4-src/build && \
    cmake -DCMAKE_INSTALL_PREFIX=/softwares/${version_geant4} \ 
    -DGEANT4_INSTALL_DATA=ON \
    -DGEANT4_USE_OPENGL_X11=OFF \
    -DGEANT4_USE_GDML=OFF \
    -DGEANT4_USE_QT=OFF \
    /softwares/geant4-src/${version_geant4} && \
    make -j 6 && make install && \ 
    rm -rf /softwares/geant4-src

#-------------------------------------------
# Release Container
#-------------------------------------------
# use OSG base container
FROM opensciencegrid/osgvo-ubuntu-20.04:latest

COPY --from=stage1 /softwares /software

