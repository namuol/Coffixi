###
@author Mat Groves http://matgroves.com/
###

define 'Coffixi/extras/TilingSprite', [
  '../utils/Utils'
  '../Point'
  '../DisplayObjectContainer'
  '../Sprite'
], (
  Utils
  Point
  DisplayObjectContainer
  Sprite
) ->

  ###
  A tiling sprite is a fast way of rendering a tiling image
  @class TilingSprite
  @extends DisplayObjectContainer
  @constructor
  @param texture {Texture} the texture of the tiling sprite
  @param width {Number}  the width of the tiling sprite
  @param height {Number} the height of the tiling sprite
  ###
  class TilingSprite extends DisplayObjectContainer
    constructor: (texture, width, height) ->
      super
      @texture = texture
      @width = width
      @height = height
      @renderable = true
      
      ###
      The scaling of the image that is being tiled
      @property tileScale
      @type Point
      ###
      @tileScale = new Point(1, 1)
      
      ###
      The offset position of the image that is being tiled
      @property tilePosition
      @type Point
      ###
      @tilePosition = new Point(0, 0)
      @blendMode = Sprite.blendModes.NORMAL

    setTexture = (texture) ->
      #TODO SET THE TEXTURES
      #TODO VISIBILITY
      
      # stop current texture 
      @texture = texture
      @updateFrame = true

    onTextureUpdate = (event) ->
      @updateFrame = true