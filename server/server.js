require('./config/config');
const {ObjectID} = require('mongodb');
const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
var bodyParser = require('body-parser');
const _ = require('lodash');
var {mongoose} = require('./db/mongoose');
var {Device} = require('./models/device');
var {User} = require('./models/user');
var {authenticate, superAuthenticate} = require('./middleware/authenticate');
var app = express();
var server = http.Server(app);
var io = socketIO(server);
const port = process.env.PORT || 4000;
app.use(bodyParser.json());

//// Device pings every 5 seconds
//// redFlag is number of value warning
const minTimeIntervalBetweenNotifications = 30				/// in seconds
io.on('connection', (socket) => {
	console.log('connected to client');

	socket.on('join', (room, callback) => {
		socket.join(room);
		console.log('socket joined',room);
		callback(`joined service__${room}`);
		var redFlag = 0;
		var redInvFlag = 0;
		var lastTriggerTime = 0;
		var lastInvTriggerTime = 0;
		socket.on('logTemp', (tempData, callback) => {
			console.log(tempData.data)
			Device.logCurrentTemp(tempData).then((device) => {
				// console.log(device);
			}).catch(err => {
				console.log(err);
			})
			Device.surveyTemperatureData(tempData).then((flag) => {
				if(flag) {
					redFlag++;
				} else {
					redFlag = 0;
					Device.getDeviceID(tempData).then((device) => {
						User.logWarning(device._id, false, "temperature")
					}).catch((err) => {
						console.log(err);
						console.log("deviceID query failed");
					});
				}
			}).then(() => {
				const currentTime = Date.now()
				if(redFlag > 4) {							//// Reads atleast 5 warnings before triggering notification
					if(currentTime - lastTriggerTime > (minTimeIntervalBetweenNotifications * 1000)) {
						console.log("****warning temp above limit");
						Device.getDeviceID(tempData).then((device) => {
							User.logWarning(device._id, true, "temperature")
						}).catch((err) => {
							console.log(err);
							console.log("deviceID query failed");
						});
						lastTriggerTime = currentTime;
					} else {
						console.log("*****not now");
					}
					// const currentTime = new Date.now()
					// if(currentTime - lastTriggerTime > minTimeIntervalBetweenNotifications) {
						
					// 	lastTriggerTime = currentTime;
					// } else {
					// 	console.log("****not now");
					// } 
					
				}
			}).catch((flag) => {
				if(flag) {
					redFlag = 0;
					Device.getDeviceID(tempData).then((device) => {
						User.logWarning(device._id, false, "temperature")
					}).catch((err) => {
						console.log(err);
						console.log("deviceID query failed");
					});
					console.log("****cool");
				} else {
					console.log("****not so cool");
				}
			});
			Device.logTemperatureData(tempData).then((msg) => {
				console.log(msg, tempData.data);
				callback(msg);
			}).catch((err) => {
				console.log(err);
				callback(err);
			});
		});

		socket.on('warnInventry', (invData) => {
			console.log(invData.data)
			Device.logCurrentWeight(invData).then((device) => {

			}).catch(err => {
				console.log(err);
			})
			Device.surveyInventryData(invData).then((flag) => {
				if(flag) {
					redInvFlag++;
				} else {
					redInvFlag = 0;
					Device.getDeviceID(invData).then((device) => {
						User.logWarning(device._id, false, "weight")
					}).catch((err) => {
						console.log(err);
						console.log("deviceID query failed");
					});
				}
			}).then(() => {
				const currentTime = Date.now()
				if(redInvFlag > 4) {
					if(currentTime - lastInvTriggerTime > (minTimeIntervalBetweenNotifications * 1000)) {
						console.log("****warning inventry below limit");
						Device.getDeviceID(invData).then((device) => {
							User.logWarning(device._id, true, "weight")
						}).catch((err) => {
							console.log(err);
							console.log("deviceID query failed");
						});
						lastInvTriggerTime = currentTime;
					} else {
						console.log("*****not now");
					}
					
				}
			}).catch((flag) => {
				if(flag) {
					redInvFlag = 0;
					Device.getDeviceID(invData).then((device) => {
						User.logWarning(device._id, false, "weight")
					}).catch((err) => {
						console.log(err);
						console.log("deviceID query failed");
					});
					console.log("****ok inv");
				} else {
					console.log("****not ok inv");
				}
			});
		});

		socket.to(room).on('imageFetch', (data) => {
			socket.to(room).emit('deviceImageFetch');
		});

		socket.to(room).on('serverMonitorImage', (data) => {
			console.log('******emitting fetched data');
			socket.to(room).emit('clientImageFetch', data);
		});

		socket.to(room).on('temp_control_monitor', (data, deviceID) => {
			Device.updateSettings(data, deviceID)
			socket.to(room).broadcast.emit('temp_control_monitor', data);
		});

		socket.to(room).on('temp_control_threshold', (data, deviceID) => {
			Device.updateSettings(data, deviceID)
			socket.to(room).broadcast.emit('temp_control_threshold', data);
		});

		socket.to(room).on('inventry_control_monitor', (data, deviceID) => {
			Device.updateSettings(data, deviceID)
			socket.to(room).broadcast.emit('inventry_control_monitor', data);
		});

		socket.to(room).on('inventry_control_threshold', (data, deviceID) => {
			Device.updateSettings(data, deviceID)
			socket.to(room).broadcast.emit('inventry_control_threshold', data);
		});
		
	});

	socket.on('disconnect', () => {
		console.log('Disconnected from client');
	});
});

app.post('/log', (req, res) => {
	Device.logTemperatureData(req.body).then(() => {
		res.status(200).send();
	}).catch(() => {
		res.status(400).send();
	});
});

/// Add Device to Master Device List, i/p: n/a, payload: {serial: '1234567'}	(Done)	√

app.post('/master', superAuthenticate, (req, res) => {
	var body = _.pick(req.body, ['serial']);
	var device = new Device({
		serial: body.serial
	});

	device.save().then((details) => {
		res.send(details);
	}, err => {
		res.status(400).send(err);
	})
});

/// Add Device to User Device List, i/p: n/a, payload: {serial: '1234567'}	(Done)	√

app.post('/device', authenticate, (req, res) => {
	var body = _.pick(req.body, ['name','serial']);
	Device.findOne({
		serial: body.serial
	}).then((device) => {
		return User.verifyDevice(req.user._id, device._id).then(() => {
			return Promise.resolve();
		}).catch(() => {
			return req.user.addDevice(device._id, body.name).then((devices) => {
				return Promise.resolve(devices);
			}).catch(() => {
				return Promise.reject();
			});
		});
	}).then((devices) => {
		if(!devices) {
			User.findById(req.user._id).then((user) => {
				res.send(user.devices);
			}, err => res.status(405).send(err));
		} else {
			res.send(devices);
		}
	}).catch((err) => {
		res.status(400).send(err);
	});
});

/// Get User Device List, i/p: n/a, payload: n/a	(Done)	√

app.get('/device', authenticate, (req, res) => {
	User.findById(req.user._id).then((user) => {
		res.send(user.devices);
	}, err => res.status(400).send(err));
});

/// Get User Device Details, i/p: deviceID, payload: n/a	(Done)	√
/*
app.get('/device/:id', authenticate, (req, res) => {
	var id = req.params.id;
	if(!ObjectID.isValid(id)) {
		return res.status(404).send();
	}
	User.findOne({
		'devices._deviceID': id
	}).then((device) => {
		if(!device) return res.status(401).send();
		return Device.findOne({_id: id});
	}).then((device) => {
		if(!device) return res.status(404).send();
		res.send({device});
	}).catch(err => res.status(400).send(err));
});
*/

/// Get User Device Details, i/p: deviceID, payload: n/a	(Done)	√

app.get('/device/:id', authenticate, (req, res) => {
	var id = req.params.id;
	User.verifyDevice(req.user._id, id).then(() => {
		return Device.findOne({_id: id});
	}).then((device) => {
		if(!device) return res.status(404).send();
		res.send({device});
	}).catch(err => res.status(err).send());
});

/// Remove Device from User Device List, i/p: deviceID, payload: n/a	(Done)	√

app.delete('/device/:id', authenticate, (req, res) => {
	var id = req.params.id;
	if(!ObjectID.isValid(id)) return res.status(404).send();
	req.user.removeDevice(id).then(() => {
		User.findById(req.user._id).then((user) => {
			res.send(user.devices);
		}, err => res.status(400).send(err));
	}).catch((err) => {
		res.status(400).send(err);
	});
});

app.get('/notification/:type/:id', authenticate, (req, res) => {
	var entryID = req.params.id;
	var type = req.params.type
	if(!ObjectID.isValid(entryID)) return res.status(404).send();
	User.resetAlert(entryID, type).then(() => {
		res.status(200).send('removed alert');
	}).catch(err => {
		res.status(400).send(err);
	});
});

/// Update Device Settings, (Done) √

app.patch('/device/pref/:id', authenticate, (req, res) => {
	var id = req.params.id;
	var body = _.pick(req.body, ['set', 'monitoring', 'threshold']);
	
	User.verifyDevice(req.user._id, id).then(() => {
		return Device.updateSettings(body, id);
	}).then((device) => {
		res.send(device);
	}).catch((err) => {
		res.status(err).send();
	});
});

/// Create New User Account, i/p: n/a, payload: {email: 'example@email.com', password: '123456'} (Done)	√

app.post('/user/new', (req, res) => {
	var body = _.pick(req.body, ['email', 'password']);
	var user = new User(body);
	user.save().then(() => {
		return user.generateAuthToken();
	}).then((token) => {
		res.header('x-auth', token).send({_id: user._id, email: user.email});
	}).catch((err) => res.status(400).send(err));
});

/// Get User Object, i/p: n/a, payload: n/a	(Done)	√

app.get('/user/me', authenticate, (req, res) => {
	res.send(req.user);
});

/// Login User, i/p: n/a, payload: {email: 'example@email.com', password: '123456'} (Done)	√

app.post('/user/login', (req, res) => {
	var body = _.pick(req.body, ['email', 'password']);
	User.findByCredentials(body.email, body.password).then((user) => {
		return user.generateAuthToken().then((token) => {
			res.header('x-auth',token).send({_id: user._id, email: user.email});
		});
	}).catch((err) => {
		res.status(400).send(err);
	});
});

/// Logout User, i/p: n/a, payload: n/a	(Done)	√

app.delete('/user/logout', authenticate, (req, res) => {
	req.user.removeToken(req.token).then(() => {
		res.status(200).send();
	}).catch(() => {
		res.status(400).send();
	});
});

/// Logout All User, i/p: n/a, payload: n/a	(Done)	√

app.delete('/user/logout/all', authenticate, (req, res) => {
	req.user.removeAllToken(req.token).then(() => {
		res.status(200).send();
	}).catch((err) => {
		res.status(400).send(err);
	});
});

app.get('/device/self/:serial', (req, res) => {
	var data = {
		serial : req.params.serial
	}
	Device.getDeviceID(data).then((device) => {
		res.send(device.config);
	}).catch((err) => {
		res.status(400).send(err);
	});
});

server.listen(port, () => {
	console.log(`Listening on port ${port}`);
});

module.exports = {app};						/// exporting required for testing