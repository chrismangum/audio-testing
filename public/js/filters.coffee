
app.filter 'convertTimestamp', ->
  padTime = (n) ->
    if n < 10
      n = '0' + n
    return n

  (s = 0) ->
    ms = s % 1000
    s = (s - ms) / 1000
    secs = s % 60
    s = (s - secs) / 60
    mins = s % 60
    hrs = (s - mins) / 60
    if hrs
      return hrs + ':' + padTime mins + ':' + padTime secs
    else
      return mins + ':' + padTime secs

