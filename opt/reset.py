#!/usr/bin/env python
import os
import time
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(2,GPIO.IN)

while True:
  input = GPIO.input(2)
  if not input:
    print("RESET!!")
    os.system("reboot")
  time.sleep(1)
