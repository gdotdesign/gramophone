# @requires panel.coffee
# @requires logger.coffee

Events =
  'click': (e, selector)->
    return if e.target.getAttribute('id') is '__gph_context__'
    return if e.target.parentNode.getAttribute('id') is '__gph_context__'
    @doc.querySelector('#__gph_context__').style.display = 'none'
    @push {selector: selector, type: 'click'}
  'change': (e, selector)->
    if e.target.value
      value = e.target.value
      prop = 'value'
    else
      value = e.target.textContent
      prop = 'textContent'
    @push {selector: selector, type: 'change', value: value, property: prop}
  ###
  'focus': (e, selector) ->
    @push {selector: selector, type: 'focus'}
  'blur': (e,selector) ->
    @push {selector: selector, type: 'blur'}
  ###

Assertions =
  'assert-text': (selector)->
    @push {selector: selector, type: 'assert-text', value: @target.textContent }
  'assert-element': (selector)->
    @push {selector: selector, type: 'assert-element'}
  'assert-class': (selector)->
    cls = prompt('class')
    return unless cls
    @win2.focus()
    @push {selector: selector, type: 'assert-class', value: cls}
  'assert-attribute': (selector)->
    attr = prompt('attribute')
    return unless attr
    value = prompt('value')
    return unless value
    @win2.focus()
    @push {selector: selector, type: 'assert-attribute', value: value, attribute: attr}

class Recorder
  constructor: (@frame)->
    @started = false

    # Save and restore window position
    win = nw.Window.get()
    win.on "close", ->
      localStorage.x = win.x
      localStorage.y = win.y
      localStorage.width = win.width
      localStorage.height = win.height
      @close true
    if localStorage.width and localStorage.height
      win.resizeTo parseInt(localStorage.width), parseInt(localStorage.height)
      win.moveTo parseInt(localStorage.x), parseInt(localStorage.y)
    win.show()

    @panel = new Panel document.querySelector('#panel')
    @logger = new Log document.querySelector('#log tbody')
    @preview = document.querySelector('#preview')

    # When the open dialog changes start playing
    @openDialog = document.querySelector('#open')
    @openDialog.addEventListener 'change', (e)=>
      @play @openDialog.value
      @openDialog.value = ""

    # When the save dialog changes start recording
    @saveDialog = document.querySelector('#save')
    @saveDialog.addEventListener 'change', (e)=>
      @record @openDialog.value

    @recordButton = document.querySelector('#record')
    @recordButton.addEventListener 'click', =>
      return if @recordButton.classList.contains('disabled')
      @saveDialog.click()

    @stopButton = document.querySelector('#stop')
    @stopButton.addEventListener 'click', =>
      return if @stopButton.classList.contains('disabled')
      @stop()

    @playButton = document.querySelector('#play')
    @playButton.addEventListener 'click', =>
      return if @playButton.classList.contains('disabled')
      @openDialog.click()

  push: (action)->
    @actions.push action
    @logger.log action

  # Idle state "play, record" enabled "stop" disabled
  # restores icons on buttons
  idle: (type)->
    @stopButton.classList.add('disabled')
    @recordButton.classList.remove('disabled')
    @playButton.classList.remove('disabled')

    @preview.style.display = 'none'
    icon = if type is 'play' then 'icon-play' else 'icon-circle'
    button = if type is 'play' then @playButton else @recordButton
    button.querySelector('i').classList.add icon
    button.querySelector('i').classList.remove 'icon-spinner'
    button.querySelector('i').classList.remove 'icon-spin'

  # In progress state "stop" enabled "play, record" disabled
  # adds spinner to relevant button
  inProgress: (type)->
    @stopButton.classList.remove('disabled')
    @recordButton.classList.add('disabled')
    @playButton.classList.add('disabled')

    @preview.style.display = 'block' if type is 'play'
    icon = if type is 'play' then 'icon-play' else 'icon-circle'
    button = if type is 'play' then @playButton else @recordButton
    button.querySelector('i').classList.remove icon
    button.querySelector('i').classList.add 'icon-spinner'
    button.querySelector('i').classList.add 'icon-spin'

    @logger.empty()
    @panel.open()

  # Updates image captured from caster js
  updateImage: ->
    unless fs.existsSync('../test.png')
      @preview.innerHTML = ""
      return
    try
      data = fs.readFileSync('../test.png','base64')
      img = document.createElement 'img'
      img.src = "data:image/png;base64,"+data
      # Clear preview after reading the file
      @preview.innerHTML = ""
      @preview.appendChild img

  play: (path)->
    return if path is ''
    # Set playing state
    @playing = true
    @inProgress 'play'

    # Start casper js with file path
    @casper = spawn 'casperjs',[process.cwd()+'/js/tester.coffee','--file='+path]
    @casper.stdout.on 'data', (data)=>
      @updateImage()
      # Only log pass / fail messages
      if (m = data.toString().match(/(PASS|FAIL)/))
        status = m[0].toLowerCase()
        # Remove color codes
        text = data.toString().replace(/\[.*?m/g, '').split(m[0]+" ").pop()
        [type,selector,value] = text.split("|")
        # Log message
        @logger.log type: type, selector: selector, value: value, status: status
    @casper.on 'close', (code)=>
      # Set idle state
      @playing = false
      @idle 'play'

  # Adds index for selector if multiple other elements match
  # the same selector
  addIndexIfNeeded: (selector, el)->
    return selector if @doc.querySelectorAll(selector).length is 1
    index = null
    for item,i in el.parentNode.children
      if item is el
        index = i+1
    selector += ":nth-child("+index+")"

  # Create selector for target element
  createSelector: (target, affix)->
    # When we reach top return affix
    return affix if target.tagName is "HTML"

    # Get selector material
    id = target.getAttribute('id')
    classes = ''
    if target.classList.length > 0
      for cls in target.classList
        classes = "."+cls
    tag = target.tagName.toLowerCase()
    name = target.getAttribute('name')

    if id
      # Check for unique id else go up the tree
      if @doc.querySelectorAll("##{id}").length is 1
        selector = "##{id}"
      else
        selector = @createSelector(target.parentNode, "##{id}")
    else if classes
      # Check for unique class else go up the tree
      if @doc.querySelectorAll(classes).length > 1
        selector = @createSelector(target.parentNode, classes)
      else
        selector = classes
    else if name
      # Check for unqiue name attribute esle go up the tree
      if @doc.querySelectorAll("[name='#{name}']").length > 1
        selector = @createSelector(target.parentNode, "[name='#{name}']")
      else
        selector = "[name='#{name}']"
    else
      # Else match by tag
      selector = @createSelector(target.parentNode, tag)
    # Add index if needed (nth-child)
    selector = @addIndexIfNeeded(selector, target)
    if affix
      selector+" > "+affix
    else selector

  # This handles context menu
  # TODO: replace with NodeWebkit menu when fixed
  # ISSUE: ....
  handleContextMenu: (e) =>
    if e.target.tagName is 'LI'
      @doc.querySelector('#__gph_context__').style.display = 'none'
      selector = @createSelector @target
      Assertions[e.target.getAttribute('action')]?.call @, selector

  # Injects context menu into the current document
  injectContextMenu: (win)->
    contextMenu = document.querySelector('#__gph_context__').cloneNode(true)
    contextMenu.addEventListener 'click', @handleContextMenu, true
    style = document.querySelector('#__gph_style__').cloneNode(true)
    @doc.body.appendChild style
    @doc.body.appendChild contextMenu

  record: ->
    src = prompt('url')
    return unless src

    # Set state
    @inProgress 'record'
    @actions = []
    @started = true
    # Push first action (always load)
    @push {type: 'load', url: src}

    # Open window
    win = window.open(src)
    @win2 = nw.Window.get(win)
    @win2.on 'loaded', =>
      # When loaded show
      @win2.show()
      @doc = win.document

      # This is needed for because ajax requests
      # trigger this event
      return if @doc.__gph_loaded__
      @doc.__gph_loaded__ = true

      # Push navigation step
      @push {type: 'navigate', url: win.location.href.replace(/(\?|#).*$/,'')}

      # Setup events and context menu
      @injectContextMenu()
      @addEvents()

  # Stops the recording or playing
  stop: ->
    if @playing
      @idle 'play'
      @playing = false
      @casper.kill('SIGKILL')
    else
      @idle 'record'
      @started = false
      # Save the file on stop
      # TODO: move this somwhere else
      fs.writeFileSync(@saveDialog.value,JSON.stringify(@actions,null,"  "))

  # Setup events for document
  addEvents: ->
    @doc.addEventListener 'contextmenu', (e)=>
      @target = e.target
      ctx = @doc.querySelector('#__gph_context__')
      ctx.style.top = e.pageY+"px"
      ctx.style.left = e.pageX+"px"
      ctx.style.display = 'block'
    , true

    for event, fn of Events
      do (event,fn) =>
        @doc.addEventListener event, (e) =>
          return unless @started
          selector = @createSelector e.target
          fn.call @, e, selector
        , true