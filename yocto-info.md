
# Building a yocto image with everest

We are using [kas](https://github.com/siemens/kas) to build the yocto images inside a container.
We need to build our own image of kas to add a couple things.

```sh
git clone https://github.com/siemens/kas.git
cd kas
git checkout 4.7
```

Then modify the Dockerfile to add the following

```
# Install NREL root certs.
RUN curl -fsSLk -o /usr/local/share/ca-certificates/nrel_root.crt https://raw.github.nrel.gov/TADA/nrel-certs/v20180329/certs/nrel_root.pem && \
  curl -fsSLk -o /usr/local/share/ca-certificates/nrel_xca1.crt https://raw.github.nrel.gov/TADA/nrel-certs/v20180329/certs/nrel_xca1.pem && \
  update-ca-certificates

# suppresses a warning in yocto
RUN mkdir -p /usr/include/python3.11
```

Then build the image

```
docker build -t mykas:4.7 .
```

We need to use a docker volume to store the build results of yocto.

```
docker create volume pokykas
```

Make sure that docker is set to use the maximum amount of RAM available,
it will use a lot.

Start kas

```
docker run -it -v pokykas:/workdir mykas:4.7
```

Change ownership of the workdir to the builder user

```sh
sudo chown -R builder:builder /workdir
```

Now we can start the build process

```sh
cd /workdir
git clone https://github.com/catarial/meta-charin-demo
kas build meta-charin-demo/config.yml
```

The build result will be stored in `/workdir/build/tmp/deploy/images/raspberrypi4`
use docker cp to copy them out.

