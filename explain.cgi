#!/home/jcgregorio/bin/python
from template_parser import Parser, URITemplate
import cgi
import re
import cgitb; cgitb.enable()

def error(msg):
  print "Status: 400"
  print "Content-Type: text/plain"
  print ""
  print msg


descriptions = {
 "<" : "If %(var)s is defined then prefix the value of %(var)s with '%(arg)s'.",
 ">" : "If %(var)s is defined then append the value of %(var)s with '%(arg)s'.",
 "?" : "If %(var)s is defined and a string, or a list with one or more members, then insert '%(arg)s' into the URI.",
 "!" : "If %(var)s is undefined, or a zero length list, then insert '%(arg)s' into the URI.",
 "," : "Join 'var=value' for each variable in %(var)s with '%(arg)s'.",
 "&" : "Join the members of the list %(var)s together with '%(arg)s'.",
 "*" : "Replaced with the value of %(var)s."
}

def explain(expansion, line, parsed_exp):
    op = expansion[1]
    var = parsed_exp.variables()
    arg = expansion[2:].split("|")[0]
    if op in descriptions:
        print "".join(line), descriptions[op] % vars()
    else:
        print "".join(line), descriptions["*"] % vars()

     

form = cgi.FieldStorage()
if not form.has_key("t"):
  error("No URI Template was provided")
else:
  template = form["t"].value

  print "Status: 200"
  print "Content-Type: text/plain"
  print ""
  print template
  parts = re.split("(\{[^\}]*\})", template)
  try:
    parsed = URITemplate(template)
  except:
    error("Not a valid URI Template")
  parser = Parser()
  expansions = []
  length = 0
  line = [] 
  for p in parts:
    if len(p) and p[0] == '{':
      expansions.append((p, length, length+len(p), length+len(p)/2))
      line.append("\\")
      line.append("_" * (len(p)-2))
      line.append("/")
    else:
      line.append(" " * len(p))
    length += len(p)
  print "".join(line)
  line = [" "] * len(template)
  for (s, begin, end, middle) in expansions:
    line[middle] = "|"
  print "".join(line)
  print "".join(line)
  expansions.reverse()
  for (s, begin, end, middle) in expansions:
      parsed_exp = parser(s[1:-1])
      line[middle] = "+"
      line[middle+1] = "-"
      line[middle+2] = ">"
      line = line[:middle+3]
      "".join(line)
      explain(s, line, parsed_exp)

      line = line[:middle-1]
      print "".join(line)
      
  
