import uritemplate
import simplejson
import sys

f = file("testdata.json")
testdata = simplejson.load(f)

for name, testsuite in testdata.iteritems():
  print name
  vars = testsuite['variables']
  testcases= testsuite['testcases']

  for testcase in testcases:
    template = testcase[0]
    expected = testcase[1]
    actual = uritemplate.expand(template, vars)
    sys.stdout.write(".") 
    if expected != actual:
      print "Template %s expected to expand to %s, got %s instead" % (template, expected, actual)
      assert 0
  print
