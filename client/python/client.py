from threading import Thread
import time
from socketIO_client_nexus import SocketIO, LoggingNamespace

import pigpio
pi = pigpio.pi()

import DHT22
sensor = DHT22.sensor(pi, 17)

# import logging
# logging.getLogger('socketIO-client').setLevel(logging.DEBUG)
# logging.basicConfig()

enableLog = True

def on_connect():
	print ('connected to server')

def on_join(*args):
	print (args[0])

def on_emit(*args):
	print ('got ack from server '+ args[0])	

def on_tempControl(*args):
	global enableLog
	enableLog = args[0]

serial = '1'

socketIO = SocketIO('http://192.168.2.12', 4000, LoggingNamespace)
socketIO.on('connect',on_connect)
socketIO.emit('join', serial, on_join)
socketIO.wait(seconds=1)

def thread_TempEmit():
	i = 1
	while 1 : 
		if not enableLog: 
			print('monitoring off')
			time.sleep(5)
			continue
		sensor.trigger()
		time.sleep(3)
		socketIO.emit('logTemp', {
			'serial': '1',
			'time': sensor.temperature()/1.0,
			'data': time.time()
		},on_emit)
		i = i+1
		socketIO.wait(seconds=2)

def thread_Monitoring():
	while 1:
		socketIO.on('tempControl', on_tempControl)
		socketIO.wait(seconds=3)

if __name__ == "__main__":
	_thread_temp = Thread(target= thread_TempEmit)
	_thread_temp.start()
	# _thread_temp.join()

	_thread_mon = Thread(target= thread_Monitoring)
	_thread_mon.start()
	# _thread_mon.join()
	
