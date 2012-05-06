OUTFORMATS ?= flac mp3 ogg

# These generally output fine
OUTTYPES_NICE += timidity-campbell
OUTTYPES_NICE += timidity-freepats
OUTTYPES_NICE += linuxsampler-maestro

# Outputting these is a bit broken/manual. Avoid it.
OUTTYPES_EVIL += linuxsampler-pleyelp190
OUTTYPES_EVIL += linuxsampler-steinwayc

# No longer support this one at all
# because there seems to be no way to get that .nki file
#OUTTYPES_EVIL += lmms-pianobello

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

support/CampbellsPianoBeta2.sf2: | support
	cd support && wget -O 'CampbellsPianoBeta2.rar' 'http://www.hammersound.com/cgi-bin/soundlink_download2.pl/Download%20USA;CampbellsPianoBeta2.rar;505'
	cd support && unrar x 'CampbellsPianoBeta2.rar' 'CampbellsPianoBeta2.sf2'
	cd support && rm -f 'CampbellsPianoBeta2.rar'

support/000_Acoustic_Grand_Piano.pat: | support
	cd support && wget -O '000_Acoustic_Grand_Piano.pat' 'http://freepats.zenvoid.org/freepats/Tone_000/000_Acoustic_Grand_Piano.pat'

support/maestro_concert_grand_v2.gig: | support
	cd support && wget -O 'maestro_concert_grand_v2.rar' 'http://download.linuxsampler.org/instruments/pianos/maestro_concert_grand_v2.rar'
	cd support && unrar x 'maestro_concert_grand_v2.rar' 'maestro_concert_grand_v2.gig'
	cd support && rm -f 'maestro_concert_grand_v2.rar'

support/classicpianos-pleyel_ambient_p190.giga-*.rar: | support
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Register at http://www.gigfiles.com/freebees.php
	@echo and download the FREE Piano set
	@echo Pleyel Ambient P190
	@echo
	@echo Place the downloaded file named
	@echo $@
	@echo in support/ to proceed.
	@echo
	@echo
	@false
support/PleyelP190.gig: | support support/classicpianos-pleyel_ambient_p190.giga-*.rar
	cd support && unrar x classicpianos-pleyel_ambient_p190.giga-*.rar 'Pleyel P190.gig' && mv 'Pleyel P190.gig' 'PleyelP190.gig'

support/classicpianos-steinway_c.giga-*.rar: | support
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Register at http://www.gigfiles.com/freebees.php
	@echo and download the FREE Piano set
	@echo Steinway C
	@echo
	@echo Place the downloaded file named
	@echo $@
	@echo in support/ to proceed.
	@echo
	@echo
	@false
support/SteinwayC.gig: | support support/classicpianos-steinway_c.giga-*.rar
	cd support && unrar x classicpianos-steinway_c.giga-*.rar 'Steinway C.gig' && mv 'Steinway C.gig' 'SteinwayC.gig'

support/Kontakt5.dll: | support
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Download and install the Kontakt 5 Player using WINE.
	@echo Then locate the Kontakt 5.dll in .wine/drive_c
	@echo
	@echo Symlink the file to
	@echo $@
	@echo in support/ to proceed.
	@echo
	@echo
	@false

support/pianobello.nki: | support
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Get pianobello.nki.
	@echo
	@echo Place the downloaded file named
	@echo $@
	@echo in support/ to proceed.
	@echo
	@echo As pianobello.com is down currently,
	@echo GOOD LUCK
	@echo
	@echo
	@false


LMMS_SETINSTRUMENT = sed -e 's,%LMMS_SUPPORT%,$(CURDIR)/support,g' | bin/lmms_setinstrument.pl
TIMIDITY_SETSOUNDFONT_PRE = -x "dir $(CURDIR)\nsoundfont
TIMIDITY_SETSOUNDFONT_POST = "
TIMIDITY_SETGUSPATCH_PRE = -x "dir $(CURDIR)\nfont exclude 0 0\nbank 0\n0
TIMIDITY_SETGUSPATCH_POST = "


# Kontakt 5, Pianobello (LMMS)
%-lmms-pianobello-raw.wav: %.mmp support/Kontakt5.dll support/pianobello.nki
	< instruments/kontakt5-pianobello.lmms $(LMMS_SETINSTRUMENT) $< $*-lmms-pianobello-raw.tmp
	@echo
	@echo
	@echo MANUAL TASK:
	@echo Please load
	@echo $(CURDIR)/support/pianobello.nki
	@echo into Kontakt 5, then export as $@
	@echo
	@echo
	lmms $*-lmms-pianobello.tmp
	[ -f $@ ]

# Format 0 MIDI (friendly for the synths)
%-format0.mid: %.mid
	bin/to_format0.pl $< $@ 0 5 1

# Audio renderers
%-timidity-campbell-raw.wav: %.mid support/CampbellsPianoBeta2.sf2
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETSOUNDFONT_PRE) support/CampbellsPianoBeta2.sf2      $(TIMIDITY_SETSOUNDFONT_POST) -EI0 -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-timidity-freepats-raw.wav: %.mid support/000_Acoustic_Grand_Piano.pat
	$(TIMIDITY) $(TIMIDITYFLAGS) $(TIMIDITY_SETGUSPATCH_PRE)  support/000_Acoustic_Grand_Piano.pat $(TIMIDITY_SETGUSPATCH_POST)  -EI0 -EFreverb=G,70 -EFchorus=n,40 -Ow -o $@ $<
%-linuxsampler-pleyelp190-raw.wav: %-format0.mid support/PleyelP190.gig
	bin/linuxsampler.sh $< $(CURDIR)/support/PleyelP190.gig $@
%-linuxsampler-steinwayc-raw.wav: %-format0.mid support/SteinwayC.gig
	bin/linuxsampler.sh $< $(CURDIR)/support/SteinwayC.gig $@
%-linuxsampler-maestro-raw.wav: %-format0.mid support/maestro_concert_grand_v2.gig
	bin/linuxsampler.sh $< $(CURDIR)/support/maestro_concert_grand_v2.gig - | sox - $*-linuxsampler-maestro-tmp.wav
	sox $*-linuxsampler-maestro-tmp.wav $@ reverb 50 50 60 100 0 0

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
