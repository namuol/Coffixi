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
      @source = source #new Image();
      if @source instanceof Image
        if @source.complete
          @hasLoaded = true
          @width = @source.width
          @height = @source.height
          BaseTexture.texturesToUpdate.push this
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
            BaseTexture.texturesToUpdate.push @
            @emit
              type: "loaded"
              content: @

      else
        @hasLoaded = true
        @width = @source.width
        @height = @source.height
        
        BaseTexture.texturesToUpdate.push this

    fromImage: (imageUrl) ->
    @texturesToUpdate: []
    @cache: {}

  return BaseTexture
