# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
#FROM phusion/passenger-full:0.9.15
# Or, instead of the 'full' variant, use one of these:
#FROM phusion/passenger-ruby19:<VERSION>
#FROM phusion/passenger-ruby20:<VERSION>
#FROM phusion/passenger-ruby21:<VERSION>
#FROM phusion/passenger-ruby22:<VERSION>
#FROM phusion/passenger-jruby17:<VERSION>
#FROM phusion/passenger-nodejs:<VERSION>
FROM phusion/passenger-customizable:0.9.15

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# If you're using the 'customizable' variant, you need to explicitly opt-in
# for features. Uncomment the features you want:
#
#   Build system and git.
RUN /pd_build/utilities.sh
#   Ruby support.
#RUN /pd_build/ruby1.9.sh
#RUN /pd_build/ruby2.0.sh
#RUN /pd_build/ruby2.1.sh
#RUN /pd_build/ruby2.2.sh
#RUN /pd_build/jruby1.7.sh
#   Python support.
RUN /pd_build/python.sh
#   Node.js and Meteor support.
#RUN /pd_build/nodejs.sh

# ...put your own build instructions here...
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python get-pip.py
RUN pip install azure
RUN git clone https://github.com/chanezon/azure-linux.git

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
