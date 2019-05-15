ARGS = --startup-file=no --color=yes

.PHONY: docs
docs:
	julia $(ARGS) --project=docs/ docs/make.jl

.PHONY: docs-serve
docs-serve:
	cd docs/build && python3 -m http.server --bind localhost

