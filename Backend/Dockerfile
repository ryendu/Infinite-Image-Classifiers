# For more information, please refer to https://aka.ms/vscode-docker-python
FROM python:3.8-slim-buster

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1
ARG FLASK_ENV="production"
ENV FLASK_ENV="${FLASK_ENV}" \
    PYTHONUNBUFFERED="true"
# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1

# Install pip requirements
ADD requirements_x86.txt .
RUN python -m pip install -r requirements_x86.txt
RUN apt-get update
RUN apt-get install ffmpeg libsm6 libxext6  -y

WORKDIR /app
ADD . /app

RUN mkdir -p app/tmp
RUN mkdir -p app/tmp/finishedModels
RUN mkdir -p app/tmp/visualization
EXPOSE 5000

# Switching to a non-root user, please refer to https://aka.ms/vscode-docker-python-user-rights
RUN useradd appuser && chown -R appuser /app
USER appuser

# ENTRYPOINT ["gunicorn","--chdir","app","main:app","-w","2","--threads","2","-b","0.0.0.0:5000"]
ENTRYPOINT ["gunicorn","--chdir","app","main:app","-b","0.0.0.0:5000"]
