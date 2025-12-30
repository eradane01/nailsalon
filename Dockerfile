FROM rocker/shiny:4.3.2

RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny', 'shinyjs', 'DBI', 'RSQLite'), repos='https://cloud.r-project.org')"

WORKDIR /srv/shiny-server/app

COPY app.R .
COPY www ./www

RUN chmod -R 777 /srv/shiny-server/app

# Render-required port
EXPOSE 10000

# Override Shiny port for Render
ENV SHINY_PORT=10000

CMD ["/usr/bin/shiny-server"]
