FROM ruby:2.7.6-slim as bundle

RUN apt-get update -qq && \
apt-get install -y nano build-essential libpq-dev curl wget && \
gem install bundler

RUN apt-get update \
&& apt-get -qq -y install libsqlite3-dev libmagickwand-dev imagemagick yarn

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
        && apt-get install -y nodejs

#gcloud
ENV CLOUD_SDK_REPO "cloud-sdk-$(lsb_release -c -s)"
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-bionic main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl -sL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update && apt-get -qq -y install google-cloud-sdk

RUN mkdir /app

COPY Gemfile* ./
WORKDIR /app
ENV RAILS_ENV=production RACK_ENV=production

RUN bundle install
COPY . /app

RUN rails assets:precompile

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]