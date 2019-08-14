
def write(text)
  print text
  $stdout.flush
end

# Move cursor n character towards the beginning of the line
def left(n=1)
  print "\033[#{n}D"
end

# Erase (from cursor to) End Of Line
def eeol
  print "\033[K"
end

# Move to beginning of line and erase
def rewind
  print "\r"
  eeol
end
