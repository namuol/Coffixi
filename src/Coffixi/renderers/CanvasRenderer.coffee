###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/CanvasRenderer', [
  '../Sprite'
  '../textures/BaseTexture'
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
    constructor: (width, height, view, transparent, @textureFilter=BaseTexture.filterModes.LINEAR, @resizeFilter=BaseTexture.filterModes.LINEAR) ->
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
    __render: (stage) ->
      # update children if need be
      stage.__childrenAdded = []
      stage.__childrenRemoved = []

      # update textures if need be
      BaseTexture.texturesToUpdate = []
      @context.setTransform 1, 0, 0, 1, 0, 0
      stage.updateTransform()
      @context.setTransform 1, 0, 0, 1, 0, 0
      imgSmoothingEnabled = @textureFilter is not BaseTexture.filterModes.NEAREST
      @context.imageSmoothingEnabled = imgSmoothingEnabled
      @context.webkitImageSmoothingEnabled = imgSmoothingEnabled
      @context.mozImageSmoothingEnabled = imgSmoothingEnabled
      @context.oImageSmoothingEnabled = imgSmoothingEnabled

      if @view.style.backgroundColor isnt stage.backgroundColorString and not @transparent
        # update the background color
        @view.style.backgroundColor = stage.backgroundColorString
      @context.clearRect 0, 0, @width, @height
      @renderDisplayObject stage

    ###
    resizes the canvas view to the specified width and height
    @param width {Number} the new width of the canvas view
    @param height {Number] the new height of the canvas view
    @param scale {Number} the size of one game-pixel in device-pixels
    ###
    resize: (width, height, scale) ->
      width = Math.round width
      height = Math.round height
      @width = width
      @height = height
      @view.width = width
      @view.height = height

      imageSmoothingEnabled = (@resizeFilter != BaseTexture.filterModes.NEAREST)

      if imageSmoothingEnabled or scale == 1
        @_view = @view
        if imageSmoothingEnabled
          @_view.style.width = '100%'
        @render = @__render
      else
        if !@_view? or (@_view is @view)
          @_view = document.createElement 'canvas'
        @_view.width = Math.round @width * scale
        @_view.height = Math.round @height * scale
        _context = @_view.getContext '2d'
        _context.imageSmoothingEnabled = imageSmoothingEnabled
        _context.webkitImageSmoothingEnabled = imageSmoothingEnabled
        _context.mozImageSmoothingEnabled = imageSmoothingEnabled
        _context.oImageSmoothingEnabled = imageSmoothingEnabled
        w = @width
        h = @height
        s = scale
        ws = Math.round w*s
        hs = Math.round h*s
        @render = (stage) =>
          @__render(stage)
          if @_view.style.backgroundColor isnt stage.backgroundColorString and not @transparent
            @_view.style.backgroundColor = stage.backgroundColorString
          _context.clearRect 0,0, ws, hs
          _context.drawImage @view,
            0,0,
            w, h,
            0,0,
            ws, hs
    
    getView: -> @_view

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