# Gramophone [![Build Status](https://travis-ci.org/gdotdesign/gramophone.png?branch=master)](https://travis-ci.org/gdotdesign/gramophone)

Gramophone is a Graphical [Intergation Testing](http://en.wikipedia.org/wiki/Integration_testing) utility, for web applications
and websites. It allows you to record a session (to a file) and play it back.

![screenshot](http://dl.dropbox.com/u/157845/gramophone/screenshot.png)

## Dependencies
  * [Node Webkit](https://github.com/rogerwang/node-webkit)
  * [PhantomJS](http://phantomjs.org/)
  * [CasperJS](http://casperjs.org/)

## Usage (v0.1.0)
  * Download [Gramophone](http://dl.dropbox.com/u/157845/gramophone/gramophone.nw) (gramophone.nw).
  * `nw gramophone.nw`

## Data Structure
Gramophone uses simple json for describing the steps:
```json
[
  {
    "type": "load",
    "url": "http://github.com"
  },
  {
    "type": "navigate",
    "url": "https://github.com/"
  },
  {
    "selector": ".header-actions > .button:nth-child(2)",
    "type": "assert-class",
    "value": "button"
  },
  ...
]
```

## Events
The following events can be recorded (there will be more):
  * Click - When click occurs
  * Change - When a change occurs (input, select, contenteditable)
  * Navigate - When a new page loads

## Assertions
The following assertions are supported (there will be more):
  * Text - Match for the given elements textContent
  * Element - Match for the given selector for an HTMLElement
  * Class - Match for a class in the HTMLElements classList
  * Attribute - Match for an attribute of the HTMLElement

## Continues Integration
Gramophone is developed with CI in mind.

It uses CasperJS with a script [tester.coffee](https://raw.github.com/gdotdesign/gramophone/master/public/js/tester.coffee).

To run a test file just run:

`casperjs tester.coffee --file=/path/to/file.json`

## Roadmap
Gramphone is in early stages, a lot of features will be added:
  * More assertions (position, size, wait, etc...)
  * More events (focus, blur, select, file upload, etc...)
  * Mocks for `alert`, `confirm`, `prompt`
  * Follow new windows (`window.open`)
  * Settings for assertions / events
  * Support for multiple scenarios / file
  * Use a simpler build / development system
  * Other adapters (basic phantomjs, zombiejs, selenium, etc...)
  * Integrations (Rails, Express, etc...)
  * And more...

## Issues and suggestions
If you found some bugs or have suggestions, open a ticket in [Issues](https://github.com/gdotdesign/gramophone/issues).

## Hacking
Gramophone is build with [Diamond](https://github.com/gdotdesign/diamond)

In order to start the application in development mode, follow these steps:
  * Clone Diamond `git clone https://github.com/gdotdesign/diamond`
  * Install dependencies `cd diamond && bundle`
  * Symlink the executable ```ln -sf `pwd`/bin/diamond /usr/local/bin/diamond```
  * Get the Node Webkit executable and symlink `nw`
  * Install PhantomJS and CasperJS
  * Start Gramophone `diamond nw`
