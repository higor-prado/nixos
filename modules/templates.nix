# Flake templates output - devenv project templates
{ lib, ... }:
let
  devenvTemplateRoot = ../config/devenv-templates;
  devenvTemplateDirs = lib.filterAttrs (_: fileType: fileType == "directory") (
    builtins.readDir devenvTemplateRoot
  );
  devenvTemplateNames = builtins.attrNames devenvTemplateDirs;
  devenvTemplates = lib.genAttrs devenvTemplateNames (name: {
    path = devenvTemplateRoot + "/${name}";
    description = "devenv project template (${name})";
  });
in
{
  flake.templates =
    devenvTemplates
    // lib.optionalAttrs (devenvTemplateDirs ? python) {
      default = devenvTemplates.python;
    };
}
