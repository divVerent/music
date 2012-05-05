OUTFORMATS ?= flac mp3 ogg wav
OUTTYPES_NICE ?= timidity-fluidr3 timidity-campbell timidity-roland
OUTTYPES_EVIL ?= lmms-mdapiano
# lmms-mdaPiano
DO_MANUAL ?= no

CP ?= cp
PATCH ?= patch

LILYPOND ?= lilypond
LILYPONDFLAGS ?=

TIMIDITY ?= timidity
TIMIDITYFLAGS ?=

LAME ?= lame
LAMEFLAGS ?= --preset standard

OGGENC ?= oggenc
OGGENCFLAGS ?= -q3

FLAC ?= flac
FLACFLAGS ?= -8

RG = $(shell ls */*.rg | grep -v -- -ramp)
MID = $(patsubst %.rg,%.mid,$(RG))
LY_ORIG = $(patsubst %.rg,%.ly.orig,$(RG))
LY_DIFF = $(patsubst %.rg,%.ly.diff,$(RG))
LY = $(patsubst %.rg,%.ly,$(RG))
PDF = $(patsubst %.rg,%.pdf,$(RG))
MMP = $(patsubst %.rg,%.mmp,$(RG))
AUDIO_NICE = $(foreach OUTFORMAT,wav $(OUTFORMATS),$(foreach OUTTYPE,$(OUTTYPES_NICE),$(patsubst %.rg,%-$(OUTTYPE).$(OUTFORMAT),$(RG))))
AUDIO_EVIL = $(foreach OUTFORMAT,wav $(OUTFORMATS),$(foreach OUTTYPE,$(OUTTYPES_EVIL),$(patsubst %.rg,%-$(OUTTYPE).$(OUTFORMAT),$(RG))))


CLEANTEMP = $(RM) *.tmp */*.tmp


all: audio sheet

audio: $(AUDIO_NICE)
	$(CLEANTEMP)

audio-evil: $(AUDIO_EVIL)
	$(CLEANTEMP)

sheet: $(PDF)
	$(CLEANTEMP)

manual: $(MID) $(MMP) $(LY_ORIG)
	$(CLEANTEMP)



support/mdaPiano.dll:
	mkdir -p support
	cd support && wget -qO- 'http://sourceforge.net/projects/mda-vst/files/mda-vst/mda-vst-src%20100214/mda-vst-bin-win-32-2010-02-14.zip/download' | bsdtar xf - mdaPiano.dll

support/FluidR3GM.SF2:
	mkdir -p support
	cd support && wget -O 'FluidR3122501.zip' 'http://www.hammersound.com/cgi-bin/soundlink_download2.pl/Download%20USA;FluidR3122501.zip;699'
	cd support && unzip 'FluidR3122501.zip' 'FluidR3 GM.sfArk'
	cd support && rm -f 'FluidR3122501.zip'
	cd support && sfarkxtc 'FluidR3 GM.sfArk' 'FluidR3GM.SF2'
	cd support && rm -f 'FluidR3 GM.sfArk'

support/CampbellsPianoBeta2.sf2:
	mkdir -p support
	cd support && wget -O 'CampbellsPianoBeta2.rar' 'http://www.hammersound.com/cgi-bin/soundlink_download2.pl/Download%20USA;CampbellsPianoBeta2.rar;505'
	cd support && unrar x 'CampbellsPianoBeta2.rar' 'CampbellsPianoBeta2.sf2'
	cd support && rm -f 'CampbellsPianoBeta2.rar'

support/RolandNicePiano.sf2:
	mkdir -p support
	cd support && wget -O 'RolandNicePiano.rar' 'http://www.hammersound.com/cgi-bin/soundlink_download2.pl/Download%20USA;RolandNicePiano.rar;639'
	cd support && unrar x 'RolandNicePiano.rar' 'RolandNicePiano.sf2'
	cd support && rm -f 'RolandNicePiano.rar'


LMMS_SETINSTRUMENT = sed -e 's,%LMMS_SUPPORT%,$(CURDIR)/support,g' | bin/lmms_setinstrument.pl
TIMIDITY_SETSOUNDFONT_PRE = -x "dir $(CURDIR)/support" -x "soundfont 
TIMIDITY_SETSOUNDFONT_POST = "
TIMIDITY_SETGUSPATCH_PRE = -x "dir $(CURDIR)/support" -x "bank 0" -x "000 
TIMIDITY_SETGUSPATCH_POST = "


# mda Piano (LMMS)
%-lmms-mdaPiano.wav: %.mmp support/mdaPiano.dll
	< instruments/mdaPiano.lmms $(LMMS_SETINSTRUMENT) $< $*-lmms-mdaPiano.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export as $@
	@echo
	@echo
	lmms $*-lmms-mdaPiano.tmp


# MIDI -> LMMS (MANUAL)
%.mmp: %.mid
	bin/to_format0.pl $< $*-format0.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please import $*-format0.tmp as MIDI and save as $@
	@echo
	@echo
	lmms >/dev/null 2>&1
	[ -f $@ ]


# Rosegarden -> MIDI (MANUAL)
%.mid: %.rg
	< $< gunzip | bin/autoramp.pl | gzip > $*-ramp.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export to MIDI as $@
	@echo
	@echo
	rosegarden $*-ramp.tmp >/dev/null 2>&1
	[ -f $@ ]


# Rosegarden -> Lilypond (MANUAL)
%.ly.orig: %.rg
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export to Lilypond as $@
	@echo
	@echo
	rosegarden $< >/dev/null 2>&1
	[ -f $@ ]


# Audio renderers
%-timidity-fluidr3.wav: %.mid support/FluidR3GM.SF2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE)support/FluidR3GM.SF2$(TIMIDITY_SETSOUNDFONT_POST)            -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-timidity-campbell.wav: %.mid support/CampbellsPianoBeta2.sf2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE)support/CampbellsPianoBeta2.sf2$(TIMIDITY_SETSOUNDFONT_POST)  -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-timidity-roland.wav: %.mid support/RolandNicePiano.sf2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE)support/RolandNicePiano.sf2$(TIMIDITY_SETSOUNDFONT_POST) -EI1 -EFreverb=G,70 -EFchorus=n,10 -Ow -o $@ $<


# Audio codecs
%.flac: %.wav
	$(FLAC) $(FLACFLAGS) -f -o $@ $< && touch $@

%.mp3: %.wav
	$(LAME) $(LAMEFLAGS) $< $@

%.ogg: %.wav
	$(OGGENC) $(OGGENCFLAGS) -o $@ $<


# Fixing Lilypond file by included patch
%.ly: %.ly.diff %.ly.orig
	$(CP) $*.ly.orig $*.ly
	$(PATCH) $*.ly $*.ly.diff 


# Lilypond -> PDF
%.pdf: %.ly
	$(LILYPOND) $(LILYPONDFLAGS) -o $* $<


# Cleanup
clean:
	$(CLEANTEMP)
	$(RM) $(AUDIO_NICE) $(WAV) $(LY) $(PDF)

clean-evil: clean
	$(CLEANTEMP)
	$(RM) $(AUDIO_EVIL)

realclean: clean-evil
	$(CLEANTEMP)
	$(RM) support $(LY_ORIG) $(MID) $(MMP)
