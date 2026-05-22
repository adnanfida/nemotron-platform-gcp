FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir flask==3.0.3

COPY app.py /app/app.py

EXPOSE 8000 9400

ENV TOKEN_DELAY_SECS=0.05

CMD ["python", "app.py"]
