###
@author Adrien Brault <adrien.brault@gmail.com>
###

define 'Coffixi/core/Polygon', [
  './Point'
], (
  Point
) ->

  ###
  @class Polygon
  @constructor
  @param points* {Array<Point>|Array<Number>|Point...|Number...} This can be an array of Points that form the polygon,
  a flat array of numbers that will be interpreted as [x,y, x,y, ...], or the arugments passed can be
  all the points of the polygon e.g. `new Polygon(new Point(), new Point(), ...)`, or the
  arguments passed can be flat x,y values e.g. `new Polygon(x,y, x,y, x,y, ...)` where `x` and `y` are
  Numbers.
  ###
  class Polygon
    constructor: (points) ->
      
      #if points isn't an array, use arguments as the array
      points = Array::slice.call(arguments)  unless points instanceof Array
      
      #if this is a flat array of numbers, convert it to points
      if typeof points[0] is "number"
        p = []
        i = 0
        il = points.length

        while i < il
          p.push new Point(points[i], points[i + 1])
          i += 2
        points = p
      @points = points

    ###
    Creates a clone of this polygon

    @method clone
    @return {Polygon} a copy of the polygon
    ###
    clone: ->
      points = []
      i = 0

      while i < @points.length
        points.push @points[i].clone()
        i++
      new Polygon(points)

    ###
    Checks if the x, and y coords passed to this function are contained within this polygon

    @method contains
    @param x {Number} The X coord of the point to test
    @param y {Number} The Y coord of the point to test
    @return {Boolean} if the x/y coords are within this polygon
    ###
    contains: (x, y) ->
      inside = false
      
      # use some raycasting to test hits
      # https://github.com/substack/point-in-polygon/blob/master/index.js
      i = 0
      j = @points.length - 1

      while i < @points.length
        xi = @points[i].x
        yi = @points[i].y
        xj = @points[j].x
        yj = @points[j].y
        intersect = ((yi > y) isnt (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
        inside = not inside  if intersect
        j = i++
      inside
