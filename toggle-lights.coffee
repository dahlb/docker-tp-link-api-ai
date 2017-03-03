#!./node_modules/.bin/coffee

Hs100Api = require('hs100-api')

client = new Hs100Api.Client()

client.startDiscovery().on 'plug-new', (plug) ->
  plug.getInfo().then (plugInfo) ->
    if plugInfo.sysInfo.alias == 'Living Room'
#      console.log plugInfo
      console.log 'turning off'
      isOn = plugInfo.sysInfo.relay_state == 1
      plug.setPowerState(!isOn).then ->
        process.exit()
