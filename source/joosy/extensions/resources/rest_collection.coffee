#= require ./collection

#
# Collection of REST Resources
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
#
class Joosy.Resources.RESTCollection extends Joosy.Resources.Collection
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  #
  # Refetches the data from backend and triggers `changed`
  #
  # @param [Hash] options         See {Joosy.Resources.REST.find} for possible options
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    Success and Error callbacks to run `{ success: () ->, error: () -> }`
  #
  reload: (options={}, callback=false) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    @model.__query @model.collectionPath(options, @__source), 'GET', options.params, (data) =>
      @load data
      callback?(data)

  load: (args...) ->
    res = super(args...)
    @data.each (x) =>
      x.__source = @__source
    res