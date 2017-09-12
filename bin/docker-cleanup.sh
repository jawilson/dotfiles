#!/bin/bash

echo "WARN: This will remove everything from docker: volumes, containers and images. Will you dare? [y/N] "
read choice

if [ \( "$choice" == "y" \) -o \( "$choice" == "Y" \) ]
then
  sudo echo "> sudo rights [OK]"
  sizea=`sudo du -sh /var/lib/docker/aufs`

  echo "Stopping all running containers"
  containers=`docker ps -a -q`
  if [ -n "$containers" ]
  then
    docker stop $containers
  fi

  echo "Removing all docker images and containers"
  docker system prune -f

  echo "Stopping Docker daemon"
  sudo service docker stop

  echo "Removing all leftovers in /var/lib/docker (bug #22207)"
  sudo rm -rf /var/lib/docker/aufs
  sudo rm -rf /var/lib/docker/image/aufs
  sudo rm -f /var/lib/docker/linkgraph.db

  echo "Starting Docker daemon"
  sudo service docker start

  sizeb=`sudo du -sh /var/lib/docker/aufs`
  echo "Size before full cleanup:"
  echo "        $sizea"
  echo "Size after full cleanup:"
  echo "        $sizeb"
fi