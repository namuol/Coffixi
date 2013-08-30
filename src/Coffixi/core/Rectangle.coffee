###
@author Mat Groves http://matgroves.com/
###

define 'Coffixi/core/Rectangle', ->

  ###
  the Rectangle object is an area defined by its position, as indicated by its top-left corner point (x, y) and by its width and its height.

  @class Rectangle
  @constructor
  @param x {Number} The X coord of the upper-left corner of the rectangle
  @param y {Number} The Y coord of the upper-left corner of the rectangle
  @param width {Number} The overall wisth of this rectangle
  @param height {Number} The overall height of this rectangle
  ###
  class Rectangle
    constructor: (x, y, width, height) ->
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
      @property width
      @type Number
      @default 0
      ###
      @width = width or 0
      
      ###
      @property height
      @type Number
      @default 0
      ###
      @height = height or 0

    ###
    Creates a clone of this Rectangle

    @method clone
    @return {Rectangle} a copy of the rectangle
    ###
    clone: ->
      new Rectangle(@x, @y, @width, @height)

    ###
    Checks if the x, and y coords passed to this function are contained within this Rectangle

    @method contains
    @param x {Number} The X coord of the point to test
    @param y {Number} The Y coord of the point to test
    @return {Boolean} if the x/y coords are within this Rectangle
    ###
    contains: (x, y) ->
      return false  if @width <= 0 or @height <= 0
      x1 = @x
      if x >= x1 and x <= x1 + @width
        y1 = @y
        return true  if y >= y1 and y <= y1 + @height
      false
