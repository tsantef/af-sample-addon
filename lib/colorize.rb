def colorize(str, beginColor, endColor = 0)
  "\e[#{beginColor}m#{str}\e[#{endColor}m"
end

def bright(str, endColor = 0)
  colorize(str, 1, endColor)
end

def white(str, endColor = 0)
  colorize(str, 37, endColor)
end

def red(str, endColor = 0)
  colorize(str, 31, endColor)
end

def green(str, endColor = 0)
  colorize(str, 32, endColor)
end

def bgreen(str, endColor = 0)
  colorize(str, "1;32", endColor)
end
