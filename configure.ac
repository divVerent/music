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

AC_ARG_WITH(lame, AS_HELP_STRING([--without-lame], [Do not use LAME to make .mp3 output files]), [with_lame=$withval], [with_lame=yes])
RP_CONDITIONAL(lame,[test x$with_lame = xyes])

AC_ARG_WITH(oggenc, AS_HELP_STRING([--without-oggenc], [Do not use vorbis-tools to make .ogg output files]), [with_oggenc=$withval], [with_oggenc=yes])
RP_CONDITIONAL(oggenc,[test x$with_oggenc = xyes])

AC_ARG_WITH(flac, AS_HELP_STRING([--without-flac], [Do not use flac to make .flac output files]), [with_flac=$withval], [with_flac=yes])
RP_CONDITIONAL(flac,[test x$with_flac = xyes])

AC_ARG_WITH(timidity, AS_HELP_STRING([--without-timidity], [Use timidity outputs]), [with_timidity=$withval], [with_timidity=yes])
RP_CONDITIONAL(timidity,[test x$with_timidity = xyes])

AC_ARG_WITH(fluidsynth, AS_HELP_STRING([--without-fluidsynth], [Do not use fluidsynth outputs]), [with_fluidsynth=$withval], [with_fluidsynth=yes])
RP_CONDITIONAL(fluidsynth,[test x$with_fluidsynth = xyes])

AC_ARG_WITH(linuxsampler, AS_HELP_STRING([--without-linuxsampler], [Do not use LinuxSampler outputs]), [with_linuxsampler=$withval], [with_linuxsampler=yes])
RP_CONDITIONAL(linuxsampler,[test x$with_linuxsampler = xyes])

AC_ARG_WITH(linuxsampler-pleyelp190, AS_HELP_STRING([--with-linuxsampler-pleyelp190], [Use Pleyel P190.gig (http://www.gigfiles.com/freebees.php)]), [with_linuxsampler_pleyelp190=$withval], [with_linuxsampler_pleyelp190=no])
RP_CONDITIONAL(linuxsampler_pleyelp190,[test x$with_linuxsampler_pleyelp190 = xyes])

AC_ARG_WITH(linuxsampler-steinwayc, AS_HELP_STRING([--with-linuxsampler-steinwayc], [Use Steinway C.gig (http://www.gigfiles.com/freebees.php)]), [with_linuxsampler_steinwayc=$withval], [with_linuxsampler_steinwayc=no])
RP_CONDITIONAL(linuxsampler_steinwayc,[test x$with_linuxsampler_steinwayc = xyes])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
