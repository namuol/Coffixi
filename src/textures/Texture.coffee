###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define [
  'utils/EventTarget'
  'textures/BaseTexture'
  'Rectangle'
  'Point'
], (EventTarget, BaseTexture, Rectangle, Point) ->
  ###
  A texture stores the information that represents an image or part of an image. It cannot be added to the display list directly. To do this use Sprite. If no frame is provided then the whole image is used
  @class Texture
  @extends EventTarget
  @constructor
  @param baseTexture {BaseTexture}
  @param frmae {Rectangle}
  ###
  class Texture extends EventTarget
    @cache: {}
    constructor: (baseTexture, frame) ->
      super

      if not frame
        @noFrame = true
        frame = new Rectangle(0, 0, 1, 1)

      # LOU TODO: What is this? Is it used? Should I remove it?
      @trim = new Point()
      
      ###
      The base texture of this texture
      @property baseTexture
      @type BaseTexture
      ###
      @baseTexture = baseTexture
      
      ###
      The frame specifies the region of the base texture that this texture uses
      @property frame
      @type #Rectangle
      ###
      @frame = frame
      @scope = this
      if baseTexture.hasLoaded
        frame = new Rectangle(0, 0, baseTexture.width, baseTexture.height)  if @noFrame
        @setFrame frame
      else
        scope = this
        baseTexture.addEventListener "loaded", ->
          scope.onBaseTextureLoaded()

    onBaseTextureLoaded: (event) ->
      baseTexture = @baseTexture
      baseTexture.removeEventListener "loaded", @onLoaded
      @frame = new Rectangle(0, 0, baseTexture.width, baseTexture.height)  if @noFrame
      @noFrame = false
      @width = @frame.width
      @height = @frame.height
      @scope.dispatchEvent
        type: "update"
        content: this

    ###
    Specifies the rectangle region of the baseTexture
    @method setFrame
    @param frame {Rectangle}
    ###
    setFrame: (frame) ->
      @frame = frame
      @width = frame.width
      @height = frame.height
      if frame.x + frame.width > @baseTexture.width or frame.y + frame.height > @baseTexture.height
        throw new Error("Texture Error: frame does not fit inside the base Texture dimensions " + this)

    ###
    Helper function that returns a texture based on an image url
    If the image is not in the texture cache it will be  created and loaded
    @static
    @method fromImage
    @param imageUrl {String} The image url of the texture
    @return Texture
    ###
    @fromImage: (imageUrl, crossorigin) ->
      texture = Texture.cache[imageUrl]
      unless texture
        baseTexture = BaseTexture.cache[imageUrl]
        unless baseTexture
          image = new Image
          image.crossOrigin = ""  if crossorigin
          image.src = imageUrl
          baseTexture = new BaseTexture(image)
          BaseTexture.cache[imageUrl] = baseTexture
        texture = new Texture(baseTexture)
        Texture.cache[imageUrl] = texture
      texture

    ###
    Helper function that returns a texture based on a frame id
    If the frame id is not in the texture cache an error will be thrown
    @method fromFrame
    @param frameId {String} The frame id of the texture
    @return Texture
    ###
    @fromFrame: (frameId) ->
      texture = Texture.cache[frameId]
      throw new Error("The frameId '" + frameId + "' does not exist in the texture cache " + this)  unless texture
      texture

    ###
    Helper function that returns a texture based on a canvas element
    If the canvas is not in the texture cache it will be  created and loaded
    @static
    @method fromCanvas
    @param canvas {Canvas} The canvas element source of the texture
    @return Texture
    ###
    @fromCanvas: (canvas) ->
      
      # create a canvas id??
      texture = Texture.cache[canvas]
      unless texture
        baseTexture = BaseTexture.cache[canvas]
        unless baseTexture
          baseTexture = new BaseTexture(canvas)
          BaseTexture.cache[canvas] = baseTexture
        texture = new Texture(baseTexture)
        Texture.cache[canvas] = texture
      texture

    ###
    Adds a texture to the textureCache.
    @method addTextureToCache
    @param texture {Texture}
    @param id {String} the id that the texture will be stored against.
    ###
    @addTextureToCache: (texture, id) ->
      Texture.cache[id] = texture

    ###
    Remove a texture from the textureCache.
    @method removeTextureFromCache
    @param id {String} the id of the texture to be removed
    @return {Texture} the texture that was removed
    ###
    @removeTextureFromCache: (id) ->
      texture = Texture.cache[id]
      Texture.cache[id] = null
      texture

  return Texture