###*
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/text/Text', [
  'Coffixi/display/Sprite'
  'Coffixi/textures/Texture'
  'Coffixi/textures/BaseTexture'
  'Coffixi/core/Point'
], (
  Sprite
  Texture
  BaseTexture
  Point
) ->

  # LOU TODO: Abstract out all the canvas rendering stuff. Native implementation will use SDL_ttf.

  ###*
  A Text Object will create a line(s) of text to split a line you can use "\n"

  @class Text
  @extends Sprite
  @constructor
  @param text {String} The copy that you would like the text to display
  @param [style] {Object} The style parameters
  @param [style.font] {String} default "bold 20pt Arial" The style and size of the font
  @param [style.fill="black"] {Object} A canvas fillstyle that will be used on the text eg "red", "#00FF00"
  @param [style.align="left"] {String} An alignment of the multiline text ("left", "center" or "right")
  @param [style.stroke] {String} A canvas fillstyle that will be used on the text stroke eg "blue", "#FCFF00"
  @param [style.strokeThickness=0] {Number} A number that represents the thickness of the stroke. Default is 0 (no stroke)
  @param [style.wordWrap=false] {Boolean} Indicates if word wrap should be used
  @param [style.wordWrapWidth=100] {Number} The width at which text will wrap
  ###
  class Text extends Sprite
    @heightCache: {}
    
    constructor: (text, style) ->
      canvas = document.createElement("canvas")
      canvas.getContext("2d")
      super Texture.fromCanvas(canvas)
      @canvas = @texture.baseTexture.source
      @context = @texture.baseTexture._ctx
      @setText text
      @setStyle style
      @updateText()
      @dirty = false

    ###*
    Set the style of the text

    @method setStyle
    @param [style] {Object} The style parameters
    @param [style.font="bold 20pt Arial"] {String} The style and size of the font
    @param [style.fill="black"] {Object} A canvas fillstyle that will be used on the text eg "red", "#00FF00"
    @param [style.align="left"] {String} An alignment of the multiline text ("left", "center" or "right")
    @param [style.stroke="black"] {String} A canvas fillstyle that will be used on the text stroke eg "blue", "#FCFF00"
    @param [style.strokeThickness=0] {Number} A number that represents the thickness of the stroke. Default is 0 (no stroke)
    @param [style.wordWrap=false] {Boolean} Indicates if word wrap should be used
    @param [style.wordWrapWidth=100] {Number} The width at which text will wrap
    ###
    setStyle: (style) ->
      style = style or {}
      style.font = style.font or "bold 20pt Arial"
      style.fill = style.fill or "black"
      style.align = style.align or "left"
      style.stroke = style.stroke or "black" #provide a default, see: https://github.com/GoodBoyDigital/pixi.js/issues/136
      style.strokeThickness = style.strokeThickness or 0
      style.wordWrap = style.wordWrap or false
      style.wordWrapWidth = style.wordWrapWidth or 100
      @style = style
      @dirty = true

    ###*
    Set the copy for the text object. To split a line you can use "\n"

    @methos setText
    @param {String} text The copy that you would like the text to display
    ###
    setText: (text) ->
      @text = text.toString() or " "
      @dirty = true

    ###*
    Renders text

    @method updateText
    @private
    ###
    updateText: ->
      @context.font = @style.font
      outputText = @text
      
      # word wrap
      # preserve original text
      outputText = @wordWrap(@text)  if @style.wordWrap
      
      #split text into lines
      lines = outputText.split(/(?:\r\n|\r|\n)/)
      
      #calculate text width
      lineWidths = []
      maxLineWidth = 0
      i = 0

      while i < lines.length
        lineWidth = @context.measureText(lines[i]).width
        lineWidths[i] = lineWidth
        maxLineWidth = Math.max(maxLineWidth, lineWidth)
        i++
      @width = @canvas.width = maxLineWidth + @style.strokeThickness
      
      #calculate text height
      lineHeight = @determineFontHeight("font: " + @style.font + ";") + @style.strokeThickness
      @height = @canvas.height = lineHeight * lines.length
      
      #set canvas text styles
      @context.fillStyle = @style.fill
      @context.font = @style.font
      @context.strokeStyle = @style.stroke
      @context.lineWidth = @style.strokeThickness
      @context.textBaseline = "top"
      
      #draw lines line by line
      i = 0
      while i < lines.length
        linePosition = new Point(@style.strokeThickness / 2, @style.strokeThickness / 2 + i * lineHeight)
        if @style.align is "right"
          linePosition.x += maxLineWidth - lineWidths[i]
        else linePosition.x += (maxLineWidth - lineWidths[i]) / 2  if @style.align is "center"
        @context.strokeText lines[i], linePosition.x, linePosition.y  if @style.stroke and @style.strokeThickness
        @context.fillText lines[i], linePosition.x, linePosition.y  if @style.fill
        i++
      @updateTexture()

    ###*
    Updates texture size based on canvas size

    @method updateTexture
    @private
    ###
    updateTexture: ->
      @texture.baseTexture.width = @canvas.width
      @texture.baseTexture.height = @canvas.height
      @texture.frame.width = @canvas.width
      @texture.frame.height = @canvas.height
      @width = @canvas.width
      @height = @canvas.height
      BaseTexture.texturesToUpdate.push @texture.baseTexture

    ###*
    Updates the transfor of this object

    @method updateTransform
    @private
    ###
    updateTransform: ->
      if @dirty
        @updateText()
        @dirty = false
      super

    ###*
    http://stackoverflow.com/users/34441/ellisbben
    great solution to the problem!

    @method determineFontHeight
    @param fontStyle {Object}
    @private
    ###    
    determineFontHeight: (fontStyle) ->
      
      # build a little reference dictionary so if the font style has been used return a
      # cached version...
      result = Text.heightCache[fontStyle]
      unless result
        body = document.getElementsByTagName("body")[0]
        dummy = document.createElement("div")
        dummyText = document.createTextNode("M")
        dummy.appendChild dummyText
        dummy.setAttribute "style", fontStyle + ";position:absolute;top:0;left:0"
        body.appendChild dummy
        result = dummy.offsetHeight
        Text.heightCache[fontStyle] = result
        body.removeChild dummy
      result

    ###*
    A Text Object will apply wordwrap

    @method wordWrap
    @param text {String}
    @private
    ###
    wordWrap: (text) ->
      
      # search good wrap position
      searchWrapPos = (ctx, text, start, end, wrapWidth) ->
        p = Math.floor((end - start) / 2) + start
        return 1  if p is start
        if ctx.measureText(text.substring(0, p)).width <= wrapWidth
          if ctx.measureText(text.substring(0, p + 1)).width > wrapWidth
            p
          else
            arguments.callee ctx, text, p, end, wrapWidth
        else
          arguments.callee ctx, text, start, p, wrapWidth

      lineWrap = (ctx, text, wrapWidth) ->
        return text  if ctx.measureText(text).width <= wrapWidth or text.length < 1
        pos = searchWrapPos(ctx, text, 0, text.length, wrapWidth)
        text.substring(0, pos) + "\n" + arguments.callee(ctx, text.substring(pos), wrapWidth)

      result = ""
      lines = text.split("\n")
      i = 0

      while i < lines.length
        result += lineWrap(@context, lines[i], @style.wordWrapWidth) + "\n"
        i++
      result


    ###*
    Destroys this text object

    @method destroy
    @param destroyTexture {Boolean}
    ###
    destroy: (destroyTexture) ->
      @texture.destroy()  if destroyTexture
