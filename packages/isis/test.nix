# Runs a few command-line applications end to end: no ISISDATA, no display.
{
  runCommand,
  isis,
}:
runCommand "isis-smoke-test" { nativeBuildInputs = [ isis ]; } ''
  export HOME=$TMPDIR ISISDATA=$TMPDIR/isisdata
  mkdir -p $ISISDATA
  cd $TMPDIR

  makecube to=flat.cub samples=64 lines=64 bands=1 value=5
  stats from=flat.cub to=stats.pvl
  grep -E 'Average += 5\.0' stats.pvl
  grep -E 'ValidPixels += 4096' stats.pvl
  catlab from=flat.cub | grep -q 'Object = IsisCube'

  touch $out
''
