FROM archlinux:latest
RUN pacman -Syyu --noconfirm && pacman -S git openssh base-devel openmpi aws-cli iproute2 --noconfirm
RUN mkdir /root/TopoSAT2
RUN git clone https://github.com/qtja/TopoSAT2-Source /root/TopoSAT2
RUN cd /root/TopoSAT2 && ./buildSolver.sh

# Setup SSHD
RUN mkdir /var/run/sshd
RUN echo 'root:THEPASSWORDYOUCREATED' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
ENV SSHDIR /root/.ssh
RUN mkdir -p ${SSHDIR}
RUN touch ${SSHDIR}/sshd_config
RUN ssh-keygen -t rsa -f ${SSHDIR}/ssh_host_rsa_key -N ''
RUN cp ${SSHDIR}/ssh_host_rsa_key.pub ${SSHDIR}/authorized_keys
RUN cp ${SSHDIR}/ssh_host_rsa_key ${SSHDIR}/id_rsa
RUN echo " IdentityFile ${SSHDIR}/id_rsa" >> /etc/ssh/ssh_config
RUN echo "Host *" >> /etc/ssh/ssh_config && echo " StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN chmod -R 600 ${SSHDIR}/* && \
chown -R ${USER}:${USER} ${SSHDIR}/
# check if ssh agent is running or not, if not, run
RUN eval `ssh-agent -s` && ssh-add ${SSHDIR}/id_rsa

ADD make_combined_hostfile.py /root/TopoSAT2/make_combined_hostfile.py
ADD mpi-run.sh /root/TopoSAT2/mpi-run.sh
RUN chmod 755 /root/TopoSAT2/mpi-run.sh
EXPOSE 22

CMD /root/TopoSAT2/mpi-run.sh