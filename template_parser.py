# Copyright 2007 Google Inc.

import tpg
import re
import copy
import unicodedata

# Each sub_XXX function takes the following arguments:
# variables - A dict of variable names to default values.
# arg - the template <arg> string
# values - Values for variables supplied by the caller.

def sub_identity(variables, arg, values, varorder):
    key = variables.keys()[0]
    return values.get(key, variables[key] or "")

def sub_prefix(variables, arg, values, varorder):
    key = variables.keys()[0]
    value = values.get(key, variables[key])
    if None == value:
        return ""
    elif type(value) == type([]):
        return arg + arg.join(value)
    else:
        return arg + value                        


def sub_postfix(variables, arg, values, varorder):
    key = variables.keys()[0]
    value = values.get(key, variables[key])
    if None == value:
        return ""
    elif type(value) == type([]):
        return arg.join(value) + arg
    else:
        return value + arg               


# Is order important?
def sub_join(variables, arg, values, varorder):
  retval = []
  for key in varorder:
    value = values.get(key, variables[key])
    if None != value:
      retval.append("%s=%s" % (key, value))
  return arg.join(retval)

def sub_listjoin(variables, arg, values, varorder):
  key = variables.keys()[0]
  value = values.get(key, [])
  return arg.join(value)

def sub_if_non_zero(variables, arg, values, varorder):
  for key in variables.keys():
    value = values.get(key, None)
    if None != value:
      if (getattr(value, '__iter__', False) and len(value) == 0):
        continue 
      else:
        return arg
  return ""

def sub_if_zero(variables, arg, values, varorder):
  if sub_if_non_zero(variables, arg, values, varorder):
    return ""
  else:
    return arg

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
    s = unicodedata.normalize('NFKC', s)
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
  def __init__(self, vars, substitute, arg, varorder):
    self.vars = vars
    self.substitute = substitute
    self.arg = arg
    self.varorder = varorder

  def sub(self, values):
    return self.substitute(self.vars, self.arg, percent_encode(values), self.varorder)

  def variables(self):
    return self.vars.keys()

# The result of parsing is a ParsedTemplate
class Parser(tpg.Parser):
  r"""
  set lexer = ContextSensitiveLexer

  token arg        '[^\|]*';
  token varname    '[a-zA-Z0-9][a-zA-Z0-9\_\.\-]*' ;
  token vardefault '[\w\-\.\~\%]+' ;
  token num        '[0-9]+';

  START/e    -> Template/e;
  Template/t ->
       IdentityOperatorTemplate/tpl                       $ t = ParsedTemplate(*tpl)
     | OperatorTemplate/tpl                               $ t = ParsedTemplate(*tpl)
     ;
  IdentityOperatorTemplate/i -> Var/var                   $ i = (var[0], sub_identity, "", var[1])$ ;
  OperatorTemplate/o         ->
       '-suffix\|'   arg/arg '\|' Var/var                 $ o = (var[0], sub_postfix,     arg, var[1])
     | '-prefix\|'   arg/arg '\|' Var/var                 $ o = (var[0], sub_prefix,      arg, var[1])
     | '-join\|'     arg/arg '\|' Vars/var                $ o = (var[0], sub_join,        arg, var[1])
     | '-list\|'     arg/arg '\|' VarNoDefault/var        $ o = (var[0], sub_listjoin,    arg, var[1])
     | '-opt\|'      arg/arg '\|' Vars/var                $ o = (var[0], sub_if_non_zero, arg, var[1])
     | '-neg\|'      arg/arg '\|' Vars/var                $ o = (var[0], sub_if_zero,     arg, var[1])
     ;
  Vars/var                     -> Var/var
                                 (
                                    ',' Var/i             $ var = (dict(var[0].items() + i[0].items()), var[1] + i[1]) $
                                 ) * ;
  Var/var                      -> varname/name            $ var = ({name: None}, [name])
                                 (
                                   '=' vardefault/default $ var[0][name] = default
                                 ) ? ;
  VarNoDefault/var             -> varname/name            $ var = ({name: None}, [name])$ ;
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

      ( "-prefix|&|foo",       {},                 "" ),
      ( "-prefix|&|foo=wilma", {},                 "&wilma" ),
      ( "-prefix||foo=wilma", {},                 "wilma" ),
      ( "-prefix|&|foo=wilma", {"foo": "barney"},  "&barney" ),
      ( "-prefix|&|foo", {"foo": ["wilma", "barney"]},  "&wilma&barney" ),
 
      ( "-suffix|/|foo",        {},                 "" ),
      ( "-suffix|#|foo=wilma",  {},                 "wilma#" ),
      ( "-suffix|&?|foo=wilma", {"foo": "barney"},  "barney&?" ),
      ( "-suffix|&|foo", {"foo": ["wilma", "barney"]},  "wilma&barney&" ),

      ( "-join|/|foo",                  {},                 "" ),
      ( "-join|/|foo,bar",                  {},                 "" ),
      ( "-join|&|q,num",                  {},                 "" ),
      ( "-join|#|foo=wilma",            {},                 "foo=wilma"),
      ( "-join|#|foo=wilma,bar",        {},                 "foo=wilma"),
      ( "-join|#|foo=wilma,bar=barney", {},                 "foo=wilma#bar=barney"),
      ( "-join|&?|foo=wilma",           {"foo": "barney"},  "foo=barney" ),

      ( "-list|/|foo",       {},                    "" ),
      ( "-list|/|foo",       {"foo": ["a", "b"]},   "a/b"),
      ( "-list||foo",       {"foo": ["a", "b"]},   "ab"),
      ( "-list|/|foo",       {"foo": ["a"]},        "a"),
      ( "-list|/|foo",       {"foo": []},           ""),

      ( "-opt|&|foo",       {},                      ""),
      ( "-opt|&|foo",       {"foo": "fred"},         "&"),
      ( "-opt|&|foo",       {"foo": []},             ""),
      ( "-opt|&|foo",       {"foo": ["a"]},          "&"),
      ( "-opt|&|foo,bar",   {"foo": ["a"]},          "&"),
      ( "-opt|&|foo,bar",   {"bar": "a"},         "&"),
      ( "-opt|&|foo,bar",   {},                      ""),

      ( "-neg|&|foo",       {},                     "&"),
      ( "-neg|&|foo",       {"foo": "fred"},        ""),
      ( "-neg|&|foo",       {"foo": []},            "&"),
      ( "-neg|&|foo",       {"foo": ["a"]},         ""),
      ( "-neg|&|foo,bar",   {"bar": "a"},           ""),
      ( "-neg|&|foo,bar",   {"bar": []},            "&"),

      ( "foo",          {"foo": " "},           "%20" ),
      ( "-list|&|foo",       {"foo": ["&", "&", "|", "_"]},   "%26&%26&%7C&_" )

      ]

      i = 0
      for (template, values, expected) in test_cases:
        i += 1
        parsed = p(template)
        self.assertEqual(expected, parsed.sub(values), "Test case #%d [%s != %s]" % (i, expected, parsed.sub(values)))

  class TestURITemplate(unittest.TestCase):
    def test_simple(self):
      t = URITemplate("http://example.org/news/{id}/")
      self.assertEqual(set(["id"]), t.variables())
      self.assertEqual("http://example.org/news/joe/", t.sub({"id": "joe"}))

      t = URITemplate("http://www.google.com/notebook/feeds/{userID}{-prefix|/notebooks/|notebookID}{-opt|/-/|categories}{-list|/|categories}?{-join|&|updated-min,updated-max,alt,start-index,max-results,entryID,orderby}")
      self.assertEqual(set(['max-results', 'orderby', 'notebookID',
        'start-index', 'userID', 'updated-max', 'entryID', 'alt',
        'updated-min', 'categories']), t.variables())
      self.assertEqual("http://www.google.com/notebook/feeds/joe?", t.sub({"userID": "joe"}))
      self.assertEqual("http://www.google.com/notebook/feeds/joe/-/A%7C-B/-C?start-index=10",
          t.sub({"userID": "joe", "categories": ["A|-B", "-C"], "start-index":
            "10"}))

  unittest.main()
