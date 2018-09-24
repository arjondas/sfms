var mongoose = require('mongoose');

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
				default: 5
			}
		},
		temperature: {
			monitoring: {
				type: Boolean,
				default: false
			},
			threshold: {
				type: Number,
				default: 5
			}
		}
	},
	sensors: [{
		name: {
			type: String,
			default: null
		},
		rawdata: [{
			time: {
				type: Number,
				default: null
			},
			data: {
				type: Number,
				default: null
			}
		}]
	}]
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

var Device = mongoose.model('Device', DeviceSchema);

module.exports = {Device}