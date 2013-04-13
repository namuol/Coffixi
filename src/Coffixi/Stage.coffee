###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/Stage', [
  './utils/Utils'
  './utils/Matrix'
  './InteractionManager'
  './DisplayObjectContainer'
], (Utils, Matrix, InteractionManager, DisplayObjectContainer) ->

  ###
  A Stage represents the root of the display tree. Everything connected to the stage is rendered
  @class Stage
  @extends DisplayObjectContainer
  @constructor
  @param backgroundColor {Number} the background color of the stage
  @param interactive {Boolean} enable / disable interaction (default is false)
  ###
  class Stage extends DisplayObjectContainer
    constructor: (backgroundColor, interactive) ->
      super

      @worldTransform = Matrix.mat3.create() #.//identity();
      @__childrenAdded = []
      @__childrenRemoved = []
      @childIndex = 0
      @stage = this
      
      # interaction!
      @interactive = !!interactive
      @interactionManager = new InteractionManager(this)
      @setBackgroundColor backgroundColor

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
        
        # update interactive!
        @interactionManager.dirty = true

    ###
    @method setBackgroundColor
    @param backgroundColor {Number}
    ###
    setBackgroundColor: (backgroundColor) ->
      @backgroundColor = backgroundColor or 0x000000
      @backgroundColorSplit = Utils.HEXtoRGB(@backgroundColor)
      @backgroundColorString = "#" + @backgroundColor.toString(16)

    # LOU TODO: Remove this along with Interactive stuff. It looks like this is only used there.
    __addChild: (child) ->
      @dirty = true  if child.interactive
      child.stage = this
      if child.children
        i = 0

        while i < child.children.length
          @__addChild child.children[i]
          i++

    __removeChild: (child) ->
      @dirty = true  if child.interactive
      @__childrenRemoved.push child
      child.stage = `undefined`
      if child.children
        i = 0
        j = child.children.length

        while i < j
          @__removeChild child.children[i]
          i++

  return Stage