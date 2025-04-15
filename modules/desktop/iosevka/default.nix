{ iosevka }:

iosevka.override {
  privateBuildPlan = builtins.readFile ./private-build-plans.toml;
  set = "Custom";
}
