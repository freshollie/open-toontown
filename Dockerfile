FROM alpine:3.12 as panda3d
WORKDIR /panda3d

ARG QEMU_CPU
ENV QEMU_CPU=${QEMU_CPU}

RUN apk add python3 patchelf python3-dev binutils py3-pip alpine-sdk build-base linux-headers openssl-dev zlib-dev
RUN git clone --depth 1 https://github.com/open-toontown/panda3d.git

WORKDIR /panda3d/panda3d

RUN python3 makepanda/makepanda.py --threads $(nproc) --nothing --wheel --use-python --use-direct --use-nametag --use-movement --use-navigation --use-dna --use-suit --use-pets --use-pandaparticlesystem --use-pandaphysics --use-deploytools --use-contrib --use-openssl --use-zlib

FROM alpine:3.12 as base

ARG QEMU_CPU
ENV QEMU_CPU=${QEMU_CPU}

WORKDIR /toontown

RUN apk update && apk add --no-cache python3 py3-pip libstdc++
RUN pip install pytz

COPY --from=panda3d /panda3d/panda3d/*.whl .
RUN pip install *.whl

COPY otp otp
COPY toontown toontown
COPY etc etc

COPY resources/ resources/

FROM base as ai

ENV BASE_CHANNEL=401000000
ENV MAX_CHANNELS=999999
ENV STATE_SERVER=4002
ENV MESSAGE_DIRECTOR_IP="127.0.0.1:7199"
ENV EVENT_LOGGER_IP="127.0.0.1:7197"
ENV DISTRICT_NAME="Toon Valley"

CMD python3 -u -m toontown.ai.AIStart --base-channel $BASE_CHANNEL \
               --max-channels $MAX_CHANNELS --stateserver $STATE_SERVER \
               --messagedirector-ip $MESSAGE_DIRECTOR_IP \
               --eventlogger-ip $EVENT_LOGGER_IP --district-name "$DISTRICT_NAME"

FROM base as ud

COPY resources/phase_3/etc resources/phase_3/etc

ENV MAX_CHANNELS=999999
ENV STATE_SERVER=4002
ENV MESSAGE_DIRECTOR_IP="127.0.0.1:7199"
ENV EVENT_LOGGER_IP="127.0.0.1:7197"
ENV BASE_CHANNEL=1000000

CMD python3 -u -m toontown.uberdog.UDStart --base-channel $BASE_CHANNEL \
               --max-channels $MAX_CHANNELS --stateserver $STATE_SERVER \
               --messagedirector-ip $MESSAGE_DIRECTOR_IP \
               --eventlogger-ip $EVENT_LOGGER_IP
