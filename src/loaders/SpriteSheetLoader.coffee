###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define [
  'utils/EventTarget'
  'textures/Texture'
], (EventTarget, Texture) ->

  ###
  The sprite sheet loader is used to load in JSON sprite sheet data
  To generate the data you can use http://www.codeandweb.com/texturepacker and publish the "JSON" format
  There is a free version so thats nice, although the paid version is great value for money.
  It is highly recommended to use Sprite sheets (also know as texture atlas') as it means sprite's can be batched and drawn together for highly increased rendering speed.
  Once the data has been loaded the frames are stored in the texture cache and can be accessed though Texture.fromFrameId() and Sprite.fromFromeId()
  This loader will also load the image file that the Spritesheet points to as well as the data.
  When loaded this class will dispatch a 'loaded' event
  @class SpriteSheetLoader
  @extends EventTarget
  @constructor
  @param url {String} the url of the sprite sheet JSON file
  ###
  class SpriteSheetLoader extends EventTarget
    constructor: (url) ->
      # i use texture packer to load the assets..
      # http://www.codeandweb.com/texturepacker
      # make sure to set the format as "JSON"
      super
      @url = url
      @baseUrl = url.replace(/[^\/]*$/, "")
      @texture
      @frames = {}
      @crossorigin = false

    ###
    This will begin loading the JSON file
    ###
    load: ->
      @ajaxRequest = new AjaxRequest()
      scope = this
      @ajaxRequest.onreadystatechange = ->
        scope.onLoaded()

      @ajaxRequest.open "GET", @url, true
      @ajaxRequest.overrideMimeType "application/json"  if @ajaxRequest.overrideMimeType
      @ajaxRequest.send null

    onLoaded: ->
      if @ajaxRequest.readyState is 4
        if @ajaxRequest.status is 200 or window.location.href.indexOf("http") is -1
          jsondata = eval("(" + @ajaxRequest.responseText + ")")
          textureUrl = @baseUrl + jsondata.meta.image
          @texture = Texture.fromImage(textureUrl, @crossorigin).baseTexture
          
          #	if(!this.texture)this.texture = new Texture(textureUrl);
          frameData = jsondata.frames
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
                
                #var realSize = frameData[i].spriteSourceSize;
                Texture.cache[i].realSize = frameData[i].spriteSourceSize
                Texture.cache[i].trim.x = 0 # (realSize.x / rect.w)
          # calculate the offset!
          
          if @texture.hasLoaded
            @dispatchEvent
              type: "loaded"
              content: this
          else
            scope = this
            
            # wait for the texture to load..
            @texture.addEventListener "loaded", ->
              scope.dispatchEvent
                type: "loaded"
                content: scope

  return SpriteSheetLoader