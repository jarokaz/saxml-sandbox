FROM locustio/locust

RUN pip install -U pip 
RUN pip install jsonlines google-cloud-pubsub google-cloud-storage 

WORKDIR /app
COPY . .

