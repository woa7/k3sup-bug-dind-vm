#curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#/releases/latest
#sudo curl -L --fail https://github.com/docker/compose/releases/download/1.26.2/run.sh -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose


RUN curl -L --fail https://github.com/docker/compose/releases/latest/download/run.sh -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose
