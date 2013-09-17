###*
@author Chad Engler <chad@pantherdev.com>
###

define 'Coffixi/core/Ellipse', ->

  ###*
  The Ellipse object can be used to specify a hit area for displayobjects

  @class Ellipse
  @constructor
  @param x {Number} The X coord of the upper-left corner of the framing rectangle of this ellipse
  @param y {Number} The Y coord of the upper-left corner of the framing rectangle of this ellipse
  @param width {Number} The overall height of this ellipse
  @param height {Number} The overall width of this ellipse
  ###
  class Ellipse
    constructor: (x, y, width, height) ->
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
      @property width
      @type Number
      @default 0
      ###
      @width = width or 0
      
      ###*
      @property height
      @type Number
      @default 0
      ###
      @height = height or 0

    ###*
    Creates a clone of this Ellipse instance

    @method clone
    @return {Ellipse} a copy of the ellipse
    ###
    clone: ->
      new PIXI.Ellipse(@x, @y, @width, @height)

    ###*
    Checks if the x, and y coords passed to this function are contained within this ellipse

    @method contains
    @param x {Number} The X coord of the point to test
    @param y {Number} The Y coord of the point to test
    @return {Boolean} if the x/y coords are within this ellipse
    ###
    contains: (x, y) ->
      return false  if @width <= 0 or @height <= 0
      
      #normalize the coords to an ellipse with center 0,0
      #and a radius of 0.5
      normx = ((x - @x) / @width) - 0.5
      normy = ((y - @y) / @height) - 0.5
      normx *= normx
      normy *= normy
      normx + normy < 0.25

    @getBounds: ->
      new PIXI.Rectangle(@x, @y, @width, @height)
