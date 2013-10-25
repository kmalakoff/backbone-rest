_ = require 'underscore'

module.exports = (options, callback) ->
  test_parameters = _.extend options,
    database_url: '/test'
    schema:
      name: ['String', indexed: true]
      created_at: 'DateTime'
      updated_at: 'DateTime'
    sync: require('backbone-orm/memory_sync')
    embed: true

  require('../generators/all')(test_parameters, callback)
