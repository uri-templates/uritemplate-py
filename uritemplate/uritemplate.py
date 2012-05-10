#!/usr/bin/env python

"""
URI Template (RFC6570) Processor
"""

__copyright__ = """\
Copyright 2011-2012 Joe Gregorio

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import re
from urllib import quote

RESERVED = ":/?#[]@!$&'()*+,;="
OPERATOR = "+#./;?&|!@"
MODIFIER = ":^"
TEMPLATE = re.compile("{([^\}]+)}")


def _tostring(varname, value, explode, operator, safe=""):
    if type(value) == type([]):
        return ",".join([quote(x, safe) for x in value])
    if type(value) == type({}):
        keys = value.keys()
        keys.sort()
        if explode:
            return ",".join([quote(key, safe) + "=" + \
                             quote(value[key], safe) for key in keys])
        else:
            return ",".join([quote(key, safe) + "," + \
                             quote(value[key], safe) for key in keys])
    elif value == None:
        return
    else:
        return quote(value, safe)


def _tostring_path(varname, value, explode, operator, safe=""):
    joiner = operator
    if type(value) == type([]):
        if explode:
            out = [quote(x, safe) for x in value if value != None]
        else:
            joiner = ","
            out = [quote(x, safe) for x in value if value != None]
        if out:
            return joiner.join(out)
        else:
            return
    elif type(value) == type({}):
        keys = value.keys()
        keys.sort()
        if explode:
            out = [quote(key, safe) + "=" + \
                   quote(value[key], safe) for key in keys \
                   if value[key] != None]
        else:
            joiner = ","
            out = [quote(key, safe) + "," + \
                   quote(value[key], safe) \
                   for key in keys if value[key] != None]
        if out:
            return joiner.join(out)
        else:
            return
    elif value == None:
        return
    else:
        return quote(value, safe)


def _tostring_semi(varname, value, explode, operator, safe=""):
    joiner = operator
    if operator == "?":
        joiner = "&"
    if type(value) == type([]):
        if explode:
            out = [varname + "=" + quote(x, safe) \
                   for x in value if x != None]
            if out:
                return joiner.join(out)
            else:
                return
        else:
            return varname + "=" + ",".join([quote(x, safe) \
                                             for x in value])
    elif type(value) == type({}):
        keys = value.keys()
        keys.sort()
        if explode:
            return joiner.join([quote(key, safe) + "=" + \
                                quote(value[key], safe) \
                                for key in keys if key != None])
        else:
            return varname + "=" + ",".join([quote(key, safe) + "," + \
                             quote(value[key], safe) for key in keys \
                             if key != None])
    else:
        if value == None:
            return
        elif value:
            return varname + "=" + quote(value, safe)
        else:
            return varname


def _tostring_query(varname, value, explode, operator, safe=""):
    joiner = operator
    if operator in ["?", "&"]:
        joiner = "&"
    if type(value) == type([]):
        if 0 == len(value):
            return None
        if explode:
            return joiner.join([varname + "=" + quote(x, safe) \
                                for x in value])
        else:
            return varname + "=" + ",".join([quote(x, safe) \
                                             for x in value])
    elif type(value) == type({}):
        if 0 == len(value):
            return None
        keys = value.keys()
        keys.sort()
        if explode:
            return joiner.join([quote(key, safe) + "=" + \
                                quote(value[key], safe) \
                                for key in keys])
        else:
            return varname + "=" + \
                   ",".join([quote(key, safe) + "," + \
                             quote(value[key], safe) for key in keys])
    else:
        if value == None:
            return
        elif value:
            return varname + "=" + quote(value, safe)
        else:
            return varname  + "="


TOSTRING = {
    "" : _tostring,
    "+": _tostring,
    "#": _tostring,
    ";": _tostring_semi,
    "?": _tostring_query,
    "&": _tostring_query,
    "/": _tostring_path,
    ".": _tostring_path,
    }


def expand(template, variables):
    def _sub(match):
        expression = match.group(1)
        operator = ""
        if expression[0] in OPERATOR:
            operator = expression[0]
            varlist = expression[1:]
        else:
            varlist = expression

        safe = ""
        explode = False
        if operator in ["+", "#"]:
            safe = RESERVED
        varspecs = varlist.split(",")
        varnames = []
        defaults = {}
        for varspec in varspecs:
            default = None
            if "=" in varspec:
                varname, default = tuple(varspec.split("=", 1))
            else:
                varname = varspec
            if varname[-1] == "*":
                explode = True
                varname = varname[:-1]
            if default:
                defaults[varname] = default
            varnames.append((varname, explode))

        retval = []
        joiner = operator
        prefix = operator
        if operator == "+":
            prefix = ""
            joiner = ","
        if operator == "#":
            joiner = ","
        if operator == "?":
            joiner = "&"
        if operator == "&":
            prefix = "&"
        if operator == "":
            joiner = ","
        for varname, explode in varnames:
            if varname in variables:
                value = variables[varname]
                if not value and value != "" and varname in defaults:
                    value = defaults[varname]
            elif varname in defaults:
                value = defaults[varname]
            else:
                continue
            expanded = TOSTRING[operator](
              varname, value, explode, operator, safe=safe)
            if expanded != None:
                retval.append(expanded)
        if len(retval) > 0:
            return prefix + joiner.join(retval)
        else:
            return ""

    return TEMPLATE.sub(_sub, template)
