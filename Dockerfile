FROM ocaml/opam:alpine-3.5_ocaml-4.04.2 
RUN sudo apk add --update sudo
COPY . /home/opam/src
RUN sudo chown -R opam /home/opam/src
WORKDIR /home/opam/src
EXPOSE 8080
RUN ./container-run.sh
CMD ["/home/opam/src/src/nickrobison-www"]
