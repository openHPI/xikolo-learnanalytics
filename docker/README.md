# Docker configuration

## Build containers

```console
$ cd docker/
$ docker buildx bake --load
[..]
```

### Build and push to specific registry

```console
$ cd docker/
$ REGISTRY=registry.example.org/container docker buildx bake [--push|--load]
[..]
```

## Usage

### Local demo/testing

The default compose configuration expects a running xikolo environment that already includes `redis-cache`, `redis-sidekiq`, and the shared `rabbitmq`:

```console
cd docker/
docker compose [-f compose.yml] up
```

#### Standalone mode

The standalone mode starts (and stops) `redis-cache`, `redis-sidekiq` and `rabbitmq` in addition to the lanalytics services:

```console
cd docker/
docker compose -f compose.standalone.yml up
```

Note: The containers are named identical to the one used in the xikolo compose demo. Therefore, docker will use these, if the exists or are running. Stopping the standalone environment will stop the Redis and RabbitMQ containers, even if you have a xikolo compose still running.

## Configuration

### Environment variables

See `.env`.

### Configuration files

TODO

## Setup

TODO
