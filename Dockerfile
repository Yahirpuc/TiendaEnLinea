FROM tiangolo/uvicorn-gunicorn-fastapi:python3.8

# Establece el directorio de trabajo en la raíz
WORKDIR /

# Copia los archivos de requirements.txt a la raíz del contenedor
COPY ./requirements.txt /requirements.txt

# Instala las dependencias necesarias
# Actualiza el sistema e instala las dependencias necesarias
RUN apt-get update && \
    apt-get install -y \
    curl \
    apt-transport-https \
    gnupg \
    unixodbc-dev \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && rm -rf /var/lib/apt/lists/*
    
RUN pip install --no-cache-dir -r /requirements.txt

# Copia el resto de los archivos del proyecto a la raíz del contenedor
COPY . .

# Expone el puerto que la aplicación usará
EXPOSE 8000

# Define el comando por defecto para ejecutar cuando el contenedor se inicie
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
