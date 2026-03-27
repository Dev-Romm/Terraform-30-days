#!/bin/bash
cat > index.html <<EOF
<h1>${web_message}. These are Gotchas and Versioning</h1>
EOF
nohup busybox httpd -f -p ${server_port} &