define 'Coffixi/utils/Module', ->
  # LOU TODO: Docs
    
  # From http://arcturo.github.io/library/coffeescript/03_classes.html

  moduleKeywords = ['onMixinStatic', 'onMixin', 'constructor']

  class Module
    @mixinStatic: (obj) ->
      for key, value of obj when key not in moduleKeywords
        @[key] = value

      obj.onMixinStatic?.call(@)
      return @

    @mixin: (obj) ->
      for key, value of obj when key not in moduleKeywords
        # Assign properties to the prototype
        @::[key] = value

      obj.onMixin?.call(@)
      return @

  return Module