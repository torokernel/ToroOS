docker run --rm --mount type=bind,source="$(pwd)",target=/root/toroos --workdir="/root/toroos/src" toroos-dev make
docker run --rm --mount type=bind,source="$(pwd)",target=/root/toroos --workdir="/root/toroos/tools" toroos-dev make
docker run --rm -e "DISPLAY=${DISPLAY:-:0.0}" -v /tmp/.X11-unix:/tmp/.X11-unix --mount type=bind,source="$(pwd)",target=/root/toroos --workdir="/root/toroos/src" --privileged=true --publish=0.0.0.0:5900:5900 -it toroos-dev ./run.sh
