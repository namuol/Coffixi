###*
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/filters/FilterBlock', ->

  class FilterBlock
    constructor: (mask) ->
      @graphics = mask
      @visible = true
      @renderable = true
