Headers = {
	CommandReg : new Buffer([0x65, 0x00])
	Length : new Buffer([0x04, 0x00])
	SessionHandle : new Buffer([0x00, 0x00, 0x00, 0x00])
	EnipStatus : new Buffer([0x00, 0x00, 0x00, 0x00])
	SenderContext : new Buffer([0x65, 0x66, 0x6c, 0x65, 0x78, 0x00, 0x00, 0x00])
	Options : new Buffer([0x00, 0x00, 0x00, 0x00])
	ProtocolVersion : new Buffer([0x01, 0x00])
	OptionFlags : new Buffer([0x00, 0x00])

	CommandSend : new Buffer([0x6f, 0x00])
	CmStatus : new Buffer([0x00, 0x00, 0x00, 0x00])
	InterfaceHandle : new Buffer([0x00, 0x00, 0x00, 0x00])
	TimeOut : new  Buffer([0x05, 0x00])
	ItemCount : new Buffer([0x02, 0x00])
	TypeId : new Buffer([0x00, 0x00])
	TypeLength : new Buffer([0x00, 0x00])
	TypeId2 : new Buffer([0xb2, 0x00])
	TypeLength2 : new Buffer([0x32, 0x00])
	Service : new Buffer([0x54])

	CommandUnitData : new Buffer([0x70, 0x00])
	CipStatus : new Buffer([0x00, 0x00, 0x00, 0x00])
	CipTimeOut : new Buffer([0x00, 0x00])
	CIPItemCount : new Buffer([0x02, 0x00])
	ConnectionAddressItem : new Buffer([0xa1, 0x00])
	ConnectionIDLength : new Buffer([0x04, 0x00])
	ConnectionID : new Buffer([0x00, 0x00, 0x00, 0x00])
	TypeIDb1 : new Buffer([0xb1, 0x00])
	B1Length : new Buffer([0x12, 0x00]) #calculated from remaining bytes in packet
	CipSequence : new Buffer([0x62, 0x00])
	CipService : new Buffer([0x52])
	RequestPathSize : new Buffer([0x04]) #in WORDS (Double byte) number of words for reques path padding appended to end of needed
	PathSegment : new Buffer([0x91]) #ANSI Extended Symbol Segment
	DataSize : new Buffer([0x06]) #length of TagSymbol
	TagSymbol : new Buffer([0x52, 0x46, 0x49, 0x44, 0x31, 0x5f, 0x52, 0x45, 0x41, 0x44])
	Padding : new Buffer(0)
	RequestTotalData : new Buffer([0x0d, 0x66])
	RequestDataLength : new Buffer([0x00, 0x00, 0x00, 0x00])

	RegBuffer : () ->
          Buffer.concat([@CommandReg, @Length, @SessionHandle, @EnipStatus, @SenderContext, @Options, @ProtocolVersion, @OptionFlags])

	CmBuffer : () ->
          Buffer.concat([@CommandSend, @Length, @SessionHandle, @CmStatus, @SenderContext, @Options, @InterfaceHandle, @TimeOut, @ItemCount, @TypeId, @TypeLength, @TypeId2, @TypeLength2, @Service, new Buffer([0x02, 0x20, 0x06, 0x24, 0x01, 0x00, 0xfa, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x20, 0xdb, 0xe5, 0x41, 0x53, 0x01, 0x02, 0x04, 0x08, 0x02, 0x00, 0x00, 0x00, 0x80, 0x84, 0x1e, 0x00, 0xf4, 0x43, 0x80, 0x84, 0x1e, 0x00, 0xf4, 0x43, 0xa3, 0x04, 0x01, 0x00, 0x20, 0x02, 0x24, 0x01, 0x2c, 0x01])])

	CipBuffer : () ->
	  @GetRequestPathSize()
	  @GetTagSymbolLength()
	  @GetConnectedDataItemLength()
	  Buffer.concat([@CommandUnitData, @Length, @SessionHandle, @CipStatus, @SenderContext, @Options, @InterfaceHandle, @CipTimeOut, @CIPItemCount, @ConnectionAddressItem, @ConnectionIDLength, @ConnectionID, @TypeIDb1, @B1Length, @CipSequence, @CipService, @RequestPathSize, @PathSegment, @DataSize, @TagSymbol, @Padding, @RequestTotalData, @RequestDataLength])

	GetRequestPathSize : () ->
	  num = Buffer.concat([@PathSegment, @DataSize, @TagSymbol, @Padding]).length
	  if (num % 2) is 0
	     @RequestPathSize.writeUInt8 (num / 2), 0
	     @Padding = new Buffer(0)
	  else
	    @Padding = new Buffer([0x00])
	    @GetRequestPathSize()

	GetTagSymbolLength : () ->
	  @DataSize.writeUInt8 @TagSymbol.length, 0

	GetConnectedDataItemLength : () ->
	  @B1Length.writeUInt16LE Buffer.concat([@CipSequence, @CipService, @RequestPathSize, @PathSegment, @DataSize, @TagSymbol, @RequestTotalData, @RequestDataLength]).length, 0

	GetCipSendCSDLength : () ->
          @CipBuffer().length - 24

	MultiBuffer : () ->
          Buffer.concat([@CommandUnitData, @Length, @SessionHandle, new Buffer([0x00, 0x00, 0x00, 0x00, 0x65, 0x66, 0x6c, 0x65, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0xa1, 0x00, 0x04, 0x00]), @ConnectionID, new Buffer([0xb1, 0x00, 0x1c, 0x00]), @CipSequence, @CipService, new Buffer([0x02, 0x20, 0x02, 0x24, 0x01, 0x01, 0x00, 0x04, 0x00, 0x4c, 0x04, 0x91, 0x06, 0x43, 0x6f, 0x6e, 0x66, 0x69, 0x67, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00])])
}
module.exports = Headers
