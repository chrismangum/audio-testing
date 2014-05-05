
socket = io.connect 'http://localhost'
socket.on 'metadata', (data) ->
  console.log data
socket.on 'json', (data) ->
  console.log data

