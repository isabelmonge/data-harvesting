#!/bin/bash
echo "Setting up scraper..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

# Remove existing container if it exists
docker rm -f scraper_container > /dev/null 2>&1

# Pull the Selenium Firefox image
echo "Pulling Selenium Firefox image (this may take a moment)..."
docker pull selenium/standalone-firefox:latest

# Run the Selenium container
echo "Starting Selenium container..."
docker run -d -p 4449:4444 --name scraper_container selenium/standalone-firefox:latest

# Wait for container to be ready
echo "Waiting for Selenium to initialize..."
sleep 5

# Check if the container is running
if ! docker ps | grep -q scraper_container; then
  echo "Error: Failed to start Selenium container. Please check Docker logs."
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p output

# Run the R script
echo "Running R script..."
Rscript scraper_script.R

echo "Done! Your data has been saved to the output folder."
echo "Press any key to close this window..."
read -n 1 -s
