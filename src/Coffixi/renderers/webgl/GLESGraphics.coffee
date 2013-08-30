###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/webgl/GLESGraphics', [
  'Coffixi/core/Point'
  'Coffixi/core/Matrix'
  'Coffixi/utils/PolyK'
  'Coffixi/primitives/Graphics'
  'Coffixi/renderers/webgl/GLESShaders'
  'Coffixi/utils/Utils'
], (
  Point
  Matrix
  PolyK
  Graphics
  GLESShaders
  Utils
) ->

  ###
  A set of functions used by the webGL renderer to draw the primitive graphics data

  @class CanvasGraphics
  ###
  class GLESGraphics
    ###
    Renders the graphics object

    @static
    @private
    @method renderGraphics
    @param graphics {Graphics}
    @param projection {Object}
    ###
    @renderGraphics: (graphics, projection) ->
      gl = @gl
      unless graphics._GL
        graphics._GL =
          points: []
          indices: []
          lastIndex: 0
          buffer: gl.createBuffer()
          indexBuffer: gl.createBuffer()
      if graphics.dirty
        graphics.dirty = false
        if graphics.clearDirty
          graphics.clearDirty = false
          graphics._GL.lastIndex = 0
          graphics._GL.points = []
          graphics._GL.indices = []
        GLESGraphics.updateGraphics graphics
      GLESShaders.activatePrimitiveShader gl
      m = Matrix.mat3.clone(graphics.worldTransform)
      Matrix.mat3.transpose m
      gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
      gl.uniformMatrix3fv GLESShaders.primitiveShader.translationMatrix, false, m
      gl.uniform2f GLESShaders.primitiveShader.projectionVector, projection.x, projection.y
      gl.uniform1f GLESShaders.primitiveShader.alpha, graphics.worldAlpha
      gl.bindBuffer gl.ARRAY_BUFFER, graphics._GL.buffer
      gl.vertexAttribPointer GLESShaders.defaultShader.vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0
      gl.vertexAttribPointer GLESShaders.primitiveShader.vertexPositionAttribute, 2, gl.FLOAT, false, 4 * 6, 0
      gl.vertexAttribPointer GLESShaders.primitiveShader.colorAttribute, 4, gl.FLOAT, false, 4 * 6, 2 * 4
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, graphics._GL.indexBuffer
      gl.drawElements gl.TRIANGLE_STRIP, graphics._GL.indices.length, gl.UNSIGNED_SHORT, 0
      GLESShaders.activateDefaultShader gl

    ###
    Updates the graphics object

    @static
    @private
    @method updateGraphics
    @param graphics {Graphics}
    ###
    @updateGraphics: (graphics) ->
      i = graphics._GL.lastIndex

      while i < graphics.graphicsData.length
        data = graphics.graphicsData[i]
        if data.type is Graphics.POLY
          GLESGraphics.buildPoly data, graphics._GL  if data.points.length > 3  if data.fill
          GLESGraphics.buildLine data, graphics._GL  if data.lineWidth > 0
        else if data.type is Graphics.RECT
          GLESGraphics.buildRectangle data, graphics._GL
        else GLESGraphics.buildCircle data, graphics._GL  if data.type is Graphics.CIRC or data.type is Graphics.ELIP
        i++
      graphics._GL.lastIndex = graphics.graphicsData.length
      gl = @gl
      graphics._GL.glPoints = new Utils.Float32Array(graphics._GL.points)
      gl.bindBuffer gl.ARRAY_BUFFER, graphics._GL.buffer
      gl.bufferData gl.ARRAY_BUFFER, graphics._GL.glPoints, gl.STATIC_DRAW
      graphics._GL.glIndicies = new Utils.Uint16Array(graphics._GL.indices)
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, graphics._GL.indexBuffer
      gl.bufferData gl.ELEMENT_ARRAY_BUFFER, graphics._GL.glIndicies, gl.STATIC_DRAW

    ###
    Builds a rectangle to draw

    @static
    @private
    @method buildRectangle
    @param graphics {Graphics}
    @param webGLData {Object}
    ###
    @buildRectangle: (graphicsData, webGLData) ->
      rectData = graphicsData.points
      x = rectData[0]
      y = rectData[1]
      width = rectData[2]
      height = rectData[3]
      if graphicsData.fill
        color = Utils.HEXtoRGB(graphicsData.fillColor)
        alpha = graphicsData.fillAlpha
        r = color[0] * alpha
        g = color[1] * alpha
        b = color[2] * alpha
        verts = webGLData.points
        indices = webGLData.indices
        vertPos = verts.length / 6
        verts.push x, y
        verts.push r, g, b, alpha
        verts.push x + width, y
        verts.push r, g, b, alpha
        verts.push x, y + height
        verts.push r, g, b, alpha
        verts.push x + width, y + height
        verts.push r, g, b, alpha
        indices.push vertPos, vertPos, vertPos + 1, vertPos + 2, vertPos + 3, vertPos + 3
      if graphicsData.lineWidth
        graphicsData.points = [x, y, x + width, y, x + width, y + height, x, y + height, x, y]
        GLESGraphics.buildLine graphicsData, webGLData

    ###
    Builds a circle to draw

    @static
    @private
    @method buildCircle
    @param graphics {Graphics}
    @param webGLData {Object}
    ###
    @buildCircle: (graphicsData, webGLData) ->
      rectData = graphicsData.points
      x = rectData[0]
      y = rectData[1]
      width = rectData[2]
      height = rectData[3]
      totalSegs = 40
      seg = (Math.PI * 2) / totalSegs
      if graphicsData.fill
        color = Utils.HEXtoRGB(graphicsData.fillColor)
        alpha = graphicsData.fillAlpha
        r = color[0] * alpha
        g = color[1] * alpha
        b = color[2] * alpha
        verts = webGLData.points
        indices = webGLData.indices
        vecPos = verts.length / 6
        indices.push vecPos
        i = 0

        while i < totalSegs + 1
          verts.push x, y, r, g, b, alpha
          verts.push x + Math.sin(seg * i) * width, y + Math.cos(seg * i) * height, r, g, b, alpha
          indices.push vecPos++, vecPos++
          i++
        indices.push vecPos - 1
      if graphicsData.lineWidth
        graphicsData.points = []
        i = 0

        while i < totalSegs + 1
          graphicsData.points.push x + Math.sin(seg * i) * width, y + Math.cos(seg * i) * height
          i++
        GLESGraphics.buildLine graphicsData, webGLData

    ###
    Builds a line to draw

    @static
    @private
    @method buildLine
    @param graphics {Graphics}
    @param webGLData {Object}
    ###
    @buildLine: (graphicsData, webGLData) ->
      wrap = true
      points = graphicsData.points
      return  if points.length is 0
      firstPoint = new Point(points[0], points[1])
      lastPoint = new Point(points[points.length - 2], points[points.length - 1])
      if firstPoint.x is lastPoint.x and firstPoint.y is lastPoint.y
        points.pop()
        points.pop()
        lastPoint = new Point(points[points.length - 2], points[points.length - 1])
        midPointX = lastPoint.x + (firstPoint.x - lastPoint.x) * 0.5
        midPointY = lastPoint.y + (firstPoint.y - lastPoint.y) * 0.5
        points.unshift midPointX, midPointY
        points.push midPointX, midPointY
      verts = webGLData.points
      indices = webGLData.indices
      length = points.length / 2
      indexCount = points.length
      indexStart = verts.length / 6
      width = graphicsData.lineWidth / 2
      color = Utils.HEXtoRGB(graphicsData.lineColor)
      alpha = graphicsData.lineAlpha
      r = color[0] * alpha
      g = color[1] * alpha
      b = color[2] * alpha
      p1x = undefined
      p1y = undefined
      p2x = undefined
      p2y = undefined
      p3x = undefined
      p3y = undefined
      perpx = undefined
      perpy = undefined
      perp2x = undefined
      perp2y = undefined
      perp3x = undefined
      perp3y = undefined
      ipx = undefined
      ipy = undefined
      a1 = undefined
      b1 = undefined
      c1 = undefined
      a2 = undefined
      b2 = undefined
      c2 = undefined
      denom = undefined
      pdist = undefined
      dist = undefined
      p1x = points[0]
      p1y = points[1]
      p2x = points[2]
      p2y = points[3]
      perpx = -(p1y - p2y)
      perpy = p1x - p2x
      dist = Math.sqrt(perpx * perpx + perpy * perpy)
      perpx /= dist
      perpy /= dist
      perpx *= width
      perpy *= width
      verts.push p1x - perpx, p1y - perpy, r, g, b, alpha
      verts.push p1x + perpx, p1y + perpy, r, g, b, alpha
      i = 1

      while i < length - 1
        p1x = points[(i - 1) * 2]
        p1y = points[(i - 1) * 2 + 1]
        p2x = points[(i) * 2]
        p2y = points[(i) * 2 + 1]
        p3x = points[(i + 1) * 2]
        p3y = points[(i + 1) * 2 + 1]
        perpx = -(p1y - p2y)
        perpy = p1x - p2x
        dist = Math.sqrt(perpx * perpx + perpy * perpy)
        perpx /= dist
        perpy /= dist
        perpx *= width
        perpy *= width
        perp2x = -(p2y - p3y)
        perp2y = p2x - p3x
        dist = Math.sqrt(perp2x * perp2x + perp2y * perp2y)
        perp2x /= dist
        perp2y /= dist
        perp2x *= width
        perp2y *= width
        a1 = (-perpy + p1y) - (-perpy + p2y)
        b1 = (-perpx + p2x) - (-perpx + p1x)
        c1 = (-perpx + p1x) * (-perpy + p2y) - (-perpx + p2x) * (-perpy + p1y)
        a2 = (-perp2y + p3y) - (-perp2y + p2y)
        b2 = (-perp2x + p2x) - (-perp2x + p3x)
        c2 = (-perp2x + p3x) * (-perp2y + p2y) - (-perp2x + p2x) * (-perp2y + p3y)
        denom = a1 * b2 - a2 * b1
        denom += 1  if denom is 0
        px = (b1 * c2 - b2 * c1) / denom
        py = (a2 * c1 - a1 * c2) / denom
        pdist = (px - p2x) * (px - p2x) + (py - p2y) + (py - p2y)
        if pdist > 140 * 140
          perp3x = perpx - perp2x
          perp3y = perpy - perp2y
          dist = Math.sqrt(perp3x * perp3x + perp3y * perp3y)
          perp3x /= dist
          perp3y /= dist
          perp3x *= width
          perp3y *= width
          verts.push p2x - perp3x, p2y - perp3y
          verts.push r, g, b, alpha
          verts.push p2x + perp3x, p2y + perp3y
          verts.push r, g, b, alpha
          verts.push p2x - perp3x, p2y - perp3y
          verts.push r, g, b, alpha
          indexCount++
        else
          verts.push px, py
          verts.push r, g, b, alpha
          verts.push p2x - (px - p2x), p2y - (py - p2y)
          verts.push r, g, b, alpha
        i++
      p1x = points[(length - 2) * 2]
      p1y = points[(length - 2) * 2 + 1]
      p2x = points[(length - 1) * 2]
      p2y = points[(length - 1) * 2 + 1]
      perpx = -(p1y - p2y)
      perpy = p1x - p2x
      dist = Math.sqrt(perpx * perpx + perpy * perpy)
      perpx /= dist
      perpy /= dist
      perpx *= width
      perpy *= width
      verts.push p2x - perpx, p2y - perpy
      verts.push r, g, b, alpha
      verts.push p2x + perpx, p2y + perpy
      verts.push r, g, b, alpha
      indices.push indexStart
      i = 0

      while i < indexCount
        indices.push indexStart++
        i++
      indices.push indexStart - 1

    ###
    Builds a polygon to draw

    @static
    @private
    @method buildPoly
    @param graphics {Graphics}
    @param webGLData {Object}
    ###
    @buildPoly: (graphicsData, webGLData) ->
      points = graphicsData.points
      return  if points.length < 6
      verts = webGLData.points
      indices = webGLData.indices
      length = points.length / 2
      color = Utils.HEXtoRGB(graphicsData.fillColor)
      alpha = graphicsData.fillAlpha
      r = color[0] * alpha
      g = color[1] * alpha
      b = color[2] * alpha
      triangles = PolyK.Triangulate(points)
      vertPos = verts.length / 6
      i = 0

      while i < triangles.length
        indices.push triangles[i] + vertPos
        indices.push triangles[i] + vertPos
        indices.push triangles[i + 1] + vertPos
        indices.push triangles[i + 2] + vertPos
        indices.push triangles[i + 2] + vertPos
        i += 3
      i = 0

      while i < length
        verts.push points[i * 2], points[i * 2 + 1], r, g, b, alpha
        i++
