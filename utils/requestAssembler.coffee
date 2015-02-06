DecoderRing = require('decoder-ring')
decoderRing = new DecoderRing()
RequireDir = require('require-directory')
Spec = RequireDir(module, '../packets')
_ = require 'lodash'

module.exports = class requestAssembler
  constructor: () ->
    @dataLength = 'undefined'
    @_byteSize  = { "bit": 1, "uint8": 1, "int8": 1, "uint16": 2, "int16": 2, "uint32": 4, "int32": 4, "float": 4, "double": 8 }

  buildPacket: (requestPath, @dataLength, totalDataLength, offset) ->
    @_setPathRequest(requestPath)
    @_updatePacketJSON 'totalDataLength', totalDataLength
    @_updatePacketJSON 'offset', offset
    @_enipLength()
    @_serviceLength()
    @cipBuffer = decoderRing.encode {}, Spec.cip
    Buffer.concat [@cipBuffer]

  setSessionId: (sessionId) ->
    @_updatePacketJSON 'session_handle', sessionId

  setConnectionId: (connectionId) ->
    @_updatePacketJSON 'connectionId', connectionId

  _setPathRequest: (requestPath) ->
    _len = requestPath.length
    @_updatePacketJSON 'symbolLength', _len
    if _len %% 2 is 0
      @_updatePacketJSON 'requestPathSize', _len / 2
    else
      @_updatePacketJSON 'requestPathSize', (_len + 1) / 2
      requestPath += '\u0000'
    @_updatePacketJSON 'symbol', requestPath

  _updatePacketJSON: (name, value) ->
    index = _(Spec.cip.fields).findIndex({name: name})
    Spec.cip.fields[index].default = value
    if Spec.cip.fields[index].type is "ascii"
      Spec.cip.fields[index].length = value.length
      @_cascadeStartByte(index + 1, Spec.cip.fields[index].start + value.length)

  _enipLength: ->
    packetLength = _(Spec.cip.fields).sortBy('start').last()
    #24 is the lenght of the EtherNet IP header which isn't part of the length
    @_updatePacketJSON 'length', packetLength.start + @_byteSize[packetLength.type] + @dataLength - 24

  _serviceLength: ->
    packetLength = _(Spec.cip.fields).sortBy('start').last()
    #42 is the lenght of the CIP header which isn't part of the length
    @_updatePacketJSON 'typeId2Length', packetLength.start + @_byteSize[packetLength.type] + @dataLength - 42

  _cascadeStartByte: (index, startByte) ->
    for i in [index..Spec.cip.fields.length - 1]
      do (i) =>
        obj = Spec.cip.fields[i]
        obj.start = startByte
        startByte += @_byteSize[obj.type.toString()]
