###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/textures/RenderTexture', [
  '../Rectangle'
  '../utils/EventTarget'
  '../utils/Matrix'
  '../renderers/CanvasRenderer'
  '../renderers/GLESRenderer'
  './BaseTexture'
  './Texture'
], (
  Rectangle
  EventTarget
  Matrix
  CanvasRenderer
  GLESRenderer
  BaseTexture
  Texture
) ->

  GLESRenderGroup = GLESRenderer.GLESRenderGroup

  ###
  A RenderTexture is a special texture that allows any pixi displayObject to be rendered to it.

  __Hint__: All DisplayObjects (exmpl. Sprites) that renders on RenderTexture should be preloaded.
  Otherwise black rectangles will be drawn instead.

  RenderTexture takes snapshot of DisplayObject passed to render method. If DisplayObject is passed to render method, position and rotation of it will be ignored. For example:

  var renderTexture = new RenderTexture(800, 600);
  var sprite = Sprite.fromImage("spinObj_01.png");
  sprite.x = 800/2;
  sprite.y = 600/2;
  sprite.anchor.x = 0.5;
  sprite.anchor.y = 0.5;
  renderTexture.render(sprite);

  Sprite in this case will be rendered to 0,0 position. To render this sprite at center DisplayObjectContainer should be used:

  var doc = new DisplayObjectContainer();
  doc.addChild(sprite);
  renderTexture.render(doc);  // Renders to center of renderTexture

  @class RenderTexture
  @extends Texture
  @constructor
  @param width {Number}
  @param height {Number}
  ###
  class RenderTexture extends Texture
    constructor: (width, height, @textureFilter=BaseTexture.filterModes.LINEAR, @filterMode=BaseTexture.filterModes.LINEAR) ->
      # LOU TODO: Can we just call original Texture super?
      EventTarget.call this

      @width = width or 100
      @height = height or 100
      @indetityMatrix = Matrix.mat3.create()
      @frame = new Rectangle(0, 0, @width, @height)
      if GLESRenderer.gl
        @initGLES()
      else
        @initCanvas()

    initGLES: ->
      gl = GLESRenderer.gl
      @glFramebuffer = gl.createFramebuffer()
      gl.bindFramebuffer gl.FRAMEBUFFER, @glFramebuffer
      @glFramebuffer.width = @width
      @glFramebuffer.height = @height
      @baseTexture = new BaseTexture()
      @baseTexture.width = @width
      @baseTexture.height = @height
      @baseTexture._glTexture = gl.createTexture()
      gl.bindTexture gl.TEXTURE_2D, @baseTexture._glTexture
      gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, @width, @height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null
      filterMode = GLESRenderer.getGLFilterMode @filterMode
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filterMode
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filterMode
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
      @baseTexture.isRender = true
      gl.bindFramebuffer gl.FRAMEBUFFER, @glFramebuffer
      gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, @baseTexture._glTexture, 0
      
      # create a projection matrix..
      @projectionMatrix = Matrix.mat4.create()
      @projectionMatrix[5] = 2 / @height # * 0.5;
      @projectionMatrix[13] = -1
      @projectionMatrix[0] = 2 / @width
      @projectionMatrix[12] = -1
      
      # set the correct render function..
      @render = @renderGLES

    initCanvas: ->
      @renderer = new CanvasRenderer(@width, @height, null, 0)
      @baseTexture = new BaseTexture(@renderer.view)
      @frame = new Rectangle(0, 0, @width, @height)
      @render = @renderCanvas

    ###
    This function will draw the display object to the texture.
    @method render
    @param displayObject {DisplayObject}
    @param clear {Boolean} If true the texture will be cleared before the displayObject is drawn
    ###
    renderGLES: (displayObject, clear) ->
      gl = GLESRenderer.gl
      
      # enable the alpha color mask..
      gl.colorMask true, true, true, true
      gl.viewport 0, 0, @width, @height
      gl.bindFramebuffer gl.FRAMEBUFFER, @glFramebuffer
      if clear
        gl.clearColor 0, 0, 0, 0
        gl.clear gl.COLOR_BUFFER_BIT
      
      # THIS WILL MESS WITH HIT TESTING!
      children = displayObject.children
      
      #TODO -? create a new one??? dont think so!
      displayObject.worldTransform = Matrix.mat3.create() #sthis.indetityMatrix;
      i = 0
      j = children.length

      while i < j
        children[i].updateTransform()
        i++
      renderGroup = displayObject.__renderGroup
      if renderGroup
        if displayObject is renderGroup.root
          renderGroup.render @projectionMatrix
        else
          renderGroup.renderSpecific displayObject, @projectionMatrix
      else
        @renderGroup = new GLESRenderGroup(gl, @textureFilter)  unless @renderGroup
        @renderGroup.setRenderable displayObject
        @renderGroup.render @projectionMatrix

    renderCanvas: (displayObject, clear) ->
      children = displayObject.children
      displayObject.worldTransform = Matrix.mat3.create()
      i = 0
      j = children.length

      while i < j
        children[i].updateTransform()
        i++
      @renderer.context.clearRect 0, 0, @width, @height  if clear
      @renderer.renderDisplayObject displayObject
      BaseTexture.texturesToUpdate.push @baseTexture