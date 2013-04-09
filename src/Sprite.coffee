###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define [
  'RenderCore/Point'
  'RenderCore/DisplayObjectContainer'
], (Point, DisplayObjectContainer) ->

  Sprite.blendModes = {}
  Sprite.blendModes.NORMAL = 0
  Sprite.blendModes.SCREEN = 1

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
      @anchor = new Point()
      
      ###
      The texture that the sprite is using
      @property texture
      @type Texture
      ###
      @texture = texture
      
      ###
      The blend mode of sprite.
      currently supports RenderCore.blendModes.NORMAL and RenderCore.blendModes.SCREEN
      @property blendMode
      @type uint
      ###
      @blendMode = RenderCore.blendModes.NORMAL
      
      ###
      The width of the sprite (this is initially set by the texture)
      @property width
      @type #Number
      ###
      @width = 1
      
      ###
      The height of the sprite (this is initially set by the texture)
      @property height
      @type #Number
      ###
      @height = 1
      if texture.baseTexture.hasLoaded
        @width = @texture.frame.width
        @height = @texture.frame.height
        @updateFrame = true
      else
        @onTextureUpdateBind = @onTextureUpdate.bind(this)
        @texture.addEventListener "update", @onTextureUpdateBind
      @renderable = true
      
      # [readonly] best not to toggle directly! use setInteractive()
      @interactive = false

    # thi next bit is here for the docs...

    #
    #  * MOUSE Callbacks
    #  

    ###
    A callback that is used when the users clicks on the sprite with thier mouse
    @method click
    @param interactionData {InteractionData}
    ###

    ###
    A callback that is used when the user clicks the mouse down over the sprite
    @method mousedown
    @param interactionData {InteractionData}
    ###

    ###
    A callback that is used when the user releases the mouse that was over the sprite
    for this callback to be fired the mouse must have been pressed down over the sprite
    @method mouseup
    @param interactionData {InteractionData}
    ###

    ###
    A callback that is used when the users mouse rolls over the sprite
    @method mouseover
    @param interactionData {InteractionData}
    ###

    ###
    A callback that is used when the users mouse leaves the sprite
    @method mouseout
    @param interactionData {InteractionData}
    ###

    #
    #  * TOUCH Callbacks
    #  

    ###
    A callback that is used when the users taps on the sprite with thier finger
    basically a touch version of click
    @method tap
    @param interactionData {InteractionData}
    ###

    ###
    A callback that is used when the user touch's over the sprite
    @method touchstart
    @param interactionData {InteractionData}
    ###

    ###
    A callback that is used when the user releases the touch that was over the sprite
    for this callback to be fired. The touch must have started over the sprite
    @method touchend
    @param interactionData {InteractionData}
    ###

    ###
    @method setTexture
    @param texture {Texture} The RenderCore texture that is displayed by the sprite
    ###
    setTexture: (texture) ->
      
      # stop current texture;
      @textureChange = true  unless @texture.baseTexture is texture.baseTexture
      @texture = texture
      @width = texture.frame.width
      @height = texture.frame.height
      @updateFrame = true


    ###
    Indicates if the sprite will have touch and mouse interactivity. It is false by default
    @method setInteractive
    @param interactive {Boolean}
    ###
    setInteractive: (interactive) ->
      @interactive = interactive
      
      # TODO more to be done here..
      # need to sort out a re-crawl!
      @stage.dirty = true  if @stage


    ###
    @private
    ###
    onTextureUpdate: (event) ->
      @width = @texture.frame.width
      @height = @texture.frame.height
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
      texture = RenderCore.TextureCache[frameId]
      throw new Error("The frameId '" + frameId + "' does not exist in the texture cache" + this)  unless texture
      new RenderCore.Sprite(texture)


    ###
    Helper function that creates a sprite that will contain a texture based on an image url
    If the image is not in the texture cache it will be loaded
    @method fromImage
    @static
    @param The image url of the texture
    @return {Sprite} A new Sprite using a texture from the texture cache matching the image id
    ###
    @fromImage: (imageId) ->
      texture = RenderCore.Texture.fromImage(imageId)
      new RenderCore.Sprite(texture)