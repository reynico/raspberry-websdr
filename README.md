# WebSDR node based on a Raspberry PI
![SDR receiver working on 40m band](https://github.com/reynico/raspberry-websdr/raw/master/sdr-40m.jpg)

This WebSDR setup covers a dual band receiver (80/40 meters bands) time-based switched. It uses a relay to switch between antennas who is managed by one GPiO pin on the Raspberry PI (using a driver transistor). 

Very special thanks to Mark G4FPH and Jarek SQ9NFI for the helpful hand on configuring the progfreq setting.

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

### Antenna controller
This WebSDR setup uses one RTL-SDR dongle for two bands (40/80 meters), crontab takes control of which band is working. As wave length isn't the same on both two bands, I'm using a GPiO port to switch between them using a DPDT relay. GPIO3 is controlled by the check_band.sh cron script.
![Antenna controller schematic](https://github.com/reynico/raspberry-websdr/raw/master/gpio_antenna_control.png)

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
