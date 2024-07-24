FROM tiangolo/uvicorn-gunicorn-fastapi:python3.8

# Establece el directorio de trabajo en /app
WORKDIR /





# Instala las dependencias necesarias
RUN apt-get update && apt-get install -y curl apt-transport-https gnupg
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17
RUN apt-get install -y unixodbc-dev
RUN pip install --no-cache-dir -r requirements.txt

# Expone el puerto que la aplicación usará
EXPOSE 8000

# Define el comando por defecto para ejecutar cuando el contenedor se inicie
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
