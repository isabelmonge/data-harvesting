# S&P 500 Performance and Sentiment Dashboard
# Load required libraries
library(shiny)
library(shinydashboard)
library(shinythemes)
library(DT)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tidytext)
library(textdata)
library(wordcloud)
library(plotly)
library(quantmod)
library(factoextra)
library(reshape2)
library(lubridate)
library(scales)
library(shinycssloaders)
library(shinyWidgets)
library(RColorBrewer)
library(stringr)

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "S&P 500 Performance & Sentiment", 
                  titleWidth = 350),
  
  dashboardSidebar(
    width = 350,
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Company Profiles", tabName = "profiles", icon = icon("building")),
      menuItem("Sector Analysis", tabName = "sectors", icon = icon("chart-pie")),
      menuItem("Momentum Index", tabName = "momentum", icon = icon("chart-line")),
      menuItem("Sentiment Analysis", tabName = "sentiment", icon = icon("comment")),
      menuItem("PCA Analysis", tabName = "pca", icon = icon("project-diagram"))
    ),
    
    # Global filters
    selectizeInput("companyFilter", "Search Companies:", 
                   choices = NULL, 
                   multiple = TRUE,
                   options = list(
                     placeholder = 'Type to search...',
                     onInitialize = I('function() { this.setValue(""); }')
                   )),
    
    selectInput("sectorFilter", "Filter by Sector:",
                choices = c("All Sectors" = ""), 
                multiple = FALSE),
    
    dateRangeInput("dateRange", "Date Range:",
                   start = Sys.Date() - 365,
                   end = Sys.Date()),
    
    # Changed refresh button to have a different color than the sidebar background
    div(style = "padding: 0 15px 20px 15px;",
        actionButton("refreshData", "Refresh Data", 
                     icon = icon("sync"),
                     class = "btn-warning btn-block"))
  ),
  
  dashboardBody(
    # Add the disclaimer modal that shows at startup
    tags$script(HTML('
      $(document).ready(function() {
        $("#disclaimerModal").modal("show");
        
        $("#acceptDisclaimer").on("click", function() {
          if($("#disclaimerCheckbox").prop("checked")) {
            $("#disclaimerModal").modal("hide");
          } else {
            alert("Please check the box to acknowledge the disclaimer");
          }
        });
      });
    ')),
    
    # Disclaimer modal with email contact added
    tags$div(id = "disclaimerModal", class = "modal fade", tabindex = "-1", role = "dialog", 
             tags$div(class = "modal-dialog modal-lg", role = "document",
                      tags$div(class = "modal-content",
                               tags$div(class = "modal-header", style = "background-color: #2c3e50; color: white;",
                                        tags$h4(class = "modal-title", "Important Disclaimer")
                               ),
                               tags$div(class = "modal-body", style = "font-size: 16px;",
                                        tags$p("This dashboard is part of an academic project and is provided for educational and informational purposes only."),
                                        tags$p(style = "font-weight: bold;", "This is not financial advice. Past performance does not guarantee future results."),
                                        tags$p("The data displayed in this dashboard may not be accurate, complete, or up-to-date. Any investment decisions should be made based on your own research and consultation with a qualified financial advisor."),
                                        tags$p("By using this dashboard, you acknowledge that you understand these limitations and risks."),
                                        tags$hr(),
                                        tags$p("If you have any questions, please reach out to Rstockmarketdashboard@gmail.com"),
                                        tags$div(class = "checkbox",
                                                 tags$label(
                                                   tags$input(id = "disclaimerCheckbox", type = "checkbox"), 
                                                   "I understand and accept these terms"
                                                 )
                                        )
                               ),
                               tags$div(class = "modal-footer",
                                        tags$button(id = "acceptDisclaimer", type = "button", class = "btn btn-primary", "Continue to Dashboard")
                               )
                      )
             )
    ),
    
    tags$head(
      tags$style(HTML("
        /* Base styling */
        .content-wrapper {
          background-color: #f8f9fa;
        }
        
        /* Box styling */
        .box {
          border-top: 3px solid #2c3e50;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
        }
        
        /* Box header colors */
        .box.box-primary > .box-header {
          background-color: #2c3e50;
          color: white;
        }
        
        .box.box-info > .box-header {
          background-color: #3498db;
          color: white;
        }
        
        .box.box-success > .box-header {
          background-color: #4575b4;
          color: white;
        }
        
        .box.box-warning > .box-header {
          background-color: #5e85b8;
          color: white;
        }
        
        .box.box-danger > .box-header {
          background-color: #92c5de;
          color: white;
        }
        
        /* Value boxes */
        .small-box {
          border-radius: 3px;
        }
        
        .small-box h3 {
          font-size: 28px;
        }
        
        .bg-blue {
          background-color: #2c3e50 !important;
        }
        
        .bg-green {
          background-color: #4575b4 !important;
        }
        
        .bg-yellow {
          background-color: #5e85b8 !important;
        }
        
        .bg-red {
          background-color: #92c5de !important;
        }
        
        /* Sidebar styling */
        .skin-blue .main-sidebar {
          background-color: #2c3e50;
        }
        
        .skin-blue .sidebar-menu > li.active > a {
          background-color: #1a252f;
          border-left-color: #3498db;
        }
        
        /* Button styling */
        .btn-primary {
          background-color: #2c3e50;
          border-color: #2c3e50;
        }
        
        .btn-primary:hover, .btn-primary:focus {
          background-color: #1a252f;
          border-color: #1a252f;
        }
        
        /* Make sure the refresh button is clearly visible */
        .btn-warning {
          background-color: #f39c12;
          border-color: #e08e0b;
          color: #ffffff;
        }
        
        .btn-warning:hover, .btn-warning:focus {
          background-color: #e08e0b;
          border-color: #d35400;
        }
      "))
    ),
    
    tabItems(
      # Dashboard Tab
      tabItem(tabName = "dashboard",
              fluidRow(
                # Changed first value box to show average P/B ratio instead of company count
                valueBoxOutput("avgPB", width = 3),
                valueBoxOutput("avgPE", width = 3),
                # Fixed percentage display for these metrics (multiply by 100)
                valueBoxOutput("avgGrowth", width = 3),
                valueBoxOutput("avgDividend", width = 3)
              ),
              
              fluidRow(
                box(
                  # Changed Market Overview to show P/E Ratio vs Revenue Growth
                  title = "Market Overview: P/E Ratio vs Revenue Growth", 
                  solidHeader = TRUE, status = "primary", width = 8,
                  plotlyOutput("marketOverview") %>% withSpinner()
                ),
                box(
                  # Changed box color to blue
                  title = "Top Performers", solidHeader = TRUE, status = "primary", width = 4,
                  plotlyOutput("topPerformers") %>% withSpinner()
                )
              ),
              
              fluidRow(
                box(
                  # Changed box color to match blue theme
                  title = "Key Metrics Distribution", solidHeader = TRUE, status = "primary", width = 6,
                  selectInput("metricSelector", "Select Metric:", 
                              choices = c("PE Ratio" = "PE_Ratio",
                                          "Revenue Growth" = "Revenue_Growth_YOY",
                                          "EPS Growth" = "EPS_Growth_YOY",
                                          "Dividend Yield" = "Dividend_Yield")),
                  plotlyOutput("metricDistribution") %>% withSpinner()
                ),
                box(
                  # Changed box color to match blue theme
                  title = "Sector Comparison", solidHeader = TRUE, status = "primary", width = 6,
                  selectInput("sectorMetric", "Select Metric:", 
                              choices = c("PE Ratio" = "PE_Ratio",
                                          "Revenue Growth" = "Revenue_Growth_YOY",
                                          "EPS Growth" = "EPS_Growth_YOY",
                                          "Dividend Yield" = "Dividend_Yield")),
                  plotlyOutput("sectorComparison") %>% withSpinner()
                )
              )
      ),
      
      # Company Profiles Tab
      tabItem(tabName = "profiles",
              fluidRow(
                box(
                  title = "Company Selector", solidHeader = TRUE, status = "primary", width = 12,
                  selectizeInput("companySelector", "Select Company:", choices = NULL)
                )
              ),
              
              fluidRow(
                box(
                  title = "Company Overview", solidHeader = TRUE, status = "primary", width = 6,
                  uiOutput("companyOverview")
                ),
                box(
                  title = "Key Financial Metrics", solidHeader = TRUE, status = "primary", width = 6,
                  plotlyOutput("companyMetrics") %>% withSpinner()
                )
              ),
              
              fluidRow(
                tabBox(
                  title = "Detailed Analysis", width = 12,
                  tabPanel("Financials", 
                           DTOutput("companyFinancials") %>% withSpinner()),
                  tabPanel("Recent Transcripts", 
                           uiOutput("transcriptPanel"))
                )
              )
      ),
      
      # Sector Analysis Tab
      tabItem(tabName = "sectors",
              fluidRow(
                box(
                  title = "Sector Performance", solidHeader = TRUE, status = "primary", width = 12,
                  plotlyOutput("sectorPerformance") %>% withSpinner()
                )
              ),
              
              fluidRow(
                box(
                  title = "Metrics by Sector", solidHeader = TRUE, status = "primary", width = 6,
                  selectInput("sectorDetailMetric", "Select Metric:", 
                              choices = c("PE Ratio" = "PE_Ratio",
                                          "Revenue Growth" = "Revenue_Growth_YOY",
                                          "EPS Growth" = "EPS_Growth_YOY",
                                          "Dividend Yield" = "Dividend_Yield")),
                  plotlyOutput("sectorDetailMetrics") %>% withSpinner()
                ),
                box(
                  title = "Companies in Selected Sector", solidHeader = TRUE, status = "primary", width = 6,
                  selectInput("sectorCompare", "Select Sector:", choices = NULL),
                  DTOutput("sectorCompanies") %>% withSpinner()
                )
              )
      ),
      
      # Momentum Index Tab
      tabItem(tabName = "momentum",
              fluidRow(
                box(
                  title = "Momentum Index", solidHeader = TRUE, status = "primary", width = 12,
                  selectInput("momentumPeriod", "Momentum Period:", 
                              choices = c("1 Month" = 30,
                                          "3 Months" = 90,
                                          "6 Months" = 180,
                                          "1 Year" = 365)),
                  plotlyOutput("momentumIndex") %>% withSpinner()
                )
              ),
              
              fluidRow(
                box(
                  title = "Top 10 Momentum Stocks", solidHeader = TRUE, status = "primary", width = 6,
                  plotlyOutput("topMomentum") %>% withSpinner()
                ),
                box(
                  title = "Bottom 10 Momentum Stocks", solidHeader = TRUE, status = "primary", width = 6,
                  plotlyOutput("bottomMomentum") %>% withSpinner()
                )
              ),
      ),
      
      # Sentiment Analysis Tab
      tabItem(tabName = "sentiment",
              fluidRow(
                box(
                  title = "Sentiment Analysis Controls", solidHeader = TRUE, status = "primary", width = 12,
                  column(6,
                         selectizeInput("sentimentCompany", "Select Company:", choices = NULL)
                  ),
                  column(6,
                         selectInput("sentimentType", "Sentiment Lexicon:", 
                                     choices = c("AFINN" = "afinn", 
                                                 "NRC" = "nrc", 
                                                 "Bing" = "bing"))
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Transcript Summary", solidHeader = TRUE, status = "primary", width = 8,
                  uiOutput("transcriptSummary") %>% withSpinner()
                ),
                box(
                  title = "Sentiment Word Cloud", solidHeader = TRUE, status = "primary", width = 4,
                  plotOutput("sentimentCloud") %>% withSpinner()
                )
              ),
              
              fluidRow(
                box(
                  title = "Most Common Terms", solidHeader = TRUE, status = "primary", width = 6,
                  plotlyOutput("commonTerms") %>% withSpinner()
                ),
                box(
                  title = "Sentiment Stats", solidHeader = TRUE, status = "primary", width = 6,
                  verbatimTextOutput("sentimentStats") %>% withSpinner()
                )
              )
      ),
      
      # PCA Analysis Tab
      tabItem(tabName = "pca",
              fluidRow(
                box(
                  title = "PCA Configuration", solidHeader = TRUE, status = "primary", width = 12,
                  column(4,
                         selectInput("pcaMetrics", "Select Metrics for PCA:", 
                                     choices = c("PE_Ratio", "Revenue_Growth_YOY", "EPS_Growth_YOY", 
                                                 "Dividend_Yield", "Price_to_Book", "Profit_Margin"),
                                     multiple = TRUE,
                                     selected = c("PE_Ratio", "Revenue_Growth_YOY", "Profit_Margin"))
                  ),
                  column(4,
                         numericInput("pcaComponents", "Number of Components:", 
                                      value = 2, min = 2, max = 5)
                  ),
                  column(4,
                         checkboxInput("pcaGroupBySector", "Group by Sector", value = TRUE)
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "PCA Visualization", solidHeader = TRUE, status = "primary", width = 8,
                  plotlyOutput("pcaPlot") %>% withSpinner()
                ),
                box(
                  title = "Variable Contributions", solidHeader = TRUE, status = "primary", width = 4,
                  plotOutput("pcaContributions") %>% withSpinner()
                )
              ),
              
              fluidRow(
                box(
                  title = "Component Explanations", solidHeader = TRUE, status = "primary", width = 12,
                  verbatimTextOutput("pcaExplanation")
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store processed data
  rv <- reactiveValues(
    fundamentals = NULL,
    transcripts = NULL,
    price_data = NULL,
    momentum_data = NULL,
    pca_results = NULL
  )
  
  # Add lexicon initialization with robust error handling and fallbacks
  tryCatch({
    # Try to get lexicons with explicit acceptance
    suppressWarnings({
      # Create a simple custom lexicon if downloads fail
      afinn_lexicon <- data.frame(
        word = c("good", "great", "excellent", "amazing", "fantastic", "wonderful", "best", "happy", "positive", "profit", 
                 "growth", "increase", "up", "higher", "improve", "success", "successful", "growing", "gain", "better",
                 "bad", "terrible", "awful", "poor", "negative", "worst", "unhappy", "loss", "decrease", "down", 
                 "lower", "fail", "failing", "failed", "worse", "decline", "risk", "problem", "difficult", "challenge"),
        value = c(3, 4, 5, 5, 5, 4, 5, 3, 3, 3, 
                  3, 3, 2, 2, 3, 4, 4, 3, 3, 3,
                  -3, -4, -4, -3, -3, -5, -3, -3, -3, -2, 
                  -2, -3, -3, -3, -3, -3, -2, -2, -2, -2)
      )
      
      # First try to use the real lexicons
      tryCatch({
        textdata::lexicon_afinn()
        textdata::lexicon_bing() 
        textdata::lexicon_nrc()
      }, error = function(e) {
        # If error occurs, we'll use our custom lexicon through this modified get_sentiments function
        assign("get_sentiments", function(lexicon_name) {
          if(lexicon_name == "afinn") {
            return(afinn_lexicon)
          } else if(lexicon_name == "bing") {
            # Create simplified bing lexicon from afinn values
            bing_lexicon <- data.frame(
              word = afinn_lexicon$word,
              sentiment = ifelse(afinn_lexicon$value > 0, "positive", "negative")
            )
            return(bing_lexicon)
          } else if(lexicon_name == "nrc") {
            # Create simplified nrc lexicon from afinn values
            emotions <- c("anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise", "trust")
            words <- character()
            sentiment <- character()
            
            for(w in afinn_lexicon$word) {
              val <- afinn_lexicon$value[afinn_lexicon$word == w]
              # Assign basic emotions based on positive/negative value
              if(val > 0) {
                words <- c(words, rep(w, 3))
                sentiment <- c(sentiment, "positive", "joy", "trust")
              } else {
                words <- c(words, rep(w, 3))
                sentiment <- c(sentiment, "negative", "anger", "sadness")
              }
            }
            
            nrc_lexicon <- data.frame(word = words, sentiment = sentiment)
            return(nrc_lexicon)
          }
        }, envir = .GlobalEnv)
      })
    })
  }, error = function(e) {
    warning("Error in sentiment initialization: ", e$message)
  })
  
  # Function to load and process data
  loadData <- function() {
    # Load fundamentals data with full path
    fundamentals <- read.csv("data/sp500_fundamentals_combined_app.csv", stringsAsFactors = FALSE)
    
    # Load transcript data with full path
    transcripts <- read.csv("data/transcripts_app.csv", stringsAsFactors = FALSE)
    
    # Process dates if needed
    if ("transcript_date" %in% colnames(transcripts)) {
      transcripts$transcript_date <- as.Date(transcripts$transcript_date)
    }
    
    # Store in reactive values
    rv$fundamentals <- fundamentals
    rv$transcripts <- transcripts
    
    # Update UI selectors
    updateSelectizeInput(session, "companyFilter", 
                         choices = c("All Companies" = "", sort(unique(fundamentals$Name))),
                         server = TRUE)
    
    updateSelectizeInput(session, "companySelector", 
                         choices = sort(unique(fundamentals$Name)),
                         server = TRUE)
    
    updateSelectizeInput(session, "sentimentCompany", 
                         choices = sort(unique(transcripts$company)),
                         server = TRUE)
    
    sectors <- sort(unique(fundamentals$Sector))
    updateSelectInput(session, "sectorFilter", 
                      choices = c("All Sectors" = "", sectors))
    
    updateSelectInput(session, "sectorCompare", 
                      choices = sectors)
  }
  
  # Load data on app initialization and when refresh button is clicked
  observe({
    loadData()
  })
  
  observeEvent(input$refreshData, {
    loadData()
  })
  
  # Filter data based on user selections
  filteredFundamentals <- reactive({
    req(rv$fundamentals)
    
    data <- rv$fundamentals
    
    # Filter by company if selected
    if (!is.null(input$companyFilter) && input$companyFilter != "") {
      data <- data %>% filter(Name %in% input$companyFilter)
    }
    
    # Filter by sector if selected
    if (!is.null(input$sectorFilter) && input$sectorFilter != "") {
      data <- data %>% filter(Sector == input$sectorFilter)
    }
    
    return(data)
  })
  
  filteredTranscripts <- reactive({
    req(rv$transcripts)
    data <- rv$transcripts
    
    # Filter by company if selected
    if (!is.null(input$companyFilter) && input$companyFilter != "") {
      data <- data %>% filter(company %in% input$companyFilter)
    }
    
    # Filter by date range
    if (!is.null(input$dateRange)) {
      data <- data %>% filter(transcript_date >= input$dateRange[1] & 
                                transcript_date <= input$dateRange[2])
    }
    
    return(data)
  })
  
  # Dashboard tab outputs
  # Changed to show Average P/B Ratio instead of company count
  output$avgPB <- renderValueBox({
    req(filteredFundamentals())
    avg_pb <- mean(filteredFundamentals()$Price_to_Book, na.rm = TRUE)
    valueBox(
      round(avg_pb, 2), "Avg. P/B Ratio",
      icon = icon("book"),
      color = "blue"
    )
  })
  
  output$avgPE <- renderValueBox({
    req(filteredFundamentals())
    avg_pe <- mean(filteredFundamentals()$PE_Ratio, na.rm = TRUE)
    valueBox(
      round(avg_pe, 2), "Avg. P/E Ratio",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  # Fixed percentage display (multiply by 100)
  output$avgGrowth <- renderValueBox({
    req(filteredFundamentals())
    avg_growth <- mean(filteredFundamentals()$Revenue_Growth_YOY, na.rm = TRUE) * 100
    valueBox(
      paste0(round(avg_growth, 2), "%"), "Avg. Revenue Growth",
      icon = icon("percentage"),
      color = "yellow"
    )
  })
  
  # Fixed percentage display (multiply by 100)
  output$avgDividend <- renderValueBox({
    req(filteredFundamentals())
    avg_dividend <- mean(filteredFundamentals()$Dividend_Yield, na.rm = TRUE) * 100
    valueBox(
      paste0(round(avg_dividend, 2), "%"), "Avg. Dividend Yield",
      icon = icon("dollar-sign"),
      color = "red"
    )
  })
  
  # Changed Market Overview Plot to show P/E Ratio vs Revenue Growth for better visualization
  output$marketOverview <- renderPlotly({
    req(filteredFundamentals())
    
    # Create a scatter plot of PE Ratio vs Revenue Growth
    p <- filteredFundamentals() %>%
      ggplot(aes(x = PE_Ratio, y = Revenue_Growth_YOY * 100, 
                 color = Sector, size = Market_Cap, 
                 text = paste("Company:", Name, 
                              "<br>P/E Ratio:", round(PE_Ratio, 2),
                              "<br>Revenue Growth:", round(Revenue_Growth_YOY * 100, 2), "%",
                              "<br>Market Cap:", scales::dollar(Market_Cap)))) +
      geom_point(alpha = 0.7) +
      scale_size(range = c(3, 15), guide = "none") +
      scale_color_brewer(palette = "Blues", direction = -1) +
      labs(x = "P/E Ratio", y = "Revenue Growth (%)") +
      theme_minimal() +
      theme(legend.position = "bottom")
    
    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", y = -0.2))
  })
  
  # Top Performers Plot - changed to use blue color palette
  output$topPerformers <- renderPlotly({
    req(filteredFundamentals())
    
    # Get top 10 companies by EPS growth
    top_performers <- filteredFundamentals() %>%
      arrange(desc(EPS_Growth_YOY)) %>%
      head(10)
    
    p <- top_performers %>%
      ggplot(aes(x = reorder(Name, EPS_Growth_YOY), y = EPS_Growth_YOY * 100, 
                 fill = EPS_Growth_YOY,
                 text = paste("Company:", Name, 
                              "<br>EPS Growth:", round(EPS_Growth_YOY * 100, 2), "%",
                              "<br>Sector:", Sector))) +
      geom_bar(stat = "identity") +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +
      coord_flip() +
      labs(x = "", y = "EPS Growth (%)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p, tooltip = "text")
  })
  
  # Metric Distribution Plot
  output$metricDistribution <- renderPlotly({
    req(filteredFundamentals(), input$metricSelector)
    
    # Create histogram of selected metric
    metric_col <- sym(input$metricSelector)
    
    # Get nice label for the metric and multiply percentage values by 100
    metric_labels <- c(
      "PE_Ratio" = "P/E Ratio",
      "Revenue_Growth_YOY" = "Revenue Growth (%)",
      "EPS_Growth_YOY" = "EPS Growth (%)",
      "Dividend_Yield" = "Dividend Yield (%)"
    )
    
    # Adjust values for percentage metrics
    plot_data <- filteredFundamentals()
    if(input$metricSelector %in% c("Revenue_Growth_YOY", "EPS_Growth_YOY", "Dividend_Yield")) {
      plot_data <- plot_data %>%
        mutate(!!input$metricSelector := !!metric_col * 100)
    }
    
    p <- plot_data %>%
      ggplot(aes(x = !!metric_col)) +
      geom_histogram(aes(fill = ..count..), bins = 30) +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +
      labs(x = metric_labels[input$metricSelector], y = "Count") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Sector Comparison Plot
  output$sectorComparison <- renderPlotly({
    req(filteredFundamentals(), input$sectorMetric)
    
    # Create boxplot by sector
    metric_col <- sym(input$sectorMetric)
    
    # Get nice label for the metric
    metric_labels <- c(
      "PE_Ratio" = "P/E Ratio",
      "Revenue_Growth_YOY" = "Revenue Growth (%)",
      "EPS_Growth_YOY" = "EPS Growth (%)",
      "Dividend_Yield" = "Dividend Yield (%)"
    )
    
    # Adjust values for percentage metrics
    plot_data <- filteredFundamentals()
    if(input$sectorMetric %in% c("Revenue_Growth_YOY", "EPS_Growth_YOY", "Dividend_Yield")) {
      plot_data <- plot_data %>%
        mutate(!!input$sectorMetric := !!metric_col * 100)
    }
    
    p <- plot_data %>%
      ggplot(aes(x = Sector, y = !!metric_col, fill = Sector)) +
      geom_boxplot() +
      scale_fill_brewer(palette = "Blues") +
      coord_flip() +
      labs(y = metric_labels[input$sectorMetric], x = "") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # Company Profile outputs
  output$companyOverview <- renderUI({
    req(input$companySelector, rv$fundamentals)
    
    company_data <- rv$fundamentals %>%
      filter(Name == input$companySelector) %>%
      head(1)
    
    if(nrow(company_data) == 0) {
      return(h4("No data available for selected company"))
    }
    
    # Multiply percentage values by 100 for display
    HTML(paste0(
      "<h3>", company_data$Name, " (", company_data$Symbol, ")</h3>",
      "<p><strong>Sector:</strong> ", company_data$Sector, "</p>",
      "<p><strong>Industry:</strong> ", company_data$Industry, "</p>",
      "<p><strong>Market Cap:</strong> ", scales::dollar(company_data$Market_Cap), "</p>",
      "<div class='row'>",
      "<div class='col-md-6'>",
      "<p><strong>P/E Ratio:</strong> ", round(company_data$PE_Ratio, 2), "</p>",
      "<p><strong>Price to Book:</strong> ", round(company_data$Price_to_Book, 2), "</p>",
      "<p><strong>Profit Margin:</strong> ", round(company_data$Profit_Margin * 100, 2), "%</p>",
      "</div>",
      "<div class='col-md-6'>",
      "<p><strong>Revenue (TTM):</strong> ", scales::dollar(company_data$Revenue_TTM), "</p>",
      "<p><strong>EPS Growth:</strong> ", round(company_data$EPS_Growth_YOY * 100, 2), "%</p>",
      "<p><strong>Dividend Yield:</strong> ", round(company_data$Dividend_Yield * 100, 2), "%</p>",
      "</div>",
      "</div>"
    ))
  })
  
  output$companyMetrics <- renderPlotly({
    req(input$companySelector, rv$fundamentals)
    
    company_data <- rv$fundamentals %>%
      filter(Name == input$companySelector) %>%
      head(1)
    
    if(nrow(company_data) == 0) {
      return(NULL)
    }
    
    # Select key metrics for radar chart
    metrics <- c("PE_Ratio", "Revenue_Growth_YOY", "Profit_Margin", 
                 "Price_to_Book", "Dividend_Yield", "Return_on_Equity")
    
    # Get sector average for comparison
    sector_avg <- rv$fundamentals %>%
      filter(Sector == company_data$Sector) %>%
      summarise(across(all_of(metrics), mean, na.rm = TRUE))
    
    # Prepare data for radar chart
    radar_data <- rbind(
      company_data[, metrics],
      sector_avg
    )
    
    # Normalize data to 0-1 scale for radar chart
    radar_data_norm <- apply(radar_data, 2, function(x) {
      (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
    })
    
    # Melt data for plotting
    plot_data <- data.frame(
      metric = rep(c("P/E Ratio", "Revenue Growth", "Profit Margin",
                     "Price to Book", "Dividend Yield", "Return on Equity"), 2),
      value = c(as.numeric(radar_data_norm[1,]), as.numeric(radar_data_norm[2,])),
      group = rep(c("Company", "Sector Average"), each = 6)
    )
    
    # Create radar chart with blue color palette
    p <- plot_ly(
      type = 'scatterpolar',
      fill = 'toself'
    ) %>%
      add_trace(
        r = plot_data$value[plot_data$group == "Company"],
        theta = plot_data$metric[plot_data$group == "Company"],
        name = company_data$Name,
        fillcolor = 'rgba(69, 117, 180, 0.5)',  # Blue with transparency 
        line = list(color = '#2c3e50')
      ) %>%
      add_trace(
        r = plot_data$value[plot_data$group == "Sector Average"],
        theta = plot_data$metric[plot_data$group == "Sector Average"],
        name = 'Sector Average',
        fillcolor = 'rgba(146, 197, 222, 0.5)',  # Light blue with transparency
        line = list(color = '#5e85b8')
      ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible = TRUE,
            range = c(0,1)
          )
        )
      )
    
    return(p)
  })
  
  output$companyFinancials <- renderDT({
    req(input$companySelector, rv$fundamentals)
    
    company_data <- rv$fundamentals %>%
      filter(Name == input$companySelector)
    
    if(nrow(company_data) == 0) {
      return(NULL)
    }
    
    # Create a transpose of key financial metrics
    # Multiply percentage values by 100 for display
    financial_data <- data.frame(
      Metric = c("P/E Ratio", "PEG Ratio", "Price to Book", "Price to Sales",
                 "EV/EBITDA", "EV/Revenue", "Profit Margin (%)", "Operating Margin (%)",
                 "Return on Assets (%)", "Return on Equity (%)", "Revenue Growth YOY (%)",
                 "EPS Growth YOY (%)", "Current Ratio", "Debt to Equity",
                 "Interest Coverage", "Dividend Yield (%)", "Dividend Per Share",
                 "Beta"),
      Value = c(
        company_data$PE_Ratio, company_data$PEG_Ratio,
        company_data$Price_to_Book, company_data$Price_to_Sales,
        company_data$EV_to_EBITDA, company_data$EV_to_Revenue,
        company_data$Profit_Margin * 100, company_data$Operating_Margin * 100,
        company_data$Return_on_Assets * 100, company_data$Return_on_Equity * 100,
        company_data$Revenue_Growth_YOY * 100, company_data$EPS_Growth_YOY * 100,
        company_data$Current_Ratio, company_data$Debt_to_Equity,
        company_data$Interest_Coverage, company_data$Dividend_Yield * 100,
        company_data$Dividend_Per_Share, company_data$Beta
      )
    )
    
    datatable(financial_data, options = list(
      pageLength = 10,
      dom = 't',
      ordering = FALSE
    )) %>%
      formatRound('Value', digits = 2)
  })
  
  output$transcriptPanel <- renderUI({
    req(input$companySelector, rv$transcripts)
    
    # Fix matching between company selector and transcript data
    # Try exact match first, then partial match if needed
    company_name <- input$companySelector
    company_transcripts <- rv$transcripts %>%
      filter(company == company_name | 
               str_detect(tolower(company), tolower(company_name)) | 
               str_detect(tolower(company_name), tolower(company)))
    
    if(nrow(company_transcripts) == 0) {
      return(h4("No transcript data available for selected company"))
    }
    
    # Sort transcripts by date (newest first)
    sorted_transcripts <- company_transcripts %>%
      arrange(desc(transcript_date))
    
    # Display the most recent transcript
    latest <- sorted_transcripts[1,]
    
    div(
      h4(paste("Latest Transcript:", format(as.Date(latest$transcript_date), "%B %d, %Y"))),
      
      # Add a tabset panel for transcript navigation
      tabsetPanel(
        tabPanel("Summary", 
                 div(
                   style = "max-height: 400px; overflow-y: auto;",
                   # Display first 500 characters with a "Read more" button
                   p(substr(latest$transcript_text, 1, 500), "..."),
                   actionButton("readMoreBtn", "Read Full Transcript", 
                                class = "btn-primary")
                 )
        ),
        tabPanel("All Transcripts", 
                 div(
                   style = "max-height: 400px; overflow-y: auto;",
                   DTOutput("transcriptList")
                 )
        ),
        tabPanel("Key Phrases", 
                 div(
                   style = "max-height: 400px; overflow-y: auto;",
                   plotOutput("keyPhrases") %>% withSpinner()
                 )
        )
      )
    )
  })
  
  # Modal dialog for full transcript
  observeEvent(input$readMoreBtn, {
    req(input$companySelector, rv$transcripts)
    
    company_transcripts <- rv$transcripts %>%
      filter(company == input$companySelector) %>%
      arrange(desc(transcript_date))
    
    if(nrow(company_transcripts) > 0) {
      latest <- company_transcripts[1,]
      
      showModal(modalDialog(
        title = paste(latest$company, "Transcript -", format(as.Date(latest$transcript_date), "%B %d, %Y")),
        div(
          style = "max-height: 70vh; overflow-y: auto;",
          p(latest$transcript_text)
        ),
        size = "l",
        easyClose = TRUE
      ))
    }
  })
  
  # Render the table of all transcripts
  output$transcriptList <- renderDT({
    req(input$companySelector, rv$transcripts)
    
    company_transcripts <- rv$transcripts %>%
      filter(company == input$companySelector) %>%
      arrange(desc(transcript_date)) %>%
      select(transcript_date, chars = transcript_text) %>%
      mutate(
        transcript_date = as.Date(transcript_date),
        chars = nchar(chars)
      )
    
    datatable(company_transcripts, options = list(
      pageLength = 5,
      order = list(list(0, 'desc'))
    )) %>%
      formatDate('transcript_date', method = 'toLocaleDateString') %>%
      formatRound('chars', digits = 0)
  })
  
  # Sentiment Analysis tab outputs
  
  # Process transcripts for sentiment analysis
  transcript_tokens <- reactive({
    req(input$sentimentCompany, rv$transcripts)
    
    company_data <- rv$transcripts %>%
      filter(company == input$sentimentCompany)
    
    if(nrow(company_data) == 0) {
      return(NULL)
    }
    
    # Tokenize and clean transcript text
    tokens <- company_data %>%
      mutate(transcript_date = as.Date(transcript_date)) %>%
      unnest_tokens(word, transcript_text) %>%
      anti_join(stop_words, by = "word") %>%
      filter(str_detect(word, "^[a-z]+$"), # Keep only alphabetic tokens
             nchar(word) > 2) # Remove very short words
    
    return(tokens)
  })
  
  # Sentiment analysis
  sentiment_data <- reactive({
    req(transcript_tokens(), input$sentimentType)
    
    tokens <- transcript_tokens()
    
    if(input$sentimentType == "afinn") {
      sentiment <- tokens %>%
        inner_join(get_sentiments("afinn"), by = "word")
    } else if(input$sentimentType == "bing") {
      sentiment <- tokens %>%
        inner_join(get_sentiments("bing"), by = "word")
    } else if(input$sentimentType == "nrc") {
      sentiment <- tokens %>%
        inner_join(get_sentiments("nrc"), by = "word")
    }
    
    return(sentiment)
  })
  
  # Add sentiment stats function
  output$sentimentStats <- renderText({
    req(transcript_tokens(), input$sentimentType)
    
    # If no sentiment data, return message
    tokens <- transcript_tokens()
    
    if(is.null(tokens) || nrow(tokens) == 0) {
      return("No sentiment data available for selected company")
    }
    
    sentiment <- sentiment_data()
    
    if(input$sentimentType == "afinn") {
      # AFINN sentiment statistics
      stats <- sentiment %>%
        summarise(
          avg_score = mean(value, na.rm = TRUE),
          total_words = n(),
          positive_words = sum(value > 0, na.rm = TRUE),
          negative_words = sum(value < 0, na.rm = TRUE),
          neutral_words = sum(value == 0, na.rm = TRUE),
          min_score = min(value, na.rm = TRUE),
          max_score = max(value, na.rm = TRUE),
          pos_ratio = positive_words / total_words,
          neg_ratio = negative_words / total_words
        )
      
      # Create text output
      output_text <- paste0(
        "Sentiment Analysis for ", input$sentimentCompany, ":\n\n",
        "Average sentiment score: ", round(stats$avg_score, 2), "\n",
        "Total words analyzed: ", stats$total_words, "\n\n",
        "Positive words: ", stats$positive_words, " (", round(stats$pos_ratio * 100, 1), "%)\n",
        "Negative words: ", stats$negative_words, " (", round(stats$neg_ratio * 100, 1), "%)\n",
        "Neutral words: ", stats$neutral_words, "\n\n",
        "Sentiment range: ", stats$min_score, " to ", stats$max_score, "\n"
      )
      
    } else if(input$sentimentType == "bing") {
      # Bing sentiment statistics
      stats <- sentiment %>%
        count(sentiment) %>%
        mutate(ratio = n / sum(n))
      
      pos_count <- stats %>% filter(sentiment == "positive") %>% pull(n)
      pos_ratio <- stats %>% filter(sentiment == "positive") %>% pull(ratio)
      neg_count <- stats %>% filter(sentiment == "negative") %>% pull(n)
      neg_ratio <- stats %>% filter(sentiment == "negative") %>% pull(ratio)
      
      if(length(pos_count) == 0) pos_count <- 0
      if(length(pos_ratio) == 0) pos_ratio <- 0
      if(length(neg_count) == 0) neg_count <- 0
      if(length(neg_ratio) == 0) neg_ratio <- 0
      
      # Create text output
      output_text <- paste0(
        "Sentiment Analysis for ", input$sentimentCompany, ":\n\n",
        "Total words analyzed: ", nrow(sentiment), "\n\n",
        "Positive words: ", pos_count, " (", round(pos_ratio * 100, 1), "%)\n",
        "Negative words: ", neg_count, " (", round(neg_ratio * 100, 1), "%)\n",
        "Sentiment ratio: ", round((pos_count - neg_count) / (pos_count + neg_count), 3)
      )
      
    } else if(input$sentimentType == "nrc") {
      # NRC emotion statistics
      stats <- sentiment %>%
        count(sentiment) %>%
        mutate(ratio = n / sum(n))
      
      # Create text output 
      output_text <- paste0(
        "Emotion Analysis for ", input$sentimentCompany, ":\n\n",
        "Total words analyzed: ", nrow(sentiment), "\n\n",
        "Emotion Distribution:\n"
      )
      
      # Add each emotion
      for(i in 1:nrow(stats)) {
        output_text <- paste0(
          output_text,
          stats$sentiment[i], ": ", stats$n[i], " words (",
          round(stats$ratio[i] * 100, 1), "%)\n"
        )
      }
    }
    
    return(output_text)
  })
  
  # Word cloud
  output$sentimentCloud <- renderPlot({
    req(transcript_tokens(), input$sentimentType)
    
    tokens <- transcript_tokens()
    sentiment <- sentiment_data()
    
    if(input$sentimentType == "afinn") {
      # Color by positive/negative score
      sentiment$group <- ifelse(sentiment$value > 0, "positive", "negative")
      
      # Get top words by absolute sentiment
      top_words <- sentiment %>%
        group_by(word, group) %>%
        summarise(n = n(), score = mean(value)) %>%
        mutate(abs_score = abs(score)) %>%
        arrange(desc(abs_score)) %>%
        group_by(group) %>%
        top_n(50, n)
      
      # Generate word cloud with blue gradient for positive and red for negative
      wordcloud(words = top_words$word, 
                freq = top_words$n,
                scale = c(3, 0.5),
                min.freq = 1,
                colors = ifelse(top_words$group == "positive", 
                                brewer.pal(9, "Blues")[5:9],
                                brewer.pal(9, "Reds")[5:9]),
                random.order = FALSE)
      
    } else if(input$sentimentType == "bing") {
      # Get most common positive and negative words
      top_words <- sentiment %>%
        count(word, sentiment) %>%
        group_by(sentiment) %>%
        top_n(50, n)
      
      # Generate word cloud with blue for positive and red for negative
      wordcloud(words = top_words$word, 
                freq = top_words$n,
                scale = c(3, 0.5),
                min.freq = 1,
                colors = ifelse(top_words$sentiment == "positive", 
                                brewer.pal(9, "Blues")[5:9],
                                brewer.pal(9, "Reds")[5:9]),
                random.order = FALSE)
      
    } else if(input$sentimentType == "nrc") {
      # Get most common words for each emotion
      top_words <- sentiment %>%
        count(word, sentiment) %>%
        group_by(sentiment) %>%
        top_n(30, n)
      
      # For NRC, we'll use a blue palette for all emotions for consistency
      emotion_colors <- colorRampPalette(brewer.pal(9, "Blues"))(length(unique(top_words$sentiment)))
      names(emotion_colors) <- unique(top_words$sentiment)
      
      # Generate word cloud with blue palette for emotions
      wordcloud(words = top_words$word, 
                freq = top_words$n,
                scale = c(3, 0.5),
                min.freq = 1,
                colors = emotion_colors[top_words$sentiment],
                random.order = FALSE)
    }
  })
  
  # Most common terms chart
  output$commonTerms <- renderPlotly({
    req(transcript_tokens())
    
    # Get top 20 most frequent terms
    top_terms <- transcript_tokens() %>%
      count(word, sort = TRUE) %>%
      top_n(20, n)
    
    p <- top_terms %>%
      ggplot(aes(x = reorder(word, n), y = n, 
                 fill = n,
                 text = paste("Word:", word, "\nCount:", n))) +
      geom_col() +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +
      coord_flip() +
      labs(x = NULL, y = "Count") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p, tooltip = "text")
  })
  
  # Momentum Index tab functions
  
  # Function to download price data for S&P 500 stocks
  downloadPriceData <- reactive({
    req(rv$fundamentals)
    
    # If we already have price data cached, use it
    if (!is.null(rv$price_data)) {
      return(rv$price_data)
    }
    
    # Get list of symbols
    symbols <- rv$fundamentals$Symbol
    
    # Use sample of 10 symbols for testing
    # Remove this limitation in production
    # symbols <- sample(symbols, 10)
    
    # Initialize empty list to store price data
    price_data <- list()
    
    # For each symbol, try to get price data
    withProgress(message = 'Downloading price data', value = 0, {
      for (i in seq_along(symbols)) {
        symbol <- symbols[i]
        
        # Update progress
        incProgress(1/length(symbols), detail = paste("Downloading", symbol))
        
        # Try to get data
        tryCatch({
          # Get data from Yahoo Finance
          ticker_data <- getSymbols(symbol, src = "yahoo", 
                                    from = Sys.Date() - 365*2,
                                    to = Sys.Date(),
                                    auto.assign = FALSE)
          
          # Extract adjusted closing prices
          prices <- Ad(ticker_data)
          
          # Store in list
          price_data[[symbol]] <- prices
        }, error = function(e) {
          # If error, just skip this symbol
          warning(paste("Could not download data for", symbol))
        })
      }
    })
    
    # Combine all price data into a single xts object
    if (length(price_data) > 0) {
      combined_prices <- do.call(merge, price_data)
      colnames(combined_prices) <- names(price_data)
      
      # Store in reactive values
      rv$price_data <- combined_prices
      
      return(combined_prices)
    } else {
      return(NULL)
    }
  })
  
  # Calculate momentum
  calculateMomentum <- reactive({
    req(downloadPriceData())
    
    prices <- downloadPriceData()
    period <- as.numeric(input$momentumPeriod)
    
    # Calculate returns over the specified period
    returns <- (prices / lag(prices, period) - 1) * 100
    
    # Get the most recent momentum values
    recent_momentum <- tail(returns, 1)
    
    # Convert to data frame
    momentum_df <- data.frame(
      Symbol = colnames(recent_momentum),
      Momentum = as.numeric(recent_momentum),
      stringsAsFactors = FALSE
    )
    
    # Join with fundamentals to get company names
    momentum_df <- momentum_df %>%
      inner_join(rv$fundamentals %>% select(Symbol, Name, Sector), by = "Symbol") %>%
      arrange(desc(Momentum))
    
    # Store momentum data
    rv$momentum_data <- momentum_df
    
    return(momentum_df)
  })
  
  # Momentum index plot
  output$momentumIndex <- renderPlotly({
    req(calculateMomentum())
    
    momentum_df <- calculateMomentum()
    
    # Create a histogram of momentum values
    p <- ggplot(momentum_df, aes(x = Momentum)) +
      geom_histogram(aes(y = ..density.., fill = ..count..), bins = 30) +
      geom_density(alpha = 0.2, fill = "#4575b4") +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +
      labs(x = paste0(input$momentumPeriod, "-Day Momentum (%)"), y = "Density") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Top momentum stocks - kept green coloring for positive momentum
  output$topMomentum <- renderPlotly({
    req(calculateMomentum())
    
    momentum_df <- calculateMomentum()
    
    # Get top 10 momentum stocks
    top_10 <- head(momentum_df, 10)
    
    p <- ggplot(top_10, aes(x = reorder(Name, Momentum), y = Momentum, 
                            fill = Momentum,
                            text = paste("Company:", Name,
                                         "\nSymbol:", Symbol,
                                         "\nMomentum:", round(Momentum, 2), "%",
                                         "\nSector:", Sector))) +
      geom_col() +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +  # Changed to blue palette
      coord_flip() +
      labs(x = NULL, y = paste0(input$momentumPeriod, "-Day Momentum (%)")) +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p, tooltip = "text")
  })
  
  # Bottom momentum stocks - kept red coloring for negative momentum
  output$bottomMomentum <- renderPlotly({
    req(calculateMomentum())
    
    momentum_df <- calculateMomentum()
    
    # Get bottom 10 momentum stocks
    bottom_10 <- tail(momentum_df, 10)
    
    p <- ggplot(bottom_10, aes(x = reorder(Name, Momentum), y = Momentum, 
                               fill = Momentum,
                               text = paste("Company:", Name,
                                            "\nSymbol:", Symbol,
                                            "\nMomentum:", round(Momentum, 2), "%",
                                            "\nSector:", Sector))) +
      geom_col() +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +  # Changed to blue palette
      coord_flip() +
      labs(x = NULL, y = paste0(input$momentumPeriod, "-Day Momentum (%)")) +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p, tooltip = "text")
  })
  
  # Simulate long/short performance
  output$longShortPerformance <- renderPlotly({
    req(downloadPriceData(), calculateMomentum())
    
    prices <- downloadPriceData()
    momentum_df <- calculateMomentum()
    
    # Get top and bottom 10% of stocks by momentum
    n_stocks <- floor(nrow(momentum_df) * 0.1)
    top_stocks <- head(momentum_df$Symbol, n_stocks)
    bottom_stocks <- tail(momentum_df$Symbol, n_stocks)
    
    # Extract prices for these stocks
    top_prices <- prices[, top_stocks]
    bottom_prices <- prices[, bottom_stocks]
    
    # Calculate equally weighted portfolio returns
    top_returns <- rowMeans(ROC(top_prices, n = 1, type = "discrete"), na.rm = TRUE)
    bottom_returns <- rowMeans(ROC(bottom_prices, n = 1, type = "discrete"), na.rm = TRUE)
    
    # Calculate long/short strategy returns
    long_short_returns <- top_returns - bottom_returns
    
    # Calculate cumulative returns
    cum_top <- cumprod(1 + top_returns)
    cum_bottom <- cumprod(1 + bottom_returns)
    cum_long_short <- cumprod(1 + long_short_returns)
    
    # Extract last year of data
    last_year <- tail(merge(cum_top, cum_bottom, cum_long_short), 252)
    colnames(last_year) <- c("Long", "Short", "Long-Short")
    
    # Convert to data frame for plotting
    plot_data <- fortify(last_year, melt = TRUE)
    colnames(plot_data) <- c("Date", "Series", "Return")
    
    # Create plot with consistent blue color scheme
    p <- ggplot(plot_data, aes(x = Date, y = Return, color = Series)) +
      geom_line(size = 1) +
      scale_color_manual(values = c("Long" = "#4575b4", "Short" = "#92c5de", "Long-Short" = "#2c3e50")) +
      labs(x = NULL, y = "Cumulative Return", color = "Strategy") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # PCA Analysis tab functions
  
  # Perform PCA analysis
  performPCA <- reactive({
    req(rv$fundamentals, input$pcaMetrics, input$pcaComponents)
    
    # Select metrics for PCA
    pca_data <- rv$fundamentals %>%
      select(all_of(input$pcaMetrics), Sector, Name, Symbol) %>%
      na.omit()
    
    # Adjust percentage values for PCA
    for(metric in input$pcaMetrics) {
      if(metric %in% c("Revenue_Growth_YOY", "EPS_Growth_YOY", "Dividend_Yield", "Profit_Margin")) {
        pca_data[[metric]] <- pca_data[[metric]] * 100
      }
    }
    
    # Extract numeric data for PCA
    numeric_data <- pca_data %>%
      select(all_of(input$pcaMetrics))
    
    # Perform PCA
    pca_result <- prcomp(numeric_data, scale. = TRUE)
    
    # Get PC scores
    pca_scores <- as.data.frame(pca_result$x)
    
    # Add metadata
    pca_scores$Sector <- pca_data$Sector
    pca_scores$Name <- pca_data$Name
    pca_scores$Symbol <- pca_data$Symbol
    
    # Store PCA results
    rv$pca_results <- list(
      pca = pca_result,
      scores = pca_scores,
      original_data = pca_data
    )
    
    return(rv$pca_results)
  })
  
  # PCA plot
  output$pcaPlot <- renderPlotly({
    req(performPCA())
    
    pca_results <- performPCA()
    pca_scores <- pca_results$scores
    
    # Create scatter plot of first two principal components
    if(input$pcaGroupBySector) {
      # Get a consistent set of colors for sectors
      sector_colors <- colorRampPalette(brewer.pal(9, "Blues"))(length(unique(pca_scores$Sector)))
      names(sector_colors) <- unique(pca_scores$Sector)
      
      # Color by sector
      p <- ggplot(pca_scores, aes(x = PC1, y = PC2, color = Sector,
                                  text = paste("Company:", Name,
                                               "\nSymbol:", Symbol,
                                               "\nSector:", Sector,
                                               "\nPC1:", round(PC1, 2),
                                               "\nPC2:", round(PC2, 2)))) +
        geom_point(alpha = 0.7, size = 3) +
        scale_color_manual(values = sector_colors) +
        labs(x = "Principal Component 1", y = "Principal Component 2") +
        theme_minimal()
    } else {
      # No grouping
      p <- ggplot(pca_scores, aes(x = PC1, y = PC2,
                                  text = paste("Company:", Name,
                                               "\nSymbol:", Symbol,
                                               "\nSector:", Sector,
                                               "\nPC1:", round(PC1, 2),
                                               "\nPC2:", round(PC2, 2)))) +
        geom_point(alpha = 0.7, size = 3, color = "#4575b4") +
        labs(x = "Principal Component 1", y = "Principal Component 2") +
        theme_minimal()
    }
    
    ggplotly(p, tooltip = "text")
  })
  
  # Variable contributions plot
  output$pcaContributions <- renderPlot({
    req(performPCA())
    
    pca_results <- performPCA()
    
    # Plot variable contributions with our blue palette
    fviz_pca_var(pca_results$pca,
                 col.var = "contrib",
                 gradient.cols = c("#92c5de", "#4575b4", "#2c3e50"),
                 repel = TRUE)
  })
  
  # Component explanations
  output$pcaExplanation <- renderText({
    req(performPCA())
    
    pca_results <- performPCA()
    pca <- pca_results$pca
    
    # Get summary of PCA
    pca_summary <- summary(pca)
    
    # Format explanation text
    explanation <- paste0(
      "PCA Summary:\n\n",
      "Standard deviations:\n",
      paste(colnames(pca$x), ":", round(pca$sdev, 4), collapse = "\n"),
      "\n\n",
      "Proportion of Variance Explained:\n",
      paste(colnames(pca$x), ":", round(pca_summary$importance[2,], 4), collapse = "\n"),
      "\n\n",
      "Cumulative Proportion:\n",
      paste(colnames(pca$x), ":", round(pca_summary$importance[3,], 4), collapse = "\n"),
      "\n\n",
      "Variable Loadings (top 2 components):\n"
    )
    
    # Add loadings for first two components
    for(var in rownames(pca$rotation)) {
      explanation <- paste0(
        explanation,
        var, ":\n",
        "  PC1: ", round(pca$rotation[var, 1], 4), "\n",
        "  PC2: ", round(pca$rotation[var, 2], 4), "\n"
      )
    }
    
    # Add interpretation
    interpretation <- "\nInterpretation:\n"
    
    # Find top contributing variables for PC1
    pc1_loadings <- pca$rotation[, 1]
    pc1_top_pos <- names(sort(pc1_loadings, decreasing = TRUE)[1:2])
    pc1_top_neg <- names(sort(pc1_loadings)[1:2])
    
    interpretation <- paste0(
      interpretation,
      "PC1 seems to represent a spectrum of ",
      paste(pc1_top_pos, collapse = " and "),
      " (positive values) versus ",
      paste(pc1_top_neg, collapse = " and "),
      " (negative values).\n\n"
    )
    
    # Find top contributing variables for PC2
    pc2_loadings <- pca$rotation[, 2]
    pc2_top_pos <- names(sort(pc2_loadings, decreasing = TRUE)[1:2])
    pc2_top_neg <- names(sort(pc2_loadings)[1:2])
    
    interpretation <- paste0(
      interpretation,
      "PC2 seems to represent a spectrum of ",
      paste(pc2_top_pos, collapse = " and "),
      " (positive values) versus ",
      paste(pc2_top_neg, collapse = " and "),
      " (negative values)."
    )
    
    return(paste0(explanation, interpretation))
  })
  
  # Key phrases for company transcripts
  output$keyPhrases <- renderPlot({
    req(input$companySelector, rv$transcripts)
    
    company_transcripts <- rv$transcripts %>%
      filter(company == input$companySelector)
    
    if(nrow(company_transcripts) == 0) {
      return(NULL)
    }
    
    # Extract bigrams
    bigrams <- company_transcripts %>%
      unnest_tokens(bigram, transcript_text, token = "ngrams", n = 2) %>%
      separate(bigram, c("word1", "word2"), sep = " ") %>%
      filter(!word1 %in% stop_words$word,
             !word2 %in% stop_words$word,
             str_detect(word1, "^[a-z]+$"),
             str_detect(word2, "^[a-z]+$"),
             nchar(word1) > 2,
             nchar(word2) > 2) %>%
      unite(bigram, word1, word2, sep = " ") %>%
      count(bigram, sort = TRUE) %>%
      head(20)
    
    # Create bar plot with our blue palette
    ggplot(bigrams, aes(x = reorder(bigram, n), y = n, fill = n)) +
      geom_col() +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +
      coord_flip() +
      labs(x = NULL, y = "Count", title = "Top Bigrams in Transcripts") +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Sector analysis tab
  
  #  Sector performance plot
  output$sectorPerformance <- renderPlotly({
    req(rv$fundamentals)
    
    # Calculate average metrics by sector
    sector_performance <- rv$fundamentals %>%
      group_by(Sector) %>%
      summarise(
        AvgPE = mean(PE_Ratio, na.rm = TRUE),
        AvgRevenueGrowth = mean(Revenue_Growth_YOY * 100, na.rm = TRUE),  # Multiply by 100 for percentage
        AvgEPSGrowth = mean(EPS_Growth_YOY * 100, na.rm = TRUE),          # Multiply by 100 for percentage
        AvgDividendYield = mean(Dividend_Yield * 100, na.rm = TRUE),      # Multiply by 100 for percentage
        Count = n()
      ) %>%
      arrange(desc(AvgEPSGrowth))
    
    # Create plot with blue color palette
    p <- sector_performance %>%
      ggplot(aes(x = reorder(Sector, AvgEPSGrowth), y = AvgEPSGrowth, 
                 fill = AvgPE,
                 text = paste("Sector:", Sector,
                              "\nAvg EPS Growth:", round(AvgEPSGrowth, 2), "%",
                              "\nAvg PE Ratio:", round(AvgPE, 2),
                              "\nAvg Revenue Growth:", round(AvgRevenueGrowth, 2), "%",
                              "\nAvg Dividend Yield:", round(AvgDividendYield, 2), "%",
                              "\nNumber of Companies:", Count))) +
      geom_col() +
      coord_flip() +
      scale_fill_gradient(low = "#92c5de", high = "#2c3e50") +
      labs(x = NULL, y = "Average EPS Growth (%)", fill = "Avg P/E") +
      theme_minimal()
    
    ggplotly(p, tooltip = "text")
  })
  
  # Sector detail metrics
  output$sectorDetailMetrics <- renderPlotly({
    req(rv$fundamentals, input$sectorDetailMetric)
    
    metric_col <- sym(input$sectorDetailMetric)
    
    # Adjust values for percentage metrics
    plot_data <- rv$fundamentals
    if(input$sectorDetailMetric %in% c("Revenue_Growth_YOY", "EPS_Growth_YOY", "Dividend_Yield")) {
      plot_data <- plot_data %>%
        mutate(!!input$sectorDetailMetric := !!metric_col * 100)
    }
    
    # Create boxplot of selected metric by sector
    p <- plot_data %>%
      ggplot(aes(x = reorder(Sector, !!metric_col, FUN = median, na.rm = TRUE), 
                 y = !!metric_col)) +
      geom_boxplot(aes(fill = Sector), alpha = 0.7) +
      scale_fill_brewer(palette = "Blues") +
      coord_flip() +
      theme_minimal() +
      theme(legend.position = "none") +
      labs(x = NULL, y = gsub("_", " ", input$sectorDetailMetric))
    
    ggplotly(p)
  })
  
  # Companies in selected sector
  output$sectorCompanies <- renderDT({
    req(rv$fundamentals, input$sectorCompare)
    
    # Filter companies in selected sector
    # Multiply percentage values by 100 for display
    sector_companies <- rv$fundamentals %>%
      filter(Sector == input$sectorCompare) %>%
      select(Symbol, Name, Industry, PE_Ratio, Revenue_Growth_YOY, EPS_Growth_YOY, Market_Cap) %>%
      mutate(
        Revenue_Growth_YOY = Revenue_Growth_YOY * 100,
        EPS_Growth_YOY = EPS_Growth_YOY * 100
      ) %>%
      arrange(desc(EPS_Growth_YOY))
    
    # Format table
    datatable(sector_companies, options = list(
      pageLength = 10,
      order = list(list(4, 'desc'))
    )) %>%
      formatRound(c('PE_Ratio', 'Revenue_Growth_YOY', 'EPS_Growth_YOY'), digits = 2) %>%
      formatCurrency('Market_Cap', currency = "$", digits = 2)
  })
  
  # Create a sector sentiment comparison plot
  # Add transcript summary function (using text summarization)
  output$transcriptSummary <- renderUI({
    req(input$sentimentCompany, rv$transcripts)
    
    # Get transcript for selected company
    # Fix matching between company selector and transcript data
    company_name <- input$sentimentCompany
    company_transcripts <- rv$transcripts %>%
      filter(company == company_name | 
               str_detect(tolower(company), tolower(company_name)) | 
               str_detect(tolower(company_name), tolower(company))) %>%
      arrange(desc(transcript_date))
    
    if(nrow(company_transcripts) == 0) {
      return(h4("No transcript data available for selected company"))
    }
    
    # Get the latest transcript
    latest <- company_transcripts[1,]
    
    # Generate a summary using a simple extraction approach
    transcript_text <- latest$transcript_text
    
    # Split into sentences
    sentences <- unlist(strsplit(transcript_text, "[.!?]\\s+"))
    
    # Clean and trim sentences
    sentences <- sentences[nchar(sentences) > 10 & nchar(sentences) < 200]
    
    # Select a few representative sentences for the summary
    # Try to get sentences that mention earnings, performance, growth, or outlook
    key_sentences <- sentences[grepl("(revenue|profit|growth|outlook|earnings|quarterly|performance|increase|decrease)", 
                                     sentences, ignore.case = TRUE)]
    
    # If no key sentences found, just take a few from the beginning
    if(length(key_sentences) < 3) {
      key_sentences <- sentences[1:min(5, length(sentences))]
    }
    
    # Take 3-4 sentences for the summary
    summary_sentences <- key_sentences[1:min(4, length(key_sentences))]
    
    # Join sentences back with periods
    summary_text <- paste(summary_sentences, collapse = ". ")
    
    # Add periods back
    summary_text <- paste0(summary_text, ".")
    
    # Return formatted summary
    div(
      h4(paste("Summary of", company_name, "Transcript -", format(as.Date(latest$transcript_date), "%B %d, %Y"))),
      p(summary_text),
      hr(),
      p("Key Statistics:"),
      fluidRow(
        column(4, 
               div(
                 style = "background-color: #f8f9fa; padding: 10px; border-radius: 5px;",
                 h5("Sentiment Score"),
                 sentiment_data() %>% 
                   filter(input$sentimentType == "afinn") %>% 
                   summarise(avg_score = mean(value, na.rm = TRUE)) %>% 
                   pull(avg_score) %>% 
                   round(2) %>% 
                   h3(style = ifelse(. > 0, "color: #4575b4;", "color: #d73027;"))
               )
        ),
        column(4,
               div(
                 style = "background-color: #f8f9fa; padding: 10px; border-radius: 5px;",
                 h5("Word Count"),
                 transcript_tokens() %>% 
                   nrow() %>% 
                   h3()
               )
        ),
        column(4,
               div(
                 style = "background-color: #f8f9fa; padding: 10px; border-radius: 5px;",
                 h5("Transcript Length"),
                 nchar(latest$transcript_text) %>% 
                   h3()
               )
        )
      )
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
          