# This dockerfile should be user for development purposes only.
# Alpine docker images are smaller, using alpine linux
FROM ruby:2.5.7-alpine
# Linux dependencies
RUN apk add --no-cache --update build-base openssl tar bash linux-headers git \
  postgresql postgresql-dev tzdata nodejs postgresql-client less imagemagick

# Copying gemfile and installing gems
RUN mkdir /myapp
WORKDIR /myapp
COPY Gemfile .
COPY Gemfile.lock .

RUN gem install bundler -v 2.0.2
ENV BUNDLER_VERSION=2.0.2

RUN bundle install --jobs `expr $(cat /proc/cpuinfo | grep -c "cpu cores") - 1` --retry 3

#### COMMENT THESE LINES IF YOU DON'T USE WEBPACKER (any app made before 2019.2) ###
# Copying webpack files and installing dependencies. Need only for apps with webpack.
# COPY package.json .
# COPY yarn.lock .
# RUN yarn
# Must rebuild node sass, the linux binary is incompatible with alpine linux binary
# RUN npm rebuild node-sass

# Copying the entire app
COPY . .

# Add a script to be executed every time the container starts, that erases the tmp/pids/server.pid file
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# rails server
EXPOSE 3000
# yarn server
# EXPOSE 3001
# for vscode debug
# EXPOSE 1234
# EXPOSE 26162

# Start the main process
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
