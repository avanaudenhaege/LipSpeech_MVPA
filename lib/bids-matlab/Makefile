 .PHONY: clean manual
clean:
	rm version.txt

version.txt: CITATION.cff
	grep -w "^version" CITATION.cff | sed "s/version: /v/g" > version.txt

validate_cff: CITATION.cff
	cffconvert --validate

manual:
	cd docs && sh create_manual.sh

update_schema:
	wget https://bids-specification.readthedocs.io/en/latest/schema.json -O schema.json
