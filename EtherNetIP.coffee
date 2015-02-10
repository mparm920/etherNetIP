NodeState = require('node-state')
Util = require('./utils/requestAssembler')
Net = require('net')
DecoderRing = require('decoder-ring')
RequireDirectory = require('require-directory')
Spec = RequireDirectory(module, './packets')

module.exports = class EtherNetIP extends NodeState
  constructor: (options) ->
    @_maxPacketSize   = 472
    @packets          = []
    @sessionHandle    = null
    @decoderRing      = new DecoderRing()
    @ip               = options.ip ? '127.0.0.1'
    @port             = options.port ? 44818
    @intialState      = options.intialState ? 'enip'
    @packetAssembler  = new Util()
    @socket           = new Net.connect { port: @port, host: @ip }
    @socket.setNoDelay true
    super autostart: false, initial_state: @intialState, sync_goto: true
    @socket.on 'data', (data) =>
      @raise 'Recieve', data

  _multiPackets: (data) ->
    _offset = 0
    while((_offset + @_maxPacketSize) < data.packetData.length)
      @packets.push Buffer.concat([@packetAssembler.buildPacket(data.symbol, @_maxPacketSize, data.packetData.length, _offset), data.packetData[_offset..._offset + @_maxPacketSize]])
      _offset += @_maxPacketSize
    @packets.push Buffer.concat([@packetAssembler.buildPacket(data.symbol, data.packetData[_offset..].length, data.packetData.length, _offset), data.packetData[_offset..]])
    @raise 'Recieve'

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
        @packetAssembler.setConnectionId = data.readUInt32LE 44 #28 #reads connectionId sent back from PLC
        status = data.readUInt16LE 26 #checks CIP packet status 0 is success anything else is a error
        if !status
          @goto 'cipSend'
        else
          console.log status
    cipSend:
      WriteCIP: (data) ->
        console.log data.symbol
        @_multiPackets(data)
      Recieve: () ->
        if @packets.length > 0 then @socket.write @packets.shift()
