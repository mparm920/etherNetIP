lib = require './EtherNetIP.coffee'

app = new lib {ip: '172.16.1.40' }
app.start()
setTimeout ->
  app.raise 'SendCIP'
,500
