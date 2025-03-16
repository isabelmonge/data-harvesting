# Web Scraper Tool

A Selenium-based web scraper using R to automate data collection, combined with API data integration and Shiny app visualization.

## Overview

This project combines multiple data sources into a comprehensive data tool:

1. **Web Scraper**: Uses Docker, Selenium, and R to automatically collect web data
2. **API Integration**: Fetches additional data through API calls
3. **Shiny App**: Combines and visualizes all data in an interactive dashboard

## Prerequisites

- **Docker Desktop:** [Download here](https://www.docker.com/products/docker-desktop/)
- **R/RStudio:** Make sure R is installed and available from command line

## Quick Start Guide

### Windows Users
1. Install Docker Desktop and make sure it's running
2. Clone this repository or download the ZIP
3. Double-click `run_scraper.bat`
4. Wait for the process to complete
5. Find your data in the output folder

### Mac/Linux Users
1. Install Docker Desktop and make sure it's running
2. Clone this repository: `git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git`
3. Navigate to the repository folder: `cd YOUR-REPO-NAME`
4. Make the script executable: `chmod +x run_scraper.sh`
5. Run the script: `./run_scraper.sh`
6. Wait for the process to complete
7. Find your data in the output folder

## How It Works

This project operates in several steps:

### Web Scraper
1. **Setup:** Pulls and runs a Selenium Firefox container from Docker Hub
2. **Execution:** Runs the R script that connects to the Selenium container
3. **Data Collection:** The script navigates to target websites, extracts data, and saves it locally

### API Integration
The system also fetches complementary data through API calls, which is processed and stored alongside the scraped data.

### Shiny App
A Shiny application combines data from both sources (web scraper and API) to create interactive visualizations and analysis tools.

## Troubleshooting

### Common Issues:

- **Docker not running error:**
  Make sure Docker Desktop is running before starting the scraper

- **Port already in use error:**
  Run this command in the terminal to remove any existing containers: docker rm -f scraper_container

  - **Script errors or no data:**
Check your internet connection and make sure the target website hasn't changed its structure

## Project Components

### Web Scraper
- Uses Selenium and Firefox to automate web browsing
- Collects structured data from target websites
- Runs in a containerized environment for consistent performance

### API Integration
- Connects to external data sources via API
- Processes and standardizes API responses
- Combines with scraped data for comprehensive analysis

### Shiny Application
- Interactive dashboard for data exploration
- Visualizes combined data from both sources
- Provides filtering and analysis tools

## Project Information

This is a school project created to demonstrate data acquisition, storage and integration techniques using web scraping, API calls, and interactive visualization.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
