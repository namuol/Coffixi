###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/loaders/SpriteSheetLoader', [
  '../utils/Utils'
  '../utils/EventTarget'
  '../textures/Texture'
  './ImageLoader'
], (
  Utils
  EventTarget
  Texture
  ImageLoader
) ->

  ###
  The sprite sheet loader is used to load in JSON sprite sheet data
  To generate the data you can use http://www.codeandweb.com/texturepacker and publish the "JSON" format
  There is a free version so thats nice, although the paid version is great value for money.
  It is highly recommended to use Sprite sheets (also know as texture atlas") as it means sprite"s can be batched and drawn together for highly increased rendering speed.
  Once the data has been loaded the frames are stored in the texture cache and can be accessed though Texture.fromFrameId() and Sprite.fromFromeId()
  This loader will also load the image file that the Spritesheet points to as well as the data.
  When loaded this class will dispatch a "loaded" event
  @class SpriteSheetLoader
  @extends EventTarget
  @constructor
  @param {String} url the url of the sprite sheet JSON file
  @param {Boolean} crossorigin
  ###
  class SpriteSheetLoader extends EventTarget
    constructor: (url, crossorigin) ->
      #
      #  * i use texture packer to load the assets..
      #  * http://www.codeandweb.com/texturepacker
      #  * make sure to set the format as "JSON"
      #  
      super

      @url = url
      @baseUrl = url.replace(/[^\/]*$/, "")
      @texture = null
      @frames = {}
      @crossorigin = crossorigin

    ###
    This will begin loading the JSON file
    ###
    load: ->
      @ajaxRequest = new AjaxRequest()
      scope = this
      @ajaxRequest.onreadystatechange = ->
        scope.onJSONLoaded()

      @ajaxRequest.open "GET", @url, true
      @ajaxRequest.overrideMimeType "application/json"  if @ajaxRequest.overrideMimeType
      @ajaxRequest.send null

    ###
    Invoke when JSON file is loaded
    @private
    ###
    onJSONLoaded: ->
      if @ajaxRequest.readyState is 4
        if @ajaxRequest.status is 200 or window.location.href.indexOf("http") is -1
          jsonData = eval_("(" + @ajaxRequest.responseText + ")")
          textureUrl = @baseUrl + jsonData.meta.image
          image = new ImageLoader(textureUrl, @crossorigin)
          @texture = image.texture.baseTexture
          scope = this
          image.addEventListener "loaded", (event) ->
            scope.onLoaded()

          frameData = jsonData.frames
          for i of frameData
            rect = frameData[i].frame
            if rect
              Texture.cache[i] = new Texture(@texture,
                x: rect.x
                y: rect.y
                width: rect.w
                height: rect.h
              )
              if frameData[i].trimmed
                Texture.cache[i].realSize = frameData[i].spriteSourceSize
                Texture.cache[i].trim.x = Texture.cache[i].realSize.x / rect.w
                Texture.cache[i].trim.y = Texture.cache[i].realSize.y / rect.h
          image.load()

    ###
    Invoke when all files are loaded (json and texture)
    @private
    ###
    onLoaded: ->
      @emit
        type: "loaded"
        content: this