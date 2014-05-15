#' Get ERDDAP data.
#'
#' @export
#' @import httr assertthat
#' @param datasetid Dataset id
#' @param fields Columns to return, as a character vector
#' @param ... Any number of key-value pairs in quotes as query constraints. See Details and examples
#' @param distinct If TRUE ERDDAP will sort all of the rows in the results table (starting with the 
#' first requested variable, then using the second requested variable if the first variable has a 
#' tie, ...), then remove all non-unique rows of data. In many situations, ERDDAP can return 
#' distinct values quickly and efficiently. But in some cases, ERDDAP must look through all rows 
#' of the source dataset.
#' @param orderby If used, ERDDAP will sort all of the rows in the results table (starting with the 
#' first variable, then using the second variable if the first variable has a tie, ...). Normally, 
#' the rows of data in the response table are in the order they arrived from the data source. 
#' orderBy allows you to request that the results table be sorted in a specific way. For example, 
#' use \code{orderby=c("stationID,time")} to get the results sorted by stationID, then time. The 
#' orderby variables MUST be included in the list of requested variables in the fields parameter.
#' @param orderbymax Give a vector of one or more fields, that must be included in the fields 
#' parameter as well. Gives back data given constraints. ERDDAP will sort all of the rows in the 
#' results table (starting with the first variable, then using the second variable if the first 
#' variable has a tie, ...) and then just keeps the rows where the value of the last sort variable 
#' is highest (for each combination of other values). 
#' @param orderbymin Same as \code{orderbymax} parameter, except returns minimum value.
#' @param orderbyminmax Same as \code{orderbymax} parameter, except returns two rows for every 
#' combination of the n-1 variables: one row with the minimum value, and one row with the maximum 
#' value.
#' @param units One of 'udunits' (units will be described via the UDUNITS standard (e.g.,degrees_C))
#' or 'ucum' (units will be described via the UCUM standard (e.g., Cel)). 
#' @param callopts Further args passed on to httr::GET (must be a named parameter)
#' @details
#' For key-value pair query constraints, the valid operators are =, != (not equals), =~ (a regular 
#' expression test), <, <=, >, and >= . 
#' 
#' Server-side functionality: Some tasks are done server side. You don't have to worry about what 
#' that means. They are provided via parameters in this function. See \code{distinct}, \code{}
#' @examples \dontrun{
#' erddap_data(datasetid='erdCalCOFIfshsiz', fields=c('longitude','latitude','fish_size','itis_tsn'),
#'    'time>=' = '2001-07-07','time<=' = '2001-07-10')
#' erddap_data(datasetid='erdCinpKfmBT', fields=c('latitude','longitude',
#'    'Aplysia_californica_Mean_Density','Muricea_californica_Mean_Density'),
#'    'time>=' = '2007-06-24','time<=' = '2007-07-01')
#' 
#' erddap_info('erdCalCOFIlrvsiz')$variables   
#' erddap_data(datasetid='erdCalCOFIlrvsiz', fields=c('latitude','longitude','larvae_size',
#'    'itis_tsn'), 'time>=' = '2011-10-25','time<=' = '2011-10-31')
#'
#' # An example workflow
#' (out <- erddap_search(query='fish size'))
#' id <- out$info$dataset_id[1]
#' erddap_info(datasetid=id)$variables
#' 
#' # Time constraint
#' ## Limit by time with date only
#' erddap_data(datasetid = id, fields = c('latitude','longitude','scientific_name'),
#'    'time>=' = '2001-07-14')
#' ## Limit by time with hours and date
#' erddap_data(datasetid='ndbcSosWTemp', fields=c('latitude','longitude','sea_water_temperature'),
#'    'time>=' = '2014-05-14T15:15:00Z')
#'    
#' # Example error response, warning thrown and give back NA
#' erddap_data(datasetid='ndbcSosWTemp', fields=c('latitude','longitude','sea_water_temperature'),
#'    'sea_water_temperature>=' = '25')
#'    
#' # Use distinct parameter
#' erddap_data(datasetid='erdCalCOFIfshsiz', fields=c('longitude','latitude','fish_size','itis_tsn'),
#'    'time>=' = '2001-07-07','time<=' = '2001-07-10', distinct=TRUE)
#'    
#' # Use units parameter
#' erddap_data(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=' = '2007-09-19', 'time<=' = '2007-09-21', units='udunits')
#' erddap_data(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=' = '2007-09-19', 'time<=' = '2007-09-21', units='ucum')
#'    
#' # Use orderby parameter
#' erddap_data(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=' = '2007-09-19', 'time<=' = '2007-09-21', orderby='temperature')
#' # Use orderbymax parameter
#' erddap_data(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=' = '2007-09-19', 'time<=' = '2007-09-21', orderbymax='temperature')
#' # Use orderbymin parameter
#' erddap_data(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=' = '2007-09-19', 'time<=' = '2007-09-21', orderbymin='temperature')
#' # Use orderbyminmax parameter
#' erddap_data(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=' = '2007-09-19', 'time<=' = '2007-09-21', orderbyminmax='temperature')
#' # Use orderbymin parameter with multiple values
#' erddap_data(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','depth','temperature'),
#'    'time>=' = '2007-06-10', 'time<=' = '2007-09-21', orderbymax=c('depth','temperature'))
#' }

erddap_data <- function(datasetid, fields=NULL, ..., distinct=FALSE, orderby=NULL, 
  orderbymax=NULL, orderbymin=NULL, orderbyminmax=NULL, units=NULL, callopts=list())
{
  fields <- paste(fields, collapse = ",")
  url <- "http://coastwatch.pfeg.noaa.gov/erddap/tabledap/%s.csv?%s"
  url <- sprintf(url, datasetid, fields)
  args <- list(...)
  distinct <- if(distinct) 'distinct()' else NULL
  units <- makevar(units, 'units("%s")')
  orderby <- makevar(orderby, 'orderBy("%s")')
  orderbymax <- makevar(orderbymax, 'orderByMax("%s")')
  orderbymin <- makevar(orderbymin, 'orderByMin("%s")')
  orderbyminmax <- makevar(orderbyminmax, 'orderByMinMax("%s")')
  moreargs <- noaa_compact(list(distinct, orderby, orderbymax, orderbymin, orderbyminmax, units))
  args <- c(args, moreargs)
  args <- collapse_args(args)
  if(!nchar(args[[1]]) == 0){
    url <- paste0(url, '&', args)
  }
  tt <- GET(url, list(), callopts)
  out <- check_response_erddap(tt)
  if(grepl("Error", out)){
    return( NA )
  } else {
    df <- read.delim(text=out, sep=",")[-1,]
    df
  }
}

collapse_args <- function(x){
  outout <- list()
  for(i in seq_along(x)){
    tmp <- paste(names(x[i]), x[i], sep="")
    outout[[i]] <- tmp
  }
  paste0(outout, collapse = "&")
}

makevar <- function(x, y){
  if(!is.null(x)){
    x <- paste0(x, collapse = ",")
    sprintf(y, x)
  } else {
    NULL
  }
} 

#' Get information on an ERDDAP dataset.
#' 
#' Gives back a brief data.frame for quick inspection and a list of more complete
#' metadata on the dataset.
#'
#' @export
#' @import httr assertthat
#' @importFrom jsonlite fromJSON
#' @param datasetid Dataset id
#' @param callopts Further args passed on to httr::GET (must be a named parameter)
#' @return A list of length two
#' \itemize{
#'  \item variables Data.frame of variables and their types
#'  \item alldata List of data variables and their full attributes
#' }
#' @examples \dontrun{
#' erddap_info(datasetid='erdCalCOFIfshsiz')
#' out <- erddap_info(datasetid='erdCinpKfmBT')
#' }

erddap_info <- function(datasetid, callopts=list()){
  url <- 'http://coastwatch.pfeg.noaa.gov/erddap/info/%s/index.json'
  url <- sprintf(url, datasetid)
  tt <- GET(url, list(), callopts)
  warn_for_status(tt)
  assert_that(tt$headers$`content-type` == 'application/json;charset=UTF-8')
  out <- content(tt, as = "text")
  json <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  colnames <- sapply(tolower(json$table$columnNames), function(z) gsub("\\s", "_", z))
  dfs <- lapply(json$table$rows, function(x){
    tmp <- data.frame(x, stringsAsFactors = FALSE)
    names(tmp) <- colnames
    tmp
  })
  lists <- lapply(json$table$rows, function(x){
    names(x) <- colnames
    x
  })
  df <- data.frame(rbindlist(dfs))
  vars <- df[ df$row_type == 'variable', names(df) %in% c('row_type','variable_name','data_type')]
  res <- list(variables=vars, alldata=lists)
  class(res) <- "erddap_info"
  return( res )
}

# print.erddap_info <- function(x, ...){
#   x <- x[ x$row_type == 'variable', names(x) %in% c('row_type','variable_name','data_type')]
#   print(x)
# }
#   cutlength <- vapply(x[apply(x, c(1,2), nchar) > 25], substr, "", start=1, stop=25, USE.NAMES = FALSE)
#   cutlength <- paste0(cutlength, "...")
#   x[apply(x, c(1,2), nchar) > 25] <- cutlength
#   x <- data.frame(x, stringsAsFactors = FALSE)

#' Search for ERDDAP datasets.
#'
#' @export
#' @import httr assertthat
#' @param query Search terms
#' @param page Page number
#' @param page_size Results per page
#' @param callopts Further args passed on to httr::GET (must be a named parameter)
#' @param x Input to print method for class erddap_search
#' @param ... Further args to print, ignored.
#' @examples \dontrun{
#' (out <- erddap_search(query='fish size'))
#' out$alldata
#' (out <- erddap_search(query='size'))
#' out$info
#' }

erddap_search <- function(query, page=NULL, page_size=NULL, callopts=list()){
  url <- 'http://coastwatch.pfeg.noaa.gov/erddap/search/index.json'
  args <- noaa_compact(list(searchFor=query, page=page, itemsPerPage=page_size))
  tt <- GET(url, query=args, callopts)
  warn_for_status(tt)
  assert_that(tt$headers$`content-type` == 'application/json;charset=UTF-8')
  out <- content(tt, as = "text")
  json <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  colnames <- vapply(tolower(json$table$columnNames), function(z) gsub("\\s", "_", z), "", USE.NAMES = FALSE)
  dfs <- lapply(json$table$rows, function(x){
    names(x) <- colnames
    x <- x[c('title','dataset_id')]
    data.frame(x, stringsAsFactors = FALSE)
  })
  df <- data.frame(rbindlist(dfs))
  lists <- lapply(json$table$rows, function(x){
    names(x) <- colnames
    x
  })
  res <- list(info=df, alldata=lists)
  class(res) <- "erddap_search"
  return( res )
}

#' @method print erddap_search
#' @export
#' @rdname erddap_search
print.erddap_search <- function(x, ...){
  cat(sprintf("%s results, showing first 20", nrow(x$info)), "\n")
  print(head(x$info, n = 20))
}