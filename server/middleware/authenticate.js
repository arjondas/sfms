var {User} = require('../models/user');
var bcrypt = require('bcrypt');

var authenticate = (req, res, next) => {
	var token = req.header('x-auth');
	User.findByToken(token).then((user) => {
		if(!user) {
			return Promise.reject();
		}
		req.user = user;
		req.token = token;
		next();
	}).catch((err) => {
		res.status(401).send();
	});
};

var superAuthenticate = (req, res, next) => {
	var keyOne = req.header('x-super-one');
	var keyTwo = req.header('x-super-two');
	verify(keyOne, keyTwo).then((msg) => {
		next();
	}).catch((err) => {
		res.status(401).send(err);
	});
}

var verify = (one, two) => {
	var hashOne = '$2b$10$4uCnOyoxC81YIYLiriPx2O5Tfr.CCq0K44eZ8XDWIDmay18Tk5XDy';
	var hashTwo = '$2b$10$nuxsBYTksm2ZC6r7UV82juefMtuD4M3kTiriEkI0NbEYauXkWJQFm';

	return new Promise((resolve, reject) => {
		bcrypt.compare(one, hashOne, (err, res) => {
			if(res) {
				bcrypt.compare(two, hashTwo, (err, res) => {
					if(res) {
						resolve('Super Authentication Successful');
					} else reject('Super Authentication Failed');
				});
			} else reject('Super Authentication Failed');
		});
	});
}

module.exports = {authenticate, superAuthenticate};

/*
return new Promise((resolve, reject) => {
	bcrypt.compare(password, user.password, (err, res) => {
		if(res) {
			resolve(user);
		} else {
			reject();
		}
	});
});*/