shinyUI(fluidPage(
  
  img(src = 'logo.png', width = '50%'),
  br(),
  tags$head(
    # Note the wrapping of the string in HTML()
    tags$style(HTML("
    @import url('https://fonts.googleapis.com/css2?family=Barlow&display=swap');
      body {
       font-family: 'Barlow', sans-serif;
      }
      h1{
        font-family: 'Barlow', sans-serif;
        text-align: center;
      }
      h2{
        font-family: 'Barlow', sans-serif;
        text-align: center;
      }
      h3{
        font-family: 'Barlow', sans-serif;
        text-align: center;
      }
      p {
        font-family: 'Barlow', sans-serif;
      }
      .shiny-input-container {
        color: #474747;
      }"))
  ),
  
  # Application title
  titlePanel(
    HTML('Propensity Score Weighted Analysis Lab')
  ),
  h3(HTML('M. Alan Brookhart, PhD')),
  h3(HTML("PHS 921: Introduction to Causal Inference")),
  br(),
  br(),
  
  column(1),
  
  # Sidebar Input Panel
  sidebarLayout(
    sidebarPanel(
      
      # INPUT: selecting dataset
      selectInput('dataset', 'Select a dataset:', choices = data_list, selectize = T),
      br(),
      
      # INPUT: specifying treatment
      selectInput('a', 'Treatment / Exposure variable:', '', 
                  multiple = F, selectize = T),
      
      # INPUT: specifying outcome
      selectInput('y', 'Outcome variable:', '', multiple = F, selectize = T),
      
      # INPUT: specifying PS model
      selectInput('x', 'Variables in propensity score model:', '', multiple = T, selectize = T),
      
      # INPUT: specifying the weighting scheme
      selectInput('weight', 'Weight type:', choices = list(`Inverse Probability of Treatment Weights` = "IPTW",
                                                           `Standardized Mortality Ratio Weights - Treatment` = "SMRW1",
                                                           `Standardized Mortality Ratio Weights - Control` = "SMRW2"),
                  multiple = F, selectize = T),
      
      actionButton("run", "Fit PS Model"),
      
      # Changing sidebar width
      width = 2),
    
    # Results Output Main Panel
    mainPanel(
      tabsetPanel(type = 'tabs',
                  tabPanel('Data Description',textOutput('data_description')),
                  tabPanel('Data',
                           br(),
                           DT::dataTableOutput('all_data')),
                  tabPanel('Table 1', htmlOutput('table_1')),
                  tabPanel('PS Model Fit',
                           p("These are the results from a logistic regression of the treatment
                           on the specified covariates. The paramters estimates are odds ratios."),
                           #plotOutput("fp_ps_model"),
                           gt_output(outputId = "summary_gt"),
                           p("This is the actual R output."),
                           verbatimTextOutput('summary_fit')),
                  tabPanel('PS Distribution', girafeOutput('ps_dist', height = "800px")),
                  tabPanel('Data Augmented with PS and Weight',
                           br(),
                           DT::dataTableOutput('aug_data')),
                  tabPanel('Weighted PS Distribution', girafeOutput('ps_dist_wt', height = "800px")),
                  tabPanel('Weighted Table 1', htmlOutput('ipw_table_1')),
                  tabPanel('Results',
                           h3("Unweighted / Unadjusted"),
                           p("These are the results from an unweighted linear regression of the outcome on treatment.
                             Estimation is done using a GEE approach for a binary outcome with an identity link function.
                             This results in an estimate of a risk difference. 
                             Robust standard errors are computed using an independence working variance-covariance matrix."),
                           gt_output(outputId = "gee_unwt_gt"),
                           p("This is the actual R output."),
                           verbatimTextOutput('summary_unadjusted'),
                           h3("Weighted / Adjusted"),
                           p("These are the results from a weighted linear regression of the outcome on treatment.
                             Estimation is done using a weighted GEE approach for a binary outcome with an identity link function.
                             This results in an estimate of a risk difference. 
                             Robust standard errors are computed using an independence working variance-covariance matrix."),
                           gt_output(outputId = "gee_wt_gt"),
                           p("This is the actual R output."),
                           verbatimTextOutput('summary_adjusted')),
      ), width = 7)
  ), column(1)
))
