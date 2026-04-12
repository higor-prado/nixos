{
  conda.disabled = true;
  format = "[](red)$os$username$hostname[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:green bg:lavender)$time[ ](fg:lavender)$cmd_duration$line_break$character";
  hostname.format = "[@$hostname]($style)";
  hostname.style = "bg:red fg:base bold";
  hostname.ssh_only = true;
  character.format = "\n$symbol ";
  character.success_symbol = "[❯](bold fg:green)";
  character.error_symbol = "[❯](bold fg:red)";
  character.vimcmd_symbol = "[❮](bold fg:green)";
  character.vimcmd_replace_one_symbol = "[❮](bold fg:lavender)";
  character.vimcmd_replace_symbol = "[❮](bold fg:lavender)";
  character.vimcmd_visual_symbol = "[❮](bold fg:yellow)";
}
