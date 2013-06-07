###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/Stage', [
  './utils/Utils'
  './utils/Matrix'
  './DisplayObjectContainer'
], (
  Utils
  Matrix
  DisplayObjectContainer
) ->

  ###
  A Stage represents the root of the display tree. Everything connected to the stage is rendered
  @class Stage
  @extends DisplayObjectContainer
  @constructor
  @param backgroundColor {Number} the background color of the stage
  ###
  class Stage extends DisplayObjectContainer
    constructor: (backgroundColor) ->
      super

      @worldTransform = Matrix.mat3.create()
      @__childrenAdded = []
      @__childrenRemoved = []
      @childIndex = 0
      @stage = this
      
      @setBackgroundColor backgroundColor
      @worldVisible = true

    ###
    @method updateTransform
    @internal
    ###
    updateTransform: ->
      @worldAlpha = 1
      i = 0
      j = @children.length

      while i < j
        @children[i].updateTransform()
        i++

      if @dirty
        @dirty = false

    ###
    @method setBackgroundColor
    @param backgroundColor {Number}
    ###
    setBackgroundColor: (backgroundColor) ->
      @backgroundColor = backgroundColor or 0x000000
      @backgroundColorSplit = Utils.HEXtoRGB(@backgroundColor)
      @backgroundColorString = "#" + @backgroundColor.toString(16)

    __addChild: (child) ->
      child.stage = this
      if child.children
        i = 0

        while i < child.children.length
          @__addChild child.children[i]
          i++
      return

    __removeChild: (child) ->
      child.stage = `undefined`
      if child.children
        i = 0
        j = child.children.length

        while i < j
          @__removeChild child.children[i]
          i++
      return