# Nodo WebSDR utilizando un Raspberry PI

Leer en [Inglés](README.md), [Español](README.es.md)
Read in [English](README.md), [Español](README.es.md)

![Receptor SDR funcionando en la banda de 40 metros](https://github.com/reynico/raspberry-websdr/raw/master/sdr-40m.jpg)

- [Nodo WebSDR utilizando un Raspberry PI](#nodo-websdr-utilizando-un-raspberry-pi)
  - [Requerimientos de hardware](#requerimientos-de-hardware)
  - [Estás usando una Raspberry PI 4 o mas nueva?](#estás-usando-una-raspberry-pi-4-o-mas-nueva)
  - [Configuración y software requerido](#configuración-y-software-requerido)
  - [Clonar este repositorio](#clonar-este-repositorio)
  - [Librerias faltantes](#librerias-faltantes)
    - [libpng12](#libpng12)
    - [libssl-1.0.0](#libssl-100)
  - [Direct sampling en RTL SDR (500KHz - 28.8MHz sin upconverter!)](#direct-sampling-en-rtl-sdr-500khz---288mhz-sin-upconverter)
  - [Instalar WebSDR](#instalar-websdr)
  - [WebSDR de una sola banda](#websdr-de-una-sola-banda)
  - [WebSDR multi banda controlado por tiempo](#websdr-multi-banda-controlado-por-tiempo)
    - [Controlador de antena](#controlador-de-antena)
    - [Habilitar WebSDR doble banda](#habilitar-websdr-doble-banda)
    - [Cron](#cron)
    - [Control manual](#control-manual)
    - [Configuración de los pines GPIO](#configuración-de-los-pines-gpio)
  - [Reinicio por software](#reinicio-por-software)
  - [Blacklist de los modulos RTL](#blacklist-de-los-modulos-rtl)
  - [Desgaste de la tarjeta SD](#desgaste-de-la-tarjeta-sd)

Esta guía cubre la configuración de un receptor de doble banda (80/40 metros) basada en forma horaria. Usa un relay para intercambiar entre antenas, controlado por un puerto GPiO del Raspberry PI (utilizando un transistor como driver).

Muchas gracias a Pieter PA3FWM, Mark GP4FPH y Jarek SQ9NFI por la gran mano configurando el parámetro progfreq.req setting.

## Requerimientos de hardware

- Raspberry PI 3 o superior
- [Raspberry Pi OS (Legacy) instalado](https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2024-03-12/2024-03-12-raspios-bullseye-armhf-lite.img.xz) y funcionando.
- Acceso a internet configurado y funcionando
- Receptor RTL-SDR USB

## Estás usando una Raspberry PI 4 o mas nueva?

A partir de la Raspberry PI 4, el hardware corre en una arquitectura diferente (pero similar) al hardware viejo. `websdr-rpi` no es completamente compatible con esta nueva arquitectura, mas que nada por dependencias desactualizadas y por lo tanto puede que te encuentres con algunos de estos errores:

```
websdr-rpi: cannot execute: required file not found
```

or

```
websdr-rpi: error while loading shared libraries: libfftw3f.so.3
```

Algunos de los pasos listados aquí abajo tienen instrucciones específicas para configurar una Raspberry PI 4 con hardware moderno y solucionar estos problemas.

## Configuración y software requerido

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

Si estás usando una Rapberry PI 4 o mas nueva (con arquitectura arm64), instalá la arquitectura `armhf`:

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

## Clonar este repositorio

```
cd /home/pi/
git clone https://github.com/reynico/raspberry-websdr.git
cd raspberry-websdr/
```

## Librerias faltantes

Con las últimas actualizaciones, algunas librerias requeridas por websdr fueron deprecadas haciéndolas incompatibles.

### libpng12

Si estás usando una Rapberry PI 4 o mas nueva (con arquitectura arm64), compilá `libpng` de esta manera:

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

Si estás usando una Raspberry anterior a una PI 4, usá este comando:

```bash
tar xf libpng-1.2.59.tar.xz
cd libpng-1.2.59/
./configure
make
sudo make install
cd ..
```

### libssl-1.0.0

Si estás usando una Rapberry PI 4 o mas nueva (con arquitectura arm64), compilá `libssl` de esta manera:

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


Si estás usando una Raspberry anterior a una PI 4, usá este comando:

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

## Direct sampling en RTL SDR (500KHz - 28.8MHz sin upconverter!)

Si estás usando un receptor RTL-SDR.com V4, necesitás una versión especial del driver `rtl-sdr` para poder recibir 500KHz-28.8MHz

```bash
git clone https://github.com/rtlsdrblog/rtl-sdr-blog
cd rtl-sdr-blog/
mkdir build
cd build
cmake ../ -DINSTALL_UDEV_RULES=ON
make
sudo make install
sudo cp ../rtl-sdr.rules /etc/udev/rules.d/
sudo ldconfig
```

If you are running a different SDR device, but if it supports direct sampling (such as RTL-SDR.com V3 receiver), there's a way to receive 500KHz-28.8MHz without an external upconverter hardware, easing the node build.

Si estás usando un receptor SDR diferente, pero que soporta direct sampling (como el RTL-SDR.com v3), hay una manera de recibir las frecuencias entre 500KHz y 28.8MHz sin necesidad de un upconverter externo, facilitando la construcción del nodo.

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

No olvides eliminar o comentar la linea `progfreq` de el(los) archivo(s) de configuración de websdr.

Use the following systemd unit for direct sampling:

```bash
sudo cp etc/systemd/system/rtl_tcp_direct_sampling.service /etc/systemd/system/rtl_tcp@.service
```

## Instalar WebSDR

- Este es un buen momento para reiniciar la Raspberry PI, ejecutar `sudo reboot`.
- Enviale un email a [Pieter](http://websdr.org/) para obtener una copia de WebSDR.
- Copia el binario websdr-rpi y los archivos de configuración a tu directorio personal (/home/pi/)
- Edita websdr-80m.cfg y websdr-40m.cfg para ajustarlo a tu configuración
- Crea dos Systemd units para controlar websdr y rtl_tcp

```bash
sudo cp etc/systemd/system/websdr@.service /etc/systemd/system/websdr@.service
```

Copia este archivo solo si NO estás usando el modo direct sampling de tu RTL SDR. Los receptores RTL-SDR.com V4 no necesitan la configuración especial de [Direct Sampling](#rtl-sdr-direct-sampling-500khz---288mhz-without-upconverter) para funcionar.

```bash
sudo cp etc/systemd/system/rtl_tcp@.service /etc/systemd/system/rtl_tcp@.service
```

## WebSDR de una sola banda

El setup descripto en esta sección es el mas común: un receptor SDR de una sola banda, por ejemplo de 40 metros.

- Crea las systemd units para controlar `websdr` y `rtl_tcp`:

```bash
sudo cp etc/systemd/system/websdr.service /etc/systemd/system/websdr.service
sudo cp etc/systemd/system/rtl_tcp@.service /etc/systemd/system/rtl_tcp@.service
```

- Habilita la systemd unit `rtl_tcp`:

```bash
sudo systemctl enable rtl_tcp@0.service
```

- Habilita la systemd unit `websdr`:

```bash
sudo systemctl enable websdr.service
```

## WebSDR multi banda controlado por tiempo

El Setup descripto en esta sección es mas poderoso: donde la Raspberry PI cambia la banda de recepción de WebSDR de acuerdo a los horarios definidos en `crontab`.

### Controlador de antena

Esta configuración de WebSDR utiliza un solo receptor RTL-SDR para dos bandas (40/80 metros), crontab toma el control de que banda está funcionando. Así como la longitud de onda no es la misma para las dos bandas, estoy utilizando un pin GPiO para intercambiar entre ellas usando un relé doble polo doble inversor. El pin GPiO3 es controlado por el script check_band.sh
![Circuito esquemático del control de antena](https://github.com/reynico/raspberry-websdr/raw/master/gpio_antenna_control_npn.png)

### Habilitar WebSDR doble banda

- Hablita solo la systemd unit `rtl_tcp`. Websdr es controlado por `crontab`.

```bash
sudo systemctl enable rtl_tcp@0.service
```

### Cron

- Fabriqué una configuración de crontabl para intercambiar entre las bandas de 40 y 80 metros basada en horarios. Sólo importa las lineas del archivo crontab en tu crontab.

### Control manual

Siempre podrás controlar el cambio de bandas de forma manual. Deshabilita las lineas de cron para evitar cambios automáticos. Luego puedes usar:

```bash
sudo systemctl stop websdr@40.service
sudo systemctl start websdr@40.service
```

Donde 40 es la banda que quieres recibir. Puedes usar y configurar prácticamente cualquier banda que quieras, siempre y cuando hayas configurado tu archivo websdr-{{banda}}m.cfg

### Configuración de los pines GPIO

- Copia el archivo etc/rc.local a tu /etc/rc.local

```bash
sudo cp etc/rc.local /etc/rc.local
```

- Controla y revisa el número de puerto GPiO para el control de antenas y el botón de reinicio por software.

## Reinicio por software

- Hay un script en Python que controla el reinicio de la Raspberry PI a través de un switch de hardware, sin necesidad de quitarle la energía eléctrica.
- Revisa el archivo /etc/rc.local y sincroniza el pin GPiO designado para esta aplicación.
- Copia el archivo etc/systemd/system/reset.service a /etc/systemd/system/reset.service

```bash
sudo cp opt/reset.py /opt/reset.py
sudo cp etc/systemd/system/reset.service /etc/systemd/system/reset.service
sudo chmod 644 /etc/systemd/system/reset.service
sudo systemctl enable reset.service
sudo systemctl start reset.service
```

Éste es el circuito esquemático del reinicio por software. Tiene una señal de pull-up a 5v a través de una resistencia de 10k.
![Soft reset](https://github.com/reynico/raspberry-websdr/raw/master/gpio_soft_reset.png)

## Blacklist de los modulos RTL

Tendrás que hacer blacklist (bloquear) algunos modulos para conseguir que rtl_tcp funcione. Edita o crea el archivo `/etc/modprobe.d/blacklist.conf` con el siguiente contenido:

```bash
blacklist dvb_usb_rtl28xxu
```


## Desgaste de la tarjeta SD

Para reducir el desgaste de la tarjeta SD por las escrituras a disco de los logs, recomiendo instalar [log2ram](https://github.com/azlux/log2ram), una herramienta que crea un punto de montaje en ram para `/var/log`.

```bash
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
sudo apt update
sudo apt install log2ram

sudo systemctl enable log2ram
```

Probablemente quieras aumentar el tamaño de la partición de logs a 200M, edita el archivo `/etc/log2ram.conf` y configura `SIZE=200M`.

Si bien Websdr tiene una opción para prevenir que los logs se escriban a la tarjeta (`logfileinterval 0`), hay dos archivos de log que se escriben de todas formas: `log-cpuload.txt` y `userslog.txt`. Crea un directorio para logs dentro de `/var/log` y enlaza de forma simbólica para los dos archivos.

```bash
sudo rm /home/pi/dist11/userslog.txt
sudo rm /home/pi/dist11/log-cpuload.txt
sudo mkdir -p /var/log/websdr
ln -s /var/log/websdr/userslog.txt /home/pi/dist11/userslog.txt
ln -s /var/log/websdr/log-cpuload.txt /home/pi/dist11/log-cpuload.txt
```
