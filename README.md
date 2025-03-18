# Stock Market Sentiment Analysis and Performance Tracking Using Scraping and APIs

A Selenium-based web scraper using R to automate data collection, combined with API data integration and Shiny app visualization.

## Overview

This project combines multiple data sources into a comprehensive data tool:

1. **Web Scraper**: Uses Docker, Selenium, and R to automatically collect earnings call transcripts
2. **API Integration**: Fetches additional stock market data through API calls
3. **Shiny App**: Combines and visualizes all data in an interactive dashboard

## Web Scraper Instructions

### Step 1: Set up Docker container

1. **Install Docker Desktop** for your operating system:
   - [Download Docker](https://www.docker.com/get-started)
   
2. **Start Docker and run the Selenium Firefox container:**
   ```bash
   docker run -d -p 4449:4444 --name selenium_firefox selenium/standalone-firefox:3.141.59
   ```
   **Note for Mac users with Apple Silicon (M1/M2/M3):** You may see a warning about platform mismatch (amd64 vs arm64). This is normal, and the container should still work properly.

3. **Verify the container is running:**
   ```bash
   docker ps
   ```
   You should see a container named `selenium_firefox` in the list.

### Step 2: Set up R environment

1. **Download and install R from CRAN:**
   - **Windows users:** Select "Download R for Windows"
   - **Mac users:** Select "Download R for macOS"
     - For Apple Silicon Macs (M1/M2/M3), download the `arm64` version
   - **Linux users:** Select "Download R for Linux" and follow the instructions for your distribution
   
2. **Install RStudio Desktop**: [Download RStudio](https://posit.co/download/rstudio-desktop/)

3. **Open R or RStudio and install the required packages:**
   ```r
   install.packages(c("RSelenium", "rvest", "xml2", "lubridate", "tidyquant"))
   ```
   
### Step 3: Run the Scraper

1. **Download the `scraper_script.R` file** from this repository.
2. **Open R or RStudio**.
3. **Set your working directory** to where you saved the script:
   ```r
   setwd("/path/to/folder/with/script")  # Replace with actual path
   ```
4. **Run the script:**
   ```r
   source("scraper_script.R")
   ```

The script will:
- Connect to the Selenium Firefox container
- Scrape earnings call transcripts for S&P 500 companies
- Create a file called `all_transcripts.csv` with the results
- Make results available in R via the `current_transcripts_df` variable

### Troubleshooting

- **If Docker container stops:** Restart it with:
  ```bash
  docker restart selenium_firefox
  ```
- **If the script can't connect to Selenium:** Check that the container is running:
  ```bash
  docker ps
  ```
- **For network issues:** Ensure that port `4449` is available on your system.
- If you get a container conflict error: This means a container with the name selenium_firefox already exists. You have two options:

   1. Remove the existing container before creating a new one:
```bash
docker rm -f selenium_firefox
```
   Then re-run the docker run command.

   2. Run the new container with a different name by changing selenium_firefox to something unique:
```bash
docker run -d -p 4449:4444 --name selenium_firefox_new selenium/standalone-firefox:3.141.59
```

## API Instructions

These instructions outline three approaches to efficiently collect S&P 500 data from the Alpha Vantage API while respecting rate limits.

### Prerequisites

- **R/RStudio**: Version 4.0.0 or higher with required packages
- **Tor Browser**: For IP rotation approach - [Download here](https://www.torproject.org/download/) (note: this webpage may not work on institutional wifi networks with high security controls)
- **Python 3.6+**: With the `requests` package installed
- **.env file with API keys** API keys can be generated [here](https://www.alphavantage.co/support/#api-key) 

### 1. Main approach: Auto Tor IP Rotation

#### Overview
The Auto Tor IP Rotation approach uses the Tor network to rotate IP addresses, allowing us to make multiple API requests without hitting rate limits. This method resolves the issue that Alpha Vantage has a hard limit of 25 requests per day and per IP address. We used the following tutorial to make it work: https://github.com/FDX100/Auto_Tor_IP_changer

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
   Rscript API_main_approach.R
   ```

#### How It Works
1. **IP Rotation**: The Auto Tor IP Changer restarts the Tor Browser at regular intervals, providing the user with a new IP address each time
2. **Proxy Configuration**: The R script connects through the Tor SOCKS proxy (127.0.0.1:9150)
3. **API Requests**: With constantly rotating IPs, you can make more API requests without triggering rate limits

#### Troubleshooting
- **Tor Browser not starting**: Make sure Tor Browser is properly installed
- **Connection errors**: Verify that Tor is running properly and the SOCKS proxy is accessible
- **Slow response times**: This is normal when using Tor; consider adjusting request intervals

### 2. Backup 1: batched requests approach

#### Overview
This approach intelligently cycles through multiple Alpha Vantage API keys to maximize data collection efficiency while respecting rate limits. It prioritizes companies by market cap and implements a smart refresh cycle to keep high-value data updated.

#### Setup

Create a .env file in the root directory with your Alpha Vantage API keys:
ALPHA_VANTAGE_KEY_1=YOUR_KEY_1
ALPHA_VANTAGE_KEY_2=YOUR_KEY_2
Add more keys as needed

``` R # Create .env
writeLines("ALPHA_VANTAGE_KEY_1=YOUR_KEY_1", ".env")
```

Install required R packages:
``` R # Install packages
install.packages(c("httr", "jsonlite", "dotenv", "rvest"))
```

#### Usage
Run the API key rotation script:
``` bash 
fallback_alpha_vantage.R
```
Or with options:
``` bash
fallback_alpha_vantage.R --auto --refresh=5 --combined=sp500_fundamentals_combined.csv
```

How It Works

Smart Prioritization: The script prioritizes S&P 500 companies by market capitalization

Refresh Cycles: Top companies are refreshed more frequently in a configurable cycle

Key Management: When one API key hits its rate limit, the script automatically switches to the next one

Progress Tracking: Each day's collection is logged and saved separately, while also updating a master dataset

Error Handling: Failed requests are retried and logged, ensuring robust data collection

#### Configuration Options

--auto: Run in automatic mode

--refresh=N: Set the refresh cycle for top companies (default: 5 days)

--combined=FILE: Specify the combined output file path

### 3. Backup 2: manual Collection with VPN Rotation

#### Overview
This approach uses manual VPN rotation with multiple API keys to efficiently collect data while respecting Alpha Vantage's rate limits. The script intelligently manages API keys and tracks collection progress, prompting you to change your VPN location when needed.

#### Prerequisites

Any free VPN service (we used PrivadoVPN)
Multiple Alpha Vantage API keys in a .env file

#### Usage

First run: Execute the entire script and then run the main function:
``` R # Load the script
source("API_key_rotation_manual.R")
```

``` R # Start collection with 100 companies, 25 requests per IP
main(sample_size = 100, requests_per_ip = 25)
```

When the VPN rotation message appears, change your VPN location
``` R # To check where you left off:
check_collection_progress()
```

``` R # To continue collection:
main(start_index = 42)  # Replace with the "Next start index" value from previous step
```

#### How It Works

The script intelligently selects uncollected S&P 500 companies. It manages multiple API keys to respect Alpha Vantage's rate limits (5 calls per minute, 25 calls per day)
After a set number of requests per IP (requests_per_ip) - which is set to 25 by default - it prompts you to change your VPN location. Progress is automatically saved after each successful request, allowing you to resume at any time. The script maintains detailed logs of the collection process and generates both partial and complete datasets

### Configuration Options

sample_size: Number of companies to collect (default: 100)
requests_per_ip: Requests before VPN rotation (default: 25)
start_index: Index to resume collection from
data_file: Path to the output CSV file


### Troubleshooting

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

