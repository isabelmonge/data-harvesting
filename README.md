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




# API

This project collects financial data from the Alpha Vantage API for S&P 500 companies using three different approaches to overcome API rate limits.

## Overview

This project combines multiple data collection strategies into a comprehensive financial data tool:

1. **API Data Collection**: Uses three different approaches to efficiently gather data from Alpha Vantage API

## Prerequisites

- **R/RStudio**: Version 4.0.0 or higher with required packages
- **Tor Browser**: For IP rotation approach - [Download here](https://www.torproject.org/download/)
- **Python 3.6+**: With the `requests` package installed

## API Data Collection Approaches

We've implemented three different approaches to efficiently collect data while respecting API limitations:

### 1. Auto Tor IP Rotation Approach

#### Overview
The Auto Tor IP Rotation approach uses the Tor network to rotate IP addresses, allowing us to make multiple API requests without hitting rate limits. This method is resolves the issue that Alpha Vantage has a hard limit of 25 requests per day and per IP address/

#### Installation

##### For macOS Users
1. Clone this repository
2. Navigate to the repository folder
3. Run the installation script:
   ```bash
   chmod +x autotor/install_autotor_mac.sh
   ./autotor/install_autotor_mac.sh
   ```
4. The script will install all necessary components

##### For Linux Users
1. Clone this repository
2. Navigate to the repository folder
3. Run the installation script:
   ```bash
   chmod +x autotor/install_autotor_linux.sh
   ./autotor/install_autotor_linux.sh
   ```
4. Again, the script will install all necessary components

#### Usage
1. Start the Auto Tor IP Changer:
   ```bash
   aut
   ```
2. When prompted:
   - Set the interval to 75 seconds
   - Press enter in order to choose "infinite" for the number of changes
3. Open another terminal window and run the R script:
   ```bash
   Rscript API_key_rotation_Tor_2.R
   ```

#### How It Works
1. **IP Rotation**: The Auto Tor IP Changer restarts the Tor Browser at regular intervals, providing the user with a new IP address each time
2. **Proxy Configuration**: The R script connects through the Tor SOCKS proxy (127.0.0.1:9150)
3. **API Requests**: With constantly rotating IPs, you can make more API requests without triggering rate limits

#### Troubleshooting
- **Tor Browser not starting**: Make sure Tor Browser is properly installed
- **Connection errors**: Verify that Tor is running properly and the SOCKS proxy is accessible
- **Slow response times**: This is normal when using Tor; consider adjusting request intervals

### 2. API Key Rotation Approach

#### Overview
This approach cycles through multiple Alpha Vantage API keys to maximize the number of requests within a given timeframe.

#### Setup
1. Create a `.env` file in the root directory with your Alpha Vantage API keys:
   ```
   ALPHA_VANTAGE_KEY_1=YOUR_KEY_1
   ALPHA_VANTAGE_KEY_2=YOUR_KEY_2
   # Add more keys as needed
   ```

2. Install required R packages:
   ```r
   install.packages(c("httr", "jsonlite", "dotenv", "rvest"))
   ```

#### Usage
Run the API key rotation script:
```bash
Rscript API_key_rotation_manual.R
```

#### How It Works
1. The script loads multiple API keys from the `.env` file
2. Requests are distributed across these keys to stay within rate limits
3. Data is collected in batches, with progress saved after each batch

### 3. Manual Collection with Scheduling

#### Overview
This approach strategically schedules API requests over time to collect data while respecting API limits.

#### Usage
```bash
Rscript fallback_alpha_vantage.R
```

#### Configuration Parameters
You can customize the data collection process by modifying these parameters in the R script:
- `batch_size`: Number of companies to collect in each batch (default: 50)
- `interval_seconds`: Time between processing symbols (default: 75 seconds)
- `max_retries`: Maximum retry attempts for failed symbols (default: 3)


## Troubleshooting

### Common Issues:

#### API Collection Issues
- **API rate limits**: Verify your approach configuration and adjust parameters if needed
- **Connection timeouts**: Check your internet connection and retry
- **Missing data**: Some symbols may not have complete data available; check logs for details

#### Auto Tor Issues
- **Cannot connect to Tor**: 
  - Ensure Tor Browser is running
  - Verify you clicked "Always connect automatically" when Tor Browser opened
  - Check if port 9150 is accessible

 
## Project Information

This is a school project created to demonstrate data acquisition, storage and integration techniques using web scraping, API calls, and interactive visualization.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.







