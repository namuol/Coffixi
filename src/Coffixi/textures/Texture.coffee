###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/textures/Texture', [
  'Coffixi/utils/EventTarget'
  './BaseTexture'
  'Coffixi/core/Rectangle'
  'Coffixi/core/Point'
], (
  EventTarget
  BaseTexture
  Rectangle
  Point
) ->

  ###
  A texture stores the information that represents an image or part of an image. It cannot be added
  to the display list directly. To do this use Sprite. If no frame is provided then the whole image is used

  @class Texture
  @uses EventTarget
  @constructor
  @param baseTexture {BaseTexture} The base texture source to create the texture from
  @param frmae {Rectangle} The rectangle frame of the texture to show
  ###
  class Texture extends EventTarget
    @cache: {}
    @frameUpdates: []
    constructor: (baseTexture, frame) ->
      super

      if not frame
        @noFrame = true
        frame = new Rectangle(0, 0, 1, 1)

      if baseTexture instanceof Texture
        baseTexture = baseTexture.baseTexture
      
      ###
      The base texture of this texture
      
      @property baseTexture
      @type BaseTexture
      ###
      @baseTexture = baseTexture
      
      ###
      The frame specifies the region of the base texture that this texture uses
      
      @property frame
      @type Rectangle
      ###
      @frame = frame
      
      ###
      The trim point
      
      @property trim
      @type Point
      ###
      @trim = new Point()
      @scope = this
      if baseTexture.hasLoaded
        frame = new Rectangle(0, 0, baseTexture.width, baseTexture.height)  if @noFrame
        
        #console.log(frame)
        @setFrame frame
      else
        scope = this
        baseTexture.on "loaded", ->
          scope.onBaseTextureLoaded()

    ###
    Called when the base texture is loaded

    @method onBaseTextureLoaded
    @param event
    @private
    ###
    onBaseTextureLoaded: (event) ->
      baseTexture = @baseTexture
      baseTexture.off "loaded", @onLoaded
      @frame = new Rectangle(0, 0, baseTexture.width, baseTexture.height)  if @noFrame
      @noFrame = false
      @width = @frame.width
      @height = @frame.height
      @scope.emit
        type: "update"
        content: this

    ###
    Destroys this texture

    @method destroy
    @param destroyBase {Boolean} Whether to destroy the base texture as well
    ###
    destroy: (destroyBase) ->
      @baseTexture.destroy()  if destroyBase

    ###
    Specifies the rectangle region of the baseTexture

    @method setFrame
    @param frame {Rectangle} The frame of the texture to set it to
    ###
    setFrame: (frame) ->
      @frame = frame
      @width = frame.width
      @height = frame.height
      if frame.x + frame.width > @baseTexture.width or frame.y + frame.height > @baseTexture.height
        throw new Error("Texture Error: frame does not fit inside the base Texture dimensions " + this)
      @updateFrame = true
      Texture.frameUpdates.push this

    getPixel: (x,y) -> @baseTexture.getPixel @frame.x + x, @frame.y + y
    beginRead: -> @baseTexture.beginRead()
    endRead: -> @baseTexture.endRead()
    
    ###
    Helper function that returns a texture based on an image url
    If the image is not in the texture cache it will be  created and loaded

    @static
    @method fromImage
    @param imageUrl {String} The image url of the texture
    @param crossorigin {Boolean} Whether requests should be treated as crossorigin
    @return Texture
    ###
    @fromImage: (imageUrl, crossorigin) ->
      texture = Texture.cache[imageUrl]
      unless texture
        texture = new Texture(BaseTexture.fromImage(imageUrl, crossorigin))
        Texture.cache[imageUrl] = texture
      texture

    ###
    Helper function that returns a texture based on a frame id
    If the frame id is not in the texture cache an error will be thrown

    @static
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
      baseTexture = new BaseTexture(canvas)
      new Texture(baseTexture)

    ###
    Adds a texture to the textureCache.

    @static
    @method addTextureToCache
    @param texture {Texture}
    @param id {String} the id that the texture will be stored against.
    ###
    @addTextureToCache: (texture, id) ->
      Texture.cache[id] = texture

    ###
    Remove a texture from the textureCache.

    @static
    @method removeTextureFromCache
    @param id {String} the id of the texture to be removed
    @return {Texture} the texture that was removed
    ###
    @removeTextureFromCache: (id) ->
      texture = Texture.cache[id]
      Texture.cache[id] = null
      texture
