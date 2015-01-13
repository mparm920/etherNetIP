NodeState = require("node-state")
class EtherNetIP extends NodeState
  constructor: (intialState) ->
    super autostart: false, initial_state: intialState, sync_goto: true
  states:
    enip:
      Enter: (data) ->
        console.log 'enip enter state'
      Send: (data) ->
      Recieve: (data) ->
        if data[0] = 101
          @goto 'enipcm', data
    enipcm:
      Enter: (data) ->
        console.log 'enipcm enter state'
      Send: (data) ->
      Recieve: (data) ->
        @goto 'cipSend', data
    cipSend:
      Enter: (data) ->
        console.log 'Enter CIP call'
	
      SendCIP: (data) ->
        console.log 'send call'
      MultiService: (data) ->
        console.log 'multiservice call'
      Recieve: (data) ->
        console.log 'receive data'
