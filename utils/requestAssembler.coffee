DecoderRing = require('decoder-ring')
decoderRing = new DecoderRing()
RequireDir = require('require-directory')
Spec = RequireDir(module, '../packets')
_ = require 'lodash'

class requestAssembler
  constructor: ->
    @wtf = decoderRing.encode {}, Spec.cip
    @cipHeader = decoderRing.decode @wtf, Spec.cip
    #console.log @cipHeader
    @_byteSize = { "bit": 1, "uint8": 1, "int8": 1, "uint16": 2, "int16": 2, "uint32": 4, "int32": 4, "float": 4, "double": 8 }

  _getENIPLength: (buffer) ->
    enipLength = buffer.length - 24
    @cipHeader.length = enipLength
    #console.log @cipHeader

  buildPacket: (requestPath, dataType, dataLength) ->

  _getPathRequestLength: (requestPath) ->
    _len = requestPath.length
    if _len %% 2 is 0
      return _len / 2
    else
      return (_len + 1) / 2

  _createPacketJSON: (name, type) ->
    console.log Spec.cip.fields.length
    lastObj = _(Spec.cip.fields).sortBy('start').last()
    if lastObj.type is "ascii"
       lastObjLength = lastObj.length
    else
       lastObjLength = @_byteSize[lastObj.type]
    startByte = lastObj.start + lastObjLength
    if type is "ascii"
      Spec.cip.fields.push({name: name, start: startByte, type: type, length: name.length})
    else
      Spec.cip.fields.push({name: name, start: startByte, type: type})
    console.log JSON.stringify(Spec.cip, null, 4)

req = new requestAssembler()
req._createPacketJSON("Data_To_PC", "ascii")
req._createPacketJSON("connectionID", "uint32")
