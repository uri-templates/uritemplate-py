import tpg
import re
import copy

def sub_identity(variables, arg, values):
    key = variables.keys()[0]
    return values.get(key, variables[key] or "")

def sub_prefix(variables, arg, values):
    key = variables.keys()[0]
    value = values.get(key, variables[key])
    if None != value:
        return arg + value
    else:
        return ""

def sub_postfix(variables, arg, values):
    key = variables.keys()[0]
    value = values.get(key, variables[key])
    if None != value:
        return value + arg
    else:
        return ""

# Is order important?
def sub_join(variables, arg, values):
  retval = []
  for key in sorted(variables.iterkeys()):
    value = values.get(key, variables[key])
    if None != value:
      retval.append("%s=%s" % (key, value))
  return arg.join(retval)

def sub_listjoin(variables, arg, values):
  key = variables.keys()[0]
  value = values.get(key, [])
  return arg.join(value)

def sub_if_non_zero(variables, arg, values):
  key = variables.keys()[0]
  value = values.get(key, None)
  if None != value:
    if (getattr(value, '__iter__', False) and len(value) == 0):
      return ""
    else:
      return arg
  else:
    return ""

def sub_if_zero(variables, arg, values):
  if sub_if_non_zero(variables, arg, values):
    return ""
  else:
    return arg


ESC_COLONS = re.compile(r"\\:")
def unescape_colons(s):
  return ESC_COLONS.sub(":", s[:-1])

def unreserved(c):
  return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") or (c in "-_~.")

def encode_unreserved(c):
  if unreserved(c):
    return c
  else:
    return "%%%02X" % ord(c)

def percent_encode_str(s):
  if None == s:
    return None
  if isinstance(s, unicode):
    s = s.encode("utf-8")
  return "".join([encode_unreserved(c) for c in s])

def percent_encode(values):
  retval = {}
  for key, value in values.iteritems():
    if (getattr(value, '__iter__', False)):
      retval[key] = [percent_encode_str(s) for s in value]
    else:
      retval[key] = percent_encode_str(value)
  return retval


class ParsedTemplate(object):
  def __init__(self, vars, substitute, arg):
    self.vars = vars
    self.substitute = substitute
    self.arg = arg

  def sub(self, values):
    return self.substitute(self.vars, self.arg, percent_encode(values))

  def variables(self):
    return self.vars.keys()

# The result of parsing is a ParsedTemplate
class Parser(tpg.Parser):
  r"""
  set lexer = ContextSensitiveLexer

  token arg        '.*(?<!\\):'                           $ unescape_colons
  token varname    '[\w\-\.~]+' ;
  token vardefault '[\w\-\.\~\%]+' ;

  START/e    -> Template/e;
  Template/t ->
       IdentityOperatorTemplate/tpl                       $ t = ParsedTemplate(*tpl)
     | OperatorTemplate/tpl                               $ t = ParsedTemplate(*tpl)
     ;
  IdentityOperatorTemplate/i -> Var/var                   $ i = (var, sub_identity, "")$ ;
  OperatorTemplate/o         ->
       '>'  arg/arg  Var/var                              $ o = (var, sub_postfix,     arg)
     | '<'  arg/arg  Var/var                              $ o = (var, sub_prefix,      arg)
     | ','  arg/arg  Vars/var                             $ o = (var, sub_join,       arg)
     | '\|' arg/arg  VarNoDefault/var                     $ o = (var, sub_listjoin,    arg)
     | '\?' arg/arg  VarNoDefault/var                     $ o = (var, sub_if_non_zero, arg)
     | '!'  arg/arg  VarNoDefault/var                     $ o = (var, sub_if_zero,     arg)

     ;
  Vars/var                     -> Var/var
                                 (
                                    ',' Var/i             $ var.update(i)
                                 ) * ;
  Var/var                      -> varname/name            $ var = {name: None}
                                 (
                                   '=' vardefault/default $ var[name] = default
                                 ) ? ;
  VarNoDefault/var             -> varname/name            $ var = {name: None}$ ;
  """


class DummyParsed(object):
  def __init__(self, s):
    self.s = s

  def sub(self, values):
    return self.s

  def variables(self):
    return {}

class URITemplate(object):
  def __init__(self, uri_template):
    self.uri_template = uri_template
    parts = re.split("(\{[^\}]*\})", uri_template)
    self.parsed_templates = []
    parser = Parser()
    for p in parts:
      if p and p[0] == '{':
        self.parsed_templates.append(parser(p[1:-1]))
      else:
        self.parsed_templates.append(DummyParsed(p))

  def variables(self):
    retval = set() 
    for p in self.parsed_templates:
      retval.update(set(p.variables()))
    return retval

  def sub(self, values):
    retval = []
    for p in self.parsed_templates:
      retval.append(p.sub(values))
    return "".join(retval)

if __name__ == "__main__":
  import unittest

  class Test(unittest.TestCase):
    def test_syntax_errors(self):
      p = Parser()
      syntax_errors = [
        "fred=",
        "f:",
        "f<",
        "<:",
        "<:fred,barney",
        ">:",
        ">:fred,barney"
      ]
      for s in syntax_errors:
        try:
          p(s)
          self.fail("Syntax error should have been raised.")
        except tpg.SyntacticError:
          pass

    def test_pre(self):
      p = Parser()
      test_cases = [
      # ( template,  values,  expected)
      ( "foo",       {},                 "" ),
      ( "foo",       {"foo": "barney"},  "barney" ),
      ( "foo=wilma", {},                 "wilma" ),
      ( "foo=wilma", {"foo": "barney"},  "barney" ),

      ( "<&:foo",       {},                 "" ),
      ( "<&:foo=wilma", {},                 "&wilma" ),
      ( "<&:foo=wilma", {"foo": "barney"},  "&barney" ),

      ( ">/:foo",        {},                 "" ),
      ( ">#:foo=wilma",  {},                 "wilma#" ),
      ( ">&?:foo=wilma", {"foo": "barney"},  "barney&?" ),

      ( ",/:foo",                  {},                 "" ),
      ( ",#:foo=wilma",            {},                 "foo=wilma"),
      ( ",#:foo=wilma,bar",        {},                 "foo=wilma"),
      ( ",#:foo=wilma,bar=barney", {},                 "bar=barney#foo=wilma"),
      ( ",&?:foo=wilma",           {"foo": "barney"},  "foo=barney" ),

      ( "|/:foo",       {},                    "" ),
      ( "|/:foo",       {"foo": ["a", "b"]},   "a/b"),
      ( "|/:foo",       {"foo": ["a"]},        "a"),
      ( "|/:foo",       {"foo": []},           ""),

      ( "?&:foo",       {},        ""),
      ( "?&:foo",       {"foo": "fred"},        "&"),
      ( "?&:foo",       {"foo": []},            ""),
      ( "?&:foo",       {"foo": ["a"]},         "&"),

      ( "!&:foo",       {},                     "&"),
      ( "!&:foo",       {"foo": "fred"},        ""),
      ( "!&:foo",       {"foo": []},            "&"),
      ( "!&:foo",       {"foo": ["a"]},         ""),

      ( "foo",          {"foo": " "},           "%20" ),
      ( "|&:foo",       {"foo": ["&", "&", "|", "_"]},   "%26&%26&%7C&_" )

      ]

      for (template, values, expected) in test_cases:
        parsed = p(template)
        self.assertEqual(expected, parsed.sub(values))

  class TestURITemplate(unittest.TestCase):
    def test_simple(self):
      t = URITemplate("http://example.org/news/{id}/")
      self.assertEqual(set(["id"]), t.variables())
      self.assertEqual("http://example.org/news/joe/", t.sub({"id": "joe"}))

      t = URITemplate("http://www.google.com/notebook/feeds/{userID}{</notebooks/:notebookID}{?/-/:categories}{|/:categories}?{,&:updated-min,updated-max,alt,start-index,max-results,entryID,orderby}")
      self.assertEqual(set(['max-results', 'orderby', 'notebookID',
        'start-index', 'userID', 'updated-max', 'entryID', 'alt',
        'updated-min', 'categories']), t.variables())
      self.assertEqual("http://www.google.com/notebook/feeds/joe?", t.sub({"userID": "joe"}))
      self.assertEqual("http://www.google.com/notebook/feeds/joe/-/A%7C-B/-C?start-index=10",
          t.sub({"userID": "joe", "categories": ["A|-B", "-C"], "start-index":
            "10"}))

  unittest.main()
