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
            console.error('Database connection failed: ' + err.stack);
            return res.send(`
                <html>
                    <head><title>DB Connection</title></head>
                    <body style="font-family: Arial; background-color: #ffe6e6; padding: 20px;">
                        <h1 style="color: red;">❌ Database connection failed</h1>
                    </body>
                </html>
            `);
        }

        console.log('Connected to database.');
        connection.release();

        res.send(`
            <html>
                <head><title>DB Connection</title></head>
                <body style="font-family: Arial; background-color: #e6ffe6; padding: 20px;">
                    <h1 style="color: green;">✅ DB connection successful</h1>
                    <p>Pipeline completed successfully.</p>
                </body>
            </html>
        `);
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
            return res.send(`
                <html>
                    <head><title>Redis Connection</title></head>
                    <body style="font-family: Arial; background-color: #ffe6e6; padding: 20px;">
                        <h1 style="color: red;">❌ Redis connection failed</h1>
                    </body>
                </html>
            `);
        }

        console.log(rep);
        res.send(`
            <html>
                <head><title>Redis Connection</title></head>
                <body style="font-family: Arial; background-color: #e6ffe6; padding: 20px;">
                    <h1 style="color: green;">✅ Redis connected successfully</h1>
                    <p>Message: Redis is working (HOSdasdsAA and mourad)</p>
                </body>
            </html>
        `);
    });
});

app.listen(port, () => {
    console.log(`Example app listening at http://localhost:${port}`)
})
