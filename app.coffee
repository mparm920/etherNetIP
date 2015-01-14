express = require 'express'
app = express()
server = require('http').createServer app
io = require('socket.io')(server)
web = io.of '/web'
serv = io.of '/server'

webSocket = {}

app.get '/', (req, res) ->
	res.sendFile __dirname + '/public/index.html'

web.on 'connect', (socket) ->
	console.log 'websocket connected'
	webSocket = socket

serv.on 'connect', (socket) ->
	console.log 'server connected'
	socket.on 'data', (data) ->
		console.log 'new data recieved'
		webSocket.emit 'data', data
	socket.on 'count', (count) ->
		console.log count.toString()
		webSocket.emit 'count', count

server.listen 3001, () ->
	console.log 'listening on port 3001'
