OUTFORMATS ?= flac mp3 ogg

# These generally output fine
OUTTYPES_NICE += timidity-fluidr3
OUTTYPES_NICE += timidity-campbell
OUTTYPES_NICE += timidity-roland
OUTTYPES_NICE += timidity-freepats
OUTTYPES_NICE += linuxsampler-maestro

# Outputting these is a bit broken/manual. Avoid it.
OUTTYPES_EVIL ?= lmms-mdapiano
OUTTYPES_EVIL += linuxsampler-pleyelp190
OUTTYPES_EVIL += linuxsampler-steinwayc
# lmms-pianobello

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
MID_FORMAT0 = $(patsubst %.rg,%-format0.mid,$(RG))
LY_ORIG = $(patsubst %.rg,%.ly.orig,$(RG))
LY_DIFF = $(patsubst %.rg,%.ly.diff,$(RG))
LY = $(patsubst %.rg,%.ly,$(RG))
PDF = $(patsubst %.rg,%.pdf,$(RG))
MMP = $(patsubst %.rg,%.mmp,$(RG))
AUDIO_NICE = $(foreach OUTFORMAT,$(OUTFORMATS),$(foreach OUTTYPE,$(OUTTYPES_NICE),$(patsubst %.rg,%-$(OUTTYPE).$(OUTFORMAT),$(RG))))
AUDIO_EVIL = $(foreach OUTFORMAT,$(OUTFORMATS),$(foreach OUTTYPE,$(OUTTYPES_EVIL),$(patsubst %.rg,%-$(OUTTYPE).$(OUTFORMAT),$(RG))))


CLEANTEMP = $(RM) *.tmp */*.tmp *.wav */*.wav


all: audio sheet

audio: $(AUDIO_NICE)
	$(CLEANTEMP)

audio-evil: $(AUDIO_EVIL)
	$(CLEANTEMP)

sheet: $(PDF)
	$(CLEANTEMP)

manual: $(MID) $(MMP) $(LY_ORIG)
	$(CLEANTEMP)


support:
	mkdir -p support

support/mdaPiano.dll: | support
	cd support && wget -qO- 'http://sourceforge.net/projects/mda-vst/files/mda-vst/mda-vst-src%20100214/mda-vst-bin-win-32-2010-02-14.zip/download' | bsdtar xf - mdaPiano.dll

support/FluidR3GM.SF2: | support
	cd support && wget -O 'FluidR3122501.zip' 'http://www.hammersound.com/cgi-bin/soundlink_download2.pl/Download%20USA;FluidR3122501.zip;699'
	cd support && unzip 'FluidR3122501.zip' 'FluidR3 GM.sfArk'
	cd support && rm -f 'FluidR3122501.zip'
	cd support && sfarkxtc 'FluidR3 GM.sfArk' 'FluidR3GM.SF2'
	cd support && rm -f 'FluidR3 GM.sfArk'

support/CampbellsPianoBeta2.sf2: | support
	cd support && wget -O 'CampbellsPianoBeta2.rar' 'http://www.hammersound.com/cgi-bin/soundlink_download2.pl/Download%20USA;CampbellsPianoBeta2.rar;505'
	cd support && unrar x 'CampbellsPianoBeta2.rar' 'CampbellsPianoBeta2.sf2'
	cd support && rm -f 'CampbellsPianoBeta2.rar'

support/RolandNicePiano.sf2: | support
	cd support && wget -O 'RolandNicePiano.rar' 'http://www.hammersound.com/cgi-bin/soundlink_download2.pl/Download%20USA;RolandNicePiano.rar;639'
	cd support && unrar x 'RolandNicePiano.rar' 'RolandNicePiano.sf2'
	cd support && rm -f 'RolandNicePiano.rar'

support/000_Acoustic_Grand_Piano.pat: | support
	cd support && wget -O '000_Acoustic_Grand_Piano.pat' 'http://freepats.zenvoid.org/freepats/Tone_000/000_Acoustic_Grand_Piano.pat'

support/maestro_concert_grand_v2.gig: | support
	cd support && wget -c -O 'maestro_concert_grand_v2.rar' 'http://download.linuxsampler.org/instruments/pianos/maestro_concert_grand_v2.rar'
	cd support && unrar x 'maestro_concert_grand_v2.rar' 'maestro_concert_grand_v2.gig'


LMMS_SETINSTRUMENT = sed -e 's,%LMMS_SUPPORT%,$(CURDIR)/support,g' | bin/lmms_setinstrument.pl
TIMIDITY_SETSOUNDFONT_PRE = -x "dir $(CURDIR)\nsoundfont
TIMIDITY_SETSOUNDFONT_POST = "
TIMIDITY_SETGUSPATCH_PRE = -x "dir $(CURDIR)\nfont exclude 0 0\nbank 0\n0
TIMIDITY_SETGUSPATCH_POST = "


# mda Piano (LMMS)
%-lmms-mdapiano-raw.wav: %.mmp support/mdaPiano.dll
	< instruments/mdaPiano.lmms $(LMMS_SETINSTRUMENT) $< $*-lmms-mdapiano-raw.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export as $@
	#echo Furthermore, complain to LMMS guys why --render does not work.
	@echo
	@echo
	lmms $*-lmms-mdapiano.tmp
	[ -f $@ ]

# Kontakt 5, Pianobello (LMMS)
%-lmms-pianobello-raw.wav: %.mmp
	< instruments/kontakt5-pianobello.lmms $(LMMS_SETINSTRUMENT) $< $*-lmms-pianobello-raw.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please export as $@
	#echo Furthermore, complain to LMMS guys why --render does not work.
	@echo
	@echo
	lmms $*-lmms-pianobello.tmp
	[ -f $@ ]

# Format 0 MIDI (friendly for the synths)
%-format0.mid: %.mid
	bin/to_format0.pl $< $@ 5 1

# Audio renderers
%-timidity-fluidr3-raw.wav: %.mid support/FluidR3GM.SF2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE) support/FluidR3GM.SF2                $(TIMIDITY_SETSOUNDFONT_POST) -EI0 -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-timidity-campbell-raw.wav: %.mid support/CampbellsPianoBeta2.sf2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE) support/CampbellsPianoBeta2.sf2      $(TIMIDITY_SETSOUNDFONT_POST) -EI0 -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-timidity-roland-raw.wav: %.mid support/RolandNicePiano.sf2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE) support/RolandNicePiano.sf2          $(TIMIDITY_SETSOUNDFONT_POST) -EI1 -EFreverb=G,70 -EFchorus=n,10 -Ow -o $@ $<
%-timidity-freepats-raw.wav: %.mid support/000_Acoustic_Grand_Piano.pat
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETGUSPATCH_PRE)  support/000_Acoustic_Grand_Piano.pat $(TIMIDITY_SETGUSPATCH_POST)  -EI0 -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-linuxsampler-pleyelp190-raw.wav: %-format0.mid support/PleyelP190.gig
	bin/linuxsampler.sh $< $(CURDIR)/support/PleyelP190.gig $@
%-linuxsampler-steinwayc-raw.wav: %.-format0.mid support/SteinwayC.gig
	bin/linuxsampler.sh $< $(CURDIR)/support/SteinwayC.gig $@
%-linuxsampler-maestro-raw.wav: %-format0.mid support/maestro_concert_grand_v2.gig
	bin/linuxsampler.sh $< $(CURDIR)/support/maestro_concert_grand_v2.gig $@

%.wav: %-raw.wav
	sox $< $@ silence 1 0 0% reverse silence 1 0 0% reverse

# Project conversion (ANNOYING, so we only perform it if the file is missing)
%.mmp: | %-format0.mid
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please import $*-format0.mid as MIDI and save as $@
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
	mp3gain -r -k $@

%.ogg: %.wav
	$(OGGENC) $(OGGENCFLAGS) -o $@ $<
	vorbisgain $@


# PDF making
%.ly: %.ly.diff %.ly.orig
	$(CP) $*.ly.orig $*.ly
	$(PATCH) $*.ly $*.ly.diff

%.pdf: %.ly
	$(LILYPOND) $(LILYPONDFLAGS) -o $* $<


# Cleanup
mostlyclean:
	$(CLEANTEMP)
	$(RM) $(AUDIO_NICE) $(WAV) $(LY) $(PDF) $(MID_FORMAT0)

clean:
	$(CLEANTEMP)
	$(RM) $(AUDIO_EVIL)

realclean: clean
	$(CLEANTEMP)
	$(RM) support $(LY_ORIG) $(MID) $(MMP)
