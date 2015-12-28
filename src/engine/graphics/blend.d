/**
 * Control how colors are blended when drawing.
 */
module engine.graphics.blend;

import allegro5.allegro;

enum BlendMode
{
  zero            = ALLEGRO_BLEND_MODE.ALLEGRO_ZERO              ,
  one             = ALLEGRO_BLEND_MODE.ALLEGRO_ONE               ,
  alpha           = ALLEGRO_BLEND_MODE.ALLEGRO_ALPHA             ,
  inverseAlpha    = ALLEGRO_BLEND_MODE.ALLEGRO_INVERSE_ALPHA     ,
  srcColor        = ALLEGRO_BLEND_MODE.ALLEGRO_SRC_COLOR         ,
  dstColor        = ALLEGRO_BLEND_MODE.ALLEGRO_DEST_COLOR        ,
  inverseSrcColor = ALLEGRO_BLEND_MODE.ALLEGRO_INVERSE_SRC_COLOR ,
  inverseDstColor = ALLEGRO_BLEND_MODE.ALLEGRO_INVERSE_DEST_COLOR,
}

enum BlendOp
{
  add         = ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD           ,
  srcMinusDst = ALLEGRO_BLEND_OPERATIONS.ALLEGRO_SRC_MINUS_DEST,
  dstMinusSrc = ALLEGRO_BLEND_OPERATIONS.ALLEGRO_DEST_MINUS_SRC,
}

struct Blender {
  BlendOp   op  = BlendOp.add;
  BlendMode src = BlendMode.alpha;
  BlendMode dst = BlendMode.inverseAlpha;
}
