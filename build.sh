#!/usr/bin/env bash

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--tag)        TAG="$2";            shift 2 ;;
        -r|--registry)   REGISTRY="$2";       shift 2 ;;
        -c|--controller) CONTROL_IMAGE="$2";  shift 2 ;;
        -w|--worker)     WORKER_IMAGE="$2";   shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Map vars to corresponding argument
declare -A FLAGS=(
    [TAG]="-t/--tag"
    [REGISTRY]="-r/--registry"
    [CONTROL_IMAGE]="-c/--controller"
    [WORKER_IMAGE]="-w/--worker"
)

# Show missing argument(s)
for var in TAG REGISTRY CONTROL_IMAGE WORKER_IMAGE
do
    if [[ -z "${!var}" ]]
    then
        echo "Missing required argument: ${FLAGS[$var]}"
        exit 1
    fi
done

# Controller
echo "Building Controller image - $CONTROL_IMAGE:$TAG"
docker build --build-arg TARGETARCH=amd64 --build-arg COMPONENT=controller -t $REGISTRY/$CONTROL_IMAGE:$TAG .

echo "Pushing $CONTROL_IMAGE:$TAG to $REGISTRY"
docker push $REGISTRY/$CONTROL_IMAGE:$TAG


# Worker
echo "Building Worker image - $WORKER_IMAGE:$TAG"
docker build --build-arg TARGETARCH=amd64 --build-arg COMPONENT=worker -t $REGISTRY/$WORKER_IMAGE:$TAG .

echo "Pushing $WORKER_IMAGE:$TAG to $REGISTRY"
docker push $REGISTRY/$WORKER_IMAGE:$TAG