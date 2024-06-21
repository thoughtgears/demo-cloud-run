FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1
ENV VENV_PATH="/app/venv"

WORKDIR /app
RUN python -m venv $VENV_PATH

COPY . .
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
