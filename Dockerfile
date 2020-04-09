FROM archlinux:latest
RUN pacman -Syyu --noconfirm && pacman -S git openssh base-devel openmpi --noconfirm
RUN git clone https://github.com/the-kiel/TopoSAT2
RUN cd TopoSAT2 && ./buildSolver.sh
