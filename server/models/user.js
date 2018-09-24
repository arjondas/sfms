const mongoose = require('mongoose');
const {ObjectID} = require('mongodb');
const uniqueValidator = require('mongoose-unique-validator');
const validator = require('validator');
const jwt = require('jsonwebtoken');
const _ = require('lodash');
const bcrypt = require('bcrypt');

var UserSchema = new mongoose.Schema({
	email: {
		type: String,
		required: true,
		trim: true,
		minlength: 1,
		index: true,
		unique: true,
		validate: {
			validator: validator.isEmail,
			message: '{VALUE} is not a valid email'
		}
	},
	password: {
		type: String,
		required: true,
		minlength: 6
	},
	devices: [{
		_deviceID: {
			type: mongoose.Schema.Types.ObjectId				/// ******* Try string
		}
	}],
	tokens: [{
		access: {
			type: String,
			required: true
		},
		token: {
			type: String,
			required: true
		}
	}]
});

UserSchema.plugin(uniqueValidator);

UserSchema.methods.toJSON = function() {
	var user = this;
	var userObject = user.toObject();
	return _.pick(userObject, ['_id', 'email', 'devices']);
}

UserSchema.methods.generateAuthToken = function() {
	var user = this;
	var access = 'auth';
	var token = jwt.sign({_id: user._id.toHexString(), access}, process.env.JWT_SECRET).toString();
	user.tokens.push({access, token});

	return user.save().then(() => {
		return token;
	});
};

UserSchema.methods.removeToken = function(token) {
	var user = this;

	return user.update({
		$pull: {
			tokens: {
				token: token
			}
		}
	});
};

UserSchema.methods.removeAllToken = function(token) {
	var user = this;
	
	return user.update({
		$pull: {
			tokens: {
				token: token
			}
		}
	}).then(() => {
		return user.update({
			tokens: []
		});
	});
};

UserSchema.methods.addDevice = function(deviceID) {
	var user = this;
	user.devices.push({_deviceID: deviceID});

	return user.save().then(() => {
		return user.devices;
	});
};

UserSchema.methods.removeDevice = function(deviceID) {
	var user = this;
	return user.update({
		$pull: {
			devices: {
				_deviceID : deviceID
			}
		}
	});
};

UserSchema.statics.verifyDevice = function(userID, deviceID) {
	var User = this;
	if(!ObjectID.isValid(deviceID)) return Promise.reject(404);
	return User.findOne({
		'_id': userID,
		'devices._deviceID': deviceID
	}).then((user) => {
		if(!user) return Promise.reject(401);
		return Promise.resolve();
	}).catch((err) => Promise.reject(401));
}

UserSchema.statics.findByToken = function(token) {
	var User = this;
	var decoded;

	try {
		decoded = jwt.verify(token, process.env.JWT_SECRET);
	} catch(err) {
		return Promise.reject(err);
	}

	return User.findOne({
		'_id': decoded._id,
		'tokens.token': token,
		'tokens.access': 'auth'
	});
}

UserSchema.statics.findByCredentials = function(email, password) {
	var User = this;

	return User.findOne({email}).then((user) => {
		if(!user) {
			return Promise.reject();
		}
		return new Promise((resolve, reject) => {
			bcrypt.compare(password, user.password, (err, res) => {
				if(res) {
					resolve(user);
				} else {
					reject();
				}
			});
		});
	});
}

UserSchema.pre('save', function(next) {
	var user = this;
	if(user.isModified('password')) {
		bcrypt.genSalt(10, (err, salt) => {
			bcrypt.hash(user.password, salt, (err, hash) => {
				user.password = hash;
				next();
			});
		});
	} else {
		next();
	}
})

var User = mongoose.model('User', UserSchema);

module.exports = {User};