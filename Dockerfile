FROM ocaml/opam:debian-10-ocaml-4.09

USER 1000:100
WORKDIR /src
RUN sudo chown opam /src
RUN sudo apt-get install time
RUN git clone --branch opam-monorepo https://gitlab.com/CraigFe/tezos ./ #A

# Setup Rust toolchain & run deps script (requires a fake switch prefix)
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.44.0 -y
ENV PATH="~/.cargo/bin:${PATH}"
ENV OPAM_SWITCH_PREFIX="${HOME}/opam-virtual-switch"
RUN mkdir ${OPAM_SWITCH_PREFIX}
RUN ./scripts/install_build_deps.rust.sh

# Get and initialise `opam-monorepo`
RUN opam pin add opam-monorepo git+https://github.com/CraigFe/opam-monorepo.git\#fix-solver-problem -n
RUN opam depext opam-monorepo
RUN opam install opam-monorepo

# Optional: generate the lock file from scratch
COPY . /overlays
RUN opam repo add overlays -k local /overlays
RUN time opam monorepo lock --recurse-opam --versions ocaml.4.09.1

# Pull and build!
RUN time opam monorepo pull # NOTE: this pull is very quiet when not a TTY
RUN time opam exec -- dune build
