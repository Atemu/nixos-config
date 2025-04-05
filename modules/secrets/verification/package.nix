{
  lib,
  rustPlatform,
  runCommand,
  rustfmt,
}:

rustPlatform.buildRustPackage {
  name = "secrets-verification";

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  src =
    let
      # Only copy a select few files, not the entire tree that includes Nix code
      files = [
        "src"
        "Cargo.toml"
        "Cargo.lock"
      ];
      commands =
        [
          "mkdir -p $out"
        ]
        ++ (map (file: "cp -r ${./${file}} $out/${file}") files);
      script = lib.concatLines commands;
    in
    runCommand "source" { } script;

  nativeBuildInputs = [
    rustfmt
  ];

  meta = {
    mainProgram = "verification";
  };
}
