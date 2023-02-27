shinyServer(function(input, output, session) {
  
  # REACTION: loading dataset
  df_data <- reactive({
    get(input$dataset)
  })
  
  # REACTION: storing selected variables and rendering UI
  vars <- reactiveValues()
  
  observe({
    vars$df <- names(df_data())
    updateSelectInput(session, 'a', choices = vars$df)
  })
  
  observe({
    vars$y <- names(df_data()) 
    #vars$df[vars$df != input$a]
    updateSelectInput(session, 'y', choices = vars$y)
  })
  
  observe({
    #vars$a <- vars$df[vars$df != input$a]
    vars$x <- vars$df[vars$df != input$y & vars$df != input$a]
    updateSelectInput(session, 'x', choices = vars$x)
  })
  
   observe({
     vars$default_treatment <- default_treatment[[input$dataset]]
     vars$default_outcome <- default_outcome[[input$dataset]]
     updateSelectInput(session, 'a', selected = vars$default_treatment)
     updateSelectInput(session, 'y', selected = vars$default_outcome)
   })

  
  # DATA DESCRIPTION
  observe({
    output$data_description = renderText({
      data_descript[[ input$dataset ]]
      })
    output$temp = renderText({
      data_descript[[ 1 ]]
    })
    })
  
  #### Render Table 1 ####
  observe({
    cont_vars = cont_vars_list[[ input$dataset ]]
    factor_vars = factor_vars_list[[ input$dataset ]]
    if(input$a != "") {
      table1 = CreateTableOne(data = ns, vars = c(cont_vars, factor_vars), factorVars = factor_vars,
                              #strata = "cox2_initiation", test = FALSE, smd = TRUE)
                              strata = input$a, test = FALSE, smd = TRUE)
      output$table_1 = renderText({
        print(table1, smd = TRUE, printToggle = FALSE) %>%
          kable("html", digit = 2, padding = 100, caption = paste("Stratified by", input$a)) %>% kable_styling()
    })
    } else {
      output$table_1 = renderText({
        data.frame("Not Selected") %>% kable("html", digit = 2, padding = 100, caption = "Stratified by") %>% kable_styling()
      })
    }
  })

  
  # REACTION: storing selected variables and rendering UI

  # DATA SELECTION OUTPUT
  observe({
    lx <- length(input$x)
    if(lx == 0){
      output$data <- renderDataTable({
        datatable(df_data(), filter = "none",  options = list(scrollX = TRUE))
      })
    } else {
      output$data <- renderDataTable({
        datatable(df_data() %>% select_(.dots = input$x), filter = "none",  options = list(scrollX = TRUE))
      })
    }
    output$all_data <- renderDataTable({
      datatable(df_data(), filter = "none",  options = list(scrollX = TRUE))
    })
  })
 
  
 observeEvent(input$run, {
   
    # fit PS model
    if(length(input$x) == 0){
      fit = glm(formula(paste0(input$a, '~ 1')),
          family = "binomial", data = df_data())
    } else {
      fit = glm(formula(paste0(input$a, '~', paste0(input$x, collapse = "+"))),
          family = "binomial", data = df_data())
    }
   
   # fit PS model
   output$summary_fit = renderPrint({
     summary(fit)
   })
   
   # compute weights
   analy = df_data() %>%
     transmute(ps = predict(fit, type = "response"), 
               id = row_number(),
              treatment = !!sym(input$a),
              outcome = ifelse(!!sym(input$y) == "Yes", 1L, 0L),
              weight = case_when(input$weight == "IPTW" ~ I(treatment=="Yes") / ps + I(treatment=="No") / (1- ps),
                                 input$weight == "SMRW1" ~ I(treatment=="Yes") + ps / (1-ps) * I(treatment=="No"),
                                 TRUE ~ I(treatment=="No") +  (1-ps) / ps * I(treatment=="Yes"))
              )
   
   # Unweighted PS histogram, by treatment group
   temp = 
     ggplot(data = analy, aes(x = ps,
                              group = treatment,
                              fill = treatment)) +
     
   geom_histogram_interactive(
     aes(y = ..density..),
     color = "white",
     alpha = 0.5,
     binwidth = 0.01,
     position = position_dodge(width = 0.01/2)) +
     theme_bw() +
     xlab("Propensity Score") + 
     guides(colour = FALSE, linetype = FALSE, 
            fill = guide_legend("Treatment Group"))
   
   ps_dist = girafe(code = print(temp))
   girafe_options(ps_dist, opts_tooltip(css = tooltip_css))
   output$ps_dist = renderGirafe({ ps_dist })
   
   # Weighted PS histogram, by treatment group
   temp = 
     ggplot(data = analy, aes(x = ps,
                              weight = weight,
                              group = treatment,
                              fill = treatment)) +
     
     geom_histogram_interactive(
       aes(y = ..density..),
       color = "white",
       alpha = 0.5,
       binwidth = 0.01,
       position = position_dodge(width = 0.01/2)) +
     theme_bw() +
     xlab("Propensity Score") + 
     guides(colour = FALSE, linetype = FALSE, 
            fill = guide_legend("Treatment Group"))
   
   ps_dist_wt = girafe(code = print(temp))
   girafe_options(ps_dist, opts_tooltip(css = tooltip_css))
   output$ps_dist_wt = renderGirafe({ ps_dist_wt })
   
   # output data with weight
   output$aug_data <- renderDataTable({
     datatable(analy,
               filter = "none",  options = list(scrollX = TRUE))
   })
     
   #IPW Table 1 
  analy = cbind(analy, df_data())
  survey = svydesign(ids = ~ 1, data = analy,
                      weights = ~ weight)
  cont_vars = cont_vars_list[[ input$dataset ]]
  factor_vars = factor_vars_list[[ input$dataset ]]
  ipw_table1 = svyCreateTableOne(data = survey,
                                  vars = c(cont_vars, factor_vars), 
                                  factorVars = factor_vars, 
                                  strata = "treatment",
                                  test = FALSE, smd = TRUE)
   output$ipw_table_1 = renderText({
     print(ipw_table1, smd = TRUE, printToggle = FALSE) %>%
       kable("html", digit = 2, padding = 100, caption = paste("Stratified by", input$a)) %>%
       kable_styling()
   })
   
   # gee_unweighted = geeglm(outcome ~ treatment, data = analy,
   #                       id = id, family = binomial("identity"))
   gee_unweighted = geeglm(outcome ~ treatment, data = analy,
                           id = id, family = binomial("identity"))
   output$summary_unadjusted = renderPrint({
     summary(gee_unweighted)
   })
   
   gee_weighted = geeglm(outcome ~ treatment, data = analy,
                         id = id, weight = weight, 
                         family = binomial("identity"))
   output$summary_adjusted = renderPrint({
     summary(gee_weighted)
   })
  })
 
# run regression
 
 # observeEvent(input$run, {
 #   #browser()
 #   if(length(input$x) == 0){
 #     fit = glm(formula(paste0(input$a, '~ 1')),
 #               family = "binomial", data = df_data())
 #   } else {
 #     fit = glm(formula(paste0(input$a, '~', paste0(input$x, collapse = "+"))),
 #               family = "binomial", data = df_data())
 #   }
 #   output$summary_fit = renderPrint({
 #     summary(fit)
 #     #input$x
 #   })
 # }) 
  
})
  
