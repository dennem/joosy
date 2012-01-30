class Joosy.Resource.RESTCollection extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  data:  []
  pages: Object.extended()

  constructor: (@model, params={}) ->
    @params = Object.extended(params)

  # Clears the storage and attempts to import given JSON
  reset: (entities) ->
    @data  = @modelize entities
    @pages = Object.extended().merge { 1: @data }

    this

  # Clears the storage and gets new data from server
  fetch: (callback, options) ->
    @model.__ajax 'get', @model.__buildSource(params: @params), options, (data) =>
      @reset(data)
      callback?(this)

    this

  # Returns the subset for requested page. Requests with &page=x if not found localy.
  page: (number, callback=false) ->
    if @pages[number]?
      callback?(@pages[number])
      return this

    @model.__ajax 'get', @model.__buildSource(params: @params.merge(page: number)), {}, (data) =>
      @pages[number] = @modelize data

      @data = []
      @pages.keys().sort().each (x) =>
        @data.add @pages[x]

      callback?(@pages[number])

    this

  modelize: (collection) ->
    if collection instanceof Array
      collection.map (x) =>
        @model.create x
    else
      []