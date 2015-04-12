p = require 'p-promise'

cache = require './cache'
db = require './db'

module.exports =
  connect: (pgConfig) -> db.init(pgConfig)
  query: (text, options) ->
    queried = p.defer()

    # caching disabled unless duration is specified
    options = options ? {
      duration: 0
    }

    execute = (params) ->
      db.prepare(text).then (stmt) ->
        stmt.execute(params).then (results) ->
          cache.store text, results.rows, options.duration if options.duration > 0
          queried.resolve results.rows
        .done()
      .done()

    # return results directly if cache hit, run query if cache miss
    cache.get(text).then(
      (results) -> queried.resolve results,
      (err) -> if err? then queried.reject err else execute()
    ).done()

    queried.promise