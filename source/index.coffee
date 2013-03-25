# @requires recorder.coffee

# Requires
{spawn} = require 'child_process'
nw      = require 'nw.gui'
fs      = require 'fs'

# Some utils
Element::hasClass    = (cls)-> @classList.contains cls
Element::removeClass = (cls)-> @classList.remove cls
Element::addClass    = (cls)-> @classList.add cls

# Init
window.addEventListener 'load', -> new Recorder()