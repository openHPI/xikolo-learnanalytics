# vim: ft=hcl

variable TAG {
  default = "latest"
}

variable CI_COMMIT_SHA {
  default = "latest"
}

variable REGISTRY {
  default = ""
}

group default {
  targets = ["lanalytics"]
}

target lanalytics {
  context    = "../"
  dockerfile = "./docker/Dockerfile"

  tags = [
    "${REGISTRY}xikolo-lanalytics:${TAG}",
    "${REGISTRY}xikolo-lanalytics:${CI_COMMIT_SHA}",
    "${REGISTRY}xikolo-lanalytics:latest",
  ]

  annotations = [
    "org.opencontainers.image.ref.name=${TAG}",
    "org.opencontainers.image.revision=${CI_COMMIT_SHA}",
    "org.opencontainers.image.title=xikolo-lanalytics",
    "org.opencontainers.image.vendor=Hasso Plattner Institute for Digital Engineering gGmbH",
    "org.opencontainers.image.version=${TAG}",
  ]

  platforms = [
    "linux/amd64"
  ]
}
