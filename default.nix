{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, util-linux
, hexdump
, autoSignDarwinBinariesHook ? null
, wrapQtAppsHook ? null
, boost
, libevent
, miniupnpc
, zeromq
, zlib
, db48
, sqlite
, qrencode
, qtbase ? null
, qttools ? null
, python3
, withGui ? false
, withWallet ? true
}:

stdenv.mkDerivation rec {
  pname = if withGui then "sequentia" else "sequentiad";
  version = "23.2.1";

  src = ./.;

  nativeBuildInputs =
    [ autoreconfHook pkg-config ]
    ++ lib.optionals stdenv.isLinux [ util-linux ]
    ++ lib.optionals stdenv.isDarwin [ hexdump ]
    ++ lib.optionals (stdenv.isDarwin && stdenv.isAarch64) [ autoSignDarwinBinariesHook ]
    ++ lib.optionals withGui [ wrapQtAppsHook ];

  buildInputs = [ boost libevent miniupnpc zeromq zlib ]
    ++ lib.optionals withWallet [ db48 sqlite ]
    ++ lib.optionals withGui [ qrencode qtbase qttools ];

  configureFlags = [
    "--with-boost-libdir=${boost.out}/lib"
    "--disable-bench"
  ] ++ lib.optionals (!doCheck) [
    "--disable-tests"
    "--disable-gui-tests"
  ] ++ lib.optionals (!withWallet) [
    "--disable-wallet"
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ];

  # fix "Killed: 9  test/test_bitcoin"
  # https://github.com/NixOS/nixpkgs/issues/179474
  hardeningDisable = lib.optionals (stdenv.isAarch64 && stdenv.isDarwin) [ "fortify" "stackprotector" ];

  nativeCheckInputs = [ python3 ];

  doCheck = false;

  checkFlags =
    [ "LC_ALL=en_US.UTF-8" ]
    # QT_PLUGIN_PATH needs to be set when executing QT, which is needed when testing Bitcoin's GUI.
    # See also https://github.com/NixOS/nixpkgs/issues/24256
    ++ lib.optional withGui "QT_PLUGIN_PATH=${qtbase}/${qtbase.qtPluginPrefix}";

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Open Source implementation of advanced blockchain features extending the Bitcoin protocol";
    longDescription= ''
      The Elements blockchain platform is a collection of feature experiments and extensions to the
      Bitcoin protocol. This platform enables anyone to build their own businesses or networks
      pegged to Bitcoin as a sidechain or run as a standalone blockchain with arbitrary asset
      tokens.
    '';
    homepage = "https://www.github.com/ElementsProject/elements";
    maintainers = with maintainers; [ prusnak ];
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
