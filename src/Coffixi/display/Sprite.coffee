###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/display/Sprite', [
  './DisplayObjectContainer'
  'Coffixi/core/Point'
  'Coffixi/textures/Texture'
], (
  DisplayObjectContainer
  Point
  Texture
) ->

  ###
  The Sprite object is the base for all textured objects that are rendered to the screen

  @class Sprite
  @extends DisplayObjectContainer
  @constructor
  @param texture {Texture} The texture for this sprite
  @type String
  ###
  class Sprite extends DisplayObjectContainer
    @blendModes:
      NORMAL: 0
      SCREEN: 1
    constructor: (texture) ->
      super
      
      ###
      The anchor sets the origin point of the texture.
      The default is 0,0 this means the textures origin is the top left
      Setting than anchor to 0.5,0.5 means the textures origin is centered
      Setting the anchor to 1,1 would mean the textures origin points will be the bottom right
      
      @property anchor
      @type Point
      ###
      @anchor ?= new Point()
      
      ###
      The texture that the sprite is using
      
      @property texture
      @type Texture
      ###
      if texture?
        @texture = texture
      
      ###
      The blend mode of sprite.
      currently supports Sprite.blendModes.NORMAL and Sprite.blendModes.SCREEN
      
      @property blendMode
      @type Number
      ###
      @blendMode = Sprite.blendModes.NORMAL
      
      ###
      The width of the sprite (this is initially set by the texture)
      
      @property _width
      @type Number
      @private
      ###
      @_width = 0
      
      ###
      The height of the sprite (this is initially set by the texture)
      
      @property _height
      @type Number
      @private
      ###
      @_height = 0

      if @texture?
        if @texture.baseTexture.hasLoaded
          @updateFrame = true
        else
          @onTextureUpdateBind = @onTextureUpdate.bind(this)
          @texture.addEventListener "update", @onTextureUpdateBind

      @renderable = true

    # ###
    # The width of the sprite, setting this will actually modify the scale to acheive the value set

    # @property width
    # @type Number
    # ###
    # Object.defineProperty Sprite::, "width",
    #   get: ->
    #     @scaleX * @texture.frame.width

    #   set: (value) ->
    #     @scaleX = value / @texture.frame.width
    #     @_width = value

    # ###
    # The height of the sprite, setting this will actually modify the scale to acheive the value set

    # @property height
    # @type Number
    # ###
    # Object.defineProperty Sprite::, "height",
    #   get: ->
    #     @scaleY * @texture.frame.height

    #   set: (value) ->
    #     @scaleY = value / @texture.frame.height
    #     @_height = value

    ###
    Sets the texture of the sprite

    @method setTexture
    @param texture {Texture} The texture that is displayed by the sprite
    ###
    setTexture: (texture) ->
      # stop current texture;
      if @texture? and @texture.baseTexture isnt texture.baseTexture
        @textureChange = true
      @texture = texture
      @updateFrame = true

    ###
    When the texture is updated, this event will fire to update the scale and frame

    @method onTextureUpdate
    @param event
    @private
    ###
    onTextureUpdate: (event) ->
      #this.texture.removeEventListener( 'update', this.onTextureUpdateBind );
      
      # so if _width is 0 then width was not set..
      @scaleX = @_width / @texture.frame.width  if @_width
      @scaleY = @_height / @texture.frame.height  if @_height
      @updateFrame = true

    # some helper functions..

    ###
    Helper function that creates a sprite that will contain a texture from the TextureCache based on the frameId
    The frame ids are created when a Texture packer file has been loaded

    @method fromFrame
    @static
    @param frameId {String} The frame Id of the texture in the cache
    @return {Sprite} A new Sprite using a texture from the texture cache matching the frameId
    ###
    @fromFrame: (frameId) ->
      texture = Texture.cache[frameId]
      throw new Error("The frameId '" + frameId + "' does not exist in the texture cache" + this)  unless texture
      new Sprite(texture)

    ###
    Helper function that creates a sprite that will contain a texture based on an image url
    If the image is not in the texture cache it will be loaded

    @method fromImage
    @static
    @param imageId {String} The image url of the texture
    @return {Sprite} A new Sprite using a texture from the texture cache matching the image id
    ###
    @fromImage: (imageId) ->
      texture = Texture.fromImage(imageId)
      new Sprite(texture)
