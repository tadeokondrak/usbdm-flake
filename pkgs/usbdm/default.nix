{ stdenv
, lib
, fetchFromGitHub
, wxGTK30
, libusb
, xercesc
, tcl
, jdk ? null
, javaSupport ? false
}:

stdenv.mkDerivation {
  pname = "usbdm";
  version = "4.12.1.270";

  src = fetchFromGitHub {
    owner = "podonoghue";
    repo = "usbdm-eclipse-makefiles-build";
    rev = "927e69b67b88ea0ffee42a0203d4b0c86674843a";
    sha256 = "sha256-FznsxNdesx1CmCuyfiTiUAs2Hhc4HBRMlHwuy4l/3DA=";
  };

  enableParallelBuilding = true;

  buildInputs = [
    wxGTK30
    libusb
    xercesc
    tcl
  ]
  ++ lib.optional javaSupport jdk
  ;

  hardeningDisable = [ "fortify" ];

  postPatch = ''
    patchShebangs .
    substituteInPlace Common.mk \
        --replace "/usr/share/java/java_defaults.mk" "/dev/null"
    for f in Makefile-x{32,64}.mk; do
        substituteInPlace "$f" \
            --replace "UsbdmJni_DLL" "${if javaSupport then "UsbdmJni_DLL" else ""}"
    done
    substituteInPlace Makefile-x64.mk \
        --replace "USBDM_API_Example" "" \
        --replace "USBDM_Programmer_API_Example" ""
    for f in PackageFiles/MiscellaneousLinux/*.desktop; do
      substituteInPlace "$f" \
          --replace "/usr/bin/" "$out/bin/"
    done
    for f in Shared/src/{PluginFactory,SingletonPluginFactory,Common}.h; do
        substituteInPlace "$f" \
            --replace '#define USBDM_INSTALL_DIRECTORY "/usr"' '#define USBDM_INSTALL_DIRECTORY "'$out'"'
    done
  '';

  buildPhase = ''
    ./MakeAll
  '';

  installPhase = ''
    mkdir -p $out/{share/{applications,pixmaps,doc/usbdm,usbdm,man/man1},etc/udev/rules.d}
    cp PackageFiles/MiscellaneousLinux/Hardware-Chip.png $out/share/pixmaps
    cp PackageFiles/MiscellaneousLinux/*.desktop $out/share/applications
    cp PackageFiles/MiscellaneousLinux/usbdm.rules $out/etc/udev/rules.d/46-usbdm.rules
    cp PackageFiles/MiscellaneousLinux/{changelog.Debian.gz,copyright} $out/share/doc/usbdm
    cp PackageFiles/Miscellaneous/{nano.specs,*.xlkr,error.wav} $out/share/usbdm
    cp PackageFiles/MiscellaneousLinux/{TryProgrammer,usbdm.rules} $out/share/usbdm
    cp PackageFiles/Scripts/*.tcl $out/share/usbdm
    cp -r PackageFiles/{WizardPatches,DeviceData,Stationery,Examples,FlashImages,LaunchConfig} $out/share/usbdm
    cp -r PackageFiles/lib $out/lib
    cp -r PackageFiles/bin $out/bin
    rm -f $out/bin/{CopyFlash,*TestImage,*Example,Test*}
    for f in Documentation/ManPages/*; do
      cp $f $f.1
      gzip --best -f $f.1
      mv $f.1.gz $out/share/man/man1
    done
  '';
}
