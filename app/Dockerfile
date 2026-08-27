FROM python:3.12-slim

# Create a non-root user to run the app — production containers should never run as root
RUN useradd --create-home appuser

WORKDIR /app

# Copy only requirements first — this layer gets cached and only rebuilds
# when requirements.txt actually changes, not on every code edit
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the rest of the app code
COPY . .

# Switch to the non-root user before running the app
USER appuser

EXPOSE 5000

ENV APP_ENV=production

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["python", "app.py"]
