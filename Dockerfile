FROM rocker/verse
RUN wget https://sqlite.org/snapshot/sqlite-snapshot-202110132029.tar.gz
RUN tar xvf sqlite-snapshot-202110132029.tar.gz
WORKDIR sqlite-snapshot-202110132029
RUN ./configure && make && make install
WORKDIR /
RUN apt update && apt-get install -y openssh-server
RUN ssh-keygen -A
RUN mkdir -p /run/sshd
RUN sudo usermod -aG sudo rstudio
RUN apt update && DEBIAN_FRONTEND=noninteractive apt-get install -y dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev asciidoc xmlto docbook2x
RUN git clone git://git.kernel.org/pub/scm/git/git.git
WORKDIR /git
RUN make configure &&\
 ./configure --prefix=/usr &&\
 make all doc info &&\
 make install 
WORKDIR /
RUN R -e "install.packages('RSQLite')";
RUN apt update && apt install -y software-properties-common
RUN add-apt-repository ppa:kelleyk/emacs
RUN DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install -y emacs28
