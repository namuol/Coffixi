define [
  'DisplayObject'
  'DisplayObjectContainer'
  'InteractionManager'
  'loaders/AssetLoader'
  'loaders/SpriteSheetLoader'
  'MovieClip'
  'Point'
  'Rectangle'
  'renderers/CanvasRenderer'
  'Sprite'
  'Stage'
  'textures/BaseTexture'
  'textures/Texture'
  'utils/Detector'
  'utils/EventTarget'
  'utils/Matrix'
  'utils/Utils'
], (
  DisplayObject,
  DisplayObjectContainer,
  InteractionManager,
  AssetLoader,
  SpriteSheetLoader,
  MovieClip,
  Point,
  Rectangle,
  CanvasRenderer,
  Sprite,
  Stage,
  BaseTexture,
  Texture,
  Detector,
  EventTarget,
  Matrix,
  Utils
) ->
  PIXI = {}

  PIXI.DisplayObject = DisplayObject
  PIXI.DisplayObjectContainer = DisplayObjectContainer
  PIXI.InteractionManager = InteractionManager
  PIXI.AssetLoader = AssetLoader
  PIXI.SpriteSheetLoader = SpriteSheetLoader
  PIXI.MovieClip = MovieClip
  PIXI.Point = Point
  PIXI.Rectangle = Rectangle
  PIXI.CanvasRenderer = CanvasRenderer
  PIXI.Sprite = Sprite
  PIXI.Stage = Stage
  PIXI.BaseTexture = BaseTexture
  PIXI.Texture = Texture
  PIXI.Detector = Detector
  PIXI.autoDetectRenderer = Detector.autoDetectRenderer
  PIXI.EventTarget = EventTarget
  PIXI.Matrix = Matrix
  PIXI.Utils = Utils

  window.PIXI = PIXI
  return PIXI