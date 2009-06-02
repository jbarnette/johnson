
function create_frame(title, width, height)
{
  var frame;
  frame = Ruby.Java.javax().swing().JFrame().new(title);
  frame.setSize(width, height);
  return frame;
}


