FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1
ENV VENV_PATH="/app/venv"

WORKDIR /app
RUN python -m venv $VENV_PATH

COPY requirements.txt main.py ./
RUN pip install --no-cache-dir -r requirements.txt

ADD spacelift.bash /usr/bin/spacelift.bash
RUN chmod +x /usr/bin/spacelift.bash

ENTRYPOINT [ "/usr/bin/spacelift.bash" ]
