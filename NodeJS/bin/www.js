#!/usr/bin/env node

const bodyParser = require('body-parser');
const express = require('express');
const test = require('../test');

const app = express();

let server;
const mode = process.env.MODE;

/**
 * Parse the port integer
 */
function normalizePort(val) {
    const port = parseInt(val, 10);
    if (port >= 0) {
        // port number
        return port;
    }
    return false;
}


const port = normalizePort(process.env.PORT || '8000');
app.set('port', port);

console.log(`Mode is ${mode}`);

/**
 * Listen on provided port, on all network interfaces.
 */
server = app.listen(app.get('port'), function () {
    console.log(`Server listening on port ${app.get('port')} press CTRL+C to terminate.`);
});

/**
 * Event listener for HTTP server "error" event.
 */
function onError(error) {
    if (error.syscall !== 'listen') {
        throw error;
    }

    // handle specific listen errors with friendly messages
    switch (error.code) {
        case 'EACCES':
            console.error(`Port ${port} requires elevated privileges`);
            process.exit(1);
            break;
        case 'EADDRINUSE':
            console.error(`Port ${port} is already in use`);
            process.exit(1);
            break;
        default:
            throw error;
    }
}

/**
 * Event listener for HTTP server "listening" event.
 */
function onListening() {
    const addr = server.address();
    console.log(`Listening on ${addr.port}`);
}

app.on('error', onError);
app.on('listening', onListening);
app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json()); // for parsing application/json

/**
 * APIs
 */
app.get('/api/v1/current', test.current);
app.post('/api/v1/update', test.update);
app.post('/api/v1/refresh_all', test.refresh_all);
app.post('/api/v1/refresh', test.refresh);

// Show the endpoints which are being registered
// eslint-disable-next-line no-underscore-dangle
app._router.stack.forEach(function (r) {
    if (r.route && r.route.path) {
        console.log('Registered endpoint: ', r.route.path);
    }
});

// Shutdown process
// this function is called when you want the server to die gracefully
// i.e. wait for existing connections
const shutdownServer = function (err) {
    let msg = 'Received kill signal, shutting down server...';
    console.log(msg);
    if (typeof err !== 'undefined') {
        console.log('There has been an uncaught exception :', err.stack);
    }
    server.close(function () {
        msg = 'Closed out remaining connections.';
        console.log(msg);
        process.exit();
    });

    // if after 10 seconds, force shutdown
    setTimeout(function () {
        console.error('Could not close connections in time, forcefully shutting down');
        process.exit();
    }, 10 * 1000);
};

// listen for TERM signal .e.g. kill
process.on('SIGTERM', shutdownServer);
// listen for INT signal e.g. Ctrl-C
process.on('SIGINT', shutdownServer);
if (mode === 'DEV' || mode === 'Dev' || mode === 'dev') {
    // catches uncaught exceptions
    process.on('uncaughtException', shutdownServer);
}
