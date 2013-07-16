###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/core/Point', ->
  ###
  The Point object represents a location in a two-dimensional coordinate system, where x represents the horizontal axis and y represents the vertical axis.
  @class Point
  @constructor
  @param x {Number} position of the point
  @param y {Number} position of the point
  ###
  class Point
    constructor: (@x=0, @y=0) ->
      ###
      @property x
      @type Number
      @default 0
      ###
      
      ###
      @property y
      @type Number
      @default 0
      ###

    ###
    @method clone
    @return a copy of the point
    ###
    clone: ->
      new Point(@x, @y)

  return Point