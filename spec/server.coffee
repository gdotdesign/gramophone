connect = require('connect')
connect.createServer(
  connect.static(__dirname+"/server")
).listen(8080)