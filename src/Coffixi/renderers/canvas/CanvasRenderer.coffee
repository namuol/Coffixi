###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/canvas/CanvasRenderer', [
  'Coffixi/textures/Texture'
  'Coffixi/textures/BaseTexture'
  'Coffixi/display/Sprite'
  'Coffixi/extras/Strip'
  'Coffixi/extras/TilingSprite'
  'Coffixi/extras/CustomRenderable'
  'Coffixi/primitives/Graphics'
  './CanvasGraphics'
  'Coffixi/filters/FilterBlock'
], (
  Texture
  BaseTexture
  Sprite
  Strip
  TilingSprite
  CustomRenderable
  Graphics
  CanvasGraphics
  FilterBlock
) ->

  ###
  the CanvasRenderer draws the stage and all its content onto a 2d canvas. This renderer should be used for browsers that do not support webGL.
  Dont forget to add the view to your DOM or you will not see anything :)

  @class CanvasRenderer
  @constructor
  @param width=0 {Number} the width of the canvas view
  @param height=0 {Number} the height of the canvas view
  @param view {Canvas} the canvas to use as a view, optional
  @param transparent=false {Boolean} the transparency of the render view, default false
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
      
      ###
      The canvas element that the everything is drawn to
      
      @property view
      @type Canvas
      ###
      @view = view or document.createElement("canvas")
      
      ###
      The canvas context that the everything is drawn to
      @property context
      @type Canvas 2d Context
      ###
      @context = @view.getContext("2d")
      @refresh = true
      
      # hack to enable some hardware acceleration!
      #this.view.style["transform"] = "translatez(0)";
      @view.width = @width
      @view.height = @height
      @count = 0

    ###
    Renders the stage to its canvas view

    @method render
    @param stage {Stage} the Stage element to be rendered
    ###
    render: (stage) ->
      
      # update children if need be
      
      #stage.__childrenAdded = [];
      #stage.__childrenRemoved = [];
      
      # update textures if need be
      BaseTexture.texturesToUpdate = []
      BaseTexture.texturesToDestroy = []
      stage.updateTransform()
      
      # update the background color
      @view.style.backgroundColor = stage.backgroundColorString  if @view.style.backgroundColor isnt stage.backgroundColorString and not @transparent
      @context.setTransform 1, 0, 0, 1, 0, 0
      @context.clearRect 0, 0, @width, @height
      @renderDisplayObject stage
      
      #as
      
      # run interaction!
      if stage.interactive
        
        #need to add some events!
        unless stage._interactiveEventsAdded
          stage._interactiveEventsAdded = true
          stage.interactionManager.setTarget this
      
      # remove frame updates..
      Texture.frameUpdates = []  if Texture.frameUpdates.length > 0


    ###
    resizes the canvas view to the specified width and height

    @method resize
    @param width {Number} the new width of the canvas view
    @param height {Number} the new height of the canvas view
    ###
    resize: (width, height, viewportWidth, viewportHeight, viewportX, viewportY) ->
      @width = width
      @height = height
      
      @viewportX = viewportX ? 0
      @viewportY = viewportY ? 0

      @viewportWidth = viewportWidth ? @width
      @viewportHeight = viewportHeight ? @height
      
      @view.width = width
      @view.height = height
      
    getView: -> @view

    ###
    Renders a display object

    @method renderDisplayObject
    @param displayObject {DisplayObject} The displayObject to render
    @private
    ###
    renderDisplayObject: (displayObject) ->
      
      # no loger recurrsive!
      transform = undefined
      context = @context
      context.globalCompositeOperation = "source-over"
      
      # one the display object hits this. we can break the loop	
      testObject = displayObject.last._iNext
      displayObject = displayObject.first
      loop
        transform = displayObject.worldTransform
        unless displayObject.visible
          displayObject = displayObject.last._iNext
          break  if displayObject is testObject
          continue
        unless displayObject.renderable
          displayObject = displayObject._iNext
          break  if displayObject is testObject
          continue
        if displayObject instanceof Sprite
          frame = displayObject.texture.frame
          if frame
            context.globalAlpha = displayObject.worldAlpha
            context.setTransform transform[0], transform[3], transform[1], transform[4], transform[2], transform[5]
            context.drawImage displayObject.texture.baseTexture.source, frame.x, frame.y, frame.width, frame.height, (displayObject.anchor.x) * -frame.width, (displayObject.anchor.y) * -frame.height, frame.width, frame.height
        else if displayObject instanceof Strip
          context.setTransform transform[0], transform[3], transform[1], transform[4], transform[2], transform[5]
          @renderStrip displayObject
        else if displayObject instanceof TilingSprite
          context.setTransform transform[0], transform[3], transform[1], transform[4], transform[2], transform[5]
          @renderTilingSprite displayObject
        else if displayObject instanceof CustomRenderable
          displayObject.renderCanvas this
        else if displayObject instanceof Graphics
          context.setTransform transform[0], transform[3], transform[1], transform[4], transform[2], transform[5]
          CanvasGraphics.renderGraphics displayObject, context
        else if displayObject instanceof FilterBlock
          if displayObject.open
            context.save()
            cacheAlpha = displayObject.mask.alpha
            maskTransform = displayObject.mask.worldTransform
            context.setTransform maskTransform[0], maskTransform[3], maskTransform[1], maskTransform[4], maskTransform[2], maskTransform[5]
            displayObject.mask.worldAlpha = 0.5
            context.worldAlpha = 0
            CanvasGraphics.renderGraphicsMask displayObject.mask, context
            
            #		context.fillStyle = 0xFF0000;
            #	context.fillRect(0, 0, 200, 200);
            context.clip()
            displayObject.mask.worldAlpha = cacheAlpha
          
          #context.globalCompositeOperation = 'lighter';
          else
            
            #context.globalCompositeOperation = 'source-over';
            context.restore()
        
        #	count++
        displayObject = displayObject._iNext
        break  if displayObject is testObject

    ###
    Renders a flat strip

    @method renderStripFlat
    @param strip {Strip} The Strip to render
    @private
    ###
    renderStripFlat: (strip) ->
      context = @context
      verticies = strip.verticies
      uvs = strip.uvs
      length = verticies.length / 2
      @count++
      context.beginPath()
      i = 1

      while i < length - 2
        
        # draw some triangles!
        index = i * 2
        x0 = verticies[index]
        x1 = verticies[index + 2]
        x2 = verticies[index + 4]
        y0 = verticies[index + 1]
        y1 = verticies[index + 3]
        y2 = verticies[index + 5]
        context.moveTo x0, y0
        context.lineTo x1, y1
        context.lineTo x2, y2
        i++
      context.fillStyle = "#FF0000"
      context.fill()
      context.closePath()

    ###
    Renders a tiling sprite

    @method renderTilingSprite
    @param sprite {TilingSprite} The tilingsprite to render
    @private
    ###
    renderTilingSprite: (sprite) ->
      context = @context
      context.globalAlpha = sprite.worldAlpha
      sprite.__tilePattern = context.createPattern(sprite.texture.baseTexture.source, "repeat")  unless sprite.__tilePattern
      context.beginPath()
      tilePosition = sprite.tilePosition
      tileScale = sprite.tileScale
      
      # offset
      context.scale tileScale.x, tileScale.y
      context.translate tilePosition.x, tilePosition.y
      context.fillStyle = sprite.__tilePattern
      context.fillRect -tilePosition.x, -tilePosition.y, sprite.width / tileScale.x, sprite.height / tileScale.y
      context.scale 1 / tileScale.x, 1 / tileScale.y
      context.translate -tilePosition.x, -tilePosition.y
      context.closePath()

    ###
    Renders a strip

    @method renderStrip
    @param strip {Strip} The Strip to render
    @private
    ###
    renderStrip: (strip) ->
      context = @context
      
      #context.globalCompositeOperation = 'lighter';
      # draw triangles!!
      verticies = strip.verticies
      uvs = strip.uvs
      length = verticies.length / 2
      @count++
      i = 1

      while i < length - 2
        
        # draw some triangles!
        index = i * 2
        x0 = verticies[index]
        x1 = verticies[index + 2]
        x2 = verticies[index + 4]
        y0 = verticies[index + 1]
        y1 = verticies[index + 3]
        y2 = verticies[index + 5]
        u0 = uvs[index] * strip.texture.width
        u1 = uvs[index + 2] * strip.texture.width
        u2 = uvs[index + 4] * strip.texture.width
        v0 = uvs[index + 1] * strip.texture.height
        v1 = uvs[index + 3] * strip.texture.height
        v2 = uvs[index + 5] * strip.texture.height
        context.save()
        context.beginPath()
        context.moveTo x0, y0
        context.lineTo x1, y1
        context.lineTo x2, y2
        context.closePath()
        
        #	context.fillStyle = "white"//rgb(1, 1, 1,1));
        #	context.fill();
        context.clip()
        
        # Compute matrix transform
        delta = u0 * v1 + v0 * u2 + u1 * v2 - v1 * u2 - v0 * u1 - u0 * v2
        delta_a = x0 * v1 + v0 * x2 + x1 * v2 - v1 * x2 - v0 * x1 - x0 * v2
        delta_b = u0 * x1 + x0 * u2 + u1 * x2 - x1 * u2 - x0 * u1 - u0 * x2
        delta_c = u0 * v1 * x2 + v0 * x1 * u2 + x0 * u1 * v2 - x0 * v1 * u2 - v0 * u1 * x2 - u0 * x1 * v2
        delta_d = y0 * v1 + v0 * y2 + y1 * v2 - v1 * y2 - v0 * y1 - y0 * v2
        delta_e = u0 * y1 + y0 * u2 + u1 * y2 - y1 * u2 - y0 * u1 - u0 * y2
        delta_f = u0 * v1 * y2 + v0 * y1 * u2 + y0 * u1 * v2 - y0 * v1 * u2 - v0 * u1 * y2 - u0 * y1 * v2
        context.transform delta_a / delta, delta_d / delta, delta_b / delta, delta_e / delta, delta_c / delta, delta_f / delta
        context.drawImage strip.texture.baseTexture.source, 0, 0
        context.restore()
        i++

    #	context.globalCompositeOperation = 'source-over';	
