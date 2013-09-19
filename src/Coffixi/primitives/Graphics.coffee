###*
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/primitives/Graphics', [
  'Coffixi/display/DisplayObjectContainer'
  'Coffixi/core/RenderTypes'
], (
  DisplayObjectContainer
  RenderTypes
) ->

  ###*
  The Graphics class contains a set of methods that you can use to create primitive shapes and lines.
  It is important to know that with the webGL renderer only simple polys can be filled at this stage
  Complex polys will not be filled. Heres an example of a complex poly: http://www.goodboydigital.com/wp-content/uploads/2013/06/complexPolygon.png

  @class Graphics
  @extends DisplayObjectContainer
  @constructor
  ###
  class Graphics extends DisplayObjectContainer
    __renderType: RenderTypes.GRAPHICS
    # SOME TYPES:
    @POLY: 0
    @RECT: 1
    @CIRC: 2
    @ELIP: 3

    constructor: ->
      super

      @renderable = true
      
      ###*
      The alpha of the fill of this graphics object
      
      @property fillAlpha
      @type Number
      ###
      @fillAlpha = 1
      
      ###*
      The width of any lines drawn
      
      @property lineWidth
      @type Number
      ###
      @lineWidth = 0
      
      ###*
      The color of any lines drawn
      
      @property lineColor
      @type String
      ###
      @lineColor = 'black'
      
      ###*
      Graphics data
      
      @property graphicsData
      @type Array
      @private
      ###
      @graphicsData = []
      
      ###*
      Current path
      
      @property currentPath
      @type Object
      @private
      ###
      @currentPath = points: []

    ###*
    Specifies a line style used for subsequent calls to Graphics methods such as the lineTo() method or the drawCircle() method.

    @method lineStyle
    @param lineWidth {Number} width of the line to draw, will update the object's stored style
    @param color {Number} color of the line to draw, will update the object's stored style
    @param alpha {Number} alpha of the line to draw, will update the object's stored style
    ###
    lineStyle: (lineWidth, color, alpha) ->
      @graphicsData.pop()  if @currentPath.points.length is 0
      @lineWidth = lineWidth or 0
      @lineColor = color or 0
      @lineAlpha = (if (alpha is `undefined`) then 1 else alpha)
      @currentPath =
        lineWidth: @lineWidth
        lineColor: @lineColor
        lineAlpha: @lineAlpha
        fillColor: @fillColor
        fillAlpha: @fillAlpha
        fill: @filling
        points: []
        type: Graphics.POLY

      @graphicsData.push @currentPath

    ###*
    Moves the current drawing position to (x, y).

    @method moveTo
    @param x {Number} the X coord to move to
    @param y {Number} the Y coord to move to
    ###
    moveTo: (x, y) ->
      @graphicsData.pop()  if @currentPath.points.length is 0
      @currentPath = @currentPath =
        lineWidth: @lineWidth
        lineColor: @lineColor
        lineAlpha: @lineAlpha
        fillColor: @fillColor
        fillAlpha: @fillAlpha
        fill: @filling
        points: []
        type: Graphics.POLY

      @currentPath.points.push x, y
      @graphicsData.push @currentPath

    ###*
    Draws a line using the current line style from the current drawing position to (x, y);
    the current drawing position is then set to (x, y).

    @method lineTo
    @param x {Number} the X coord to draw to
    @param y {Number} the Y coord to draw to
    ###
    lineTo: (x, y) ->
      @currentPath.points.push x, y
      @dirty = true

    ###*
    Specifies a simple one-color fill that subsequent calls to other Graphics methods
    (such as lineTo() or drawCircle()) use when drawing.

    @method beginFill
    @param color {uint} the color of the fill
    @param alpha {Number} the alpha
    ###
    beginFill: (color, alpha) ->
      @filling = true
      @fillColor = color or 0
      @fillAlpha = alpha ? 1

    ###*
    Applies a fill to the lines and shapes that were added since the last call to the beginFill() method.

    @method endFill
    ###
    endFill: ->
      @filling = false
      @fillColor = null
      @fillAlpha = 1

    ###*
    @method drawRect

    @param x {Number} The X coord of the top-left of the rectangle
    @param y {Number} The Y coord of the top-left of the rectangle
    @param width {Number} The width of the rectangle
    @param height {Number} The height of the rectangle
    ###
    drawRect: (x, y, width, height) ->
      @graphicsData.pop()  if @currentPath.points.length is 0
      @currentPath =
        lineWidth: @lineWidth
        lineColor: @lineColor
        lineAlpha: @lineAlpha
        fillColor: @fillColor
        fillAlpha: @fillAlpha
        fill: @filling
        points: [x, y, width, height]
        type: Graphics.RECT

      @graphicsData.push @currentPath
      @dirty = true

    ###*
    Draws a circle.

    @method drawCircle
    @param x {Number} The X coord of the center of the circle
    @param y {Number} The Y coord of the center of the circle
    @param radius {Number} The radius of the circle
    ###
    drawCircle: (x, y, radius) ->
      @graphicsData.pop()  if @currentPath.points.length is 0
      @currentPath =
        lineWidth: @lineWidth
        lineColor: @lineColor
        lineAlpha: @lineAlpha
        fillColor: @fillColor
        fillAlpha: @fillAlpha
        fill: @filling
        points: [x, y, radius, radius]
        type: Graphics.CIRC

      @graphicsData.push @currentPath
      @dirty = true

    ###*
    Draws an elipse.

    @method drawElipse
    @param x {Number}
    @param y {Number}
    @param width {Number}
    @param height {Number}
    ###
    drawElipse: (x, y, width, height) ->
      @graphicsData.pop()  if @currentPath.points.length is 0
      @currentPath =
        lineWidth: @lineWidth
        lineColor: @lineColor
        lineAlpha: @lineAlpha
        fillColor: @fillColor
        fillAlpha: @fillAlpha
        fill: @filling
        points: [x, y, width, height]
        type: Graphics.ELIP

      @graphicsData.push @currentPath
      @dirty = true

    ###*
    Clears the graphics that were drawn to this Graphics object, and resets fill and line style settings.

    @method clear
    ###
    clear: ->
      @lineWidth = 0
      @filling = false
      @dirty = true
      @clearDirty = true
      @graphicsData = []
