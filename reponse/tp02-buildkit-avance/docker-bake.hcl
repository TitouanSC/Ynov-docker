variable "VERSION" {
  default = "1.0"
}

variable "GIT_SHA" {
  default = "local"
}

variable "REGISTRY" {
  default = "docker.io/library"
}

group "default" {
  targets = ["api", "worker"]
}

target "_common" {
  args = {
    APP_VERSION = VERSION
    GIT_SHA     = GIT_SHA
  }
  labels = {
    "org.opencontainers.image.revision" = GIT_SHA
    "org.opencontainers.image.version"  = VERSION
  }
}

target "api" {
  inherits   = ["_common"]
  context    = "../tp01-optimisation-image/shopapi"
  dockerfile = "Dockerfile"
  tags       = ["${REGISTRY}/shopapi:${VERSION}"]
}

target "worker" {
  inherits   = ["_common"]
  context    = "./shop-worker"
  dockerfile = "Dockerfile"
  tags       = ["${REGISTRY}/shop-worker:${VERSION}"]
  secret = [
    { type = "file", id = "pipconf", src = "./shop-worker/pip.conf" }
  ]
}

target "worker-test" {
  inherits = ["worker"]
  target   = "test"
  tags     = ["${REGISTRY}/shop-worker:test"]
  output   = ["type=cacheonly"]
}
