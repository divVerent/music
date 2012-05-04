OUTFORMATS ?= flac mp3 ogg wav
OUTTYPES ?= timidity

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

RG = $(shell echo */*.rg)
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



all: audio sheet

audio: $(AUDIO)

sheet: $(PDF)

manual: $(MID) $(MMP) $(LY_ORIG)


# Format 0 (for LMMS)
%-format0.mid: %.mid
	bin/to_format0.pl $< $@


# MIDI -> LMMS (MANUAL)
%.mmp: %-format0.mid
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please import $< and save as $@
	@echo
	@echo
	lmms >/dev/null 2>&1
	[ -f $@ ]


# Ramps
%-ramp.rg: %.rg
	< $< gunzip | bin/autoramp.pl | gzip > $@


# Rosegarden -> MIDI (MANUAL)
%.mid: %-ramp.rg
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export to MIDI as $@
	@echo
	@echo
	rosegarden $< >/dev/null 2>&1
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
	$(FLAC) $(FLACFLAGS) -f -o $@ $<

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
	$(RM) $(AUDIO) $(WAV) $(LY) $(PDF)

realclean: clean
	$(RM) $(RAMP_RG) $(LY_ORIG) $(MID) $(MMP) $(FORMAT0_MID)
