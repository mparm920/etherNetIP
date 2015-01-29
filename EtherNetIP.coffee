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
    @ip            = options.ip ? @ip
    @port          = options.port ? @port
    @intialState   = options.intialState ? @intialState
    @socket        = new Net.connect { port: @port, host: @ip }
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
        @socket.write @decoderRing.encode({session_handle: @sessionHandle}, Spec.cipCM)
      Recieve: (data) ->
        @connectionId = data.readUInt32LE 44 #28 #reads connectionId sent back from PLC
        status = data.readUInt16LE 26 #checks CIP packet status 0 is success anything else is a error
        if !status
          @goto 'cipSend'
        else
          console.log status
    cipSend:
      Enter: () ->
        @raise 'SendCIP'
      SendCIP: () ->
        cipHeader = @decoderRing.encode({
                                          session_handle: @sessionHandle,
                                          connectionId: @connectionId,
                                          typeId2Length: 488,
                                          dataLength: 2048,
                                          length: 508
                                        }, Spec.cip)
        cipData = new Buffer(462)
        cipData.fill 2
        @socket.write Buffer.concat([cipHeader, cipData])
      Recieve: (data) ->
        document.getElementById('buffer').innerHTML = data.toString()
        console.log 'receive data'

