define 'Coffixi/utils/Module', ->
  
  # From http://arcturo.github.io/library/coffeescript/03_classes.html

  moduleKeywords = ['extended', 'included']

  class Module
    @extend: (obj) ->
      for key, value of obj when key not in moduleKeywords
        @[key] = value

      obj.extended?.apply(@)
      return @

    @include: (obj) ->
      for key, value of obj when key not in moduleKeywords
        # Assign properties to the prototype
        @::[key] = value

      obj.included?.apply(@)
      return @

  return Module