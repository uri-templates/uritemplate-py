
LEVEL = 4

test: spec-examples spec-examples-by-section extended variables

spec-examples:
	PYTHONPATH=..:$(PYTHONPATH) python uritemplate_test.py cases/spec-examples.json $(LEVEL)

spec-examples-by-section:
	PYTHONPATH=..:$(PYTHONPATH) python uritemplate_test.py cases/spec-examples-by-section.json $(LEVEL)

extended:
	PYTHONPATH=..:$(PYTHONPATH) python uritemplate_test.py cases/extended-tests.json $(LEVEL)

negative:
	PYTHONPATH=..:$(PYTHONPATH) python uritemplate_test.py cases/negative-tests.json $(LEVEL)

variables:
	PYTHONPATH=..:$(PYTHONPATH) python variables_test.py
