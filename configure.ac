AC_INIT([divVerents-music],[0.1],[divVerent@xonotic.org])
AC_CONFIG_MACRO_DIR([m4])

dnl simplified AM_CONDITIONAL
AC_DEFUN([RP_CONDITIONAL],
[AC_PREREQ(2.52)dnl
 AC_SUBST([$1_TRUE])dnl
 AC_SUBST([$1_FALSE])dnl
 if $2; then
  $1_TRUE=
  $1_FALSE='#'
 else
  $1_TRUE='#'
  $1_FALSE=
 fi])

# detect check option and test if the binary exists then

AC_DEFUN([RP_PROGOPTION],
[
AS_IF(
	[test x$with_[]$1 = xno],
		[$1=],
	[
		AC_PATH_PROG($1,$1,[])
		AS_IF(
			[test x$with_[]$1 = xcheck],
				[],
			[test -z [$]$1],
				[AC_MSG_FAILURE([--with-$1 was given, but $1 was not found])])])
RP_CONDITIONAL($1,[test -n $1])
AC_SUBST($1,[[$]$1])
AC_SUBST($1[_flags],[[$]m4_toupper($1)[FLAGS]])
])

AC_DEFUN([RP_NEEDPROG],
[
AC_PATH_PROG($1,$1,[])
AS_IF(
	[test -z [$]$1],
		[AC_MSG_FAILURE([--with-$1 was given, but $1 was not found])])
RP_CONDITIONAL($1,[test -n $1])
AC_SUBST($1,[[$]$1])
AC_SUBST($1[_flags],[[$]m4_toupper($1)[FLAGS]])
])

AS_IF([test -z $LAMEFLAGS],[LAMEFLAGS="--preset standard"])
AS_IF([test -z $OGGENCFLAGS],[OGGENCFLAGS="-q3"])
AS_IF([test -z $FLACFLAGS],[FLACFLAGS="-8"])

RP_NEEDPROG(cp)
RP_NEEDPROG(patch)
RP_NEEDPROG(lilypond)
RP_NEEDPROG(wget)
RP_NEEDPROG(unrar)
RP_NEEDPROG(sox)
RP_NEEDPROG(gzip)
RP_NEEDPROG(gunzip)
RP_NEEDPROG(rosegarden)
RP_NEEDPROG(mp3gain)
RP_NEEDPROG(vorbisgain)

AC_ARG_WITH(lame, AS_HELP_STRING([--without-lame], [Do not use LAME to make .mp3 output files]), [with_lame=$withval], [with_lame=yes])
RP_PROGOPTION(lame)

AC_ARG_WITH(oggenc, AS_HELP_STRING([--without-oggenc], [Do not use vorbis-tools to make .ogg output files]), [with_oggenc=$withval], [with_oggenc=yes])
RP_PROGOPTION(oggenc)

AC_ARG_WITH(flac, AS_HELP_STRING([--without-flac], [Do not use flac to make .flac output files]), [with_flac=$withval], [with_flac=yes])
RP_PROGOPTION(flac)

AC_ARG_WITH(timidity, AS_HELP_STRING([--without-timidity], [Use timidity outputs]), [with_timidity=$withval], [with_timidity=yes])
RP_PROGOPTION(timidity)

AC_ARG_WITH(fluidsynth, AS_HELP_STRING([--without-fluidsynth], [Do not use fluidsynth outputs]), [with_fluidsynth=$withval], [with_fluidsynth=yes])
RP_PROGOPTION(fluidsynth)

AC_ARG_WITH(linuxsampler, AS_HELP_STRING([--without-linuxsampler], [Do not use LinuxSampler outputs]), [with_linuxsampler=$withval], [with_linuxsampler=yes])
RP_PROGOPTION(linuxsampler)

AC_ARG_WITH(linuxsampler-pleyelp190, AS_HELP_STRING([--with-linuxsampler-pleyelp190], [Use Pleyel P190.gig (http://www.gigfiles.com/freebees.php)]), [with_linuxsampler_pleyelp190=$withval], [with_linuxsampler_pleyelp190=no])
RP_CONDITIONAL(linuxsampler_pleyelp190,[test -n $with_linuxsampler_pleyelp190])

AC_ARG_WITH(linuxsampler-steinwayc, AS_HELP_STRING([--with-linuxsampler-steinwayc], [Use Steinway C.gig (http://www.gigfiles.com/freebees.php)]), [with_linuxsampler_steinwayc=$withval], [with_linuxsampler_steinwayc=no])
RP_CONDITIONAL(linuxsampler_steinwayc,[test -n $with_linuxsampler_steinwayc])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
