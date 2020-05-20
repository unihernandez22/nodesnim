# author: Ethosa
import
  ../thirdparty/opengl,
  ../thirdparty/opengl/glut,

  ../core/vector2,
  ../core/rect2,
  ../core/anchor,
  ../core/input,
  ../core/enums,
  ../core/color,
  ../core/color_text,

  ../nodes/node,
  control


type
  RichLabelObj* = object of ControlPtr
    font*: pointer          ## Glut font data.
    spacing*: float         ## Font spacing.
    size*: float            ## Font size.
    text*: ColorTextRef     ## RichLabel text.
    text_align*: AnchorRef  ## Text align.
  RichLabelPtr* = ptr RichLabelObj


proc RichLabel*(name: string, variable: var RichLabelObj): RichLabelPtr =
  nodepattern(RichLabelObj)
  controlpattern()
  variable.rect_size.x = 40
  variable.rect_size.y = 40
  variable.text = clrtext""
  variable.font = GLUT_BITMAP_HELVETICA_12
  variable.size = 12
  variable.spacing = 2
  variable.text_align = Anchor(0, 0, 0, 0)

proc RichLabel*(obj: var RichLabelObj): RichLabelPtr {.inline.} =
  RichLabel("RichLabel", obj)


method draw*(self: RichLabelPtr, w, h: GLfloat) =
  self.calcGlobalPosition()
  let
    x = -w/2 + self.global_position.x
    y = h/2 - self.global_position.y

  glColor4f(self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a)
  glRectf(x, y, x+self.rect_size.x, y-self.rect_size.y)


  var th = 0f

  for line in self.text.splitLines():  # get text height
    th += self.spacing + self.size
  if th != 0:
    th -= self.spacing
  var ty = y - self.rect_size.y*self.text_align.y1 + th*self.text_align.y2 - self.size

  for line in self.text.splitLines():
    var tw = self.font.glutBitmapLength($line).float
    # Draw text:
    var tx = x + self.rect_size.x*self.text_align.x1 - tw * self.text_align.x2
    for c in line.chars:
      glColor4f(c.color.r, c.color.g, c.color.b, c.color.a)
      glRasterPos2f(tx, ty)  # set char position
      self.font.glutBitmapCharacter(c.c.int)  # render char
      tx += self.font.glutBitmapWidth(c.c.int).float
    ty -= self.spacing + self.size

  # Press
  if self.pressed:
    self.press(last_event.x, last_event.y)

method setTextAlign*(self: RichLabelPtr, align: AnchorRef) {.base.} =
  self.text_align = align

method setTextAlign*(self: RichLabelPtr, x1, y1, x2, y2: float) {.base.} =
  self.text_align = Anchor(x1, y1, x2, y2)
