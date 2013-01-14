#!/bin/bash

## Timezone
echo "Europe/Berlin" > /etc/timezone
dpkg-reconfigure -fnoninteractive tzdata
