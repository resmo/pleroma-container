# Pleroma

[Pleroma](https://pleroma.social/) is a federated social networking platform, compatible with GNU social and other OStatus implementations. It is free software licensed under the AGPLv3.

## Usage

### Installation

Copy and modify `docker-compose.yml`, then:

```
docker-compose up
```

Setup the admin user (generates an URL to set password):

```
docker exec -ti pleroma_web ./bin/pleroma_ctl user new mynickname email@example.com --admin
```

Get a shell:
```
docker exec -ti pleroma_web /bin/ash
```

## Why

This project is based on and inspired by https://github.com/angristan/docker-pleroma. However I wanted to have a minimal container image without build utilities in it.
