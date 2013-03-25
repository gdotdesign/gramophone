# Logger
class Log
  constructor: (@base) ->

  # TODO: Template this
  log: (action)->
    div = document.createElement('tr')

    status = document.createElement('td')
    status.classList.add 'status'
    status.classList.add action.status
    status.textContent = action.type

    msg = document.createElement('td')
    msg.classList.add 'text'
    msg.textContent = action.selector or action.url or action.text

    value = document.createElement('td')
    value.classList.add 'text'
    value.textContent = action.value or ''

    div.appendChild status
    div.appendChild msg
    div.appendChild value

    @base.insertBefore div, @base.firstChild

  empty: ->
    @base.innerHTML = ""