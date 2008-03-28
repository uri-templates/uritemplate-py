NAME=draft-gregorio-uritemplate
REV=03
LASTREV=02
LAST=$(NAME)-$(LASTREV)
SOURCE=$(NAME)
TARGET=$(NAME)-$(REV)

default: $(TARGET).html $(TARGET).txt diff nits

test: $(TARGET).txt 
	python ../template_parser.py
	python ../explain.cgi --test
	python test_draft_examples.py $(TARGET).txt

$(TARGET).html: $(SOURCE).xml xml2rfc.tcl
	tclsh8.4 xml2rfc.tcl xml2html $(SOURCE).xml  $(TARGET).html

$(TARGET).txt:  $(SOURCE).xml xml2rfc.tcl
	tclsh8.4 xml2rfc.tcl xml2rfc $(SOURCE).xml $(TARGET).txt

.PHONY: diff
diff:
	./rfcdiff --html $(LAST).txt $(TARGET).txt

.PHONY: nits
nits:
	./idnits --verbose $(TARGET).txt

