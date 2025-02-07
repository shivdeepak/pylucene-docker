FROM python:3.13

RUN pip install --upgrade pip && pip install build setuptools

WORKDIR /opt

# Install Temurin 23 JDK - https://adoptium.net/
# Temurin is a JDK distribution from Adoptium Working Group of the Eclipse Foundation
RUN apt install wget apt-transport-https gnupg
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
RUN echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
RUN apt update
RUN apt install temurin-23-jdk -y
ENV JAVA_HOME=/usr/lib/jvm/temurin-23-jdk-arm64

# Download, Build and Install pylucene - https://lucene.apache.org/pylucene/
RUN mkdir pylucene && cd pylucene \
    && wget https://downloads.apache.org/lucene/pylucene/pylucene-10.0.0-src.tar.gz -O pylucene.tar.gz \
    && tar -xzf pylucene.tar.gz --strip-components=1 \
    && rm pylucene.tar.gz

ENV JCC_JDK=$JAVA_HOME
RUN cd pylucene/jcc \
    && NO_SHARED=1 python -m build -nw \
    && pip install dist/JCC-*.whl

RUN cd pylucene \
    && make all install JCC='python -m jcc' PYTHON=python NUM_FILES=16 MODERN_PACKAGING=true 

# Clean up build files and leave samples in the working directory
RUN mv pylucene/samples samples && rm -rf pylucene

ENTRYPOINT ["/bin/bash"]
