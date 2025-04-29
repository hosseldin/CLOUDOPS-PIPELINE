const express = require('express')
const app = express()
const port = process.env.PORT || 80

const mysql = require('mysql2');
const pool = mysql.createPool({
    host: process.env.MYSQL_HOSTNAME,
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
    port: process.env.MYSQL_PORT || 3306,
});

app.get("/db", (req, res) => {
    pool.getConnection(function (err, connection) {
        if (err) {
            res.send("db connection failed");
            console.error('Database connection failed: ' + err.stack);
            return;
        }
        res.send("db connection successful finished pipeline");
        console.log('Connected to database.');
        connection.release(); // release back to the pool
    });
});

const redis = require('redis');
const client = redis.createClient({
    host: process.env.REDIS_HOSTNAME,
    port: process.env.REDIS_PORT || 6379,
});

client.on('error', err => {
    console.log('Error ' + err);
});

app.get('/redis', (req, res) => {

    client.set('foo', 'bar', (error, rep) => {
        if (error) {
            console.log(error);
            res.send("redis connection failed");
            return;
        }
        if (rep) {                          //JSON objects need to be parsed after reading from redis, since it is stringified before being stored into cache                      
            console.log(rep);
            res.send("redis is successfulyyyyy connected hosa and mourad");
        }
    })
})

app.listen(port, () => {
    console.log(`Example app listening at http://localhost:${port}`)
})
