FROM postgres:13.8

COPY ./data ./data
COPY ./setup ./setup
COPY ./setup.sh .
COPY ./setup_seed_data.sh .
COPY ./init_db.sh .

RUN apt-get update && apt-get install -y \
    make \
    unzip \
    gdal-bin \
    p7zip-full \
    python3-pip \
    libpq-dev \
    postgis

RUN pip install bcdata
RUN chmod +x setup.sh
RUN chmod +x setup_seed_data.sh
RUN chmod +x init_db.sh

CMD [ "./init_db.sh" ]