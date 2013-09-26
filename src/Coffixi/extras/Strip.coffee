###*
@author Mat Groves http://matgroves.com/
###

define 'Coffixi/extras/Strip', [
  'Coffixi/display/DisplayObjectContainer'
  'Coffixi/display/Sprite'
  'Coffixi/utils/Utils'
  'Coffixi/core/RenderTypes'
], (
  DisplayObjectContainer
  Sprite
  Utils
  RenderTypes
) ->

  class Strip extends DisplayObjectContainer
    __renderType: RenderTypes.STRIP
    constructor: (texture, width, height) ->
      super

      @texture = texture
      @blendMode = Sprite.blendModes.NORMAL
      try
        @uvs = new Utils.Float32Array([0, 1, 1, 1, 1, 0, 0, 1])
        @verticies = new Utils.Float32Array([0, 0, 0, 0, 0, 0, 0, 0, 0])
        @colors = new Utils.Float32Array([1, 1, 1, 1])
        @indices = new Utils.Uint16Array([0, 1, 2, 3])
      catch error
        @uvs = [0, 1, 1, 1, 1, 0, 0, 1]
        @verticies = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        @colors = [1, 1, 1, 1]
        @indices = [0, 1, 2, 3]
      
      #
      #	this.uvs = new Utils.Float32Array()
      #	this.verticies = new Utils.Float32Array()
      #	this.colors = new Utils.Float32Array()
      #	this.indices = new Utils.Uint16Array()
      #
      @width = width
      @height = height
      
      # load the texture!
      if texture.baseTexture.hasLoaded
        @width = @texture.frame.width
        @height = @texture.frame.height
        @updateFrame = true
      else
        @onTextureUpdateBind = @onTextureUpdate.bind(this)
        @texture.on 'update', @onTextureUpdateBind
      @renderable = true

    ###*
    The texture used by this `Strip`.

    @property texture
    ###
    Object.defineProperty @::, 'texture',
      get: -> @_texture
      set: (texture) ->
        #TODO SET THE TEXTURES
        #TODO VISIBILITY
        
        # stop current texture 
        @_texture = texture
        @width = texture.frame.width
        @height = texture.frame.height
        @updateFrame = true

    onTextureUpdate: (event) ->
      @updateFrame = true
