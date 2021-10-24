FROM ubuntu:20.04

COPY . /files
WORKDIR /files

RUN ./bootstrap.sh
