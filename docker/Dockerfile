# syntax = docker/dockerfile:1.9@sha256:fe40cf4e92cd0c467be2cfc30657a680ae2398318afd50b0c80585784c604f28

FROM docker.io/ruby:3.3.4-slim@sha256:0f5c785e2189ab9ffda522b20c0380dbc51d9991361f9e0bfbcf46bb68d32b29 AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production

RUN mkdir --parents /app/
WORKDIR /app/

# Install dependencies for installing gems
RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet install \
    build-essential \
    git \
    libcurl4 \
    libffi-dev \
    libidn11-dev \
    libpq-dev \
    libsodium23 \
    pax-utils \
    shared-mime-info \
    tzdata
EOF

COPY Gemfile* /app/

RUN <<EOF
  gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
  bundle config set --local without 'development test integration'
  bundle install --jobs 4 --retry 3
EOF

# Scan gem files for linked native libaries, lookup the packages they
# are shipped with, and colled it list into a file so that only required
# packages can be installed in the runtime image below.
RUN <<EOF
  scanelf --recursive --needed --nobanner --format '%n#p' /usr/local/bundle/ \
    | tr ',' '\n' \
    | sort -u \
    | grep -v libruby.so* \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | tee /usr/local/bundle/packages
EOF

# Copy rest of the application (see .dockerignore too)
COPY . /app/

# Cleanup application directory
RUN <<EOF
  rm -r ./docker
EOF


#
# Runtime image
#
FROM docker.io/ruby:3.3.4-slim@sha256:0f5c785e2189ab9ffda522b20c0380dbc51d9991361f9e0bfbcf46bb68d32b29

ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BRAND=${BRAND}
ENV MALLOC_ARENA_MAX=2
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=1

RUN mkdir --parents /app/
WORKDIR /app/

# Add system user for running the app
RUN useradd --create-home --shell /bin/bash xikolo

# Install extra dependencies for runtime environment
RUN <<EOF
  apt-get --yes --quiet update
  apt-get --yes --quiet --no-install-recommends install \
    curl \
    git \
    libcurl4 \
    libsodium23 \
    nginx \
    shared-mime-info \
    tzdata \
    xz-utils
EOF

COPY docker/rootfs/ /
COPY docker/bin/ /docker/bin
RUN /docker/bin/install-s6-overlay

# Copy installed gems and config from `build` stage above
COPY --from=build /usr/local/bundle /usr/local/bundle

# Install required runtime packages for native dependencies
RUN <<EOF
  xargs apt-get install --yes < /usr/local/bundle/packages
EOF

# Copy application files from build stage
COPY --from=build /app/ /app/

EXPOSE 80/tcp

CMD [ "server" ]
ENTRYPOINT [ "/init", "with-contenv", "/app/bin/entrypoint" ]
