casper = require('casper').create
  viewportSize: {width: 1280, height: 800}

pass = (type, selector, value) ->
  casper.capture('../test.png')
  casper.test.pass [type,selector,value].join "|"

fail = (selector) ->
  casper.capture('../test.png')
  casper.test.fail "NOT FOUND|"+selector

data = JSON.parse(require('fs').read(casper.cli.options.file))
casper.start()
casper.userAgent 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17'
data.forEach (action) ->
  switch action.type
    when "load"
      casper.thenOpen action.url, ->
        @capture('../test.png')
    when "click"
      casper.waitForSelector action.selector, ->
        @click action.selector
        pass action.type, action.selector
      , -> fail action.selector
    when "focus"
      casper.waitForSelector action.selector, ->
        @evaluate "function(){ document.querySelector('#{action.selector}').focus() }"
        pass action.type, action.selector
      , -> fail action.selector
    when "blur"
      casper.waitForSelector action.selector, ->
        @evaluate "function(){ document.querySelector('#{action.selector}').blur() }"
        pass action.type, action.selector
      , -> fail action.selector
    when "change"
      casper.waitForSelector action.selector, ->
        action.selector = action.selector.replace(/\'/g,"\"")
        @evaluate "function(){ document.querySelector('#{action.selector}').#{action.property} = '#{action.value}' }"
        pass action.type, action.selector, action.value
      , -> fail action.selector
    when "navigate"
      casper.then ->
        m = !!@getCurrentUrl().match action.url
        @capture('../test.png')
        @test.assertEquals m, true, "URL|#{action.url}"
    when "assert-element"
      casper.waitForSelector action.selector, ->
        pass action.type, action.selector
      , -> fail action.selector
    when "assert-text"
      casper.waitForSelector action.selector, ->
        text = @evaluate("function(){return document.querySelector('#{action.selector}').textContent}")
        if action.value is text
          pass action.type, action.selector, action.value
        else
          fail action.selector
      , -> fail action.selector
    when "assert-class"
      casper.waitForSelector action.selector, ->
        result = @evaluate("function(){return document.querySelector('#{action.selector}').classList.contains('#{action.value}')}")
        if result
          pass action.type, action.selector, action.value
        else
          fail action.selector
      , -> fail action.selector
    when "assert-attribute"
      casper.waitForSelector action.selector, ->
        text = @evaluate("function(){return document.querySelector('#{action.selector}').getAttribute('#{action.attribute}')}")
        if action.value is text
          pass action.type, action.selector, action.value
        else
          fail action.selector
      , -> fail action.selector

casper.run ->
  require('fs').remove('../test.png')
  exitCode = if @test.getFailures().length is 0 then 0 else 1
  @exit exitCode