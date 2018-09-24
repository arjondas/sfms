require('./config/config');
const {ObjectID} = require('mongodb');
var express = require('express');
var bodyParser = require('body-parser');
const _ = require('lodash');
var {mongoose} = require('./db/mongoose');
var {Device} = require('./models/device');
var {User} = require('./models/user');
var {authenticate, superAuthenticate} = require('./middleware/authenticate');

var app = express();
const port = process.env.PORT || 4000;
app.use(bodyParser.json());

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
	var body = _.pick(req.body, ['serial']);
	Device.findOne({
		serial: body.serial
	}).then((device) => {
		return User.verifyDevice(req.user._id, device._id).then(() => {
			return Promise.resolve();
		}).catch(() => {
			return req.user.addDevice(device._id).then((devices) => {
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

app.listen(port, () => {
	console.log(`Listening on port ${port}`);
});

module.exports = {app};						/// exporting required for testing