#!/bin/bash

echo "websites list:"
echo ""

websites=$(ls -1 /etc/apache2/sites-enabled)

if [ -z "$websites" ]; then
	echo "no websites"
else
	echo $websites
fi

