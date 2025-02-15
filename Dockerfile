# Use official Ruby image
FROM ruby:3.3

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --system

COPY . ./

EXPOSE 9292

ENTRYPOINT ["bundle", "exec"]
CMD ["foreman", "start"]
