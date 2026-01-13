# Nailed it! - Nail Salon Manager Shiny Application

library(shiny)
library(shinyjs)
library(DBI)
library(RSQLite)

# ==============================================================================
# DATA STORAGE (Using reactive values as in-memory database)
# ==============================================================================

# Services definition
services_list <- list(
  list(id = "gel-mani", name = "Gel Manicure", price = 249, points = 5),
  list(id = "gel-pedi", name = "Gel Pedicure", price = 249, points = 5),
  list(id = "softgel-plain", name = "Softgel Extensions (Plain)", price = 349, points = 10),
  list(id = "softgel-full", name = "Softgel Extensions (Full Design)", price = 499, points = 15),
  list(id = "biab", name = "BIAB Overlay", price = 399, points = 12)
)

time_slots <- c("10:00 AM", "2:00 PM", "5:00 PM", "8:00 PM")

# Default admin credentials
admin_credentials <- list(
  username = "admin",
  password = "admin123"
)

# ==============================================================================
# UI DEFINITION
# ==============================================================================

ui <- fluidPage(
  # Enable shinyjs
  useShinyjs(),
  
  # Include custom CSS
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$title("Nailed it! - Nail Salon Manager"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$style(HTML('
      /* Responsive login layout + modern input styles */
      .login-box { max-width: 560px; width: 92%; margin: 0 auto; }
      .form-label { display: block; font-weight: 600; margin-bottom: 6px; }
      .input-field { width: 100%; padding: 12px 14px; border-radius: 12px; border: 2px solid rgba(74,21,75,0.15); outline: none; transition: box-shadow .2s, border-color .2s; background: #fff; }
      .input-field:focus { border-color: #ff69b4; box-shadow: 0 0 0 4px rgba(255,105,180,0.15); }
      .password-wrapper { position: relative; }
      .password-wrapper .eye-toggle { position: absolute; right: 12px; top: 50%; transform: translateY(-50%); cursor: pointer; user-select: none; font-size: 18px; line-height: 1; padding: 6px; border-radius: 8px; }
      .password-wrapper .eye-toggle:hover { background: rgba(0,0,0,0.06); }
      #login_btn { cursor: pointer; position: relative; z-index: 10; pointer-events: auto !important; }
      @media (max-width: 640px) {
        .section-header h2 { font-size: 1.4rem; }
        table.w-full thead { display: none; }
        table.w-full tr { display: block; margin-bottom: 10px; }
        table.w-full td { display: block; padding: 10px 12px; }
      }
    ')),
    tags$script(HTML('
      function togglePassword(id, checkboxId){
        var el = document.getElementById(id);
        var checkbox = document.getElementById(checkboxId);
        if(!el) return;
        if(checkbox.checked){ el.type = "text"; }
        else { el.type = "password"; }
      }
      
      // Sync display password input with hidden input before form submission
      document.addEventListener("DOMContentLoaded", function(){
        var displayInput = document.getElementById("login_password_display");
        var hiddenInput = document.getElementById("login_password");
        if(displayInput){
          displayInput.addEventListener("input", function(){
            if(hiddenInput) hiddenInput.value = displayInput.value;
            Shiny.setInputValue("login_password", displayInput.value);
          });
        }
      });
    '))
  ),
  
  # Background
  div(class = "coquette-bg"),
  
  # ========================================
  # LOGIN SCREEN
  # ========================================
  div(
    id = "login-screen",
    class = "login-screen w-full h-full",
    div(
      class = "login-box coquette-shadow rounded-3xl p-10 bow-decoration sparkle-decoration corner-ornament",
      div(
        class = "text-center mb-8",
        # Nail Polish SVG Icon
        div(
          class = "lock-icon mb-4",
          HTML('
            <svg width="80" height="80" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" style="margin: 0 auto; display: block;">
              <defs>
                <linearGradient id="nailGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" style="stop-color:#ff69b4;stop-opacity:1" />
                  <stop offset="100%" style="stop-color:#ffb6c1;stop-opacity:1" />
                </linearGradient>
              </defs>
              <!-- Nail polish bottle -->
              <ellipse cx="50" cy="35" rx="18" ry="6" fill="url(#nailGradient)" opacity="0.3" />
              <rect x="32" y="35" width="36" height="40" rx="4" fill="url(#nailGradient)" />
              <rect x="35" y="38" width="30" height="32" rx="3" fill="rgba(255, 255, 255, 0.3)" />
              <!-- Cap -->
              <rect x="42" y="20" width="16" height="15" rx="2" fill="#4a154b" />
              <ellipse cx="50" cy="20" rx="8" ry="4" fill="#6b2571" />
              <!-- Shine effect -->
              <ellipse cx="42" cy="50" rx="4" ry="12" fill="rgba(255, 255, 255, 0.5)" />
              <!-- Polish drip -->
              <path d="M 50 75 L 48 85 Q 48 88, 50 88 Q 52 88, 52 85 L 50 75 Z" fill="url(#nailGradient)" />
            </svg>
          ')
        ),
        h2(class = "font-playfair text-7xl font-black mb-2 shimmer-text", "Nailed it!"),
        p(class = "font-cormorant text-4xl font-light italic mb-2", "Welcome Back, Admin"),
        p(class = "font-cormorant text-2xl font-light italic mb-4", "Unlock your salon management dashboard")
      ),
      div(
        class = "space-y-6",
        div(
          tags$label(class = "form-label", `for` = "login_username", "Username", style = "font-size: 14px; font-weight: bold;"),
          textInput("login_username", NULL, placeholder = "Enter username", width = "100%")
        ),
        div(
          tags$label(class = "form-label", `for` = "login_password", "Password", style = "font-size: 14px; font-weight: bold;"),
          div(
            class = "password-wrapper",
            tags$input(id = "login_password_display", type = "password", placeholder = "Enter password", class = "input-field", style = "width: 100%;"),
            div(style = "margin-top: 10px; display: flex; align-items: center; gap: 8px;",
                tags$input(id = "show_password_cb", type = "checkbox", style = "width: 18px; height: 18px; cursor: pointer;", onchange = "togglePassword('login_password_display', 'show_password_cb')"),
                tags$label(`for` = "show_password_cb", "Show Password", style = "margin: 0; cursor: pointer; font-size: 14px;")
            )
          ),
          tags$input(id = "login_password", type = "hidden", value = "")
        ),
        actionButton(
          "login_btn",
          HTML("\U0001F513 Login"),
          class = "w-full py-4 rounded-xl font-bold text-lg btn-hover btn-primary",
          style = "background: linear-gradient(135deg, #ff69b4 0%, #ffb6c1 100%); color: #ffffff; border: 2px solid rgba(255, 105, 180, 0.6);"
        ),
        hidden(
          div(
            id = "login_error",
            class = "mt-4 text-center",
            style = "color: #dc2626; font-weight: 600;",
            "\u274C Incorrect username or password. Please try again."
          )
        )
      )
    )
  ),
  
  # ========================================
  # MAIN APP CONTAINER (Hidden until login)
  # ========================================
  hidden(
    div(
      id = "app-container",
      class = "w-full h-full overflow-auto",
      
      # Header with Logout Button
      tags$header(
        class = "w-full text-center py-16 relative vintage-border",
        div(
          class = "float-animation",
          h1(
            id = "salon-name",
            class = "font-playfair text-7xl font-black mb-4 shimmer-text",
            "Nailed it!"
          ),
          p(
            id = "salon-tagline",
            class = "font-cormorant text-2xl font-light italic",
            "Elegance in Every Detail"
          )
        ),
        # Logout Button
        actionButton(
          "logout_btn",
          HTML("\U0001F6AA Logout"),
          class = "logout-btn btn-hover",
          style = "position: absolute; top: 1rem; right: 1.5rem;"
        )
      ),
      
      # Navigation Tabs
      tags$nav(
        class = "w-full max-w-7xl mx-auto px-6 mb-8",
        div(
          class = "flex gap-4 justify-center flex-wrap",
          actionButton(
            "tab_customers",
            HTML("👤 Customers"),
            class = "tab-button active"
          ),
          actionButton(
            "tab_appointments",
            HTML("📅 Appointments"),
            class = "tab-button"
          ),
          actionButton(
            "tab_redemptions",
            HTML("🎁 Redemptions"),
            class = "tab-button"
          )
        )
      ),
      
      # ========================================
      # CUSTOMERS TAB CONTENT
      # ========================================
      div(
        id = "customers-content",
        class = "w-full max-w-7xl mx-auto px-6 pb-12",
        # Button to show the customer form
        actionButton(
          "show_customer_form",
          HTML("➕ Add New Customer"),
          class = "btn-hover btn-primary mb-6",
          style = "margin-bottom: 1rem;"
        ),
        div(
          class = "grid grid-cols-1 gap-8",
          
          # Add Customer Form (hidden until Add button is clicked)
          tags$section(
            id = "customer_form_section",
            style = "display: none;",
            class = "lg:col-span-1 coquette-shadow rounded-3xl p-8 relative bow-decoration sparkle-decoration corner-ornament h-fit",
            h2(id = "customer_form_title", class = "font-playfair text-3xl font-bold mb-6", "Add New Customer"),
            
            div(
              class = "space-y-5",
              div(
                tags$label(class = "form-label", `for` = "customer_name", "Customer Name"),
                textInput("customer_name", NULL, placeholder = "Enter full name", width = "100%")
              ),
              div(
                tags$label(class = "form-label", `for` = "customer_phone", "Phone Number"),
                textInput("customer_phone", NULL, placeholder = "09XX XXX XXXX", width = "100%")
              ),
              div(
                tags$label(class = "form-label", `for` = "customer_instagram", "Instagram Handle (Optional)"),
                textInput("customer_instagram", NULL, placeholder = "@username", width = "100%")
              ),
              div(
                class = "flex gap-3 pt-2",
                actionButton(
                  "save_customer",
                  HTML("💾 Save Customer"),
                  class = "flex-1 py-4 rounded-xl font-bold text-lg btn-hover btn-primary"
                ),
                actionButton(
                  "cancel_customer_edit",
                  "Cancel",
                  class = "py-4 rounded-xl font-bold text-lg btn-hover btn-secondary"
                )
              )
            )
          ),
          
          # Customers List
          tags$section(
            class = "lg:col-span-2 coquette-shadow rounded-3xl p-8 heart-decoration corner-ornament",
            div(
              class = "section-header",
              h2(class = "font-playfair text-3xl font-bold", "All Customers"),
              span(class = "text-4xl", "👥")
            ),
            div(
              id = "customers-grid",
              class = "grid grid-cols-1 gap-4 max-h-700 overflow-y-auto scroll-smooth",
              uiOutput("customers_list")
            )
          )
        )
      ),
      
      # ========================================
      # APPOINTMENTS TAB CONTENT
      # ========================================
      hidden(
        div(
          id = "appointments-content",
          class = "w-full max-w-7xl mx-auto px-6 pb-12",
          # Button to show the appointment form
          actionButton(
            "show_appointment_form",
            HTML("➕ Add New Appointment"),
            class = "btn-hover btn-primary mb-6",
            style = "margin-bottom: 1rem;"
          ),
          div(
            class = "grid grid-cols-1 gap-8",
            
            # Appointment Form (hidden until Add button is clicked)
            tags$section(
              id = "appointment_form_section",
              style = "display: none;",
              class = "lg:col-span-1 coquette-shadow rounded-3xl p-8 relative bow-decoration sparkle-decoration corner-ornament h-fit",
              h2(id = "appointment_form_title", class = "font-playfair text-3xl font-bold mb-6", "Add New Appointment"),
              
              div(
                class = "space-y-5",
                div(
                  tags$label(class = "form-label", "Select Customer"),
                  uiOutput("customer_dropdown")
                ),
                div(
                  tags$label(class = "form-label", "Service"),
                  div(
                    class = "space-y-2 max-h-300 overflow-y-auto",
                    uiOutput("services_checkboxes")
                  )
                ),
                div(
                  tags$label(class = "form-label", `for` = "appointment_date", "Date"),
                  dateInput("appointment_date", NULL, value = Sys.Date(), min = Sys.Date(), width = "100%")
                ),
                div(
                  tags$label(class = "form-label", `for` = "appointment_time", "Time Slot"),
                  selectInput("appointment_time", NULL, choices = c("Select time slot" = "", time_slots), width = "100%")
                ),
                div(
                  class = "flex gap-3 pt-2",
                  actionButton(
                    "save_appointment",
                    HTML("💾 Save Appointment"),
                    class = "flex-1 py-4 rounded-xl font-bold text-lg btn-hover btn-primary"
                  ),
                  actionButton(
                    "cancel_appointment_edit",
                    "Cancel",
                    class = "py-4 rounded-xl font-bold text-lg btn-hover btn-secondary"
                  )
                )
              )
            ),
            
            # Appointments Table
            tags$section(
              class = "lg:col-span-2 coquette-shadow rounded-3xl p-8 heart-decoration corner-ornament",
              div(
                class = "section-header",
                h2(class = "font-playfair text-3xl font-bold", "All Appointments"),
                span(class = "text-4xl", "📋")
              ),
              
              # Filter Buttons
              div(
                class = "flex flex-wrap gap-3 mb-6",
                actionButton("filter_all", "All", class = "filter-btn active"),
                actionButton("filter_today", "Today", class = "filter-btn"),
                actionButton("filter_upcoming", "Upcoming", class = "filter-btn"),
                actionButton("filter_missed", "Missed", class = "filter-btn"),
                actionButton("filter_done", "Done", class = "filter-btn"),
                actionButton("filter_cancelled", "Cancelled", class = "filter-btn"),
                actionButton("filter_archived", "Archived", class = "filter-btn")
              ),
              
              # Customer Filter and Sort
              div(
                class = "flex gap-4 mb-6",
                uiOutput("customer_filter"),
                selectInput("sort_appointments", "Sort by:", choices = c("Recently Booked" = "recent", "Earliest Date First" = "date_asc", "Latest Date First" = "date_desc"), selected = "recent", width = "200px")
              ),
              
              div(
                class = "overflow-x-auto max-h-700 overflow-y-auto scroll-smooth",
                uiOutput("appointments_table")
              )
            )
          )
        )
      ),
      
      # ========================================
      # REDEMPTIONS TAB CONTENT
      # ========================================
      hidden(
        div(
          id = "redemptions-content",
          class = "w-full max-w-7xl mx-auto px-6 pb-12",
          tags$section(
            class = "coquette-shadow rounded-3xl p-8 heart-decoration corner-ornament",
            div(
              class = "section-header",
              h2(class = "font-playfair text-3xl font-bold", "All Redemptions"),
              span(class = "text-4xl", "🎁")
            ),
            
            # Filter Buttons
            div(
              class = "flex flex-wrap gap-3 mb-6",
              actionButton("filter_redemptions_all", "All", class = "filter-btn active"),
              actionButton("filter_redemptions_redeemed", "Redeemed", class = "filter-btn"),
              actionButton("filter_redemptions_completed", "Completed", class = "filter-btn"),
              actionButton("filter_redemptions_archived", "Archived", class = "filter-btn")
            ),
            
            div(
              class = "overflow-x-auto max-h-700 overflow-y-auto scroll-smooth",
              uiOutput("redemptions_table")
            )
          )
        )
      )
    )
  ) # Close hidden app-container
)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================

server <- function(input, output, session) {
  # Database backend (SQLite) setup
  db_path <- file.path(getwd(), "nail_salon.sqlite")
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
  
  init_db <- function() {
    DBI::dbExecute(conn, "CREATE TABLE IF NOT EXISTS customers (id TEXT PRIMARY KEY, name TEXT, phone TEXT, instagram TEXT, created_at TEXT)")
    DBI::dbExecute(conn, "CREATE TABLE IF NOT EXISTS appointments (id TEXT PRIMARY KEY, customer_name TEXT, services TEXT, date TEXT, time_slot TEXT, total_price REAL, status TEXT, loyalty_points INTEGER, is_redemption INTEGER, created_at TEXT)")
  }
  
  db_load_customers <- function() {
    if (!DBI::dbExistsTable(conn, "customers")) return(data.frame(id=character(), name=character(), phone=character(), instagram=character(), created_at=character(), stringsAsFactors=FALSE))
    df <- DBI::dbGetQuery(conn, "SELECT * FROM customers")
    if (nrow(df) == 0) return(data.frame(id=character(), name=character(), phone=character(), instagram=character(), created_at=character(), stringsAsFactors=FALSE))
    df
  }
  
  db_load_appointments <- function() {
    if (!DBI::dbExistsTable(conn, "appointments")) return(data.frame(id=character(), customer_name=character(), services=character(), date=character(), time_slot=character(), total_price=numeric(), status=character(), loyalty_points=integer(), is_redemption=logical(), created_at=character(), stringsAsFactors=FALSE))
    df <- DBI::dbGetQuery(conn, "SELECT * FROM appointments")
    if (nrow(df) == 0) return(data.frame(id=character(), customer_name=character(), services=character(), date=character(), time_slot=character(), total_price=numeric(), status=character(), loyalty_points=integer(), is_redemption=logical(), created_at=character(), stringsAsFactors=FALSE))
    # Convert numeric flags
    df$is_redemption <- as.logical(as.integer(df$is_redemption))
    df$loyalty_points <- as.numeric(df$loyalty_points)
    df
  }
  
  db_insert_customer <- function(customer) {
    DBI::dbExecute(conn, "INSERT OR REPLACE INTO customers (id, name, phone, instagram, created_at) VALUES (?, ?, ?, ?, ?)", params = list(customer$id, customer$name, customer$phone, customer$instagram, customer$created_at))
  }
  
  db_update_customer <- function(customer) {
    DBI::dbExecute(conn, "UPDATE customers SET name = ?, phone = ?, instagram = ? WHERE id = ?", params = list(customer$name, customer$phone, customer$instagram, customer$id))
  }
  
  db_delete_customer <- function(customer_id) {
    DBI::dbExecute(conn, "DELETE FROM customers WHERE id = ?", params = list(customer_id))
  }
  
  db_insert_appointment <- function(appt) {
    # store is_redemption as integer 0/1
    DBI::dbExecute(conn, "INSERT OR REPLACE INTO appointments (id, customer_name, services, date, time_slot, total_price, status, loyalty_points, is_redemption, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", params = list(appt$id, appt$customer_name, appt$services, appt$date, appt$time_slot, appt$total_price, appt$status, as.integer(appt$loyalty_points), as.integer(appt$is_redemption), appt$created_at))
  }
  
  db_update_appointment <- function(appt) {
    DBI::dbExecute(conn, "UPDATE appointments SET customer_name = ?, services = ?, date = ?, time_slot = ?, total_price = ?, status = ?, loyalty_points = ?, is_redemption = ? WHERE id = ?", params = list(appt$customer_name, appt$services, appt$date, appt$time_slot, appt$total_price, appt$status, as.integer(appt$loyalty_points), as.integer(appt$is_redemption), appt$id))
  }
  
  db_delete_appointment <- function(appt_id) {
    DBI::dbExecute(conn, "DELETE FROM appointments WHERE id = ?", params = list(appt_id))
  }
  
  # Initialize DB and load into reactive values
  init_db()
  
  # Reactive values for data storage (seed from DB)
  customers <- reactiveVal(db_load_customers())
  appointments <- reactiveVal(db_load_appointments())
  
  # Reactive timer to auto-update missed appointments every minute
  observe({
    invalidateLater(60000, session)  # 60,000 ms = 1 minute
    appts_data <- appointments()
    updated <- FALSE
    for (i in seq_len(nrow(appts_data))) {
      if (appts_data$status[i] == "pending") {
        # Parse scheduled date/time and mark missed if 2 hours have passed
        date_str <- appts_data$date[i]
        time_str <- appts_data$time_slot[i]
        if (!is.na(date_str) && nzchar(date_str) && !is.na(time_str) && nzchar(time_str)) {
          sched <- try(as.POSIXct(paste(date_str, time_str), format = "%Y-%m-%d %I:%M %p"), silent = TRUE)
          if (!inherits(sched, "try-error") && !is.na(sched)) {
            elapsed_mins <- as.numeric(difftime(Sys.time(), sched, units = "mins"))
            if (!is.na(elapsed_mins) && elapsed_mins >= 120) {
              appts_data$status[i] <- "missed"
              # Update in DB
              db_update_appointment(list(id = appts_data$id[i], customer_name = appts_data$customer_name[i], services = appts_data$services[i], date = appts_data$date[i], time_slot = appts_data$time_slot[i], total_price = appts_data$total_price[i], status = "missed", loyalty_points = appts_data$loyalty_points[i], is_redemption = appts_data$is_redemption[i], created_at = appts_data$created_at[i]))
              updated <- TRUE
            }
          }
        }
      }
    }
    if (updated) {
      appointments(appts_data)
    }
  })
  
  # Editing state
  editing_customer_id <- reactiveVal(NULL)
  editing_appointment_id <- reactiveVal(NULL)
  current_filter <- reactiveVal("all")
  current_redemption_filter <- reactiveVal("all")
  
  # Track observers to avoid duplicates
  customer_observers <- reactiveVal(list())
  appointment_observers <- reactiveVal(list())
  
  # ============================================
  # LOGIN / LOGOUT
  # ============================================
  
  observeEvent(input$login_btn, {
    username <- trimws(input$login_username)
    password <- input$login_password
    
    if (username == admin_credentials$username && password == admin_credentials$password) {
      # Successful login
      shinyjs::hide("login-screen")
      shinyjs::show("app-container")
      shinyjs::hide("login_error")
      showNotification("\U0001F389 Welcome to Nailed it!", type = "message")
      
      # Reset login form
      updateTextInput(session, "login_username", value = "")
      updateTextInput(session, "login_password", value = "")
    } else {
      # Failed login
      shinyjs::show("login_error")
      updateTextInput(session, "login_username", value = "")
      updateTextInput(session, "login_password", value = "")
    }
  })
  
  observeEvent(input$logout_btn, {
    # Hide app and show login screen
    shinyjs::hide("app-container")
    shinyjs::show("login-screen")
    shinyjs::hide("login_error")
    
    # Reset login form
    updateTextInput(session, "login_username", value = "")
    updateTextInput(session, "login_password", value = "")
    
    showNotification("\U0001F44B Logged out successfully", type = "message")
  })
  
  # ============================================
  # TAB NAVIGATION
  # ============================================
  
  observeEvent(input$tab_customers, {
    shinyjs::removeClass(id = "tab_appointments", class = "active")
    shinyjs::removeClass(id = "tab_redemptions", class = "active")
    shinyjs::addClass(id = "tab_customers", class = "active")
    shinyjs::show("customers-content")
    shinyjs::hide("appointments-content")
    shinyjs::hide("redemptions-content")
  })
  
  observeEvent(input$tab_appointments, {
    shinyjs::removeClass(id = "tab_customers", class = "active")
    shinyjs::removeClass(id = "tab_redemptions", class = "active")
    shinyjs::addClass(id = "tab_appointments", class = "active")
    shinyjs::hide("customers-content")
    shinyjs::show("appointments-content")
    shinyjs::hide("redemptions-content")
  })
  
  observeEvent(input$tab_redemptions, {
    shinyjs::removeClass(id = "tab_customers", class = "active")
    shinyjs::removeClass(id = "tab_appointments", class = "active")
    shinyjs::addClass(id = "tab_redemptions", class = "active")
    shinyjs::hide("customers-content")
    shinyjs::hide("appointments-content")
    shinyjs::show("redemptions-content")
  })
  
  # ============================================
  # FILTER BUTTONS
  # ============================================
  
  update_filter_buttons <- function(active_filter) {
    filters <- c("all", "today", "upcoming", "missed", "done", "cancelled", "archived")
    for (f in filters) {
      btn_id <- paste0("filter_", f)
      shinyjs::removeClass(id = btn_id, class = "active")
    }
    shinyjs::addClass(id = paste0("filter_", active_filter), class = "active")
  }
  
  observeEvent(input$filter_all, { current_filter("all"); update_filter_buttons("all") })
  observeEvent(input$filter_today, { current_filter("today"); update_filter_buttons("today") })
  observeEvent(input$filter_upcoming, { current_filter("upcoming"); update_filter_buttons("upcoming") })
  observeEvent(input$filter_missed, { current_filter("missed"); update_filter_buttons("missed") })
  observeEvent(input$filter_done, { current_filter("done"); update_filter_buttons("done") })
  observeEvent(input$filter_cancelled, { current_filter("cancelled"); update_filter_buttons("cancelled") })
  observeEvent(input$filter_archived, { current_filter("archived"); update_filter_buttons("archived") })
  
  update_redemption_filter_buttons <- function(active_filter) {
    filters <- c("all", "redeemed", "completed", "archived")
    for (f in filters) {
      btn_id <- paste0("filter_redemptions_", f)
      shinyjs::removeClass(id = btn_id, class = "active")
    }
    shinyjs::addClass(id = paste0("filter_redemptions_", active_filter), class = "active")
  }
  
  observeEvent(input$filter_redemptions_all, { current_redemption_filter("all"); update_redemption_filter_buttons("all") })
  observeEvent(input$filter_redemptions_redeemed, { current_redemption_filter("redeemed"); update_redemption_filter_buttons("redeemed") })
  observeEvent(input$filter_redemptions_completed, { current_redemption_filter("completed"); update_redemption_filter_buttons("completed") })
  observeEvent(input$filter_redemptions_archived, { current_redemption_filter("archived"); update_redemption_filter_buttons("archived") })
  
  # ============================================
  # HELPER FUNCTIONS
  # ============================================
  
  get_customer_points <- function(customer_name, appts) {
    if (nrow(appts) == 0) return(0)
    customer_appts <- appts[tolower(appts$customer_name) == tolower(customer_name), ]
    sum(customer_appts$loyalty_points, na.rm = TRUE)
  }
  
  # ============================================
  # CUSTOMER DROPDOWN FOR APPOINTMENTS
  # ============================================
  
  output$customer_dropdown <- renderUI({
    cust_data <- customers()
    choices <- c("Choose a customer" = "")
    if (nrow(cust_data) > 0) {
      cust_data <- cust_data[order(cust_data$name), ]
      cust_choices <- setNames(cust_data$name, paste0(cust_data$name, " (", cust_data$phone, ")"))
      choices <- c(choices, cust_choices)
    }
    selectInput("appointment_customer", NULL, choices = choices, width = "100%")
  })
  
  # ============================================
  # CUSTOMER FILTER FOR APPOINTMENTS
  # ============================================
  
  output$customer_filter <- renderUI({
    cust_data <- customers()
    # Use a non-empty sentinel so Selectize always shows it
    choices <- c("All Customers" = "__ALL__")
    if (nrow(cust_data) > 0) {
      cust_data <- cust_data[order(cust_data$name), ]
      cust_names <- cust_data$name
      names(cust_names) <- cust_data$name
      choices <- c(choices, cust_names)
    }
    selectInput(
      "filter_customer",
      "Filter by Customer:",
      choices = choices,
      selected = if (is.null(input$filter_customer) || input$filter_customer == "") "__ALL__" else input$filter_customer,
      width = "200px"
    )
  })
  
  # ============================================
  # SERVICES CHECKBOXES
  # ============================================
  
  output$services_checkboxes <- renderUI({
    # Styled single-service selection (radio cards)
    choiceNames <- lapply(services_list, function(s) {
      div(class = "service-checkbox",
          div(class = "flex-1",
              span(class = "block font-semibold", s$name),
              span(class = "text-sm opacity-75", paste0("\u20B1", s$price, " \u2022 ", s$points, " pts"))
          )
      )
    })
    choiceValues <- sapply(services_list, function(s) s$id)
    radioButtons("appointment_service", NULL, choiceNames = choiceNames, choiceValues = choiceValues, selected = "")
  })
  
  # ============================================
  # RENDER CUSTOMERS LIST
  # ============================================
  
  output$customers_list <- renderUI({
    cust_data <- customers()
    appt_data <- appointments()
    
    if (nrow(cust_data) == 0) {
      return(
        div(
          class = "empty-state",
          div(class = "empty-state-icon", "👤"),
          p(class = "font-cormorant text-xl font-light", "No customers yet"),
          p(class = "font-montserrat text-sm mt-2", "Add your first customer to get started!")
        )
      )
    }
    
    cust_data <- cust_data[order(cust_data$name), ]
    
    lapply(seq_len(nrow(cust_data)), function(i) {
      customer <- cust_data[i, ]
      total_points <- get_customer_points(customer$name, appt_data)
      
      div(
        class = "customer-card fade-in",
        div(
          class = "flex flex-col gap-3",
          div(
            class = "flex justify-between items-start",
            div(
              class = "flex-1",
              h3(class = "font-playfair font-bold text-xl mb-1", customer$name),
              p(class = "text-sm opacity-75 mb-1", paste0("📞 ", customer$phone)),
              if (!is.na(customer$instagram) && customer$instagram != "") {
                tags$a(
                  href = paste0("https://instagram.com/", gsub("@", "", customer$instagram)),
                  target = "_blank",
                  class = "text-sm opacity-75",
                  style = "color: #ff69b4;",
                  paste0("📷 ", customer$instagram)
                )
              }
            ),
            div(class = "loyalty-badge", paste0("⭐ ", total_points, " pts"))
          ),
          if (total_points >= 100) {
            div(
              class = "mt-2 p-2 rounded-lg text-center font-semibold text-sm",
              style = "background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%); color: #854d0e; border: 2px solid rgba(255, 215, 0, 0.6);",
              "🎉 Eligible for free service!"
            )
          },
          div(
            class = "flex gap-2 flex-wrap",
            if (total_points >= 100) {
              actionButton(
                paste0("redeem_", customer$id),
                HTML("🎁 Redeem 100 pts"),
                class = "btn-hover",
                style = "background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%); color: #854d0e; border: 2px solid rgba(255, 215, 0, 0.6); padding: 0.5rem 1rem; border-radius: 0.75rem; font-weight: 700;"
              )
            },
            actionButton(
              paste0("view_transactions_", customer$id),
              HTML("🧾 Points Receipt"),
              class = "btn-hover",
              style = "background-color: #10b981; color: #ffffff; padding: 0.5rem 1rem; border-radius: 0.75rem; font-weight: 700;"
            ),
            actionButton(
              paste0("edit_customer_", customer$id),
              HTML("✏️ Edit"),
              class = "btn-hover",
              style = "background-color: #ff69b4; color: #ffffff; padding: 0.5rem 1rem; border-radius: 0.75rem; font-weight: 600;"
            ),
            actionButton(
              paste0("delete_customer_", customer$id),
              HTML("🗑️"),
              class = "btn-hover",
              style = "background-color: #ffc0cb; color: #4a154b; padding: 0.5rem 1rem; border-radius: 0.75rem; font-weight: 600;"
            )
          )
        )
      )
    })
  })
  
  # ============================================
  # RENDER APPOINTMENTS TABLE
  # ============================================
  
  output$appointments_table <- renderUI({
    appt_data <- appointments()
    filter_type <- current_filter()
    
    # Filter appointments (include redemptions)
    if (nrow(appt_data) > 0) {
      today <- Sys.Date()
      
      filtered <- switch(filter_type,
                         "today" = appt_data[as.Date(appt_data$date) == today, ],
                         "upcoming" = appt_data[as.Date(appt_data$date) > today, ],
                         "missed" = appt_data[appt_data$status == "missed", ],
                         "done" = appt_data[appt_data$status %in% c("done", "completed"), ],
                         "cancelled" = appt_data[appt_data$status == "cancelled", ],
                         "archived" = appt_data[appt_data$status == "archived", ],
                         appt_data
      )
      appt_data <- filtered
      
      # Exclude archived from all filters except archived
      if (filter_type != "archived") {
        appt_data <- appt_data[appt_data$status != "archived", ]
      }
      
      # Exclude cancelled free appointments from the appointments tab
      appt_data <- appt_data[!(appt_data$status == "cancelled" & appt_data$is_redemption == TRUE), ]
    }
    
    # Filter by customer if selected
    selected_customer <- input$filter_customer
    if (!is.null(selected_customer) && selected_customer != "" && selected_customer != "__ALL__") {
      appt_data <- appt_data[appt_data$customer_name == selected_customer, ]
    }
    
    # Sort
    if (nrow(appt_data) > 0) {
      sort_by <- input$sort_appointments
      if (!is.null(sort_by)) {
        if (sort_by == "recent") {
          appt_data <- appt_data[order(as.POSIXct(appt_data$created_at), decreasing = TRUE), ]
        } else if (sort_by == "date_asc") {
          appt_data <- appt_data[order(as.Date(appt_data$date), appt_data$time_slot), ]
        } else if (sort_by == "date_desc") {
          appt_data <- appt_data[order(as.Date(appt_data$date), decreasing = TRUE, appt_data$time_slot), ]
        }
      }
    }
    
    if (nrow(appt_data) == 0) {
      return(
        div(
          class = "empty-state",
          div(class = "empty-state-icon", "📅"),
          p(class = "font-cormorant text-xl font-light", "No appointments yet"),
          p(class = "font-montserrat text-sm mt-2", "Create your first appointment to get started!")
        )
      )
    }
    
    all_appts <- appointments()
    
    tags$table(
      class = "w-full",
      tags$thead(
        class = "sticky top-0 z-10",
        tags$tr(
          tags$th(class = "text-left p-4 rounded-l-2xl", "Customer"),
          tags$th(class = "text-left p-4", "Services"),
          tags$th(class = "text-left p-4", "Date & Time"),
          tags$th(class = "text-left p-4", "Price"),
          tags$th(class = "text-left p-4", "Status"),
          tags$th(class = "text-center p-4 rounded-r-2xl", "Actions")
        )
      ),
      tags$tbody(
        lapply(seq_len(nrow(appt_data)), function(i) {
          appt <- appt_data[i, ]
          total_points <- get_customer_points(appt$customer_name, all_appts)
          services <- strsplit(appt$services, ",")[[1]]
          is_done <- appt$status %in% c("done", "completed")
          
          tags$tr(
            tags$td(
              class = "p-4 rounded-l-2xl",
              div(class = "font-semibold", appt$customer_name),
              div(class = "loyalty-badge mt-1", style = "font-size: 0.75rem;", paste0("⭐ ", total_points, " pts"))
            ),
            tags$td(
              class = "p-4",
              div(
                class = "flex flex-wrap gap-1",
                lapply(services, function(s) {
                  span(class = "service-tag", trimws(s))
                })
              )
            ),
            tags$td(
              class = "p-4",
              div(class = "font-semibold", paste0("📅 ", format(as.Date(appt$date), "%b %d, %Y"))),
              div(class = "text-sm opacity-75", paste0("🕐 ", appt$time_slot))
            ),
            tags$td(
              class = "p-4",
              div(class = "font-bold text-lg", if(appt$is_redemption) "Free" else paste0("\u20B1", appt$total_price))
            ),
            tags$td(
              class = "p-4",
              if (appt$status == "redeemed") {
                span(class = "status-badge", style = "background-color: #ffd700; color: #854d0e; border-color: #ffd700;", "Redeemed")
              } else if (is_done) {
                span(class = "status-badge", style = "background-color: #86efac; color: #166534; border-color: #166534;", "Done")
              } else if (appt$status == "missed") {
                span(class = "status-badge", style = "background-color: #f59e0b; color: #92400e; border-color: #f59e0b;", "Missed")
              } else if (appt$status == "cancelled") {
                span(class = "status-badge", style = "background-color: #f87171; color: #7f1d1d; border-color: #f87171;", "Cancelled")
              } else if (appt$status == "archived") {
                span(class = "status-badge", style = "background-color: #9ca3af; color: #374151; border-color: #9ca3af;", "Archived")
              } else {
                span(class = "status-badge", style = "background-color: #ffc0cb; color: #4a154b; border-color: #4a154b;", "Pending")
              }
            ),
            tags$td(
              class = "p-4 rounded-r-2xl",
              div(
                class = "action-buttons",
                if (filter_type == "missed") {
                  list(
                    actionButton(
                      paste0("edit_appt_", appt$id),
                      HTML("✏️ Update"),
                      class = "action-btn",
                      style = "background-color: #ff69b4; color: #ffffff;"
                    ),
                    actionButton(
                      paste0("delete_appt_", appt$id),
                      HTML("🗑️"),
                      class = "action-btn",
                      style = "background-color: #ffc0cb; color: #4a154b;"
                    )
                  )
                } else if (filter_type %in% c("today", "upcoming") && is_done) {
                  tagList(
                    actionButton(
                      paste0("undo_appt_", appt$id),
                      HTML("↶ Undone"),
                      class = "action-btn",
                      style = "background-color: #fbbf24; color: #ffffff;"
                    ),
                    actionButton(
                      paste0("archive_appt_", appt$id),
                      HTML("📦 Archive"),
                      class = "action-btn",
                      style = "background-color: #9ca3af; color: #ffffff; margin-left: 0.5rem;"
                    )
                  )
                } else if (filter_type %in% c("today", "upcoming")) {
                  list(
                    if (!is_done && appt$status != "cancelled") {
                      actionButton(
                        paste0("done_appt_", appt$id),
                        HTML("✅ Done"),
                        class = "action-btn btn-success"
                      )
                    },
                    actionButton(
                      paste0("edit_appt_", appt$id),
                      HTML("✏️"),
                      class = "action-btn",
                      style = "background-color: #ff69b4; color: #ffffff;"
                    ),
                    actionButton(
                      paste0("cancel_appt_", appt$id),
                      HTML("❌ Cancel"),
                      class = "action-btn",
                      style = "background-color: #dc2626; color: #ffffff;"
                    ),
                    actionButton(
                      paste0("delete_appt_", appt$id),
                      HTML("🗑️"),
                      class = "action-btn",
                      style = "background-color: #ffc0cb; color: #4a154b;"
                    )
                  )
                } else if (filter_type == "cancelled") {
                  list(
                    actionButton(
                      paste0("reschedule_appt_", appt$id),
                      HTML("🔄 Reschedule"),
                      class = "action-btn",
                      style = "background-color: #10b981; color: #ffffff;"
                    ),
                    actionButton(
                      paste0("delete_appt_", appt$id),
                      HTML("🗑️"),
                      class = "action-btn",
                      style = "background-color: #ffc0cb; color: #4a154b;"
                    )
                  )
                } else {
                  if (appt$status == "archived") {
                    list(
                      actionButton(
                        paste0("restore_appt_", appt$id),
                        HTML("🔄 Restore"),
                        class = "action-btn",
                        style = "background-color: #10b981; color: #ffffff;"
                      ),
                      actionButton(
                        paste0("delete_appt_", appt$id),
                        HTML("🗑️"),
                        class = "action-btn",
                        style = "background-color: #ffc0cb; color: #4a154b; margin-left: 0.5rem;"
                      )
                    )
                  } else if (is_done) {
                    # For ALL appointments with DONE status, always show undone and archive
                    tagList(
                      actionButton(
                        paste0("undo_appt_", appt$id),
                        HTML("↶ Undone"),
                        class = "action-btn",
                        style = "background-color: #fbbf24; color: #ffffff;"
                      ),
                      actionButton(
                        paste0("archive_appt_", appt$id),
                        HTML("📦 Archive"),
                        class = "action-btn",
                        style = "background-color: #9ca3af; color: #ffffff; margin-left: 0.5rem;"
                      )
                    )
                  } else {
                    list(
                      if (!is_done && appt$status != "cancelled") {
                        actionButton(
                          paste0("done_appt_", appt$id),
                          HTML("✅ Done"),
                          class = "action-btn btn-success"
                        )
                      },
                      if (!is_done) {
                        if (appt$status == "missed" || appt$status == "cancelled") {
                          actionButton(
                            paste0("reschedule_appt_", appt$id),
                            HTML("🔄 Reschedule"),
                            class = "action-btn",
                            style = "background-color: #10b981; color: #ffffff;"
                          )
                        } else {
                          actionButton(
                            paste0("edit_appt_", appt$id),
                            HTML("✏️"),
                            class = "action-btn",
                            style = "background-color: #ff69b4; color: #ffffff;"
                          )
                        }
                      },
                      if (filter_type == "all" && appt$status == "pending") {
                        actionButton(
                          paste0("cancel_appt_", appt$id),
                          HTML("❌ Cancel"),
                          class = "action-btn",
                          style = "background-color: #dc2626; color: #ffffff;"
                        )
                      },
                      if (!is_done) {
                        actionButton(
                          paste0("delete_appt_", appt$id),
                          HTML("🗑️"),
                          class = "action-btn",
                          style = "background-color: #ffc0cb; color: #4a154b;"
                        )
                      }
                    )
                  }
                }
              )
            )
          )
        })
      )
    )
  })
  
  # ============================================
  # RENDER REDEMPTIONS TABLE
  # ============================================
  
  output$redemptions_table <- renderUI({
    appt_data <- appointments()
    
    if (nrow(appt_data) > 0) {
      redemptions <- appt_data[appt_data$is_redemption == TRUE, ]
    } else {
      redemptions <- appt_data[0, ]
    }
    
    # Filter redemptions
    redemption_filter <- current_redemption_filter()
    if (nrow(redemptions) > 0) {
      redemptions <- switch(redemption_filter,
                            "redeemed" = redemptions[redemptions$status == "redeemed", ],
                            "completed" = redemptions[redemptions$status == "completed", ],
                            "archived" = redemptions[redemptions$status == "archived", ],
                            redemptions
      )
      # Exclude archived and cancelled from 'All' filter
      if (redemption_filter == "all") {
        redemptions <- redemptions[!redemptions$status %in% c("archived", "cancelled"), ]
      }
    }
    
    if (nrow(redemptions) == 0) {
      return(
        div(
          class = "empty-state",
          div(class = "empty-state-icon", "🎁"),
          p(class = "font-cormorant text-xl font-light", "No redemptions yet"),
          p(class = "font-montserrat text-sm mt-2", "Customers can redeem points from their profile!")
        )
      )
    }
    
    redemptions <- redemptions[order(as.POSIXct(redemptions$created_at), decreasing = TRUE), ]
    all_appts <- appointments()
    
    tags$table(
      class = "w-full",
      tags$thead(
        class = "sticky top-0 z-10",
        tags$tr(
          tags$th(class = "text-left p-4 rounded-l-2xl", "Customer"),
          tags$th(class = "text-left p-4", "Redeemed Service"),
          tags$th(class = "text-left p-4", "Date Redeemed"),
          tags$th(class = "text-left p-4", "Scheduled For"),
          tags$th(class = "text-left p-4", "Status"),
          tags$th(class = "text-center p-4 rounded-r-2xl", "Actions")
        )
      ),
      tags$tbody(
        lapply(seq_len(nrow(redemptions)), function(i) {
          redemption <- redemptions[i, ]
          total_points <- get_customer_points(redemption$customer_name, all_appts)
          is_done <- redemption$status %in% c("done", "completed")
          
          tags$tr(
            tags$td(
              class = "p-4 rounded-l-2xl",
              div(class = "font-semibold", redemption$customer_name),
              div(class = "loyalty-badge mt-1", style = "font-size: 0.75rem;", paste0("⭐ ", total_points, " pts"))
            ),
            tags$td(
              class = "p-4",
              span(
                style = "padding: 0.25rem 0.75rem; border-radius: 0.5rem; font-weight: 500; background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%); color: #854d0e; border: 2px solid rgba(255, 215, 0, 0.6);",
                "💝 Free Service (100 pts)"
              )
            ),
            tags$td(
              class = "p-4",
              div(class = "font-semibold", paste0("📅 ", format(as.POSIXct(redemption$created_at), "%b %d, %Y")))
            ),
            tags$td(
              class = "p-4",
              if (!is.na(redemption$date) && redemption$date != "") {
                div(
                  div(class = "font-semibold", paste0("📅 ", format(as.Date(redemption$date), "%b %d, %Y"))),
                  if (!is.na(redemption$time_slot) && redemption$time_slot != "") {
                    div(class = "text-sm opacity-75", paste0("🕐 ", redemption$time_slot))
                  }
                )
              } else {
                span("⏳ Pending")
              }
            ),
            tags$td(
              class = "p-4",
              if (is_done) {
                span(class = "status-badge", style = "background-color: #86efac; color: #166534; border-color: #166534;", "Completed")
              } else {
                span(class = "status-badge", style = "background-color: #fde047; color: #854d0e; border-color: #854d0e;", "Redeemed")
              }
            ),
            tags$td(
              class = "p-4 rounded-r-2xl",
              div(
                class = "action-buttons",
                if (redemption$status == "archived") {
                  list(
                    actionButton(
                      paste0("restore_redemption_", redemption$id),
                      HTML("🔄 Restore"),
                      class = "action-btn",
                      style = "background-color: #10b981; color: #ffffff;"
                    ),
                    actionButton(
                      paste0("delete_redemption_", redemption$id),
                      HTML("🗑️"),
                      class = "action-btn",
                      style = "background-color: #ffc0cb; color: #4a154b;"
                    )
                  )
                } else {
                  list(
                    if (!is_done) {
                      actionButton(
                        paste0("complete_redemption_", redemption$id),
                        HTML("✅ Complete"),
                        class = "action-btn btn-success"
                      )
                    },
                    if (redemption$status == "redeemed") {
                      actionButton(
                        paste0("unredeem_redemption_", redemption$id),
                        HTML("↩️ Unredeem"),
                        class = "action-btn",
                        style = "background-color: #f59e0b; color: #ffffff;"
                      )
                    },
                    actionButton(
                      paste0("archive_redemption_", redemption$id),
                      HTML("📦 Archive"),
                      class = "action-btn",
                      style = "background-color: #9ca3af; color: #ffffff;"
                    )
                  )
                }
              )
            )
          )
        })
      )
    )
  })
  
  # ============================================
  # SAVE CUSTOMER
  # ============================================
  
  observeEvent(input$save_customer, {
    name <- trimws(input$customer_name)
    phone <- trimws(input$customer_phone)
    instagram <- trimws(input$customer_instagram)
    
    if (name == "" || phone == "") {
      showNotification("Please fill in all required fields", type = "error")
      return()
    }
    
    edit_id <- editing_customer_id()
    cust_data <- customers()
    
    if (!is.null(edit_id)) {
      # Update existing customer
      idx <- which(cust_data$id == edit_id)
      if (length(idx) > 0) {
        cust_data[idx, "name"] <- name
        cust_data[idx, "phone"] <- phone
        cust_data[idx, "instagram"] <- instagram
        customers(cust_data)
        # Persist update
        db_update_customer(list(id = edit_id, name = name, phone = phone, instagram = instagram))
        showNotification("Customer updated successfully! 💖", type = "message")
      }
      editing_customer_id(NULL)
      shinyjs::hide("cancel_customer_edit")
      updateActionButton(session, "save_customer", label = HTML("💾 Save Customer"))
      shinyjs::html(id = "customer_form_title", html = "Add New Customer")
    } else {
      # Add new customer
      new_customer <- data.frame(
        id = as.character(as.numeric(Sys.time()) * 1000),
        name = name,
        phone = phone,
        instagram = instagram,
        created_at = as.character(Sys.time()),
        stringsAsFactors = FALSE
      )
      customers(rbind(cust_data, new_customer))
      # Persist new customer
      db_insert_customer(as.list(new_customer[1, ]))
      showNotification("Customer added successfully! 💖", type = "message")
      # Hide the customer form after creating a new customer
      shinyjs::hide("customer_form_section")
    }
    
    # Reset form
    updateTextInput(session, "customer_name", value = "")
    updateTextInput(session, "customer_phone", value = "")
    updateTextInput(session, "customer_instagram", value = "")
  })
  
  # ============================================
  # CANCEL CUSTOMER EDIT
  # ============================================
  
  observeEvent(input$cancel_customer_edit, {
    editing_customer_id(NULL)
    shinyjs::hide("cancel_customer_edit")
    shinyjs::hide("customer_form_section")
    updateActionButton(session, "save_customer", label = HTML("💾 Save Customer"))
    shinyjs::html(id = "customer_form_title", html = "Add New Customer")
    updateTextInput(session, "customer_name", value = "")
    updateTextInput(session, "customer_phone", value = "")
    updateTextInput(session, "customer_instagram", value = "")
  })
  
  # ============================================
  # SAVE APPOINTMENT
  # ============================================
  
  observeEvent(input$save_appointment, {
    customer <- input$appointment_customer
    date_val <- input$appointment_date
    time_val <- input$appointment_time
    
    if (is.null(customer) || customer == "") {
      showNotification("Please select a customer", type = "error")
      return()
    }
    
    if (is.null(time_val) || time_val == "") {
      showNotification("Please select a time slot", type = "error")
      return()
    }
    
    # Single selected service (radio selection stores service id)
    selected_service_id <- input$appointment_service
    if (is.null(selected_service_id) || selected_service_id == "") {
      showNotification("Please select a service", type = "error")
      return()
    }
    
    s_idx <- which(sapply(services_list, function(s) s$id == selected_service_id))
    if (length(s_idx) == 0) {
      showNotification("Selected service not found", type = "error")
      return()
    }
    sel_service <- services_list[[s_idx]]
    selected_services <- sel_service$name
    total_price <- sel_service$price
    
    edit_id <- editing_appointment_id()
    appt_data <- appointments()
    
    # Prevent duplicate appointments for same date & time slot (exclude current edit)
    conflict_idx <- which(as.Date(appt_data$date) == as.Date(date_val) & appt_data$time_slot == time_val)
    if (length(conflict_idx) > 0) {
      if (is.null(edit_id) || any(appt_data$id[conflict_idx] != edit_id)) {
        showNotification("This time slot is already booked", type = "error")
        return()
      }
    }
    
    if (!is.null(edit_id)) {
      # Update existing appointment
      idx <- which(appt_data$id == edit_id)
      if (length(idx) > 0) {
        appt_data[idx, "customer_name"] <- customer
        appt_data[idx, "services"] <- selected_services
        appt_data[idx, "date"] <- as.character(date_val)
        appt_data[idx, "time_slot"] <- time_val
        appt_data[idx, "total_price"] <- total_price
        appointments(appt_data)
        # Persist update
        db_update_appointment(list(id = edit_id, customer_name = customer, services = selected_services, date = as.character(date_val), time_slot = time_val, total_price = total_price, status = appt_data[idx, "status"], loyalty_points = as.integer(appt_data[idx, "loyalty_points"]), is_redemption = as.logical(appt_data[idx, "is_redemption"]), created_at = appt_data[idx, "created_at"]))
        showNotification("Appointment updated successfully! 💖", type = "message")
      }
      editing_appointment_id(NULL)
      shinyjs::hide("cancel_appointment_edit")
      shinyjs::hide("appointment_form_section")
      updateActionButton(session, "save_appointment", label = HTML("💾 Save Appointment"))
    } else {
      # Add new appointment
      new_appt <- data.frame(
        id = as.character(as.numeric(Sys.time()) * 1000),
        customer_name = customer,
        services = selected_services,
        date = as.character(date_val),
        time_slot = time_val,
        total_price = total_price,
        status = "pending",
        loyalty_points = 0,
        is_redemption = FALSE,
        created_at = as.character(Sys.time()),
        stringsAsFactors = FALSE
      )
      appointments(rbind(appt_data, new_appt))
      # Persist new appointment
      db_insert_appointment(as.list(new_appt[1, ]))
      showNotification("Appointment created successfully! 💖", type = "message")
      # Hide the appointment form after creating a new appointment
      shinyjs::hide("appointment_form_section")
    }
    
    # Reset service selection
    updateRadioButtons(session, "appointment_service", selected = "")
    updateSelectInput(session, "appointment_time", selected = "")
    updateDateInput(session, "appointment_date", value = Sys.Date())
  })
  
  # ============================================
  # CANCEL APPOINTMENT EDIT
  # ============================================
  
  observeEvent(input$cancel_appointment_edit, {
    editing_appointment_id(NULL)
    shinyjs::hide("cancel_appointment_edit")
    shinyjs::hide("appointment_form_section")
    updateActionButton(session, "save_appointment", label = HTML("💾 Save Appointment"))
    updateRadioButtons(session, "appointment_service", selected = "")
    updateSelectInput(session, "appointment_time", selected = "")
    updateDateInput(session, "appointment_date", value = Sys.Date())
  })
  
  # ============================================
  # DYNAMIC BUTTON OBSERVERS
  # ============================================
  
  # Helper to show delete modal
  show_delete_modal <- function(item_type, item_id, on_confirm) {
    showModal(modalDialog(
      title = div(class = "font-playfair text-2xl font-bold", "Confirm Delete"),
      p(class = "font-cormorant text-lg", paste0("Are you sure you want to delete this ", item_type, "? This action cannot be undone.")),
      footer = tagList(
        actionButton("modal_confirm_delete", "Yes, Delete", class = "btn-hover", style = "background-color: #dc2626; color: #ffffff; padding: 0.75rem 1.5rem; border-radius: 1rem;"),
        modalButton("Cancel")
      ),
      easyClose = FALSE
    ))
    
    observeEvent(input$modal_confirm_delete, {
      on_confirm()
      removeModal()
    }, ignoreInit = TRUE, once = TRUE)
  }
  
  # Helper to show archive modal
  show_archive_modal <- function(item_type, item_id, on_confirm) {
    showModal(modalDialog(
      title = div(class = "font-playfair text-2xl font-bold", "Confirm Archive"),
      p(class = "font-cormorant text-lg", paste0("Are you sure you want to archive this ", item_type, "? It will be moved to the archived section.")),
      footer = tagList(
        actionButton("modal_confirm_archive", "Yes, Archive", class = "btn-hover", style = "background-color: #6b7280; color: #ffffff; padding: 0.75rem 1.5rem; border-radius: 1rem;"),
        modalButton("Cancel")
      ),
      easyClose = TRUE
    ))
    
    observeEvent(input$modal_confirm_archive, {
      on_confirm()
      removeModal()
    }, ignoreInit = TRUE, once = TRUE)
  }
  
  # Helper to show cancel modal
  show_cancel_modal <- function(item_type, item_id, on_confirm) {
    showModal(modalDialog(
      title = div(class = "font-playfair text-2xl font-bold", "Confirm Cancel"),
      p(class = "font-cormorant text-lg", paste0("Are you sure you want to cancel this ", item_type, "? It will be marked as cancelled.")),
      footer = tagList(
        actionButton("modal_confirm_cancel", "Yes, Cancel", class = "btn-hover", style = "background-color: #dc2626; color: #ffffff; padding: 0.75rem 1.5rem; border-radius: 1rem;"),
        modalButton("Keep")
      ),
      easyClose = TRUE
    ))
    
    observeEvent(input$modal_confirm_cancel, {
      on_confirm()
      removeModal()
    }, ignoreInit = TRUE, once = TRUE)
  }
  
  # Watch for any button clicks
  observe({
    # Get all input names
    all_inputs <- names(input)
    
    # Customer edit buttons
    edit_customer_btns <- grep("^edit_customer_", all_inputs, value = TRUE)
    for (btn in edit_customer_btns) {
      local({
        btn_name <- btn
        cust_id <- sub("^edit_customer_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          cust_data <- customers()
          cust <- cust_data[cust_data$id == cust_id, ]
          if (nrow(cust) > 0) {
            editing_customer_id(cust_id)
            updateTextInput(session, "customer_name", value = cust$name[1])
            updateTextInput(session, "customer_phone", value = cust$phone[1])
            updateTextInput(session, "customer_instagram", value = if(is.na(cust$instagram[1])) "" else cust$instagram[1])
            shinyjs::show("cancel_customer_edit")
            updateActionButton(session, "save_customer", label = HTML("💾 Update Customer"))
            shinyjs::html(id = "customer_form_title", html = "Update Customer")
            shinyjs::click("tab_customers")
            shinyjs::show("customer_form_section")
          }
        }, ignoreInit = TRUE)
      })
    }
    
    # Customer delete buttons
    delete_customer_btns <- grep("^delete_customer_", all_inputs, value = TRUE)
    for (btn in delete_customer_btns) {
      local({
        btn_name <- btn
        cust_id <- sub("^delete_customer_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          show_delete_modal("customer", cust_id, function() {
            current_data <- customers()
            customers(current_data[current_data$id != cust_id, ])
            # Persist delete
            db_delete_customer(cust_id)
            showNotification("Customer deleted successfully", type = "message")
          })
        }, ignoreInit = TRUE)
      })
    }
    
    # Customer transactions/receipt buttons
    view_tx_btns <- grep("^view_transactions_", all_inputs, value = TRUE)
    for (btn in view_tx_btns) {
      local({
        btn_name <- btn
        cust_id <- sub("^view_transactions_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          cust_data <- customers()
          cust <- cust_data[cust_data$id == cust_id, ]
          if (nrow(cust) > 0) {
            cust_name <- cust$name[1]
            current_appts <- appointments()
            # Transactions: appointments that earned points (loyalty_points > 0)
            tx <- current_appts[tolower(current_appts$customer_name) == tolower(cust_name) &
                                  as.numeric(current_appts$loyalty_points) > 0, ]
            
            # Build rows
            tx_rows <- list()
            total_pts <- 0
            if (nrow(tx) > 0) {
              for (i in seq_len(nrow(tx))) {
                ap <- tx[i, ]
                date_str <- if (!is.na(ap$date) && ap$date != "") format(as.Date(ap$date), "%b %d, %Y") else format(as.POSIXct(ap$created_at), "%b %d, %Y")
                services <- strsplit(ap$services, ",")[[1]]
                svc_tags <- lapply(services, function(sv) {
                  sv_clean <- trimws(sv)
                  pts <- 0
                  for (s in services_list) { if (sv_clean == s$name) { pts <- s$points; break } }
                  span(class = "service-tag", paste0(sv_clean, " (", pts, " pts)"))
                })
                pts_earned <- as.integer(ap$loyalty_points)
                total_pts <- total_pts + pts_earned
                tx_rows[[length(tx_rows)+1]] <- tags$tr(
                  tags$td(class = "p-3", paste0("📅 ", date_str)),
                  tags$td(class = "p-3", div(class = "flex flex-wrap gap-1", svc_tags)),
                  tags$td(class = "p-3", span(class = "status-badge", ap$status)),
                  tags$td(class = "p-3", strong(paste0(pts_earned, " pts")))
                )
              }
            }
            
            showModal(modalDialog(
              title = div(class = "font-playfair text-2xl font-bold", paste0("🧾 Points Receipt — ", cust_name)),
              size = "l",
              easyClose = TRUE,
              footer = tagList(modalButton("Close")),
              div(
                class = "mb-3",
                span(class = "font-montserrat text-sm", "This lists all appointments that earned points for this customer.")
              ),
              if (length(tx_rows) == 0) {
                div(class = "empty-state", p(class = "font-cormorant text-lg", "No point-earning appointments yet."))
              } else {
                tagList(
                  tags$table(
                    class = "w-full",
                    tags$thead(
                      tags$tr(
                        tags$th(class = "text-left p-3", "Date"),
                        tags$th(class = "text-left p-3", "Services"),
                        tags$th(class = "text-left p-3", "Status"),
                        tags$th(class = "text-left p-3", "Points Earned")
                      )
                    ),
                    tags$tbody(tx_rows)
                  ),
                  div(class = "mt-4 p-3 rounded-xl",
                      style = "background-color: #f0fdf4; border: 2px solid #86efac;",
                      span(class = "font-playfair text-xl font-bold", paste0("Total Points: ", total_pts, " pts"))
                  )
                )
              }
            ))
          }
        }, ignoreInit = TRUE)
      })
    }
    # Redeem buttons
    redeem_btns <- grep("^redeem_", all_inputs, value = TRUE)
    for (btn in redeem_btns) {
      local({
        btn_name <- btn
        cust_id <- sub("^redeem_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          cust_data <- customers()
          cust <- cust_data[cust_data$id == cust_id, ]
          if (nrow(cust) > 0) {
            appt_data <- appointments()
            total_points <- get_customer_points(cust$name[1], appt_data)
            
            if (total_points >= 100) {
              showModal(modalDialog(
                title = div(class = "font-playfair text-2xl font-bold", "🎉 Redeem Loyalty Points"),
                p(class = "font-cormorant text-lg", paste0(cust$name[1], " has ", total_points, " points. Redeem 100 points for a free service?")),
                dateInput("redeem_date", "Appointment Date", value = Sys.Date(), min = Sys.Date()),
                selectInput("redeem_time", "Time Slot", choices = c("Select time slot" = "", time_slots)),
                selectInput("redeem_service", "Choose Service", choices = setNames(sapply(services_list, function(s) s$id), sapply(services_list, function(s) s$name)), selected = sapply(services_list, function(s) s$id)[1]),
                footer = tagList(
                  actionButton("confirm_redeem", HTML("🎁 Redeem & Schedule"), class = "btn-hover", style = "background-color: #ff69b4; color: #ffffff; padding: 0.75rem 1.5rem; border-radius: 1rem;"),
                  modalButton("Cancel")
                ),
                easyClose = TRUE
              ))
              
              # Store customer name for redeem handler
              session$userData$redeem_customer <- cust$name[1]
            }
          }
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment done buttons
    done_appt_btns <- grep("^done_appt_", all_inputs, value = TRUE)
    for (btn in done_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^done_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          showModal(modalDialog(
            title = div(class = "font-playfair text-2xl font-bold", "Mark as Done"),
            p(class = "font-cormorant text-lg", "Are you sure you want to mark this appointment as completed? This will award loyalty points to the customer."),
            footer = tagList(
              actionButton("confirm_done", "Yes, Mark as Done", class = "btn-hover", style = "background-color: #10b981; color: #ffffff; padding: 0.75rem 1.5rem; border-radius: 1rem;"),
              modalButton("Cancel")
            ),
            easyClose = FALSE
          ))
          
          observeEvent(input$confirm_done, {
            current_appts <- appointments()
            idx <- which(current_appts$id == appt_id)
            if (length(idx) > 0) {
              # Calculate loyalty points
              services <- strsplit(current_appts[idx, "services"], ",")[[1]]
              earned_points <- 0
              for (service_name in services) {
                for (s in services_list) {
                  if (trimws(service_name) == s$name) {
                    earned_points <- earned_points + s$points
                    break
                  }
                }
              }
              
              current_appts[idx, "status"] <- "done"
              current_appts[idx, "loyalty_points"] <- earned_points
              appointments(current_appts)
              # Persist appointment status and loyalty points
              db_update_appointment(list(id = appt_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "done", loyalty_points = as.integer(earned_points), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
              showNotification(paste0("✅ Appointment completed! ", earned_points, " loyalty points awarded."), type = "message")
            }
            removeModal()
          }, ignoreInit = TRUE, once = TRUE)
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment undo buttons
    undo_appt_btns <- grep("^undo_appt_", all_inputs, value = TRUE)
    for (btn in undo_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^undo_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          showModal(modalDialog(
            title = div(class = "font-playfair text-2xl font-bold", "Mark as Undone"),
            p(class = "font-cormorant text-lg", "Are you sure you want to mark this appointment as not completed? This will remove the loyalty points awarded."),
            footer = tagList(
              actionButton("confirm_undo", "Yes, Mark as Undone", class = "btn-hover", style = "background-color: #f59e0b; color: #ffffff; padding: 0.75rem 1.5rem; border-radius: 1rem;"),
              modalButton("Cancel")
            ),
            easyClose = FALSE
          ))
          
          observeEvent(input$confirm_undo, {
            current_appts <- appointments()
            idx <- which(current_appts$id == appt_id)
            if (length(idx) > 0) {
              current_appts[idx, "status"] <- "pending"
              current_appts[idx, "loyalty_points"] <- 0  # Remove points
              appointments(current_appts)
              # Persist
              db_update_appointment(list(id = appt_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "pending", loyalty_points = 0, is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
              showNotification("↶ Appointment marked as undone.", type = "message")
            }
            removeModal()
          }, ignoreInit = TRUE, once = TRUE)
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment edit buttons
    edit_appt_btns <- grep("^edit_appt_", all_inputs, value = TRUE)
    for (btn in edit_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^edit_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          current_appts <- appointments()
          appt <- current_appts[current_appts$id == appt_id, ]
          if (nrow(appt) > 0) {
            if (appt$status[1] == "done") {
              showNotification("Cannot edit a completed appointment", type = "error")
              return()
            }
            editing_appointment_id(appt_id)
            updateSelectInput(session, "appointment_customer", selected = appt$customer_name[1])
            updateDateInput(session, "appointment_date", value = as.Date(appt$date[1]))
            updateSelectInput(session, "appointment_time", selected = appt$time_slot[1])
            
            # Set single-service radio selection based on stored service name
            stored_service <- trimws(appt$services[1])
            # If stored_service is a redeemed label like 'Free - <name>', strip prefix
            stored_clean <- sub('^Free -\\s*', '', stored_service)
            sel_id <- NULL
            for (s in services_list) {
              if (s$name == stored_clean) {
                sel_id <- s$id
                break
              }
            }
            if (!is.null(sel_id)) {
              updateRadioButtons(session, "appointment_service", selected = sel_id)
            } else {
              updateRadioButtons(session, "appointment_service", selected = "")
            }
            
            shinyjs::show("cancel_appointment_edit")
            updateActionButton(session, "save_appointment", label = HTML("💾 Update Appointment"))
            shinyjs::html(id = "appointment_form_title", html = "Update Appointment")
            shinyjs::click("tab_appointments")
            shinyjs::show("appointment_form_section")
          }
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment delete buttons
    delete_appt_btns <- grep("^delete_appt_", all_inputs, value = TRUE)
    for (btn in delete_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^delete_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          show_delete_modal("appointment", appt_id, function() {
            current_appts <- appointments()
            appointments(current_appts[current_appts$id != appt_id, ])
            # Persist delete
            db_delete_appointment(appt_id)
            showNotification("Appointment deleted successfully", type = "message")
          })
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment archive buttons
    archive_appt_btns <- grep("^archive_appt_", all_inputs, value = TRUE)
    for (btn in archive_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^archive_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          show_archive_modal("appointment", appt_id, function() {
            current_appts <- appointments()
            idx <- which(current_appts$id == appt_id)
            if (length(idx) > 0) {
              current_appts[idx, "status"] <- "archived"
              appointments(current_appts)
              # Persist archive
              db_update_appointment(list(id = appt_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "archived", loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
              showNotification("Appointment archived successfully", type = "message")
            }
          })
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment cancel buttons
    cancel_appt_btns <- grep("^cancel_appt_", all_inputs, value = TRUE)
    for (btn in cancel_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^cancel_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          show_cancel_modal("appointment", appt_id, function() {
            current_appts <- appointments()
            idx <- which(current_appts$id == appt_id)
            if (length(idx) > 0) {
              current_appts[idx, "status"] <- "cancelled"
              appointments(current_appts)
              # Persist cancel
              db_update_appointment(list(id = appt_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "cancelled", loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
              showNotification("Appointment cancelled successfully", type = "message")
            }
          })
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment reschedule buttons
    reschedule_appt_btns <- grep("^reschedule_appt_", all_inputs, value = TRUE)
    for (btn in reschedule_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^reschedule_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          current_appts <- appointments()
          appt <- current_appts[current_appts$id == appt_id, ]
          if (nrow(appt) > 0) {
            # Change status to pending since rescheduling
            idx <- which(current_appts$id == appt_id)
            current_appts[idx, "status"] <- "pending"
            appointments(current_appts)
            # Persist status change
            db_update_appointment(list(id = appt_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "pending", loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
            
            editing_appointment_id(appt_id)
            updateSelectInput(session, "appointment_customer", selected = appt$customer_name[1])
            updateDateInput(session, "appointment_date", value = as.Date(appt$date[1]))
            updateSelectInput(session, "appointment_time", selected = appt$time_slot[1])
            
            # Set single-service radio selection based on stored service name
            stored_service <- trimws(appt$services[1])
            # If stored_service is a redeemed label like 'Free - <name>', strip prefix
            stored_clean <- sub('^Free -\\s*', '', stored_service)
            sel_id <- NULL
            for (s in services_list) {
              if (s$name == stored_clean) {
                sel_id <- s$id
                break
              }
            }
            if (!is.null(sel_id)) {
              updateRadioButtons(session, "appointment_service", selected = sel_id)
            } else {
              updateRadioButtons(session, "appointment_service", selected = "")
            }
            
            shinyjs::show("cancel_appointment_edit")
            updateActionButton(session, "save_appointment", label = HTML("💾 Update Appointment"))
            shinyjs::html(id = "appointment_form_title", html = "Update Appointment")
            shinyjs::click("tab_appointments")
            shinyjs::show("appointment_form_section")
          }
        }, ignoreInit = TRUE)
      })
    }
    
    # Redemption complete buttons
    complete_redemption_btns <- grep("^complete_redemption_", all_inputs, value = TRUE)
    for (btn in complete_redemption_btns) {
      local({
        btn_name <- btn
        redemption_id <- sub("^complete_redemption_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          current_appts <- appointments()
          idx <- which(current_appts$id == redemption_id)
          if (length(idx) > 0) {
            current_appts[idx, "status"] <- "completed"
            appointments(current_appts)
            # Persist redemption completion
            db_update_appointment(list(id = redemption_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "completed", loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
            showNotification("✅ Redemption completed!", type = "message")
          }
        }, ignoreInit = TRUE)
      })
    }
    
    # Redemption archive buttons
    archive_redemption_btns <- grep("^archive_redemption_", all_inputs, value = TRUE)
    # Redemption unredeem buttons
    unredeem_redemption_btns <- grep("^unredeem_redemption_", all_inputs, value = TRUE)
    for (btn in unredeem_redemption_btns) {
      local({
        btn_name <- btn
        redemption_id <- sub("^unredeem_redemption_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          showModal(modalDialog(
            title = div(class = "font-playfair text-2xl font-bold", "Confirm Unredeem"),
            p(class = "font-cormorant text-lg", "Are you sure you want to unredeem? The appointment will be cancelled and the 100 points will be returned to the customer."),
            footer = tagList(
              actionButton("confirm_unredeem", "Yes, Unredeem", class = "btn-hover", style = "background-color: #f59e0b; color: #ffffff; padding: 0.75rem 1.5rem; border-radius: 1rem;"),
              modalButton("Cancel")
            ),
            easyClose = FALSE
          ))
          
          observeEvent(input$confirm_unredeem, {
            current_appts <- appointments()
            idx <- which(current_appts$id == redemption_id)
            if (length(idx) > 0) {
              customer_name <- current_appts[idx, "customer_name"]
              
              # Add back 100 points across customer's done or archived appointments, capped by their service points
              customer_done_idx <- which(
                tolower(current_appts$customer_name) == tolower(customer_name) &
                  current_appts$status %in% c("done", "archived")
              )
              
              # Prefer most recent appointments first
              if (length(customer_done_idx) > 1) {
                ord <- order(as.POSIXct(current_appts$created_at[customer_done_idx]), decreasing = TRUE)
                customer_done_idx <- customer_done_idx[ord]
              }
              
              points_to_add <- 100
              if (length(customer_done_idx) > 0) {
                for (didx in customer_done_idx) {
                  if (points_to_add <= 0) break
                  # Compute maximum points for this appointment from its service(s)
                  svc_names <- strsplit(current_appts[didx, "services"], ",")[[1]]
                  max_pts <- 0
                  for (svc in svc_names) {
                    for (s in services_list) {
                      if (trimws(svc) == s$name) {
                        max_pts <- max_pts + s$points
                        break
                      }
                    }
                  }
                  current_pts <- as.integer(current_appts[didx, "loyalty_points"])
                  add_here <- max_pts - current_pts
                  if (add_here > 0) {
                    add_val <- min(add_here, points_to_add)
                    current_appts[didx, "loyalty_points"] <- current_pts + add_val
                    points_to_add <- points_to_add - add_val
                  }
                }
                # Persist loyalty point restorations
                for (didx in customer_done_idx) {
                  ap <- list(
                    id = current_appts[didx, "id"],
                    customer_name = current_appts[didx, "customer_name"],
                    services = current_appts[didx, "services"],
                    date = current_appts[didx, "date"],
                    time_slot = current_appts[didx, "time_slot"],
                    total_price = as.numeric(current_appts[didx, "total_price"]),
                    status = current_appts[didx, "status"],
                    loyalty_points = as.integer(current_appts[didx, "loyalty_points"]),
                    is_redemption = as.logical(current_appts[didx, "is_redemption"]),
                    created_at = current_appts[didx, "created_at"]
                  )
                  db_update_appointment(ap)
                }
              }
              
              # Remove the redemption appointment entirely
              current_appts <- current_appts[current_appts$id != redemption_id, ]
              appointments(current_appts)
              # Persist delete in DB
              db_delete_appointment(redemption_id)
              
              showNotification("↩️ Redemption unredeemed. Free appointment removed and points restored.", type = "message")
            }
            removeModal()
          }, ignoreInit = TRUE, once = TRUE)
        }, ignoreInit = TRUE)
      })
    }
    for (btn in archive_redemption_btns) {
      local({
        btn_name <- btn
        redemption_id <- sub("^archive_redemption_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          show_archive_modal("redemption", redemption_id, function() {
            current_appts <- appointments()
            idx <- which(current_appts$id == redemption_id)
            if (length(idx) > 0) {
              current_appts[idx, "status"] <- "archived"
              appointments(current_appts)
              # Persist archive
              db_update_appointment(list(id = redemption_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "archived", loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
              showNotification("Redemption archived successfully", type = "message")
            }
          })
        }, ignoreInit = TRUE)
      })
    }
    
    # Appointment restore buttons
    restore_appt_btns <- grep("^restore_appt_", all_inputs, value = TRUE)
    for (btn in restore_appt_btns) {
      local({
        btn_name <- btn
        appt_id <- sub("^restore_appt_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          current_appts <- appointments()
          idx <- which(current_appts$id == appt_id)
          if (length(idx) > 0) {
            current_appts[idx, "status"] <- "done"
            appointments(current_appts)
            # Persist restore
            db_update_appointment(list(id = appt_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "done", loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
            showNotification("Appointment restored successfully", type = "message")
          }
        }, ignoreInit = TRUE)
      })
    }
    
    # Redemption restore buttons
    restore_redemption_btns <- grep("^restore_redemption_", all_inputs, value = TRUE)
    for (btn in restore_redemption_btns) {
      local({
        btn_name <- btn
        redemption_id <- sub("^restore_redemption_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          current_appts <- appointments()
          idx <- which(current_appts$id == redemption_id)
          if (length(idx) > 0) {
            current_appts[idx, "status"] <- "completed"
            appointments(current_appts)
            # Persist restore
            db_update_appointment(list(id = redemption_id, customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = "completed", loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"]))
            showNotification("Redemption restored successfully", type = "message")
          }
        }, ignoreInit = TRUE)
      })
    }
    
    # Redemption delete buttons
    delete_redemption_btns <- grep("^delete_redemption_", all_inputs, value = TRUE)
    for (btn in delete_redemption_btns) {
      local({
        btn_name <- btn
        redemption_id <- sub("^delete_redemption_", "", btn_name)
        
        observeEvent(input[[btn_name]], {
          show_delete_modal("redemption", redemption_id, function() {
            current_appts <- appointments()
            appointments(current_appts[current_appts$id != redemption_id, ])
            # Persist delete
            db_delete_appointment(redemption_id)
            showNotification("Redemption deleted successfully", type = "message")
          })
        }, ignoreInit = TRUE)
      })
    }
  })
  
  # Show customer form when Add button is clicked
  observeEvent(input$show_customer_form, {
    editing_customer_id(NULL)
    updateActionButton(session, "save_customer", label = HTML("💾 Save Customer"))
    shinyjs::html(id = "customer_form_title", html = "Add New Customer")
    updateTextInput(session, "customer_name", value = "")
    updateTextInput(session, "customer_phone", value = "")
    updateTextInput(session, "customer_instagram", value = "")
    shinyjs::show("customer_form_section")
    # optionally scroll to the form
    session$sendCustomMessage(type = 'focus', message = list(id = 'customer_form_section'))
  })
  
  # Show appointment form when Add button is clicked
  observeEvent(input$show_appointment_form, {
    editing_appointment_id(NULL)
    updateActionButton(session, "save_appointment", label = HTML("💾 Save Appointment"))
    shinyjs::html(id = "appointment_form_title", html = "Add New Appointment")
    updateRadioButtons(session, "appointment_service", selected = "")
    updateSelectInput(session, "appointment_time", selected = "")
    updateDateInput(session, "appointment_date", value = Sys.Date())
    shinyjs::show("appointment_form_section")
    # optionally scroll to the form
    session$sendCustomMessage(type = 'focus', message = list(id = 'appointment_form_section'))
  })
  
  # Handle redeem confirmation
  observeEvent(input$confirm_redeem, {
    redeem_date <- input$redeem_date
    redeem_time <- input$redeem_time
    redeem_service_id <- input$redeem_service
    customer_name <- session$userData$redeem_customer
    
    if (is.null(redeem_time) || redeem_time == "") {
      showNotification("Please select a time slot", type = "error")
      return()
    }
    
    if (is.null(customer_name)) return()
    
    # Prevent duplicate appointments for same date & time slot
    current_appts <- appointments()
    conflict_idx <- which(as.Date(current_appts$date) == as.Date(redeem_date) & current_appts$time_slot == redeem_time)
    if (length(conflict_idx) > 0) {
      showNotification("This time slot is already booked", type = "error")
      return()
    }
    
    # Deduct 100 points from existing appointments (include archived 'done' too)
    current_appts <- appointments()
    customer_appts_idx <- which(
      tolower(current_appts$customer_name) == tolower(customer_name) &
        current_appts$loyalty_points > 0
    )
    
    points_to_deduct <- 100
    for (idx in customer_appts_idx) {
      if (points_to_deduct <= 0) break
      current_points <- current_appts[idx, "loyalty_points"]
      deduction <- min(current_points, points_to_deduct)
      current_appts[idx, "loyalty_points"] <- current_points - deduction
      points_to_deduct <- points_to_deduct - deduction
    }
    # Persist loyalty point deductions for modified appointments
    if (length(customer_appts_idx) > 0) {
      for (idx in customer_appts_idx) {
        ap <- list(id = current_appts[idx, "id"], customer_name = current_appts[idx, "customer_name"], services = current_appts[idx, "services"], date = current_appts[idx, "date"], time_slot = current_appts[idx, "time_slot"], total_price = as.numeric(current_appts[idx, "total_price"]), status = current_appts[idx, "status"], loyalty_points = as.integer(current_appts[idx, "loyalty_points"]), is_redemption = as.logical(current_appts[idx, "is_redemption"]), created_at = current_appts[idx, "created_at"])
        db_update_appointment(ap)
      }
    }
    
    # Create redemption appointment
    redemption_appt <- data.frame(
      id = as.character(as.numeric(Sys.time()) * 1000),
      customer_name = customer_name,
      services = {
        # Map selected service id to readable name; store as Free - <name>
        svc_name <- "Free Service"
        if (!is.null(redeem_service_id) && redeem_service_id != "") {
          s_idx <- which(sapply(services_list, function(s) s$id == redeem_service_id))
          if (length(s_idx) > 0) svc_name <- paste0("Free - ", services_list[[s_idx]]$name)
        }
        svc_name
      },
      date = as.character(redeem_date),
      time_slot = redeem_time,
      total_price = 0,
      status = "redeemed",
      loyalty_points = 0,
      is_redemption = TRUE,
      created_at = as.character(Sys.time()),
      stringsAsFactors = FALSE
    )
    
    appointments(rbind(current_appts, redemption_appt))
    # Persist redemption appointment
    db_insert_appointment(as.list(redemption_appt[1, ]))
    removeModal()
    session$userData$redeem_customer <- NULL
    showNotification(paste0("🎉 100 points redeemed! Appointment scheduled for ", redeem_date), type = "message")
  }, ignoreInit = TRUE)
  
  # Disconnect DB when session ends
  session$onSessionEnded(function() {
    try(DBI::dbDisconnect(conn), silent = TRUE)
  })
}

# ==============================================================================
# RUN APPLICATION
# ==============================================================================

shinyApp(ui = ui, server = server)
