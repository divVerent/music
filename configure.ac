AC_INIT([divVerents-music],[0.1],[divVerent@xonotic.org])
AC_CONFIG_MACRO_DIR([m4])

AC_ARG_WITH(lame, AS_HELP_STRING([--without-lame], [Do not use LAME to make .mp3 output files]), [with_lame=$withval], [with_lame=yes])
AC_ARG_WITH(oggenc, AS_HELP_STRING([--with-oggenc], [Use vorbis-tools to make .ogg output files]), [with_oggenc=$withval], [with_oggenc=no])
AC_ARG_WITH(flac, AS_HELP_STRING([--without-flac], [Do not use flac to make .flac output files]), [with_flac=$withval], [with_flac=yes])
AC_ARG_WITH(timidity, AS_HELP_STRING([--with-timidity], [Use timidity outputs]), [with_timidity=$withval], [with_timidity=no])
AC_ARG_WITH(linuxsampler, AS_HELP_STRING([--without-linuxsampler], [Use LinuxSampler outputs]), [with_linuxsampler=$withval], [with_linuxsampler=yes])
AC_ARG_WITH(linuxsampler-pleyelp190, AS_HELP_STRING([--with-linuxsampler-pleyelp190], [Use Pleyel P190.gig (http://www.gigfiles.com/freebees.php)]), [with_linuxsampler_pleyelp190=$withval], [with_linuxsampler_pleyelp190=no])
AC_ARG_WITH(linuxsampler-steinwayc, AS_HELP_STRING([--with-linuxsampler-steinwayc], [Use Steinway C.gig (http://www.gigfiles.com/freebees.php)]), [with_linuxsampler_steinwayc=$withval], [with_linuxsampler_steinwayc=no])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
