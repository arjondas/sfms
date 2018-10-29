var mongoose = require('mongoose');
var _ = require('lodash');

var DeviceSchema = new mongoose.Schema({
	serial: {
		type: Number,
		unique: true,
		required: true
	},
	description: {
		type: String,
		required: false,
		minlength: 1,
		trim: true
	},
	config: {
		weight: {
			monitoring: {
				type: Boolean,
				default: false
			},
			threshold: {
				type: Number,
				default: 100
			}
		},
		temperature: {
			monitoring: {
				type: Boolean,
				default: false
			},
			threshold: {
				type: Number,
				default: 4
			}
		}
	},
	currentTemp: {
		type: Number,
		default: 0
	},
	currentWeight: {
		type: Number,
		default: 0
	},
	logs: {
		tempData: [{
			time: {
				type: Number
			},
			data: {
				type: Number
			}
		}]
	}
})

DeviceSchema.statics.updateSettings = function(settings, deviceID) {
	var Device = this;
	if(settings.set === 'temperature') {
		if(settings.monitoring !== undefined && settings.threshold !== undefined) {
			var configure = {
				monitoring: settings.monitoring,
				threshold: settings.threshold
			}
			return Device.findOneAndUpdate({
				_id: deviceID
			}, {$set: {
					'config.temperature': configure
				}}, {new: true}).then((device) => {
				if(!device) return Promise.reject(404);
				return Promise.resolve(device);
			});
		} else if (settings.monitoring !== undefined) {
			return Device.findOneAndUpdate({
				_id: deviceID
			}, {$set: {
					'config.temperature.monitoring': settings.monitoring
				}}, {new: true}).then((device) => {
				if(!device) return Promise.reject(404);
				return Promise.resolve(device);
			});
		} else if(settings.threshold !== undefined) {
			return Device.findOneAndUpdate({
				_id: deviceID
			}, {$set: {
				'config.temperature.threshold': settings.threshold
				}}, {new: true}).then((device) => {
				if(!device) return Promise.reject(404);
				return Promise.resolve(device);
			});
		} else {
			return Promise.reject(400);
		}
	} else if(settings.set === 'weight') {
		if(settings.monitoring !== undefined && settings.threshold !== undefined) {
			var configure = {
				monitoring: settings.monitoring,
				threshold: settings.threshold
			}
			return Device.findOneAndUpdate({
				_id: deviceID
			}, {$set: {
					'config.weight': configure
				}}, {new: true}).then((device) => {
				if(!device) return Promise.reject(404);
				return Promise.resolve(device);
			});
		} else if (settings.monitoring !== undefined) {
			return Device.findOneAndUpdate({
				_id: deviceID
			}, {$set: {
					'config.weight.monitoring': settings.monitoring
				}}, {new: true}).then((device) => {
				if(!device) return Promise.reject(404);
				return Promise.resolve(device);
			});
		} else if(settings.threshold !== undefined) {
			return Device.findOneAndUpdate({
				_id: deviceID
			}, {$set: {
					'config.weight.threshold': settings.threshold
				}}, {new: true}).then((device) => {
				if(!device) return Promise.reject(404);
				return Promise.resolve(device);
			});
		} else {
			return Promise.reject(400);
		}
	} else {
		return Promise.reject(400);
	}
}

DeviceSchema.statics.logTemperatureData = function(tempData) {
	var Device = this;
	var time = tempData.time;
	var data = tempData.data;
	return Device.findOne({
		serial: tempData.serial
	}).then((device) => {
		device.logs.tempData.push({time, data});
		return device.save().then(() => {
			return Promise.resolve('s200');
		})
	}).catch(() => {
		return Promise.reject('s400');
	});
}

DeviceSchema.statics.logCurrentTemp = function(tempData) {
	var Device = this;
	var data = tempData.data;
	return Device.findOneAndUpdate({
		serial: tempData.serial
	}, {
		$set: {
			currentTemp: data
	}}, {new: true})
}

DeviceSchema.statics.logCurrentWeight = function(weightData) {
	var Device = this;
	var data = weightData.data;
	return Device.findOneAndUpdate({
		serial: weightData.serial
	}, {
		$set: {
			currentWeight: Math.abs(data)
	}}, {new: true})
}

DeviceSchema.statics.surveyTemperatureData = function(tempData) {
	var Device = this;
	var data = tempData.data;
	return Device.findOne({
		serial: tempData.serial
	}).then((device) => {
		if(device.config.temperature.monitoring) {
			if(device.config.temperature.threshold < data) {
				console.log('resolving');
				return Promise.resolve(true);
			} else {
				return Promise.reject(true);
			}
		} else {
			return Promise.resolve(false);
		}
	}).catch((flag) => {
		if (typeof(flag) === "boolean") {
			return Promise.reject(true);
		} else {
			return Promise.reject(false);
		}
	});
}

DeviceSchema.statics.surveyInventryData = function(invData) {
	var Device = this;
	var data = invData.data;
	return Device.findOne({
		serial: invData.serial
	}).then((device) => {
		if(device.config.weight.monitoring) {
			if(data < device.config.weight.threshold) {
				console.log('resolving inventry');
				return Promise.resolve(true);
			} else {
				return Promise.reject(true);
			}
		} else {
			return Promise.resolve(false);
		}
	}).catch((flag) => {
		if (typeof(flag) === "boolean") {
			return Promise.reject(true);
		} else {
			return Promise.reject(false);
		}
	});
}

DeviceSchema.statics.getDeviceID = function(tempData) {
	var Device = this;
	return Device.findOne({
		serial: tempData.serial
	});
}

var Device = mongoose.model('Device', DeviceSchema);

module.exports = {Device}