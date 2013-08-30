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
    constructor: (x, y) ->
      ###
      @property x
      @type Number
      @default 0
      ###
      @x = x or 0
      
      ###
      @property y
      @type Number
      @default 0
      ###
      @y = y or 0


    ###
    Creates a clone of this point

    @method clone
    @return {Point} a copy of the point
    ###
    clone: ->
      new Point(@x, @y)

  return Point