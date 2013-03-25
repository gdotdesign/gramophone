class Panel
  constructor: (@base)->
    @handle = @base.querySelector '#handle'
    @handle.addEventListener 'click', @toggle

  open: ->
    @base.addClass 'open'
    @handle.removeClass 'icon-chevron-up'
    @handle.addClass 'icon-chevron-down'

  close: ->
    @base.removeClass 'open'
    @handle.addClass 'icon-chevron-up'
    @handle.removeClass 'icon-chevron-down'

  toggle: =>
    if @base.hasClass 'open' then @close() else @open()