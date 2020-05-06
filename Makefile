 
# Generate PDFs from the Markdown source files
#
# In order to use this makefile, you need some tools:
# - GNU make
# - Pandoc
# - LuaLaTeX
# - DejaVu Sans fonts (part of texlive-luatex deb)

# Directory containing source (Markdown) files
source := docs

# Directory containing pdf files
output := print

# All markdown files in src/ are considered sources
sources := $(wildcard $(source)/*.md)

# Convert the list of source files (Markdown files in directory src/)
# into a list of output files (PDFs in directory print/).
objects := $(patsubst %.md,%.pdf,$(subst $(source),$(output),$(sources)))

all: outdir $(objects)

outdir: 
	mkdir -p $(output)

# Recipe for converting a Markdown file into PDF using Pandoc
$(output)/%.pdf: $(source)/%.md
	pandoc -V fontfamily=lmodern \
	    --variable fontsize=11pt \
		--variable geometry:margin=1.5cm \
		--variable geometry:a4paper \
		-f markdown  $< \
		--pdf-engine=lualatex \
		-o $@



.PHONY : clean

clean:
	rm -f $(output)/*
