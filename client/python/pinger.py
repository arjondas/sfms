from threading import Thread
import RPi.GPIO as GPIO
import sys
from hx711 import HX711
import time
import os
import requests
from socketIO_client_nexus import SocketIO, LoggingNamespace

import pigpio
pi = pigpio.pi()

import DHT22
sensor = DHT22.sensor(pi, 17)

hx = HX711(9,11)
hx.set_reading_format("LSB", "MSB")
hx.set_reference_unit(321)

hx.reset()
hx.tare()

enableLog = False
enableInventry = False

def on_connect():
	print ('connected to server')

def on_join(*args):
	print (args[0])

def on_emit(*args):
	print ('got ack from server '+ args[0])	

def on_tempControl(*args):
	global enableLog
	enableLog = args[0]['monitoring']

def on_inventryControl(*args):
	global enableInventry
	enableInventry = args[0]['monitoring']

def fetch_Image():
	print('sending image from device')
	os.system('fswebcam -r 320x240 --no-banner --save /home/pi/Final/monitor/image.jpg')
	time.sleep(1)
	data = open('image.jpg', 'rb').read()
	encodedData = data.encode("base64")
	socketIO.emit('serverMonitorImage', encodedData)
	socketIO.wait(seconds=3)

def cleanAndExit():
	print ("Cleaning...")
	GPIO.cleanup()
	sys.exit()

serial = '1'
baseURL = 'http://192.168.2.6'
port = 4000
url = baseURL + ':' + str(port) + '/device/self/' + serial
config = requests.get(url)
enableLog = config.json()['temperature']['monitoring']
enableInventry = config.json()['weight']['monitoring']

socketIO = SocketIO(baseURL, port, LoggingNamespace)
socketIO.on('connect',on_connect)
socketIO.emit('join', serial, on_join)
socketIO.wait(seconds=1)
socketIO.on('deviceImageFetch', fetch_Image)
socketIO.wait(seconds=1)

def thread_TempEmit():
	while 1 : 
		if not enableLog: 
			print('monitoring off')
			time.sleep(5)
			continue
		sensor.trigger()
		time.sleep(3)
		socketIO.emit('logTemp', {
			'serial': serial,
			'time': time.time(),
			'data': sensor.temperature()/1.0
		},on_emit)
		socketIO.wait(seconds=2)

def thread_TempMonitor():
	while 1:
		socketIO.on('temp_control_monitor', on_tempControl)
		socketIO.wait(seconds=3)

def thread_InventryMonitor():
	while 1:
		socketIO.on('inventry_control_monitor', on_inventryControl)
		socketIO.wait(seconds=3)

def thread_InventryEmit():
	while 1 :
		if not enableInventry:
			print('inventry monitoring off')
			time.sleep(5)
			continue
		time.sleep(3)
		socketIO.emit('warnInventry', {
			'serial': serial,
			'time': time.time(),
			'data': hx.get_weight(5)
		})
		hx.power_down()
		hx.power_up()
		socketIO.wait(seconds=2)



if __name__ == "__main__":
	_thread_temp = Thread(target= thread_TempEmit)
	_thread_temp.start()

	_thread_tempMon = Thread(target= thread_TempMonitor)
	_thread_tempMon.start()

	_thread_inventry = Thread(target= thread_InventryEmit)
	_thread_inventry.start()

	_thread_inventryMon = Thread(target= thread_InventryMonitor)
	_thread_inventryMon.start()

