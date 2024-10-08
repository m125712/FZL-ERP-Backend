import cors from 'cors';

const whitelist = [
	// FZL H/O
	'http://103.147.163.46:3005',
	'http://103.147.163.46:4010',
	'http://103.147.163.46:3000',
	'http://103.147.163.46:4015',
	'http://103.147.163.46:4016',
	// Development
	'http://localhost:3005',
	'http://localhost:4010',
	'http://localhost:3000',
	'http://localhost:4015',
	'http://localhost:4016',
	// Office Server PC
	'http://192.168.10.56:3005',
	'http://192.168.10.56:4010',
	'http://192.168.10.56:3000',
	'http://192.168.10.56:4015',
	'http://192.168.10.56:4016',

	// RBR Home
	'http://192.168.1.108:4175',
];

var corsOptionsDelegate = function (req, callback) {
	var corsOptions;
	if (whitelist.indexOf(req?.header('Origin')) !== -1) {
		corsOptions = { origin: true };
	} else {
		corsOptions = { origin: false };
	}
	callback(null, corsOptions);
};

export default cors(corsOptionsDelegate);
