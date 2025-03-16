library(RSelenium)
library(rvest)
library(xml2)
library(lubridate)
library(tidyquant)

# function to scrape transcripts for multiple tickers with Docker restart
scrape_transcripts_with_restart <- function(tickers, container_name = "selenium_firefox") {
  all_transcripts <- list()
  processed_count <- 0
  
  # create a global variable for the combined dataframe
  assign("current_transcripts_df", data.frame(), envir = .GlobalEnv)
  
  for (ticker in tickers) {
    cat(paste0("\n=== Processing ticker: ", ticker, " ===\n"))
    
    # restart the Docker container
    cat("Restarting Docker container...\n")
    system(paste0("docker restart ", container_name))
    
    # wait for container to be ready
    cat("Waiting for container to restart...\n")
    Sys.sleep(10)
    
    # process this ticker
    transcript_df <- try(process_single_ticker(ticker))
    
    if (!inherits(transcript_df, "try-error") && !is.null(transcript_df)) {
      if (identical(transcript_df, "NO_TRANSCRIPT_AVAILABLE")) {
        # no transcript message
        cat(paste0("Skipping ticker: ", ticker, " (no transcript available on MarketBeat)\n"))
      } else {
        all_transcripts[[ticker]] <- transcript_df
        cat(paste0("Successfully processed ticker: ", ticker, " (transcript extracted and stored)\n"))
        processed_count <- processed_count + 1
        
        # save results every 5 tickers
        if (processed_count %% 5 == 0) {
          # create a temporary combined dataframe
          temp_transcripts <- do.call(rbind, all_transcripts)
          
          # update the global dataframe
          assign("current_transcripts_df", temp_transcripts, envir = .GlobalEnv)
          
          cat(paste0("Updated global dataframe with ", processed_count, " transcripts\n"))
          cat(paste0("Access results anytime with 'current_transcripts_df'\n"))
        }
      }
    } else {
      cat(paste0("Error processing ticker: ", ticker, " (technical issue)\n"))
    }
  }
  
  # combine all transcripts into one data frame
  if (length(all_transcripts) > 0) {
    combined_transcripts <- do.call(rbind, all_transcripts)
    
    # final update to the global dataframe
    assign("current_transcripts_df", combined_transcripts, envir = .GlobalEnv)
    
    write.csv(combined_transcripts, "all_transcripts.csv", row.names = FALSE)
    cat(paste0("\nExtracted ", length(all_transcripts), " transcripts out of ", length(tickers), " tickers.\n"))
    cat("Some tickers don't have transcripts available on MarketBeat - this is normal.\n")
    cat("All transcripts combined and saved to all_transcripts.csv\n")
    cat("Final results also available in the 'current_transcripts_df' variable\n")
    
    return(combined_transcripts)
  } else {
    cat("\nNo transcripts were extracted. This is unusual and may indicate a problem.\n")
    return(NULL)
  }
}

# function to process a single ticker 
process_single_ticker <- function(ticker) {
  
  
  # 1) initialize a new session
  remDr <- remoteDriver(
    remoteServerAddr = "localhost",
    port = 4449L,
    browserName = "firefox"
  )
  
  # 2) open the session
  remDr$open()
  Sys.sleep(3)
  
  # 3) navigate to the transcripts page
  remDr$navigate("https://www.marketbeat.com/earnings/transcripts/")
  Sys.sleep(5)
  
  # 4) close the consent popup if it appears
  tryCatch({
    consent_button <- remDr$findElement(
      using = "xpath",
      value = "//button[contains(., 'Consent')]"
    )
    consent_button$clickElement()
    cat("Consent popup closed.\n")
  }, error = function(e) {
    cat("No consent popup or couldn't close it.\n")
  })
  
  # 5) enter ticker into the Company Name box and press enter
  input_field <- remDr$findElement(using = "id", value = "cphPrimaryContent_txtCompany")
  input_field$sendKeysToElement(list(ticker, key = "enter"))
  cat(paste0("Typed ", ticker, " and pressed Enter.\n"))
  
  # 6) wait for the results to load
  Sys.sleep(4) 
  
  # 7) check if transcript links exist, then click the FIRST one if available
  tryCatch({
    # check if any transcript links exist on the page
    page_source <- remDr$getPageSource()[[1]]
    
    if (!grepl("Read Transcript", page_source)) {
      cat("No transcripts available for ticker", ticker, "- this is normal for some tickers\n")
      # return a special marker to indicate "no transcript available" rather than an error
      return("NO_TRANSCRIPT_AVAILABLE")
    }
    
    # if we get here, transcript links exist, so proceed
    read_transcript_link <- remDr$findElement(
      using = "xpath",
      value = "(//a[contains(text(), 'Read Transcript')])[1]"
    )
    read_transcript_link$clickElement()
    cat("Clicked the first 'Read Transcript' link.\n")
    Sys.sleep(4)
  }, error = function(e) {
    cat("No transcripts available for ticker", ticker, "- this is normal for some tickers\n")
    # return special marker to indicate "no transcript available" 
    return("NO_TRANSCRIPT_AVAILABLE")
  })
  
  # 8) move mouse to coordinates and click to close ads, robust against different ad types
  webElem <- remDr$findElement("css selector", "body")
  remDr$mouseMoveToLocation(x = 1135, y = 208)
  remDr$click()
  cat("Ad closing action performed.\n")
  Sys.sleep(3)
  
  # 9) extract the transcript
  transcript_df <- extract_transcript(remDr, ticker)
  cat("Transcript extracted successfully.\n")
  
  return(transcript_df)
}

# extract_transcript function
extract_transcript <- function(remDr, ticker) {
  # use ticker as company name
  company_name <- ticker
  
  # get date from the specific div
  date_text <- remDr$findElement("css selector", "div.d-block.c-gray-8.font-smaller")$getElementText()
  
  # convert to proper date object using lubridate
  transcript_date <- mdy(date_text)
  
  # get the HTML source of the page
  page_source <- remDr$getPageSource()[[1]]
  
  # parse the HTML
  html <- read_html(page_source)
  
  # extract the transcript text from the specific div with ID "transcriptPresentation"
  transcript_text <- html %>%
    html_node("#transcriptPresentation") %>%
    html_text()
  
  # clean up the text (remove extra whitespace)
  transcript_text <- gsub("\\s+", " ", transcript_text)
  transcript_text <- trimws(transcript_text)
  
  # create data frame with properly named columns
  result_df <- data.frame(
    company = company_name,
    stringsAsFactors = FALSE
  )
   
  # add the date column with a proper name
  result_df$transcript_date <- transcript_date
  
  # add the transcript text
  result_df$transcript_text <- transcript_text
  
  return(result_df)
}

# define list of tickers
sp500 <- tq_index("SP500")
tickers <- sp500$symbol

# run the scraper with the correct container name
transcripts <- scrape_transcripts_with_restart(tickers, container_name = "selenium_firefox")