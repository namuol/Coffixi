###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/canvas/CanvasGraphics', [
  'Coffixi/primitives/Graphics'
], (
  Graphics
) ->

  ###
  A set of functions used by the canvas renderer to draw the primitive graphics data

  @class CanvasGraphics
  ###
  class CanvasGraphics
    #
    # * Renders the graphics object
    # *
    # * @static
    # * @private
    # * @method renderGraphics
    # * @param graphics {Graphics}
    # * @param context {Context2D}
    # 
    @renderGraphics: (graphics, context) ->
      worldAlpha = graphics.worldAlpha
      i = 0

      while i < graphics.graphicsData.length
        data = graphics.graphicsData[i]
        points = data.points
        context.strokeStyle = color = "#" + ("00000" + (data.lineColor | 0).toString(16)).substr(-6)
        context.lineWidth = data.lineWidth
        if data.type is Graphics.POLY
          
          #if(data.lineWidth <= 0)continue;
          context.beginPath()
          context.moveTo points[0], points[1]
          j = 1

          while j < points.length / 2
            context.lineTo points[j * 2], points[j * 2 + 1]
            j++
          
          # if the first and last point are the same close the path - much neater :)
          context.closePath()  if points[0] is points[points.length - 2] and points[1] is points[points.length - 1]
          if data.fill
            context.globalAlpha = data.fillAlpha * worldAlpha
            context.fillStyle = color = "#" + ("00000" + (data.fillColor | 0).toString(16)).substr(-6)
            context.fill()
          if data.lineWidth
            context.globalAlpha = data.lineAlpha * worldAlpha
            context.stroke()
        else if data.type is Graphics.RECT
          
          if data.fillColor or data.fillColor is 0
            context.globalAlpha = data.fillAlpha * worldAlpha
            context.fillStyle = color = "#" + ("00000" + (data.fillColor | 0).toString(16)).substr(-6)
            context.fillRect points[0], points[1], points[2], points[3]
          if data.lineWidth
            context.globalAlpha = data.lineAlpha * worldAlpha
            context.strokeRect points[0], points[1], points[2], points[3]
        else if data.type is Graphics.CIRC
          
          # TODO - need to be Undefined!
          context.beginPath()
          context.arc points[0], points[1], points[2], 0, 2 * Math.PI
          context.closePath()
          if data.fill
            context.globalAlpha = data.fillAlpha * worldAlpha
            context.fillStyle = color = "#" + ("00000" + (data.fillColor | 0).toString(16)).substr(-6)
            context.fill()
          if data.lineWidth
            context.globalAlpha = data.lineAlpha * worldAlpha
            context.stroke()
        else if data.type is Graphics.ELIP
          
          # elipse code taken from: http://stackoverflow.com/questions/2172798/how-to-draw-an-oval-in-html5-canvas
          elipseData = data.points
          w = elipseData[2] * 2
          h = elipseData[3] * 2
          x = elipseData[0] - w / 2
          y = elipseData[1] - h / 2
          context.beginPath()
          kappa = .5522848
          ox = (w / 2) * kappa # control point offset horizontal
          oy = (h / 2) * kappa # control point offset vertical
          xe = x + w # x-end
          ye = y + h # y-end
          xm = x + w / 2 # x-middle
          ym = y + h / 2 # y-middle
          context.moveTo x, ym
          context.bezierCurveTo x, ym - oy, xm - ox, y, xm, y
          context.bezierCurveTo xm + ox, y, xe, ym - oy, xe, ym
          context.bezierCurveTo xe, ym + oy, xm + ox, ye, xm, ye
          context.bezierCurveTo xm - ox, ye, x, ym + oy, x, ym
          context.closePath()
          if data.fill
            context.globalAlpha = data.fillAlpha * worldAlpha
            context.fillStyle = color = "#" + ("00000" + (data.fillColor | 0).toString(16)).substr(-6)
            context.fill()
          if data.lineWidth
            context.globalAlpha = data.lineAlpha * worldAlpha
            context.stroke()
        i++

    #
    # * Renders a graphics mask
    # *
    # * @static
    # * @private
    # * @method renderGraphicsMask
    # * @param graphics {Graphics}
    # * @param context {Context2D}
    # 
    @renderGraphicsMask: (graphics, context) ->
      worldAlpha = graphics.worldAlpha
      len = graphics.graphicsData.length
      if len > 1
        len = 1
        console.log "Pixi.js warning: masks in canvas can only mask using the first path in the graphics object"
      i = 0

      while i < 1
        data = graphics.graphicsData[i]
        points = data.points
        if data.type is Graphics.POLY
          
          #if(data.lineWidth <= 0)continue;
          context.beginPath()
          context.moveTo points[0], points[1]
          j = 1

          while j < points.length / 2
            context.lineTo points[j * 2], points[j * 2 + 1]
            j++
          
          # if the first and last point are the same close the path - much neater :)
          context.closePath()  if points[0] is points[points.length - 2] and points[1] is points[points.length - 1]
        else if data.type is Graphics.RECT
          context.beginPath()
          context.rect points[0], points[1], points[2], points[3]
          context.closePath()
        else if data.type is Graphics.CIRC
          
          # TODO - need to be Undefined!
          context.beginPath()
          context.arc points[0], points[1], points[2], 0, 2 * Math.PI
          context.closePath()
        else if data.type is Graphics.ELIP
          
          # elipse code taken from: http://stackoverflow.com/questions/2172798/how-to-draw-an-oval-in-html5-canvas
          elipseData = data.points
          w = elipseData[2] * 2
          h = elipseData[3] * 2
          x = elipseData[0] - w / 2
          y = elipseData[1] - h / 2
          context.beginPath()
          kappa = .5522848
          ox = (w / 2) * kappa # control point offset horizontal
          oy = (h / 2) * kappa # control point offset vertical
          xe = x + w # x-end
          ye = y + h # y-end
          xm = x + w / 2 # x-middle
          ym = y + h / 2 # y-middle
          context.moveTo x, ym
          context.bezierCurveTo x, ym - oy, xm - ox, y, xm, y
          context.bezierCurveTo xm + ox, y, xe, ym - oy, xe, ym
          context.bezierCurveTo xe, ym + oy, xm + ox, ye, xm, ye
          context.bezierCurveTo xm - ox, ye, x, ym + oy, x, ym
          context.closePath()
        i++
