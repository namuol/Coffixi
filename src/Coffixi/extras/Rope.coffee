###
@author Mat Groves http://matgroves.com/
###

define 'Coffixi/extras/Rope', [
  '../utils/Utils'
  './Strip'
], (
  Utils
  Strip
) ->

  class Rope extends Strip
    constructor: (texture, points) ->
      super

      @points = points
      try
        @verticies = new Utils.Float32Array(points.length * 4)
        @uvs = new Utils.Float32Array(points.length * 4)
        @colors = new Utils.Float32Array(points.length * 2)
        @indices = new Utils.Uint16Array(points.length * 2)
      catch error
        @verticies = verticies
        @uvs = uvs
        @colors = colors
        @indices = indices
      @refresh()

    refresh: ->
      points = @points
      return  if points.length < 1
      uvs = @uvs
      indices = @indices
      colors = @colors
      lastPoint = points[0]
      nextPoint = undefined
      perp =
        x: 0
        y: 0

      point = points[0]
      @count -= 0.2
      uvs[0] = 0
      uvs[1] = 1
      uvs[2] = 0
      uvs[3] = 1
      colors[0] = 1
      colors[1] = 1
      indices[0] = 0
      indices[1] = 1
      total = points.length
      i = 1

      while i < total
        point = points[i]
        index = i * 4
        
        # time to do some smart drawing!
        amount = i / (total - 1)
        if i % 2
          uvs[index] = amount
          uvs[index + 1] = 0
          uvs[index + 2] = amount
          uvs[index + 3] = 1
        else
          uvs[index] = amount
          uvs[index + 1] = 0
          uvs[index + 2] = amount
          uvs[index + 3] = 1
        index = i * 2
        colors[index] = 1
        colors[index + 1] = 1
        index = i * 2
        indices[index] = index
        indices[index + 1] = index + 1
        lastPoint = point
        i++

    updateTransform: ->
      points = @points
      return  if points.length < 1
      verticies = @verticies
      lastPoint = points[0]
      nextPoint = undefined
      perp =
        x: 0
        y: 0

      point = points[0]
      @count -= 0.2
      verticies[0] = point.x + perp.x
      verticies[1] = point.y + perp.y #+ 200
      verticies[2] = point.x - perp.x
      verticies[3] = point.y - perp.y #+200
      # time to do some smart drawing!
      total = points.length
      i = 1

      while i < total
        point = points[i]
        index = i * 4
        if i < points.length - 1
          nextPoint = points[i + 1]
        else
          nextPoint = point
        perp.y = -(nextPoint.x - lastPoint.x)
        perp.x = nextPoint.y - lastPoint.y
        ratio = (1 - (i / (total - 1))) * 10
        ratio = 1  if ratio > 1
        perpLength = Math.sqrt(perp.x * perp.x + perp.y * perp.y)
        num = @texture.height / 2 #(20 + Math.abs(Math.sin((i + this.count) * 0.3) * 50) )* ratio;
        perp.x /= perpLength
        perp.y /= perpLength
        perp.x *= num
        perp.y *= num
        verticies[index] = point.x + perp.x
        verticies[index + 1] = point.y + perp.y
        verticies[index + 2] = point.x - perp.x
        verticies[index + 3] = point.y - perp.y
        lastPoint = point
        i++

      super

    setTexture: (texture) ->
      
      # stop current texture 
      @texture = texture
      @updateFrame = true