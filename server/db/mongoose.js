var mongoose = require('mongoose');

mongoose.Promise = global.Promise;				/// Setting up mongoose promise

mongoose.connect(process.env.MONGODB_URI, {useNewUrlParser: true});

module.exports = {mongoose};