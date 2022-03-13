FROM ruby:latest
RUN gem install prometheus-splash
RUN splash conf set
EXPOSE 9234
CMD ["splash","web", "start" ,"-F"]