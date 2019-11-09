#!/bin/bash
find . -maxdepth 1 -type d |cut -d/ -f2|grep ^_ | while read folder ; do 
  find $(pwd)/$folder -type f | while read file ; do
      
    ln -s $file /srv/salt/state/$folder/$(basename $file) 
  done
done


