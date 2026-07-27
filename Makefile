.PHONY: test
vusted:
	vusted ./test

.PHONY: format
format:
	stylua .

# Re-record the README gifs. Requires vhs (https://github.com/charmbracelet/vhs).
.PHONY: demo
demo:
	for t in vhs/*.tape; do vhs $$t; done
