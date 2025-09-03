# Build Environment Setup

This project uses a tool called [kas](https://github.com/siemens/kas)
to build the yocto image. It requires a Linux environment to have a
consistent build. I've tried using Podman/Docker on MacOS, but ran into
some issues with how the image interacts with the file system. I haven't
tested with WSL or Podman/Docker on Windows yet.

To use `kas` without a container, setup your build environment as
described in the [yocto quick build page](https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html)
and install `kas`. [kas install guide](https://kas.readthedocs.io/en/latest/userguide/getting-started.html)

To use `kas` with a container, install Docker/Podman then use the `kas-container` script
in the `kas` repo instead of `kas`.

# Building The Project

Make a workdir

```
mkdir charin-demo
cd charin-demo
```

Clone the repo in the workdir

```
git clone https://github.com/catarial/meta-charin-demo
```

Run kas

```
<path to kas/kas-container> build meta-charin-demo/config.yml
```

# Missing Directory Issue

You might need to create `/usr/include/python3.11` if it doesn't exist
on your system or container. The build doesn't add anything to
that directory, it just fails if it doesn't see it.

# Connecting To WiFi

It is configured by default to connect to a network named 'umwc-wifi' with
password 'umwc\_everest'. To connect to a different network you can
run `wpa_cli` as root and run the commands below.

```
> add_network
0
> set_network 0 ssid "MYSSID"
> set_network 0 psk "passphrase"
> enable_network 0
<2>CTRL-EVENT-CONNECTED - Connection to 00:00:00:00:00:00 completed (reauth) [id=0 id_str=]
> save_config
OK
> quit
```

You could also edit the file `recipes-connectivity/wpa-supplicant/files/umwc-wifi.conf`
before you build to have it connect to a different network by default.

