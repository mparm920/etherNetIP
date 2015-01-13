express = require 'express'
app = express()
net = require 'net'
headers = require './Headers.coffee'

socket = new net.Socket({readable: true, writable: true})

socket.connect 44818, "172.16.1.40", () ->
	socket.write headers.RegBuffer()  #sending ENIP request to PLC

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
			headers.Length.writeUInt16LE headers.CipSendCSDLength(), 0 #insterting length for command specific data
			socket.write headers.CipBuffer()
		when 112
			seq = headers.CipSequence.readUInt16LE 0
			headers.CipSequence.writeUInt16LE seq + 1, 0
			#if count % 2 == 0
			setTimeout () ->
				console.log 'cip'
				if data[49] = 6
					count += (data.length - 50)
					headers.RequestDataLength.writeUInt32LE count, 0
				else
					count = 0
					headers.RequestDataLength.writeUInt32LE count, 0
				headers.Length.writeUInt16LE headers.CipBuffer().length - 24, 0
				socket.write headers.CipBuffer()
			, 3000
			#else
			#	console.log 'multi'
			#	headers.Length.writeUInt16LE headers.MultiBuffer().length - 24, 0
			#	socket.write headers.MultiBuffer()
			#count++
		else
			console.log 'default'

