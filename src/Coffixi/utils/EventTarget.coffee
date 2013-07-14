###
https://github.com/mrdoob/eventtarget.js/
THankS mr DOob!
###

define 'Coffixi/utils/EventTarget', [
  'Coffixi/utils/Module'
], (
  Module
) ->
  class EventTarget extends Module
    constructor: ->
      listeners = {}
      @addEventListener = @on = (type, listener) ->
        listeners[type] = []  if listeners[type] is `undefined`
        listeners[type].push listener  if listeners[type].indexOf(listener) is -1

      @dispatchEvent = @emit = (event) ->
        for listener of listeners[event.type]
          listeners[event.type][listener] event

      @removeEventListener = @off = (type, listener) ->
        index = listeners[type].indexOf(listener)
        listeners[type].splice index, 1  if index isnt -1

  return EventTarget