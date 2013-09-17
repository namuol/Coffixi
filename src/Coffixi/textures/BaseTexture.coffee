###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/textures/BaseTexture', [
  'Coffixi/utils/Module'
  'Coffixi/utils/HasSignals'
], (
  Module
  HasSignals
) ->

  ###
  A texture stores the information that represents an image. All textures have a base texture

  @class BaseTexture
  @extends Module
  @uses HasSignals
  @constructor
  @param source {String} the source object (image or canvas)
  ###
  class BaseTexture extends Module
    @mixin HasSignals

    @cache: {}
    @texturesToUpdate: []
    @texturesToDestroy: []
    
    @filterModes:
      LINEAR: 1
      NEAREST: 2

    constructor: (source) ->
      super
      
      ###
      [read-only] The width of the base texture set when the image has loaded
      
      @property width
      @type Number
      @readOnly
      ###
      @width = 100
      
      ###
      [read-only] The height of the base texture set when the image has loaded
      
      @property height
      @type Number
      @readOnly
      ###
      @height = 100
      
      ###
      [read-only] Describes if the base texture has loaded or not
      
      @property hasLoaded
      @type Boolean
      @readOnly
      ###
      @hasLoaded = false
      
      ###
      The source that is loaded to create the texture
      
      @property source
      @type Image
      ###
      @source = source
      
      return  unless source

      if not (@source instanceof Image or @source instanceof HTMLImageElement)
        @hasLoaded = true
        @width = @source.width
        @height = @source.height

        @createCanvas @source  if @source instanceof Image
      else
        if @source.complete
          @hasLoaded = true
          @width = @source.width
          @height = @source.height
          @createCanvas @source
          @emit 'loaded', @
        else
          @source.onerror = =>
            @emit 'error', @

          @source.onload = =>
            @hasLoaded = true
            @width = @source.width
            @height = @source.height
            
            # add it to somewhere...
            @createCanvas @source
            @emit 'loaded', @

      @_powerOf2 = false

      @filterMode = undefined # Use renderer's default filter mode.

    setFilterMode: (mode) ->
      @filterMode = mode
      BaseTexture.texturesToUpdate.push @

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

    ###
    Destroys this base texture

    @method destroy
    ###
    destroy: ->
      @source.src = null  if @source instanceof Image
      @source = null
      BaseTexture.texturesToDestroy.push this

    ###
    Helper function that returns a base texture based on an image url
    If the image is not in the base texture cache it will be  created and loaded

    @static
    @method fromImage
    @param imageUrl {String} The image url of the texture
    @return BaseTexture
    ###
    @fromImage: (imageUrl, crossorigin) ->
      baseTexture = BaseTexture.cache[imageUrl]
      unless baseTexture
        
        # new Image() breaks tex loading in some versions of Chrome.
        # See https://code.google.com/p/chromium/issues/detail?id=238071
        image = new Image() #document.createElement('img');
        image.crossOrigin = ""  if crossorigin
        image.src = imageUrl
        baseTexture = new BaseTexture(image)
        BaseTexture.cache[imageUrl] = baseTexture
      baseTexture
