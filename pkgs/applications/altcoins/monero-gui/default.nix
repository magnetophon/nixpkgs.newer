{ stdenv, fetchFromGitHub
, makeWrapper, makeDesktopItem
, qtbase, qmake, qtmultimedia, qttools
, qtgraphicaleffects, qtdeclarative
, qtlocation, qtquickcontrols2, qtwebchannel
, qtwebengine, qtx11extras, qtxmlpatterns
, monero, unbound, readline, boost, libunwind
, pcsclite, zeromq, cppzmq, pkgconfig
, CoreData
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "monero-gui-${version}";
  version = "0.12.0.0";

  src = fetchFromGitHub {
    owner  = "monero-project";
    repo   = "monero-gui";
    rev    = "v${version}";
    sha256 = "1mg5ival8a2wdp14yib4wzqax4xyvd40zjy9anhszljds1439jhl";
  };

  nativeBuildInputs = [ qmake pkgconfig ];

  buildInputs = [
    qtbase qtmultimedia qtgraphicaleffects
    qtdeclarative qtlocation qtquickcontrols2
    qtwebchannel qtwebengine qtx11extras
    qtxmlpatterns monero unbound readline
    boost libunwind pcsclite zeromq cppzmq
    makeWrapper
  ] ++ stdenv.lib.optional stdenv.isDarwin CoreData;

  patches = [
    ./move-log-file.patch
    ./move-translations-dir.patch
  ];

  postPatch = ''
    echo '
      var GUI_VERSION = "${version}";
      var GUI_MONERO_VERSION = "${getVersion monero}";
    ' > version.js
    substituteInPlace monero-wallet-gui.pro \
      --replace '$$[QT_INSTALL_BINS]/lrelease' '${getDev qttools}/bin/lrelease'
    substituteInPlace src/daemon/DaemonManager.cpp \
      --replace 'QApplication::applicationDirPath() + "' '"${monero}/bin'
  '';

  makeFlags = [ "INSTALL_ROOT=$(out)" ];

  preBuild = ''
    sed -i s#/opt/monero-wallet-gui##g Makefile
    make -C src/zxcvbn-c
  '';

  desktopItem = makeDesktopItem {
    name = "monero-wallet-gui";
    exec = "monero-wallet-gui";
    icon = "monero";
    desktopName = "Monero Wallet";
    genericName = "Wallet";
    categories  = "Application;Network;Utility;";
  };

  postInstall = ''
    # install desktop entry
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications

    # install translations
    cp -r release/bin/translations $out/share/

    # install icons
    for n in 16 24 32 48 64 96 128 256; do
      size=$n"x"$n
      mkdir -p $out/share/icons/hicolor/$size/apps
      cp $src/images/appicons/$size.png \
         $out/share/icons/hicolor/$size/apps/monero.png
    done;
  '';

  meta = {
    description = "Private, secure, untraceable currency";
    homepage    = https://getmonero.org/;
    license     = licenses.bsd3;
    platforms   = platforms.all;
    maintainers = with maintainers; [ rnhmjoj ];
  };
}
