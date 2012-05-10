import uritemplate
import simplejson
import sys

filename = sys.argv[1]
print "Running", filename
f = file(filename)
testdata = simplejson.load(f)

try:
  desired_level = int(sys.argv[2])
except IndexError:
  desired_level = 4

for name, testsuite in testdata.iteritems():
  vars = testsuite['variables']
  testcases = testsuite['testcases']

  level = testsuite.get('level', 4)
  if level > desired_level:
    continue

  print name
  for testcase in testcases:
    template = testcase[0]
    expected = testcase[1]
    actual = uritemplate.expand(template, vars)
    sys.stdout.write(".") 
    if expected != actual:
      print "Template %s expected to expand to %s, got %s instead" % (template, expected, actual)
      assert 0
  print
