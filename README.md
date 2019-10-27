# WebSDR node based on a Raspberry PI
Leer en [Inglés](README.md), [Español](README.es.md).
Read in [English](README.md), [Spanish](README.es.md).

![SDR receiver working on 40m band](https://github.com/reynico/raspberry-websdr/raw/master/sdr-40m.jpg)


- [WebSDR node based on a Raspberry PI](#websdr-node-based-on-a-raspberry-pi)
    - [Requirements](#requirements)
    - [Required setup and software](#required-setup-and-software)
    - [GPIO Setup](#gpio-setup)
    - [Software reset](#software-reset)
    - [Antenna controller](#antenna-controller)
    - [WebSDR](#websdr)
    - [Cron](#cron)
    - [Manual control](#manual-control)
    - [How to fix the LibSSL issue](#how-to-fix-the-libssl-issue)
    - [RTL SDR direct sampling (500khz - 28.8Mhz without upconverter!)](#rtl-sdr-direct-sampling-500khz---288mhz-without-upconverter)

This WebSDR setup covers a dual band receiver (80/40 meters bands) time-based switched. It uses a relay to switch between antennas who is managed by one GPiO pin on the Raspberry PI (using a driver transistor). 

Very special thanks to Pieter PA3FWM, Mark G4FPH and Jarek SQ9NFI for the helpful hand on configuring the progfreq setting.

### Requirements
- Raspberry PI 3
- Raspbian 9 installed and working
- Internet access setup and working
- RTL-SDR USB Dongle

### Required setup and software
```
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install g++ make libsigc++-1.2-dev libgsm1-dev libpopt-dev tcl8.5-dev libgcrypt-dev libspeex-dev libasound2-dev alsa-utils libqt4-dev
sudo apt-get install libsigc++ cmake groff rtl-sdr
```

### GPIO Setup
- Copy the etc/rc.local file to your /etc/rc.local
```
sudo cp etc/rc.local /etc/rc.local
```
- Check and match GPIO ports for relay control to switch antennas and a button to soft reset the Raspberry pi.

### Software reset
- There is a Python script that handles Raspberry PI reboots from a hardware switch without killing power.
- Check the /etc/rc.local file and match the desired GPIO port for this task.
- Copy lib/systemd/system/reset.service to /lib/systemd/system/reset.service
```
sudo cp opt/reset.py /opt/reset.py
sudo cp etc/systemd/system/reset.service to /etc/systemd/system/reset.service
chmod 644 /lib/systemd/system/reset.service
systemctl enable reset.service
systemctl start reset.service
```
This is the software reset schematic. It has a 5v pull-up signal between a 10k resistor.
![Soft reset](https://github.com/reynico/raspberry-websdr/raw/master/gpio_soft_reset.png)

### Antenna controller
This WebSDR setup uses one RTL-SDR dongle for two bands (40/80 meters), crontab takes control of which band is working. As wave length isn't the same on both two bands, I'm using a GPiO port to switch between them using a DPDT relay. GPIO3 is controlled by the check_band.sh cron script.
![Antenna controller schematic](https://github.com/reynico/raspberry-websdr/raw/master/gpio_antenna_control_npn.png)

### WebSDR
- Ask [Pieter](http://websdr.org/) to get a copy of WebSDR.
- Copy the websdr-rpi binary and files to your home directory (/home/pi/)
- Edit websdr-80m.cfg and websdr-40m.cfg to fulfill your configuration
- Create Systemd units to manage websdr and rtl_tcp
```
sudo cp etc/systemd/system/websdr@.service /etc/systemd/system/websdr@.service
sudo cp etc/systemd/system/rtl_tcp@.service /etc/systemd/system/rtl_tcp@.service
```
- Enable just the rtl_tcp one. Websdr is managed by crontab
```
sudo systemctl enable rtl_tcp@0.service
```

### Cron
- I built a crontab configuration to switch between 40m and 80m bands time-based. Just import the crontab lines into your crontab.

### Manual control
You can always control band changes manual way. Disable cron lines to avoid automatic setup changes. Then you can use
```
sudo systemctl stop websdr@40.service
sudo systemctl start websdr@40.service
```
Where 40 is the band you want to receive. You can use and setup almost any band you want, as long as you had setup your websdr-{{band}}m.cfg

### How to fix the LibSSL issue
I've noticed several websdr nodes that fails to start `websdr-rpi` using Raspbian. That's due a missing library called `libcrypto`. 
```
pi@raspberrypi:~/dist11 $ ./websdr-rpi websdr-40m.cfg
./websdr-rpi: error while loading shared libraries: libcrypto.so.1.0.0: cannot open shared object file: No such file or directory
```
Fix is really easy:
`sudo dpkg -i libssl1.0.0_1.0.1t-1+deb8u11_armhf.deb`

### RTL SDR direct sampling (500khz - 28.8Mhz without upconverter!)
If your SDR dongle supports direct sampling (such as RTL-SDR.com V3 receiver), there's a way to receive 500khz-28.8mhz without an external upconverter hardware, easing the node build. Install cmake first!
1. Unzip [rtl-sdr-driver-patched.zip](rtl-sdr-driver-patched.zip) and prepare the environment to build
   1. `unzip rtl-sdr-driver-patched.zip`
   2. `cd pkg-rtl-sdr/build`
   3. `rm *`
2. Build it
   1. `cmake ../ -DINSTALL_UDEV_RULES=ON`
   2. `make`
   3. `sudo make install`
   4. `sudo ldconfig`

Once finished, configure `rtl_tcp` to use direct sampling mode with the `-D 2` switch as follows:
* `/usr/bin/rtl_tcp -s1024000 -g10 -d0 -p9990 -D2`
Don't forget to remove the `progfreq` line from the websdr configuration file(s).
