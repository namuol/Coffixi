###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/textures/BaseTexture', [
  '../utils/EventTarget'
], (EventTarget) ->
  ###
  A texture stores the information that represents an image. All textures have a base texture
  @class BaseTexture
  @extends EventTarget
  @constructor
  @param source {String} the source object (image or canvas)
  ###
  class BaseTexture extends EventTarget
    constructor: (source) ->
      super      
      ###
      [read only] The width of the base texture set when the image has loaded
      @property width
      @type Number
      ###
      @width = 100
      
      ###
      [read only] The height of the base texture set when the image has loaded
      @property height
      @type Number
      ###
      @height = 100
      
      ###
      The source that is loaded to create the texture
      @property source
      @type Image
      ###
      @source = source

      if not (@source instanceof Image)
        @hasLoaded = true
        @width = @source.width
        @height = @source.height
        
        @createCanvas @source
      else
        if @source.complete
          @hasLoaded = true
          @width = @source.width
          @height = @source.height
          @createCanvas @source
          @emit
            type: "loaded"
            content: @
        else
          @source.onerror = =>
            @emit
              type: 'error'
              content: @
              
          @source.onload = =>
            @hasLoaded = true
            @width = @source.width
            @height = @source.height
            
            # add it to somewhere...
            @createCanvas @source
            @emit
              type: "loaded"
              content: @

    beginRead: ->
      @_imageData ?= @_ctx.getImageData(0,0, @_ctx.canvas.width,@_ctx.canvas.height)

    getPixel: (x, y) ->
      idx = (x + y * @_imageData.width) * 4

      return {
        r: @_imageData.data[idx + 0]
        g: @_imageData.data[idx + 1]
        b: @_imageData.data[idx + 2]
        a: @_imageData.data[idx + 3]
      }
    
    endRead: ->
      # IF we change this back to EDIT, we'd need to update the texture like so:
      # @_ctx.putImageData @_imageData, 0,0
      BaseTexture.texturesToUpdate.push @

    # Converts a loaded image to a canvas element and 
    #  sets it as our source for easy pixel access.
    createCanvas: (loadedImage) ->
      @source = document.createElement 'canvas'
      @source.width = loadedImage.width
      @source.height = loadedImage.height
      @_ctx = @source.getContext '2d'
      @_ctx.drawImage loadedImage, 0,0

      @beginRead()
      @endRead()

    @fromImage: (imageUrl, crossorigin) ->
      baseTexture = BaseTexture.cache[imageUrl]
      unless baseTexture
        image = new Image()
        image.crossOrigin = ""  if crossorigin
        image.src = imageUrl
        baseTexture = new BaseTexture(image)
        BaseTexture.cache[imageUrl] = baseTexture
      baseTexture

    @texturesToUpdate: []
    @cache: {}
    @filterModes:
      LINEAR: 1
      NEAREST: 2

  return BaseTexture
