# author: Ethosa
## The base of other Control nodes.
import
  ../thirdparty/opengl,

  ../core/vector2,
  ../core/rect2,
  ../core/anchor,
  ../core/input,
  ../core/enums,
  ../core/color,

  ../nodes/node,
  ../nodes/canvas


type
  ControlObj* = object of CanvasObj
    hovered*: bool
    pressed*: bool
    focused*: bool

    mousemode*: MouseMode
    background_color*: ColorRef

    on_mouse_enter*: proc(self: ControlRef, x, y: float): void  ## This called when the mouse enters the Control node.
    on_mouse_exit*: proc(self: ControlRef, x, y: float): void   ## This called when the mouse exit from the Control node.
    on_click*: proc(self: ControlRef, x, y: float): void        ## This called when the user clicks on the Control node.
    on_press*: proc(self: ControlRef, x, y: float): void        ## This called when the user holds on the mouse on the Control node.
    on_release*: proc(self: ControlRef, x, y: float): void      ## This called when the user no more holds on the mouse.
    on_focus*: proc(self: ControlRef): void                   ## This called when the Control node gets focus.
    on_unfocus*: proc(self: ControlRef): void                 ## This called when the Control node loses focus.
  ControlRef* = ref ControlObj


template controlpattern*: untyped =
  result.hovered = false
  result.focused = false
  result.pressed = false

  result.mousemode = MOUSEMODE_SEE
  result.background_color = Color()

  result.on_mouse_enter = proc(self: ControlRef, x, y: float) = discard
  result.on_mouse_exit = proc(self: ControlRef, x, y: float) = discard
  result.on_click = proc(self: ControlRef, x, y: float) = discard
  result.on_press = proc(self: ControlRef, x, y: float) = discard
  result.on_release = proc(self: ControlRef, x, y: float) = discard
  result.on_focus = proc(self: ControlRef) = discard
  result.on_unfocus = proc(self: ControlRef) = discard
  result.type_of_node = NODE_TYPE_CONTROL

proc Control*(name: string = "Control"): ControlRef =
  ## Creates a new Control.
  ##
  ## Arguments:
  ## - `name` is a node name.
  runnableExamples:
    var ctrl = Control("Control")
  nodepattern(ControlRef)
  controlpattern()
  result.kind = CONTROL_NODE


method calcPositionAnchor*(self: ControlRef) =
  ## Calculates node position. This uses in the `scene.nim`.
  if self.parent != nil:
    if self.can_use_size_anchor:
      if self.size_anchor.x > 0.0:
        self.rect_size.x = self.parent.rect_size.x * self.size_anchor.x
      if self.size_anchor.y > 0.0:
        self.rect_size.y = self.parent.rect_size.y * self.size_anchor.y
    if self.can_use_anchor:
      self.position.x = self.parent.rect_size.x*self.anchor.x1 - self.rect_size.x*self.anchor.x2
      self.position.y = self.parent.rect_size.y*self.anchor.y1 - self.rect_size.y*self.anchor.y2

method draw*(self: ControlRef, w, h: GLfloat) =
  ## this method uses in the `window.nim`.
  {.warning[LockLevel]: off.}
  let
    x = -w/2 + self.global_position.x
    y = h/2 - self.global_position.y

  glColor4f(self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a)
  glRectf(x, y, x+self.rect_size.x, y-self.rect_size.y)

  # Press
  if self.pressed:
    self.on_press(self, last_event.x, last_event.y)

method duplicate*(self: ControlRef): ControlRef {.base.} =
  ## Duplicates Control object and create a new Control.
  self.deepCopy()

method getGlobalMousePosition*(self: ControlRef): Vector2Ref {.base, inline.} =
  ## Returns mouse position.
  Vector2Ref(x: last_event.x, y: last_event.y)

method handle*(self: ControlRef, event: InputEvent, mouse_on: var NodeRef) =
  ## Handles user input. This uses in the `window.nim`.
  {.warning[LockLevel]: off.}
  if self.mousemode == MOUSEMODE_IGNORE:
    return
  let
    hasmouse = Rect2(self.global_position, self.rect_size).contains(event.x, event.y)
    click = mouse_pressed and event.kind == MOUSE
  if mouse_on == nil and hasmouse:
    mouse_on = self
    # Hover
    if not self.hovered:
      self.on_mouse_enter(self, event.x, event.y)
      self.hovered = true
    # Focus
    if not self.focused and click:
      self.focused = true
      self.on_focus(self)
    # Click
    if mouse_pressed and not self.pressed:
      self.pressed = true
      self.on_click(self, event.x, event.y)
  elif not hasmouse or mouse_on != self:
    if not mouse_pressed and self.hovered:
      self.on_mouse_exit(self, event.x, event.y)
      self.hovered = false
    # Unfocus
    if self.focused and click:
      self.on_unfocus(self)
      self.focused = false
  if not mouse_pressed and self.pressed:
    self.pressed = false
    self.on_release(self, event.x, event.y)

method setBackgroundColor*(self: ControlRef, color: ColorRef) {.base.} =
  ## Changes Control background color.
  self.background_color = color
