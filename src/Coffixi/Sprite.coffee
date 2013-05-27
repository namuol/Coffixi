###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/Sprite', [
  './Point'
  './DisplayObjectContainer'
], (Point, DisplayObjectContainer) ->
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

      @renderable = true

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

    @blendModes:
      NORMAL: 0
      SCREEN: 1