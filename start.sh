#!/bin/bash 

function box_out()
{
  local s=("$@") b w
  for l in "${s[@]}"; do
    ((w<${#l})) && { b="$l"; w="${#l}"; }
  done
  tput setaf 3
  echo " -${b//?/-}-
| ${b//?/ } |"
  for l in "${s[@]}"; do
    printf '| %s%*s%s |\n' "$(tput setaf 4)" "-$w" "$l" "$(tput setaf 3)"
  done
  echo "| ${b//?/ } |
 -${b//?/-}-"
  tput sgr 0
}

docker build . -t ufo

MODE=$1
PORT_SHIFT=$2

if [ -z "$PORT_SHIFT" ];
then
    PORT_SHIFT=111
fi

let MAIN_PORT=$((8787 + PORT_SHIFT))
let SSH_PORT=$((8722 + PORT_SHIFT))
let EX_PORT=$((8080 + PORT_SHIFT))
let JL_PORT=$((8765 + PORT_SHIFT))


if [ -z "$MODE" ] || [ "$MODE" == "rstudio" ];
then
export R_PASS=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo)
docker run --rm \
 -p $MAIN_PORT:8787 \
 -p $SSH_PORT:22 \
 -p $EX_PORT:8080\
 -e PASSWORD=$R_PASS\
 -v $(pwd):/home/rstudio/work\
 -d\
 -t ufo > /tmp/docker-output

export DOUT=$(cat /tmp/docker-output)

echo $DOUT

export CID=$(echo $DOUT | tail -1)

box_out 'Log into RStudio on port 8787'\
        'Username: rstudio'\
        "Password: $R_PASS"\
        'to kill the docker container'\
        "run \"docker kill $CID\""

fi

if [ "$MODE" == "term" ];
then
x11docker --clipboard --share ~/.ssh --share $(pwd) --share ~/.emacs.d --share ~/.emacs-trash ufo /bin/xfce4-terminal
fi

if [ "$MODE" == "emacs" ];
then
    xhost +SI:localuser:$(whoami) 
    docker run -p $EX_PORT:8080 \
       -p $MAIN_PORT:8787 \
       -v $HOME/.emacs.d:/home/rstudio/.emacs.d \
       -v $HOME/.emacs-trash:/home/rstudio/.emacs-trash \
       -v $HOME/emacs-local:/home/rstudio/emacs-local \
       -v $(pwd):/home/rstudio/work \
       --user rstudio \
       --workdir /home/rstudio/work\
       -e DISPLAY=:0\
       -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0\
       -v $HOME/.Xauthority:/home/rstudio/.Xauthority\
       -it ufo\
       emacs /home/rstudio/work
fi

if [ "$MODE" == "jupyterlab" ];
then
    export R_PASS=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo)
    docker run \
           -p $JL_PORT:8765 \
           -p $EX_PORT:8080 \
           -v `pwd`:/home/rstudio/work \
           -e PASSWORD=$R_PASS \
           -it ufo sudo -H -u rstudio /bin/bash -c "cd ~/; jupyter lab --ip 0.0.0.0 --port 8765 --no-browser"
fi

if [ "$MODE" == "shell" ];
then
    docker run \
           -v `pwd`:/home/rstudio/project \
           -it ufo sudo -H -u rstudio /bin/bash 
fi


