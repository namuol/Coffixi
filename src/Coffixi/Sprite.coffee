###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/Sprite', [
  './Point'
  './DisplayObjectContainer'
  './textures/Texture'
], (
  Point
  DisplayObjectContainer
  Texture
) ->

  ###
  @class Sprite
  @extends DisplayObjectContainer
  @constructor
  @param texture {Texture}
  @type String
  ###
  class Sprite extends DisplayObjectContainer
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
      @type uint
      ###
      @blendMode = Sprite.blendModes.NORMAL
      
      if @texture?    
        if texture.baseTexture.hasLoaded
          @width ?= @texture.frame.width
          @height ?= @texture.frame.height
          @updateFrame = true
        else
          @onTextureUpdateBind = @onTextureUpdate.bind(this)
          @texture.on "update", @onTextureUpdateBind
      
      ###
      The width of the sprite (this is initially set by the texture)
      @property width
      @type #Number
      ###
      @width ?= 1
      
      ###
      The height of the sprite (this is initially set by the texture)
      @property height
      @type #Number
      ###
      @height ?= 1
      if @texture?
        if texture.baseTexture.hasLoaded
          @updateFrame = true
        else
          @onTextureUpdateBind = @onTextureUpdate.bind(this)
          @texture.on "update", @onTextureUpdateBind
      @renderable = true

    # LOU TODO: Decide if we really want these.
    # OOH! shiney new getters and setters for width and height
    # The width and height now modify the scale (this is what flash does, nice and tidy!)
    Object.defineProperty Sprite::, "width",
      get: ->
        if @texture
          @scaleX * @texture.frame.width
        else
          @_width

      set: (value) ->
        @_width = value
        if @texture
          @scaleX = value / @texture.frame.width

    Object.defineProperty Sprite::, "height",
      get: ->
        if @texture
          @scaleY * @texture.frame.height
        else
          @_height

      set: (value) ->
        @_height = value
        if @texture
          @scaleY = value / @texture.frame.height

    ###
    @method setTexture
    @param texture {Texture} The texture that is displayed by the sprite
    ###
    setTexture: (texture) ->
      
      # stop current texture;
      if @texture? and @texture.baseTexture is not texture.baseTexture
        @textureChange = true
      @texture = texture
      @width = texture.frame.width
      @height = texture.frame.height
      @updateFrame = true

    ###
    @private
    ###
    onTextureUpdate: (event) ->
      @width = @texture.frame.width
      @height = @texture.frame.height
      @updateFrame = true

    # some helper functions..

    ###
    Helper function that creates a sprite that will contain a texture from the Texture.cache based on the frameId
    The frame ids are created when a Texture packer file has been loaded
    @method fromFrame
    @static
    @param frameId {String} The frame Id of the texture in the cache
    @return {Sprite} A new Sprite using a texture from the texture cache matching the frameId
    ###
    @fromFrame: (frameId) ->
      texture = Texture.cache[frameId]
      if not texture
        throw new Error("The frameId '" + frameId + "' does not exist in the texture cache" + this)
      new Sprite(texture)

    ###
    Helper function that creates a sprite that will contain a texture based on an image url
    If the image is not in the texture cache it will be loaded
    @method fromImage
    @static
    @param The image url of the texture
    @return {Sprite} A new Sprite using a texture from the texture cache matching the image id
    ###
    @fromImage: (imageId) ->
      new Sprite Texture.fromImage(imageId)

    @blendModes:
      NORMAL: 0
      SCREEN: 1