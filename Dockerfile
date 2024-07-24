FROM tiangolo/uvicorn-gunicorn-fastapi:python3.8

WORKDIR /app

COPY ./app /app
COPY ./requirements.txt /app/requirements.txt
COPY ./Login /app/Login
COPY ./PaginasDeInicio /app/PaginasDeInicio
COPY ./PaginasNav /app/PaginasNav
COPY ./PanelAdministracion /app/PanelAdministracion

COPY ./Index.html /app/Index.html

RUN apt-get update && apt-get install -y curl apt-transport-https gnupg
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17
RUN apt-get install -y unixodbc-dev
RUN pip install --no-cache-dir -r /app/requirements.txt

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
