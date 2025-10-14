# Build the image

Use `build-image.sh` script provided in this directory.

For NREL employees make sure to pass the `-n` flag to install NREL certs

The script sets up [kas](https://kas.readthedocs.io/en/latest/) in a docker
container and uses the configs from `meta-everest-dev` to generate an image
with everest installed.

It will use A LOT of resources so make sure your Docker settings have the maximum
amount of resources available and close out of other applications that are using
a lot of RAM. You will also need 200-300 GB available on your disk.

# Running everest in a VM with VMWare Fusion

Run the `build-image.sh` script with the `-m` flag set to arm64vm or amd64vm depending
on what architecture you are on. When the image is done building you will see
a `vmdk` file in the `images/generic*` directory. This will be the file you
will use for VMWare Fusion.

Open VMWare Fusion, create a new VM. Select, "Create a custom virtual machine",
"Other Linux 5.x". Then, for the disk, "Use an existing virtual disk" and
"Choose virtual disk". Navigate to the directory with the vmdk file, make sure
to choose the one with the numbers in it's name. Continue and click
"Customize Settings", then choose a name for the VM.

In the settings for the VM, go to "Processors & Memory" and bump up the
memory to at least 2 GB. Go Back, click on "Network Adapter" and change the
setting to "Bridged Networking - Autodetect". Go back, click on "Hard Disk",
"Advanced options" and change the "Bus type" to "SATA", then click "Apply".

Now you can start the VM. You will see a GUI that you can navigate with arrow
keys. Go to "Terminal" and run "ip a". You want to get the ipv4 address
under "eth0". This the address you will use to connect node-red
to the MQTT server.

## Run AC SIL demo

While you're in the terminal run `manager --config /etc/everest/config-sil.yaml`

Return to the Host OS, edit the node red docker compose file in `custom-yocto-build` and change
the MQTT address to the address you found when running `ip a`. Run
`docker compose --file docker-compose.node-red-ac-sil.yml up` to start
node-red. Now you can control the manager in the VM from
<http://127.0.0.1:1880>

