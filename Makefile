# These are the files used for editing content
# They are version controlled but not packaged with the game
RESOURCE_DIR = resource

MAP_SOURCE   = $(RESOURCE_DIR)/map
FONT_SOURCE  = $(RESOURCE_DIR)/font
SOUND_SOURCE = $(RESOURCE_DIR)/sound
IMAGE_SOURCE = $(RESOURCE_DIR)/image
MUSIC_SOURCE = $(RESOURCE_DIR)/music

# These are the files that end up packaged with the game
# They are not version controlled but are generated from resource files
CONTENT_DIR = content

MAP_DEST   = $(CONTENT_DIR)/map
FONT_DEST  = $(CONTENT_DIR)/font
SOUND_DEST = $(CONTENT_DIR)/sound
IMAGE_DEST = $(CONTENT_DIR)/image
MUSIC_DEST = $(CONTENT_DIR)/music

# Source content files
MAP_FILES   := $(wildcard $(MAP_SOURCE)/*.json)
FONT_FILES  := $(wildcard $(FONT_SOURCE)/*.ttf)
SOUND_FILES := $(wildcard $(SOUND_SOURCE)/*.wav)
IMAGE_FILES := $(wildcard $(IMAGE_SOURCE)/*.ase)
MUSIC_FILES := $(wildcard $(MUSIC_SOURCE)/*.mmpz)

# All generated content files
ALL_CONTENT := $(wildcard $(CONTENT_DIR)/**/*)

all: debug

verify:
	@echo $(MAP_FILES)
	@echo $(FONT_FILES)
	@echo $(SOUND_FILES)
	@echo $(IMAGE_FILES)
	@echo $(MUSIC_FILES)

debug: content
	@dub build --build=debug

release: content
	@dub build --build=release

run: content
	@dub run

clean:
	$(RM) $(ALL_CONTENT)

content: dirs maps fonts images music sounds

# Create the content output directories
dirs:
	@mkdir -p $(MAP_DEST) $(FONT_DEST) $(IMAGE_DEST) $(MUSIC_DEST) $(SOUND_DEST)

# Copy map files from resource to content
maps: $(MAP_FILES:$(MAP_SOURCE)/%.json=$(MAP_DEST)/%.json)

$(MAP_DEST)/%.json : $(MAP_SOURCE)/%.json
	@echo copying map $*
	@cp $(MAP_SOURCE)/$*.json $(MAP_DEST)/$*.json

# Copy font files from resource to content
fonts: $(FONT_FILES:$(FONT_SOURCE)/%.ttf=$(FONT_DEST)/%.ttf)

$(FONT_DEST)/%.ttf : $(FONT_SOURCE)/%.ttf
	@echo copying font $*
	@cp $(FONT_SOURCE)/$*.ttf $(FONT_DEST)/$*.ttf

sounds: $(SOUND_FILES:$(SOUND_SOURCE)/%.wav=$(SOUND_DEST)/%.wav)

# Copy sound files from resource to content
$(SOUND_DEST)/%.wav : $(SOUND_SOURCE)/%.wav
	@echo copying sound $*
	@cp $(SOUND_SOURCE)/$*.wav $(SOUND_DEST)/$*.wav

# Use aseprite to convert .ase to .png
images: $(IMAGE_FILES:$(IMAGE_SOURCE)/%.ase=$(IMAGE_DEST)/%.png)

$(IMAGE_DEST)/%.png : $(IMAGE_SOURCE)/%.ase
	@echo building image $*
	@aseprite --batch --sheet $(IMAGE_DEST)/$*.png $(IMAGE_SOURCE)/$*.ase --data /dev/null

# Use mmpz to render .mmpz files into .ogg files
music: $(MUSIC_FILES:$(MUSIC_SOURCE)/%.mmpz=$(MUSIC_DEST)/%.ogg)

# lmms sometimes crashes after completely rendering the file
# this silently assumes success even if lmms 'fails'
$(MUSIC_DEST)/%.ogg : $(MUSIC_SOURCE)/%.mmpz
	@echo building song $*
	@-! { lmms -r $(MUSIC_SOURCE)/$*.mmpz -f ogg -b 64 -o $(MUSIC_DEST)/$*.ogg ; } >/dev/null 2>&1

# vim: set textwidth=100:
