import uritemplate
try:
  import json
except ImportError:
  import simplejson as json
import sys

filename = sys.argv[1]
print("Running", filename)
f = open(filename)
testdata = json.load(f)

try:
  desired_level = int(sys.argv[2])
except IndexError:
  desired_level = 4

for name, testsuite in testdata.items():
  vars = testsuite['variables']
  testcases = testsuite['testcases']

  level = testsuite.get('level', 4)
  if level > desired_level:
    continue

  print(name)
  for testcase in testcases:
    template = testcase[0]
    expected = testcase[1]
    actual = uritemplate.expand(template, vars)
    sys.stdout.write(".") 
    if type(expected) == type([]):
      if actual not in expected:
        sys.stderr.write("%s didn't expand as expected, got %s instead\n" % (template, actual))
        assert 0
    else:
      if actual != expected:
        sys.stderr.write("%s expected to expand to %s, got %s instead\n" % (template, expected, actual))
        assert 0
  print()
