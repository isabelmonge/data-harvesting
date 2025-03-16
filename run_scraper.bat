@echo off
echo Setting up scraper...

REM Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Error: Docker is not running. Please start Docker Desktop and try again.
  pause
  exit /b 1
)

REM Remove existing container if it exists
docker rm -f scraper_container > nul 2>&1

REM Pull the Selenium Firefox image
echo Pulling Selenium Firefox image (this may take a moment)...
docker pull selenium/standalone-firefox:latest

REM Run the Selenium container
echo Starting Selenium container...
docker run -d -p 4449:4444 --name scraper_container selenium/standalone-firefox:latest

REM Wait for container to be ready
echo Waiting for Selenium to initialize...
timeout /t 5 /nobreak > nul

REM Check if the container is running
docker ps | find "scraper_container" > nul
if %ERRORLEVEL% NEQ 0 (
  echo Error: Failed to start Selenium container. Please check Docker logs.
  pause
  exit /b 1
)

REM Create output directory if it doesn't exist
if not exist output mkdir output

REM Run the R script
echo Running R script...
Rscript scraper_script.R

echo Done! Your data has been saved to the output folder.
pause
