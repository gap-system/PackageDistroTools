ScanForUpdates := function(pkg_name, pkg_info_fname, distro_version)
  local pkginfo;
  if not IsExistingFile( pkg_info_fname) then
    # TODO better errors
    Error( "no package name given and no PackageInfo.g file found" );
  elif not IsReadableFile( pkg_info_fname) then
    # TODO better errors
    Error( "cannot read PackageInfo.g" );
  fi;
  Unbind( GAPInfo.PackageInfoCurrent );
  Read( pkg_info_fname );
  if not IsBound( GAPInfo.PackageInfoCurrent ) then
    Error( "reading PackageInfo.g failed" );
  fi;
  pkginfo := GAPInfo.PackageInfoCurrent;
  FileString(Concatenation(pkg_name, ".version"), pkginfo.Version);
  QUIT_GAP(pkginfo.Version = distro_version);
end;
