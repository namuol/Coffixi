###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define [
  'Sprite'
  'textures/BaseTexture'
], (Sprite, BaseTexture) ->

  ###
  the CanvasRenderer draws the stage and all its content onto a 2d canvas. This renderer should be used for browsers that do not support webGL.
  Dont forget to add the view to your DOM or you will not see anything :)
  @class CanvasRenderer
  @constructor
  @param width {Number} the width of the canvas view
  @default 0
  @param height {Number} the height of the canvas view
  @default 0
  @param view {Canvas} the canvas to use as a view, optional
  @param transparent {Boolean} the transparency of the render view, default false
  @default false
  ###
  class CanvasRenderer
    constructor: (width, height, view, transparent) ->
      @transparent = transparent 
      ###
      The width of the canvas view
      @property width
      @type Number
      @default 800
      ###
      @width = width or 800
      
      ###
      The height of the canvas view
      @property height
      @type Number
      @default 600
      ###
      @height = height or 600
      @refresh = true
      
      ###
      The canvas element that the everything is drawn to
      @property view
      @type Canvas
      ###
      @view = view or document.createElement("canvas")
      
      # hack to enable some hardware acceleration!
      #this.view.style["transform"] = "translatez(0)";
      @view.width = @width
      @view.height = @height
      @count = 0
      
      ###
      The canvas context that the everything is drawn to
      @property context
      @type Canvas 2d Context
      ###
      @context = @view.getContext("2d")

    ###
    Renders the stage to its canvas view
    @method render
    @param stage {Stage} the Stage element to be rendered
    ###
    render: (stage) ->
      return
      # update children if need be
      stage.__childrenAdded = []
      stage.__childrenRemoved = []

      # update textures if need be
      BaseTexture.texturesToUpdate = []
      @context.setTransform 1, 0, 0, 1, 0, 0
      stage.updateTransform()
      @context.setTransform 1, 0, 0, 1, 0, 0
      
      if @view.style.backgroundColor isnt stage.backgroundColorString and not @transparent
        # update the background color
        @view.style.backgroundColor = stage.backgroundColorString
      @context.clearRect 0, 0, @width, @height
      @renderDisplayObject stage
      
      #as
      
      # run interaction!
      if stage.interactive
        
        #need to add some events!
        unless stage._interactiveEventsAdded
          stage._interactiveEventsAdded = true
          stage.interactionManager.setTarget this

    ###
    resizes the canvas view to the specified width and height
    @param the new width of the canvas view
    @param the new height of the canvas view
    ###
    resize: (width, height) ->
      @width = width
      @height = height
      @view.width = width
      @view.height = height

    ###
    @private
    ###
    renderDisplayObject: (displayObject) ->
      transform = displayObject.worldTransform
      context = @context
      context.globalCompositeOperation = "source-over"
      return if not displayObject.visible

      if displayObject instanceof Sprite
        frame = displayObject.texture.frame
        if frame
          context.globalAlpha = displayObject.worldAlpha
          context.setTransform transform[0], transform[3], transform[1], transform[4], transform[2], transform[5]
          context.drawImage displayObject.texture.baseTexture.source,
            frame.x,
            frame.y,
            frame.width,
            frame.height,
            (displayObject.anchor.x - displayObject.texture.trim.x) * -frame.width,
            (displayObject.anchor.y - displayObject.texture.trim.y) * -frame.height,
            displayObject.width,
            displayObject.height
      
      # render!
      i = 0
      while i < displayObject.children.length
        @renderDisplayObject displayObject.children[i]
        ++i

  return CanvasRenderer