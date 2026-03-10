{ lib }:
let
  escape = lib.escapeShellArg;
in
{
  mkCopyOnce =
    {
      source,
      target,
      mode ? "0644",
    }:
    ''
      target="${target}"
      if [ ! -f "$target" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
        $DRY_RUN_CMD cp ${escape (toString source)} "$target"
        $DRY_RUN_CMD chmod ${escape mode} "$target"
      fi
    '';
}
