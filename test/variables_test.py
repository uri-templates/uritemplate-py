'''Tests for the variables function'''

import unittest

import uritemplate


class VariablesTests(unittest.TestCase):

    def test_simple(self):
        template = 'http://example.com/{x,y}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y']))

    def test_simple2(self):
        template = 'http://example.com/{x,y}/{z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_reserved(self):
        template = 'http://example.com/{+x,y}/{+z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_fragment(self):
        template = 'http://example.com/{#x,y},{#z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_label(self):
        template = 'http://{.x,y,z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_path_segment(self):
        template = 'http://example.com{/x,y}/w{/z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_parameter(self):
        template = 'http://example.com{;x,y}{;z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_query(self):
        template = 'http://example.com{?x,y,z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_query_continuation(self):
        template = 'http://example.com?a=1&b=2{&x,y}&r=13{&z}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_prefix_modifier(self):
        template = 'http://example.com{/x:5,y:7}{/z:2}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_explode_modifier(self):
        template = 'http://example.com{/x*,y*}/page{/z*}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['x', 'y', 'z']))

    def test_mixed_expansion_types(self):
        template = 'http://{a,b}.com{;c,d}{/e,f}/page{?g,h}{&i,j}{#k,l}'
        vars = uritemplate.variables(template)
        expected_vars = set('abcdefghijkl')
        self.assertEquals(vars, expected_vars)

    def test_overlapping_expansion(self):
        template = 'http://{a,b}.com{;a,b}{/a,b}/page{?a,b}{&a,b}{#a,b}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['a', 'b']))

    def test_partially_overlapping(self):
        template = 'http://{.a,b}{/b,c}/{c,d}'
        vars = uritemplate.variables(template)
        self.assertEquals(vars, set(['a', 'b', 'c', 'd']))


if __name__ == '__main__':
    unittest.main()
