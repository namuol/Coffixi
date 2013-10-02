###*
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/display/Sprite', [
  './DisplayObjectContainer'
  'Coffixi/core/Point'
  'Coffixi/textures/Texture'
  'Coffixi/core/RenderTypes'
], (
  DisplayObjectContainer
  Point
  Texture
  RenderTypes
) ->

  ###*
  The Sprite object is the base for all textured objects that are rendered to the screen

  @class Sprite
  @extends DisplayObjectContainer
  @constructor
  @param texture {Texture} The texture for this sprite
  @type String
  ###
  class Sprite extends DisplayObjectContainer
    __renderType: RenderTypes.SPRITE

    @blendModes:
      NORMAL: 0
      SCREEN: 1
    constructor: (texture) ->
      super
      
      ###*
      The x-component of this `Sprite`'s anchor.

      The anchor sets the origin point of this `Sprite`'s texture.
  
      A value of 0 indicates that the texture's left side is aligned with `this.x`, 
      and a value of 1 indicates that the texture's right side is aligned with `this.x`.

      A value of 0.5 indicates that the texture is horizontally centered on `this.x`, etc.

      @property anchorX
      @type Number
      @default 0
      ###
      @anchorX ?= 0

      ###*
      The y-component of this `Sprite`'s anchor.

      The anchor sets the origin point of this `Sprite`'s texture.
  
      A value of 0 indicates that the texture's top is aligned with `this.y`, 
      and a value of 1 indicates that the texture's bottom is aligned with `this.y`.

      A value of 0.5 indicates that the texture is vertically centered on `this.y`, etc.

      @property anchorY
      @type Number
      @default 0
      ###
      @anchorY ?= 0

      ###*
      The texture that the sprite is using
      
      @property texture
      @type Texture
      ###
      if texture?
        @texture = texture
      
      ###*
      The blend mode of sprite.
      currently supports Sprite.blendModes.NORMAL and Sprite.blendModes.SCREEN
      
      @property blendMode
      @type Number
      ###
      @blendMode = Sprite.blendModes.NORMAL
      
      @_width ?= 10
      @_height ?= 10

      if @texture?
        if @texture.baseTexture.hasLoaded
          @updateFrame = true
        else
          @onTextureUpdateBind = @onTextureUpdate.bind(this)
          @texture.on 'update', @onTextureUpdateBind

      @renderable = true

    ###*
    The width of the sprite, setting this will actually modify the scale to acheive the value set

    @property width
    @type Number
    ###
    Object.defineProperty @::, 'width',
      get: ->
        if @texture?.frame?
          @scaleX * @texture.frame.width
        else
          @_width

      set: (value) ->
        @_width = value
        if @texture
          @scaleX = value / @texture.frame.width

    ###*
    The height of the sprite, setting this will actually modify the scale to acheive the value set

    @property height
    @type Number
    ###
    Object.defineProperty @::, 'height',
      get: ->
        if @texture?.frame?
          @scaleY * @texture.frame.height
        else
          @_height

      set: (value) ->
        @_height = value
        if @texture
          @scaleY = value / @texture.frame.height

    ###*
    The texture used by this `Sprite`.

    @property texture
    ###
    Object.defineProperty @::, 'texture',
      get: -> @_texture
      set: (texture) ->
        # stop current texture;
        if @_texture? and @_texture.baseTexture isnt texture.baseTexture
          @textureChange = true
        @_texture = texture
        @updateFrame = true

    ###*
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

    ###*
    Helper function that creates a sprite that will contain a texture from the TextureCache based on the frameId
    The frame ids are created when a Texture packer file has been loaded

    @method fromFrame
    @static
    @param frameId {String} The frame Id of the texture in the cache
    @return {Sprite} A new Sprite using a texture from the texture cache matching the frameId
    ###
    @fromFrame: (frameId) ->
      texture = Texture.cache[frameId]
      throw new Error('The frameId \'' + frameId + '\' does not exist in the texture cache ' + this)  unless texture
      new Sprite(texture)

    ###*
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
