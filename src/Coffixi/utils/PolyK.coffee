#
#	PolyK library
#	url: http://polyk.ivank.net
#	Released under MIT licence.
#	
#	Copyright (c) 2012 Ivan Kuckir
#
#	Permission is hereby granted, free of charge, to any person
#	obtaining a copy of this software and associated documentation
#	files (the "Software"), to deal in the Software without
#	restriction, including without limitation the rights to use,
#	copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the
#	Software is furnished to do so, subject to the following
#	conditions:
#
#	The above copyright notice and this permission notice shall be
#	included in all copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#	OTHER DEALINGS IN THE SOFTWARE.
#
#	This is an amazing lib! 
#	
#	slightly modified by mat groves (matgroves.com);
#

define 'Coffixi/utils/PolyK', ->

  PolyK = {}

  ###
  Triangulates shapes for webGL graphic fills

  @method Triangulate
  @namespace PolyK
  @constructor
  ###
  PolyK.Triangulate = (p) ->
    sign = true
    n = p.length >> 1
    return []  if n < 3
    tgs = []
    avl = []
    i = 0

    while i < n
      avl.push i
      i++
    i = 0
    al = n
    while al > 3
      i0 = avl[(i + 0) % al]
      i1 = avl[(i + 1) % al]
      i2 = avl[(i + 2) % al]
      ax = p[2 * i0]
      ay = p[2 * i0 + 1]
      bx = p[2 * i1]
      _by = p[2 * i1 + 1]
      cx = p[2 * i2]
      cy = p[2 * i2 + 1]
      earFound = false
      if PolyK._convex(ax, ay, bx, _by, cx, cy, sign)
        earFound = true
        j = 0

        while j < al
          vi = avl[j]
          j++
          continue  if vi is i0 or vi is i1 or vi is i2
          if PolyK._PointInTriangle(p[2 * vi], p[2 * vi + 1], ax, ay, bx, _by, cx, cy)
            earFound = false
            break
      if earFound
        tgs.push i0, i1, i2
        avl.splice (i + 1) % al, 1
        al--
        i = 0
      else if i++ > 3 * al
        
        # need to flip flip reverse it!
        # reset!
        if sign
          tgs = []
          avl = []
          i = 0

          while i < n
            avl.push i
            i++
          i = 0
          al = n
          sign = false
        else
          console.log "PIXI Warning: shape too complex to fill"
          return []
    tgs.push avl[0], avl[1], avl[2]
    tgs


  ###
  Checks if a point is within a triangle

  @class _PointInTriangle
  @namespace PolyK
  @private
  ###
  PolyK._PointInTriangle = (px, py, ax, ay, bx, _by, cx, cy) ->
    v0x = cx - ax
    v0y = cy - ay
    v1x = bx - ax
    v1y = _by - ay
    v2x = px - ax
    v2y = py - ay
    dot00 = v0x * v0x + v0y * v0y
    dot01 = v0x * v1x + v0y * v1y
    dot02 = v0x * v2x + v0y * v2y
    dot11 = v1x * v1x + v1y * v1y
    dot12 = v1x * v2x + v1y * v2y
    invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    u = (dot11 * dot02 - dot01 * dot12) * invDenom
    v = (dot00 * dot12 - dot01 * dot02) * invDenom
    
    # Check if point is in triangle
    (u >= 0) and (v >= 0) and (u + v < 1)


  ###
  Checks if a shape is convex

  @class _convex
  @namespace PolyK
  @private
  ###
  PolyK._convex = (ax, ay, bx, _by, cx, cy, sign) ->
    ((ay - _by) * (cx - bx) + (bx - ax) * (cy - _by) >= 0) is sign

  return PolyK