NodeState = require('node-state')
Util = require('./utils/requestAssembler')
Net = require('net')
DecoderRing = require('decoder-ring')
RequireDirectory = require('require-directory')
Spec = RequireDirectory(module, './packets')

module.exports = class EtherNetIP extends NodeState
  constructor: (options) ->
    @sessionHandle    = null
    @connectionId     = null
    @decoderRing      = new DecoderRing()
    @ip               = '127.0.0.1'
    @port             = 44818
    @intialState      = 'enip'
    @ip               = options.ip ? @ip
    @port             = options.port ? @port
    @intialState      = options.intialState ? @intialState
    @packetAssembler  = new Util()
    @socket           = new Net.connect { port: @port, host: @ip }
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
          @packetAssembler.setSessionId @sessionHandle
        @goto 'enipcm'
    enipcm:
      Enter: () ->
        @raise 'Send'
      Send: () ->
        @socket.write @decoderRing.encode({session_handle: @sessionHandle}, Spec.cipCM)
      Recieve: (data) ->
        @connectionId = data.readUInt32LE 44 #28 #reads connectionId sent back from PLC
        @packetAssembler.setConnectionId @connectionId
        status = data.readUInt16LE 26 #checks CIP packet status 0 is success anything else is a error
        if !status
          @goto 'cipSend'
        else
          console.log status
    cipSend:
      SendCIP: (data) ->
        buf = new Buffer 74
        buf.fill 1
        cipBuffer = @packetAssembler.buildPacket 'DATA_FROM_PC', buf.length, 75, 0
        @socket.write Buffer.concat([cipBuffer, buf])
      Recieve: (data) ->
        console.log 'receive data'

