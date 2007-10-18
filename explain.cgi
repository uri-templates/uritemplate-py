#!/home/jcgregorio/bin/python
# Copyright Google 2007
__contributors__ = ["Dan Connolly <connolly@w3.org>"]

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
    """
    >>> e = ",&|q,num"
    >>> explain(e, ' ' * 5, Parser()(e))
          Join the members of the list ['q', 'num'] together with ''.
    """
    op = expansion[1]
    var = parsed_exp.variables()
    arg = expansion[2:].split("|")[0]
    if op in descriptions:
        print "".join(line), descriptions[op] % vars()
    else:
        print "".join(line), descriptions["*"] % vars()

     

def handle_request():
  form = cgi.FieldStorage()
  if not form.has_key("t"):
    error("No URI Template was provided")
  else:
    template = form["t"].value
  try:
    parsed = URITemplate(template)
  except:
    error("Not a valid URI Template")

  print "Status: 200"
  print "Content-Type: text/plain"
  print ""
  print template
  expansions = []
  brackets(template, parsed, expansions)
  l = lines(template, expansions)
  explanations(template, expansions, l)


def brackets(template, parsed, expansions):
    """
    >>> t = 'http://example/s?{,&|q,num}'
    >>> brackets(t, URITemplate(t), [])
                     \________/
    """
    
    parts = re.split("(\{[^\}]*\})", template)
    length = 0
    line = [] 
    for p in parts:
      if len(p) and p[0] == '{':
        expansions.append((p, length+len(p)/2))
        line.append("\\")
        line.append("_" * (len(p)-2))
        line.append("/")
      else:
        line.append(" " * len(p))
      length += len(p)
    print "".join(line)

def lines(template, expansions):
    """
    >>> t = 'http://example/s?{,&|q,num}'
    >>> e = []
    >>> brackets(t, URITemplate(t), e)
                     \________/
    >>> len(lines(t, e))
                          |    
                          |    
    27
    """
    line = [" "] * len(template)
    for (s, middle) in expansions:
      line[middle] = "|"
    print "".join(line)
    print "".join(line)
    return line

def explanations(template, expansions, line):
    """
    >>> t = 'http://example/s?{,&|q,num}'
    >>> e = []
    >>> brackets(t, URITemplate(t), e)
                     \________/
    >>> l = lines(t, e)
                          |    
                          |    
    >>> explanations(t, e, l)
                          +-> Join 'var=value' for each variable in ['q', 'num'] with '&'.
    <BLANKLINE>             
  """
    parser = Parser()
    expansions.reverse()
    for (s, middle) in expansions:
        parsed_exp = parser(s[1:-1])
        line[middle] = "+"
        line[middle+1] = "-"
        line[middle+2] = ">"
        line = line[:middle+3]
        explain(s, line, parsed_exp)

        line = line[:middle-1]
        print "".join(line)


def _test():
  import doctest
  doctest.testmod()

if __name__ == '__main__':
  import sys
  if '--test' in sys.argv: 
    _test()
  else: 
    handle_request()
