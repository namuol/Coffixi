###*
@author Chad Engler <chad@pantherdev.com>
###

define 'Coffixi/core/Circle', ->

  ###*
  The Circle object can be used to specify a hit area for displayobjects

  @class Circle
  @constructor
  @param x {Number} The X coord of the upper-left corner of the framing rectangle of this circle
  @param y {Number} The Y coord of the upper-left corner of the framing rectangle of this circle
  @param radius {Number} The radius of the circle
  ###
  class Circle
    constructor: (x, y, radius) ->
      ###*
      @property x
      @type Number
      @default 0
      ###
      @x = x or 0
      
      ###*
      @property y
      @type Number
      @default 0
      ###
      @y = y or 0
      
      ###*
      @property radius
      @type Number
      @default 0
      ###
      @radius = radius or 0

    ###*
    Creates a clone of this Circle instance

    @method clone
    @return {Circle} a copy of the polygon
    ###
    clone: ->
      new PIXI.Circle(@x, @y, @radius)


    ###*
    Checks if the x, and y coords passed to this function are contained within this circle

    @method contains
    @param x {Number} The X coord of the point to test
    @param y {Number} The Y coord of the point to test
    @return {Boolean} if the x/y coords are within this polygon
    ###
    contains: (x, y) ->
      return false  if @radius <= 0
      dx = (@x - x)
      dy = (@y - y)
      r2 = @radius * @radius
      dx *= dx
      dy *= dy
      dx + dy <= r2
