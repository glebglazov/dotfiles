function copy-file-to-clipboard() {
  local absolute_path
  absolute_path=$(realpath "$1") || return 1

  osascript -l JavaScript -e "
    ObjC.import('AppKit');
    var pb = \$.NSPasteboard.generalPasteboard;
    pb.clearContents;
    var url = \$.NSURL.fileURLWithPath('$absolute_path');
    pb.writeObjects(\$([url]));
  " >/dev/null
}
