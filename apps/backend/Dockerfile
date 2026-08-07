FROM python:3.13-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apk add --no-cache --virtual .build-dependencies build-base linux-headers swig wget \
    && wget -qO- https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz | tar -xz -C /tmp \
    && make -C /tmp/lg-0.2.2 lib \
    && install -m 0755 /tmp/lg-0.2.2/liblgpio.so.1 /usr/lib/ \
    && ln -s liblgpio.so.1 /usr/lib/liblgpio.so

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && apk del .build-dependencies

COPY src ./src

EXPOSE 8080

CMD ["python", "src/app.py"]