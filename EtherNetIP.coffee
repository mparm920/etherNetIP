NodeState = require('node-state')
Net = require('net')
DecoderRing = require('decoder-ring')
RequireDirectory = require('require-directory')
Spec = RequireDirectory(module, './packets')

module.exports = class EtherNetIP extends NodeState
  constructor: (options) ->
    @sessionHandle = null
    @connectionId  = null
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
        @socket.write @decoderRing.encode({}, Spec.enip)
      Recieve: (data) ->
        data = @decoderRing.decode(data, Spec.enip)
        if data.status is 0
          @sessionHandle = data.session_handle
          @goto 'enipcm'
    enipcm:
      Enter: () ->
        @raise 'Send'
      Send: () ->
        Spec.cipCM.fields[2].default = @sessionHandle #setting the session handle returned from the PLC
        Spec.cip.fields[2].default = @sessionHandle
        @socket.write @decoderRing.encode({}, Spec.cipCM)
      Recieve: (data) ->
        @connectionId = data.readInt32LE 28 #reads connectionId sent back from PLC
        status = data.readInt16LE 26 #checks CIP packet status 0 is success anything else is a error
        if !status
          @goto 'cipSend'
        else
          console.log status
    cipSend:
      Enter: () ->
        console.log 'Enter CIP call'
      SendCIP: () ->
        console.log @decoderRing.encode({}, Spec.cip)
        @socket.write @decoderRing.encode({}, Spec.cip)
      Recieve: (data) ->
        console.log 'receive data'

