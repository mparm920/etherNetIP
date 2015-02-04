DecoderRing = require('decoder-ring')
decoderRing = new DecoderRing()
RequireDir = require('require-directory')
Spec = RequireDir(module, '../packets')
_ = require 'lodash'

module.exports = class requestAssembler
  constructor: ->
    @data      = 'undefined'
    @_byteSize = { "bit": 1, "uint8": 1, "int8": 1, "uint16": 2, "int16": 2, "uint32": 4, "int32": 4, "float": 4, "double": 8 }

#TODO implement to return cip packet to send to the plc
  buildPacket: (requestPath, dataType, @data, dataLength) ->
    if @_getPathRequestLength(requestPath)
      @_createPacketJSON('symbol', 'ascii', requestPath + '\0')
    else
      @_createPacketJSON('symbol', 'ascii', requestPath)
    @_createPacketJSON('dataType', 'int16', dataType)
    @_createPacketJSON('dataLength', 'int16', dataLength)
    @_createPacketJSON('offset', 'int32', 0)
    Spec.cip.fields[1].default = @_enipLength()
    Spec.cip.fields[13].default = @_serviceLength()
    @cipBuffer = decoderRing.encode {}, Spec.cip
    @cipHeader = decoderRing.decode @cipBuffer, Spec.cip

  _getPathRequestLength: (requestPath) ->
    _len = requestPath.length
    Spec.cip.fields[18].default = _len
    if _len %% 2 is 0
      Spec.cip.fields[16].default = _len / 2
      false
    else
      Spec.cip.fields[16].default = (_len + 1) / 2
      true

  _createPacketJSON: (name, type, value) ->
    #lastObj is geting the starting point of the last object then adds the length of the data type to the lastObj starting point to get the starting point for the next object
    lastObj = _(Spec.cip.fields).sortBy('start').last()
    if lastObj.type is "ascii"
       lastObjLength = lastObj.length
    else
       lastObjLength = @_byteSize[lastObj.type]
    startByte = lastObj.start + lastObjLength
    if type is "ascii"
      Spec.cip.fields.push({name: name, start: startByte, type: type, length: value.length, default: value})
    else
      Spec.cip.fields.push({name: name, start: startByte, type: type, default: value})

  _enipLength: ->
    packetLength = _(Spec.cip.fields).sortBy('start').last()
    #24 is the lenght of the EtherNet IP header which isn't part of the length
    packetLength.start + @_byteSize[packetLength.type] + @data.length - 24

  _serviceLength: ->
    packetLength = _(Spec.cip.fields).sortBy('start').last()
    #42 is the lenght of the CIP header which isn't part of the length
    packetLength.start + @_byteSize[packetLength.type] + @data.length - 42



req = new requestAssembler()
console.log req.buildPacket('RFID1_WRITE', 195, [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], 3)
