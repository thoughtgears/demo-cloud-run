FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1
ENV VENV_PATH="/app/venv"

WORKDIR /app
RUN python -m venv $VENV_PATH

COPY . .
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
