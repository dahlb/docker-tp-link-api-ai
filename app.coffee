#!./node_modules/.bin/coffee

# setup tp link plugs
Hs100Api = require('hs100-api')
client = new Hs100Api.Client()

plugs = {}
plugInfos = {}

client.startDiscovery().on 'plug-new', (plug) ->
  plug.getInfo().then (plugInfo) ->
    plugs[plugInfo.sysInfo.alias] = plug
    plugInfos[plugInfo.sysInfo.alias] = plugInfo

# setup http server
ApiAiAssistant = require('actions-on-google').ApiAiAssistant
express = require('express')
basicAuth = require('express-basic-auth')
bodyParser = require('body-parser')
app = express()
app.set('port', (process.env.PORT || 7005))
app.use(basicAuth({
  challenge: true
  users:
    'dahlb': 'Password4'
    'api.ai': 'truiovcnreq43290vcFJKDS2:FD-'
}))
app.use(bodyParser.json({type: 'application/json'}))

app.get '/', (request, response) ->
  console.log 'get'
  response.send(plugInfos)

app.post '/', (request, response) ->
  console.log 'received request'
  assistant = new ApiAiAssistant
    request: request
    response: response
  actionMap = new Map()
  actionMap.set 'change_power_state', (assistant) ->
    deviceName = assistant.getArgument('device')
    console.log deviceName
    plug = plugs[deviceName]
    plug.getInfo().then (plugInfo) ->
      shouldPowerOn = assistant.getArgument('power_state') == 'on'
      isOn = plugInfo.sysInfo.relay_state == 1
      console.log "#{deviceName} is currently: #{isOn}, and is changing to #{shouldPowerOn}"
      if shouldPowerOn != isOn
        plug.setPowerState(shouldPowerOn).then ->
          assistant.tell("I am powering #{assistant.getArgument('power_state')} the #{deviceName}")
      else
        assistant.tell("#{deviceName} is already #{assistant.getArgument('power_state')}")
  assistant.handleRequest(actionMap)

server = app.listen app.get('port'), ->
  console.log('App listening on port %s', server.address().port)
  console.log('Press Ctrl+C to quit.')

