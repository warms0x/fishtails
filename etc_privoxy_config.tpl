forward-socks4a / 127.0.0.1:9050 .
confdir /etc/privoxy
logdir /var/log/privoxy
actionsfile standard  # Internal purpose, recommended
actionsfile default   # Main actions file
actionsfile user      # User customizations
filterfile default.filter
jarfile jarfile
listen-address  127.0.0.1:8118
toggle  1
enable-remote-toggle  1
enable-edit-actions 1
buffer-limit 4096
