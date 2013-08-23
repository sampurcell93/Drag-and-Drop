{exec}  = require 'child_process'
task 'build', 'Build project from public/coffee/*.coffee to public/js/*.js', ->
  exec 'coffee --compile --output public/js public/coffee', (err, stdout, stderr) ->
    throw err if err
    console.log "Built coffee"
