FROM python:latest

WORKDIR /srv/eleados

COPY requirements.txt .

RUN pip install -r requirements.txt


COPY cbor.py  database.py  main.py  mqtt.py tasks.py .


CMD ["python", "main.py"]
