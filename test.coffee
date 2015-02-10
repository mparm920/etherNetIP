lib = require './EtherNetIP.coffee'

app = new lib {ip: '172.16.1.40' }
app.start()
setInterval () ->
  tagSize = 8
  tagName = "Config.StationName.DATA[0]"
  #tagName = "TRACKTRACE_STA[0].recvPartStatus.Packet"
  cipbuffer = new Buffer(tagSize)
  for i in [0...tagSize]
    do(i) ->
      cipbuffer[i] = Math.floor Math.random() * 6 + 1
  app.raise 'WriteCIP', { symbol: tagName, packetData: cipbuffer }
, 5000
