OUTFORMATS ?= flac mp3 ogg wav
OUTTYPES_NICE ?= timidity-fluidr3 timidity-campbell timidity-roland timidity-freepats
OUTTYPES_EVIL ?= lmms-mdapiano
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

support/000_Acoustic_Grand_Piano.pat:
	mkdir -p support
	cd support && wget -O '000_Acoustic_Grand_Piano.pat' 'http://freepats.zenvoid.org/freepats/Tone_000/000_Acoustic_Grand_Piano.pat'


LMMS_SETINSTRUMENT = sed -e 's,%LMMS_SUPPORT%,$(CURDIR)/support,g' | bin/lmms_setinstrument.pl
TIMIDITY_SETSOUNDFONT_PRE = -x "dir $(CURDIR)/support" -x "soundfont 
TIMIDITY_SETSOUNDFONT_POST = "
TIMIDITY_SETGUSPATCH_PRE = -x "dir $(CURDIR)/support" -x "bank 0" -x "000 
TIMIDITY_SETGUSPATCH_POST = "


# mda Piano (LMMS)
%-lmms-mdapiano.wav: %.mmp support/mdaPiano.dll
	< instruments/mdaPiano.lmms $(LMMS_SETINSTRUMENT) $< $*-lmms-mdapiano.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export as $@
	#echo Furthermore, complain to LMMS guys why --render does not work.
	@echo
	@echo
	lmms $*-lmms-mdapiano.tmp
	[ -f $@ ]


# Audio renderers
%-timidity-fluidr3.wav: %.mid support/FluidR3GM.SF2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE)support/FluidR3GM.SF2$(TIMIDITY_SETSOUNDFONT_POST)              -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-timidity-campbell.wav: %.mid support/CampbellsPianoBeta2.sf2                                                                 
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE)support/CampbellsPianoBeta2.sf2$(TIMIDITY_SETSOUNDFONT_POST)    -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-timidity-roland.wav: %.mid support/RolandNicePiano.sf2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE)support/RolandNicePiano.sf2$(TIMIDITY_SETSOUNDFONT_POST) -EI1   -EFreverb=G,70 -EFchorus=n,10 -Ow -o $@ $<
%-timidity-freepats.wav: %.mid support/000_Acoustic_Grand_Piano.pat
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETGUSPATCH_PRE)support/000_Acoustic_Grand_Piano.pat$(TIMIDITY_SETGUSPATCH_POST) -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<


# Project conversion (ANNOYING, so we only perform it if the file is missing)
%.mmp: | %.mid
	bin/to_format0.pl $*.mid $*-format0.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please import $*-format0.tmp as MIDI and save as $@
	@echo
	@echo
	lmms >/dev/null 2>&1
	[ -f $@ ]

%.mid: | %.rg
	< $*.rg gunzip | bin/autoramp.pl | gzip > $*-ramp.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export to MIDI as $@
	@echo
	@echo
	rosegarden $*-ramp.tmp >/dev/null 2>&1
	[ -f $@ ]

%.ly.orig: | %.rg
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export to Lilypond as $@
	@echo
	@echo
	rosegarden $*.rg >/dev/null 2>&1
	[ -f $@ ]


# Audio codecs
%.flac: %.wav
	$(FLAC) $(FLACFLAGS) -f -o $@ $< && touch $@

%.mp3: %.wav
	$(LAME) $(LAMEFLAGS) $< $@

%.ogg: %.wav
	$(OGGENC) $(OGGENCFLAGS) -o $@ $<


# PDF making
%.ly: %.ly.diff %.ly.orig
	$(CP) $*.ly.orig $*.ly
	$(PATCH) $*.ly $*.ly.diff 

%.pdf: %.ly
	$(LILYPOND) $(LILYPONDFLAGS) -o $* $<


# Cleanup
mostlyclean:
	$(CLEANTEMP)
	$(RM) $(AUDIO_NICE) $(WAV) $(LY) $(PDF)

clean:
	$(CLEANTEMP)
	$(RM) $(AUDIO_EVIL)

realclean: clean
	$(CLEANTEMP)
	$(RM) support $(LY_ORIG) $(MID) $(MMP)
