# Early, and incomplete implementation of -04.
#
import re
import urllib

RESERVED = ":/?#[]@!$&'()*+,;="
OPERATOR = "+#./;?&|!@"
EXPLODE = "*+"
MODIFIER = ":^"
TEMPLATE = re.compile("{([^\}]+)}")


def _tostring(varname, value, explode, operator, safe=""):
    if type(value) == type([]):
        if explode in ["+", "#"]:
            return ",".join([varname + "." + urllib.quote(x, safe) \
                       for x in value])
        else:
            return ",".join([urllib.quote(x, safe) for x in value])
    if type(value) == type({}):
        keys = value.keys()
        keys.sort()
        if explode == "*":
            return ",".join([urllib.quote(key, safe) + "=" + \
                             urllib.quote(value[key], safe) for key in keys])
        if explode in ["+", "#"]:
            return ",".join([varname + "." + urllib.quote(key, safe) + "," + \
                             urllib.quote(value[key], safe) for key in keys])
        else:
            return ",".join([urllib.quote(key, safe) + "," + \
                             urllib.quote(value[key], safe) for key in keys])
    elif value == None:
        return
    else:
        return urllib.quote(value, safe)


def _tostring_path(varname, value, explode, operator, safe=""):
    joiner = operator
    if type(value) == type([]):
        if explode == "+":
            out = [varname + "." + urllib.quote(x, safe) for x in value \
                   if value != None]
        elif explode == "*":
            out = [urllib.quote(x, safe) for x in value if value != None]
        else:
            joiner = ","
            out = [urllib.quote(x, safe) for x in value if value != None]
        if out:
            return joiner.join(out)
        else:
            return
    elif type(value) == type({}):
        keys = value.keys()
        keys.sort()
        if explode == "+":
            out = [varname + "." + urllib.quote(key, safe) + joiner + \
                   urllib.quote(value[key], safe) for key in keys \
                   if value[key] != None]
        elif explode == "*":
            out = [urllib.quote(key, safe) + "=" + \
                   urllib.quote(value[key], safe) for key in keys \
                   if value[key] != None]
        else:
            joiner = ","
            out = [urllib.quote(key, safe) + "," + \
                   urllib.quote(value[key], safe) \
                   for key in keys if value[key] != None]
        if out:
            return joiner.join(out)
        else:
            return
    elif value == None:
        return
    else:
        return urllib.quote(value, safe)


def _tostring_semi(varname, value, explode, operator, safe=""):
    joiner = operator
    if operator == "?":
        joiner = "&"
    if type(value) == type([]):
        if explode in ["+", "*"]:
            out = [varname + "=" + urllib.quote(x, safe) \
                   for x in value if x != None]
            if out:
                return joiner.join(out)
            else:
                return
        else:
            return varname + "=" + ",".join([urllib.quote(x, safe) \
                                             for x in value])
    elif type(value) == type({}):
        keys = value.keys()
        keys.sort()
        if explode == "+":
            return joiner.join([varname + "." + urllib.quote(key, safe) + \
                                "=" + urllib.quote(value[key], safe) \
                                for key in keys if key != None])
        elif explode == "*":
            return joiner.join([urllib.quote(key, safe) + "=" + \
                                urllib.quote(value[key], safe) \
                                for key in keys if key != None])
        else:
            return varname + "=" + ",".join([urllib.quote(key, safe) + "," + \
                             urllib.quote(value[key], safe) for key in keys \
                             if key != None])
    else:
        if value == None:
            return
        elif value:
            return varname + "=" + urllib.quote(value, safe)
        else:
            return varname


def _tostring_query(varname, value, explode, operator, safe=""):
    joiner = operator
    if operator in ["?", "&"]:
        joiner = "&"
    if type(value) == type([]):
        if 0 == len(value):
            return None
        if explode == "+":
            return joiner.join([varname + "=" + urllib.quote(x, safe) \
                                for x in value])
        elif explode == "*":
            return joiner.join([varname + "=" + urllib.quote(x, safe) \
                                for x in value])
        else:
            return varname + "=" + ",".join([urllib.quote(x, safe) \
                                             for x in value])
    elif type(value) == type({}):
        if 0 == len(value):
            return None
        keys = value.keys()
        keys.sort()
        if explode == "+":
            return joiner.join([varname + "." + urllib.quote(key, safe) + \
                                "=" + urllib.quote(value[key], safe) \
                                for key in keys])
        elif explode == "*":
            return joiner.join([urllib.quote(key, safe) + "=" + \
                                urllib.quote(value[key], safe) \
                                for key in keys])
        else:
            return varname + "=" + \
                   ",".join([urllib.quote(key, safe) + "," + \
                             urllib.quote(value[key], safe) for key in keys])
    else:
        if value == None:
            return
        elif value:
            return varname + "=" + urllib.quote(value, safe)
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


def expand(template, vars):
    def _sub(match):
        expression = match.group(1)
        operator = ""
        if expression[0] in OPERATOR:
            operator = expression[0]
            varlist = expression[1:]
        else:
            varlist = expression

        safe = ""
        explode = ""
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
            if varname[-1] in EXPLODE:
                explode = varname[-1]
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
            if varname in vars:
                value = vars[varname]
                #if not value and (type(value) == type({}) or type(value) == type([])) and varname in defaults:
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
