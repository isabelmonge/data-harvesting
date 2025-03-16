library(httr)
library(jsonlite)
library(curl)
library(dotenv)

# Function to check current IP
check_current_ip <- function(max_attempts = 3) {
  for (attempt in 1:max_attempts) {
    tryCatch({
      # Configure to use Tor SOCKS proxy
      h <- new_handle()
      handle_setopt(h, proxy = "socks5h://127.0.0.1:9150")
      handle_setopt(h, timeout = 30)
      
      # Get IP through Tor
      cat("Checking IP (attempt", attempt, ")...\n")
      response <- curl_fetch_memory("https://api.ipify.org", h)
      ip_address <- rawToChar(response$content)
      
      cat("Current IP through Tor:", ip_address, "\n")
      return(ip_address)
    }, error = function(e) {
      cat("Error checking IP (attempt", attempt, "):", e$message, "\n")
      if (attempt < max_attempts) {
        cat("Waiting 5 seconds before retry...\n")
        Sys.sleep(5)
      }
    })
  }
  return(NULL)
}

# Function to get company data via Alpha Vantage
get_company_data <- function(symbol, api_key, max_attempts = 3) {
  for (attempt in 1:max_attempts) {
    # Set up the Tor proxy with curl package
    h <- new_handle()
    handle_setopt(h, proxy = "socks5h://127.0.0.1:9150")
    handle_setopt(h, timeout = 30)
    
    # Build the Alpha Vantage API URL
    url <- paste0(
      "https://www.alphavantage.co/query?function=OVERVIEW&symbol=", 
      symbol, 
      "&apikey=", 
      api_key
    )
    
    cat("Fetching data for", symbol, "(attempt", attempt, ")...\n")
    
    # Make the request through Tor
    tryCatch({
      response <- curl_fetch_memory(url, h)
      
      # Parse the JSON response
      data <- fromJSON(rawToChar(response$content))
      
      # Check for API errors or limits
      if (!is.null(data$Information) && grepl("API rate limit", data$Information)) {
        cat("API rate limit hit for", symbol, "\n")
        if (attempt < max_attempts) {
          cat("Waiting for IP rotation before retry...\n")
          Sys.sleep(15)  # Wait for IP rotation
          next
        }
        return(NULL)
      }
      
      if (!is.null(data$`Error Message`)) {
        cat("API Error for", symbol, ":", data$`Error Message`, "\n")
        return(NULL)
      }
      
      if (length(data) == 0 || (length(data) == 1 && is.null(names(data)))) {
        cat("Empty response received for", symbol, "\n")
        return(NULL)
      }
      
      cat("Successfully fetched data for", symbol, "\n")
      return(data)
      
    }, error = function(e) {
      cat("Error fetching data for", symbol, "(attempt", attempt, "):", e$message, "\n")
      if (attempt < max_attempts) {
        cat("Waiting before retry...\n")
        Sys.sleep(5)
      }
    })
  }
  return(NULL)
}

# Function to extract comprehensive metrics from the OVERVIEW endpoint
extract_company_metrics <- function(data, symbol) {
  tryCatch({
    metrics <- data.frame(
      # Basic Information
      Symbol = symbol,
      Name = ifelse(is.null(data$Name), NA, data$Name),
      Sector = ifelse(is.null(data$Sector), NA, data$Sector),
      Industry = ifelse(is.null(data$Industry), NA, data$Industry),
      
      # Valuation Metrics
      PE_Ratio = ifelse(is.null(data$PERatio), NA, as.numeric(data$PERatio)),
      PEG_Ratio = ifelse(is.null(data$PEGRatio), NA, as.numeric(data$PEGRatio)),
      Price_to_Book = ifelse(is.null(data$PriceToBookRatio), NA, as.numeric(data$PriceToBookRatio)),
      Price_to_Sales = ifelse(is.null(data$PriceToSalesRatioTTM), NA, as.numeric(data$PriceToSalesRatioTTM)),
      EV_to_EBITDA = ifelse(is.null(data$EVToEBITDA), NA, as.numeric(data$EVToEBITDA)),
      EV_to_Revenue = ifelse(is.null(data$EVToRevenue), NA, as.numeric(data$EVToRevenue)),
      
      # Profitability 
      Profit_Margin = ifelse(is.null(data$ProfitMargin), NA, as.numeric(data$ProfitMargin)),
      Operating_Margin = ifelse(is.null(data$OperatingMarginTTM), NA, as.numeric(data$OperatingMarginTTM)),
      Return_on_Assets = ifelse(is.null(data$ReturnOnAssetsTTM), NA, as.numeric(data$ReturnOnAssetsTTM)),
      Return_on_Equity = ifelse(is.null(data$ReturnOnEquityTTM), NA, as.numeric(data$ReturnOnEquityTTM)),
      
      # Growth
      Revenue_Growth_YOY = ifelse(is.null(data$QuarterlyRevenueGrowthYOY), NA, as.numeric(data$QuarterlyRevenueGrowthYOY)),
      EPS_Growth_YOY = ifelse(is.null(data$QuarterlyEarningsGrowthYOY), NA, as.numeric(data$QuarterlyEarningsGrowthYOY)),
      
      # Financial Health
      Current_Ratio = ifelse(is.null(data$CurrentRatio), NA, as.numeric(data$CurrentRatio)),
      Debt_to_Equity = ifelse(is.null(data$DebtToEquityRatio), NA, as.numeric(data$DebtToEquityRatio)),
      Interest_Coverage = ifelse(is.null(data$InterestCoverageRatio), NA, as.numeric(data$InterestCoverageRatio)),
      
      # Dividend & Shareholder Returns
      Dividend_Yield = ifelse(is.null(data$DividendYield), NA, as.numeric(data$DividendYield)),
      Dividend_Per_Share = ifelse(is.null(data$DividendPerShare), NA, as.numeric(data$DividendPerShare)),
      Dividend_Payout_Ratio = ifelse(is.null(data$PayoutRatio), NA, as.numeric(data$PayoutRatio)),
      
      # Market & Technical
      Beta = ifelse(is.null(data$Beta), NA, as.numeric(data$Beta)),
      Fifty_Two_Week_High = ifelse(is.null(data$`52WeekHigh`), NA, as.numeric(data$`52WeekHigh`)),
      Fifty_Two_Week_Low = ifelse(is.null(data$`52WeekLow`), NA, as.numeric(data$`52WeekLow`)),
      
      # Additional Size/Scale Metrics
      Market_Cap = ifelse(is.null(data$MarketCapitalization), NA, as.numeric(data$MarketCapitalization)),
      EBITDA = ifelse(is.null(data$EBITDA), NA, as.numeric(data$EBITDA)),
      Revenue_TTM = ifelse(is.null(data$RevenueTTM), NA, as.numeric(data$RevenueTTM)),
      
      stringsAsFactors = FALSE
    )
    
    return(metrics)
  }, error = function(e) {
    cat("Error processing data for", symbol, ":", e$message, "\n")
    # Return minimal data if error occurs
    data.frame(Symbol = symbol, Name = NA, Sector = NA, stringsAsFactors = FALSE)
  })
}

# Function to get S&P 500 symbols
get_sp500_symbols <- function() {
  tryCatch({
    # Using Wikipedia as source
    url <- "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"
    
    # Import libraries if needed
    if (!requireNamespace("rvest", quietly = TRUE)) {
      install.packages("rvest")
      library(rvest)
    } else {
      library(rvest)
    }
    
    # Scrape the table
    page <- read_html(url)
    tables <- html_nodes(page, "table.wikitable")
    sp500_table <- html_table(tables[1], fill = TRUE)[[1]]
    
    # Extract symbols
    symbols <- sp500_table$Symbol
    
    # Clean symbols (remove .* if present)
    symbols <- gsub("\\.", "-", symbols)
    
    cat("Retrieved", length(symbols), "S&P 500 symbols\n")
    return(symbols)
  }, error = function(e) {
    cat("Error retrieving S&P 500 symbols:", e$message, "\n")
    cat("Using backup S&P 500 symbols list\n")
    
    # Backup list of major S&P 500 components (top 30 by weight)
    backup_symbols <- c("AAPL", "MSFT", "AMZN", "NVDA", "GOOGL", "META", "GOOG", "BRK-B", 
                        "UNH", "LLY", "JPM", "XOM", "V", "AVGO", "PG", "MA", "HD", "COST", 
                        "MRK", "ABBV", "CVX", "PEP", "KO", "ADBE", "WMT", "CRM", "BAC", 
                        "TMO", "ACN", "MCD")
    return(backup_symbols)
  })
}

# Modified collection function that uses CSV instead of RDS for progress tracking
collect_data_tor <- function(symbols, api_keys, interval_seconds = 75, 
                             stabilization_seconds = 25, max_retries = 3,
                             requests_per_key = 25) {
  cat("Starting data collection using Tor rotation and API key rotation\n")
  cat("Using", length(api_keys), "API keys with", requests_per_key, "requests per key\n")
  
  # Check if Tor is running
  cat("Verifying Tor connection...\n")
  initial_ip <- check_current_ip()
  if (is.null(initial_ip)) {
    cat("ERROR: Cannot connect to Tor. Make sure the Tor Browser is running.\n")
    return(NULL)
  }
  
  cat("Tor connection verified. Initial IP:", initial_ip, "\n")
  
  # Initialize results dataframe and retry queue
  results_df <- data.frame()
  retry_queue <- data.frame(
    symbol = character(0),
    attempts = integer(0),
    last_error = character(0),
    stringsAsFactors = FALSE
  )
  
  # API key tracking
  current_key_index <- 1
  current_key <- api_keys[current_key_index]
  requests_with_current_key <- 0
  
  # Process each symbol
  for (i in seq_along(symbols)) {
    symbol <- symbols[i]
    cat("\n==== Processing", i, "of", length(symbols), ":", symbol, "====\n")
    
    # API key rotation check
    if (requests_with_current_key >= requests_per_key) {
      current_key_index <- current_key_index %% length(api_keys) + 1
      current_key <- api_keys[current_key_index]
      cat("\n*** Rotating to API key", current_key_index, "of", length(api_keys), "***\n")
      requests_with_current_key <- 0
    }
    
    # Add stabilization period before each request to ensure Tor connection is ready
    if (i > 1) {  # Skip first symbol as we already verified connection
      cat("Waiting", stabilization_seconds, "seconds for Tor connection to stabilize...\n")
      Sys.sleep(stabilization_seconds)
    }
    
    # Check current IP with multiple retries
    current_ip <- NULL
    for (retry in 1:5) {  # Up to 5 retries for IP check
      current_ip <- check_current_ip(max_attempts = 1)  # Single attempt per retry
      if (!is.null(current_ip)) break
      cat("Retrying IP check in 3 seconds...\n")
      Sys.sleep(3)
    }
    
    if (is.null(current_ip)) {
      cat("WARNING: Could not verify Tor IP before processing", symbol, "\n")
      cat("Adding", symbol, "to retry queue for safety\n")
      retry_queue <- rbind(retry_queue, data.frame(
        symbol = symbol,
        attempts = 0,
        last_error = "Could not verify Tor IP",
        stringsAsFactors = FALSE
      ))
      # Wait the standard interval before continuing
      if (i < length(symbols)) {
        cat("Waiting", interval_seconds, "seconds before next symbol...\n")
        Sys.sleep(interval_seconds)
      }
      next  # Skip this symbol for now
    }
    
    cat("Using IP:", current_ip, "\n")
    
    # Get data
    cat("Using API key:", substr(current_key, 1, 5), "...\n")
    data <- get_company_data(symbol, current_key)
    requests_with_current_key <- requests_with_current_key + 1
    
    if (!is.null(data)) {
      # Extract metrics and add to results dataframe
      symbol_metrics <- extract_company_metrics(data, symbol)
      
      # Check if the results_df is empty
      if (nrow(results_df) == 0) {
        results_df <- symbol_metrics
      } else {
        results_df <- rbind(results_df, symbol_metrics)
      }
      
      cat("Data for", symbol, "collected successfully\n")
      cat("API key", current_key_index, "has been used for", requests_with_current_key, "requests\n")
      
      # Save progress to a temporary batch file after each successful request
      batch_temp_file <- paste0("batch_progress_temp.csv")
      write.csv(results_df, batch_temp_file, row.names = FALSE)
      cat("Progress saved to temporary file\n")
    } else {
      cat("Failed to get data for", symbol, ", adding to retry queue\n")
      retry_queue <- rbind(retry_queue, data.frame(
        symbol = symbol,
        attempts = 0,
        last_error = "Initial fetch failed",
        stringsAsFactors = FALSE
      ))
    }
    
    # Wait for the next IP rotation from the aut script
    if (i < length(symbols)) {
      cat("Waiting", interval_seconds, "seconds for next IP rotation...\n")
      Sys.sleep(interval_seconds)
    }
  }
  
  # Process retry queue with exponential backoff
  if (nrow(retry_queue) > 0) {
    cat("\n\n==== Processing retry queue ====\n")
    cat("There are", nrow(retry_queue), "symbols in the retry queue\n")
    
    # Wait longer before starting retries to ensure Tor is stable
    retry_wait <- 180  # 3 minutes initial wait
    cat("Waiting", retry_wait, "seconds before starting retries...\n")
    Sys.sleep(retry_wait)
    
    # Continue retrying until queue is empty or max retries reached
    while (nrow(retry_queue) > 0) {
      # Get first symbol from queue
      current <- retry_queue[1, ]
      symbol <- current$symbol
      attempts <- current$attempts + 1
      
      # Check if we've reached max retries
      if (attempts > max_retries) {
        cat("\nSymbol", symbol, "has reached maximum retry attempts (", max_retries, ")\n")
        cat("Giving up on this symbol\n")
        # Remove from queue
        retry_queue <- retry_queue[-1, ]
        next
      }
      
      # API key rotation for retries too
      if (requests_with_current_key >= requests_per_key) {
        current_key_index <- current_key_index %% length(api_keys) + 1
        current_key <- api_keys[current_key_index]
        cat("\n*** Rotating to API key", current_key_index, "of", length(api_keys), "for retry ***\n")
        requests_with_current_key <- 0
      }
      
      # Calculate exponential backoff
      backoff_time <- 30 * (2 ^ (attempts - 1))  # 30, 60, 120 seconds...
      
      cat("\n==== Retry attempt", attempts, "for", symbol, "====\n")
      cat("Previous error:", current$last_error, "\n")
      
      # Verify Tor connection
      cat("Verifying Tor connection for retry...\n")
      current_ip <- check_current_ip()
      
      if (is.null(current_ip)) {
        cat("WARNING: Could not verify Tor IP for retry. Waiting", backoff_time, "seconds...\n")
        Sys.sleep(backoff_time)
        
        # Update retry queue
        retry_queue$attempts[1] <- attempts
        retry_queue$last_error[1] <- "Could not verify Tor IP on retry"
        # Move to the end of the queue
        retry_queue <- rbind(retry_queue[-1, ], retry_queue[1, ])
        next
      }
      
      cat("Using IP for retry:", current_ip, "\n")
      
      # Get data
      cat("Using API key:", substr(current_key, 1, 5), "...\n")
      data <- get_company_data(symbol, current_key)
      requests_with_current_key <- requests_with_current_key + 1
      
      if (!is.null(data)) {
        # Extract metrics and add to results dataframe
        symbol_metrics <- extract_company_metrics(data, symbol)
        
        # Add to results dataframe
        if (nrow(results_df) == 0) {
          results_df <- symbol_metrics
        } else {
          results_df <- rbind(results_df, symbol_metrics)
        }
        
        cat("Data for", symbol, "collected successfully on retry\n")
        cat("API key", current_key_index, "has been used for", requests_with_current_key, "requests\n")
        
        # Save progress to a temporary batch file
        batch_temp_file <- paste0("batch_progress_temp.csv")
        write.csv(results_df, batch_temp_file, row.names = FALSE)
        cat("Progress saved to temporary file\n")
        
        # Remove from retry queue
        retry_queue <- retry_queue[-1, ]
      } else {
        cat("Retry failed for", symbol, ". Waiting", backoff_time, "seconds...\n")
        Sys.sleep(backoff_time)
        
        # Update retry queue
        retry_queue$attempts[1] <- attempts
        retry_queue$last_error[1] <- paste("Retry", attempts, "failed")
        # Move to the end of the queue
        retry_queue <- rbind(retry_queue[-1, ], retry_queue[1, ])
      }
    }
  }
  
  cat("\n==== Data collection complete ====\n")
  cat("Successfully collected data for", nrow(results_df), "out of", length(symbols), "symbols\n")
  
  # Return results
  return(results_df)
}

# Load environment variables
dotenv::load_dot_env()

# Get API keys from environment
get_api_keys <- function() {
  # Get all environment variables
  all_env <- Sys.getenv()
  
  # Filter for Alpha Vantage keys
  key_names <- grep("^ALPHA_VANTAGE_KEY_", names(all_env), value = TRUE)
  
  # Extract the values
  api_keys <- sapply(key_names, function(key) Sys.getenv(key))
  
  # Filter out empty keys
  api_keys <- api_keys[api_keys != ""]
  
  if (length(api_keys) == 0) {
    stop("No Alpha Vantage API keys found in environment variables. Please check your .env file.")
  }
  
  cat("Found", length(api_keys), "API keys in environment variables\n")
  return(api_keys)
}

# Get API keys from environment
api_keys <- get_api_keys()

# Load existing progress from CSV
if (file.exists("sp500_fundamentals_combined.csv")) {
  combined_df <- read.csv("sp500_fundamentals_combined.csv", stringsAsFactors = FALSE)
  already_collected <- combined_df$Symbol
  cat("Already collected data for", length(already_collected), "companies from CSV file:\n")
  cat(paste(already_collected, collapse=", "), "\n\n")
} else {
  combined_df <- data.frame()
  already_collected <- c()
}

# Get full S&P 500 list
all_sp500 <- get_sp500_symbols()

# Remove companies you've already collected
remaining_symbols <- all_sp500[!all_sp500 %in% already_collected]
cat("Remaining companies to collect:", length(remaining_symbols), "\n")

# Define how many companies to collect in this run
companies_to_collect <- 150  # Adjust this number as needed

# Randomly sample from remaining symbols
if (length(remaining_symbols) > 0) {
  # If we have fewer remaining symbols than requested, collect all of them
  if (length(remaining_symbols) <= companies_to_collect) {
    batch_symbols <- remaining_symbols
    cat("Collecting all remaining", length(batch_symbols), "symbols:\n")
  } else {
    # Randomly sample the requested number
    set.seed(Sys.time()) # Use current time as seed for true randomness
    batch_symbols <- sample(remaining_symbols, companies_to_collect)
    cat("Collecting", companies_to_collect, "randomly selected symbols:\n")
  }
  
  cat(paste(batch_symbols, collapse=", "), "\n\n")
  
  # Collect data for this batch
  batch_results <- collect_data_tor(
    symbols = batch_symbols,
    api_keys = api_keys,
    interval_seconds = 75,
    stabilization_seconds = 25,
    max_retries = 3,
    requests_per_key = 25
  )
  
  # Process and save the results for this batch
  if (!is.null(batch_results) && nrow(batch_results) > 0) {
    # Generate a timestamp for the batch file
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    batch_csv_name <- paste0("sp500_fundamentals_batch_", timestamp, ".csv")
    
    # Save this batch as its own CSV
    write.csv(batch_results, batch_csv_name, row.names = FALSE)
    cat("Batch results saved to", batch_csv_name, "\n")
    
    # If we have previous results, combine them
    if (nrow(combined_df) > 0) {
      # Remove any duplicates (in case of overlaps)
      combined_df <- combined_df[!combined_df$Symbol %in% batch_results$Symbol, ]
      
      # Combine with new batch
      full_df <- rbind(combined_df, batch_results)
      
      # Save combined results
      write.csv(full_df, "sp500_fundamentals_combined.csv", row.names = FALSE)
      cat("Combined results updated with", nrow(batch_results), "new companies\n")
      cat("Total companies in combined file:", nrow(full_df), "\n")
    } else {
      # First batch, just save as combined
      write.csv(batch_results, "sp500_fundamentals_combined.csv", row.names = FALSE)
      cat("Combined results file created with", nrow(batch_results), "companies\n")
    }
  } else {
    cat("No data was collected in this run.\n")
  }
} else {
  cat("No more symbols to process. All S&P 500 companies have been collected.\n")
}
