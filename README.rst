uritemplate
===========

.. image:: https://secure.travis-ci.org/uri-templates/uritemplate-py.png?branch=master
   :alt: build status
   :target: http://travis-ci.org/uri-templates/uritemplate-py

This is a Python implementation of `RFC6570`_, URI Template, and can expand templates up to and including Level 4 in that specification.

It exposes one method, "expand". For example:

    >>> from uritemplate import expand
    >>> expand("http://www.{domain}/", {"domain": "foo.com"})
    'http://www.foo.com/'



.. _RFC6570: http://tools.ietf.org/html/rfc6570

Requirements
------------

uritemplate requires Python 2.5+ and simplejson to be installed.


License
=======

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