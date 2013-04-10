###
@author Mat Groves http://matgroves.com/
###

define 'Coffixi/Rectangle', ->
  ###
  the Rectangle object is an area defined by its position, as indicated by its top-left corner point (x, y) and by its width and its height.
  @class Rectangle
  @constructor
  @param x {Number} position of the rectangle
  @param y {Number} position of the rectangle
  @param width {Number} of the rectangle
  @param height {Number} of the rectangle
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
    @method clone
    @return a copy of the rectangle
    ###
    @clone: ->
      new Rectangle(@x, @y, @width, @height)

  return Rectangle