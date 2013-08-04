util = require 'util'
_ = require 'underscore'
ORMUtils = require 'backbone-orm/lib/utils'
JSONUtils = require 'backbone-orm/lib/json_utils'

module.exports = class RESTController

  # TODO: add raw_json vs going through parse and toJSON on the models
  constructor: (app, options={}) ->
    @[key] = value for key, value of options
    @white_lists or= {}
    @templates or= {}

    app.get "#{@route}/:id", @_call(@show)
    app.get @route, @_call(@index)

    app.post @route, @_call(@create)
    app.put "#{@route}/:id", @_call(@update)

    app.del "#{@route}/:id", @_call(@destroy)
    app.del @route, @_call(@destroyByQuery)

    app.head "#{@route}/:id", @_call(@head)
    app.head @route, @_call(@headByQuery)

  index: (req, res) =>
    try
      cursor = @model_type.cursor(JSONUtils.parse(req.query))
      cursor = cursor.whiteList(@white_lists.index) if @white_lists.index
      cursor.toJSON (err, json) =>
        return res.send(404) if err
        return res.json({result: json}) if req.query.$count
        unless json
          if req.query.$one
            return res.status(404).send(error: "Model not found with id: #{req.query.id}")
          else
            res.json(json)

        if req.query.$page
          @render req, json.rows, (err, rendered_json) =>
            return res.status(500).send(error: err.toString()) if err
            json.rows = rendered_json
            res.json(json)
        else
          @render req, json, (err, rendered_json) =>
            return res.status(500).send(error: err.toString()) if err
            res.json(rendered_json)

    catch err
      res.status(500).send(error: err.toString())

  show: (req, res) =>
    try
      cursor = @model_type.cursor(req.params.id)
      cursor = cursor.whiteList(@white_lists.show) if @white_lists.show
      cursor.toJSON (err, json) =>
        return res.status(404).send(error: err.toString()) if err
        return res.status(404).send(error: "Model not found with id: #{req.params.id}") unless json
        json = _.pick(json, @white_lists.show) if @white_lists.show

        @render req, json, (err, json) =>
          return res.status(500).send(error: err.toString()) if err
          res.json(json)

    catch err
      res.status(500).send(error: err.toString())

  create: (req, res) =>
    try
      json = JSONUtils.parse(if @white_lists.create then _.pick(req.body, @white_lists.create) else req.body)
      model = new @model_type(@model_type::parse(json))
      model.save {}, {
        success: =>
          json = model.toJSON()
          json = _.pick(json, @white_lists.create) if @white_lists.create

          @render req, json, (err, json) =>
            return res.status(500).send(error: err.toString()) if err
            res.json(json)
        error: -> res.send(404)
      }
    catch err
      res.status(500).send(error: err.toString())

  update: (req, res) =>
    try
      json = JSONUtils.parse(if @white_lists.update then _.pick(req.body, @white_lists.update) else req.body)
      @model_type.find req.params.id, (err, model) =>
        return res.status(404).send(error: err.toString()) if err
        return res.status(404).send(error: "Model not found with id: #{req.params.id}") unless model
        model.save model.parse(json), {
          success: =>
            json = model.toJSON()
            json = _.pick(json, @white_lists.update) if @white_lists.update

            @render req, json, (err, json) =>
              return res.status(500).send(error: err.toString()) if err
              res.json(json)
          error: -> res.send(404)
        }
    catch err
      res.status(500).send(error: err.toString())

  destroy: (req, res) =>
    try
      # TODO: is there a way to do this without the model? eg. transaction only (with confirmation of existence) - HEAD?
      if req.params.id
        @model_type.find req.params.id, (err, model) =>
          return res.status(500).send(error: err.toString()) if err
          return res.status(404).send(error: "Model not found with id: #{req.params.id}") unless model
          model.destroy {
            success: -> res.status(200).send()
            error: -> res.status(500).send(error: "Model not deleted with id: #{req.params.id}")
          }
    catch err
      res.status(500).send(error: err.toString())

  destroyByQuery: (req, res) =>
    try
      @model_type.destroy JSONUtils.parse(req.query), (err) =>
        return res.status(500).send(error: err.toString()) if err
        res.send(200)
    catch err
      res.status(500).send(error: err.toString())

  head: (req, res) =>
    try
      @model_type.exists req.params.id, (err, exists) =>
        return res.status(500).send(error: err.toString()) if err
        res.send(if exists then 200 else 404)
    catch err
      res.status(500).send(error: err.toString())

  headByQuery: (req, res) =>
    try
      @model_type.exists JSONUtils.parse(req.query), (err, exists) =>
        return res.status(500).send(error: err.toString()) if err
        res.send(if exists then 200 else 404)
    catch err
      res.status(500).send(error: err.toString())

  render: (req, json, callback) ->
    template_name = req.query.$render or req.query.$template or @default_template
    return callback(null, json) unless template_name
    return callback(new Error "Unrecognized template: #{template_name}") unless template = @templates[template_name]

    options = (if @renderOptions then @renderOptions(req, template_name) else {})
    models = if _.isArray(json) then _.map(json, (model_json) => new @model_type(@model_type::parse(model_json))) else new @model_type(@model_type::parse(json))
    JSONUtils.renderTemplate models, template, options, callback

  _call: (fn) =>
    auths = if _.isArray(@auth) then @auth.slice() else if @auth then [@auth] else []
    auths.push(fn)
    return auths
