FROM ruby:3.2.7-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install essential Linux packages
RUN apt-get update -qq \
 && apt-get install -y \
    build-essential \
    cmake \
    imagemagick \
    libappindicator1 \
    libpq-dev \
    libxss1 \
    memcached \
    pkg-config \
    postgresql-client \
    sudo \
    unzip

# Install Chromium for E2E integration tests
RUN apt-get update -qq && apt-get install -y chromium chromium-driver

# Files created inside the container repect the ownership
RUN adduser --shell /bin/bash --disabled-password --gecos "" consul \
 && adduser consul sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bundle/bin:/usr/local/node/bin"' > /etc/sudoers.d/secure_path
RUN chmod 0440 /etc/sudoers.d/secure_path

# Define where our application will live inside the image
ENV RAILS_ROOT=/var/www/consul

# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids

# Set our working directory inside the image
WORKDIR $RAILS_ROOT

# Install Node
COPY .node-version ./
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build `cat .node-version` /usr/local/node && \
    rm -rf /tmp/node-build-master

# Use the Gemfiles as Docker cache markers. Always bundle before copying app src.
# (the src likely changed and we don't want to invalidate Docker's cache too early)
COPY .ruby-version ./
COPY Gemfile* ./
RUN bundle install

COPY package* ./
RUN npm install

# Copy the Rails application into place
COPY . .

ENTRYPOINT ["./docker-entrypoint.sh"]
# Define the script we want run once the container boots
# Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
# CMD [ "config/containers/app_cmd.sh" ]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
