###*
@author Mat Groves http://matgroves.com/
###
define 'Coffixi/extras/TilingSprite', [
  'Coffixi/core/Point'
  'Coffixi/display/DisplayObjectContainer'
  'Coffixi/display/Sprite'
  'Coffixi/core/RenderTypes'
], (
  Point
  DisplayObjectContainer
  Sprite
  RenderTypes
) ->

  ###*
  A tiling sprite is a fast way of rendering a tiling image

  @class TilingSprite
  @extends DisplayObjectContainer
  @constructor
  @param texture {Texture} the texture of the tiling sprite *NOTE*: Dimensions of the *baseTexture* must be a power-of-2! (eg. 32x64, 128x128, etc.)
  @param width {Number}  the width of the tiling sprite
  @param height {Number} the height of the tiling sprite
  ###
  class TilingSprite extends DisplayObjectContainer
    __renderType: RenderTypes.TILINGSPRITE
    constructor: (texture, width, height) ->
      super
      
      ###*
      The texture that the sprite is using
      
      @property texture
      @type Texture
      ###
      @texture = texture
      
      ###*
      The width of the tiling sprite
      
      @property width
      @type Number
      ###
      @width = width
      
      ###*
      The height of the tiling sprite
      
      @property height
      @type Number
      ###
      @height = height
      
      ###*
      The scaling of the image that is being tiled
      
      @property tileScale
      @type Point
      ###
      @tileScale = new Point(1, 1)
      
      ###*
      The offset position of the image that is being tiled
      
      @property tilePosition
      @type Point
      ###
      @tilePosition = new Point(0, 0)
      @renderable = true
      @blendMode = Sprite.blendModes.NORMAL

    ###*
    The texture used by this `TilingSprite`.

    **NOTE**: Must be a power-of-two image.
    @property texture
    ###
    @property 'texture',
      get: -> @_texture
      set: (texture) ->
        #TODO SET THE TEXTURES
        #TODO VISIBILITY
        
        # stop current texture 
        @_texture = texture
        @updateFrame = true

    ###*
    When the texture is updated, this event will fire to update the frame

    @method onTextureUpdate
    @param event
    @private
    ###
    onTextureUpdate: (event) ->
      @updateFrame = true
