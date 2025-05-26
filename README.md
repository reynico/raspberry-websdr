# WebSDR node based on a Raspberry PI

Leer en [Inglés](README.md), [Español](README.es.md).
Read in [English](README.md), [Spanish](README.es.md).

![SDR receiver working on 40m band](https://github.com/reynico/raspberry-websdr/raw/master/sdr-40m.jpg)

- [WebSDR node based on a Raspberry PI](#websdr-node-based-on-a-raspberry-pi)
  - [General hardware requirements](#general-hardware-requirements)
  - [Running on a Raspberry PI 4 or newer?](#running-on-a-raspberry-pi-4-or-newer)
  - [Required setup and software](#required-setup-and-software)
  - [Clone this repository](#clone-this-repository)
  - [Missing libraries](#missing-libraries)
    - [libpng12](#libpng12)
    - [libssl-1.0.0](#libssl-100)
  - [RTL SDR direct sampling (500khz - 28.8Mhz without upconverter!)](#rtl-sdr-direct-sampling-500khz---288mhz-without-upconverter)
  - [Install WebSDR](#install-websdr)
  - [Single band WebSDR](#single-band-websdr)
  - [Time-controlled, dual band WebSDR](#time-controlled-dual-band-websdr)
    - [Antenna controller](#antenna-controller)
    - [Enable WebSDR for dual band operation](#enable-websdr-for-dual-band-operation)
    - [Cron](#cron)
    - [Manual control](#manual-control)
    - [GPIO Setup](#gpio-setup)
  - [Software reset](#software-reset)
  - [Blacklist RTL modules](#blacklist-rtl-modules)
  - [SD Card wear](#sd-card-wear)

This WebSDR setup covers a dual band receiver (80/40 meters bands) time-based switched. It uses a relay to switch between antennas who is managed by one GPiO pin on the Raspberry PI (using a driver transistor).

Very special thanks to Pieter PA3FWM, Mark G4FPH and Jarek SQ9NFI for the helpful hand on configuring the progfreq setting.

## General hardware requirements

- Raspberry PI 3 or greater.
- [Raspberry Pi OS (Legacy) installed](https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2024-03-12/2024-03-12-raspios-bullseye-armhf-lite.img.xz) and working.
- Internet access setup and working
- RTL-SDR USB Dongle

## Running on a Raspberry PI 4 or newer?

Raspberry PI 4 or newer runs on a different (but similar) architecture than older hardware like the PI 3. Since `websdr-rpi` is not fully compatible with this newer arch (mostly due to outdated dependencies) you may face some of these errors:

```
websdr-rpi: cannot execute: required file not found
```

or

```
websdr-rpi: error while loading shared libraries: libfftw3f.so.3
```

Some of the steps listed below have specific instructions for setting up a newer Raspberry PI hardware and overcome these issues.

## Required setup and software

```bash
sudo apt update && sudo apt upgrade
sudo apt install -y \
  g++ \
  make \
  libsigc++-2.0-dev \
  libgsm1-dev \
  libpopt-dev \
  tcl8.6-dev \
  libgcrypt-dev \
  libspeex-dev \
  libasound2-dev \
  alsa-utils \
  libsigc++-2.0-0v5 \
  cmake \
  groff \
  rtl-sdr \
  libusb-1.0-0-dev \
  unzip \
  git \
  rsync
```

If you are running a Raspberry PI 4 or newer (arm64 architecture) install the `armhf` arch:

```bash
sudo dpkg --add-architecture armhf
sudo apt install -y \
  libsigc++-2.0-dev:armhf \
  libgsm1-dev:armhf \
  libpopt-dev:armhf \
  tcl8.6-dev:armhf \
  libgcrypt-dev:armhf \
  libspeex-dev:armhf \
  libasound2-dev:armhf \
  libsigc++-2.0-0v5:armhf \
  libusb-1.0-0-dev:armhf \
  libc6:armhf \
  zlib1g-dev:armhf
```

## Clone this repository

```
cd /home/pi/
git clone https://github.com/reynico/raspberry-websdr.git
cd raspberry-websdr/
```

## Missing libraries

Over the time, some required libraries were deprecated in favor of newer and incompatible versions.

### libpng12

If you're running a Raspberry PI 4 or newer (arm64 architecture), compile `libpng` like this:

```bash
sudo apt install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf

tar xf libpng-1.2.59.tar.xz
cd libpng-1.2.59/
CC=arm-linux-gnueabihf-gcc \
CXX=arm-linux-gnueabihf-g++ \
./configure \
  --host=arm-linux-gnueabihf \
  --prefix=/usr/local \
  --libdir=/usr/local/lib/arm-linux-gnueabihf

make
sudo make install
sudo ldconfig
sudo ln -s /usr/local/lib/arm-linux-gnueabihf/libpng12.so.0 /lib/arm-linux-gnueabihf/libpng12.so.0
cd..

```


If you're running a Raspberry PI older than a PI4, compile it this way:

```bash
tar xf libpng-1.2.59.tar.xz
cd libpng-1.2.59/
./configure
make
sudo make install
cd ..
```

### libssl-1.0.0

If you're running a Raspberry PI 4 or newer (arm64 architecture), compile `libssl` like this:

```bash
cd openssl-1.0.0k/

CC=arm-linux-gnueabihf-gcc ./Configure linux-armv4 shared \
  --prefix=/usr/local/arm32 \
  --openssldir=/usr/local/arm32/ssl \
  -Wl,--version-script=openssl.ld \
  -Wl,-Bsymbolic-functions

make
sudo make install_sw

sudo ln -s /usr/local/arm32/lib/libcrypto.so.1.0.0 /usr/lib/arm-linux-gnueabihf/libcrypto.so.1.0.0
sudo ln -s /usr/local/arm32/lib/libssl.so.1.0.0 /usr/lib/arm-linux-gnueabihf/libssl.so.1.0.0

sudo ldconfig
```


If you're running a Raspberry PI older than a PI4, compile it this way:

```bash
tar xf openssl-1.0.0k.tar.gz
cd openssl-1.0.0k/
cat << EOF > openssl.ld
OPENSSL_1.0.0 {
    global:
    *;
};
EOF
./config shared --prefix=$HOME/libssl/openssl --openssldir=$HOME/libssl/ssl -Wl,--version-script=openssl.ld -Wl,-Bsymbolic-functions
make
sudo make install_sw
sudo ldconfig
ldd $HOME/libssl/openssl/bin/openssl
sudo cp $HOME/libssl/openssl/lib/libcrypto.so /usr/local/lib
sudo chmod 0755 /usr/local/lib/libcrypto.so
sudo ldconfig
cd ..
```

## RTL SDR direct sampling (500khz - 28.8Mhz without upconverter!)

If your SDR dongle supports direct sampling (such as RTL-SDR.com V3 receiver), there's a way to receive 500khz-28.8mhz without an external upconverter hardware, easing the node build.

```bash
unzip rtl-sdr-driver-patched.zip
cd pkg-rtl-sdr/
mkdir -p build/
cd build/
cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON
make
sudo make install
sudo ldconfig
cd ../../
cp -r pkg-rtl-sdr/ /home/pi/
cd ..
```

Don't forget to remove the `progfreq` line from the websdr configuration file(s).

Use the following systemd unit for direct sampling:

```bash
sudo cp etc/systemd/system/rtl_tcp_direct_sampling.service /etc/systemd/system/rtl_tcp@.service
```

## Install WebSDR

- This is a good time to reboot your Raspberry PI, do a `sudo reboot`.
- Ask [Pieter](http://websdr.org/) to get a copy of WebSDR.
- Copy the websdr-rpi binary and files to your home directory (/home/pi/)
- Edit websdr.cfg (for single band use), or websdr-80m.cfg and websdr-40m.cfg (for dual band use) to fulfill your configuration
- Create Systemd units to manage websdr and rtl_tcp

```bash
sudo cp etc/systemd/system/websdr@.service /etc/systemd/system/websdr@.service
```

Copy this systemd unit only if you're NOT using the RTL SDR direct sampling method

```bash
sudo cp etc/systemd/system/rtl_tcp@.service /etc/systemd/system/rtl_tcp@.service
```

## Single band WebSDR

The setup described in this section is the most usual: a single band SDR receiver (say, 40m band).

- Create systemd units to manage `websdr` and `rtl_tcp`:

```bash
sudo cp etc/systemd/system/websdr.service /etc/systemd/system/websdr.service
```

- Enable the `rtl_tcp` systemd unit:

```bash
sudo systemctl enable rtl_tcp@0.service
```

- Enable the `websdr` unit:

```bash
sudo systemctl enable websdr.service
```

## Time-controlled, dual band WebSDR

The setup described in this section is a more powerful one, where the Raspberry PI switches the WebSDR bands according to the time you define in `crontab`.

### Antenna controller

This WebSDR setup uses one RTL-SDR dongle for two bands (40/80 meters), crontab takes control of which band is working. As wave length isn't the same on both two bands, I'm using a GPiO port to switch between them using a DPDT relay. GPIO3 is controlled by the check_band.sh cron script.
![Antenna controller schematic](https://github.com/reynico/raspberry-websdr/raw/master/gpio_antenna_control_npn.png)

### Enable WebSDR for dual band operation

- Enable just the `rtl_tcp` systemd unit. Websdr is managed by crontab

```bash
sudo systemctl enable rtl_tcp@0.service
```

### Cron

- I built a crontab configuration to switch between 40m and 80m bands time-based. Just import the crontab lines into your crontab.

### Manual control

You can always control band changes manual way. Disable cron lines to avoid automatic setup changes. Then you can use

```bash
sudo systemctl stop websdr@40.service
sudo systemctl start websdr@40.service
```

Where 40 is the band you want to receive. You can use and setup almost any band you want, as long as you had setup your websdr-{{band}}m.cfg

### GPIO Setup

- Copy the etc/rc.local file to your /etc/rc.local

```bash
sudo cp etc/rc.local /etc/rc.local
```

- Check and match GPIO ports for relay control to switch antennas and a button to soft reset the Raspberry pi.

## Software reset

- There is a Python script that handles Raspberry PI reboots from a hardware switch without killing power.
- Check the /etc/rc.local file and match the desired GPIO port for this task.
- Copy etc/systemd/system/reset.service to /etc/systemd/system/reset.service

```bash
sudo cp opt/reset.py /opt/reset.py
sudo cp etc/systemd/system/reset.service /etc/systemd/system/reset.service
sudo chmod 644 /etc/systemd/system/reset.service
sudo systemctl enable reset.service
sudo systemctl start reset.service
```

This is the software reset schematic. It has a 5v pull-up signal between a 10k resistor.
![Soft reset](https://github.com/reynico/raspberry-websdr/raw/master/gpio_soft_reset.png)

## Blacklist RTL modules

You'll need to blacklist some modules in order to get rtl_tcp working. Edit or create the file `/etc/modprobe.d/blacklist.conf` with the following content:

```bash
blacklist dvb_usb_rtl28xxu
```


## SD Card wear

To reduce the SD Card wear due to writes from logs, I recommend you to install [log2ram](https://github.com/azlux/log2ram), a tool which creates a ramdisk mountpoint for `/var/log`.

```bash
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
sudo apt update
sudo apt install log2ram

sudo systemctl enable log2ram
```

You may want to increase the ramdisk partition size up to 200M, edit the file `/etc/log2ram.conf` and set `SIZE=200M`.

While Websdr has an option to prevent logs to be written to the card (`logfileinterval 0`), there are two log files that are written anyway: `log-cpuload.txt` and `userslog.txt`. Create a logs folder inside `/var/log` and link both files in a symbolic fashion.

```bash
sudo rm /home/pi/dist11/userslog.txt
sudo rm /home/pi/dist11/log-cpuload.txt
sudo mkdir -p /var/log/websdr
ln -s /var/log/websdr/userslog.txt /home/pi/dist11/userslog.txt
ln -s /var/log/websdr/log-cpuload.txt /home/pi/dist11/log-cpuload.txt
```
