#!/bin/bash
SRC_PATH="${HOME}/dotfiles"

function linkhome {
  ln -snifr ${SRC_PATH}/${1} ~/${1}
}


for f in $(cat ${SRC_PATH}/homelink.txt);do
  echo "Linking ${f} in homedir"
  linkhome $f
done

