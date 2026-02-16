FROM raspbian/stretch:latest

# copy everest binaries
COPY everest.zip /everest.zip

# add legacy sources
RUN rm /etc/apt/sources.list
COPY sources.list /etc/apt/sources.list

# install dependencies
RUN apt-get update && apt-get install zip -y

# unzip everest binaries into the recommended directory
RUN mkdir -p /mnt/user_data/opt/
RUN unzip everest.zip -d /mnt/user_data/opt/
RUN rm everest.zip

ENTRYPOINT ["/bin/sh"]