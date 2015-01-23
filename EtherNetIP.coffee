enipSpec = require('./packets/enip.json')
cipCMSpec = require('./packets/cipCM.json')
NodeState = require('node-state')
Net = require('net')
DecoderRing = require('decoder-ring')

module.exports = class EtherNetIP extends NodeState
  constructor: (options) ->
    @sessionHandle = null
    @decoderRing   = new DecoderRing()
    @ip            = '127.0.0.1'
    @port          = 44818
    @intialState   = 'enip'
    if options.ip? then @ip = options.ip
    if options.port? then @port = options.port
    if options.intialState? then @intialState = options.intialState
    @socket = new Net.connect { port: @port, host: @ip }
    super autostart: false, initial_state: @intialState, sync_goto: true
    @socket.on 'data', (data) =>
      @raise 'Recieve', data

  states:
    enip:
      Enter: () ->
        @raise 'Send'
      Send: () ->
        @socket.write @decoderRing.encode({}, enipSpec)
      Recieve: (data) ->
        data = @decoderRing.decode(data, enipSpec)
        if data.status is 0
          @sessionHandle = data.session_handle
          @goto 'enipcm'
    enipcm:
      Enter: () ->
        console.log @sessionHandle
        @raise 'Send'
      Send: () ->
        console.log 'sending cm'
        cipCMSpec.fields[2].default = @sessionHandle
        @socket.write @decoderRing.encode({}, cipCMSpec)
      Recieve: (data) ->
        @goto 'cipSend', data
    cipSend:
      Enter: (data) ->
        console.log 'Enter CIP call'
	
      SendCIP: (data) ->
        console.log 'send call'
      MultiService: (data) ->
        console.log 'multiservice call'
      Recieve: (data) ->
        console.log 'receive data'

