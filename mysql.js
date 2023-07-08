var mysql = require("mysql2");

var user = "root";
var host = "localhost";
var password = "root";
var database = "festmanagement";

const mysqlConnection = mysql.createConnection({
    host: host,
    user: user,
    password: password,
    database: database,
    multipleStatements: true
}).promise();

mysqlConnection.connect(function(err) {
    if (err) {
      console.error('error connecting to mysql: ' + err.stack);
      return;
    }
    console.log(`connected to mysql user ${user}`) ;
  });

module.exports = mysqlConnection;