cd ~/Downloads
inotifywait -m . -e create -e moved_to |
  while read path action file; do
    echo "The file '$file' appeared in directory '$path' via '$action'"
    # do something with the file
    # sleep 2
    [ -f document.pdf ] && mv -f document.pdf ~/www/document.pdf
  done
