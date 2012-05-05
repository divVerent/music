OUTFORMATS ?= flac mp3 ogg wav
OUTTYPES ?= timidity-fluidr3
# lmms-mdaPiano
DO_MANUAL ?= no

CP ?= cp
PATCH ?= patch

LILYPOND ?= lilypond
LILYPONDFLAGS ?=

TIMIDITY ?= timidity
TIMIDITYFLAGS ?= -EFreverb=G,70 -EFchorus=n,40

LAME ?= lame
LAMEFLAGS ?= --preset standard

OGGENC ?= oggenc
OGGENCFLAGS ?= -q3

FLAC ?= flac
FLACFLAGS ?= -8

RG = $(shell ls */*.rg | grep -v -- -ramp)
RAMP_RG = $(patsubst %.rg,%-ramp.rg,$(RG))
MID = $(patsubst %.rg,%.mid,$(RG))
FORMAT0_MID = $(patsubst %.rg,%-format0.mid,$(RG))
LY_ORIG = $(patsubst %.rg,%.ly.orig,$(RG))
LY_DIFF = $(patsubst %.rg,%.ly.diff,$(RG))
LY = $(patsubst %.rg,%.ly,$(RG))
PDF = $(patsubst %.rg,%.pdf,$(RG))
MMP = $(patsubst %.rg,%.mmp,$(RG))
WAV = $(patsubst %.rg,%.wav,$(RG))
AUDIO = $(foreach OUTTYPE,$(OUTTYPES),$(foreach OUTFORMAT,$(OUTFORMATS),$(patsubst %.rg,%-$(OUTTYPE).$(OUTFORMAT),$(RG))))


CLEANTEMP = $(RM) *.tmp */*.tmp


all: audio sheet

audio: $(FORMAT0_MID) $(AUDIO)
	$(CLEANTEMP)

sheet: $(PDF)
	$(CLEANTEMP)

manual: $(MID) $(MMP) $(LY_ORIG)
	$(CLEANTEMP)


support/mdaPiano.dll:
	mkdir -p support && cd support && wget -O- http://sourceforge.net/projects/mda-vst/files/mda-vst/mda-vst-src%20100214/mda-vst-bin-win-32-2010-02-14.zip/download | bsdtar xvf - mdaPiano.dll

support-files: support/mdaPiano.dll


LMMS_SETINSTRUMENT = sed -e 's,%LMMS_SUPPORT%,$(CURDIR)/support,g' | bin/lmms_setinstrument.pl
TIMIDITY_SETSOUNDFONT_PRE = -x "dir $(CURDIR)/support" -x "soundfont 
TIMIDITY_SETSOUNDFONT_POST = "
TIMIDITY_SETGUSPATCH_PRE = -x "dir $(CURDIR)/support" -x "bank 0" -x "000 
TIMIDITY_SETGUSPATCH_POST = "


# mda Piano (LMMS)
%-lmms-mdaPiano.wav: %.mmp support-files
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
%-timidity.wav: %.mid
	$(TIMIDITY) $(TIMIDITYFLAGS) -Ow -o $@ $<


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
	$(RM) $(AUDIO) $(WAV) $(LY) $(PDF)

realclean: clean
	$(CLEANTEMP)
	$(RM) support $(LY_ORIG) $(MID) $(MMP)
