uritemplate
===========

.. image:: https://secure.travis-ci.org/uri-templates/uritemplate-py.png?branch=master
   :alt: build status
   :target: http://travis-ci.org/uri-templates/uritemplate-py

This is a Python implementation of `RFC6570`_, URI Template.

It exposes one method, "expand". For example:

    >>> from uritemplate import expand
    >>> expand("http://www.{domain}/", {"domain": "foo.com"})
    'http://www.foo.com/'



.. _RFC6570: http://tools.ietf.org/html/rfc6570