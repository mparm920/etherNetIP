net = require 'net'
headers = require './packets/Headers.coffee'

io = require('socket.io-client')('http://localhost:3001/server')


socket = new net.Socket({readable: true, writable: true})

socket.connect 44818, "172.16.1.40", () ->
	socket.write headers.RegBuffer()  #sending ENIP request to PLC

tempBuffer = new Buffer(100)
count = 0
socket.on 'data', (data) ->
	console.log "command " + data[0]
	switch data[0]
		when 101 #return ENIP from PLC
			data.copy headers.SessionHandle, 0, 4, 8 #adding sessionHandle from ENIP response into CM request
			headers.Length.writeUInt16LE (headers.CmBuffer().length - 24), 0  #adding length of CM buffer to Ethernet IP header length
			socket.write headers.CmBuffer() #CM request
		when 111 #receive CM and send 0ut first CIP
			data.copy headers.ConnectionID, 0, 44, 48 #connection Id from plc 
			headers.Length.writeUInt16LE headers.GetCipSendCSDLength(), 0 #insterting length for command specific data
			socket.write headers.CipBuffer()
		when 112 #sending CIP command and asking for tag data will concatinate data until successful from byte 48
			seq = headers.CipSequence.readUInt16LE 0 # incrementing the sequence value every time a new packet is sent out
			headers.CipSequence.writeUInt16LE seq + 1, 0

			data.copy tempBuffer, count, 52
			count += (data.length - 52)
			if data[48] is 6
				headers.RequestDataLength.writeUInt32LE count, 0
			else
				console.log count
				io.emit 'data', (tempBuffer.toString('hex') + '</br>Count: ' + count.toString())
				count = 0
				headers.RequestDataLength.writeUInt32LE count, 0
				process.exit(0)
			headers.Length.writeUInt16LE headers.CipBuffer().length - 24, 0
			socket.write headers.CipBuffer()
		else
			console.log 'default'
