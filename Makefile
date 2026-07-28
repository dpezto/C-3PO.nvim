.PHONY: test
test:
	vusted $(if $(COVERAGE),--coverage) ./test

.PHONY: format
format:
	stylua .

# Re-record the README gifs. Requires vhs (https://github.com/charmbracelet/vhs)
# and a Neovim config that loads this checkout — see the README's Demo section.
.PHONY: demo
demo:
	for t in vhs/*.tape; do vhs $$t; done
